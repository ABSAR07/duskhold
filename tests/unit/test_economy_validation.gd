extends GutTest
## T-05-13, T-05-16, ECON-03, ECON-05: MapConfig.validate() reports bad income-curve data through
## EconomyValidation instead of arming it. Synthetic maps are deep copies of the shipped prototype
## map with one number broken: a DECLINING tier with a step or floor below 1, a first payout below
## its floor, any curve value above MAX_CURVE_VALUE, a BOATS tier with a boat cap outside 1 to
## MAX_BOAT_CAP or no gold per boat, and curve fields set on a building whose curve does not use
## them. The pond is checked in test_pond_layout. The shipped map is clean.

const MINE: StringName = &"gold_mine"
const HOUSE: StringName = &"house"
const HARBOR: StringName = &"fishing_harbor"


func _map() -> MapConfig:
	return E2eSupport.waveless_prototype_map()


func _tier(map: MapConfig, building_id: StringName, tier: int) -> BuildingTierDef:
	for building_def: BuildingDef in map.buildings:
		if building_def.id == building_id:
			return building_def.tier_def(tier)
	return null


func _building(map: MapConfig, building_id: StringName) -> BuildingDef:
	for building_def: BuildingDef in map.buildings:
		if building_def.id == building_id:
			return building_def
	return null


func _has(problems: Array[String], needle: String) -> bool:
	for problem: String in problems:
		if problem.contains(needle):
			return true
	return false


func test_the_shipped_map_has_no_economy_problem() -> void:
	var map: MapConfig = load("res://data/maps/prototype_map.tres")
	assert_eq(EconomyValidation.problems(map), [] as Array[String], "clean")
	assert_eq(map.validate().size(), 0, "and validate() is clean as a whole")


func test_a_step_of_zero_is_reported() -> void:
	var map: MapConfig = _map()
	_tier(map, MINE, 1).income_step = 0
	assert_true(_has(EconomyValidation.problems(map), "income_step"), "the step")


func test_a_floor_of_zero_is_reported() -> void:
	var map: MapConfig = _map()
	_tier(map, MINE, 1).income_floor = 0
	assert_true(_has(EconomyValidation.problems(map), "income_floor"), "the floor")


func test_a_negative_step_is_reported() -> void:
	var map: MapConfig = _map()
	_tier(map, MINE, 1).income_step = -1
	assert_true(_has(EconomyValidation.problems(map), "income_step"), "a rising Mine is data error")


func test_a_first_payout_below_its_floor_is_reported() -> void:
	var map: MapConfig = _map()
	var tier: BuildingTierDef = _tier(map, MINE, 1)
	tier.income_floor = 1
	tier.dawn_income = 0
	assert_true(_has(EconomyValidation.problems(map), "below its income_floor"), "0 below 1")


func test_a_first_payout_equal_to_its_floor_is_allowed() -> void:
	var map: MapConfig = _map()
	var tier: BuildingTierDef = _tier(map, MINE, 1)
	tier.income_floor = 2
	tier.dawn_income = 2
	assert_eq(EconomyValidation.problems(map), [] as Array[String], "a flat Mine is odd, not wrong")


func test_a_value_above_the_cap_is_reported_for_each_curve_field() -> void:
	var cap: int = EconomyValidation.MAX_CURVE_VALUE
	for field: String in ["income_step", "income_floor", "dawn_income"]:
		var map: MapConfig = _map()
		var tier: BuildingTierDef = _tier(map, MINE, 1)
		tier.set(field, cap + 1)
		assert_true(_has(EconomyValidation.problems(map), field), "%s above %d" % [field, cap])


func test_values_exactly_at_the_cap_are_allowed() -> void:
	var map: MapConfig = _map()
	var tier: BuildingTierDef = _tier(map, MINE, 1)
	tier.dawn_income = EconomyValidation.MAX_CURVE_VALUE
	tier.income_step = EconomyValidation.MAX_CURVE_VALUE
	tier.income_floor = EconomyValidation.MAX_CURVE_VALUE
	assert_eq(EconomyValidation.problems(map), [] as Array[String], "1000 is the limit, inclusive")


func test_the_cap_is_one_thousand() -> void:
	assert_eq(EconomyValidation.MAX_CURVE_VALUE, 1000, "the documented bound")


func test_a_step_set_on_a_flat_building_is_reported_as_a_field_on_the_wrong_curve() -> void:
	var map: MapConfig = _map()
	_tier(map, HOUSE, 1).income_step = 1
	var problems: Array[String] = EconomyValidation.problems(map)
	assert_true(_has(problems, "income_step"), "named")
	assert_true(_has(problems, "FLAT"), "with the curve it is wrongly set on")


func test_a_floor_set_on_a_flat_building_is_reported() -> void:
	var map: MapConfig = _map()
	_tier(map, HOUSE, 2).income_floor = 1
	assert_true(_has(EconomyValidation.problems(map), "income_floor"), "the floor")


func test_a_curve_field_on_a_building_that_pays_nothing_is_reported() -> void:
	var map: MapConfig = _map()
	_tier(map, &"tower", 1).income_step = 3
	assert_true(_has(EconomyValidation.problems(map), "income_step"), "a tower has no curve")


func test_validate_includes_the_economy_problems() -> void:
	var map: MapConfig = _map()
	_tier(map, MINE, 1).income_step = 0
	var found: bool = false
	for error: String in map.validate():
		found = found or error.contains("income_step")
	assert_true(found, "MapConfig.validate() appends the economy helper")


func test_a_null_building_or_tier_is_skipped_not_a_crash() -> void:
	var map: MapConfig = _map()
	map.buildings.append(null)
	_building(map, MINE).tiers.append(null)
	assert_eq(EconomyValidation.problems(map), [] as Array[String], "other helpers report these")


func test_a_boat_cap_outside_one_to_twenty_is_reported() -> void:
	for cap: int in [-1, 0, EconomyValidation.MAX_BOAT_CAP + 1]:
		var map: MapConfig = _map()
		_tier(map, HARBOR, 1).boat_cap = cap
		assert_true(_has(EconomyValidation.problems(map), "boat_cap"), "a cap of %d" % cap)


func test_a_boat_cap_exactly_at_the_limits_is_allowed() -> void:
	for cap: int in [1, EconomyValidation.MAX_BOAT_CAP]:
		var map: MapConfig = _map()
		_tier(map, HARBOR, 2).boat_cap = cap
		assert_eq(EconomyValidation.problems(map), [] as Array[String], "a cap of %d" % cap)


func test_a_boat_income_outside_one_to_the_curve_cap_is_reported() -> void:
	for gold: int in [-1, 0, EconomyValidation.MAX_CURVE_VALUE + 1]:
		var map: MapConfig = _map()
		_tier(map, HARBOR, 1).boat_income = gold
		assert_true(_has(EconomyValidation.problems(map), "boat_income"), "gold %d" % gold)


func test_boat_fields_on_a_building_that_has_no_boats_are_reported() -> void:
	var map: MapConfig = _map()
	_tier(map, HOUSE, 1).boat_cap = 2
	_tier(map, MINE, 1).boat_income = 1
	var problems: Array[String] = EconomyValidation.problems(map)
	assert_true(_has(problems, "boat_cap"), "a House with a cap")
	assert_true(_has(problems, "boat_income"), "a Mine with gold per boat")
	assert_true(_has(problems, "does not use it"), "said as a field on the wrong curve")


func test_the_boat_and_pond_bounds_are_the_documented_ones() -> void:
	assert_eq(EconomyValidation.MAX_BOAT_CAP, 20, "at most twenty boats")
	assert_eq(EconomyValidation.MAX_POND_RADIUS, 30.0, "a pond of at most 30 m")
	assert_eq(EconomyValidation.POND_ROAD_CLEARANCE, 10.0, "10 m of clear water beside a road")
