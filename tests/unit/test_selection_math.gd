extends GutTest
## UNIT-09, D-10: pure click picking. A click within CLICK_RADIUS_PX of a unit point picks that
## unit's squad; the radius is inclusive; equally near squads go to the one created first.

const RADIUS: float = 32.0
const CLICK := Vector2(500.0, 300.0)


func _points(first: Array[Vector2], second: Array[Vector2] = []) -> Dictionary:
	var by_squad: Dictionary = {}
	by_squad[&"barracks_1"] = PackedVector2Array(first)
	by_squad[&"archery_1"] = PackedVector2Array(second)
	return by_squad


func test_the_controller_radius_is_32_pixels() -> void:
	assert_eq(SelectionController.CLICK_RADIUS_PX, 32.0, "UI-SPEC click select")


func test_a_point_exactly_32_px_away_hits() -> void:
	var by_squad: Dictionary = _points([CLICK + Vector2(32.0, 0.0)] as Array[Vector2])
	assert_eq(SelectionMath.nearest_squad_at(by_squad, CLICK, RADIUS), &"barracks_1", "inclusive")


func test_a_point_at_32_01_px_misses() -> void:
	var by_squad: Dictionary = _points([CLICK + Vector2(32.01, 0.0)] as Array[Vector2])
	assert_eq(SelectionMath.nearest_squad_at(by_squad, CLICK, RADIUS), &"", "just outside")


func test_the_nearer_squad_wins() -> void:
	var by_squad: Dictionary = _points(
		[CLICK + Vector2(20.0, 0.0)] as Array[Vector2],
		[CLICK + Vector2(5.0, 0.0)] as Array[Vector2]
	)
	assert_eq(SelectionMath.nearest_squad_at(by_squad, CLICK, RADIUS), &"archery_1", "nearer")


func test_equally_near_units_of_two_squads_go_to_the_squad_created_first() -> void:
	var by_squad: Dictionary = _points(
		[CLICK + Vector2(10.0, 0.0)] as Array[Vector2],
		[CLICK + Vector2(0.0, 10.0)] as Array[Vector2]
	)
	assert_eq(
		SelectionMath.nearest_squad_at(by_squad, CLICK, RADIUS), &"barracks_1", "created first"
	)


func test_any_unit_of_a_squad_can_be_the_one_hit() -> void:
	var by_squad: Dictionary = _points(
		[CLICK + Vector2(200.0, 0.0), CLICK + Vector2(-20.0, 0.0)] as Array[Vector2]
	)
	assert_eq(SelectionMath.nearest_squad_at(by_squad, CLICK, RADIUS), &"barracks_1", "second unit")


func test_an_empty_dictionary_returns_nothing() -> void:
	assert_eq(SelectionMath.nearest_squad_at({}, CLICK, RADIUS), &"", "no squads")


func test_a_squad_with_no_visible_units_is_never_hit() -> void:
	var by_squad: Dictionary = _points([] as Array[Vector2], [CLICK] as Array[Vector2])
	assert_eq(SelectionMath.nearest_squad_at(by_squad, CLICK, RADIUS), &"archery_1", "the other")


func test_the_drag_threshold_is_eight_pixels() -> void:
	assert_eq(SelectionController.DRAG_THRESHOLD_PX, 8.0, "UI-SPEC drag box")


func test_squads_in_rect_returns_every_squad_with_a_unit_inside_in_creation_order() -> void:
	var by_squad: Dictionary = _points(
		[Vector2(300.0, 300.0), Vector2(900.0, 900.0)] as Array[Vector2],
		[Vector2(320.0, 310.0)] as Array[Vector2]
	)
	var hit: Array[StringName] = SelectionMath.squads_in_rect(
		by_squad, Rect2(Vector2(250.0, 250.0), Vector2(100.0, 100.0))
	)
	assert_eq(hit, [&"barracks_1", &"archery_1"] as Array[StringName], "both, created order")


func test_one_unit_inside_is_enough_and_a_squad_wholly_outside_is_left_out() -> void:
	var by_squad: Dictionary = _points(
		[Vector2(10.0, 10.0), Vector2(900.0, 900.0)] as Array[Vector2],
		[Vector2(800.0, 800.0)] as Array[Vector2]
	)
	var hit: Array[StringName] = SelectionMath.squads_in_rect(
		by_squad, Rect2(Vector2.ZERO, Vector2(100.0, 100.0))
	)
	assert_eq(hit, [&"barracks_1"] as Array[StringName], "only the squad with a unit inside")


func test_an_empty_rectangle_over_no_unit_selects_nothing() -> void:
	var by_squad: Dictionary = _points([Vector2(300.0, 300.0)] as Array[Vector2])
	var hit: Array[StringName] = SelectionMath.squads_in_rect(
		by_squad, Rect2(Vector2(10.0, 10.0), Vector2.ZERO)
	)
	assert_true(hit.is_empty(), "a zero-size rectangle away from every unit")
	assert_true(
		SelectionMath.squads_in_rect({}, Rect2(0.0, 0.0, 50.0, 50.0)).is_empty(), "no squads"
	)


func test_a_rectangle_given_with_its_corners_reversed_selects_the_same_squads() -> void:
	var by_squad: Dictionary = _points([Vector2(300.0, 300.0)] as Array[Vector2])
	var reversed: Rect2 = Rect2(Vector2(350.0, 350.0), Vector2(-100.0, -100.0))
	var hit: Array[StringName] = SelectionMath.squads_in_rect(by_squad, reversed)
	assert_eq(hit, [&"barracks_1"] as Array[StringName], "negative size is normalised")


func test_a_unit_exactly_on_an_edge_counts_as_inside() -> void:
	var by_squad: Dictionary = _points(
		[Vector2(100.0, 50.0)] as Array[Vector2], [Vector2(0.0, 0.0)] as Array[Vector2]
	)
	var hit: Array[StringName] = SelectionMath.squads_in_rect(
		by_squad, Rect2(Vector2.ZERO, Vector2(100.0, 100.0))
	)
	assert_eq(hit, [&"barracks_1", &"archery_1"] as Array[StringName], "edges are included")
