extends GutTest
## BLDG-05, D-05: a tier with cards cannot be bought without one. validate_build checks NOT_DAY,
## UNKNOWN_SPOT, MAX_TIER, CANNOT_AFFORD, then CHOICE_REQUIRED and BAD_CHOICE; a rejection announces
## command_rejected and spends nothing; a purchase with a card emits building_built then
## choice_picked and the ledger arms the card's modifiers under the card's id. Every price and card
## is read from castle_center.tres, so a retune of the numbers cannot break the test.

const FIXTURE := "res://tests/fixtures/fixture_map_castle.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const CASTLE: StringName = &"castle_plot"
const HOUSE: StringName = &"house_1"
const ROYAL: StringName = &"royal_training"
const COMMANDER: StringName = &"commander"
const MASONS: StringName = &"masons"
const PROSPERITY: StringName = &"prosperity"
const HEADSMANS_EDGE: StringName = &"headsmans_edge"
const GRANTED_GOLD: int = 100

var _ctx: RunContext
var _rejections: Array = []
var _log: Array[String] = []


func before_each() -> void:
	_rejections = []
	_log = []
	_ctx = _context_with_gold(GRANTED_GOLD)


## A run on the castle fixture holding exactly `gold` at the start.
func _context_with_gold(gold: int) -> RunContext:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate(true)
	map.starting_gold = gold
	var ctx: RunContext = RunContext.new(map, load(TUNING))
	ctx.events.command_rejected.connect(_on_rejected)
	ctx.events.building_built.connect(_on_built)
	ctx.events.choice_picked.connect(_on_picked)
	return ctx


func _on_rejected(command: StringName, spot_id: StringName, reason: StringName) -> void:
	_rejections.append([command, spot_id, reason])


func _on_built(spot_id: StringName, _building_id: StringName, new_tier: int) -> void:
	_log.append("built %s %d" % [spot_id, new_tier])


func _on_picked(spot_id: StringName, tier: int, choice_id: StringName) -> void:
	_log.append("picked %s %d %s" % [spot_id, tier, choice_id])


func _castle_def() -> BuildingDef:
	return load("res://data/buildings/castle_center.tres")


func _tier_cost(tier: int) -> int:
	return _castle_def().tier_def(tier).cost


func _card_ids(tier: int) -> Array[StringName]:
	var ids: Array[StringName] = []
	for card: ChoiceDef in _castle_def().tier_def(tier).choices:
		ids.append(card.id)
	return ids


func _buy_tier_two(card: StringName) -> void:
	assert_eq(_ctx.commands.submit(BuildIntent.new(CASTLE, card)), CommandProcessor.OK, "tier II")


func test_the_tier_two_cards_are_the_four_abilities_in_the_authored_order() -> void:
	assert_eq(_card_ids(2), [ROYAL, COMMANDER, MASONS, PROSPERITY] as Array[StringName], "order")
	assert_true(_card_ids(1).is_empty(), "tier I carries no cards")
	assert_eq(_card_ids(3).size(), 4, "tier III offers four of its own (plan 05-03)")


func test_with_the_gold_a_branching_tier_asks_for_a_card() -> void:
	var ctx: RunContext = _context_with_gold(_tier_cost(2))
	assert_eq(ctx.commands.validate_build(CASTLE), CommandProcessor.CHOICE_REQUIRED, "no card")
	assert_eq(ctx.commands.validate_build(CASTLE, COMMANDER), CommandProcessor.OK, "a card")


func test_one_gold_short_is_cannot_afford_with_or_without_a_card() -> void:
	var ctx: RunContext = _context_with_gold(_tier_cost(2) - 1)
	assert_eq(ctx.commands.validate_build(CASTLE), CommandProcessor.CANNOT_AFFORD, "no card")
	assert_eq(
		ctx.commands.validate_build(CASTLE, COMMANDER), CommandProcessor.CANNOT_AFFORD, "card"
	)


func test_a_card_the_tier_does_not_offer_is_a_bad_choice() -> void:
	assert_eq(_ctx.commands.validate_build(CASTLE, &"no_such_card"), CommandProcessor.BAD_CHOICE)


func test_a_card_at_a_plain_tier_is_a_bad_choice_and_no_card_is_fine() -> void:
	assert_eq(_ctx.commands.validate_build(HOUSE), CommandProcessor.OK, "a plain tier needs none")
	assert_eq(_ctx.commands.validate_build(HOUSE, COMMANDER), CommandProcessor.BAD_CHOICE, "bad")


func test_an_unknown_spot_is_reported_before_the_card_is_looked_at() -> void:
	assert_eq(_ctx.commands.validate_build(&"nowhere", COMMANDER), CommandProcessor.UNKNOWN_SPOT)


func test_the_night_is_reported_before_the_card_is_looked_at() -> void:
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night begins")
	assert_eq(_ctx.commands.validate_build(CASTLE, &"no_such_card"), CommandProcessor.NOT_DAY)


func test_submitting_without_a_card_is_refused_and_spends_nothing() -> void:
	var result: StringName = _ctx.commands.submit(BuildIntent.new(CASTLE))
	assert_eq(result, CommandProcessor.CHOICE_REQUIRED, "refused")
	assert_eq(_rejections, [[&"build", CASTLE, &"choice_required"]], "announced")
	assert_eq(_ctx.economy.get_gold(), GRANTED_GOLD, "nothing spent")
	assert_eq(_ctx.buildings.current_tier(CASTLE), 1, "the castle stays at tier I")
	assert_true(_ctx.stat_stack.source_ids().is_empty(), "and nothing is armed")
	assert_true(_log.is_empty(), "no building_built and no choice_picked")


func test_submitting_a_bad_card_is_refused_and_spends_nothing() -> void:
	var result: StringName = _ctx.commands.submit(BuildIntent.new(CASTLE, &"no_such_card"))
	assert_eq(result, CommandProcessor.BAD_CHOICE, "refused")
	assert_eq(_rejections, [[&"build", CASTLE, &"bad_choice"]], "announced")
	assert_eq(_ctx.economy.get_gold(), GRANTED_GOLD, "nothing spent")
	assert_eq(_ctx.buildings.current_tier(CASTLE), 1, "no tier")


func test_a_card_at_a_plain_tier_is_refused_when_submitted() -> void:
	var result: StringName = _ctx.commands.submit(BuildIntent.new(HOUSE, COMMANDER))
	assert_eq(result, CommandProcessor.BAD_CHOICE, "refused")
	assert_eq(_ctx.buildings.current_tier(HOUSE), 0, "the House was not built")
	assert_eq(_ctx.economy.get_gold(), GRANTED_GOLD, "nothing spent")


func test_buying_with_the_second_card_spends_the_cost_and_raises_the_tier() -> void:
	_buy_tier_two(COMMANDER)
	assert_eq(_ctx.economy.get_gold(), GRANTED_GOLD - _tier_cost(2), "the cost was spent")
	assert_eq(_ctx.buildings.current_tier(CASTLE), 2, "the castle is tier II")
	assert_true(_rejections.is_empty(), "nothing was refused")


func test_building_built_comes_before_choice_picked() -> void:
	_buy_tier_two(COMMANDER)
	assert_eq(_log, ["built castle_plot 2", "picked castle_plot 2 commander"], "in that order")


func test_the_picked_card_is_armed_once_under_its_own_id() -> void:
	_buy_tier_two(COMMANDER)
	assert_true(_ctx.stat_stack.has_source(COMMANDER), "armed")
	assert_eq(_ctx.stat_stack.source_ids(), [COMMANDER] as Array[StringName], "and only it")
	assert_eq(_ctx.choices.picks_of(CASTLE), [COMMANDER] as Array[StringName], "recorded")
	assert_eq(_ctx.choices.all_picks(), [COMMANDER] as Array[StringName], "in the ledger")


func test_the_armed_card_changes_the_stats_by_exactly_the_card_data() -> void:
	_buy_tier_two(COMMANDER)
	var expected: StatStack = StatStack.new()
	expected.add_source(COMMANDER, _ctx.choices.find_choice(COMMANDER).modifiers)
	assert_eq(
		_ctx.stat_stack.int_value(&"unit.max_health", 10),
		expected.int_value(&"unit.max_health", 10),
		"unit health"
	)
	assert_gt(_ctx.stat_stack.int_value(&"unit.max_health", 10), 10, "and it really rose")
	assert_false(_ctx.stat_stack.is_modified(&"king.max_health"), "other stats are untouched")


func test_a_tier_two_card_offered_at_tier_three_is_a_bad_choice() -> void:
	_buy_tier_two(ROYAL)
	assert_eq(_ctx.commands.validate_build(CASTLE, ROYAL), CommandProcessor.BAD_CHOICE, "once")
	assert_eq(_ctx.commands.validate_build(CASTLE, COMMANDER), CommandProcessor.BAD_CHOICE, "any")
	assert_eq(_ctx.commands.validate_build(CASTLE), CommandProcessor.CHOICE_REQUIRED, "needs one")
	assert_eq(_ctx.commands.validate_build(CASTLE, HEADSMANS_EDGE), CommandProcessor.OK, "its own")


func test_a_later_pick_adds_to_the_first_and_never_replaces_it() -> void:
	_buy_tier_two(MASONS)
	_log.clear()
	var result: StringName = _ctx.commands.submit(BuildIntent.new(CASTLE, HEADSMANS_EDGE))
	assert_eq(result, CommandProcessor.OK, "tier III")
	assert_eq(_log, ["built castle_plot 3", "picked castle_plot 3 headsmans_edge"], "both lines")
	assert_eq(
		_ctx.choices.all_picks(), [MASONS, HEADSMANS_EDGE] as Array[StringName], "in pick order"
	)
	assert_true(_ctx.stat_stack.has_source(MASONS), "the first stays armed")
	assert_true(_ctx.stat_stack.has_source(HEADSMANS_EDGE), "and the second joins it")


func test_the_pick_is_one_line_of_the_replay_digest() -> void:
	var recorder: SimRecorder = SimRecorder.attach(_ctx)
	_buy_tier_two(PROSPERITY)
	var lines: PackedStringArray = recorder.lines()
	var built: int = lines.find("0 building_built castle_plot castle_center 2")
	assert_gte(built, 0, "the purchase is recorded")
	assert_eq(lines[built + 1], "0 choice_picked castle_plot 2 prosperity", "the pick follows it")


func test_an_unknown_card_is_not_found_by_the_ledger() -> void:
	assert_null(_ctx.choices.find_choice(&"no_such_card"), "unknown")
	assert_null(_ctx.choices.find_choice(&""), "empty")
	assert_not_null(_ctx.choices.find_choice(PROSPERITY), "a real card")
	assert_true(_ctx.choices.picks_of(HOUSE).is_empty(), "no pick at a House")
