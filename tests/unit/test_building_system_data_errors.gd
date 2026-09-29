extends GutTest
## BuildingSystem must not crash or desync on data errors MapConfig.validate() already reports:
## a duplicate spot id and a spot whose building id no map building defines.


func _valid_map() -> MapConfig:
	var tier: BuildingTierDef = BuildingTierDef.new()
	tier.cost = 2
	tier.dawn_income = 1
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


func test_a_duplicate_spot_id_is_listed_once_and_keeps_the_first_definition() -> void:
	var map: MapConfig = _valid_map()
	var twin: BuildSpotDef = BuildSpotDef.new()
	twin.id = map.spots[0].id
	twin.building_id = map.spots[0].building_id
	map.spots.append(twin)

	var ctx: RunContext = RunContext.new(map, LoopTuning.new())

	assert_push_error("duplicate spot id")
	assert_eq(ctx.buildings.spot_ids().size(), 1, "the duplicate is skipped, not listed twice")
	assert_eq(ctx.buildings.get_spot(&"a"), map.spots[0], "the first definition is the one kept")


func test_dawn_income_skips_a_building_whose_id_no_map_building_defines() -> void:
	var map: MapConfig = _valid_map()
	map.spots[0].building_id = &"castle_of_dreams"
	var ctx: RunContext = RunContext.new(map, LoopTuning.new())
	assert_push_error("unknown building id")
	ctx.buildings.apply_next_tier(&"a")

	var income: Dictionary = ctx.buildings.dawn_income_by_spot()

	assert_true(income.is_empty(), "an unknown building pays nothing and does not crash")
