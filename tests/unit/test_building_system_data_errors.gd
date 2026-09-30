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
	assert_same(ctx.buildings.get_spot(&"a"), map.spots[0], "the first definition is the one kept")


func test_a_duplicate_building_id_keeps_the_first_definition() -> void:
	var map: MapConfig = _valid_map()
	var twin_tier: BuildingTierDef = BuildingTierDef.new()
	twin_tier.cost = 99
	twin_tier.dawn_income = 50
	var twin: BuildingDef = BuildingDef.new()
	twin.id = map.buildings[0].id
	twin.tiers = [twin_tier]
	map.buildings.append(twin)

	var ctx: RunContext = RunContext.new(map, LoopTuning.new())

	assert_push_error("duplicate building id")
	assert_same(
		ctx.buildings.get_building_def_for_spot(&"a"), map.buildings[0], "the first def is kept"
	)
	assert_eq(ctx.buildings.next_action_cost(&"a"), 2, "the first def's tier table is used")


func test_a_spot_with_an_empty_id_is_skipped_and_never_focusable() -> void:
	var map: MapConfig = _valid_map()
	var nameless: BuildSpotDef = BuildSpotDef.new()
	nameless.building_id = &"hut"
	nameless.position = Vector3(1.0, 0.0, 0.0)
	map.spots.append(nameless)

	var ctx: RunContext = RunContext.new(map, LoopTuning.new())

	assert_push_error("empty id")
	assert_eq(ctx.buildings.spot_ids(), [&"a"] as Array[StringName], "only the named spot is kept")
	assert_null(ctx.buildings.get_spot(&""), "an empty id is an unknown spot")
	assert_eq(
		ctx.commands.submit(BuildIntent.new(&"")),
		CommandProcessor.UNKNOWN_SPOT,
		"so it is rejected"
	)


func test_apply_next_tier_refuses_a_building_no_map_building_defines() -> void:
	var map: MapConfig = _valid_map()
	map.spots[0].building_id = &"castle_of_dreams"
	var ctx: RunContext = RunContext.new(map, LoopTuning.new())
	assert_push_error("unknown building id")
	watch_signals(ctx.events)

	var instance: BuildingInstance = ctx.buildings.apply_next_tier(&"a")

	assert_null(instance, "nothing is built for a building with no definition")
	assert_null(ctx.buildings.get_instance(&"a"), "and no instance is recorded")
	assert_signal_not_emitted(ctx.events, "building_built")
	assert_true(ctx.buildings.dawn_income_by_spot().is_empty(), "so it pays nothing")


func test_apply_next_tier_never_raises_a_building_past_its_last_tier() -> void:
	var ctx: RunContext = RunContext.new(_valid_map(), LoopTuning.new())
	assert_not_null(ctx.buildings.apply_next_tier(&"a"), "tier I builds")
	watch_signals(ctx.events)

	var beyond: BuildingInstance = ctx.buildings.apply_next_tier(&"a")

	assert_null(beyond, "the hut has one tier only")
	assert_eq(ctx.buildings.current_tier(&"a"), 1, "the tier did not move")
	assert_signal_not_emitted(ctx.events, "building_built")
