extends GutTest
## BLDG-08, BLDG-05, UI-02, D-01, D-02 on the real scene (fixed run seed 1): the king climbs the
## castle from tier I to tier IV with the number keys and the action key, one pick of four at each
## upgrade. Tier II with Royal Training, tier III with Engineers (key 2), tier IV with Golden Age
## (key 4): three choice_picked lines in the digest in that order, each card armed once, the cards
## refreshing to the next tier's four with nothing highlighted, the castle's label listing the
## three picks, and no cards at the top. Nothing here reads rendered pixels: the label is checked
## through SpotLabelModel and the SpotLabel nodes' text, the cards through CardRow's hooks.

const CASTLE: StringName = &"castle_plot"
const SETTLE_FRAMES: int = 3
const GRANTED_GOLD: int = 80
const HOLD_SLACK_S: float = 1.5
const PICKS_LINE := "Royal Training · Engineers · Golden Age"

var _map: MapRoot
var _ctx: RunContext
var _picker: CardPicker
var _row: CardRow
var _recorder: SimRecorder
var _picked: Array[StringName] = []


func before_each() -> void:
	_picked = []
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	_map = scene.instantiate()
	_map.map_config = E2eSupport.waveless_prototype_map()
	_map.fixed_run_seed = 1
	_map.handle_results_actions = false
	add_child_autofree(_map)
	await wait_process_frames(SETTLE_FRAMES)
	_ctx = _map.get_context()
	_picker = _map.get_cards()
	_row = _map.get_node("CardRow")
	_recorder = SimRecorder.attach(_ctx)
	_ctx.events.choice_picked.connect(_on_picked)


func after_each() -> void:
	E2eSupport.release_all_actions()


func _on_picked(_spot_id: StringName, _tier: int, choice_id: StringName) -> void:
	_picked.append(choice_id)


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await wait_process_frames(2)
	Input.action_release(action)
	await wait_process_frames(2)


## Presses and holds the action key until the castle reaches `tier`, then lets go.
func _hold_to_tier(tier: int) -> bool:
	var cost: int = _ctx.buildings.get_building_def_for_spot(CASTLE).tier_def(tier).cost
	var seconds: float = _ctx.tuning.build_hold_seconds(cost) + HOLD_SLACK_S
	Input.action_press(&"action_build")
	var reached: Callable = func() -> bool: return _ctx.buildings.current_tier(CASTLE) == tier
	var done: bool = await E2eSupport.wait_until(self, reached, seconds)
	Input.action_release(&"action_build")
	await wait_process_frames(3)
	return done


func _card_names() -> Array[String]:
	var names: Array[String] = []
	for index: int in range(_row.card_count()):
		names.append(_row.card_name(index))
	return names


func _picks_label() -> Label3D:
	return _map.find_child("Picks", true, false) as Label3D


func _choice_lines() -> Array[String]:
	var found: Array[String] = []
	for line: String in _recorder.lines():
		if " choice_picked " in line:
			found.append(line.get_slice(" choice_picked ", 1))
	return found


func test_the_castle_climbs_to_tier_four_with_one_pick_by_key_at_each_upgrade() -> void:
	_ctx.economy.grant(GRANTED_GOLD)
	assert_true(await E2eSupport.stand_at_spot(self, _map, CASTLE), "the king is at the castle")
	await wait_process_frames(2)
	assert_eq(_card_names().size(), 4, "four tier II cards show")

	await _tap(&"group_1")
	assert_true(await _hold_to_tier(2), "tier II bought")
	assert_eq(_picked, [&"royal_training"] as Array[StringName], "with Royal Training")
	assert_eq(_picker.highlighted_index(), -1, "the highlight reset")
	assert_eq(
		_card_names(), ["Headsman's Edge", "Engineers", "War Horns", "Warded Mail"], "tier III row"
	)

	await _tap(&"group_2")
	assert_eq(_picker.highlighted(), &"engineers", "key 2 highlights Engineers")
	assert_true(await _hold_to_tier(3), "tier III bought")
	assert_eq(
		_card_names(),
		["Iron Discipline", "Arrow Storm", "Master Builders", "Golden Age"],
		"tier IV row"
	)
	assert_eq(_picker.highlighted_index(), -1, "none highlighted on the new row")

	await _tap(&"group_4")
	assert_eq(_picker.highlighted(), &"golden_age", "key 4 highlights Golden Age")
	assert_true(await _hold_to_tier(4), "tier IV bought")

	var expected: Array[StringName] = [&"royal_training", &"engineers", &"golden_age"]
	assert_eq(_picked, expected, "three picks, in order")
	assert_eq(_ctx.choices.all_picks(), expected, "the ledger agrees")
	assert_eq(_ctx.castle.tier(), 4, "the castle is tier IV")
	assert_false(_picker.is_showing(), "no cards at the top tier")
	assert_eq(_row.card_count(), 0, "no row")


func test_the_three_picks_are_digest_lines_and_each_card_is_armed_once() -> void:
	_ctx.economy.grant(GRANTED_GOLD)
	assert_true(await E2eSupport.stand_at_spot(self, _map, CASTLE), "the king is at the castle")
	await wait_process_frames(2)
	await _tap(&"group_1")
	await _hold_to_tier(2)
	await _tap(&"group_2")
	await _hold_to_tier(3)
	await _tap(&"group_4")
	await _hold_to_tier(4)
	var lines: Array[String] = _choice_lines()
	assert_eq(lines.size(), 3, "three choice_picked lines")
	assert_eq(lines[0], "castle_plot 2 royal_training", "first")
	assert_eq(lines[1], "castle_plot 3 engineers", "second")
	assert_eq(lines[2], "castle_plot 4 golden_age", "third")
	for card_id: StringName in [&"royal_training", &"engineers", &"golden_age"]:
		assert_true(_ctx.stat_stack.has_source(card_id), "%s is armed" % card_id)
	assert_false(_ctx.stat_stack.has_source(&"masons"), "a card never offered is not armed")


func test_the_label_lists_the_picks_as_they_are_made_and_ends_on_max_tier() -> void:
	_ctx.economy.grant(GRANTED_GOLD)
	assert_true(await E2eSupport.stand_at_spot(self, _map, CASTLE), "the king is at the castle")
	await wait_process_frames(2)
	var picks: Label3D = _picks_label()
	assert_not_null(picks, "the SpotLabel has a Picks line")
	assert_false(picks.visible, "hidden while nothing is picked")
	await _tap(&"group_1")
	await _hold_to_tier(2)
	assert_eq(picks.text, "Royal Training", "the first pick shows")
	assert_true(picks.visible, "and the line with it")
	await _tap(&"group_2")
	await _hold_to_tier(3)
	assert_eq(picks.text, "Royal Training · Engineers", "two picks")
	await _tap(&"group_4")
	await _hold_to_tier(4)
	assert_eq(picks.text, PICKS_LINE, "all three, in pick order")
	var content: Dictionary = SpotLabelModel.describe(_ctx, CASTLE, 0)
	assert_eq(content["picks"], PICKS_LINE, "the model says the same")
	assert_eq(content["status_line"], "Max tier", "and the castle is at the top")
