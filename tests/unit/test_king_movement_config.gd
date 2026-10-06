extends GutTest
## KingDef data contract (KING-01): speeds, acceleration and turning come from king.tres.
## The sprint is the owner's, not the source game's 1.6 ratio: at the Phase 2 playtest (UAT
## G-02-1, 2026-10-06) the owner asked for a sprint at least 1.5 times the 8 m/s they rode, so the
## multiplier is 2.4 (12 m/s at walk 5.0) and the acceleration, which is also the braking rate,
## is 60 so a king who lets go at full sprint still stops inside the build radius.

const KING_DEF_PATH := "res://data/king/king.tres"
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
const SOURCE_WALK_SPEED: float = 5.0
const OWNER_SPRINT_MULTIPLIER: float = 2.4
const ORIGINAL_SPRINT_SPEED: float = 8.0
const OWNER_ACCELERATION: float = 60.0

var _def: KingDef


func before_each() -> void:
	_def = load(KING_DEF_PATH)


func test_walk_speed_is_five_metres_per_second() -> void:
	assert_eq(_def.walk_speed, SOURCE_WALK_SPEED, "walk speed feeds the ride-time budget (D-03)")


func test_sprint_is_at_least_one_and_a_half_times_the_original_sprint() -> void:
	assert_eq(_def.sprint_multiplier, OWNER_SPRINT_MULTIPLIER, "sprint multiplier is 2.4")
	assert_gte(
		King.move_speed(_def, true),
		1.5 * ORIGINAL_SPRINT_SPEED,
		"the sprint is at least 1.5 times the 8 m/s the owner played"
	)


func test_a_king_letting_go_at_full_sprint_stops_inside_the_build_radius() -> void:
	var tuning: LoopTuning = load(TUNING_PATH)
	var speed: float = King.move_speed(_def, true)
	var stopping_distance: float = speed * speed / (2.0 * _def.acceleration)
	assert_lt(
		stopping_distance,
		tuning.interaction_radius,
		(
			"v^2 / (2 a) = %.2f m must stay under the %.1f m build radius"
			% [stopping_distance, tuning.interaction_radius]
		)
	)


func test_acceleration_is_defined_and_positive() -> void:
	var acceleration: Variant = _def.get(&"acceleration")
	assert_true(acceleration is float, "KingDef exports a float acceleration")
	if acceleration is float:
		assert_gt(acceleration, 0.0, "acceleration is positive")
		assert_eq(
			acceleration, OWNER_ACCELERATION, "acceleration is 60 m/s^2 (also the braking rate)"
		)


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
