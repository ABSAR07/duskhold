extends GutTest
## KingDef data contract (KING-01): speeds, acceleration and turning come from king.tres.
## The owner raised the sprint to 12 m/s at the round-1 playtest (UAT G-02-1, 2026-10-06) and on
## 2026-10-07 (UAT G-02-18) made the walk 1.5 times faster, 7.5 m/s, keeping the sprint at exactly
## 12 m/s, so the multiplier is 1.6, which is the source game's walk/sprint ratio again. The
## acceleration, which is also the braking rate, stays 60 so a king who lets go at full sprint
## still stops inside the build radius.

const KING_DEF_PATH := "res://data/king/king.tres"
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
const OWNER_WALK_SPEED: float = 7.5
const OWNER_SPRINT_MULTIPLIER: float = 1.6
const OWNER_SPRINT_SPEED: float = 12.0
const ORIGINAL_SPRINT_SPEED: float = 8.0
const OWNER_ACCELERATION: float = 60.0

var _def: KingDef


func before_each() -> void:
	_def = load(KING_DEF_PATH)


func test_walk_speed_is_seven_and_a_half_metres_per_second() -> void:
	assert_eq(
		_def.walk_speed,
		OWNER_WALK_SPEED,
		"the owner's walk, 1.5x the round-3 walk, feeds the ride-time budget of D-03 as amended"
	)


func test_sprint_is_at_least_one_and_a_half_times_the_original_sprint() -> void:
	assert_eq(_def.sprint_multiplier, OWNER_SPRINT_MULTIPLIER, "sprint multiplier is 1.6")
	assert_gte(
		King.move_speed(_def, true),
		1.5 * ORIGINAL_SPRINT_SPEED,
		"the sprint is at least 1.5 times the 8 m/s the owner played"
	)


func test_the_sprint_stays_exactly_twelve_metres_per_second() -> void:
	assert_eq(
		King.move_speed(_def, true),
		OWNER_SPRINT_SPEED,
		"the owner kept the sprint at 12 m/s when the walk went to 7.5; 7.5 x 1.6 is exactly 12.0"
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


func test_the_script_defaults_are_the_shipped_movement() -> void:
	var fresh: KingDef = KingDef.new()
	assert_eq(
		fresh.walk_speed,
		_def.walk_speed,
		"the script default and its doc comment describe the shipped walk"
	)
	assert_eq(
		fresh.sprint_multiplier,
		_def.sprint_multiplier,
		"the script default and its doc comment describe the shipped sprint multiplier"
	)
	assert_eq(
		fresh.acceleration,
		_def.acceleration,
		"the script default and its doc comment describe the shipped acceleration"
	)


func test_move_speed_walks_at_walk_speed() -> void:
	assert_eq(King.move_speed(_def, false), _def.walk_speed, "walking uses walk_speed")


func test_move_speed_sprints_at_walk_speed_times_multiplier() -> void:
	var expected: float = _def.walk_speed * _def.sprint_multiplier
	assert_almost_eq(King.move_speed(_def, true), expected, 0.0001, "sprinting multiplies")
