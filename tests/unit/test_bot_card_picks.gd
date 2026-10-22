extends GutTest
## BLDG-05, D-08: a PlaytestBot with `card_picks` takes the first listed card the branching tier
## offers (BuildIntent.choice_id), removes it from the list and never meets choice_required. A
## listed card the tier does not offer is skipped for the next listed one and kept for a later
## tier. With no acceptable card the entry is deferred like a locked one, so the later entries are
## still bought.

const FIXTURE := "res://tests/fixtures/fixture_map_castle.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const CASTLE: StringName = &"castle_plot"
const HOUSE: StringName = &"house_1"
const MASONS: StringName = &"masons"
const ENGINEERS: StringName = &"engineers"
const ROYAL: StringName = &"royal_training"

var _rejections: Array = []
var _picks: Array[String] = []


func before_each() -> void:
	_rejections = []
	_picks = []


func _context(gold: int = 80) -> RunContext:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate(true)
	map.starting_gold = gold
	var ctx: RunContext = RunContext.new(map, load(TUNING))
	ctx.events.command_rejected.connect(
		func(command: StringName, spot_id: StringName, reason: StringName) -> void:
			_rejections.append([command, spot_id, reason])
	)
	ctx.events.choice_picked.connect(
		func(spot_id: StringName, tier: int, choice_id: StringName) -> void:
			_picks.append("%s %d %s" % [spot_id, tier, choice_id])
	)
	return ctx


func _bot(order: Array[StringName], picks: Array[StringName]) -> PlaytestBot:
	var bot: PlaytestBot = PlaytestBot.new()
	bot.build_order = order
	bot.card_picks = picks
	bot.start_nights = false
	return bot


func test_the_bot_buys_tier_two_and_three_with_the_listed_cards() -> void:
	var ctx: RunContext = _context()
	var bot: PlaytestBot = _bot([CASTLE, CASTLE] as Array[StringName], [MASONS, ENGINEERS])
	bot.think(ctx)
	assert_eq(ctx.buildings.current_tier(CASTLE), 3, "tier III stands")
	assert_eq(_picks, ["castle_plot 2 masons", "castle_plot 3 engineers"], "one card per tier")
	assert_eq(_rejections, [], "no command was rejected, so no choice_required")


func test_a_card_the_tier_does_not_offer_is_skipped_for_the_next_listed_one() -> void:
	var ctx: RunContext = _context()
	var bot: PlaytestBot = _bot([CASTLE, CASTLE] as Array[StringName], [ENGINEERS, MASONS])
	bot.think(ctx)
	assert_eq(_picks, ["castle_plot 2 masons", "castle_plot 3 engineers"], "skipped, then kept")
	assert_eq(_rejections, [], "and nothing was rejected")


func test_a_used_card_leaves_the_list() -> void:
	var ctx: RunContext = _context()
	var bot: PlaytestBot = _bot([CASTLE] as Array[StringName], [ROYAL, MASONS])
	bot.think(ctx)
	assert_eq(_picks, ["castle_plot 2 royal_training"], "the first listed card tier II offers")
	assert_eq(bot.card_picks, [MASONS] as Array[StringName], "only the unused card is left")


func test_a_bot_with_no_card_defers_a_branching_entry_like_a_locked_one() -> void:
	var ctx: RunContext = _context()
	var bot: PlaytestBot = _bot([CASTLE, HOUSE] as Array[StringName], [])
	bot.think(ctx)
	assert_eq(ctx.buildings.current_tier(CASTLE), 1, "the castle stayed at tier I without a card")
	assert_eq(ctx.buildings.current_tier(HOUSE), 1, "the later entry was still bought")
	assert_eq(_rejections, [], "and no choice_required was ever announced")


func test_a_deferred_branching_entry_is_bought_once_a_card_is_listed() -> void:
	var ctx: RunContext = _context()
	var bot: PlaytestBot = _bot([CASTLE] as Array[StringName], [])
	bot.think(ctx)
	assert_eq(ctx.buildings.current_tier(CASTLE), 1, "deferred with no card")
	bot.card_picks = [MASONS] as Array[StringName]
	bot.think(ctx)
	assert_eq(ctx.buildings.current_tier(CASTLE), 2, "bought on the next think")
	assert_eq(_picks, ["castle_plot 2 masons"], "with the listed card")


func test_a_card_that_is_never_offered_defers_the_entry_for_good() -> void:
	var ctx: RunContext = _context()
	var gold: int = ctx.economy.get_gold()
	var bot: PlaytestBot = _bot([CASTLE] as Array[StringName], [ENGINEERS])
	for _think: int in range(3):
		bot.think(ctx)
	assert_eq(ctx.buildings.current_tier(CASTLE), 1, "tier II offers no engineers")
	assert_eq(ctx.economy.get_gold(), gold, "nothing was spent")
	assert_eq(bot.card_picks, [ENGINEERS] as Array[StringName], "the card stays listed")
