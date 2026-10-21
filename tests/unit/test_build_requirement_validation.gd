extends GutTest
## T-05-11, BLDG-09, D-03, D-10, Pitfall 9: MapConfig.validate() reports a requirement that can
## never be met instead of arming it: a castle tier above the castle's top tier or below 0, a
## requires_spot that names no spot or the plot itself, a required tier outside 1..that building's
## top tier, and a requirement cycle (reported once). A castle requirement on a map without a
## castle plot is accepted, because it never applies there. Each bad case edits a deep copy of the
## gate fixture and calls validate() directly, never through RunContext, whose push_error would
## fail the test.

const FIXTURE := "res://tests/fixtures/fixture_map_gate.tres"
const PROTOTYPE := "res://data/maps/prototype_map.tres"
const TOWER: StringName = &"tower"
const HOUSE_A: StringName = &"house_a"
const HOUSE_B: StringName = &"house_b"
const CASTLE_TIERS: int = 4


func _map() -> MapConfig:
	return (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)


func _spot(map: MapConfig, spot_id: StringName) -> BuildSpotDef:
	for spot: BuildSpotDef in map.spots:
		if spot.id == spot_id:
			return spot
	return null


func _tower_tier_two(map: MapConfig) -> BuildingTierDef:
	for building_def: BuildingDef in map.buildings:
		if building_def.id == TOWER:
			return building_def.tier_def(2)
	return null


## Asserts validate() reports exactly one error and that it contains every needle.
func _assert_one_error(map: MapConfig, needles: Array[String], what: String) -> void:
	var errors: PackedStringArray = map.validate()
	assert_eq(errors.size(), 1, "%s: exactly one error, got %s" % [what, errors])
	if errors.size() == 1:
		for needle: String in needles:
			assert_string_contains(errors[0], needle, "%s names %s" % [what, needle])


func test_the_gate_fixture_and_the_shipped_map_validate_clean() -> void:
	assert_eq(_map().validate(), PackedStringArray(), "the gate fixture")
	var shipped: MapConfig = load(PROTOTYPE)
	assert_eq(shipped.validate(), PackedStringArray(), "the shipped prototype map")
	assert_eq(BuildRequirementValidation.problems(shipped), [] as Array[String], "no problems")


func test_a_castle_tier_above_the_castles_top_tier_is_reported() -> void:
	var map: MapConfig = _map()
	_tower_tier_two(map).requires_castle_tier = CASTLE_TIERS + 1
	_assert_one_error(map, ["tower", "tier 2", "5", "4"], "castle tier 5 of 4")


func test_the_castles_top_tier_is_the_highest_tier_a_requirement_may_name() -> void:
	var map: MapConfig = _map()
	_tower_tier_two(map).requires_castle_tier = CASTLE_TIERS
	assert_eq(map.validate(), PackedStringArray(), "castle IV is reachable")


func test_a_negative_castle_tier_is_reported() -> void:
	var map: MapConfig = _map()
	_tower_tier_two(map).requires_castle_tier = -1
	_assert_one_error(map, ["tower", "tier 2", "-1"], "castle tier -1")


func test_a_requirement_on_a_tier_of_the_castle_building_that_it_cannot_reach_is_reported() -> void:
	var map: MapConfig = _map()
	for building_def: BuildingDef in map.buildings:
		if building_def.id == &"castle_center":
			building_def.tier_def(3).requires_castle_tier = 3
	_assert_one_error(map, ["castle_center", "tier 3"], "the castle gating itself")


func test_a_spot_requirement_naming_a_missing_spot_is_reported() -> void:
	var map: MapConfig = _map()
	_spot(map, HOUSE_B).requires_spot = &"mill_1"
	_assert_one_error(map, ["house_b", "mill_1"], "missing spot")


func test_a_spot_requirement_naming_the_plot_itself_is_reported() -> void:
	var map: MapConfig = _map()
	_spot(map, HOUSE_B).requires_spot = HOUSE_B
	_assert_one_error(map, ["house_b", "itself"], "self")


func test_a_required_tier_of_zero_is_reported() -> void:
	var map: MapConfig = _map()
	_spot(map, HOUSE_B).requires_spot_tier = 0
	_assert_one_error(map, ["house_b", "house_a", "0"], "tier 0")


func test_a_required_tier_above_the_required_buildings_top_tier_is_reported() -> void:
	var map: MapConfig = _map()
	_spot(map, HOUSE_B).requires_spot_tier = 4
	_assert_one_error(map, ["house_b", "house_a", "4", "3"], "tier 4 of a three-tier House")


func test_the_required_buildings_top_tier_is_allowed() -> void:
	var map: MapConfig = _map()
	_spot(map, HOUSE_B).requires_spot_tier = 3
	assert_eq(map.validate(), PackedStringArray(), "House III is reachable")


func test_a_two_plot_cycle_is_reported_once() -> void:
	var map: MapConfig = _map()
	_spot(map, HOUSE_A).requires_spot = HOUSE_B
	var errors: PackedStringArray = map.validate()
	assert_eq(errors.size(), 1, "one report for the cycle, got %s" % [errors])
	if errors.size() == 1:
		assert_string_contains(errors[0], "cycle", "it says cycle")
		assert_string_contains(errors[0], "house_a", "it names house_a")
		assert_string_contains(errors[0], "house_b", "and house_b")


func test_a_plot_chained_into_a_cycle_is_not_reported_as_part_of_it() -> void:
	var map: MapConfig = _map()
	_spot(map, HOUSE_A).requires_spot = HOUSE_B
	_spot(map, &"tower_1").requires_spot = HOUSE_A
	var errors: PackedStringArray = map.validate()
	assert_eq(errors.size(), 1, "still one report, got %s" % [errors])
	if errors.size() == 1:
		assert_false(errors[0].contains("tower_1"), "the tail is not in the cycle")


func test_a_longer_chain_without_a_cycle_is_fine() -> void:
	var map: MapConfig = _map()
	_spot(map, &"tower_1").requires_spot = HOUSE_B
	assert_eq(map.validate(), PackedStringArray(), "tower_1 -> house_b -> house_a")


func test_a_castle_requirement_on_a_map_without_a_castle_plot_is_accepted() -> void:
	var map: MapConfig = _map()
	var kept: Array[BuildSpotDef] = []
	for spot: BuildSpotDef in map.spots:
		if not spot.is_castle:
			kept.append(spot)
	map.spots = kept
	_tower_tier_two(map).requires_castle_tier = 9
	assert_eq(map.validate(), PackedStringArray(), "it never applies there")
	_tower_tier_two(map).requires_castle_tier = -1
	assert_eq(map.validate().size(), 1, "but a negative number is still wrong")


func test_the_helper_never_mutates_the_map() -> void:
	var map: MapConfig = _map()
	_spot(map, HOUSE_A).requires_spot = HOUSE_B
	var before: int = map.spots.size()
	BuildRequirementValidation.problems(map)
	assert_eq(map.spots.size(), before, "spots untouched")
	assert_eq(_spot(map, HOUSE_A).requires_spot, HOUSE_B, "and so is the data")
