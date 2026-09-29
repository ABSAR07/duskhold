extends GutTest
## Command path (BLDG-03, ECON-01) exercised on a RunContext with no scene tree.
## Every expected number is derived from loaded data so Phase 2 tuning cannot break these tests.

const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const FIXTURE_POOR := "res://tests/fixtures/fixture_map_poor.tres"
const FIXTURE_ONE_TIER := "res://tests/fixtures/fixture_map_one_tier.tres"


func _context_for(map_path: String) -> RunContext:
	var map: MapConfig = load(map_path)
	var tuning: LoopTuning = load(TUNING)
	return RunContext.new(map, tuning)


func _building_count(ctx: RunContext) -> int:
	var count: int = 0
	for spot_id: StringName in ctx.buildings.spot_ids():
		if ctx.buildings.get_instance(spot_id) != null:
			count += 1
	return count


func test_context_is_built_without_touching_the_scene_tree() -> void:
	var nodes_before: int = get_tree().root.get_child_count()
	var ctx: RunContext = _context_for(PROTOTYPE_MAP)
	assert_not_null(ctx.commands, "the command gate exists")
	assert_eq(get_tree().root.get_child_count(), nodes_before, "no Node was added to the tree")
	assert_eq(ctx.economy.get_gold(), ctx.map.starting_gold, "gold starts at the map value")


func test_build_on_empty_affordable_plot_succeeds() -> void:
	var ctx: RunContext = _context_for(PROTOTYPE_MAP)
	var spot_id: StringName = ctx.buildings.spot_ids()[0]
	var house: BuildingDef = ctx.buildings.get_building_def_for_spot(spot_id)
	var cost: int = house.tier_def(1).cost
	var start_gold: int = ctx.economy.get_gold()
	watch_signals(ctx.events)

	var result: StringName = ctx.commands.submit(BuildIntent.new(spot_id))

	assert_eq(result, CommandProcessor.OK, "the build is accepted")
	assert_eq(ctx.economy.get_gold(), start_gold - cost, "gold fell by the tier I cost")
	assert_eq(ctx.buildings.current_tier(spot_id), 1, "the plot now holds a tier I building")
	assert_signal_emitted_with_parameters(ctx.events, "building_built", [spot_id, house.id, 1])
	assert_signal_emitted_with_parameters(ctx.events, "gold_changed", [start_gold - cost, -cost])


func test_build_on_unknown_spot_is_rejected_and_changes_nothing() -> void:
	var ctx: RunContext = _context_for(PROTOTYPE_MAP)
	var start_gold: int = ctx.economy.get_gold()
	watch_signals(ctx.events)

	var result: StringName = ctx.commands.submit(BuildIntent.new(&"no_such_spot"))

	assert_eq(result, CommandProcessor.UNKNOWN_SPOT, "unknown spot reason returned")
	assert_signal_emitted_with_parameters(
		ctx.events, "command_rejected", [&"build", &"no_such_spot", CommandProcessor.UNKNOWN_SPOT]
	)
	assert_eq(ctx.economy.get_gold(), start_gold, "gold unchanged")
	assert_eq(_building_count(ctx), 0, "no building appeared")


func test_build_below_cost_is_rejected_and_changes_nothing() -> void:
	var ctx: RunContext = _context_for(FIXTURE_POOR)
	var start_gold: int = ctx.economy.get_gold()
	var cost: int = ctx.buildings.next_action_cost(&"spot_a")
	assert_true(start_gold < cost, "fixture really is too poor for the first build")
	watch_signals(ctx.events)

	var result: StringName = ctx.commands.submit(BuildIntent.new(&"spot_a"))

	assert_eq(result, CommandProcessor.CANNOT_AFFORD, "cannot_afford reason returned")
	assert_signal_emitted_with_parameters(
		ctx.events, "command_rejected", [&"build", &"spot_a", CommandProcessor.CANNOT_AFFORD]
	)
	assert_eq(ctx.economy.get_gold(), start_gold, "gold unchanged")
	assert_eq(ctx.buildings.current_tier(&"spot_a"), 0, "the plot stayed empty")


func test_second_build_on_a_single_tier_building_hits_max_tier() -> void:
	var ctx: RunContext = _context_for(FIXTURE_ONE_TIER)
	assert_eq(ctx.commands.submit(BuildIntent.new(&"spot_a")), CommandProcessor.OK, "first build")
	var gold_after_first: int = ctx.economy.get_gold()
	watch_signals(ctx.events)

	var result: StringName = ctx.commands.submit(BuildIntent.new(&"spot_a"))

	assert_eq(result, CommandProcessor.MAX_TIER, "max_tier reason returned")
	assert_signal_emitted_with_parameters(
		ctx.events, "command_rejected", [&"build", &"spot_a", CommandProcessor.MAX_TIER]
	)
	assert_eq(ctx.economy.get_gold(), gold_after_first, "gold unchanged")
	assert_eq(ctx.buildings.current_tier(&"spot_a"), 1, "tier unchanged")


func test_upgrade_path_spends_each_tier_cost_in_order() -> void:
	var ctx: RunContext = _context_for(PROTOTYPE_MAP)
	ctx.economy.grant(100)
	var spot_id: StringName = ctx.buildings.spot_ids()[0]
	var house: BuildingDef = ctx.buildings.get_building_def_for_spot(spot_id)
	for tier: int in range(1, house.max_tier() + 1):
		var gold_before: int = ctx.economy.get_gold()
		var result: StringName = ctx.commands.submit(BuildIntent.new(spot_id))
		assert_eq(result, CommandProcessor.OK, "tier %d accepted" % tier)
		var spent: int = gold_before - ctx.economy.get_gold()
		assert_eq(spent, house.tier_def(tier).cost, "tier %d cost" % tier)
		assert_eq(ctx.buildings.current_tier(spot_id), tier, "tier %d reached" % tier)
	var capped: StringName = ctx.commands.submit(BuildIntent.new(spot_id))
	assert_eq(capped, CommandProcessor.MAX_TIER, "capped at the max tier")


func test_build_is_revalidated_when_applied_outside_day() -> void:
	var ctx: RunContext = _context_for(PROTOTYPE_MAP)
	var spot_id: StringName = ctx.buildings.spot_ids()[0]
	assert_eq(ctx.commands.validate_build(spot_id), CommandProcessor.OK, "valid during the day")
	var start_gold: int = ctx.economy.get_gold()
	# A stale input-layer view (validated by day) must not slip through once it is not day.
	# RunManager has no public way to leave DAY until plan 01-08 adds start_night; that plan
	# should replace this direct phase write with the public call.
	ctx.run_manager._phase = RunManager.RunPhase.NIGHT

	var result: StringName = ctx.commands.submit(BuildIntent.new(spot_id))

	assert_eq(result, CommandProcessor.NOT_DAY, "not_day reason returned")
	assert_eq(ctx.economy.get_gold(), start_gold, "gold unchanged")
	assert_eq(_building_count(ctx), 0, "no building appeared")


func test_unknown_intent_type_is_rejected() -> void:
	var ctx: RunContext = _context_for(PROTOTYPE_MAP)
	var result: StringName = ctx.commands.submit(RefCounted.new())
	assert_eq(result, CommandProcessor.UNKNOWN_INTENT, "unknown intents are rejected")
