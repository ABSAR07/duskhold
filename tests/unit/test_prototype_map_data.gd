extends GutTest
## Data contract for the prototype sandbox map (D-02, D-03, D-04, D-09, D-10) and for
## MapConfig.validate() (T-01-10). Expected numbers are derived from the loaded .tres data;
## the only literals are the structural counts the decisions fix.

const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const KING := "res://data/king/king.tres"
const HOUSE_SPOT_COUNT: int = 5
const TOWER_SPOT_COUNT: int = 3
const HOUSE_TIER_COUNT: int = 3
const TOWER_TIER_COUNT: int = 2
const MIN_RIDE_S: float = 12.0
const MAX_RIDE_S: float = 18.0


func _map() -> MapConfig:
	return load(PROTOTYPE_MAP)


func _building(map: MapConfig, building_id: StringName) -> BuildingDef:
	for building_def: BuildingDef in map.buildings:
		if building_def.id == building_id:
			return building_def
	return null


func _spot_count_for(map: MapConfig, building_id: StringName) -> int:
	var count: int = 0
	for spot: BuildSpotDef in map.spots:
		if spot.building_id == building_id:
			count += 1
	return count


func _valid_map() -> MapConfig:
	var tier: BuildingTierDef = BuildingTierDef.new()
	tier.cost = 2
	var building_def: BuildingDef = BuildingDef.new()
	building_def.id = &"hut"
	building_def.tiers = [tier]
	var spot: BuildSpotDef = BuildSpotDef.new()
	spot.id = &"a"
	spot.building_id = &"hut"
	var map: MapConfig = MapConfig.new()
	map.starting_gold = 1
	map.buildings = [building_def]
	map.spots = [spot]
	return map


func test_castle_sits_at_the_middle_of_the_map() -> void:
	var map: MapConfig = _map()
	assert_eq(map.castle_position, Vector3.ZERO, "castle center is the map origin")


func test_map_has_eight_spots_five_house_and_three_tower_plots() -> void:
	var map: MapConfig = _map()
	assert_eq(map.spots.size(), HOUSE_SPOT_COUNT + TOWER_SPOT_COUNT, "8 fixed spots (D-03)")
	assert_eq(_spot_count_for(map, &"house"), HOUSE_SPOT_COUNT, "5 House plots")
	assert_eq(_spot_count_for(map, &"tower"), TOWER_SPOT_COUNT, "3 tower plots")


func test_spot_ids_are_unique_and_every_building_id_resolves() -> void:
	var map: MapConfig = _map()
	var seen: Dictionary = {}
	for spot: BuildSpotDef in map.spots:
		assert_false(seen.has(spot.id), "spot id %s is unique" % spot.id)
		seen[spot.id] = true
		assert_not_null(_building(map, spot.building_id), "%s has a building def" % spot.id)


func test_ride_across_the_map_takes_twelve_to_eighteen_seconds() -> void:
	var map: MapConfig = _map()
	var king: KingDef = load(KING)
	var points: Array[Vector2] = [
		Vector2(map.castle_position.x, map.castle_position.z),
		Vector2(map.king_spawn.x, map.king_spawn.z),
	]
	for spot: BuildSpotDef in map.spots:
		points.append(Vector2(spot.position.x, spot.position.z))
	var farthest: float = 0.0
	for a: Vector2 in points:
		for b: Vector2 in points:
			farthest = maxf(farthest, a.distance_to(b))
	var ride_s: float = farthest / king.walk_speed
	assert_between(ride_s, MIN_RIDE_S, MAX_RIDE_S, "ride time in s (D-03 as amended 2026-10-07)")


func test_starting_gold_buys_two_houses_or_one_tower_but_not_both() -> void:
	var map: MapConfig = _map()
	var house: BuildingDef = _building(map, &"house")
	var tower: BuildingDef = _building(map, &"tower")
	assert_not_null(tower, "the map lists the tower building")
	if house == null or tower == null:
		return
	var house_cost: int = house.tier_def(1).cost
	var tower_cost: int = tower.tier_def(1).cost
	assert_true(map.starting_gold >= 2 * house_cost, "two Houses are affordable")
	assert_true(map.starting_gold >= tower_cost, "one tower is affordable")
	assert_true(map.starting_gold < 2 * house_cost + tower_cost, "not both (D-09)")


func test_house_has_three_tiers_with_rising_dawn_income() -> void:
	var house: BuildingDef = _building(_map(), &"house")
	assert_eq(house.max_tier(), HOUSE_TIER_COUNT, "House has 3 tiers (D-10)")
	for tier: int in range(2, house.max_tier() + 1):
		var previous: int = house.tier_def(tier - 1).dawn_income
		assert_gt(house.tier_def(tier).dawn_income, previous, "tier %d pays more" % tier)


func test_tower_has_two_tiers_with_attack_data_and_no_income() -> void:
	var tower: BuildingDef = _building(_map(), &"tower")
	assert_not_null(tower, "the map lists the tower building")
	if tower == null:
		return
	assert_eq(tower.max_tier(), TOWER_TIER_COUNT, "tower has 2 tiers (D-10)")
	for tier: int in range(1, tower.max_tier() + 1):
		var tier_def: BuildingTierDef = tower.tier_def(tier)
		assert_gt(tier_def.attack_damage, 0, "tier %d deals damage" % tier)
		assert_gt(tier_def.attack_range, 0.0, "tier %d has range" % tier)
		assert_eq(tier_def.dawn_income, 0, "towers pay no income")


func test_tower_top_tier_effect_line_mentions_range_and_damage() -> void:
	var tower: BuildingDef = _building(_map(), &"tower")
	assert_not_null(tower, "the map lists the tower building")
	if tower == null:
		return
	var top: BuildingTierDef = tower.tier_def(tower.max_tier())
	var line: String = top.effect_line()
	assert_string_contains(line, String.num(top.attack_range), "effect line names the range")
	assert_string_contains(line, str(top.attack_damage), "effect line names the damage")


func test_prototype_map_is_the_permanent_sandbox_and_validates_clean() -> void:
	var map: MapConfig = _map()
	var errors: PackedStringArray = map.validate()
	assert_true(map.is_sandbox, "prototype map is flagged sandbox (D-04)")
	assert_eq(errors.size(), 0, "no validation errors: %s" % [errors])


func test_validate_accepts_a_well_formed_map() -> void:
	assert_eq(_valid_map().validate().size(), 0, "baseline map is clean")


func test_validate_reports_a_duplicate_spot_id() -> void:
	var map: MapConfig = _valid_map()
	var twin: BuildSpotDef = BuildSpotDef.new()
	twin.id = &"a"
	twin.building_id = &"hut"
	map.spots.append(twin)
	assert_gt(map.validate().size(), 0, "duplicate spot id is reported")


func test_validate_reports_a_duplicate_building_id() -> void:
	var map: MapConfig = _valid_map()
	var twin: BuildingDef = BuildingDef.new()
	twin.id = &"hut"
	twin.tiers = map.buildings[0].tiers.duplicate()
	map.buildings.append(twin)
	assert_gt(map.validate().size(), 0, "duplicate building id is reported")


func test_validate_reports_an_unknown_building_id() -> void:
	var map: MapConfig = _valid_map()
	map.spots[0].building_id = &"castle_of_dreams"
	assert_gt(map.validate().size(), 0, "dangling building id is reported")


func test_validate_reports_a_building_with_zero_tiers() -> void:
	var map: MapConfig = _valid_map()
	map.buildings[0].tiers = []
	assert_gt(map.validate().size(), 0, "empty tier list is reported")


func test_validate_reports_a_non_positive_tier_cost() -> void:
	var map: MapConfig = _valid_map()
	map.buildings[0].tiers[0].cost = 0
	assert_gt(map.validate().size(), 0, "zero cost is reported")
	map.buildings[0].tiers[0].cost = -3
	assert_gt(map.validate().size(), 0, "negative cost is reported")


func test_validate_reports_negative_income_and_negative_starting_gold() -> void:
	var income_map: MapConfig = _valid_map()
	income_map.buildings[0].tiers[0].dawn_income = -1
	assert_gt(income_map.validate().size(), 0, "negative dawn income is reported")
	var gold_map: MapConfig = _valid_map()
	gold_map.starting_gold = -1
	assert_gt(gold_map.validate().size(), 0, "negative starting gold is reported")


func test_validate_reports_a_spot_with_an_empty_id() -> void:
	var map: MapConfig = _valid_map()
	map.spots[0].id = &""
	assert_gt(map.validate().size(), 0, "an empty spot id can never be built, so it is reported")


func test_validate_reports_null_entries_instead_of_crashing() -> void:
	var building_map: MapConfig = _valid_map()
	building_map.buildings.append(null)
	assert_gt(building_map.validate().size(), 0, "a null building is reported")
	var spot_map: MapConfig = _valid_map()
	spot_map.spots.append(null)
	assert_gt(spot_map.validate().size(), 0, "a null spot is reported")
	var tier_map: MapConfig = _valid_map()
	tier_map.buildings[0].tiers.append(null)
	assert_gt(tier_map.validate().size(), 0, "a null tier is reported")


func test_validate_reports_a_building_with_an_empty_id() -> void:
	var map: MapConfig = _valid_map()
	map.buildings[0].id = &""
	map.spots[0].building_id = &""
	assert_gt(map.validate().size(), 0, "an empty building id is reported, not matched by a spot")


func test_run_context_survives_null_entries_that_validate_reports() -> void:
	var map: MapConfig = _valid_map()
	map.buildings.append(null)
	map.spots.append(null)
	var tuning: LoopTuning = LoopTuning.new()

	var ctx: RunContext = RunContext.new(map, tuning)

	assert_push_error("a building entry is empty")
	assert_push_error("a spot entry is empty")
	assert_not_null(ctx.buildings, "the context still builds")
	assert_eq(ctx.buildings.spot_ids().size(), 1, "the null spot is skipped, the real one kept")
	assert_not_null(ctx.buildings.get_building_def_for_spot(&"a"), "the real building resolves")
