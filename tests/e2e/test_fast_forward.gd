extends GutTest
## Night fast-forward on the real prototype scene (owner decision 2026-10-07, UAT G-02-14, after
## G-02-1): one press of the fast_forward input switches a night to LoopTuning.fast_forward_scale
## and it stays on after the key is let go, the next press switches it off, the HUD says so, the
## king and the simulation keep pace, and the game is at real time by day, at dawn and at the start
## of every night.
##
## Real time is read with Time.get_ticks_usec and physics frames are counted with
## wait_physics_frames, never wait_seconds: the engine time scale also scales GUT's waits. The
## ratio bounds are loose on purpose (review finding IN-05).

const ACTION: StringName = &"fast_forward"
const LABEL_TEXT := "Fast-forward 2x"
const RUN_SEED: int = 7
const RIDE_FRAMES: int = 30
const MEASURE_US: int = 1_000_000
const MAX_DAWN_STEPS: int = 600
const PACE_MIN: float = 1.7
const PACE_MAX: float = 2.3
const RATE_MIN: float = 1.6
const RATE_MAX: float = 2.4


func after_each() -> void:
	Engine.time_scale = 1.0
	E2eSupport.release_all_actions()


func _spawn(map: MapConfig) -> MapRoot:
	var scene: PackedScene = load("res://presentation/map/prototype_map.tscn")
	var map_root: MapRoot = scene.instantiate()
	map_root.map_config = map
	map_root.fixed_run_seed = RUN_SEED
	map_root.handle_results_actions = false
	add_child_autofree(map_root)
	await wait_process_frames(2)
	return map_root


func _label(map_root: MapRoot) -> Label:
	return map_root.get_node("HUD").get_node_or_null("%FastForwardLabel") as Label


## One press of the fast_forward input: down for two frames, released, two more frames.
func _tap_fast_forward() -> void:
	Input.action_press(ACTION)
	await wait_process_frames(2)
	Input.action_release(ACTION)
	await wait_process_frames(2)


func _start_night(map_root: MapRoot) -> void:
	var ctx: RunContext = map_root.get_context()
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")


## Ground the king covers walking right for RIDE_FRAMES physics frames from the spawn point.
func _ride_distance(map_root: MapRoot) -> float:
	var king: King = map_root.get_king()
	king.velocity = Vector3.ZERO
	E2eSupport.teleport_king(map_root, map_root.get_context().map.king_spawn)
	await wait_physics_frames(1)
	var start: Vector3 = king.global_position
	Input.action_press(&"move_right")
	await wait_physics_frames(RIDE_FRAMES)
	Input.action_release(&"move_right")
	return Vector2(king.global_position.x - start.x, king.global_position.z - start.z).length()


## Simulation steps per real second over about one real second.
func _ticks_per_real_second(ctx: RunContext) -> float:
	var first_tick: int = ctx.tick_count
	var started_us: int = Time.get_ticks_usec()
	var elapsed_us: int = 0
	while elapsed_us < MEASURE_US:
		await wait_process_frames(1)
		elapsed_us = Time.get_ticks_usec() - started_us
	return float(ctx.tick_count - first_tick) / (float(elapsed_us) / 1_000_000.0)


func test_pressing_fast_forward_by_day_changes_nothing_and_the_night_starts_at_real_time() -> void:
	var map_root: MapRoot = await _spawn(E2eSupport.shipped_prototype_map())
	var label: Label = _label(map_root)
	assert_not_null(label, "the HUD has a FastForwardLabel")
	if label == null:
		return
	assert_false(label.visible, "hidden to begin with")
	await _tap_fast_forward()
	assert_eq(Engine.time_scale, 1.0, "by day the game runs at real time")
	assert_false(label.visible, "and the label stays hidden")
	_start_night(map_root)
	await wait_process_frames(2)
	assert_eq(Engine.time_scale, 1.0, "the day press armed nothing: the night starts at real time")
	assert_false(label.visible, "and the label is still hidden")


func test_the_label_stays_after_release_and_hides_on_the_second_press() -> void:
	var map_root: MapRoot = await _spawn(E2eSupport.shipped_prototype_map())
	var label: Label = _label(map_root)
	assert_not_null(label, "the HUD has a FastForwardLabel")
	if label == null:
		return
	_start_night(map_root)
	await _tap_fast_forward()
	assert_eq(Engine.time_scale, 2.0, "a press at night runs at 2x")
	assert_true(label.visible, "the label is shown")
	assert_eq(label.text, LABEL_TEXT, "and says what is on")
	await wait_process_frames(2)
	assert_eq(Engine.time_scale, 2.0, "the key is up and it is still on")
	assert_true(label.visible, "and the label stays")
	await _tap_fast_forward()
	assert_eq(Engine.time_scale, 1.0, "the second press is real time")
	assert_false(label.visible, "the label is hidden again")


func test_the_king_covers_about_twice_the_ground_while_fast_forwarded() -> void:
	var map_root: MapRoot = await _spawn(E2eSupport.shipped_prototype_map())
	_start_night(map_root)
	var normal: float = await _ride_distance(map_root)
	await _tap_fast_forward()
	assert_eq(Engine.time_scale, 2.0, "fast-forward is on for the second ride")
	var fast: float = await _ride_distance(map_root)
	assert_gt(normal, 0.0, "the king moved at normal speed")
	var ratio: float = fast / normal
	assert_between(ratio, PACE_MIN, PACE_MAX, "the king kept pace: %.2fx the ground" % ratio)


func test_the_simulation_runs_about_twice_the_steps_per_real_second_while_fast_forwarded() -> void:
	var map_root: MapRoot = await _spawn(E2eSupport.shipped_prototype_map())
	_start_night(map_root)
	var ctx: RunContext = map_root.get_context()
	var normal: float = await _ticks_per_real_second(ctx)
	await _tap_fast_forward()
	assert_eq(Engine.time_scale, 2.0, "fast-forward is on for the second measurement")
	var fast: float = await _ticks_per_real_second(ctx)
	assert_gt(normal, 0.0, "the night ran at normal speed")
	var ratio: float = fast / normal
	assert_between(ratio, RATE_MIN, RATE_MAX, "tick rate ratio %.2f" % ratio)


func test_the_label_is_hidden_at_dawn_and_the_next_night_starts_at_real_time() -> void:
	var map_root: MapRoot = await _spawn(E2eSupport.waveless_prototype_map())
	var label: Label = _label(map_root)
	assert_not_null(label, "the HUD has a FastForwardLabel")
	if label == null:
		return
	var ctx: RunContext = map_root.get_context()
	_start_night(map_root)
	await _tap_fast_forward()
	assert_true(label.visible, "shown during the timed night")
	var steps: int = 0
	while ctx.run_manager.get_phase() == RunManager.RunPhase.NIGHT and steps < MAX_DAWN_STEPS:
		ctx.step()
		steps += 1
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "the night ended into dawn")
	assert_false(label.visible, "the label is hidden at dawn while it was still switched on")
	assert_eq(Engine.time_scale, 1.0, "and dawn runs at real time")
	steps = 0
	while ctx.run_manager.get_phase() != RunManager.RunPhase.DAY and steps < MAX_DAWN_STEPS:
		ctx.step()
		steps += 1
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAY, "the dawn handed over to day")
	_start_night(map_root)
	await wait_process_frames(2)
	assert_eq(Engine.time_scale, 1.0, "the next night starts at real time")
	assert_false(label.visible, "with the label hidden")
