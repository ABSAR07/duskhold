extends GutTest
## D-13, Pattern 6: a screen point becomes a ground point by a camera ray against the y = 0 plane,
## and a ground point becomes whole centimetres by roundi(x * 100.0) before it crosses into the
## simulation. The camera is the real rig's: perspective, fov 40, offset (0, 20.8, 14.3) from the
## king, looking down at him, in a 1280x720 SubViewport.

const VIEW_SIZE := Vector2i(1280, 720)
const CAMERA_AT := Vector3(0.0, 20.8, 14.3)
const FOV_DEGREES: float = 40.0
const ROUND_TRIP_TOLERANCE_M: float = 0.001
const PIXEL_TOLERANCE: float = 0.5
const CENTRE := Vector2(640.0, 360.0)
const CORNERS: Array[Vector2] = [
	Vector2(8.0, 8.0), Vector2(1272.0, 8.0), Vector2(8.0, 712.0), Vector2(1272.0, 712.0)
]
const EXTENT_M: float = 90.0

var _camera: Camera3D


func before_each() -> void:
	var view: SubViewport = SubViewport.new()
	view.size = VIEW_SIZE
	add_child_autofree(view)
	_camera = Camera3D.new()
	_camera.fov = FOV_DEGREES
	view.add_child(_camera)
	_camera.global_position = CAMERA_AT
	_camera.look_at(Vector3.ZERO, Vector3.UP)
	_camera.current = true


func test_a_ground_point_projected_and_picked_back_lands_within_a_millimetre() -> void:
	for ground: Vector3 in [
		Vector3.ZERO, Vector3(3.0, 0.0, -2.0), Vector3(-6.5, 0.0, 4.25), Vector3(9.0, 0.0, 7.0)
	]:
		var screen: Vector2 = _camera.unproject_position(ground)
		var picked: Variant = GroundPick.ground_point(_camera, screen)
		assert_not_null(picked, "%s is hit" % ground)
		if picked != null:
			assert_almost_eq(
				(picked as Vector3).distance_to(ground), 0.0, ROUND_TRIP_TOLERANCE_M, str(ground)
			)


func test_the_screen_centre_picks_the_point_the_camera_looks_at() -> void:
	var picked: Variant = GroundPick.ground_point(_camera, CENTRE)
	assert_not_null(picked, "the centre hits the ground")
	if picked != null:
		assert_almost_eq((picked as Vector3).distance_to(Vector3.ZERO), 0.0, 0.01, "at the origin")
		assert_eq((picked as Vector3).y, 0.0, "on the plane")


func test_each_corner_hits_the_ground_and_projects_back_to_the_same_pixel() -> void:
	for corner: Vector2 in CORNERS:
		var picked: Variant = GroundPick.ground_point(_camera, corner)
		assert_not_null(picked, "%s hits the ground" % corner)
		if picked != null:
			var back: Vector2 = _camera.unproject_position(picked as Vector3)
			assert_almost_eq(back.distance_to(corner), 0.0, PIXEL_TOLERANCE, str(corner))


func test_a_ray_that_cannot_reach_the_plane_returns_null() -> void:
	_camera.global_position = Vector3(0.0, 5.0, 0.0)
	_camera.look_at(Vector3(0.0, 30.0, -20.0), Vector3.UP)
	assert_null(
		GroundPick.ground_point(_camera, CENTRE), "a camera looking at the sky hits nothing"
	)
	_camera.global_position = Vector3(0.0, 5.0, 0.0)
	_camera.look_at(Vector3(40.0, 5.0, 0.0), Vector3.UP)
	assert_null(GroundPick.ground_point(_camera, CENTRE), "nor one looking along the horizon")


func test_to_centimetres_rounds_each_axis_once() -> void:
	assert_eq(GroundPick.to_centimetres(Vector3(12.34, 0.0, -5.67)), Vector2i(1234, -567), "ex")
	for ground: Vector3 in [
		Vector3(0.005, 0.0, -0.005),
		Vector3(-0.015, 0.0, 0.025),
		Vector3(-12.345, 0.0, 12.355),
		Vector3(89.999, 0.0, -90.004),
		Vector3.ZERO
	]:
		assert_eq(
			GroundPick.to_centimetres(ground),
			Vector2i(roundi(ground.x * 100.0), roundi(ground.z * 100.0)),
			str(ground)
		)


func test_to_centimetres_ignores_height() -> void:
	assert_eq(
		GroundPick.to_centimetres(Vector3(1.0, 7.0, 2.0)), Vector2i(100, 200), "y is not a command"
	)


func test_in_bounds_is_inclusive_at_the_extent_and_false_one_centimetre_beyond() -> void:
	var edge: int = roundi(EXTENT_M * 100.0)
	assert_true(GroundPick.in_bounds(Vector2i(edge, edge), EXTENT_M), "the corner is on the ground")
	assert_true(GroundPick.in_bounds(Vector2i(-edge, -edge), EXTENT_M), "so is the other corner")
	assert_true(GroundPick.in_bounds(Vector2i.ZERO, EXTENT_M), "and the middle")
	assert_false(GroundPick.in_bounds(Vector2i(edge + 1, 0), EXTENT_M), "1 cm beyond +x")
	assert_false(GroundPick.in_bounds(Vector2i(-edge - 1, 0), EXTENT_M), "1 cm beyond -x")
	assert_false(GroundPick.in_bounds(Vector2i(0, edge + 1), EXTENT_M), "1 cm beyond +z")
	assert_false(GroundPick.in_bounds(Vector2i(0, -edge - 1), EXTENT_M), "1 cm beyond -z")


func test_a_bad_extent_bounds_nothing() -> void:
	for bad: float in [0.0, -5.0, NAN, INF]:
		assert_false(GroundPick.in_bounds(Vector2i.ZERO, bad), "an extent of %s" % bad)
