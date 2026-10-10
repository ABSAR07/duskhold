extends GutTest
## UI-01 / RESEARCH Pitfall 7 and A9 (headless half): the project stretches the 1280x720 base with
## canvas_items and aspect expand, so the HUD, mouse positions, Camera3D.unproject_position and
## project_ray_* all live in one 1280x720-based space whatever the window size. The real-window half
## (1920x1080 and 16:10) is a plan 03-12 screenshot scenario.

const BASE_WIDTH: float = 1280.0
const ROUND_TRIP_TOLERANCE: float = 0.01
const SETTLE_FRAMES: int = 3
const GROUND_POINTS: Array[Vector3] = [
	Vector3(0.0, 0.0, 0.0),
	Vector3(3.0, 0.0, -2.0),
	Vector3(-4.5, 0.0, 1.5),
	Vector3(6.0, 0.0, 5.0),
]


func _ground_round_trip(camera: Camera3D, ground_point: Vector3) -> Vector3:
	var screen: Vector2 = camera.unproject_position(ground_point)
	var origin: Vector3 = camera.project_ray_origin(screen)
	var direction: Vector3 = camera.project_ray_normal(screen)
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)
	if hit == null:
		return Vector3.INF
	return hit as Vector3


func test_the_project_stretches_the_1280_base_with_canvas_items_and_expand() -> void:
	assert_eq(
		ProjectSettings.get_setting("display/window/stretch/mode"),
		"canvas_items",
		"canvas_items stretch"
	)
	assert_eq(
		ProjectSettings.get_setting("display/window/stretch/aspect"), "expand", "aspect expand"
	)
	assert_eq(
		float(ProjectSettings.get_setting("display/window/size/viewport_width")),
		BASE_WIDTH,
		"the base is 1280 wide"
	)


func test_the_visible_rect_is_1280_wide_in_the_real_scene() -> void:
	await E2eSupport.spawn_map(self)
	await wait_process_frames(SETTLE_FRAMES)
	assert_eq(get_viewport().get_visible_rect().size.x, BASE_WIDTH, "1280 px wide stretched space")


func test_a_ground_point_survives_the_unproject_and_ray_round_trip() -> void:
	await E2eSupport.spawn_map(self)
	await wait_process_frames(SETTLE_FRAMES)
	var camera: Camera3D = get_viewport().get_camera_3d()
	assert_not_null(camera, "the scene has a current camera")
	for ground_point: Vector3 in GROUND_POINTS:
		var back: Vector3 = _ground_round_trip(camera, ground_point)
		assert_lt(
			back.distance_to(ground_point), ROUND_TRIP_TOLERANCE, "round trip %s" % ground_point
		)
