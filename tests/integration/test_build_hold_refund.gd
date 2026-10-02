extends GutTest
## D-06 on the real scene: a hold is all-or-nothing. Releasing early or leaving the interaction
## range refunds every dripped coin, and the simulation (gold and buildings) never sees a
## partial payment. Also covers the focus lock, the await-release rule and the per-drip
## is_build_allowed re-check (T-01-11).

const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const RICH_GOLD: int = 20
const SLOW_DRIP_S: float = 1.0
const WAIT_SLACK_S: float = 3.0
const SPOT: StringName = &"house_1"
## Sits well inside interaction_radius of a plot.
const NEAR_OFFSET := Vector3(0.5, 0.0, 0.0)
const FAR_OFFSET := Vector3(30.0, 0.0, 0.0)


func after_each() -> void:
	E2eSupport.release_all_actions()


func _rich_map() -> MapConfig:
	var map: MapConfig = (load(PROTOTYPE_MAP) as MapConfig).duplicate(true)
	map.starting_gold = RICH_GOLD
	return map


func _tuning_with_interval(interval: float) -> LoopTuning:
	var tuning: LoopTuning = (load(TUNING) as LoopTuning).duplicate(true)
	tuning.coin_drip_interval = interval
	return tuning


func _spot_position(map_root: MapRoot, spot_id: StringName) -> Vector3:
	return map_root.get_context().buildings.get_spot(spot_id).position


func _stand_at(map_root: MapRoot, spot_id: StringName) -> void:
	E2eSupport.teleport_king(map_root, _spot_position(map_root, spot_id) + NEAR_OFFSET)
	await wait_process_frames(2)


func _coins_at_least(hold: BuildHoldController, coins: int) -> bool:
	return hold.get_coins_paid() >= coins


## A slow drip so the test can act between coins, standing next to `SPOT`.
func _slow_hold_scene() -> MapRoot:
	var map_root: MapRoot = await E2eSupport.spawn_map(
		self, _rich_map(), _tuning_with_interval(SLOW_DRIP_S)
	)
	await _stand_at(map_root, SPOT)
	return map_root


func test_early_release_refunds_every_dripped_coin_and_changes_nothing() -> void:
	var map_root: MapRoot = await _slow_hold_scene()
	var ctx: RunContext = map_root.get_context()
	var hold: BuildHoldController = map_root.get_build_hold()
	var cost: int = ctx.buildings.next_action_cost(SPOT)
	assert_gt(cost, 1, "a House needs at least two coins so a hold can be half done")
	var gold_before: int = ctx.economy.get_gold()
	watch_signals(hold)

	Input.action_press(&"action_build")
	var dripped: bool = await E2eSupport.wait_until(
		self, _coins_at_least.bind(hold, 1), WAIT_SLACK_S + SLOW_DRIP_S
	)
	assert_true(dripped, "at least one coin dripped")
	var paid: int = hold.get_coins_paid()
	assert_lt(paid, cost, "the hold is only partly paid")
	Input.action_release(&"action_build")
	await wait_process_frames(2)

	assert_signal_emitted_with_parameters(hold, "hold_cancelled", [SPOT, paid])
	assert_gt(paid, 0, "a positive number of coins is refunded")
	assert_eq(ctx.economy.get_gold(), gold_before, "gold never moved")
	assert_null(ctx.buildings.get_instance(SPOT), "nothing was built")
	assert_eq(hold.get_coins_paid(), 0, "the hold is reset")
	assert_false(hold.is_holding(), "no hold is active")
	assert_signal_not_emitted(hold, "hold_completed")


func test_leaving_the_range_mid_hold_refunds_and_changes_nothing() -> void:
	var map_root: MapRoot = await _slow_hold_scene()
	var ctx: RunContext = map_root.get_context()
	var hold: BuildHoldController = map_root.get_build_hold()
	var gold_before: int = ctx.economy.get_gold()
	watch_signals(hold)

	Input.action_press(&"action_build")
	var dripped: bool = await E2eSupport.wait_until(
		self, _coins_at_least.bind(hold, 1), WAIT_SLACK_S + SLOW_DRIP_S
	)
	assert_true(dripped, "at least one coin dripped")
	var paid: int = hold.get_coins_paid()
	E2eSupport.teleport_king(map_root, _spot_position(map_root, SPOT) + FAR_OFFSET)
	await wait_process_frames(2)

	assert_signal_emitted_with_parameters(hold, "hold_cancelled", [SPOT, paid])
	assert_eq(ctx.economy.get_gold(), gold_before, "gold never moved")
	assert_null(ctx.buildings.get_instance(SPOT), "nothing was built")
	assert_eq(hold.get_coins_paid(), 0, "the hold is reset")
	assert_false(hold.is_holding(), "no hold is active")


func test_holding_again_after_a_cancel_pays_the_tier_cost_exactly_once() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map())
	var ctx: RunContext = map_root.get_context()
	var hold: BuildHoldController = map_root.get_build_hold()
	var cost: int = ctx.buildings.next_action_cost(SPOT)
	var gold_before: int = ctx.economy.get_gold()
	await _stand_at(map_root, SPOT)

	Input.action_press(&"action_build")
	await E2eSupport.wait_until(self, _coins_at_least.bind(hold, 1), WAIT_SLACK_S)
	Input.action_release(&"action_build")
	await wait_process_frames(2)
	assert_eq(hold.get_coins_paid(), 0, "the cancel reset the drip")
	assert_eq(ctx.economy.get_gold(), gold_before, "the cancel cost nothing")
	assert_null(ctx.buildings.get_instance(SPOT), "the cancel built nothing")

	watch_signals(hold)
	await E2eSupport.hold_action_seconds(
		self, &"action_build", ctx.tuning.build_hold_seconds(cost) + 0.5
	)
	await wait_process_frames(2)
	assert_signal_emitted_with_parameters(hold, "hold_started", [SPOT, cost])
	assert_signal_emitted(hold, "hold_completed")
	assert_eq(ctx.buildings.current_tier(SPOT), 1, "the second hold built tier I")
	assert_eq(ctx.economy.get_gold(), gold_before - cost, "the cost was deducted exactly once")


func test_focus_stays_on_the_active_spot_while_holding() -> void:
	var map: MapConfig = _rich_map()
	# Put a second plot 3 m from house_1 so the king can be nearer to it while house_1 is
	# still inside the interaction radius.
	var neighbour: StringName = &"house_2"
	var anchor: Vector3 = map.spots[0].position
	map.spots[1].position = anchor + Vector3(3.0, 0.0, 0.0)
	var map_root: MapRoot = await E2eSupport.spawn_map(
		self, map, _tuning_with_interval(SLOW_DRIP_S)
	)
	var ctx: RunContext = map_root.get_context()
	var hold: BuildHoldController = map_root.get_build_hold()
	assert_eq(ctx.buildings.spot_ids()[0], SPOT, "house_1 is the first plot")
	E2eSupport.teleport_king(map_root, anchor + Vector3(0.5, 0.0, 0.0))
	await wait_process_frames(2)
	assert_eq(hold.get_focused_spot(), SPOT, "house_1 is nearest at first")
	watch_signals(hold)

	Input.action_press(&"action_build")
	await wait_process_frames(2)
	assert_eq(hold.get_active_spot(), SPOT, "the hold began on house_1")
	E2eSupport.teleport_king(map_root, anchor + Vector3(1.8, 0.0, 0.0))
	await wait_process_frames(2)

	var to_active: float = (
		Vector2(map_root.get_king().global_position.x, map_root.get_king().global_position.z)
		. distance_to(Vector2(anchor.x, anchor.z))
	)
	assert_lt(to_active, ctx.tuning.interaction_radius, "house_1 is still in range")
	var to_neighbour: float = (
		Vector2(map_root.get_king().global_position.x, map_root.get_king().global_position.z)
		. distance_to(Vector2(ctx.buildings.get_spot(neighbour).position.x, anchor.z))
	)
	assert_lt(to_neighbour, to_active, "the neighbour plot is now the nearer one")
	assert_true(hold.is_holding(), "the hold survives")
	assert_eq(hold.get_active_spot(), SPOT, "and stays on house_1")
	assert_eq(hold.get_focused_spot(), SPOT, "focus is locked to the active spot")
	assert_signal_not_emitted(hold, "hold_cancelled")

	Input.action_release(&"action_build")
	await wait_process_frames(2)
	assert_eq(hold.get_focused_spot(), neighbour, "focus resumes once the hold ends")


func test_keeping_the_key_held_after_a_completion_starts_no_new_hold() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map())
	var ctx: RunContext = map_root.get_context()
	var hold: BuildHoldController = map_root.get_build_hold()
	await _stand_at(map_root, SPOT)

	Input.action_press(&"action_build")
	var built: bool = await E2eSupport.wait_until(
		self, func() -> bool: return ctx.buildings.current_tier(SPOT) == 1, WAIT_SLACK_S
	)
	assert_true(built, "the first hold completed")
	assert_gt(ctx.buildings.next_action_cost(SPOT), 0, "the next tier is still purchasable")
	clear_signal_watcher()
	watch_signals(hold)
	var gold_after_build: int = ctx.economy.get_gold()

	await wait_seconds(2.0)
	assert_signal_not_emitted(hold, "hold_started")
	assert_false(hold.is_holding(), "no second hold began while the key stayed down")
	assert_eq(ctx.economy.get_gold(), gold_after_build, "no further gold was spent")
	assert_eq(ctx.buildings.current_tier(SPOT), 1, "the House did not upgrade by itself")


func test_a_hold_is_refunded_if_building_stops_being_allowed_mid_hold() -> void:
	var map_root: MapRoot = await _slow_hold_scene()
	var ctx: RunContext = map_root.get_context()
	var hold: BuildHoldController = map_root.get_build_hold()
	var gold_before: int = ctx.economy.get_gold()
	watch_signals(hold)

	Input.action_press(&"action_build")
	var dripped: bool = await E2eSupport.wait_until(
		self, _coins_at_least.bind(hold, 1), WAIT_SLACK_S + SLOW_DRIP_S
	)
	assert_true(dripped, "at least one coin dripped by day")
	var paid: int = hold.get_coins_paid()
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	await wait_process_frames(2)

	assert_signal_emitted_with_parameters(hold, "hold_cancelled", [SPOT, paid])
	assert_false(hold.is_holding(), "the hold ended")
	assert_eq(ctx.economy.get_gold(), gold_before, "gold never moved")
	assert_null(ctx.buildings.get_instance(SPOT), "nothing was built")
	Input.action_release(&"action_build")
