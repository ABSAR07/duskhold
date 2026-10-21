extends GutTest
## ECON-04, D-10 on the real prototype scene (the tracer of plan 05-07, fixed run seed 1): the three
## Fields stand locked from day 1. The king at field_1 reads "Needs a Mill" with no price, and the
## action key gives hold_denied(field_1, needs_spot) with the gold unchanged. He builds the Mill by
## holding and its model appears; back at field_1 the label shows the Field's price and a hold
## builds it, its model appearing; after a night the one dawn_payout lists mill_1 and field_1 at
## the tier I incomes read from the shipped data.

const MILL: StringName = &"mill_1"
const FIELD: StringName = &"field_1"
const MILL_VIEW_FILE := "mill_t1.tscn"
const FIELD_VIEW_FILE := "field_t1.tscn"
const RICH_GOLD: int = 40
const FAST_NIGHT_S: float = 0.5
## Longer than one coin trip, so the payout vfx does not warn that its coins cannot land.
const DAWN_S: float = 1.0
const SETTLE_FRAMES: int = 3
const HOLD_SLACK_S: float = 1.5
const DENIED_WINDOW_S: float = 0.5
const PHASE_TIMEOUT_S: float = 12.0

var _root: MapRoot
var _ctx: RunContext


func before_each() -> void:
	var map: MapConfig = E2eSupport.waveless_prototype_map()
	map.starting_gold = RICH_GOLD
	var tuning: LoopTuning = (load(E2eSupport.TUNING_PATH) as LoopTuning).duplicate(true)
	tuning.placeholder_night_seconds = FAST_NIGHT_S
	tuning.dawn_seconds = DAWN_S
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	_root = scene.instantiate()
	_root.map_config = map
	_root.loop_tuning = tuning
	_root.fixed_run_seed = 1
	_root.handle_results_actions = false
	add_child_autofree(_root)
	await wait_process_frames(SETTLE_FRAMES)
	_ctx = _root.get_context()


func after_each() -> void:
	E2eSupport.release_all_actions()


func _label() -> Node3D:
	return _root.find_child("SpotLabel", true, false) as Node3D


func _status_text() -> String:
	return (_label().find_child("Status", true, false) as Label3D).text


func _tier_def(spot_id: StringName, tier: int) -> BuildingTierDef:
	return _ctx.buildings.get_building_def_for_spot(spot_id).tier_def(tier)


func _view_source(spot_id: StringName) -> String:
	var view: Node3D = (_root.get_node("BuildingViews") as BuildingViews).get_view(spot_id)
	return str(view.get_meta(&"view_source", "")) if view != null else ""


## Presses and holds the action key until `spot_id` stands at `tier`, then lets go.
func _hold_to_tier(spot_id: StringName, tier: int) -> bool:
	var seconds: float = _ctx.tuning.build_hold_seconds(_tier_def(spot_id, tier).cost)
	Input.action_press(&"action_build")
	var built: Callable = func() -> bool: return _ctx.buildings.current_tier(spot_id) == tier
	var got: bool = await E2eSupport.wait_until(self, built, seconds + HOLD_SLACK_S)
	Input.action_release(&"action_build")
	await wait_process_frames(2)
	return got


func _stand_at(spot_id: StringName) -> void:
	assert_true(await E2eSupport.stand_at_spot(self, _root, spot_id), "reached %s" % spot_id)
	await wait_process_frames(2)


func _in_phase(phase: RunManager.RunPhase) -> bool:
	return _ctx.run_manager.get_phase() == phase


func test_a_locked_field_reads_needs_a_mill_and_the_hold_is_denied_for_free() -> void:
	await _stand_at(FIELD)
	assert_true(_label().visible, "the label shows")
	assert_eq(_status_text(), "Needs a Mill", "the lock reads as the plan says")
	var coins: Node3D = _label().find_child("Coins", true, false) as Node3D
	assert_eq(coins.get_child_count(), 0, "with no coin row")
	var hold: BuildHoldController = _root.get_build_hold()
	watch_signals(hold)
	var gold: int = _ctx.economy.get_gold()
	Input.action_press(&"action_build")
	await wait_seconds(DENIED_WINDOW_S)
	Input.action_release(&"action_build")
	assert_signal_emitted_with_parameters(hold, "hold_denied", [FIELD, &"needs_spot"])
	assert_signal_not_emitted(hold, "hold_started", "no hold began")
	assert_eq(_ctx.economy.get_gold(), gold, "no gold moved")
	assert_eq(_ctx.buildings.current_tier(FIELD), 0, "and the Field was not built")


func test_the_mill_opens_the_field_and_a_hold_builds_it_with_its_own_model() -> void:
	await _stand_at(MILL)
	var gold: int = _ctx.economy.get_gold()
	assert_true(await _hold_to_tier(MILL, 1), "a full hold built the Mill")
	assert_eq(_ctx.economy.get_gold(), gold - _tier_def(MILL, 1).cost, "for its price")
	assert_true(_view_source(MILL).ends_with(MILL_VIEW_FILE), "the Mill's model stands")

	await _stand_at(FIELD)
	assert_eq(_status_text(), "", "the lock is gone")
	var content: Dictionary = SpotLabelModel.describe(_ctx, FIELD, 0)
	assert_eq(content["cost"], _tier_def(FIELD, 1).cost, "the label shows the Field's price")
	var coins: Node3D = _label().find_child("Coins", true, false) as Node3D
	assert_eq(coins.get_child_count(), _tier_def(FIELD, 1).cost, "as coins")
	gold = _ctx.economy.get_gold()
	assert_true(await _hold_to_tier(FIELD, 1), "a full hold built the Field")
	assert_eq(_ctx.economy.get_gold(), gold - _tier_def(FIELD, 1).cost, "for its price")
	assert_true(_view_source(FIELD).ends_with(FIELD_VIEW_FILE), "the Field's model stands")


func test_after_a_night_the_one_payout_lists_the_mill_and_the_field() -> void:
	await _stand_at(MILL)
	assert_true(await _hold_to_tier(MILL, 1), "the Mill stands")
	await _stand_at(FIELD)
	assert_true(await _hold_to_tier(FIELD, 1), "the Field stands")
	watch_signals(_ctx.events)
	var gold: int = _ctx.economy.get_gold()
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night 1")
	var dawn: Callable = _in_phase.bind(RunManager.RunPhase.DAWN)
	assert_true(await E2eSupport.wait_until(self, dawn, PHASE_TIMEOUT_S), "dawn 1")
	assert_signal_emit_count(_ctx.events, "dawn_payout", 1, "one payout event")
	var payout: Array = get_signal_parameters(_ctx.events, "dawn_payout", 0)
	var per_spot: Dictionary = payout[1]
	assert_eq(per_spot[MILL], _tier_def(MILL, 1).dawn_income, "the Mill paid its tier I income")
	assert_eq(per_spot[FIELD], _tier_def(FIELD, 1).dawn_income, "the Field paid its flat gold")
	assert_eq(_ctx.economy.get_gold(), gold + int(payout[0]), "the gold rose by the total")
