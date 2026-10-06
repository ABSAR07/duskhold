extends GutTest
## ECON-02: at dawn each House pays its current tier's income once, in MapConfig order, and the
## castle pays the map's base income on top, listed last under MapConfig.CASTLE_PAYOUT_KEY
## (G-02-1). Expectations come from house.tres, tower.tres and the map, so Phase 2 tuning cannot
## break them.

const TUNING := "res://data/tuning/loop_tuning.tres"
const RICH_GOLD: int = 100
const HOUSE_A: StringName = &"house_1"
const HOUSE_B: StringName = &"house_2"
const HOUSE_C: StringName = &"house_3"
const TOWER: StringName = &"tower_1"

var _tuning: LoopTuning
var _house: BuildingDef


func before_each() -> void:
	_tuning = load(TUNING)
	_house = load("res://data/buildings/house.tres")


func _rich_context() -> RunContext:
	var map: MapConfig = E2eSupport.waveless_prototype_map()
	map.starting_gold = RICH_GOLD
	return RunContext.new(map, _tuning)


func _build(ctx: RunContext, spot_id: StringName, times: int = 1) -> void:
	for step: int in range(times):
		assert_eq(
			ctx.commands.submit(BuildIntent.new(spot_id)),
			CommandProcessor.OK,
			"%s build step %d" % [spot_id, step + 1]
		)


func _income(tier: int) -> int:
	return _house.tier_def(tier).dawn_income


## The base income the shipped map pays at every dawn, read from the map data.
func _base() -> int:
	return E2eSupport.waveless_prototype_map().base_dawn_income


func _run_night_into_dawn(ctx: RunContext) -> void:
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	ctx.run_manager.tick(_tuning.placeholder_night_seconds + 0.1)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "dawn reached")


func _loop(model: DebugOverlayModel) -> Dictionary:
	var rows: Dictionary = {}
	for section: Dictionary in model.collect(60.0):
		if section["title"] == "Loop":
			for row: Array in section["rows"]:
				rows[row[0]] = row[1]
	return rows


func _first_payout_spots(ctx: RunContext) -> Dictionary:
	var params: Variant = get_signal_parameters(ctx.events, "dawn_payout", 0)
	if params == null:
		return {}
	return (params as Array)[1]


func test_houses_pay_their_current_tier_income_at_dawn() -> void:
	var ctx: RunContext = _rich_context()
	_build(ctx, HOUSE_A)
	_build(ctx, HOUSE_B, 2)
	var gold_before: int = ctx.economy.get_gold()
	watch_signals(ctx.events)

	_run_night_into_dawn(ctx)

	var expected: Dictionary = {
		HOUSE_A: _income(1), HOUSE_B: _income(2), MapConfig.CASTLE_PAYOUT_KEY: _base()
	}
	var total: int = _income(1) + _income(2) + _base()
	assert_signal_emit_count(ctx.events, "dawn_payout", 1, "one payout per dawn")
	assert_signal_emitted_with_parameters(ctx.events, "dawn_payout", [total, expected])
	assert_eq(ctx.economy.get_gold(), gold_before + total, "the payout landed in gold")
	var per_spot: Dictionary = _first_payout_spots(ctx)
	assert_eq(
		per_spot.keys(),
		[HOUSE_A, HOUSE_B, MapConfig.CASTLE_PAYOUT_KEY],
		"per-spot keys are in MapConfig order with the castle last"
	)


func test_a_house_upgraded_today_pays_its_new_tier_at_the_next_dawn() -> void:
	var ctx: RunContext = _rich_context()
	_build(ctx, HOUSE_A)
	assert_eq(ctx.buildings.dawn_income_by_spot(), {HOUSE_A: _income(1)}, "tier I income")
	_build(ctx, HOUSE_A)
	assert_eq(ctx.buildings.dawn_income_by_spot(), {HOUSE_A: _income(2)}, "tier II income")
	var gold_before: int = ctx.economy.get_gold()

	_run_night_into_dawn(ctx)

	assert_eq(
		ctx.economy.get_gold(), gold_before + _income(2) + _base(), "paid at the upgraded tier"
	)


func test_two_houses_at_the_same_tier_pay_the_same_amount() -> void:
	var ctx: RunContext = _rich_context()
	_build(ctx, HOUSE_A)
	_build(ctx, HOUSE_B)
	var income: Dictionary = ctx.buildings.dawn_income_by_spot()
	assert_eq(income.get(HOUSE_A), income.get(HOUSE_B), "same tier, same pay")
	assert_eq(income.get(HOUSE_A), _income(1), "and it is the tier I income")


func test_a_tower_pays_nothing_and_is_not_listed() -> void:
	var ctx: RunContext = _rich_context()
	_build(ctx, HOUSE_A)
	_build(ctx, TOWER)
	var gold_before: int = ctx.economy.get_gold()
	watch_signals(ctx.events)

	_run_night_into_dawn(ctx)

	assert_signal_emitted_with_parameters(
		ctx.events,
		"dawn_payout",
		[_income(1) + _base(), {HOUSE_A: _income(1), MapConfig.CASTLE_PAYOUT_KEY: _base()}]
	)
	assert_false(_first_payout_spots(ctx).has(TOWER), "no tower entry in the payout")
	assert_false(ctx.buildings.dawn_income_by_spot().has(TOWER), "no tower entry")
	assert_eq(
		ctx.economy.get_gold(), gold_before + _income(1) + _base(), "the House and the castle paid"
	)


func test_a_dawn_with_no_houses_pays_only_the_base_income_and_the_day_still_returns() -> void:
	var ctx: RunContext = _rich_context()
	var gold_before: int = ctx.economy.get_gold()
	watch_signals(ctx.events)

	_run_night_into_dawn(ctx)

	assert_gt(_base(), 0, "the shipped map pays a base income")
	assert_signal_emitted_with_parameters(
		ctx.events, "dawn_payout", [_base(), {MapConfig.CASTLE_PAYOUT_KEY: _base()}]
	)
	assert_eq(ctx.economy.get_gold(), gold_before + _base(), "gold rose by the base income")
	assert_signal_emit_count(ctx.events, "gold_changed", 1, "one gold change")
	ctx.run_manager.tick(_tuning.dawn_seconds)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAY, "the next day begins")


func test_a_dawn_with_the_base_switched_off_and_no_houses_pays_nothing() -> void:
	var map: MapConfig = E2eSupport.waveless_prototype_map()
	map.starting_gold = RICH_GOLD
	map.base_dawn_income = 0
	var ctx: RunContext = RunContext.new(map, _tuning)
	var gold_before: int = ctx.economy.get_gold()
	watch_signals(ctx.events)

	_run_night_into_dawn(ctx)

	assert_signal_emitted_with_parameters(ctx.events, "dawn_payout", [0, {}])
	assert_eq(ctx.economy.get_gold(), gold_before, "gold unchanged")
	assert_signal_not_emitted(ctx.events, "gold_changed")
	ctx.run_manager.tick(_tuning.dawn_seconds)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAY, "the next day begins")


func test_a_run_manager_built_without_the_base_argument_pays_no_base_income() -> void:
	var events: SimEvents = SimEvents.new()
	var map: MapConfig = E2eSupport.waveless_prototype_map()
	var economy: Economy = Economy.new(events, 0)
	var buildings: BuildingSystem = BuildingSystem.new(map, events)
	var manager: RunManager = RunManager.new(events, economy, buildings, _tuning)
	watch_signals(events)
	manager.start_night()
	manager.tick(_tuning.placeholder_night_seconds + 0.1)
	assert_eq(manager.get_phase(), RunManager.RunPhase.DAWN, "dawn reached")
	assert_signal_emitted_with_parameters(events, "dawn_payout", [0, {}])
	assert_eq(economy.get_gold(), 0, "no base income without the argument")


func test_a_house_rebuilt_this_dawn_pays_nothing_but_the_castle_still_pays_its_base() -> void:
	var ctx: RunContext = _rich_context()
	_build(ctx, HOUSE_A)
	watch_signals(ctx.events)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	ctx.buildings.damage_building(HOUSE_A, _house.tier_def(1).max_health)
	ctx.run_manager.tick(_tuning.placeholder_night_seconds + 0.1)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "dawn reached")
	assert_true(ctx.buildings.get_instance(HOUSE_A).rebuilt_this_dawn, "the House was rebuilt")
	assert_signal_emitted_with_parameters(
		ctx.events, "dawn_payout", [_base(), {MapConfig.CASTLE_PAYOUT_KEY: _base()}]
	)


func test_payouts_follow_map_order_not_build_order() -> void:
	var ctx: RunContext = _rich_context()
	_build(ctx, HOUSE_C)
	_build(ctx, HOUSE_B)
	_build(ctx, HOUSE_A)
	watch_signals(ctx.events)

	_run_night_into_dawn(ctx)

	var per_spot: Dictionary = _first_payout_spots(ctx)
	assert_eq(
		per_spot.keys(),
		[HOUSE_A, HOUSE_B, HOUSE_C, MapConfig.CASTLE_PAYOUT_KEY],
		"MapConfig order, then the castle"
	)


func test_dawn_income_by_spot_is_identical_across_repeated_calls() -> void:
	var ctx: RunContext = _rich_context()
	_build(ctx, HOUSE_B)
	_build(ctx, HOUSE_A, 2)
	_build(ctx, HOUSE_C)
	var first: Dictionary = ctx.buildings.dawn_income_by_spot()
	assert_eq(first.keys(), [HOUSE_A, HOUSE_B, HOUSE_C], "ordered by the map")
	assert_false(first.has(MapConfig.CASTLE_PAYOUT_KEY), "the building ledger never lists castle")
	for repeat: int in range(5):
		var again: Dictionary = ctx.buildings.dawn_income_by_spot()
		assert_eq(again, first, "call %d has the same content" % repeat)
		assert_eq(again.keys(), first.keys(), "call %d has the same key order" % repeat)


func test_the_payout_happens_once_per_dawn_not_per_tick() -> void:
	var ctx: RunContext = _rich_context()
	_build(ctx, HOUSE_A)
	_run_night_into_dawn(ctx)
	var gold_after_dawn: int = ctx.economy.get_gold()
	watch_signals(ctx.events)

	ctx.run_manager.tick(_tuning.dawn_seconds * 0.4)
	ctx.run_manager.tick(_tuning.dawn_seconds * 0.4)

	assert_signal_not_emitted(ctx.events, "dawn_payout")
	assert_eq(ctx.economy.get_gold(), gold_after_dawn, "no second payment inside the same dawn")


func test_the_overlay_loop_section_shows_day_night_and_the_timer() -> void:
	var ctx: RunContext = _rich_context()
	var model: DebugOverlayModel = DebugOverlayModel.new(ctx)
	var by_day: Dictionary = _loop(model)
	assert_eq(by_day.get("Day"), "1", "day one by day")
	assert_eq(by_day.get("Night"), "0", "no night yet")
	assert_false(by_day.has("Timer"), "no timer by day")

	_run_night_into_dawn(ctx)
	ctx.run_manager.tick(0.5)
	var at_dawn: Dictionary = _loop(model)
	assert_eq(at_dawn.get("Night"), "1", "night one has started")
	assert_eq(at_dawn.get("Timer"), "%.1f" % (_tuning.dawn_seconds - 0.5), "dawn time left")
