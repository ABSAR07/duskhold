extends GutTest
## BLDG-02 / D-07 / D-08: SpotLabelModel.describe turns RunContext data into the label content.
## It is pure: no Nodes and no mutation of the context. Expectations come from .tres data.

const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const POOR_MAP := "res://tests/fixtures/fixture_map_poor.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const RICH_GOLD: int = 50
const HOUSE_SPOT: StringName = &"house_1"
const TOWER_SPOT: StringName = &"tower_1"
const POOR_SPOT: StringName = &"spot_a"
const MAX_TIER_TEXT := "Max tier"


func _context(map_path: String, gold: int = -1) -> RunContext:
	var map: MapConfig = (load(map_path) as MapConfig).duplicate(true)
	if gold >= 0:
		map.starting_gold = gold
	return RunContext.new(map, load(TUNING))


func _describe(ctx: RunContext, spot_id: StringName, coins_paid: int = 0) -> Dictionary:
	return SpotLabelModel.describe(ctx, spot_id, coins_paid)


func _build(ctx: RunContext, spot_id: StringName, times: int) -> void:
	for _i: int in range(times):
		assert_eq(ctx.commands.submit(BuildIntent.new(spot_id)), CommandProcessor.OK, "build ok")


func test_an_empty_house_plot_offers_tier_one_with_its_cost_and_income_effect() -> void:
	var ctx: RunContext = _context(PROTOTYPE_MAP, RICH_GOLD)
	var house: BuildingDef = ctx.buildings.get_building_def_for_spot(HOUSE_SPOT)
	var tier_one: BuildingTierDef = house.tier_def(1)
	var content: Dictionary = _describe(ctx, HOUSE_SPOT)
	assert_eq(content.get("title"), house.tier_label(1), "title names the next tier")
	assert_eq(content.get("cost"), tier_one.cost, "cost is the tier I price")
	assert_eq(content.get("effect"), "+%d gold at dawn" % tier_one.dawn_income, "income effect")
	assert_eq(content.get("max_tier"), false, "a House can still be bought")
	assert_eq(content.get("status_line"), "", "no status while something can be bought")
	assert_eq(content.get("paid"), 0, "nothing paid yet")


func test_after_one_build_the_label_offers_tier_two() -> void:
	var ctx: RunContext = _context(PROTOTYPE_MAP, RICH_GOLD)
	var house: BuildingDef = ctx.buildings.get_building_def_for_spot(HOUSE_SPOT)
	_build(ctx, HOUSE_SPOT, 1)
	var content: Dictionary = _describe(ctx, HOUSE_SPOT)
	assert_eq(content.get("title"), house.tier_label(2), "title names tier II")
	assert_eq(content.get("cost"), house.tier_def(2).cost, "cost is the tier II price")
	assert_eq(content.get("effect"), house.tier_def(2).effect_line(), "tier II effect")
	assert_eq(content.get("max_tier"), false, "tier III is still to come")


func test_at_max_tier_the_label_shows_the_current_tier_and_max_tier() -> void:
	var ctx: RunContext = _context(PROTOTYPE_MAP, RICH_GOLD)
	var house: BuildingDef = ctx.buildings.get_building_def_for_spot(HOUSE_SPOT)
	_build(ctx, HOUSE_SPOT, house.max_tier())
	var content: Dictionary = _describe(ctx, HOUSE_SPOT)
	assert_eq(content.get("title"), house.tier_label(house.max_tier()), "title is the top tier")
	assert_eq(content.get("max_tier"), true, "flagged as max tier")
	assert_eq(content.get("cost"), 0, "nothing left to pay")
	assert_eq(content.get("status_line"), MAX_TIER_TEXT, "status says Max tier")
	assert_eq(content.get("effect"), "", "no effect line at the top")
	assert_eq(content.get("affordable"), true, "a max tier plot is never shown as too dear")


func test_an_empty_tower_plot_shows_the_tier_one_range_and_damage_effect() -> void:
	var ctx: RunContext = _context(PROTOTYPE_MAP, RICH_GOLD)
	var tower: BuildingDef = ctx.buildings.get_building_def_for_spot(TOWER_SPOT)
	var content: Dictionary = _describe(ctx, TOWER_SPOT)
	assert_eq(content.get("title"), tower.tier_label(1), "title is Tower I")
	assert_eq(content.get("effect"), tower.tier_def(1).effect_line(), "range and damage")
	assert_eq(content.get("cost"), tower.tier_def(1).cost, "tier I tower price")


func test_affordable_is_false_when_gold_is_short_and_true_while_a_hold_is_in_progress() -> void:
	var ctx: RunContext = _context(POOR_MAP)
	var cost: int = ctx.buildings.next_action_cost(POOR_SPOT)
	assert_lt(ctx.economy.get_gold(), cost, "the fixture cannot pay for its hut")
	assert_eq(_describe(ctx, POOR_SPOT, 0).get("affordable"), false, "too dear at rest")
	assert_eq(_describe(ctx, POOR_SPOT, 1).get("affordable"), true, "a running hold was affordable")


func test_affordable_is_true_when_gold_covers_the_cost() -> void:
	var ctx: RunContext = _context(PROTOTYPE_MAP, RICH_GOLD)
	assert_eq(_describe(ctx, HOUSE_SPOT).get("affordable"), true, "plenty of gold")


func test_paid_equals_the_coins_argument_clamped_to_zero_and_cost() -> void:
	var ctx: RunContext = _context(PROTOTYPE_MAP, RICH_GOLD)
	var cost: int = ctx.buildings.next_action_cost(HOUSE_SPOT)
	assert_eq(_describe(ctx, HOUSE_SPOT, 1).get("paid"), 1, "in range passes through")
	assert_eq(_describe(ctx, HOUSE_SPOT, -3).get("paid"), 0, "never negative")
	assert_eq(_describe(ctx, HOUSE_SPOT, cost + 10).get("paid"), cost, "never above the cost")


func test_describe_does_not_touch_the_simulation() -> void:
	var ctx: RunContext = _context(PROTOTYPE_MAP, RICH_GOLD)
	var gold_before: int = ctx.economy.get_gold()
	watch_signals(ctx.events)
	_describe(ctx, HOUSE_SPOT, 2)
	_describe(ctx, TOWER_SPOT, 0)
	assert_eq(ctx.economy.get_gold(), gold_before, "gold unchanged")
	assert_eq(ctx.buildings.current_tier(HOUSE_SPOT), 0, "no building appeared")
	assert_signal_not_emitted(ctx.events, "gold_changed")
	assert_signal_not_emitted(ctx.events, "building_built")


func test_an_unknown_spot_yields_an_empty_label() -> void:
	var ctx: RunContext = _context(PROTOTYPE_MAP, RICH_GOLD)
	var content: Dictionary = _describe(ctx, &"nowhere")
	assert_eq(content.get("title"), "", "no title")
	assert_eq(content.get("cost"), 0, "no cost")
	assert_eq(content.get("max_tier"), false, "not max tier")
	assert_eq(content.get("affordable"), false, "nothing to afford")
