extends GutTest
## UAT G-01-58 (D-05 amended) on the real scene: a hold never lasts longer than the shipped
## max_build_hold_seconds. A 30-coin House I tier (repriced on an isolated copy of the shipped
## map) drips along the accelerating curve, then pays every remaining coin in the frame the hold
## clock reaches the cap and builds with one BuildIntent and one full-cost debit. D-06 is
## unchanged: a release or a range exit just before the cap still refunds every dripped coin.
## Every expectation is read from the shipped tuning, never from literals.

const SPOT: StringName = &"house_1"
const HOUSE: StringName = &"house"
const HOUSE_PATH := "res://data/buildings/house.tres"
## A tier far pricier than any shipped one, so the cap is what ends the hold.
const PRICEY_COST: int = 30
const GOLD_MARGIN: int = 10
## Sits well inside interaction_radius of a plot.
const NEAR_OFFSET := Vector3(0.5, 0.0, 0.0)
## The release test lets the hold clock pass the cap minus this, then lets go.
const RELEASE_BEFORE_CAP_S: float = 0.3
## Real-time slack on top of the cap while waiting for the build (only timeouts use real time).
const CAP_WAIT_SLACK_S: float = 1.0
const EPSILON: float = 0.0001

var _ctx: RunContext
var _hold: BuildHoldController
var _map_root: MapRoot
var _coin_numbers: Array[int] = []
var _coin_stamps_s: Array[float] = []
var _coin_deltas_s: Array[float] = []


func before_each() -> void:
	_coin_numbers.clear()
	_coin_stamps_s.clear()
	_coin_deltas_s.clear()


func after_each() -> void:
	E2eSupport.release_all_actions()


func _on_hold_progress(_spot_id: StringName, coins_paid: int, _cost: int) -> void:
	_coin_numbers.append(coins_paid)
	_coin_stamps_s.append(_hold.get_hold_elapsed())
	_coin_deltas_s.append(get_process_delta_time())


func _focused() -> bool:
	return _hold.get_focused_spot() == SPOT


func _tier_built() -> bool:
	return _ctx.buildings.current_tier(SPOT) == 1


func _clock_reached(seconds: float) -> bool:
	return _hold.get_hold_elapsed() >= seconds


## Spawns the shipped scene with a 30-coin House I tier and the shipped tuning (no override),
## stands the king beside house_1 and starts listening. The key is not pressed yet.
func _stand_at_pricey_plot() -> void:
	var pricey: MapConfig = E2eSupport.map_with_tier_cost(
		HOUSE, 1, PRICEY_COST, PRICEY_COST + GOLD_MARGIN
	)
	_map_root = await E2eSupport.spawn_map(self, pricey)
	_ctx = _map_root.get_context()
	_hold = _map_root.get_build_hold()
	var plot: Vector3 = _ctx.buildings.get_spot(SPOT).position
	E2eSupport.teleport_king(_map_root, plot + NEAR_OFFSET)
	await E2eSupport.wait_until(self, _focused, 1.0)
	_hold.hold_progress.connect(_on_hold_progress)


## Holds the key until tier I stands (or the cap plus slack passes), then lets go.
func _hold_until_built() -> void:
	await _stand_at_pricey_plot()
	watch_signals(_hold)
	watch_signals(_ctx.events)
	Input.action_press(&"action_build")
	await E2eSupport.wait_until(
		self, _tier_built, _ctx.tuning.max_build_hold_seconds + CAP_WAIT_SLACK_S
	)
	Input.action_release(&"action_build")


func test_the_pricey_hold_builds_with_one_progress_per_coin_and_one_debit() -> void:
	await _hold_until_built()
	var expected_gold: int = PRICEY_COST + GOLD_MARGIN - PRICEY_COST

	assert_eq(_ctx.buildings.current_tier(SPOT), 1, "the capped hold built tier I")
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


func test_no_coin_is_paid_before_its_due_time() -> void:
	await _hold_until_built()
	for i: int in _coin_stamps_s.size():
		var due_s: float = _ctx.tuning.coin_due_seconds(_coin_numbers[i])
		assert_gte(
			_coin_stamps_s[i], due_s - EPSILON, "coin %d is not paid early" % _coin_numbers[i]
		)


func test_the_hold_completes_at_the_cap() -> void:
	await _hold_until_built()
	var cap_s: float = _ctx.tuning.max_build_hold_seconds
	assert_gt(_coin_stamps_s.size(), 0, "coins were paid")
	if _coin_stamps_s.is_empty():
		return
	var last_stamp_s: float = _coin_stamps_s[_coin_stamps_s.size() - 1]
	var last_delta_s: float = _coin_deltas_s[_coin_deltas_s.size() - 1]

	assert_gte(last_stamp_s, cap_s - EPSILON, "the hold ran to the cap")
	assert_lte(
		last_stamp_s, cap_s + last_delta_s + EPSILON, "and not longer than one frame past it"
	)


func test_every_coin_due_at_the_cap_is_paid_in_the_same_frame() -> void:
	await _hold_until_built()
	var cap_s: float = _ctx.tuning.max_build_hold_seconds
	assert_eq(_coin_stamps_s.size(), PRICEY_COST, "every coin was paid")
	if _coin_stamps_s.size() != PRICEY_COST:
		return
	var last_stamp_s: float = _coin_stamps_s[_coin_stamps_s.size() - 1]
	var fast_forwarded: int = 0
	for coin: int in range(1, PRICEY_COST + 1):
		if _ctx.tuning.coin_due_seconds(coin) >= cap_s - EPSILON:
			fast_forwarded += 1
			assert_almost_eq(
				_coin_stamps_s[coin - 1],
				last_stamp_s,
				EPSILON,
				"coin %d rides the cap frame" % coin
			)
	assert_gt(fast_forwarded, 1, "the shipped curve fast-forwards more than one coin of 30")


func test_releasing_just_before_the_cap_refunds_everything() -> void:
	await _stand_at_pricey_plot()
	var cap_s: float = _ctx.tuning.max_build_hold_seconds
	var gold_before: int = _ctx.economy.get_gold()
	watch_signals(_hold)
	watch_signals(_ctx.events)

	Input.action_press(&"action_build")
	var near_cap: bool = await E2eSupport.wait_until(
		self, _clock_reached.bind(cap_s - RELEASE_BEFORE_CAP_S), cap_s + CAP_WAIT_SLACK_S
	)
	assert_true(near_cap, "the hold clock got close to the cap")
	var paid: int = _hold.get_coins_paid()
	Input.action_release(&"action_build")
	await wait_process_frames(2)

	assert_gt(paid, 0, "some coins had dripped")
	assert_lt(paid, PRICEY_COST, "the hold was only partly paid")
	assert_signal_emitted_with_parameters(_hold, "hold_cancelled", [SPOT, paid])
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
