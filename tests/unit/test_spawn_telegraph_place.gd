extends GutTest
## LOOP-02: where a spawn marker goes on the screen. SpawnTelegraph.place is a pure function of the
## projected point, whether it is behind the camera, the viewport and the edge margin; markers_for
## is a pure function of the map and the night number.

const VIEWPORT := Rect2(0.0, 0.0, 1152.0, 648.0)
const MARGIN: float = 48.0
const CENTRE := Vector2(576.0, 324.0)
const EPSILON: float = 0.01
## The inset rectangle: the viewport shrunk by MARGIN on every side.
const INSET_LEFT: float = 48.0
const INSET_TOP: float = 48.0
const INSET_RIGHT: float = 1104.0
const INSET_BOTTOM: float = 600.0


func _place(projected: Vector2, behind: bool = false) -> Dictionary:
	return SpawnTelegraph.place(projected, behind, VIEWPORT, MARGIN)


func _assert_inside_inset(position: Vector2, label: String) -> void:
	assert_between(position.x, INSET_LEFT - EPSILON, INSET_RIGHT + EPSILON, "%s: x" % label)
	assert_between(position.y, INSET_TOP - EPSILON, INSET_BOTTOM + EPSILON, "%s: y" % label)


func test_a_point_inside_the_inset_is_returned_unchanged_and_on_screen() -> void:
	var placed: Dictionary = _place(Vector2(300.0, 200.0))

	assert_true(placed["on_screen"], "inside the inset rectangle")
	assert_eq(placed["position"], Vector2(300.0, 200.0), "not moved")


func test_a_point_exactly_on_the_inset_edge_counts_as_on_screen() -> void:
	for edge_point: Vector2 in [
		Vector2(INSET_RIGHT, CENTRE.y),
		Vector2(INSET_LEFT, CENTRE.y),
		Vector2(CENTRE.x, INSET_TOP),
		Vector2(CENTRE.x, INSET_BOTTOM),
		Vector2(INSET_LEFT, INSET_TOP),
		Vector2(INSET_RIGHT, INSET_BOTTOM),
	]:
		var placed: Dictionary = _place(edge_point)
		assert_true(placed["on_screen"], "the edge is inclusive: %s" % edge_point)
		assert_eq(placed["position"], edge_point, "and stays where it is: %s" % edge_point)


func test_a_point_one_pixel_past_the_right_edge_is_clamped_onto_it_with_an_arrow() -> void:
	var placed: Dictionary = _place(Vector2(INSET_RIGHT + 1.0, CENTRE.y))

	assert_false(placed["on_screen"], "one pixel outside is off screen")
	var position: Vector2 = placed["position"]
	assert_almost_eq(position.x, INSET_RIGHT, EPSILON, "pulled back onto the right edge")
	assert_almost_eq(position.y, CENTRE.y, EPSILON, "level with the centre")
	assert_almost_eq(float(placed["angle"]), 0.0, EPSILON, "the arrow points right")


func test_a_point_one_pixel_past_each_other_edge_points_that_way() -> void:
	var left: Dictionary = _place(Vector2(INSET_LEFT - 1.0, CENTRE.y))
	var below: Dictionary = _place(Vector2(CENTRE.x, INSET_BOTTOM + 1.0))
	var above: Dictionary = _place(Vector2(CENTRE.x, INSET_TOP - 1.0))

	assert_false(left["on_screen"], "left is off screen")
	assert_almost_eq(absf(float(left["angle"])), PI, EPSILON, "the arrow points left")
	assert_almost_eq((left["position"] as Vector2).x, INSET_LEFT, EPSILON, "on the left edge")
	assert_false(below["on_screen"], "below is off screen")
	assert_almost_eq(float(below["angle"]), PI / 2.0, EPSILON, "screen y grows downward")
	assert_almost_eq((below["position"] as Vector2).y, INSET_BOTTOM, EPSILON, "on the bottom edge")
	assert_false(above["on_screen"], "above is off screen")
	assert_almost_eq(float(above["angle"]), -PI / 2.0, EPSILON, "the arrow points up")
	assert_almost_eq((above["position"] as Vector2).y, INSET_TOP, EPSILON, "on the top edge")


func test_a_far_diagonal_point_lands_on_the_edge_on_the_line_to_it() -> void:
	var far: Vector2 = Vector2(5000.0, 4000.0)

	var placed: Dictionary = _place(far)

	assert_false(placed["on_screen"], "far away is off screen")
	_assert_inside_inset(placed["position"], "far diagonal")
	var toward: Vector2 = far - CENTRE
	assert_almost_eq(float(placed["angle"]), toward.angle(), 0.0001, "the arrow points at it")
	var position: Vector2 = placed["position"]
	var on_a_side: bool = (
		absf(position.x - INSET_RIGHT) < EPSILON or absf(position.y - INSET_BOTTOM) < EPSILON
	)
	assert_true(on_a_side, "the marker sits on the inset rectangle's edge, not inside it")
	var along: Vector2 = (position - CENTRE).normalized()
	assert_almost_eq(along.dot(toward.normalized()), 1.0, 0.0001, "on the line from the centre")


func test_a_point_behind_the_camera_is_mirrored_before_clamping() -> void:
	# unproject_position puts a point behind the camera on the opposite side of the screen, so the
	# true direction is the mirror image through the centre: x = 300 mirrors to 852.
	var placed: Dictionary = _place(Vector2(300.0, CENTRE.y), true)

	assert_false(placed["on_screen"], "a point behind the camera is never on screen")
	var position: Vector2 = placed["position"]
	assert_almost_eq(position.x, INSET_RIGHT, EPSILON, "pushed out to the right edge it mirrors to")
	assert_almost_eq(position.y, CENTRE.y, EPSILON, "level with the centre")
	assert_almost_eq(float(placed["angle"]), 0.0, EPSILON, "the arrow points the mirrored way")


func test_a_point_exactly_behind_the_screen_centre_still_gets_a_finite_edge_position() -> void:
	var placed: Dictionary = _place(CENTRE, true)

	assert_false(placed["on_screen"], "behind the camera")
	var position: Vector2 = placed["position"]
	assert_true(is_finite(position.x) and is_finite(position.y), "no NaN from a zero direction")
	_assert_inside_inset(position, "behind the centre")
	assert_true(is_finite(float(placed["angle"])), "a defined angle")


func test_every_placed_point_ends_inside_the_inset_rectangle() -> void:
	for x: float in [-4000.0, -10.0, 0.0, 47.0, 576.0, 1105.0, 1152.0, 9000.0]:
		for y: float in [-4000.0, -10.0, 0.0, 47.0, 324.0, 601.0, 648.0, 9000.0]:
			for behind: bool in [false, true]:
				var placed: Dictionary = _place(Vector2(x, y), behind)
				_assert_inside_inset(placed["position"], "(%s, %s) behind %s" % [x, y, behind])


func test_markers_for_night_one_has_the_west_spawn_with_its_count() -> void:
	var map: MapConfig = E2eSupport.shipped_prototype_map()

	var markers: Array = SpawnTelegraph.markers_for(map, 1)

	assert_eq(markers.size(), 1, "one spawn point is used on night one")
	var marker: Dictionary = markers[0]
	assert_eq(marker["spawn_point_id"], &"west", "the west road")
	assert_eq(marker["count"], WaveSchedule.preview_counts(map, 1)[&"west"], "its night count")
	assert_eq(
		marker["world_position"], map.find_spawn_point(&"west").position, "at the spawn point"
	)


func test_markers_for_follow_map_order_and_are_the_same_on_every_call() -> void:
	var map: MapConfig = E2eSupport.shipped_prototype_map()

	var first: Array = SpawnTelegraph.markers_for(map, 3)
	var second: Array = SpawnTelegraph.markers_for(map, 3)

	assert_eq(first.size(), 2, "night three uses two spawn points")
	assert_eq(first[0]["spawn_point_id"], &"west", "west first")
	assert_eq(first[1]["spawn_point_id"], &"east", "then east")
	assert_eq(first, second, "identical on every call")


func test_markers_for_a_night_past_the_last_and_for_a_waveless_map_are_empty() -> void:
	var map: MapConfig = E2eSupport.shipped_prototype_map()

	assert_eq(SpawnTelegraph.markers_for(map, map.nights.size() + 1), [], "past the last night")
	assert_eq(
		SpawnTelegraph.markers_for(E2eSupport.waveless_prototype_map(), 1), [], "no authored nights"
	)


func test_the_edge_margin_is_kept_on_a_real_window_and_shrinks_on_a_tiny_one() -> void:
	assert_eq(SpawnTelegraph.edge_margin(VIEWPORT), SpawnTelegraph.EDGE_MARGIN_PX, "full margin")
	assert_eq(
		SpawnTelegraph.edge_margin(Rect2(0.0, 0.0, 64.0, 64.0)),
		16.0,
		"a quarter of the shorter side when 48 px would eat the screen"
	)
