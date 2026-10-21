extends GutTest
## T-05-13, ECON-03: MapConfig.validate() reports bad income-curve data through EconomyValidation
## instead of arming it. Synthetic maps are deep copies of the shipped prototype map with one
## number broken: a DECLINING tier with a step or floor below 1, a first payout below its floor, any
## curve value above MAX_CURVE_VALUE, and curve fields set on a building whose curve does not use
## them. The shipped map is clean.

const MINE: StringName = &"gold_mine"
const HOUSE: StringName = &"house"


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
