extends GutTest
## KingDef data contract (KING-01): speeds, acceleration and turning come from king.tres.

const KING_DEF_PATH := "res://data/king/king.tres"
const SOURCE_WALK_SPEED: float = 5.0
const SOURCE_SPRINT_MULTIPLIER: float = 1.6

var _def: KingDef


func before_each() -> void:
	_def = load(KING_DEF_PATH)


func test_walk_speed_is_five_metres_per_second() -> void:
	assert_eq(_def.walk_speed, SOURCE_WALK_SPEED, "walk speed feeds the ride-time budget (D-03)")


func test_sprint_multiplier_matches_the_source_ratio() -> void:
	assert_eq(_def.sprint_multiplier, SOURCE_SPRINT_MULTIPLIER, "sprint multiplier is 1.6")
	assert_between(_def.sprint_multiplier, 1.4, 1.8, "sprint ratio stays near the source game's")


func test_acceleration_is_defined_and_positive() -> void:
	var acceleration: Variant = _def.get(&"acceleration")
	assert_true(acceleration is float, "KingDef exports a float acceleration")
	if acceleration is float:
		assert_gt(acceleration, 0.0, "acceleration is positive")


func test_turn_speed_is_defined_and_positive() -> void:
	var turn_speed: Variant = _def.get(&"turn_speed")
	assert_true(turn_speed is float, "KingDef exports a float turn_speed")
	if turn_speed is float:
		assert_gt(turn_speed, 0.0, "turn speed is positive")


func test_move_speed_walks_at_walk_speed() -> void:
	assert_eq(King.move_speed(_def, false), _def.walk_speed, "walking uses walk_speed")


func test_move_speed_sprints_at_walk_speed_times_multiplier() -> void:
	var expected: float = _def.walk_speed * _def.sprint_multiplier
	assert_almost_eq(King.move_speed(_def, true), expected, 0.0001, "sprinting multiplies")
