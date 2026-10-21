extends GutTest
## ECON-03, Pitfall 4 and T-05-14: a Gold Mine and a House on the prototype map pay through the ONE
## dawn_payout. FLAT curves are paid only by BuildingSystem.dawn_income_by_spot() and every other
## curve only by IncomeState.dawn_payouts(); RunManager walks the plots in MapConfig order and lists
## the castle last, so per_spot keeps map order and its sum is the total. The Mine's numbers are
## set on a deep copy (first payout 3, step 1, floor 1) so the plan 05-11 fit cannot break this
## test; the House and the castle read their numbers from the shipped data.

const TUNING := "res://data/tuning/loop_tuning.tres"
const MINE: StringName = &"gold_mine_1"
const HOUSE: StringName = &"house_1"
const START: int = 3
const STEP: int = 1
const FLOOR: int = 1
const RICH_GOLD: int = 100

var _tuning: LoopTuning


func before_each() -> void:
	_tuning = load(TUNING)


func _map() -> MapConfig:
	var map: MapConfig = E2eSupport.waveless_prototype_map()
	map.starting_gold = RICH_GOLD
	for building_def: BuildingDef in map.buildings:
		if building_def.id == &"gold_mine":
			var tier: BuildingTierDef = building_def.tier_def(1)
			tier.dawn_income = START
			tier.income_step = STEP
			tier.income_floor = FLOOR
	return map


func _context_with_house_and_mine() -> RunContext:
	var ctx: RunContext = RunContext.new(_map(), _tuning)
	assert_eq(ctx.commands.submit(BuildIntent.new(HOUSE)), CommandProcessor.OK, "House I")
	assert_eq(ctx.commands.submit(BuildIntent.new(MINE)), CommandProcessor.OK, "the Mine")
	return ctx


## Night then dawn, by ticking the run manager through the timed night.
func _night_into_dawn(ctx: RunContext) -> void:
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	ctx.run_manager.tick(_tuning.placeholder_night_seconds + 0.1)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "dawn reached")


## Dawn over: the day begins again.
func _dawn_into_day(ctx: RunContext) -> void:
	ctx.run_manager.tick(_tuning.dawn_seconds + 0.1)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAY, "day again")


## The per_spot dictionary of the nth dawn_payout emission (0-based).
func _per_spot(ctx: RunContext, emission: int) -> Dictionary:
	var params: Variant = get_signal_parameters(ctx.events, "dawn_payout", emission)
	return (params as Array)[1] if params != null else {}


func _house_income(ctx: RunContext) -> int:
	return ctx.buildings.get_building_def_for_spot(HOUSE).tier_def(1).dawn_income


func test_the_first_dawn_lists_house_mine_and_castle_in_map_order_with_one_event() -> void:
	var ctx: RunContext = _context_with_house_and_mine()
	watch_signals(ctx.events)

	_night_into_dawn(ctx)

	assert_signal_emit_count(ctx.events, "dawn_payout", 1, "exactly one payout event")
	var per_spot: Dictionary = _per_spot(ctx, 0)
	assert_eq(per_spot.keys(), [HOUSE, MINE, MapConfig.CASTLE_PAYOUT_KEY], "map order, castle last")
	assert_eq(per_spot[HOUSE], _house_income(ctx), "the House pays its tier I income")
	assert_eq(per_spot[MINE], START, "the Mine pays its starting gold")
	assert_eq(per_spot[MapConfig.CASTLE_PAYOUT_KEY], ctx.castle.base_income(), "the castle's base")


func test_the_total_is_the_sum_of_per_spot_and_the_gold_rises_by_it() -> void:
	var ctx: RunContext = _context_with_house_and_mine()
	var gold: int = ctx.economy.get_gold()
	watch_signals(ctx.events)

	_night_into_dawn(ctx)

	var params: Array = get_signal_parameters(ctx.events, "dawn_payout", 0)
	var sum: int = 0
	for amount: int in (params[1] as Dictionary).values():
		sum += amount
	assert_eq(params[0], sum, "total equals the sum of per_spot")
	assert_eq(ctx.economy.get_gold(), gold + sum, "the ledger rose by exactly the total")


func test_the_second_dawn_lists_the_mine_at_one_less() -> void:
	var ctx: RunContext = _context_with_house_and_mine()
	watch_signals(ctx.events)
	_night_into_dawn(ctx)
	_dawn_into_day(ctx)

	_night_into_dawn(ctx)

	assert_signal_emit_count(ctx.events, "dawn_payout", 2, "one event per dawn")
	var per_spot: Dictionary = _per_spot(ctx, 1)
	assert_eq(per_spot[MINE], START - STEP, "the Mine pays one less")
	assert_eq(per_spot.keys(), [HOUSE, MINE, MapConfig.CASTLE_PAYOUT_KEY], "same order")


func test_the_mine_is_never_in_the_flat_income_and_the_house_never_in_the_other() -> void:
	var ctx: RunContext = _context_with_house_and_mine()
	assert_false(ctx.buildings.dawn_income_by_spot().has(MINE), "BuildingSystem skips the Mine")
	assert_true(ctx.buildings.dawn_income_by_spot().has(HOUSE), "BuildingSystem pays the House")
	assert_false(ctx.income.dawn_payouts().has(HOUSE), "IncomeState skips the House")


func test_every_dawn_sums_to_its_total_across_five_dawns() -> void:
	var ctx: RunContext = _context_with_house_and_mine()
	watch_signals(ctx.events)
	for dawn: int in range(5):
		_night_into_dawn(ctx)
		_dawn_into_day(ctx)
	for emission: int in range(5):
		var params: Array = get_signal_parameters(ctx.events, "dawn_payout", emission)
		var sum: int = 0
		for amount: int in (params[1] as Dictionary).values():
			sum += amount
		assert_eq(params[0], sum, "dawn %d: total equals the sum" % (emission + 1))
	var mine_amounts: Array[int] = []
	for emission: int in range(5):
		mine_amounts.append(_per_spot(ctx, emission)[MINE])
	assert_eq(mine_amounts, [3, 2, 1, 1, 1] as Array[int], "the Mine never pays 0")


func test_without_a_mine_the_payout_is_what_it_was_before() -> void:
	var ctx: RunContext = RunContext.new(_map(), _tuning)
	assert_eq(ctx.commands.submit(BuildIntent.new(HOUSE)), CommandProcessor.OK, "House I")
	watch_signals(ctx.events)

	_night_into_dawn(ctx)

	var per_spot: Dictionary = _per_spot(ctx, 0)
	assert_eq(per_spot.keys(), [HOUSE, MapConfig.CASTLE_PAYOUT_KEY], "no Mine entry")
	assert_eq(ctx.income.dawn_payouts(), {}, "and no non-flat payer at all")


func test_two_runs_of_the_same_seed_list_the_same_keys_in_the_same_order() -> void:
	var first: RunContext = _context_with_house_and_mine()
	var second: RunContext = _context_with_house_and_mine()
	watch_signals(first.events)
	watch_signals(second.events)
	_night_into_dawn(first)
	_night_into_dawn(second)
	assert_eq(_per_spot(first, 0).keys(), _per_spot(second, 0).keys(), "same keys, same order")
	assert_eq(_per_spot(first, 0), _per_spot(second, 0), "and the same amounts")
