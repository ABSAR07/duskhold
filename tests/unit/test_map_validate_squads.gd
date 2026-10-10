extends GutTest
## T-03-04 and T-03-05: MapConfig.validate() reports bad unit and squad data instead of arming it.
## Every bad case edits a deep copy of the shipped map and calls validate() directly, never through
## RunContext, whose push_error would fail the test (the one RunContext test asserts the pushes).

const SQUAD_FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const BARRACKS: StringName = &"barracks"
const HOUSE: StringName = &"house"
const FOOTMAN: StringName = &"footman"
const SUB_STEP_S: float = 0.001
const TOO_LONG_S: float = 3601.0
## Every float of a unit that must be finite.
const UNIT_FLOATS: Array[String] = [
	"move_speed",
	"radius",
	"attack_range",
	"attack_interval",
	"guard_range",
	"leash_range",
	"retarget_interval_seconds",
	"projectile_speed",
	"formation_spacing",
]
const NOT_FINITE_VALUES: Array[float] = [NAN, INF, -INF]


func _map() -> MapConfig:
	return E2eSupport.shipped_prototype_map()


func _footman(map: MapConfig) -> UnitDef:
	return map.find_unit(FOOTMAN)


func _building(map: MapConfig, building_id: StringName) -> BuildingDef:
	for building_def: BuildingDef in map.buildings:
		if building_def.id == building_id:
			return building_def
	return null


## Asserts validate() reports exactly one error and that it contains every needle.
func _assert_one_error(map: MapConfig, needles: Array[String], label: String) -> void:
	var errors: PackedStringArray = map.validate()
	assert_eq(errors.size(), 1, "%s reports exactly one error: %s" % [label, errors])
	if errors.size() == 1:
		for needle: String in needles:
			assert_string_contains(errors[0], needle, "%s names '%s'" % [label, needle])


func test_a_ground_half_extent_that_cannot_bound_a_command_point_is_reported() -> void:
	for bad: float in [0.0, -1.0, -90.0, NAN, INF, -INF, 1.0e30]:
		var map: MapConfig = _map()
		map.ground_half_extent = bad
		_assert_one_error(map, ["ground_half_extent"], "an extent of %s" % bad)


func test_the_shipped_ground_half_extent_is_ninety_metres() -> void:
	assert_eq(_map().ground_half_extent, 90.0, "the 180 m ground")
	assert_eq(MapConfig.new().ground_half_extent, 90.0, "and the default")


func test_the_shipped_map_and_the_squad_fixture_report_no_squad_error() -> void:
	assert_eq(_map().validate(), PackedStringArray(), "the shipped map is clean")
	var fixture: MapConfig = (load(SQUAD_FIXTURE) as MapConfig).duplicate_deep(
		Resource.DEEP_DUPLICATE_ALL
	)
	assert_eq(fixture.validate(), PackedStringArray(), "so is the squad fixture")


func test_an_empty_null_or_duplicate_unit_is_reported() -> void:
	var null_map: MapConfig = _map()
	null_map.units.append(null)
	_assert_one_error(null_map, ["unit entry is empty"], "a null unit")
	var empty_map: MapConfig = _map()
	var nameless: UnitDef = _footman(empty_map).duplicate()
	nameless.id = &""
	empty_map.units.append(nameless)
	_assert_one_error(empty_map, ["unit has an empty id"], "an empty id")
	var twin_map: MapConfig = _map()
	twin_map.units.append(_footman(twin_map).duplicate())
	_assert_one_error(twin_map, ["duplicate unit id", "footman"], "a duplicate id")


func test_a_building_unit_id_that_does_not_resolve_is_reported() -> void:
	var map: MapConfig = _map()
	_building(map, BARRACKS).unit_id = &"ghost"
	_assert_one_error(map, ["building 'barracks'", "unit_id", "ghost"], "an unknown unit")


func test_a_unit_float_that_is_not_finite_is_reported_once() -> void:
	for field: String in UNIT_FLOATS:
		for bad: float in NOT_FINITE_VALUES:
			var map: MapConfig = _map()
			_footman(map).set(field, bad)
			_assert_one_error(map, ["unit 'footman'", field, "not finite"], "%s %s" % [field, bad])


func test_a_unit_number_that_must_be_positive_is_reported() -> void:
	var cases: Array[Array] = [
		["max_health", 0],
		["move_speed", 0.0],
		["radius", 0.0],
		["attack_damage", 0],
		["guard_range", 0.0],
		["retarget_interval_seconds", 0.0],
		["formation_spacing", 0.0],
		["attack_range", -1.0],
		["projectile_speed", -1.0],
	]
	for case: Array in cases:
		var map: MapConfig = _map()
		_footman(map).set(case[0], case[1])
		_assert_one_error(map, ["unit 'footman'", case[0]], "%s of %s" % [case[0], case[1]])


func test_an_attack_interval_outside_one_step_to_one_hour_is_reported() -> void:
	for bad: float in [0.0, SUB_STEP_S, TOO_LONG_S]:
		var map: MapConfig = _map()
		_footman(map).attack_interval = bad
		_assert_one_error(map, ["unit 'footman'", "attack_interval"], "interval %s" % bad)
	var ok_map: MapConfig = _map()
	_footman(ok_map).attack_interval = SimClock.STEP
	assert_eq(ok_map.validate().size(), 0, "exactly one step is allowed")
	_footman(ok_map).attack_interval = MapConfig.MAX_CASTLE_ATTACK_INTERVAL_S
	assert_eq(ok_map.validate().size(), 0, "exactly one hour is allowed")


func test_a_leash_range_below_the_guard_range_is_reported() -> void:
	var map: MapConfig = _map()
	var footman: UnitDef = _footman(map)
	footman.leash_range = footman.guard_range - 0.5
	_assert_one_error(map, ["unit 'footman'", "leash_range", "guard_range"], "a short leash")
	footman.leash_range = footman.guard_range
	assert_eq(map.validate().size(), 0, "a leash equal to the guard range is allowed")


func test_a_squad_size_outside_one_to_the_unit_cap_on_a_military_tier_is_reported() -> void:
	for bad: int in [0, SquadSystem.MAX_UNITS_PER_SQUAD + 1, -3]:
		var map: MapConfig = _map()
		_building(map, BARRACKS).tiers[1].squad_size = bad
		_assert_one_error(map, ["building 'barracks'", "tier 2", "squad_size"], "size %d" % bad)
	var edge_map: MapConfig = _map()
	_building(edge_map, BARRACKS).tiers[2].squad_size = SquadSystem.MAX_UNITS_PER_SQUAD
	assert_eq(edge_map.validate().size(), 0, "exactly the cap is allowed")


func test_a_squad_size_on_a_building_that_fields_no_unit_is_reported() -> void:
	var map: MapConfig = _map()
	_building(map, HOUSE).tiers[0].squad_size = 1
	_assert_one_error(map, ["building 'house'", "tier 1", "squad_size"], "a House squad")


func test_a_respawn_interval_outside_one_step_to_one_hour_is_reported() -> void:
	for bad: float in [0.0, SUB_STEP_S, TOO_LONG_S, NAN, INF]:
		var map: MapConfig = _map()
		_building(map, BARRACKS).tiers[0].squad_respawn_seconds = bad
		_assert_one_error(
			map, ["building 'barracks'", "tier 1", "squad_respawn_seconds"], "respawn %s" % bad
		)
	var ok_map: MapConfig = _map()
	_building(ok_map, BARRACKS).tiers[0].squad_respawn_seconds = SimClock.STEP
	assert_eq(ok_map.validate().size(), 0, "exactly one step is allowed")


func test_a_post_distance_that_is_not_finite_or_negative_is_reported() -> void:
	for bad: float in [NAN, INF, -1.0]:
		var map: MapConfig = _map()
		_building(map, BARRACKS).post_distance = bad
		_assert_one_error(map, ["building 'barracks'", "post_distance"], "post %s" % bad)


func test_a_run_context_still_builds_on_bad_squad_data_that_validate_reports() -> void:
	var map: MapConfig = _map()
	map.units.append(null)
	_building(map, BARRACKS).unit_id = &"ghost"
	_footman(map).max_health = 0
	var ctx: RunContext = RunContext.new(map, LoopTuning.new())
	assert_push_error("a unit entry is empty")
	assert_push_error("unit_id")
	assert_push_error("max_health")
	assert_not_null(ctx.squads, "the squad system still exists")
	ctx.step()
	assert_eq(ctx.squads.squad_ids().size(), 0, "nothing is raised without a building")
