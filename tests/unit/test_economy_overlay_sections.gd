extends GutTest
## ECON-03, ECON-05, D-15, DEV-03: the debug overlay's Economy section. It lists the castle's tier
## with the names of the cards picked there, one row per standing declining building (the Gold Mine)
## with the dawns it has paid and what it pays next, and one row per standing Fishing Harbor with
## its boats and cap. Every row builder is a pure read: collecting the rows changes no simulation
## value and emits no event. The Mine's and the Harbor's numbers are set on a deep copy so a later
## fit of the shipped numbers cannot break this test.

const OVERLAY_SCENE := "res://ui/overlay/debug_overlay.tscn"
const FIXTURE := "res://tests/fixtures/fixture_map_one_night.tres"
const CASTLE_PLOT: StringName = &"castle_plot"
const MINE: StringName = &"gold_mine_1"
const ROYAL_TRAINING: StringName = &"royal_training"
const START: int = 3
const STEP: int = 1
const FLOOR: int = 1
const RICH_GOLD: int = 100
const NO_MINE_ROW := "gold_mine_1"
const HARBOR: StringName = &"harbor_1"
const BOAT_CAP: int = 3

var _tuning: LoopTuning


func before_each() -> void:
	_tuning = OverlayTestSupport.new_tuning()


func after_each() -> void:
	E2eSupport.release_all_actions()


func _context() -> RunContext:
	var map: MapConfig = E2eSupport.waveless_prototype_map()
	map.starting_gold = RICH_GOLD
	for building_def: BuildingDef in map.buildings:
		if building_def.id == &"gold_mine":
			var tier: BuildingTierDef = building_def.tier_def(1)
			tier.dawn_income = START
			tier.income_step = STEP
			tier.income_floor = FLOOR
		if building_def.id == &"fishing_harbor":
			building_def.tier_def(1).boat_cap = BOAT_CAP
			building_def.tier_def(1).boat_income = 1
	return RunContext.new(map, _tuning)


func _value(rows: Array, label: String) -> Variant:
	for row: Array in rows:
		if row[0] == label:
			return row[1]
	return null


func _buy(ctx: RunContext, spot_id: StringName, choice: StringName = &"") -> void:
	var result: StringName = ctx.commands.submit(BuildIntent.new(spot_id, choice))
	assert_eq(result, CommandProcessor.OK, "%s bought" % spot_id)


func _dawn(ctx: RunContext) -> void:
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	ctx.run_manager.tick(_tuning.placeholder_night_seconds + 0.1)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "dawn reached")


func _dawn_to_day(ctx: RunContext) -> void:
	ctx.run_manager.tick(_tuning.dawn_seconds + 0.1)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAY, "day again")


func test_the_section_title_is_economy() -> void:
	assert_eq(EconomyOverlaySections.ECONOMY_TITLE, "Economy", "the title the overlay shows")


func test_the_castle_row_reads_tier_one_with_no_picks_at_the_start() -> void:
	var rows: Array = EconomyOverlaySections.economy_rows(_context())
	assert_eq(_value(rows, "castle"), "tier 1, picks none", "castle: tier 1, picks none")


func test_the_castle_row_names_the_pick_after_castle_two() -> void:
	var ctx: RunContext = _context()
	_buy(ctx, CASTLE_PLOT, ROYAL_TRAINING)
	var card: ChoiceDef = ctx.choices.find_choice(ROYAL_TRAINING)

	var rows: Array = EconomyOverlaySections.economy_rows(ctx)

	assert_eq(
		_value(rows, "castle"), "tier 2, picks %s" % card.display_name, "tier II and the pick"
	)


func test_the_castle_row_joins_several_picks_in_pick_order() -> void:
	var ctx: RunContext = _context()
	_buy(ctx, CASTLE_PLOT, ROYAL_TRAINING)
	var third: ChoiceDef = (
		ctx.buildings.get_building_def_for_spot(CASTLE_PLOT).tier_def(3).choices[0]
	)
	_buy(ctx, CASTLE_PLOT, third.id)
	var first: ChoiceDef = ctx.choices.find_choice(ROYAL_TRAINING)

	var rows: Array = EconomyOverlaySections.economy_rows(ctx)

	var expected: String = "tier 3, picks %s, %s" % [first.display_name, third.display_name]
	assert_eq(_value(rows, "castle"), expected, "both names, in the order they were picked")


func test_there_is_no_mine_row_until_the_mine_stands() -> void:
	var rows: Array = EconomyOverlaySections.economy_rows(_context())
	assert_null(_value(rows, NO_MINE_ROW), "an empty plot has no row")


func test_the_mine_row_reads_paid_zero_and_the_first_payout_once_it_stands() -> void:
	var ctx: RunContext = _context()
	_buy(ctx, MINE)

	var rows: Array = EconomyOverlaySections.economy_rows(ctx)

	assert_eq(_value(rows, "gold_mine_1"), "paid 0, next %d" % START, "gold_mine_1: paid 0, next 3")


func test_the_mine_row_follows_the_decline_dawn_by_dawn() -> void:
	var ctx: RunContext = _context()
	_buy(ctx, MINE)
	_dawn(ctx)
	var rows: Array = EconomyOverlaySections.economy_rows(ctx)
	assert_eq(_value(rows, "gold_mine_1"), "paid 1, next %d" % (START - STEP), "after dawn 1")


func test_every_row_is_a_label_value_string_pair() -> void:
	var ctx: RunContext = _context()
	_buy(ctx, MINE)
	for row: Array in EconomyOverlaySections.economy_rows(ctx):
		assert_eq(row.size(), 2, "[label, value]")
		assert_true(row[0] is String and row[1] is String, "both strings")


func test_a_map_without_a_castle_plot_still_lists_a_row() -> void:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	var ctx: RunContext = RunContext.new(map, _tuning)
	var rows: Array = EconomyOverlaySections.economy_rows(ctx)
	assert_false(rows.is_empty(), "a section is never empty")
	assert_eq(_value(rows, "castle"), "no tiers", "said plainly")


func test_collecting_the_section_is_strictly_read_only() -> void:
	var ctx: RunContext = _context()
	_buy(ctx, MINE)
	_buy(ctx, CASTLE_PLOT, ROYAL_TRAINING)
	var paid_before: int = ctx.income.mine_paid_dawns(MINE)
	var next_before: int = ctx.income.next_payout(MINE)
	var model: DebugOverlayModel = DebugOverlayModel.new(ctx)
	model.register_section(
		EconomyOverlaySections.ECONOMY_TITLE,
		func() -> Array: return EconomyOverlaySections.economy_rows(ctx)
	)

	OverlayTestSupport.assert_collecting_is_read_only(self, ctx, model)

	assert_eq(ctx.income.mine_paid_dawns(MINE), paid_before, "no dawn was consumed")
	assert_eq(ctx.income.next_payout(MINE), next_before, "and the promise did not move")
	assert_eq(ctx.castle.tier(), 2, "the castle tier did not move")


func test_the_real_overlay_lists_economy_after_stats() -> void:
	var ctx: RunContext = _context()
	_buy(ctx, MINE)
	var overlay: DebugOverlay = (load(OVERLAY_SCENE) as PackedScene).instantiate()
	add_child_autofree(overlay)
	overlay.bind_run(ctx, null)
	await wait_process_frames(1)
	Input.action_press(DebugOverlay.TOGGLE_ACTION)
	await wait_process_frames(2)
	Input.action_release(DebugOverlay.TOGGLE_ACTION)
	await wait_process_frames(1)
	var text: String = overlay.get_text()
	assert_true(text.contains(EconomyOverlaySections.ECONOMY_TITLE), "the Economy section shows")
	assert_gt(text.find("Economy"), text.find("Stats"), "after the Stats section")
	assert_true(text.contains("castle: tier 1, picks none"), "with the castle row")
	assert_true(text.contains("gold_mine_1: paid 0, next 3"), "and the Mine row")


func test_there_is_no_harbor_row_until_the_harbor_stands() -> void:
	var rows: Array = EconomyOverlaySections.economy_rows(_context())
	assert_null(_value(rows, HARBOR), "an empty plot has no row")


func test_the_harbor_row_reads_no_boats_the_day_it_is_bought() -> void:
	var ctx: RunContext = _context()
	_buy(ctx, HARBOR)
	var rows: Array = EconomyOverlaySections.economy_rows(ctx)
	assert_eq(_value(rows, HARBOR), "boats 0 of %d" % BOAT_CAP, "harbor_1: boats 0 of 3")


func test_the_harbor_row_counts_the_boats_dawn_by_dawn() -> void:
	var ctx: RunContext = _context()
	_buy(ctx, HARBOR)
	_dawn(ctx)
	_dawn_to_day(ctx)
	_dawn(ctx)
	var rows: Array = EconomyOverlaySections.economy_rows(ctx)
	assert_eq(_value(rows, HARBOR), "boats 2 of %d" % BOAT_CAP, "harbor_1: boats 2 of 3")
