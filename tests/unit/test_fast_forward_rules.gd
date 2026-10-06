extends GutTest
## Night fast-forward (owner decision 2026-10-06, UAT G-02-1): holding fast_forward during a night
## runs the game at LoopTuning.fast_forward_scale through Engine.time_scale. It changes only how
## many fixed steps run per real second, never what a step does (DEV-05), it acts in NIGHT alone,
## and FastForwardController is the single writer of the engine time scale.

const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
const ACTION: StringName = &"fast_forward"
const SEED: int = 7
const MAX_DAWN_STEPS: int = 600
const NIGHT: int = RunManager.RunPhase.NIGHT
const SCAN_SKIP_DIRS: Array[String] = ["addons", "tests", ".godot", ".tools", "build"]
const WRITE_PATTERN := "Engine\\.time_scale\\s*=[^=]"
const WRITER_PATH := "res://input/fast_forward_controller.gd"

var _tuning: LoopTuning
var _changes: Array[Array] = []


func before_each() -> void:
	_tuning = load(TUNING_PATH)
	_changes = []
	Engine.time_scale = 1.0


func after_each() -> void:
	Engine.time_scale = 1.0
	E2eSupport.release_all_actions()


func _tuning_with_scale(scale: float) -> LoopTuning:
	var tuning: LoopTuning = _tuning.duplicate(true)
	tuning.fast_forward_scale = scale
	return tuning


func _context(map: MapConfig = null) -> RunContext:
	var used: MapConfig = map if map != null else E2eSupport.shipped_prototype_map()
	return RunContext.new(used, _tuning, SEED)


func _controller_on(ctx: RunContext) -> FastForwardController:
	var controller: FastForwardController = FastForwardController.new()
	add_child(controller)
	controller.bind_run(ctx, null)
	controller.changed.connect(_on_changed)
	return controller


func _on_changed(active: bool, scale: float) -> void:
	_changes.append([active, scale])


func _night_started_context() -> RunContext:
	var ctx: RunContext = _context()
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	return ctx


# --- the scale rules ---------------------------------------------------------------------------


func test_the_shipped_scale_applies_only_to_a_held_night() -> void:
	assert_eq(FastForwardController.scale_for(NIGHT, true, _tuning), 2.0, "held at night is 2x")
	assert_eq(FastForwardController.scale_for(NIGHT, false, _tuning), 1.0, "not held is real time")


func test_every_other_phase_runs_at_real_time_even_when_held() -> void:
	for phase: int in [
		RunManager.RunPhase.DAY,
		RunManager.RunPhase.NIGHT_TRANSITION,
		RunManager.RunPhase.DAWN,
		RunManager.RunPhase.WON,
		RunManager.RunPhase.LOST,
	]:
		assert_eq(FastForwardController.scale_for(phase, true, _tuning), 1.0, "phase %d" % phase)


func test_an_out_of_range_scale_is_clamped() -> void:
	var cap: float = LoopTuning.FAST_FORWARD_MAX_SCALE
	assert_eq(FastForwardController.scale_for(NIGHT, true, _tuning_with_scale(100.0)), cap, "cap")
	assert_eq(FastForwardController.scale_for(NIGHT, true, _tuning_with_scale(0.5)), 1.0, "floor")
	assert_eq(FastForwardController.scale_for(NIGHT, true, _tuning_with_scale(-3.0)), 1.0, "neg")


func test_a_scale_that_is_not_finite_counts_as_real_time() -> void:
	for bad: float in [NAN, INF, -INF]:
		var scale: float = FastForwardController.scale_for(NIGHT, true, _tuning_with_scale(bad))
		assert_eq(scale, 1.0, "%s counts as 1.0" % bad)


# --- the controller on a run -------------------------------------------------------------------


func test_fast_forward_held_by_day_changes_nothing_then_runs_the_night_at_2x() -> void:
	var ctx: RunContext = _context()
	var controller: FastForwardController = _controller_on(ctx)
	Input.action_press(ACTION)
	await wait_process_frames(2)
	assert_eq(Engine.time_scale, 1.0, "held by day stays at real time")
	assert_false(controller.is_active(), "not active by day")
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	await wait_process_frames(1)
	assert_eq(Engine.time_scale, 2.0, "held at night runs at 2x")
	assert_true(controller.is_active(), "active at night")
	assert_eq(controller.get_scale(), 2.0, "the controller reports the scale")
	assert_eq(_changes, [[true, 2.0]] as Array[Array], "changed fired once, on")
	Input.action_release(ACTION)
	await wait_process_frames(1)
	assert_eq(Engine.time_scale, 1.0, "released is real time")
	assert_eq(_changes, [[true, 2.0], [false, 1.0]] as Array[Array], "changed fired off once")


func test_a_night_that_starts_while_the_key_is_already_down_runs_fast() -> void:
	var ctx: RunContext = _context()
	_controller_on(ctx)
	Input.action_press(ACTION)
	await wait_process_frames(1)
	ctx.commands.submit(StartNightIntent.new())
	assert_eq(Engine.time_scale, 2.0, "the held key resumes fast-forward as the night begins")


func test_the_scale_drops_inside_the_step_that_ends_the_run_in_defeat() -> void:
	var ctx: RunContext = _night_started_context()
	_controller_on(ctx)
	Input.action_press(ACTION)
	await wait_process_frames(1)
	assert_eq(Engine.time_scale, 2.0, "fast at night")
	assert_true(ctx.run_manager.end_run_in_defeat(), "the run is lost")
	assert_eq(Engine.time_scale, 1.0, "real time at once, before any frame passes")


func test_the_scale_drops_inside_the_step_that_reaches_dawn() -> void:
	var ctx: RunContext = _context(E2eSupport.waveless_prototype_map())
	_controller_on(ctx)
	ctx.commands.submit(StartNightIntent.new())
	Input.action_press(ACTION)
	await wait_process_frames(1)
	assert_eq(Engine.time_scale, 2.0, "fast during the timed night")
	var steps: int = 0
	while ctx.run_manager.get_phase() == NIGHT and steps < MAX_DAWN_STEPS:
		ctx.step()
		steps += 1
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "the night ended into dawn")
	assert_eq(Engine.time_scale, 1.0, "real time the moment dawn begins, with the key still held")


func test_freeing_the_controller_while_fast_restores_real_time() -> void:
	var ctx: RunContext = _night_started_context()
	var controller: FastForwardController = _controller_on(ctx)
	Input.action_press(ACTION)
	await wait_process_frames(1)
	assert_eq(Engine.time_scale, 2.0, "fast at night")
	controller.free()
	assert_eq(Engine.time_scale, 1.0, "leaving the tree restores real time")


func test_the_prototype_scene_has_a_run_bound_fast_forward_node() -> void:
	var scene: PackedScene = load("res://presentation/map/prototype_map.tscn")
	var map_root: Node = scene.instantiate()
	var node: Node = map_root.find_child("FastForward", true, false)
	assert_not_null(node, "the scene declares a FastForward node")
	if node != null:
		assert_true(node is FastForwardController, "of type FastForwardController")
		assert_true(node.is_in_group(&"run_bound"), "bound to the run like the other inputs")
	map_root.free()


# --- determinism -------------------------------------------------------------------------------


func test_doubled_frame_deltas_run_the_same_steps_and_the_same_digest() -> void:
	var normal_ctx: RunContext = _night_started_context()
	var normal_recorder: SimRecorder = SimRecorder.attach(normal_ctx)
	var fast_ctx: RunContext = _night_started_context()
	var fast_recorder: SimRecorder = SimRecorder.attach(fast_ctx)
	for frame: int in range(120):
		normal_ctx.advance(1.0 / 60.0)
	for frame: int in range(60):
		fast_ctx.advance(1.0 / 30.0)
	assert_eq(fast_ctx.tick_count, normal_ctx.tick_count, "the same number of steps")
	assert_gt(normal_ctx.tick_count, 0, "the night really ran")
	assert_eq(fast_recorder.digest(), normal_recorder.digest(), "the same event digest")


func test_the_clamp_still_bounds_a_fast_forwarded_frame() -> void:
	var long_frame: RunContext = _night_started_context()
	var bounded: RunContext = _night_started_context()
	var long_steps: int = long_frame.advance(0.5)
	var bounded_steps: int = bounded.advance(SimClock.MAX_ADVANCE_SECONDS)
	assert_eq(long_steps, bounded_steps, "advance(0.5) runs what advance(0.25) runs")
	assert_lte(long_steps, 8, "a stalled frame never runs more than the clamp's catch-up")


# --- the single writer -------------------------------------------------------------------------


func _first_party_scripts(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return found
	for sub: String in dir.get_directories():
		if dir_path == "res://" and SCAN_SKIP_DIRS.has(sub):
			continue
		found.append_array(_first_party_scripts(dir_path.path_join(sub)))
	for file_name: String in dir.get_files():
		if file_name.ends_with(".gd"):
			found.append(dir_path.path_join(file_name))
	return found


func _code_lines(path: String) -> Array[String]:
	var lines: Array[String] = []
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		if not line.strip_edges().begins_with("#"):
			lines.append(line)
	return lines


func test_only_the_fast_forward_controller_assigns_the_engine_time_scale() -> void:
	var pattern: RegEx = RegEx.create_from_string(WRITE_PATTERN)
	assert_not_null(pattern.search("Engine.time_scale = 2.0"), "the pattern finds a write")
	assert_null(pattern.search("if Engine.time_scale == 1.0:"), "and ignores a comparison")
	var scripts: Array[String] = _first_party_scripts("res://")
	assert_gt(scripts.size(), 50, "the scan really read the first-party scripts")
	var writers: Array[String] = []
	for path: String in scripts:
		for line: String in _code_lines(path):
			if pattern.search(line) != null and not writers.has(path):
				writers.append(path)
	assert_eq(writers, [WRITER_PATH] as Array[String], "one writer of the engine time scale")


func test_nothing_under_simulation_mentions_the_time_scale() -> void:
	var scripts: Array[String] = _first_party_scripts("res://simulation")
	assert_gt(scripts.size(), 20, "the scan really read the simulation sources")
	var mentions: Array[String] = []
	for path: String in scripts:
		for line: String in _code_lines(path):
			if line.contains("time_scale"):
				mentions.append(path)
	assert_eq(mentions, [] as Array[String], "the simulation never reads the time scale")
