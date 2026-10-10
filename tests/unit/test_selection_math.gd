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
