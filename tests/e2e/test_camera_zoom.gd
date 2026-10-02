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
const UAT_OFFSET := Vector3(0.0, 16.0, 11.0)
const MIN_DEFAULT_DISTANCE_RATIO: float = 1.25
const MAX_DEFAULT_DISTANCE_RATIO: float = 1.5
const BESIDE_SPOT := Vector3(0.5, 0.0, 0.0)
const CAMERA_SETTLE_S: float = 1.2
const LABEL_SCALE_TOLERANCE: float = 0.02
const TITLE_HEIGHT_TOLERANCE: float = 0.1
const LABEL_SPOT := &"house_3"


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


## Holds `action` for `seconds` of physics time and returns [lowest, highest] zoom sampled each
## frame (an Array, not a Vector2, so the values keep double precision).
func _hold_sampling(rig: CameraRig, action: StringName, seconds: float) -> Array[float]:
	var lowest: float = rig.get_zoom()
	var highest: float = rig.get_zoom()
	Input.action_press(action)
	var started: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < roundi(seconds * 1000.0):
		await wait_physics_frames(1)
		lowest = minf(lowest, rig.get_zoom())
		highest = maxf(highest, rig.get_zoom())
	Input.action_release(action)
	return [lowest, highest]


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
	var sampled: Array[float] = await _hold_sampling(rig, &"zoom_out", seconds)
	assert_almost_eq(rig.get_zoom(), rig.zoom_max, 0.0001, "it reaches zoom_max")
	assert_lte(sampled[1], rig.zoom_max, "it never reads above zoom_max")


func test_holding_zoom_in_stops_at_zoom_min() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var rig: CameraRig = _rig(map_root)
	await _hold_sampling(rig, &"zoom_out", _full_sweep_seconds(rig, 1.0, rig.zoom_max))
	var seconds: float = _full_sweep_seconds(rig, rig.zoom_max, rig.zoom_min)
	var sampled: Array[float] = await _hold_sampling(rig, &"zoom_in", seconds)
	assert_almost_eq(rig.get_zoom(), rig.zoom_min, 0.0001, "it reaches zoom_min")
	assert_gte(sampled[0], rig.zoom_min, "it never reads below zoom_min")


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


func _stand_beside_label_spot(map_root: MapRoot) -> SpotLabel:
	var spot: Vector3 = map_root.get_context().buildings.get_spot(LABEL_SPOT).position
	E2eSupport.teleport_king(map_root, spot + BESIDE_SPOT)
	await wait_seconds(CAMERA_SETTLE_S)
	return map_root.get_node("SpotLabel") as SpotLabel


func _expected_label_scale(label: SpotLabel) -> float:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var distance: float = camera.global_position.distance_to(label.global_position)
	return maxf(1.0, distance / SpotLabel.LEGIBLE_CAMERA_DISTANCE)


## Pixel height of one metre-scaled-by-the-label's-scale at the Title, as the player sees it.
func _title_height_px(label: SpotLabel) -> float:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var title: Label3D = label.get_node("%Title") as Label3D
	var base: Vector2 = camera.unproject_position(title.global_position)
	var top: Vector3 = title.global_position + camera.global_basis.y * label.scale.y
	return base.distance_to(camera.unproject_position(top))


func test_the_default_offset_keeps_the_approved_angle_and_sits_further_out() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var rig: CameraRig = _rig(map_root)
	assert_lt(
		rig.offset.normalized().distance_to(UAT_OFFSET.normalized()), RAY_TOLERANCE, "same angle"
	)
	var ratio: float = rig.offset.length() / UAT_OFFSET.length()
	assert_gte(ratio, MIN_DEFAULT_DISTANCE_RATIO, "at least 1.25x the UAT distance")
	assert_lte(ratio, MAX_DEFAULT_DISTANCE_RATIO, "at most 1.5x the UAT distance")
	assert_lt(rig.zoom_min, 1.0, "zoom can go closer than the default")
	assert_gt(rig.zoom_max, 1.0, "zoom can go farther than the default")


func test_the_spot_label_scale_follows_the_camera_distance() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var rig: CameraRig = _rig(map_root)
	var label: SpotLabel = await _stand_beside_label_spot(map_root)
	assert_true(label.visible, "the label shows beside the spot")
	assert_almost_eq(label.scale.x, _expected_label_scale(label), LABEL_SCALE_TOLERANCE, "default")
	await _hold_sampling(rig, &"zoom_out", _full_sweep_seconds(rig, 1.0, rig.zoom_max))
	await wait_seconds(SETTLE_S)
	assert_almost_eq(
		label.scale.x, _expected_label_scale(label), LABEL_SCALE_TOLERANCE, "zoomed out"
	)
	assert_gte(label.scale.x, 1.0, "never below the approved size")


func test_the_title_keeps_its_on_screen_height_when_zoomed_all_the_way_out() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var rig: CameraRig = _rig(map_root)
	var label: SpotLabel = await _stand_beside_label_spot(map_root)
	var default_px: float = _title_height_px(label)
	await _hold_sampling(rig, &"zoom_out", _full_sweep_seconds(rig, 1.0, rig.zoom_max))
	await wait_seconds(SETTLE_S)
	var zoomed_px: float = _title_height_px(label)
	assert_gt(default_px, 0.0, "the title is on screen")
	assert_almost_eq(zoomed_px, default_px, default_px * TITLE_HEIGHT_TOLERANCE, "within 10%")
