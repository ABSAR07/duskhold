extends GutTest
## KING-01 / KING-02 proof, driven through real input on the prototype map (headless display):
## riding reaches a build spot in time, sprint is about 1.6x, diagonals are not faster, the
## deadzone is respected, the king turns to face its heading, and the camera is a detached,
## smoothed, fixed-angle follow rig whose rotation never changes.

const MAP_SCENE_PATH := "res://presentation/map/prototype_map.tscn"
const KING_DEF_PATH := "res://data/king/king.tres"
const RIDE_MARGIN_S: float = 1.5
const SPRINT_TOLERANCE: float = 0.15
const CAMERA_XZ_TOLERANCE: float = 0.5
const TELEPORT_DISTANCE: float = 25.0

var _def: KingDef


func before_each() -> void:
	_def = load(KING_DEF_PATH)


func after_each() -> void:
	E2eSupport.release_all_actions()


func _start_map() -> MapRoot:
	var scene: PackedScene = load(MAP_SCENE_PATH)
	var map_root: MapRoot = add_child_autofree(scene.instantiate())
	await wait_process_frames(2)
	return map_root


func _xz(pos: Vector3) -> Vector2:
	return Vector2(pos.x, pos.z)


## Rides in `action` for `seconds` (optionally sprinting) and returns the distance covered.
func _ride_distance(map_root: MapRoot, action: StringName, seconds: float, sprint: bool) -> float:
	var king: King = map_root.get_king()
	king.velocity = Vector3.ZERO
	E2eSupport.teleport_king(map_root, map_root.get_context().map.king_spawn)
	await wait_physics_frames(1)
	var start: Vector2 = _xz(king.global_position)
	Input.action_press(action)
	if sprint:
		Input.action_press(&"sprint")
	await wait_seconds(seconds)
	E2eSupport.release_all_actions()
	return _xz(king.global_position).distance_to(start)


func test_ride_reaches_the_first_spot_within_the_walk_time_budget() -> void:
	var map_root: MapRoot = await _start_map()
	var ctx: RunContext = map_root.get_context()
	var spot_id: StringName = ctx.buildings.spot_ids()[0]
	var spot_xz: Vector2 = _xz(ctx.buildings.get_spot(spot_id).position)
	var distance: float = _xz(map_root.get_king().global_position).distance_to(spot_xz)
	var budget_s: float = distance / _def.walk_speed + RIDE_MARGIN_S
	var arrived: bool = await E2eSupport.ride_until_focused(self, map_root, spot_id, budget_s)
	assert_true(arrived, "the king reached the spot's build range within %.1f s" % budget_s)


func test_sprint_covers_about_the_sprint_multiplier_more_ground() -> void:
	var map_root: MapRoot = await _start_map()
	var walked: float = await _ride_distance(map_root, &"move_right", 1.0, false)
	var sprinted: float = await _ride_distance(map_root, &"move_right", 1.0, true)
	assert_gt(walked, 0.0, "the king moved while walking")
	var ratio: float = sprinted / walked
	var expected: float = _def.sprint_multiplier
	assert_almost_eq(ratio, expected, expected * SPRINT_TOLERANCE, "sprint/walk distance ratio")


func test_velocity_ramps_up_instead_of_jumping_to_full_speed() -> void:
	var map_root: MapRoot = await _start_map()
	var king: King = map_root.get_king()
	Input.action_press(&"move_right")
	await wait_physics_frames(1)
	var speed: float = Vector2(king.velocity.x, king.velocity.z).length()
	assert_gt(speed, 0.0, "the king starts moving")
	assert_lt(speed, _def.walk_speed, "the king has not reached full speed after one physics step")


func test_diagonal_input_is_not_faster_than_cardinal() -> void:
	var map_root: MapRoot = await _start_map()
	var king: King = map_root.get_king()
	Input.action_press(&"move_right")
	Input.action_press(&"move_forward")
	await wait_seconds(0.6)
	var speed: float = Vector2(king.velocity.x, king.velocity.z).length()
	assert_almost_eq(speed, _def.walk_speed, 0.05, "diagonal speed equals walk speed")


func test_stick_input_below_the_deadzone_does_not_move_the_king() -> void:
	var map_root: MapRoot = await _start_map()
	var king: King = map_root.get_king()
	var start: Vector3 = king.global_position
	Input.action_press(&"move_right", 0.1)
	await wait_seconds(0.4)
	assert_almost_eq(king.global_position.x, start.x, 0.001, "no drift from sub-deadzone input")


func test_model_turns_to_face_the_ride_direction_and_the_body_does_not() -> void:
	var map_root: MapRoot = await _start_map()
	var king: King = map_root.get_king()
	var model: Node3D = king.get_node("Model")
	Input.action_press(&"move_right")
	await wait_seconds(0.6)
	assert_almost_eq(model.rotation.y, PI / 2.0, 0.1, "the model faces +X while riding right")
	assert_eq(king.rotation, Vector3.ZERO, "the CharacterBody3D root never rotates")


func test_camera_is_a_detached_rig_and_not_a_child_of_the_king() -> void:
	var map_root: MapRoot = await _start_map()
	var rig: Node = map_root.get_node_or_null("CameraRig")
	assert_not_null(rig, "the map has a CameraRig")
	var camera: Camera3D = get_viewport().get_camera_3d()
	assert_not_null(camera, "a camera is active")
	assert_false(map_root.get_king().is_ancestor_of(camera), "the camera does not ride on the king")


func test_camera_rotation_never_changes_while_riding_in_all_directions() -> void:
	await _start_map()
	var camera: Camera3D = get_viewport().get_camera_3d()
	assert_not_null(camera, "a camera is active")
	var initial_basis: Basis = camera.global_basis
	for action: StringName in E2eSupport.MOVE_ACTIONS:
		Input.action_press(action)
		await wait_seconds(2.0)
		E2eSupport.release_all_actions()
		assert_true(camera.global_basis.is_equal_approx(initial_basis), "basis after %s" % action)


func test_camera_settles_at_the_rig_offset_when_the_king_stands_still() -> void:
	var map_root: MapRoot = await _start_map()
	var rig: Node = map_root.get_node_or_null("CameraRig")
	assert_not_null(rig, "the map has a CameraRig")
	if rig == null:
		return
	var offset: Vector3 = rig.get(&"offset")
	var camera: Camera3D = get_viewport().get_camera_3d()
	await wait_seconds(1.0)
	var king_xz: Vector2 = _xz(map_root.get_king().global_position)
	var expected: Vector2 = king_xz + Vector2(offset.x, offset.z)
	var actual: Vector2 = _xz(camera.global_position)
	assert_lt(actual.distance_to(expected), CAMERA_XZ_TOLERANCE, "camera is at king + offset")


func test_camera_trails_a_sudden_king_jump_and_then_catches_up() -> void:
	var map_root: MapRoot = await _start_map()
	var rig: Node = map_root.get_node_or_null("CameraRig")
	assert_not_null(rig, "the map has a CameraRig")
	if rig == null:
		return
	var offset: Vector3 = rig.get(&"offset")
	var camera: Camera3D = get_viewport().get_camera_3d()
	var king: King = map_root.get_king()
	E2eSupport.teleport_king(map_root, king.global_position + Vector3(TELEPORT_DISTANCE, 0, 0))
	await wait_physics_frames(1)
	var target: Vector2 = _xz(king.global_position) + Vector2(offset.x, offset.z)
	assert_gt(_xz(camera.global_position).distance_to(target), 1.0, "the camera lags the jump")
	await wait_seconds(2.0)
	assert_lt(_xz(camera.global_position).distance_to(target), CAMERA_XZ_TOLERANCE, "it catches up")
