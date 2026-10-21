extends GutTest
## BLDG-09, D-03 on the real scene (fixed run seed 1), on a deep copy of the shipped prototype map
## whose Tower II needs castle II (the shipped data stays ungated until plan 05-11): with Tower I
## standing, the tower_1 label reads "Needs Castle II" with no price, the action key is refused with
## hold_denied(tower_1, castle_tier), the label shakes and no gold moves. After castle II is bought
## through the cards the label shows the price again and a full hold buys Tower II.

const CASTLE: StringName = &"castle_plot"
const TOWER: StringName = &"tower_1"
const SETTLE_FRAMES: int = 3
const GRANTED_GOLD: int = 60
const HOLD_SLACK_S: float = 1.5
const SHAKE_WINDOW_S: float = 0.6

var _map: MapRoot
var _ctx: RunContext


func before_each() -> void:
	var gated: MapConfig = E2eSupport.waveless_prototype_map()
	for building_def: BuildingDef in gated.buildings:
		if building_def.id == &"tower":
			building_def.tier_def(2).requires_castle_tier = 2
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	_map = scene.instantiate()
	_map.map_config = gated
	_map.fixed_run_seed = 1
	_map.handle_results_actions = false
	add_child_autofree(_map)
	await wait_process_frames(SETTLE_FRAMES)
	_ctx = _map.get_context()
	_ctx.economy.grant(GRANTED_GOLD)


func after_each() -> void:
	E2eSupport.release_all_actions()


func _label() -> Node3D:
	return _map.find_child("SpotLabel", true, false) as Node3D


func _status() -> Label3D:
	return _label().find_child("Status", true, false) as Label3D


func _tier_cost(spot_id: StringName, tier: int) -> int:
	return _ctx.buildings.get_building_def_for_spot(spot_id).tier_def(tier).cost


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await wait_process_frames(2)
	Input.action_release(action)
	await wait_process_frames(2)


## Presses and holds the action key until `spot_id` reaches `tier`, then lets go.
func _hold_to_tier(spot_id: StringName, tier: int) -> bool:
	var seconds: float = _ctx.tuning.build_hold_seconds(_tier_cost(spot_id, tier)) + HOLD_SLACK_S
	Input.action_press(&"action_build")
	var reached: Callable = func() -> bool: return _ctx.buildings.current_tier(spot_id) == tier
	var got: bool = await E2eSupport.wait_until(self, reached, seconds)
	Input.action_release(&"action_build")
	await wait_process_frames(2)
	return got


func _stand_at(spot_id: StringName) -> void:
	assert_true(
		await E2eSupport.stand_at_spot(self, _map, spot_id), "the king reached %s" % spot_id
	)
	await wait_process_frames(2)


func _buy_tower_one() -> void:
	await _stand_at(TOWER)
	assert_true(await _hold_to_tier(TOWER, 1), "Tower I was bought")


func test_the_gated_tower_label_reads_needs_castle_two_with_no_coins() -> void:
	await _buy_tower_one()
	assert_true(_label().visible, "the label shows")
	assert_eq(_status().text, "Needs Castle II", "the requirement")
	var coins: Node3D = _label().find_child("Coins", true, false) as Node3D
	assert_eq(coins.get_child_count(), 0, "no coin row")
	var title: Label3D = _label().find_child("Title", true, false) as Label3D
	assert_eq(title.text, "Tower II", "the title names the locked tier")
	assert_eq(title.modulate, SpotLabel.NORMAL_COLOR, "and it is not red")


func test_the_action_key_is_denied_for_free_and_the_label_shakes() -> void:
	await _buy_tower_one()
	var hold: BuildHoldController = _map.get_build_hold()
	watch_signals(hold)
	var gold: int = _ctx.economy.get_gold()
	var rest_x: float = _label().global_position.x
	var widest: float = 0.0
	Input.action_press(&"action_build")
	var started: int = Time.get_ticks_msec()
	var window_ms: int = roundi(SHAKE_WINDOW_S * 1000.0)
	while Time.get_ticks_msec() - started < window_ms:
		widest = maxf(widest, absf(_label().global_position.x - rest_x))
		await wait_process_frames(1)
	Input.action_release(&"action_build")
	assert_signal_emitted_with_parameters(hold, "hold_denied", [TOWER, &"castle_tier"])
	assert_signal_not_emitted(hold, "hold_started", "no hold began")
	assert_gt(widest, 0.02, "the label shook")
	assert_eq(_ctx.economy.get_gold(), gold, "gold is unchanged")
	assert_eq(_ctx.buildings.current_tier(TOWER), 1, "and so is the tier")


func test_castle_two_lifts_the_lock_and_a_full_hold_buys_tower_two() -> void:
	await _buy_tower_one()
	await _stand_at(CASTLE)
	await _tap(&"group_1")
	assert_true(await _hold_to_tier(CASTLE, 2), "the castle reached tier II")
	await _stand_at(TOWER)
	assert_eq(_status().text, "", "the lock is gone")
	var content: Dictionary = SpotLabelModel.describe(_ctx, TOWER, 0)
	assert_eq(content["cost"], _tier_cost(TOWER, 2), "the price is back")
	var coins: Node3D = _label().find_child("Coins", true, false) as Node3D
	assert_eq(coins.get_child_count(), _tier_cost(TOWER, 2), "and so are the coins")
	var gold: int = _ctx.economy.get_gold()
	assert_true(await _hold_to_tier(TOWER, 2), "a full hold buys Tower II")
	assert_eq(_ctx.economy.get_gold(), gold - _tier_cost(TOWER, 2), "for its price")
