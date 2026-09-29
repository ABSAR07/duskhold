extends GutTest
## D-05 / D-06 on the real scene: coins fly from the king into the spot as they drip, the HUD
## shows the gold the player would have left, and an early release flies the coins back and
## restores the full amount. The simulation stays all-or-nothing throughout.

const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const START_GOLD: int = 10
const SPOT: StringName = &"house_1"
const NEAR_OFFSET := Vector3(0.5, 0.0, 0.0)
const SLOW_DRIP_S: float = 0.8
const WAIT_SLACK_S: float = 4.0
const FLIGHT_SETTLE_S: float = 0.4
const HUD_RESTORE_S: float = 0.5


func after_each() -> void:
	E2eSupport.release_all_actions()


func _map_with_gold() -> MapConfig:
	var map: MapConfig = (load(PROTOTYPE_MAP) as MapConfig).duplicate(true)
	map.starting_gold = START_GOLD
	return map


func _tuning_with_interval(interval: float) -> LoopTuning:
	var tuning: LoopTuning = (load(TUNING) as LoopTuning).duplicate(true)
	tuning.coin_drip_interval = interval
	return tuning


func _vfx(map_root: MapRoot) -> CoinDripVfx:
	return map_root.find_child("CoinDripVfx", true, false) as CoinDripVfx


func _gold_text(map_root: MapRoot) -> String:
	return (map_root.find_child("GoldLabel", true, false) as Label).text


func _coins_at_least(hold: BuildHoldController, coins: int) -> bool:
	return hold.get_coins_paid() >= coins


## A map where house_1 already stands at tier I, so the next hold is the tier II upgrade,
## with the king beside it.
func _upgrade_scene(interval: float) -> MapRoot:
	var map_root: MapRoot = await E2eSupport.spawn_map(
		self, _map_with_gold(), _tuning_with_interval(interval)
	)
	var ctx: RunContext = map_root.get_context()
	assert_eq(ctx.commands.submit(BuildIntent.new(SPOT)), CommandProcessor.OK, "tier I built")
	var spot_position: Vector3 = ctx.buildings.get_spot(SPOT).position
	E2eSupport.teleport_king(map_root, spot_position + NEAR_OFFSET)
	await wait_process_frames(2)
	return map_root


func test_the_hud_shows_gold_minus_the_coins_in_flight_while_the_economy_is_untouched() -> void:
	var map_root: MapRoot = await _upgrade_scene(SLOW_DRIP_S)
	var ctx: RunContext = map_root.get_context()
	var hold: BuildHoldController = map_root.get_build_hold()
	var gold: int = ctx.economy.get_gold()
	assert_gte(ctx.buildings.next_action_cost(SPOT), 3, "the upgrade takes at least three coins")

	Input.action_press(&"action_build")
	var reached: bool = await E2eSupport.wait_until(
		self, _coins_at_least.bind(hold, 2), WAIT_SLACK_S
	)
	assert_true(reached, "two coins dripped")
	var paid: int = hold.get_coins_paid()
	assert_eq(paid, 2, "caught the hold at exactly two coins")
	assert_eq(_gold_text(map_root), "Gold: %d" % (gold - paid), "HUD shows gold minus the pending")
	assert_eq(ctx.economy.get_gold(), gold, "Economy gold has not moved")


func test_a_coin_node_is_alive_in_flight_mid_hold() -> void:
	var map_root: MapRoot = await _upgrade_scene(SLOW_DRIP_S)
	var hold: BuildHoldController = map_root.get_build_hold()
	var vfx: CoinDripVfx = _vfx(map_root)
	assert_not_null(vfx, "the map has a CoinDripVfx")
	if vfx == null:
		return

	Input.action_press(&"action_build")
	var reached: bool = await E2eSupport.wait_until(
		self, _coins_at_least.bind(hold, 2), WAIT_SLACK_S
	)
	assert_true(reached, "two coins dripped")
	assert_gte(vfx.live_coin_count(), 1, "at least one coin is still flying")
	await wait_seconds(FLIGHT_SETTLE_S)
	assert_true(hold.is_holding(), "the hold is still running")
	assert_eq(vfx.live_coin_count(), 0, "landed coins are freed")


func test_early_release_flies_the_coins_back_and_restores_the_hud() -> void:
	var map_root: MapRoot = await _upgrade_scene(SLOW_DRIP_S)
	var ctx: RunContext = map_root.get_context()
	var hold: BuildHoldController = map_root.get_build_hold()
	var vfx: CoinDripVfx = _vfx(map_root)
	assert_not_null(vfx, "the map has a CoinDripVfx")
	if vfx == null:
		return
	var gold: int = ctx.economy.get_gold()

	Input.action_press(&"action_build")
	var reached: bool = await E2eSupport.wait_until(
		self, _coins_at_least.bind(hold, 2), WAIT_SLACK_S
	)
	assert_true(reached, "two coins dripped")
	await wait_seconds(FLIGHT_SETTLE_S)
	var paid: int = hold.get_coins_paid()
	assert_eq(vfx.live_coin_count(), 0, "the fly-in coins have landed")
	watch_signals(hold)
	Input.action_release(&"action_build")
	await wait_process_frames(2)

	assert_signal_emitted_with_parameters(hold, "hold_cancelled", [SPOT, paid])
	assert_eq(vfx.live_coin_count(), paid, "one refund coin per refunded coin is flying back")
	var restored: bool = await E2eSupport.wait_until(
		self, func() -> bool: return _gold_text(map_root) == "Gold: %d" % gold, HUD_RESTORE_S
	)
	assert_true(restored, "the HUD shows the full amount again within half a second")
	assert_eq(ctx.economy.get_gold(), gold, "Economy gold never moved")
	await wait_seconds(FLIGHT_SETTLE_S)
	assert_eq(vfx.live_coin_count(), 0, "the refund coins are freed on arrival")


func test_after_completion_the_hud_shows_the_new_gold_without_double_subtraction() -> void:
	var map_root: MapRoot = await _upgrade_scene(0.2)
	var ctx: RunContext = map_root.get_context()
	var cost: int = ctx.buildings.next_action_cost(SPOT)
	var gold: int = ctx.economy.get_gold()

	Input.action_press(&"action_build")
	var built: bool = await E2eSupport.wait_until(
		self, func() -> bool: return ctx.buildings.current_tier(SPOT) == 2, WAIT_SLACK_S
	)
	Input.action_release(&"action_build")
	await wait_process_frames(2)

	assert_true(built, "the upgrade completed")
	assert_eq(ctx.economy.get_gold(), gold - cost, "Economy paid the cost once")
	assert_eq(_gold_text(map_root), "Gold: %d" % (gold - cost), "HUD shows exactly the new gold")
	await wait_seconds(FLIGHT_SETTLE_S)
	# Let the replaced building view finish its queue_free before GUT counts orphans.
	await wait_process_frames(1)
