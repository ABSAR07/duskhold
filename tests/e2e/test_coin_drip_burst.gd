extends GutTest
## UAT G-01-59 (D-05 amended again) on the real scene: coins paid in one frame (a long frame) or
## flown back by a refund are launched staggered inside a short window and drawn at most
## MAX_BURST_COINS at a time, so a group reads as many coins and never floods the scene (T-01-25).
## Coins that wait for their turn stay hidden until they launch (review IN-02).
## A normal drip still launches at once. The hold controller is stepped by fixed deltas
## (E2eSupport.begin_stepped_hold and step_hold), so counts are asserted right after a step, before
## any frame length can free a coin first (review WR-01 closed by stepping). Expectations come from
## the shipped tuning and VFX constants.

const SPOT: StringName = &"house_1"
const HOUSE: StringName = &"house"
const GOLD_MARGIN: int = 10
const PRICEY_COST: int = 30
const HUGE_COST: int = 60
## Coins a single long frame pays in the staggered-group test.
const LONG_FRAME_COINS: int = 6
const CLEANUP_SLACK_S: float = 0.2
## Hold-clock step for the release frame of the refund test.
const RELEASE_STEP_S: float = 1.0 / 64.0
const EPSILON: float = 0.0001

var _ctx: RunContext
var _hold: BuildHoldController
var _map_root: MapRoot
var _vfx: CoinDripVfx
var _shown_coins: int = 0


func after_each() -> void:
	E2eSupport.release_all_actions()


## Spawns the shipped scene (with House I repriced to `cost`, or unchanged for a cost of 0), stands
## the king beside house_1, and starts a stepped hold whose clock is still zero.
func _begin_hold(cost: int) -> void:
	var map: MapConfig = null
	if cost > 0:
		map = E2eSupport.map_with_tier_cost(HOUSE, 1, cost, cost + GOLD_MARGIN)
	_map_root = await E2eSupport.spawn_map(self, map)
	_ctx = _map_root.get_context()
	_hold = _map_root.get_build_hold()
	_vfx = _map_root.find_child("CoinDripVfx", true, false) as CoinDripVfx
	var focused: bool = await E2eSupport.stand_at_spot(self, _map_root, SPOT)
	assert_true(focused, "the king is in range of house_1")
	assert_not_null(_vfx, "the map has a CoinDripVfx")
	watch_signals(_hold)
	await E2eSupport.begin_stepped_hold(self, _hold)


func _cleanup_wait_s() -> float:
	return CoinDripVfx.BURST_WINDOW_SECONDS + CoinDripVfx.MAX_FLIGHT_SECONDS + CLEANUP_SLACK_S


## The coins still in the scene that are drawn (`shown` true) or wait hidden (`shown` false).
func _live_coins(shown: bool) -> Array[MeshInstance3D]:
	var coins: Array[MeshInstance3D] = []
	for child: Node in _vfx.get_children():
		var coin: MeshInstance3D = child as MeshInstance3D
		if coin != null and not coin.is_queued_for_deletion() and coin.visible == shown:
			coins.append(coin)
	return coins


func _on_coin_visibility_changed(coin: MeshInstance3D) -> void:
	if coin.visible:
		_shown_coins += 1


func test_a_long_frame_group_is_staggered_inside_the_burst_window() -> void:
	await _begin_hold(PRICEY_COST)
	if _vfx == null:
		return
	await E2eSupport.step_hold(self, _hold, _ctx.tuning.coin_due_seconds(LONG_FRAME_COINS))
	var delays: Array[float] = _vfx.get_last_burst_delays()

	assert_eq(_hold.get_coins_paid(), LONG_FRAME_COINS, "one long frame paid the due coins")
	assert_eq(delays.size(), LONG_FRAME_COINS, "every coin of the group is launched")
	if delays.is_empty():
		return
	assert_eq(delays[0], 0.0, "the first coin of the group leaves at once")
	for index: int in range(1, delays.size()):
		assert_gt(
			delays[index], delays[index - 1], "coin %d leaves after coin %d" % [index, index - 1]
		)
	assert_lte(
		delays[delays.size() - 1], CoinDripVfx.BURST_WINDOW_SECONDS + EPSILON, "inside the window"
	)
	assert_eq(_vfx.live_coin_count(), LONG_FRAME_COINS, "the whole group is in the scene")


func test_a_huge_long_frame_draws_only_the_visual_cap() -> void:
	await _begin_hold(HUGE_COST)
	if _vfx == null:
		return
	await E2eSupport.step_hold(self, _hold, _ctx.tuning.build_hold_seconds(HUGE_COST))

	assert_eq(_ctx.buildings.current_tier(SPOT), 1, "one frame paid and built the tier")
	assert_eq(
		_vfx.get_last_burst_delays().size(), CoinDripVfx.MAX_BURST_COINS, "a 60-coin group draws 12"
	)
	assert_eq(_vfx.live_coin_count(), CoinDripVfx.MAX_BURST_COINS, "and only 12 are in the scene")


func test_every_group_coin_is_freed_after_the_window_and_the_flight() -> void:
	await _begin_hold(HUGE_COST)
	if _vfx == null:
		return
	await E2eSupport.step_hold(self, _hold, _ctx.tuning.build_hold_seconds(HUGE_COST))

	await wait_seconds(_cleanup_wait_s())

	assert_eq(_vfx.live_coin_count(), 0, "no group coin is left behind")


func test_a_refund_flies_back_the_visual_cap_of_coins_and_frees_them() -> void:
	await _begin_hold(PRICEY_COST)
	if _vfx == null:
		return
	var almost: int = PRICEY_COST - 1
	await E2eSupport.step_hold(self, _hold, _ctx.tuning.coin_due_seconds(almost))
	assert_eq(_hold.get_coins_paid(), almost, "29 coins were paid")
	await wait_seconds(_cleanup_wait_s())
	assert_eq(_vfx.live_coin_count(), 0, "the dripped coins have landed")

	Input.action_release(BuildHoldController.ACTION)
	await E2eSupport.step_hold(self, _hold, RELEASE_STEP_S)

	assert_signal_emitted_with_parameters(_hold, "hold_cancelled", [SPOT, almost])
	assert_eq(
		_vfx.live_coin_count(), CoinDripVfx.MAX_BURST_COINS, "the refund draws at most 12 coins"
	)
	await wait_seconds(_cleanup_wait_s())
	assert_eq(_vfx.live_coin_count(), 0, "the refunded coins are freed")


func test_a_normal_drip_launches_immediately() -> void:
	await _begin_hold(0)
	if _vfx == null:
		return
	await E2eSupport.step_hold(self, _hold, _ctx.tuning.coin_due_seconds(1))
	var delays: Array[float] = _vfx.get_last_burst_delays()

	assert_eq(_hold.get_coins_paid(), 1, "the first coin dripped")
	assert_eq(delays.size(), 1, "a normal drip is a group of one")
	if delays.size() == 1:
		assert_eq(delays[0], 0.0, "and it launches without delay")


## Review IN-02: a coin with no launch delay is never hidden.
func test_a_normal_drip_coin_is_drawn_at_once() -> void:
	await _begin_hold(0)
	if _vfx == null:
		return
	await E2eSupport.step_hold(self, _hold, _ctx.tuning.coin_due_seconds(1))

	assert_eq(_live_coins(true).size(), 1, "the single coin is drawn")
	assert_eq(_live_coins(false).size(), 0, "and nothing waits hidden")


## Review IN-02: the coins of a same-frame group that wait for their turn are not drawn as a stack.
func test_a_long_frame_group_hides_the_coins_that_wait() -> void:
	await _begin_hold(PRICEY_COST)
	if _vfx == null:
		return
	await E2eSupport.step_hold(self, _hold, _ctx.tuning.coin_due_seconds(LONG_FRAME_COINS))

	assert_eq(_hold.get_coins_paid(), LONG_FRAME_COINS, "one long frame paid the due coins")
	assert_eq(_live_coins(true).size(), 1, "only the coin that leaves at once is drawn")
	assert_eq(_live_coins(false).size(), LONG_FRAME_COINS - 1, "the others wait hidden")


## Review IN-02: refund coins wait hidden, and each one is shown when it launches rather than freed
## while still hidden.
func test_refund_coins_wait_hidden_and_are_shown_when_they_launch() -> void:
	await _begin_hold(PRICEY_COST)
	if _vfx == null:
		return
	var almost: int = PRICEY_COST - 1
	await E2eSupport.step_hold(self, _hold, _ctx.tuning.coin_due_seconds(almost))
	await wait_seconds(_cleanup_wait_s())
	assert_eq(_vfx.live_coin_count(), 0, "the dripped coins have landed")

	Input.action_release(BuildHoldController.ACTION)
	await E2eSupport.step_hold(self, _hold, RELEASE_STEP_S)

	var waiting: Array[MeshInstance3D] = _live_coins(false)
	assert_eq(_live_coins(true).size(), 1, "only the coin that leaves at once is drawn")
	assert_eq(waiting.size(), CoinDripVfx.MAX_BURST_COINS - 1, "the others wait hidden")
	_shown_coins = 0
	for coin: MeshInstance3D in waiting:
		coin.visibility_changed.connect(_on_coin_visibility_changed.bind(coin))
	await wait_seconds(_cleanup_wait_s())

	assert_eq(_shown_coins, waiting.size(), "every waiting coin was shown when it launched")
	assert_eq(_vfx.live_coin_count(), 0, "and every refunded coin is freed")
