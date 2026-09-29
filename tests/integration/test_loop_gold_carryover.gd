extends GutTest
## ECON-07: unspent gold carries over unchanged from one day to the next. Three full cycles are
## driven through the real start-night command and RunManager.tick on the prototype map, and the
## expected gold is recomputed independently from the .tres data after every step.

const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const HOUSE_A: StringName = &"house_1"
const HOUSE_B: StringName = &"house_2"

var _tuning: LoopTuning
var _house: BuildingDef
var _payouts: Array[int] = []
var _gold_deltas: Array[int] = []


func before_each() -> void:
	_tuning = load(TUNING)
	_house = load("res://data/buildings/house.tres")
	_payouts = []
	_gold_deltas = []


func _cost(tier: int) -> int:
	return _house.tier_def(tier).cost


func _income(tier: int) -> int:
	return _house.tier_def(tier).dawn_income


func _record_payout(total: int, _per_spot: Dictionary) -> void:
	_payouts.append(total)


func _record_gold(_amount: int, delta: int) -> void:
	_gold_deltas.append(delta)


func _buy(ctx: RunContext, spot_id: StringName) -> void:
	assert_eq(
		ctx.commands.submit(BuildIntent.new(spot_id)), CommandProcessor.OK, "buy at %s" % spot_id
	)


## Runs one full night: the hold ends the day, then the placeholder night, dawn, and the next day.
## Returns the dawn payout.
func _full_night(ctx: RunContext) -> int:
	_payouts = []
	assert_eq(
		ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "the hold ends the day"
	)
	ctx.run_manager.tick(_tuning.placeholder_night_seconds + 0.1)
	ctx.run_manager.tick(_tuning.dawn_seconds)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAY, "the day returned")
	assert_eq(_payouts.size(), 1, "exactly one payout in the cycle")
	if _payouts.is_empty():
		return -1
	return _payouts[0]


func test_gold_carries_over_exactly_across_three_full_cycles() -> void:
	var map: MapConfig = load(PROTOTYPE_MAP)
	var ctx: RunContext = RunContext.new(map, _tuning)
	ctx.events.dawn_payout.connect(_record_payout)
	var expected: int = map.starting_gold
	assert_gte(expected, 2 * _cost(1), "the map affords two tier I Houses on day one")
	assert_eq(ctx.economy.get_gold(), expected, "the run starts with the map's gold")

	# Day 1: build two Houses.
	_buy(ctx, HOUSE_A)
	_buy(ctx, HOUSE_B)
	expected -= 2 * _cost(1)
	assert_eq(ctx.economy.get_gold(), expected, "day 1 spend")
	var paid_1: int = _full_night(ctx)
	expected += 2 * _income(1)
	assert_eq(paid_1, 2 * _income(1), "dawn 1 payout")
	assert_eq(ctx.economy.get_gold(), expected, "dawn 1: carried over plus payout")

	# Day 2: spend nothing.
	assert_eq(ctx.economy.get_gold(), expected, "day 2 starts with what dawn left")
	var paid_2: int = _full_night(ctx)
	expected += 2 * _income(1)
	assert_eq(paid_2, 2 * _income(1), "dawn 2 payout")
	assert_eq(ctx.economy.get_gold(), expected, "dawn 2: unspent gold was kept")

	# Day 3: upgrade one House.
	assert_gte(expected, _cost(2), "the gold saved on day 2 affords the upgrade")
	_buy(ctx, HOUSE_A)
	expected -= _cost(2)
	assert_eq(ctx.economy.get_gold(), expected, "day 3 spend")
	var paid_3: int = _full_night(ctx)
	expected += _income(2) + _income(1)
	assert_eq(paid_3, _income(2) + _income(1), "dawn 3 pays the new tier")
	assert_eq(ctx.economy.get_gold(), expected, "the run ends on the exact expected total")
	assert_eq(ctx.run_manager.get_night_number(), 3, "three nights were played")
	assert_eq(ctx.run_manager.get_day_number(), 4, "and the fourth day began")


func test_gold_only_moves_at_dawn_never_at_night_or_day_start() -> void:
	var ctx: RunContext = RunContext.new(load(PROTOTYPE_MAP), _tuning)
	ctx.events.dawn_payout.connect(_record_payout)
	_buy(ctx, HOUSE_A)
	ctx.events.gold_changed.connect(_record_gold)

	_full_night(ctx)

	assert_eq(_gold_deltas, [_income(1)] as Array[int], "the payout is the only gold change")
