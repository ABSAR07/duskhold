extends GutTest
## Pitfall 1, BLDG-09: a bot whose next entry is locked (castle_tier or needs_spot) defers that
## entry and keeps buying the later ones, retrying the deferred entries on every think, so a gate
## never stalls a whole build order. An unaffordable entry still waits in place, as it always did.
## The shipped data has no gated tier in this plan, so no shipped strategy ever defers.

const FIXTURE := "res://tests/fixtures/fixture_map_gate.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const TOWER: StringName = &"tower_1"
const HOUSE_A: StringName = &"house_a"
const HOUSE_B: StringName = &"house_b"
const CASTLE: StringName = &"castle_plot"
const CARD: StringName = &"royal_training"


func _context(gold: int = 80) -> RunContext:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate(true)
	map.starting_gold = gold
	return RunContext.new(map, load(TUNING))


func _bot(order: Array[StringName]) -> PlaytestBot:
	var bot: PlaytestBot = PlaytestBot.new()
	bot.build_order = order
	bot.start_nights = false
	return bot


func test_a_locked_entry_is_deferred_and_the_later_entries_are_still_bought() -> void:
	var ctx: RunContext = _context()
	var bot: PlaytestBot = _bot([TOWER, TOWER, HOUSE_A, HOUSE_B] as Array[StringName])
	bot.think(ctx)
	assert_eq(ctx.buildings.current_tier(TOWER), 1, "Tower I was bought")
	assert_eq(ctx.buildings.current_tier(HOUSE_A), 1, "house_a was bought past the locked entry")
	assert_eq(ctx.buildings.current_tier(HOUSE_B), 1, "and house_b right behind it")


func test_the_deferred_entry_is_bought_once_the_castle_stands_at_the_tier() -> void:
	var ctx: RunContext = _context()
	var bot: PlaytestBot = _bot([TOWER, TOWER, HOUSE_A, HOUSE_B] as Array[StringName])
	bot.think(ctx)
	bot.think(ctx)
	assert_eq(ctx.buildings.current_tier(TOWER), 1, "still locked on the second think")
	var result: StringName = ctx.commands.submit(BuildIntent.new(CASTLE, CARD))
	assert_eq(result, CommandProcessor.OK, "castle II is bought directly")
	bot.think(ctx)
	assert_eq(ctx.buildings.current_tier(TOWER), 2, "the deferred Tower II is bought")


func test_a_plot_needing_another_is_deferred_until_that_plot_stands() -> void:
	var ctx: RunContext = _context()
	var bot: PlaytestBot = _bot([HOUSE_B, HOUSE_A] as Array[StringName])
	bot.think(ctx)
	assert_eq(ctx.buildings.current_tier(HOUSE_A), 1, "house_a was bought")
	assert_eq(ctx.buildings.current_tier(HOUSE_B), 0, "house_b was deferred, not skipped for good")
	bot.think(ctx)
	assert_eq(ctx.buildings.current_tier(HOUSE_B), 1, "and bought on the next think")


func test_a_bot_whose_only_entry_is_permanently_locked_keeps_its_gold() -> void:
	var ctx: RunContext = _context()
	var gold: int = ctx.economy.get_gold()
	var bot: PlaytestBot = _bot([HOUSE_B] as Array[StringName])
	for _think: int in range(5):
		bot.think(ctx)
	assert_eq(ctx.buildings.current_tier(HOUSE_B), 0, "never built")
	assert_eq(ctx.economy.get_gold(), gold, "nothing spent")


func test_deferred_entries_are_retried_in_their_original_order() -> void:
	var ctx: RunContext = _context()
	var bot: PlaytestBot = _bot([TOWER, TOWER, HOUSE_B, HOUSE_A] as Array[StringName])
	var order: Array[StringName] = []
	ctx.events.building_built.connect(
		func(spot_id: StringName, _id: StringName, _tier: int) -> void: order.append(spot_id)
	)
	bot.think(ctx)
	assert_eq(order, [TOWER, HOUSE_A] as Array[StringName], "house_b waits for house_a")
	assert_eq(ctx.commands.submit(BuildIntent.new(CASTLE, CARD)), CommandProcessor.OK, "castle II")
	order.clear()
	bot.think(ctx)
	assert_eq(order, [TOWER, HOUSE_B] as Array[StringName], "the deferred entries, in order")


func test_an_unaffordable_entry_still_waits_in_place() -> void:
	var ctx: RunContext = _context(2)
	var bot: PlaytestBot = _bot([TOWER, HOUSE_A] as Array[StringName])
	bot.think(ctx)
	assert_eq(ctx.buildings.current_tier(TOWER), 0, "Tower I costs more than the gold")
	assert_eq(ctx.buildings.current_tier(HOUSE_A), 0, "and the cheap entry behind it waits too")
	assert_eq(ctx.economy.get_gold(), 2, "nothing was spent")
	ctx.economy.grant(10)
	bot.think(ctx)
	assert_eq(ctx.buildings.current_tier(TOWER), 1, "Tower I once the gold is there")
	assert_eq(ctx.buildings.current_tier(HOUSE_A), 1, "then the House")


func test_an_entry_that_became_max_tier_is_dropped_from_the_deferred_list() -> void:
	var ctx: RunContext = _context()
	var bot: PlaytestBot = _bot([TOWER, TOWER, TOWER] as Array[StringName])
	bot.think(ctx)
	assert_eq(ctx.commands.submit(BuildIntent.new(CASTLE, CARD)), CommandProcessor.OK, "castle II")
	bot.think(ctx)
	assert_eq(ctx.buildings.current_tier(TOWER), 2, "Tower II")
	var gold: int = ctx.economy.get_gold()
	bot.think(ctx)
	assert_eq(ctx.economy.get_gold(), gold, "the third entry is max tier and buys nothing")


func test_a_shipped_strategy_on_the_shipped_map_never_defers() -> void:
	var shipped: MapConfig = E2eSupport.shipped_prototype_map()
	for building_def: BuildingDef in shipped.buildings:
		for index: int in range(building_def.tiers.size()):
			var tier: BuildingTierDef = building_def.tiers[index]
			assert_eq(
				tier.requires_castle_tier, 0, "%s tier %d is ungated" % [building_def.id, index + 1]
			)
	for spot: BuildSpotDef in shipped.spots:
		assert_eq(spot.requires_spot, &"", "%s needs no other plot" % spot.id)
