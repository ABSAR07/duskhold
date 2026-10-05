extends GutTest
## BLDG-04: upgrading walks a building's tiers in order through the same validated command
## path as building, deducts each tier's cost, and is rejected with max_tier at the top.
## Every expected number is derived from loaded data.

const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const RICH_GOLD: int = 50


func _rich_context() -> RunContext:
	var map: MapConfig = (load(PROTOTYPE_MAP) as MapConfig).duplicate(true)
	map.starting_gold = RICH_GOLD
	return RunContext.new(map, load(TUNING))


func _first_spot_of(ctx: RunContext, building_id: StringName) -> StringName:
	for spot_id: StringName in ctx.buildings.spot_ids():
		if ctx.buildings.get_spot(spot_id).building_id == building_id:
			return spot_id
	return &""


func _climb_to_the_top(ctx: RunContext, spot_id: StringName) -> void:
	var building_def: BuildingDef = ctx.buildings.get_building_def_for_spot(spot_id)
	for tier: int in range(1, building_def.max_tier() + 1):
		var gold_before: int = ctx.economy.get_gold()
		watch_signals(ctx.events)
		var result: StringName = ctx.commands.submit(BuildIntent.new(spot_id))
		assert_eq(result, CommandProcessor.OK, "%s tier %d accepted" % [spot_id, tier])
		var spent: int = gold_before - ctx.economy.get_gold()
		assert_eq(spent, building_def.tier_def(tier).cost, "tier %d deducts its own cost" % tier)
		assert_eq(ctx.buildings.current_tier(spot_id), tier, "current_tier follows")
		assert_signal_emitted_with_parameters(
			ctx.events, "building_built", [spot_id, building_def.id, tier]
		)


func _assert_capped(ctx: RunContext, spot_id: StringName) -> void:
	var building_def: BuildingDef = ctx.buildings.get_building_def_for_spot(spot_id)
	var gold_at_top: int = ctx.economy.get_gold()
	clear_signal_watcher()
	watch_signals(ctx.events)
	var result: StringName = ctx.commands.submit(BuildIntent.new(spot_id))
	assert_eq(result, CommandProcessor.MAX_TIER, "one past the top is max_tier")
	assert_signal_emitted_with_parameters(
		ctx.events, "command_rejected", [&"build", spot_id, CommandProcessor.MAX_TIER]
	)
	assert_signal_not_emitted(ctx.events, "building_built")
	assert_eq(ctx.economy.get_gold(), gold_at_top, "gold unchanged")
	assert_eq(ctx.buildings.current_tier(spot_id), building_def.max_tier(), "tier unchanged")
	assert_eq(ctx.buildings.next_action_cost(spot_id), -1, "nothing left to buy")
	assert_null(building_def.tier_def(building_def.max_tier() + 1), "no next tier at the top")


func test_house_upgrades_through_all_three_tiers_then_hits_max_tier() -> void:
	var ctx: RunContext = _rich_context()
	var spot_id: StringName = _first_spot_of(ctx, &"house")
	assert_ne(spot_id, &"", "the map has a House plot")
	_climb_to_the_top(ctx, spot_id)
	_assert_capped(ctx, spot_id)


func test_tower_upgrades_through_both_tiers_then_hits_max_tier() -> void:
	var ctx: RunContext = _rich_context()
	var spot_id: StringName = _first_spot_of(ctx, &"tower")
	assert_ne(spot_id, &"", "the map has a tower plot")
	_climb_to_the_top(ctx, spot_id)
	_assert_capped(ctx, spot_id)


func test_an_empty_spot_has_a_tier_one_price_and_no_tier() -> void:
	var ctx: RunContext = _rich_context()
	var spot_id: StringName = _first_spot_of(ctx, &"tower")
	var tower: BuildingDef = ctx.buildings.get_building_def_for_spot(spot_id)
	assert_eq(ctx.buildings.current_tier(spot_id), 0, "nothing built yet")
	assert_eq(ctx.buildings.next_action_cost(spot_id), tower.tier_def(1).cost, "tier I price")
