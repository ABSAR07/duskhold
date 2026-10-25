class_name StressNight
extends Node
## The stress night (PLAT-01, D-10, D-11, D-12, RESEARCH Pattern 11): the tools-only stress map at
## night 1 in a real window with 300 enemies, 50 friendly units and about 200 arrows on screen,
## captured frame by frame into build/stress/run_<n>.json for tools/stress/frame_report_cli.gd.
##
## It never runs headless (it exits 2 there, like ShotRunner) and never in CI. Launch it through
## tools/stress.sh, which runs it three times and then the report tool. The raw command it wraps:
##   bash tools/godot.sh --path . --resolution 1920x1080 res://tools/stress/stress_night.tscn -- \
##       --run=1 --duration=20 --warmup=10 --out=build/stress
## Arguments (everything after `--`; anything else is a usage error):
##   --duration=<5..120>  seconds measured after the warm-up; default 20
##   --warmup=<0..60>     seconds run before measuring starts; default 10
##   --run=<1..9>         the run number, the file is run_<n>.json; default 1
##   --out=<dir>          under build/; default build/stress
## Exit codes: 0 written, 1 the framing or the output failed, 2 no real renderer, 64 usage.
##
## What it fixes so the numbers are comparable (Pitfall 13): vsync off, uncapped frame rate, speed
## 1.0x, the king parked at (0, 0, 14) with a health pool that outlasts the night, and a camera
## placed straight above the play area high enough that the box x -44..44, y 0..3, z -16..64 is
## inside the frustum (the 80 m wall, the spawn scatter out to z 59, the towers, the barracks and
## the crowd round the castle), checked on the box's eight corners. The map root's own _process is
## turned off and this node feeds the real frame time to the simulation so the step can be timed.
## The sun's shadow distance is raised to reach the high camera so the shadow pass still runs.
## tools/ is excluded from the export.

const ReplayCli := preload("res://tools/replay/replay_cli.gd")

const MAP_SCENE_PATH := "res://presentation/map/prototype_map.tscn"
const KING_DATA_PATH := "res://data/king/king.tres"
const OUT_ROOT := "res://build"
const DEFAULT_OUT := "res://build/stress"
const FIXED_RUN_SEED: int = 1
const DEFAULT_DURATION_S: int = 20
const MIN_DURATION_S: int = 5
const MAX_DURATION_S: int = 120
const DEFAULT_WARMUP_S: int = 10
const MAX_WARMUP_S: int = 60
const DEFAULT_RUN: int = 1
const MAX_RUN: int = 9
const FLAG_DURATION := "--duration="
const FLAG_WARMUP := "--warmup="
const FLAG_RUN := "--run="
const FLAG_OUT := "--out="
const EXIT_OK: int = 0
const EXIT_FAILED: int = 1
const EXIT_NO_RENDERER: int = 2
const EXIT_USAGE: int = 64
## The window size tools/stress.sh asks for with --resolution; the actual size is recorded too.
const REQUESTED_SIZE := Vector2i(1920, 1080)
## The king stands here for the whole night, between the tower rows and clear of the wall.
const KING_PARK := Vector3(0.0, 0.0, 14.0)
## The king's health pool: the night must not end in the king's death countdown.
const KING_HEALTH: int = 10000000
## The play area every enemy, unit and arrow of the night stays inside.
const FRAME_MIN := Vector3(-44.0, 0.0, -16.0)
const FRAME_MAX := Vector3(44.0, 3.0, 64.0)
## Extra height over the analytic fit, as a share, so the box corners sit inside the frustum.
const FRAME_MARGIN: float = 1.06
## The sun's shadow distance in metres, enough to reach a camera this high.
const SHADOW_DISTANCE: float = 400.0
## Counts of what is on screen are taken every this many frames of the measured window.
const SAMPLE_EVERY_FRAMES: int = 30
## Height above the ground a drawn enemy or unit is tested at, in metres.
const BODY_TEST_HEIGHT: float = 1.0
const MS_PER_S: float = 1000.0
const MICROS_PER_MS: float = 1000.0
const ROUND_STEP: float = 0.001

var _args: Dictionary = {}
var _map_root: MapRoot
var _ctx: RunContext
var _camera: Camera3D
var _enemy_views: EnemyViews
var _unit_views: UnitViews
var _projectiles: ProjectileVfx
var _viewport: RID
var _elapsed_s: float = 0.0
var _measured_s: float = 0.0
var _frame_index: int = 0
var _overhead_ms: float = 0.0
var _started: bool = false
var _done: bool = false
var _spawned_at_start: int = 0
var _frame_ms: PackedFloat64Array = PackedFloat64Array()
var _step_ms: PackedFloat64Array = PackedFloat64Array()
var _render_cpu_ms: PackedFloat64Array = PackedFloat64Array()
var _render_gpu_ms: PackedFloat64Array = PackedFloat64Array()
var _draw_calls: PackedFloat64Array = PackedFloat64Array()
var _objects: PackedFloat64Array = PackedFloat64Array()
var _primitives: PackedFloat64Array = PackedFloat64Array()
var _sample_enemies: PackedFloat64Array = PackedFloat64Array()
var _sample_units: PackedFloat64Array = PackedFloat64Array()
var _sample_arrows: PackedFloat64Array = PackedFloat64Array()


## Parses the user arguments. Returns {error, duration, warmup, run, out}; `error` is "" when every
## argument passed the allowlist, else a one-line reason. `out` comes back as a res:// path.
static func parse_args(args: PackedStringArray) -> Dictionary:
	var parsed: Dictionary = {
		"error": "",
		"duration": DEFAULT_DURATION_S,
		"warmup": DEFAULT_WARMUP_S,
		"run": DEFAULT_RUN,
		"out": DEFAULT_OUT,
	}
	for arg: String in args:
		var failure: String = ""
		if arg.begins_with(FLAG_DURATION):
			failure = _read_bounded(
				parsed, "duration", arg.trim_prefix(FLAG_DURATION), MIN_DURATION_S, MAX_DURATION_S
			)
		elif arg.begins_with(FLAG_WARMUP):
			failure = _read_bounded(parsed, "warmup", arg.trim_prefix(FLAG_WARMUP), 0, MAX_WARMUP_S)
		elif arg.begins_with(FLAG_RUN):
			failure = _read_bounded(parsed, "run", arg.trim_prefix(FLAG_RUN), 1, MAX_RUN)
		elif arg.begins_with(FLAG_OUT):
			failure = _read_out(parsed, arg.trim_prefix(FLAG_OUT))
		else:
			failure = "unknown argument '%s'" % arg
		if not failure.is_empty():
			parsed["error"] = failure
			return parsed
	return parsed


## Stores the integer `text` under `key` when it lies in `lower`..`upper`; returns "" or the reason.
static func _read_bounded(
	parsed: Dictionary, key: String, text: String, lower: int, upper: int
) -> String:
	if not text.is_valid_int():
		return "--%s must be an integer, got '%s'" % [key, text]
	var value: int = text.to_int()
	if value < lower or value > upper:
		return "--%s must be between %d and %d, got %d" % [key, lower, upper, value]
	parsed[key] = value
	return ""


static func _read_out(parsed: Dictionary, text: String) -> String:
	var path: String = ReplayCli.safe_dir(text, OUT_ROOT)
	if path.is_empty():
		return "--out must be a directory under build/"
	parsed["out"] = path
	return ""


## The camera height that puts the box FRAME_MIN..FRAME_MAX inside a camera looking straight down
## from above its centre, for a vertical field of view of `fov_degrees` and a window `aspect`
## (width over height), with FRAME_MARGIN to spare. Screen up is world -z.
static func fit_height(fov_degrees: float, aspect: float) -> float:
	var half_depth: float = (FRAME_MAX.z - FRAME_MIN.z) * 0.5
	var half_width: float = (FRAME_MAX.x - FRAME_MIN.x) * 0.5
	var tan_vertical: float = tan(deg_to_rad(fov_degrees) * 0.5)
	var tan_horizontal: float = tan_vertical * aspect
	var needed: float = maxf(half_depth / tan_vertical, half_width / tan_horizontal)
	return FRAME_MAX.y + needed * FRAME_MARGIN


## The eight corners of the play-area box.
static func frame_corners() -> Array[Vector3]:
	var corners: Array[Vector3] = []
	for x: float in [FRAME_MIN.x, FRAME_MAX.x]:
		for y: float in [FRAME_MIN.y, FRAME_MAX.y]:
			for z: float in [FRAME_MIN.z, FRAME_MAX.z]:
				corners.append(Vector3(x, y, z))
	return corners


func _ready() -> void:
	_args = parse_args(OS.get_cmdline_user_args())
	var error: String = _args["error"]
	if not error.is_empty():
		printerr("STRESS_USAGE %s" % error)
		printerr(
			(
				"usage: [--duration=<%d..%d>] [--warmup=<0..%d>] [--run=<1..%d>] [--out=build/<dir>]"
				% [MIN_DURATION_S, MAX_DURATION_S, MAX_WARMUP_S, MAX_RUN]
			)
		)
		get_tree().quit(EXIT_USAGE)
		return
	if DisplayServer.get_name() == "headless":
		printerr("the stress night needs a real renderer; never run it under --headless")
		get_tree().quit(EXIT_NO_RENDERER)
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	if not _build_night():
		get_tree().quit(EXIT_FAILED)
		return
	var corner: String = _outside_corner()
	if not corner.is_empty():
		printerr("STRESS_FRAMING_FAILED corner=%s" % corner)
		get_tree().quit(EXIT_FAILED)
		return
	_viewport = get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(_viewport, true)
	print(
		(
			"STRESS_START run=%d warmup=%d duration=%d camera_y=%.1f"
			% [_args["run"], _args["warmup"], _args["duration"], _camera.global_position.y]
		)
	)


## Instances the map on the stress map, builds every plot, starts night 1, parks the king and
## frames the play area. False after a message when a step failed.
func _build_night() -> bool:
	var stress: MapConfig = load(GateStress.STRESS_MAP) as MapConfig
	if stress == null:
		printerr("STRESS_FAILED reason=no_stress_map")
		return false
	var scene: PackedScene = load(MAP_SCENE_PATH)
	_map_root = scene.instantiate()
	_map_root.map_config = stress.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	_map_root.fixed_run_seed = FIXED_RUN_SEED
	_map_root.handle_results_actions = false
	(_map_root.get_node("King") as King).def = _king_def()
	add_child(_map_root)
	_map_root.set_process(false)
	_ctx = _map_root.get_context()
	for spot_id: StringName in _ctx.buildings.spot_ids():
		_ctx.buildings.apply_next_tier(spot_id)
	_map_root.get_king().global_position = KING_PARK
	_report_king()
	_ctx.step()
	if _ctx.commands.submit(StartNightIntent.new()) != CommandProcessor.OK:
		printerr("STRESS_FAILED reason=night_did_not_start")
		return false
	_enemy_views = _map_root.get_node("EnemyViews") as EnemyViews
	_unit_views = _map_root.get_node("UnitViews") as UnitViews
	_projectiles = _map_root.get_node("ProjectileVfx") as ProjectileVfx
	_frame_play_area()
	return true


## The shipped king with a health pool that outlasts the night.
func _king_def() -> KingDef:
	var def: KingDef = (load(KING_DATA_PATH) as KingDef).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	def.max_health = KING_HEALTH
	return def


## Places the active camera straight above the play area and lifts the sun's shadow distance.
func _frame_play_area() -> void:
	(_map_root.get_node("CameraRig") as Node).set_physics_process(false)
	_camera = _map_root.get_node("CameraRig/Camera3D") as Camera3D
	var size: Vector2 = get_viewport().get_visible_rect().size
	var height: float = fit_height(_camera.fov, size.x / size.y)
	var centre: Vector3 = (FRAME_MIN + FRAME_MAX) * 0.5
	_camera.global_position = Vector3(centre.x, height, centre.z)
	_camera.look_at(Vector3(centre.x, 0.0, centre.z), Vector3.FORWARD)
	var sun: DirectionalLight3D = _map_root.get_node("Lighting/Sun") as DirectionalLight3D
	sun.directional_shadow_max_distance = SHADOW_DISTANCE


## The first corner of the play-area box outside the camera's frustum as "x,y,z", or "".
func _outside_corner() -> String:
	for corner: Vector3 in frame_corners():
		if not _camera.is_position_in_frustum(corner):
			return "%s,%s,%s" % [corner.x, corner.y, corner.z]
	return ""


func _report_king() -> void:
	var at: Vector3 = _map_root.get_king().global_position
	_ctx.king.report_position(Vector2(at.x, at.z))


func _process(delta: float) -> void:
	if _done or _ctx == null:
		return
	var step_started: int = Time.get_ticks_usec()
	_report_king()
	_ctx.advance(delta)
	var step_ms: float = float(Time.get_ticks_usec() - step_started) / MICROS_PER_MS
	_elapsed_s += delta
	if not _started:
		if _elapsed_s >= float(_args["warmup"]):
			_started = true
			_spawned_at_start = _ctx.night.spawned_count()
		return
	_record(delta, step_ms)
	if _measured_s >= float(_args["duration"]):
		_done = true
		get_tree().quit(_finish())


## Appends the numbers of the frame that just ended. The frame time is the delta Godot reports for
## it, less the time the previous frame spent counting what is on screen.
func _record(delta: float, step_ms: float) -> void:
	_frame_ms.append(maxf(delta * MS_PER_S - _overhead_ms, 0.0))
	_measured_s += delta
	_overhead_ms = 0.0
	_step_ms.append(step_ms)
	_render_cpu_ms.append(RenderingServer.viewport_get_measured_render_time_cpu(_viewport))
	_render_gpu_ms.append(RenderingServer.viewport_get_measured_render_time_gpu(_viewport))
	_draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_objects.append(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	_primitives.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	_frame_index += 1
	if _frame_index % SAMPLE_EVERY_FRAMES == 0:
		var counting_started: int = Time.get_ticks_usec()
		_sample_counts()
		_overhead_ms = float(Time.get_ticks_usec() - counting_started) / MICROS_PER_MS


## Counts the living enemies, living units and arrows drawn that stand inside the camera frustum
## at their drawn positions.
func _sample_counts() -> void:
	var enemies: EnemySystem = _ctx.night.get_enemies()
	var enemy_count: int = 0
	for id: int in enemies.ids():
		if enemies.is_alive(id) and _enemy_views.has_view(id):
			if _in_view(_enemy_views.puppet_position(id)):
				enemy_count += 1
	var units: UnitSystem = _ctx.squads.get_units()
	var unit_count: int = 0
	for id: int in units.ids():
		if units.is_alive(id) and _unit_views.has_view(id):
			if _in_view(_unit_views.puppet_position(id)):
				unit_count += 1
	var arrow_count: int = 0
	for index: int in range(_projectiles.arrow_count()):
		if _camera.is_position_in_frustum(_projectiles.arrow_position_at(index)):
			arrow_count += 1
	_sample_enemies.append(float(enemy_count))
	_sample_units.append(float(unit_count))
	_sample_arrows.append(float(arrow_count))


func _in_view(ground_point: Vector3) -> bool:
	return _camera.is_position_in_frustum(ground_point + Vector3.UP * BODY_TEST_HEIGHT)


## Writes run_<n>.json and prints the run's one-line summary. Returns the exit code.
func _finish() -> int:
	var out: String = _args["out"]
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out)) != OK:
		printerr("STRESS_FAILED reason=cannot_make_output_folder")
		return EXIT_FAILED
	var path: String = "%s/run_%d.json" % [out, _args["run"]]
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("STRESS_FAILED reason=cannot_write file=%s" % path)
		return EXIT_FAILED
	var stored: bool = file.store_string(JSON.stringify(_run_data(), "", false) + "\n")
	file.close()
	if not stored:
		printerr("STRESS_FAILED reason=cannot_write file=%s" % path)
		return EXIT_FAILED
	var summary: Dictionary = FrameReport.summarise(_run_data())
	print(
		(
			(
				"STRESS_RUN run=%d frames=%d p50_ms=%.2f p95_ms=%.2f p99_ms=%.2f max_ms=%.2f "
				+ "enemies_min=%d units_min=%d arrows_min=%d file=%s"
			)
			% [
				_args["run"],
				summary["count"],
				summary["p50"],
				summary["p95"],
				summary["p99"],
				summary["max"],
				summary["enemies_min"],
				summary["units_min"],
				summary["arrows_min"],
				path,
			]
		)
	)
	return EXIT_OK


## The run dictionary FrameReport reads.
func _run_data() -> Dictionary:
	return {
		"header": _header(),
		"frame_ms": _rounded(_frame_ms),
		"step_ms": _rounded(_step_ms),
		"render_cpu_ms": _rounded(_render_cpu_ms),
		"render_gpu_ms": _rounded(_render_gpu_ms),
		"draw_calls": _rounded(_draw_calls),
		"objects": _rounded(_objects),
		"primitives": _rounded(_primitives),
		"sample_enemies": _rounded(_sample_enemies),
		"sample_units": _rounded(_sample_units),
		"sample_arrows": _rounded(_sample_arrows),
	}


func _header() -> Dictionary:
	var window: Vector2i = DisplayServer.window_get_size()
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	return {
		"run": _args["run"],
		"duration_s": _args["duration"],
		"warmup_s": _args["warmup"],
		"godot": Engine.get_version_info().get("string", "?"),
		"gpu": RenderingServer.get_video_adapter_name(),
		"gpu_vendor": RenderingServer.get_video_adapter_vendor(),
		"gpu_api": RenderingServer.get_video_adapter_api_version(),
		"cpu": OS.get_processor_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"driver": RenderingServer.get_current_rendering_driver_name(),
		"requested_size": [REQUESTED_SIZE.x, REQUESTED_SIZE.y],
		"window_size": [window.x, window.y],
		"viewport_size": [int(viewport.x), int(viewport.y)],
		"vsync": _vsync_name(DisplayServer.window_get_vsync_mode()),
		"max_fps": Engine.max_fps,
		"speed": Engine.time_scale,
		"camera_y": snappedf(_camera.global_position.y, ROUND_STEP),
		"spawned_at_start": _spawned_at_start,
		"night_total": _ctx.night.total_count(),
		"tick_count": _ctx.tick_count,
	}


static func _vsync_name(mode: int) -> String:
	match mode:
		DisplayServer.VSYNC_DISABLED:
			return "off"
		DisplayServer.VSYNC_ENABLED:
			return "on"
		DisplayServer.VSYNC_ADAPTIVE:
			return "adaptive"
		DisplayServer.VSYNC_MAILBOX:
			return "mailbox"
	return "unknown"


## `values` as a plain Array of floats rounded to a microsecond-scale step, for JSON.
static func _rounded(values: PackedFloat64Array) -> Array:
	var out: Array = []
	for value: float in values:
		out.append(snappedf(value, ROUND_STEP))
	return out
