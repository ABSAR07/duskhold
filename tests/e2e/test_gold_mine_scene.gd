extends GutTest
## ECON-03, D-12 on the real prototype scene (the tracer of plan 05-06): the king rides to the Gold
## Mine plot and holds the action key, the Mine's model stands up, its label says how its payout
## falls before it is built and what it pays next once built, and across two nights the one
## dawn_payout lists the Mine at its starting gold and then one less, the gold rising by the totals.
## The Mine's numbers are set on a deep copy of the map (first payout 3, step 1, floor 1), so the
## plan 05-11 fit cannot break the test; the label text is built from that same data.

const MINE: StringName = &"gold_mine_1"
const MINE_VIEW_FILE := "gold_mine_t1.tscn"
const START: int = 3
const STEP: int = 1
const FLOOR: int = 1
const RICH_GOLD: int = 30
const FAST_NIGHT_S: float = 0.5
## Longer than one coin trip, so the payout vfx does not warn that its coins cannot land.
const DAWN_S: float = 1.0
const SETTLE_FRAMES: int = 3
const RIDE_TIMEOUT_S: float = 20.0
const HOLD_SLACK_S: float = 1.5
const PHASE_TIMEOUT_S: float = 12.0

var _root: MapRoot
var _ctx: RunContext


func before_each() -> void:
	var map: MapConfig = E2eSupport.waveless_prototype_map()
	map.starting_gold = RICH_GOLD
	for building_def: BuildingDef in map.buildings:
		if building_def.id == &"gold_mine":
			var tier: BuildingTierDef = building_def.tier_def(1)
			tier.dawn_income = START
			tier.income_step = STEP
			tier.income_floor = FLOOR
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


func _effect_text() -> String:
	return (_label().find_child("Effect", true, false) as Label3D).text


func _mine_tier() -> BuildingTierDef:
	return _ctx.buildings.get_building_def_for_spot(MINE).tier_def(1)


## Presses and holds the action key until the Mine stands, then lets go.
func _hold_until_built() -> bool:
	var seconds: float = _ctx.tuning.build_hold_seconds(_mine_tier().cost) + HOLD_SLACK_S
	Input.action_press(&"action_build")
	var built: Callable = func() -> bool: return _ctx.buildings.current_tier(MINE) == 1
	var got: bool = await E2eSupport.wait_until(self, built, seconds)
	Input.action_release(&"action_build")
	await wait_process_frames(2)
	return got


func _in_phase(phase: RunManager.RunPhase) -> bool:
	return _ctx.run_manager.get_phase() == phase


func _wait_phase(phase: RunManager.RunPhase) -> bool:
	return await E2eSupport.wait_until(self, _in_phase.bind(phase), PHASE_TIMEOUT_S)


## The nth dawn_payout emission as [total, per_spot].
func _payout(emission: int) -> Array:
	return get_signal_parameters(_ctx.events, "dawn_payout", emission)


func test_the_label_says_how_the_payout_falls_before_the_mine_is_built() -> void:
	assert_true(await E2eSupport.stand_at_spot(self, _root, MINE), "the king reached the plot")
	await wait_process_frames(2)
	assert_true(_label().visible, "the label shows")
	assert_eq(_effect_text(), "Pays 3 gold, then 1 less each dawn, never below 1", "the decline")


func test_the_king_rides_to_the_plot_holds_and_the_mine_stands_up() -> void:
	var reached: bool = await E2eSupport.ride_until_focused(self, _root, MINE, RIDE_TIMEOUT_S)
	assert_true(reached, "the king rode to the Gold Mine plot")
	var gold: int = _ctx.economy.get_gold()

	assert_true(await _hold_until_built(), "a full hold built the Mine")

	assert_eq(_ctx.buildings.current_tier(MINE), 1, "tier I stands")
	assert_eq(_ctx.economy.get_gold(), gold - _mine_tier().cost, "for its price")
	var view: Node3D = (_root.get_node("BuildingViews") as BuildingViews).get_view(MINE)
	assert_not_null(view, "the plot has a view")
	assert_true(
		str(view.get_meta(&"view_source", "")).ends_with(MINE_VIEW_FILE), "it is the Mine's model"
	)
	assert_eq(_effect_text(), "Next dawn: 3 gold", "built, the label promises the next payout")


func test_two_nights_pay_the_mine_three_then_two_through_the_one_payout() -> void:
	assert_true(await E2eSupport.stand_at_spot(self, _root, MINE), "the king reached the plot")
	assert_true(await _hold_until_built(), "a full hold built the Mine")
	watch_signals(_ctx.events)

	var gold_before_one: int = _ctx.economy.get_gold()
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night 1")
	assert_true(await _wait_phase(RunManager.RunPhase.DAWN), "dawn 1")
	var first: Array = _payout(0)
	assert_eq((first[1] as Dictionary)[MINE], START, "dawn 1 pays the starting gold")
	assert_eq(_ctx.economy.get_gold(), gold_before_one + int(first[0]), "gold rose by the total")

	assert_true(await _wait_phase(RunManager.RunPhase.DAY), "day 2")
	var gold_before_two: int = _ctx.economy.get_gold()
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night 2")
	assert_true(await _wait_phase(RunManager.RunPhase.DAWN), "dawn 2")
	var second: Array = _payout(1)
	assert_eq((second[1] as Dictionary)[MINE], START - STEP, "dawn 2 pays one less")
	assert_eq(_ctx.economy.get_gold(), gold_before_two + int(second[0]), "gold rose by the total")
	assert_signal_emit_count(_ctx.events, "dawn_payout", 2, "one payout event per dawn")
	assert_true(await _wait_phase(RunManager.RunPhase.DAY), "day 3")
	assert_eq(_effect_text(), "Next dawn: 1 gold", "and the label now promises the floor")
