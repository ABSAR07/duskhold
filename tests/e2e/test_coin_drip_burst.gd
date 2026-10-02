extends GutTest
## UAT G-01-58 (D-05 as amended) on the real scene: when the 3 s cap pays the remaining coins in
## one frame, the coin VFX launches them staggered inside a short window and draws at most
## MAX_BURST_COINS of them, so the rush reads as many coins and never floods the scene (T-01-25).
## A normal drip still launches at once. Expectations come from the shipped tuning and VFX
## constants.

const SPOT: StringName = &"house_1"
const HOUSE: StringName = &"house"
const NEAR_OFFSET := Vector3(0.5, 0.0, 0.0)
const GOLD_MARGIN: int = 10
const PRICEY_COST: int = 30
const HUGE_COST: int = 60
const CAP_WAIT_SLACK_S: float = 1.0
const CLEANUP_SLACK_S: float = 0.2
const EPSILON: float = 0.0001
## At the 0.08 s interval floor with the 0.12 s minimum flight, at most two drip coins are airborne
## when the cap frame arrives.
const MAX_DRIPS_IN_AIR: int = 2

var _ctx: RunContext
var _map_root: MapRoot
var _vfx: CoinDripVfx


func after_each() -> void:
	E2eSupport.release_all_actions()


func _focused() -> bool:
	return _map_root.get_build_hold().get_focused_spot() == SPOT


func _tier_built() -> bool:
	return _ctx.buildings.current_tier(SPOT) == 1


func _one_coin_paid() -> bool:
	return _map_root.get_build_hold().get_coins_paid() >= 1


func _stand_at_plot(map: MapConfig) -> void:
	_map_root = await E2eSupport.spawn_map(self, map)
	_ctx = _map_root.get_context()
	_vfx = _map_root.find_child("CoinDripVfx", true, false) as CoinDripVfx
	var plot: Vector3 = _ctx.buildings.get_spot(SPOT).position
	E2eSupport.teleport_king(_map_root, plot + NEAR_OFFSET)
	await E2eSupport.wait_until(self, _focused, 1.0)


## Builds House I of the given cost by holding to the cap, and returns right after it stands.
func _hold_until_built(cost: int) -> void:
	await _stand_at_plot(E2eSupport.map_with_tier_cost(HOUSE, 1, cost, cost + GOLD_MARGIN))
	Input.action_press(&"action_build")
	await E2eSupport.wait_until(
		self, _tier_built, _ctx.tuning.max_build_hold_seconds + CAP_WAIT_SLACK_S
	)
	Input.action_release(&"action_build")


## How many of the first `cost` coins share the cap's due time.
func _coins_due_at_the_cap(cost: int) -> int:
	var count: int = 0
	for coin: int in range(1, cost + 1):
		if _ctx.tuning.coin_due_seconds(coin) >= _ctx.tuning.max_build_hold_seconds - EPSILON:
			count += 1
	return count


func test_the_cap_rush_is_staggered_inside_the_burst_window() -> void:
	await _hold_until_built(PRICEY_COST)
	assert_not_null(_vfx, "the map has a CoinDripVfx")
	if _vfx == null:
		return
	var delays: Array[float] = _vfx.get_last_burst_delays()
	var expected: int = mini(_coins_due_at_the_cap(PRICEY_COST), CoinDripVfx.MAX_BURST_COINS)

	assert_gte(delays.size(), expected, "every rushed coin up to the visual cap is launched")
	assert_lte(delays.size(), CoinDripVfx.MAX_BURST_COINS, "never more than the visual cap")
	if delays.is_empty():
		return
	assert_eq(delays[0], 0.0, "the first rushed coin leaves at once")
	for index: int in range(1, delays.size()):
		assert_gt(
			delays[index], delays[index - 1], "coin %d leaves after coin %d" % [index, index - 1]
		)
	assert_lte(
		delays[delays.size() - 1], CoinDripVfx.BURST_WINDOW_SECONDS + EPSILON, "inside the window"
	)
	assert_gte(_vfx.live_coin_count(), delays.size(), "the rushed coins are all in the scene")


func test_a_huge_rush_draws_only_the_visual_cap() -> void:
	await _hold_until_built(HUGE_COST)
	assert_not_null(_vfx, "the map has a CoinDripVfx")
	if _vfx == null:
		return

	assert_eq(
		_vfx.get_last_burst_delays().size(), CoinDripVfx.MAX_BURST_COINS, "a 36-coin rush draws 12"
	)
	assert_lte(
		_vfx.live_coin_count(),
		CoinDripVfx.MAX_BURST_COINS + MAX_DRIPS_IN_AIR,
		"the scene holds the capped rush plus the last drip coins"
	)


func test_every_burst_coin_is_freed_after_the_window_and_the_flight() -> void:
	await _hold_until_built(PRICEY_COST)
	assert_not_null(_vfx, "the map has a CoinDripVfx")
	if _vfx == null:
		return

	await wait_seconds(
		CoinDripVfx.BURST_WINDOW_SECONDS + CoinDripVfx.MAX_FLIGHT_SECONDS + CLEANUP_SLACK_S
	)

	assert_eq(_vfx.live_coin_count(), 0, "no burst coin is left behind")


func test_a_normal_drip_launches_immediately() -> void:
	await _stand_at_plot(null)
	assert_not_null(_vfx, "the map has a CoinDripVfx")
	if _vfx == null:
		return

	Input.action_press(&"action_build")
	var paid: bool = await E2eSupport.wait_until(self, _one_coin_paid, CAP_WAIT_SLACK_S)

	assert_true(paid, "the first coin dripped")
	var delays: Array[float] = _vfx.get_last_burst_delays()
	assert_eq(delays.size(), 1, "a normal drip is a group of one")
	if delays.size() == 1:
		assert_eq(delays[0], 0.0, "and it launches without delay")
