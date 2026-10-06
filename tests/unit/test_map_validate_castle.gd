extends GutTest
## G-02-1 point 2 (T-02-33): MapConfig.validate() reports a castle attack that is meaningless
## (negative numbers) or would never shoot or shoot every tick (damage set with no range or no
## interval), and the shipped map pins the castle's design contract: three hits kill a grunt, two
## kill a skirmisher, and the castle reaches a skirmisher at its stand-off. Each bad case edits a
## deep copy and calls validate() directly, never through RunContext, whose push_error would fail
## the test. The contract test lives here because test_prototype_map_data.gd already holds gdlint's
## 20 public methods (as with test_map_validate_income.gd). The owner doubled the reach and raised
## the arrow speed 1.5x on 2026-10-07 (G-02-13); the other castle numbers are unchanged. A castle
## number that is not finite (INF, -INF, NaN) or an attacking castle whose interval is below one
## simulation step is reported too, since either would fire every tick or never (WR-02).

const SMOKE_FIXTURE := "res://tests/fixtures/fixture_map_replay_smoke.tres"
const BAD_DAMAGE: int = -1
const BAD_NUMBER: float = -1.0
## Slack the castle's reach keeps over a skirmisher's stand-off (castle radius plus its own range),
## so a skirmisher that stops a hair short still stands in reach.
const REACH_SLACK_M: float = 0.25
const GRUNT_SHOTS: int = 3
const SKIRMISHER_SHOTS: int = 2
const GRUNT_HEALTH: int = 6
const SHIPPED_INTERVAL_S: float = 1.5
## The owner's castle (G-02-13): 22 m reach, 27 m/s arrows, so an arrow at the edge of the reach
## flies 25 ticks, under the 45-tick interval.
const OWNER_RANGE_M: float = 22.0
const OWNER_SPEED_MPS: float = 27.0
const EDGE_FLIGHT_TICKS: int = 25
## The float fields that must be finite, and the values that are not.
const FINITE_FIELDS: Array[String] = [
	"castle_attack_range", "castle_attack_interval", "castle_projectile_speed"
]
const NOT_FINITE_VALUES: Array[float] = [INF, -INF, NAN]
const SUB_STEP_INTERVAL_S: float = 0.001


func _map() -> MapConfig:
	return E2eSupport.shipped_prototype_map()


## Asserts validate() reports exactly one error and that it contains `needle`.
func _assert_one_error(map: MapConfig, needle: String, label: String) -> void:
	var errors: PackedStringArray = map.validate()
	assert_eq(errors.size(), 1, "%s reports exactly one error: %s" % [label, errors])
	if errors.size() == 1:
		assert_string_contains(errors[0], needle, "%s names the item" % label)


## Whole shots needed to bring `health` down with `damage` per shot.
func _shots_to_kill(health: int, damage: int) -> int:
	return ceili(float(health) / float(damage))


func test_the_shipped_map_and_the_smoke_fixture_report_no_castle_attack_error() -> void:
	assert_eq(_map().validate(), PackedStringArray(), "the shipped map is clean")
	var fixture: MapConfig = (load(SMOKE_FIXTURE) as MapConfig).duplicate_deep(
		Resource.DEEP_DUPLICATE_ALL
	)
	assert_eq(fixture.validate(), PackedStringArray(), "a castle that never shoots is clean")


func test_a_negative_castle_attack_damage_is_reported() -> void:
	var map: MapConfig = _map()
	map.castle_attack_damage = BAD_DAMAGE
	_assert_one_error(map, "castle_attack_damage", "a negative damage")


func test_a_negative_castle_attack_range_is_reported() -> void:
	var map: MapConfig = _map()
	map.castle_attack_range = BAD_NUMBER
	_assert_one_error(map, "castle_attack_range", "a negative range")


func test_a_negative_castle_attack_interval_is_reported() -> void:
	var map: MapConfig = _map()
	map.castle_attack_interval = BAD_NUMBER
	_assert_one_error(map, "castle_attack_interval", "a negative interval")


func test_a_negative_castle_projectile_speed_is_reported() -> void:
	var map: MapConfig = _map()
	map.castle_projectile_speed = BAD_NUMBER
	_assert_one_error(map, "castle_projectile_speed", "a negative projectile speed")


func test_an_attacking_castle_with_no_range_is_reported() -> void:
	var map: MapConfig = _map()
	map.castle_attack_range = 0.0
	_assert_one_error(map, "castle_attack_range", "damage with no range")


func test_an_attacking_castle_with_no_interval_is_reported() -> void:
	var map: MapConfig = _map()
	map.castle_attack_interval = 0.0
	_assert_one_error(map, "castle_attack_interval", "damage with no interval")


func test_a_castle_with_no_damage_needs_no_range_or_interval() -> void:
	var map: MapConfig = _map()
	map.castle_attack_damage = 0
	map.castle_attack_range = 0.0
	map.castle_attack_interval = 0.0
	map.castle_projectile_speed = 0.0
	assert_eq(map.validate(), PackedStringArray(), "an off castle is a valid castle")


func test_the_castle_kills_a_grunt_in_three_shots_and_a_skirmisher_in_two_and_reaches_one() -> void:
	var map: MapConfig = _map()
	var grunt: EnemyDef = map.find_enemy(&"grunt")
	var skirmisher: EnemyDef = map.find_enemy(&"ranged")
	assert_gt(map.castle_attack_damage, 0, "the shipped castle attacks")
	if map.castle_attack_damage <= 0:
		return
	assert_eq(
		grunt.max_health, GRUNT_HEALTH, "a grunt stays at 6 hp (5 would let the king one-shot)"
	)
	assert_eq(
		_shots_to_kill(grunt.max_health, map.castle_attack_damage), GRUNT_SHOTS, "three for a grunt"
	)
	assert_eq(
		_shots_to_kill(skirmisher.max_health, map.castle_attack_damage),
		SKIRMISHER_SHOTS,
		"two for a skirmisher"
	)
	assert_gte(
		map.castle_attack_range,
		map.castle_radius + skirmisher.attack_range + REACH_SLACK_M,
		"it reaches a skirmisher that stands off to shoot it"
	)
	assert_almost_eq(map.castle_attack_interval, SHIPPED_INTERVAL_S, 0.0001, "one shot per 1.5 s")
	assert_gt(map.castle_projectile_speed, 0.0, "its arrows fly")


func test_the_shipped_castle_reaches_22_m_and_its_arrows_fly_at_27_m_per_s() -> void:
	var map: MapConfig = _map()
	assert_almost_eq(map.castle_attack_range, OWNER_RANGE_M, 0.0001, "the owner's reach")
	assert_almost_eq(map.castle_projectile_speed, OWNER_SPEED_MPS, 0.0001, "the owner's speed")
	var flight: int = SimClock.flight_ticks(map.castle_attack_range, map.castle_projectile_speed)
	assert_eq(flight, EDGE_FLIGHT_TICKS, "an arrow at the edge of the reach flies 25 ticks")
	assert_lt(
		flight, SimClock.ticks(map.castle_attack_interval), "one castle arrow in the air at a time"
	)


func test_a_castle_number_that_is_not_finite_is_reported_once() -> void:
	for field: String in FINITE_FIELDS:
		for value: float in NOT_FINITE_VALUES:
			var map: MapConfig = _map()
			map.set(field, value)
			var label: String = "%s at %s" % [field, value]
			_assert_one_error(map, field, label)
			var errors: PackedStringArray = map.validate()
			if errors.size() == 1:
				assert_string_contains(errors[0], "finite", "%s says it is not finite" % label)


func test_an_attacking_castle_with_an_interval_below_one_step_is_reported() -> void:
	for interval: float in [SUB_STEP_INTERVAL_S, SimClock.STEP * 0.5]:
		var map: MapConfig = _map()
		map.castle_attack_interval = interval
		_assert_one_error(map, "castle_attack_interval", "an interval of %s s" % interval)
		var errors: PackedStringArray = map.validate()
		if errors.size() == 1:
			assert_string_contains(errors[0], "step", "%s s is below one step" % interval)


func test_an_interval_of_one_step_or_no_damage_is_accepted() -> void:
	var one_step: MapConfig = _map()
	one_step.castle_attack_interval = SimClock.STEP
	assert_eq(one_step.validate(), PackedStringArray(), "exactly one step is a valid interval")
	var off: MapConfig = _map()
	off.castle_attack_damage = 0
	off.castle_attack_interval = SUB_STEP_INTERVAL_S
	assert_eq(
		off.validate(), PackedStringArray(), "a castle that does not attack needs no interval"
	)
