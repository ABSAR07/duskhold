extends GutTest
## UAT G-01-59 (D-05 amended again) on the real scene: a build hold has no time limit, so every
## coin of a long tier drips at its own due time on the shipped curve. A 30-coin House I tier
## (repriced on an isolated copy of the shipped map) completes when the last coin lands, with one
## BuildIntent and one full-cost debit. A single long frame that passes several due times still
## pays them all and completes with one debit (never a partial payment). D-06 is unchanged: a
## release just before the last coin refunds every dripped coin.
## The hold controller is stepped by fixed deltas (E2eSupport.begin_stepped_hold and step_hold), so
## no assertion depends on frame length or wall-clock time (review WR-01 closed by stepping).
## Every expectation is read from the shipped tuning, never from literals.

const SPOT: StringName = &"house_1"
const HOUSE: StringName = &"house"
const HOUSE_PATH := "res://data/buildings/house.tres"
## A tier far pricier than any shipped one, so the stream runs deep into the accelerated coins.
const PRICEY_COST: int = 30
const GOLD_MARGIN: int = 10
## Fixed hold-clock step per engine frame. Exactly representable in binary, so summed steps carry no
## rounding, and shorter than every shipped coin interval, so one step pays at most one coin.
const STEP_S: float = 1.0 / 64.0
## Extra steps allowed on top of the expected hold length before a stepping loop gives up.
const STEP_SLACK: int = 8
const EPSILON: float = 0.0001

var _ctx: RunContext
var _hold: BuildHoldController
var _map_root: MapRoot
var _coin_numbers: Array[int] = []
var _coin_stamps_s: Array[float] = []


func before_each() -> void:
	_coin_numbers.clear()
	_coin_stamps_s.clear()


func after_each() -> void:
	E2eSupport.release_all_actions()


func _on_hold_progress(_spot_id: StringName, coins_paid: int, _cost: int) -> void:
	_coin_numbers.append(coins_paid)
	_coin_stamps_s.append(_hold.get_hold_elapsed())


func _tier_built() -> bool:
	return _ctx.buildings.current_tier(SPOT) == 1


## Spawns the shipped scene with a 30-coin House I tier and the shipped tuning (no override), stands
## the king beside house_1, starts listening and starts a stepped hold (the key is pressed and the
## hold has started, with a clock of zero).
func _begin_pricey_hold() -> void:
	var pricey: MapConfig = E2eSupport.map_with_tier_cost(
		HOUSE, 1, PRICEY_COST, PRICEY_COST + GOLD_MARGIN
	)
	_map_root = await E2eSupport.spawn_map(self, pricey)
	_ctx = _map_root.get_context()
	_hold = _map_root.get_build_hold()
	var focused: bool = await E2eSupport.stand_at_spot(self, _map_root, SPOT)
	assert_true(focused, "the king is in range of house_1")
	_hold.hold_progress.connect(_on_hold_progress)
	watch_signals(_hold)
	watch_signals(_ctx.events)
	await E2eSupport.begin_stepped_hold(self, _hold)
	assert_true(_hold.is_holding(), "the press started a hold")


func _step_budget() -> int:
	return ceili(_ctx.tuning.build_hold_seconds(PRICEY_COST) / STEP_S) + STEP_SLACK


## Steps the hold clock by STEP_S until tier I stands or the step budget runs out.
func _step_until_built() -> void:
	var steps: int = 0
	var budget: int = _step_budget()
	while not _tier_built() and steps < budget:
		await E2eSupport.step_hold(self, _hold, STEP_S)
		steps += 1


## Steps the hold clock by STEP_S until `coins` coins are paid or the step budget runs out.
func _step_until_paid(coins: int) -> void:
	var steps: int = 0
	var budget: int = _step_budget()
	while _hold.get_coins_paid() < coins and _hold.is_holding() and steps < budget:
		await E2eSupport.step_hold(self, _hold, STEP_S)
		steps += 1


func test_the_pricey_hold_builds_with_one_progress_per_coin_and_one_debit() -> void:
	await _begin_pricey_hold()
	assert_lt(
		STEP_S,
		_ctx.tuning.coin_interval(PRICEY_COST),
		"a step is shorter than the fastest interval, so a step pays at most one coin"
	)
	await _step_until_built()
	var expected_gold: int = PRICEY_COST + GOLD_MARGIN - PRICEY_COST

	assert_eq(_ctx.buildings.current_tier(SPOT), 1, "the hold built tier I")
	assert_eq(_coin_numbers.size(), PRICEY_COST, "one hold_progress per coin")
	for i: int in _coin_numbers.size():
		assert_eq(_coin_numbers[i], i + 1, "coins run 1..cost in order (index %d)" % i)
	assert_signal_emit_count(_hold, "hold_completed", 1)
	assert_signal_not_emitted(_hold, "hold_cancelled")
	assert_signal_emit_count(_ctx.events, "gold_changed", 1)
	assert_signal_emitted_with_parameters(
		_ctx.events, "gold_changed", [expected_gold, -PRICEY_COST]
	)
	assert_eq(_ctx.economy.get_gold(), expected_gold, "the full cost was debited once")


func test_every_coin_drips_at_its_own_due_time_and_never_two_in_one_step() -> void:
	await _begin_pricey_hold()
	await _step_until_built()
	assert_eq(_coin_stamps_s.size(), PRICEY_COST, "every coin was paid")
	if _coin_stamps_s.size() != PRICEY_COST:
		return

	for i: int in _coin_stamps_s.size():
		var coin: int = i + 1
		var due_s: float = _ctx.tuning.coin_due_seconds(coin)
		assert_gte(_coin_stamps_s[i], due_s - EPSILON, "coin %d is not paid early" % coin)
		assert_lte(
			_coin_stamps_s[i], due_s + STEP_S + EPSILON, "coin %d is paid within one step" % coin
		)
		if i > 0:
			assert_gt(
				_coin_stamps_s[i],
				_coin_stamps_s[i - 1],
				"coin %d has a step of its own, nothing is fast-forwarded" % coin
			)


func test_the_hold_lasts_the_uncapped_sum_of_its_intervals() -> void:
	await _begin_pricey_hold()
	await _step_until_built()
	assert_eq(_coin_stamps_s.size(), PRICEY_COST, "every coin was paid")
	if _coin_stamps_s.size() != PRICEY_COST:
		return
	var sum_s: float = 0.0
	for coin: int in range(1, PRICEY_COST + 1):
		sum_s += _ctx.tuning.coin_interval(coin)
	var last_stamp_s: float = _coin_stamps_s[_coin_stamps_s.size() - 1]

	assert_almost_eq(sum_s, _ctx.tuning.build_hold_seconds(PRICEY_COST), EPSILON, "the sum matches")
	assert_gte(last_stamp_s, sum_s - EPSILON, "the last coin waited for the full sum")
	assert_lte(last_stamp_s, sum_s + STEP_S + EPSILON, "and landed within one step of it")


func test_one_long_frame_pays_every_due_coin_and_completes_with_one_debit() -> void:
	await _begin_pricey_hold()
	var long_frame_s: float = _ctx.tuning.build_hold_seconds(PRICEY_COST) + STEP_S
	await E2eSupport.step_hold(self, _hold, long_frame_s)
	var expected_gold: int = PRICEY_COST + GOLD_MARGIN - PRICEY_COST

	assert_eq(_coin_stamps_s.size(), PRICEY_COST, "all coins were paid in that one frame")
	if _coin_stamps_s.size() == PRICEY_COST:
		for i: int in _coin_stamps_s.size():
			assert_almost_eq(
				_coin_stamps_s[i], long_frame_s, EPSILON, "coin %d shares it" % (i + 1)
			)
	assert_signal_emit_count(_hold, "hold_completed", 1)
	assert_signal_not_emitted(_hold, "hold_cancelled")
	assert_signal_emit_count(_ctx.events, "gold_changed", 1)
	assert_signal_emitted_with_parameters(
		_ctx.events, "gold_changed", [expected_gold, -PRICEY_COST]
	)
	assert_eq(_ctx.buildings.current_tier(SPOT), 1, "tier I was built")
	assert_false(_hold.is_holding(), "no hold is left over")


func test_releasing_before_the_last_coin_refunds_everything() -> void:
	await _begin_pricey_hold()
	var gold_before: int = _ctx.economy.get_gold()
	var almost: int = PRICEY_COST - 1
	await _step_until_paid(almost)
	assert_eq(_hold.get_coins_paid(), almost, "every coin but the last had dripped")

	Input.action_release(BuildHoldController.ACTION)
	await E2eSupport.step_hold(self, _hold, STEP_S)

	assert_signal_emitted_with_parameters(_hold, "hold_cancelled", [SPOT, almost])
	assert_signal_not_emitted(_hold, "hold_completed")
	assert_signal_not_emitted(_ctx.events, "gold_changed")
	assert_eq(_ctx.economy.get_gold(), gold_before, "gold never moved")
	assert_eq(_ctx.buildings.current_tier(SPOT), 0, "nothing was built")
	assert_false(_hold.is_holding(), "no hold is active")


func test_repricing_a_tier_leaves_the_cached_house_resource_untouched() -> void:
	var shipped_cost: int = (load(HOUSE_PATH) as BuildingDef).tier_def(1).cost
	var pricey: MapConfig = E2eSupport.map_with_tier_cost(
		HOUSE, 1, PRICEY_COST, PRICEY_COST + GOLD_MARGIN
	)

	assert_not_null(pricey, "the House tier exists on the shipped map")
	assert_eq(
		(load(HOUSE_PATH) as BuildingDef).tier_def(1).cost,
		shipped_cost,
		"the cached house.tres keeps its shipped tier I cost"
	)
	assert_ne(shipped_cost, PRICEY_COST, "the repriced copy really differs from the shipped data")
