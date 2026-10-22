extends GutTest
## Plan 05-11, research Pattern 9: the castle-aware bots. Each carries the castle plot three times
## (tiers II to IV) and one deterministic card pick per castle tier, and buys the four new economic
## buildings; the castle's first entry comes after the opening economy (D-01). The orders are
## checked against the shipped map and the shipped castle def, so a card the tier does not offer or
## a plot the map does not hold fails here.

const CASTLE: StringName = &"castle_plot"
const CASTLE_BUILDING: StringName = &"castle_center"
const MIN_ECONOMY_BEFORE_CASTLE: int = 2
const ECONOMY_BUILDINGS: Array[StringName] = [
	&"house", &"gold_mine", &"mill", &"field", &"fishing_harbor"
]
const FIELDS: Array[StringName] = [&"field_1", &"field_2", &"field_3"]
const SHRINES: Array[StringName] = [&"shrine_west", &"shrine_east"]
const EXPECTED_PICKS: Dictionary = {
	&"balanced_castle": [&"masons", &"engineers", &"golden_age"],
	&"army_castle": [&"commander", &"war_horns", &"iron_discipline"],
}
const CASTLE_STRATEGIES: Array[StringName] = [&"balanced_castle", &"army_castle"]


func _building_of(map: MapConfig, spot_id: StringName) -> StringName:
	for spot: BuildSpotDef in map.spots:
		if spot.id == spot_id:
			return spot.building_id
	return &""


func _castle_def(map: MapConfig) -> BuildingDef:
	for building_def: BuildingDef in map.buildings:
		if building_def.id == CASTLE_BUILDING:
			return building_def
	return null


func test_each_castle_bot_buys_the_castle_plot_three_times() -> void:
	for strategy: StringName in CASTLE_STRATEGIES:
		var bot: PlaytestBot = PlaytestStrategies.make(strategy)
		assert_eq(bot.build_order.count(CASTLE), 3, "%s: castle II, III and IV" % strategy)


func test_each_castle_bot_carries_one_pick_per_castle_tier_that_the_tier_offers() -> void:
	var map: MapConfig = E2eSupport.shipped_prototype_map()
	var castle: BuildingDef = _castle_def(map)
	assert_not_null(castle, "the shipped map holds the castle def")
	if castle == null:
		return
	for strategy: StringName in CASTLE_STRATEGIES:
		var picks: Array[StringName] = PlaytestStrategies.make(strategy).card_picks
		assert_eq(picks, EXPECTED_PICKS[strategy], "%s: the deterministic picks" % strategy)
		assert_eq(picks.size(), 3, "%s: one pick per castle tier" % strategy)
		for index: int in range(picks.size()):
			var offered: Array[StringName] = []
			for choice: ChoiceDef in castle.tier_def(index + 2).choices:
				offered.append(choice.id)
			assert_true(
				offered.has(picks[index]),
				"%s: tier %d offers %s" % [strategy, index + 2, picks[index]]
			)


func test_each_castle_bot_buys_every_new_economic_building() -> void:
	for strategy: StringName in CASTLE_STRATEGIES:
		var order: Array[StringName] = PlaytestStrategies.make(strategy).build_order
		for spot_id: StringName in [&"gold_mine_1", &"mill_1", &"harbor_1"]:
			assert_true(order.has(spot_id), "%s buys %s" % [strategy, spot_id])
		var fields: int = 0
		var shrines: int = 0
		for field: StringName in FIELDS:
			fields += 1 if order.has(field) else 0
		for shrine: StringName in SHRINES:
			shrines += 1 if order.has(shrine) else 0
		assert_gte(fields, 1, "%s buys at least one Field" % strategy)
		assert_gte(shrines, 1, "%s buys at least one Shrine" % strategy)


func test_the_castle_is_not_bought_before_the_opening_economy() -> void:
	## D-01: the first upgrade is a real trade-off, so the order spends on the economy first.
	var map: MapConfig = E2eSupport.shipped_prototype_map()
	for strategy: StringName in CASTLE_STRATEGIES:
		var order: Array[StringName] = PlaytestStrategies.make(strategy).build_order
		var first: int = order.find(CASTLE)
		assert_gte(first, 2, "%s: not among the first two entries" % strategy)
		var economy: int = 0
		for index: int in range(first):
			if ECONOMY_BUILDINGS.has(_building_of(map, order[index])):
				economy += 1
		assert_gte(
			economy,
			MIN_ECONOMY_BEFORE_CASTLE,
			"%s: at least two economy entries before the castle" % strategy
		)


func test_the_castle_comes_before_the_first_tier_that_needs_it() -> void:
	var map: MapConfig = E2eSupport.shipped_prototype_map()
	for strategy: StringName in CASTLE_STRATEGIES:
		var order: Array[StringName] = PlaytestStrategies.make(strategy).build_order
		assert_gt(order.find(&"tower_1", order.find(&"tower_1") + 1), order.find(CASTLE), strategy)
		assert_eq(_building_of(map, CASTLE), CASTLE_BUILDING, "%s: the castle plot" % strategy)


func test_the_castle_bots_keep_the_family_settings_of_their_phase_four_twins() -> void:
	var balanced: PlaytestBot = PlaytestStrategies.make(&"balanced_castle")
	var army: PlaytestBot = PlaytestStrategies.make(&"army_castle")
	assert_true(balanced.prefer_telegraphed_towers, "balanced_castle follows the telegraph")
	assert_eq(balanced.night_orders.size(), 0, "and gives no squad orders")
	assert_eq(army.night_orders.size(), 2, "army_castle gives its two night orders")
	assert_eq(army.slam_min_enemies, 3, "and slams the same way")
	assert_eq(army.king_mode, PlaytestBot.KING_DEFEND_NEAREST_THREAT, "the king defends")


func test_the_telegraph_never_reorders_the_castle_or_a_shrine_among_the_tower_plots() -> void:
	var ctx: RunContext = RunContext.new(
		E2eSupport.shipped_prototype_map(), load("res://data/tuning/loop_tuning.tres"), 1
	)
	var bot: PlaytestBot = PlaytestBot.new()
	assert_false(bot._is_tower_plot(ctx, CASTLE), "the castle plot is not a road tower")
	for shrine: StringName in SHRINES:
		assert_false(bot._is_tower_plot(ctx, shrine), "%s is not a road tower" % shrine)
	assert_true(bot._is_tower_plot(ctx, &"tower_1"), "a Tower plot still is")
	assert_false(bot._is_tower_plot(ctx, &"house_1"), "a House plot is not")
	assert_false(bot._is_tower_plot(ctx, &"no_such_plot"), "an unknown plot is not")
