extends GutTest
## KING-02 / G-01-3 proof, driven through the real Input Map on the prototype map: zoom_in and
## zoom_out slide the follow camera along its fixed angle between zoom_min and zoom_max, the angle
## never changes, real key and stick events zoom (a sub-deadzone stick does not), and zooming is
## presentation only. Every expected number comes from the rig's exports, never a literal.

const SETTLE_S: float = 1.0
const RAY_TOLERANCE: float = 0.001
const POSITION_TOLERANCE: float = 0.1
const SUB_DEADZONE_STICK: float = 0.2
const FULL_STICK: float = 1.0
const INPUT_FRAMES: int = 6


func after_each() -> void:
	E2eSupport.release_all_actions()
	_send_key(KEY_MINUS, false)
	_send_stick(0.0)


func _rig(map_root: MapRoot) -> CameraRig:
	return map_root.get_node("CameraRig") as CameraRig


func _send_key(keycode: Key, pressed: bool) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)


func _send_stick(value: float) -> void:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_RIGHT_Y
	event.axis_value = value
	Input.parse_input_event(event)


## Holds `action` for `seconds` of physics time and returns the (min, max) zoom sampled each frame.
func _hold_sampling(rig: CameraRig, action: StringName, seconds: float) -> Vector2:
	var lowest: float = rig.get_zoom()
	var highest: float = rig.get_zoom()
	Input.action_press(action)
	var started: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < roundi(seconds * 1000.0):
		await wait_physics_frames(1)
		lowest = minf(lowest, rig.get_zoom())
		highest = maxf(highest, rig.get_zoom())
	Input.action_release(action)
	return Vector2(lowest, highest)


func _full_sweep_seconds(rig: CameraRig, from_zoom: float, to_zoom: float) -> float:
	return absf(to_zoom - from_zoom) / rig.zoom_speed + 0.5


func test_the_camera_starts_at_the_default_zoom_on_king_plus_effective_offset() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var rig: CameraRig = _rig(map_root)
	var camera: Camera3D = get_viewport().get_camera_3d()
	assert_eq(rig.get_zoom(), 1.0, "the run starts unzoomed")
	var expected: Vector3 = map_root.get_king().global_position + rig.get_effective_offset()
	assert_lt(camera.global_position.distance_to(expected), POSITION_TOLERANCE, "king + offset")


func test_holding_zoom_out_stops_at_zoom_max() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var rig: CameraRig = _rig(map_root)
	var seconds: float = _full_sweep_seconds(rig, 1.0, rig.zoom_max)
	var sampled: Vector2 = await _hold_sampling(rig, &"zoom_out", seconds)
	assert_almost_eq(rig.get_zoom(), rig.zoom_max, 0.0001, "it reaches zoom_max")
	assert_lte(sampled.y, rig.zoom_max, "it never reads above zoom_max")


func test_holding_zoom_in_stops_at_zoom_min() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var rig: CameraRig = _rig(map_root)
	await _hold_sampling(rig, &"zoom_out", _full_sweep_seconds(rig, 1.0, rig.zoom_max))
	var seconds: float = _full_sweep_seconds(rig, rig.zoom_max, rig.zoom_min)
	var sampled: Vector2 = await _hold_sampling(rig, &"zoom_in", seconds)
	assert_almost_eq(rig.get_zoom(), rig.zoom_min, 0.0001, "it reaches zoom_min")
	assert_gte(sampled.x, rig.zoom_min, "it never reads below zoom_min")


func test_the_camera_stays_on_the_fixed_ray_at_the_effective_offset() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var rig: CameraRig = _rig(map_root)
	var camera: Camera3D = get_viewport().get_camera_3d()
	await _hold_sampling(rig, &"zoom_out", _full_sweep_seconds(rig, 1.0, rig.zoom_max))
	await wait_seconds(SETTLE_S)
	var from_king: Vector3 = camera.global_position - map_root.get_king().global_position
	assert_lt(
		from_king.distance_to(rig.get_effective_offset()), POSITION_TOLERANCE, "zoomed offset"
	)
	assert_true(
		rig.get_effective_offset().is_equal_approx(rig.offset * rig.get_zoom()), "offset times zoom"
	)
	assert_lt(
		from_king.normalized().distance_to(rig.offset.normalized()), RAY_TOLERANCE, "same ray"
	)


func test_the_camera_angle_never_changes_while_zooming() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var rig: CameraRig = _rig(map_root)
	var camera: Camera3D = get_viewport().get_camera_3d()
	var initial_basis: Basis = camera.global_basis
	await _hold_sampling(rig, &"zoom_out", _full_sweep_seconds(rig, 1.0, rig.zoom_max))
	await _hold_sampling(rig, &"zoom_in", _full_sweep_seconds(rig, rig.zoom_max, rig.zoom_min))
	await wait_seconds(SETTLE_S)
	assert_true(camera.global_basis.is_equal_approx(initial_basis), "the angle is unchanged")


func test_a_real_minus_key_press_zooms_out() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var rig: CameraRig = _rig(map_root)
	_send_key(KEY_MINUS, true)
	await wait_physics_frames(INPUT_FRAMES)
	_send_key(KEY_MINUS, false)
	assert_gt(rig.get_zoom(), 1.0, "the - key raised the zoom")


func test_a_real_right_stick_push_down_zooms_out_and_below_the_deadzone_does_nothing() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var rig: CameraRig = _rig(map_root)
	_send_stick(SUB_DEADZONE_STICK)
	await wait_physics_frames(INPUT_FRAMES)
	assert_eq(rig.get_zoom(), 1.0, "a stick push inside the deadzone leaves the zoom alone")
	_send_stick(FULL_STICK)
	await wait_physics_frames(INPUT_FRAMES)
	_send_stick(0.0)
	assert_gt(rig.get_zoom(), 1.0, "right stick down raised the zoom")


func test_zooming_changes_no_gold_phase_or_building_and_emits_no_signal() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var rig: CameraRig = _rig(map_root)
	var ctx: RunContext = map_root.get_context()
	var gold: int = ctx.economy.get_gold()
	var phase: int = ctx.run_manager.get_phase()
	var tiers: Dictionary = {}
	for spot_id: StringName in ctx.buildings.spot_ids():
		tiers[spot_id] = ctx.buildings.current_tier(spot_id)
	watch_signals(ctx.events)
	await _hold_sampling(rig, &"zoom_out", _full_sweep_seconds(rig, 1.0, rig.zoom_max))
	await _hold_sampling(rig, &"zoom_in", _full_sweep_seconds(rig, rig.zoom_max, rig.zoom_min))
	assert_eq(ctx.economy.get_gold(), gold, "gold is unchanged")
	assert_eq(ctx.run_manager.get_phase(), phase, "the phase is unchanged")
	for spot_id: StringName in tiers:
		assert_eq(ctx.buildings.current_tier(spot_id), tiers[spot_id], "tier of %s" % spot_id)
	for signal_name: String in SimSignals.ALL:
		assert_signal_not_emitted(ctx.events, signal_name)
