extends GutTest
## D-05 modal rule, Pitfall 6: while the cards show, the digit keys 1 to 4 pick cards and recall no
## control group; after leaving range, or while the castle is unaffordable (no cards), they recall
## control groups again; 5 to 9 and 0 keep their control-group meaning throughout. One key press
## does exactly one thing. Real prototype scene, scripted presses (the same just-pressed edge and
## scripted-press fallback CommandKeyController and CardPicker use).

const CASTLE: StringName = &"castle_plot"
const BARRACKS: StringName = &"barracks_1"
const SETTLE_FRAMES: int = 3
const SQUAD_TIMEOUT_S: float = 2.0
const GRANTED_GOLD: int = 40
const FAR_AWAY := Vector3(40.0, 0.0, 40.0)

var _map: MapRoot
var _ctx: RunContext
var _picker: CardPicker
var _selection: SelectionModel


## The real scene with the Barracks bought, its squad stored in groups 2 and 5 and the selection
## cleared. `rich` grants the gold for the castle's tier II, else the Barracks takes it all.
func _setup(rich: bool) -> void:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	_map = scene.instantiate()
	_map.map_config = E2eSupport.waveless_prototype_map()
	_map.fixed_run_seed = 1
	_map.handle_results_actions = false
	add_child_autofree(_map)
	await wait_process_frames(SETTLE_FRAMES)
	_ctx = _map.get_context()
	_picker = _map.get_cards()
	_selection = _map.get_selection()
	assert_eq(_ctx.commands.submit(BuildIntent.new(BARRACKS)), CommandProcessor.OK, "barracks")
	var raised: Callable = func() -> bool: return _ctx.squads.squad_ids().has(BARRACKS)
	assert_true(await E2eSupport.wait_until(self, raised, SQUAD_TIMEOUT_S), "the squad exists")
	_selection.select_only([BARRACKS] as Array[StringName], _ctx.squads.squad_ids())
	assert_true(_selection.store_group(2), "stored in group 2")
	assert_true(_selection.store_group(5), "stored in group 5")
	_selection.clear()
	if rich:
		_ctx.economy.grant(GRANTED_GOLD)
	else:
		assert_eq(_ctx.economy.get_gold(), 0, "the Barracks took every coin")


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await wait_process_frames(2)
	Input.action_release(action)
	await wait_process_frames(2)


func _at_the_castle() -> void:
	assert_true(await E2eSupport.stand_at_spot(self, _map, CASTLE), "at the castle plot")
	await wait_process_frames(2)


func after_each() -> void:
	E2eSupport.release_all_actions()


func test_a_digit_picks_a_card_and_recalls_no_group_while_the_cards_show() -> void:
	await _setup(true)
	await _at_the_castle()
	assert_true(_picker.is_showing(), "the cards show")
	watch_signals(_selection)
	await _tap(&"group_2")
	assert_eq(_picker.highlighted_index(), 1, "key 2 highlighted card 2")
	assert_signal_not_emitted(_selection, "group_recalled", "and recalled no group")
	assert_true(_selection.selected().is_empty(), "the selection is still empty")


func test_a_group_five_press_still_recalls_group_five_while_the_cards_show() -> void:
	await _setup(true)
	await _at_the_castle()
	assert_true(_picker.is_showing(), "the cards show")
	watch_signals(_selection)
	await _tap(&"group_5")
	assert_signal_emitted_with_parameters(_selection, "group_recalled", [5])
	assert_eq(_selection.selected(), [BARRACKS] as Array[StringName], "the squad is selected")
	assert_eq(_picker.highlighted_index(), -1, "and no card moved")


func test_ctrl_and_a_digit_stores_no_group_while_the_cards_show() -> void:
	await _setup(true)
	_selection.select_only([BARRACKS] as Array[StringName], _ctx.squads.squad_ids())
	await _at_the_castle()
	Input.action_press(&"selection_modifier")
	await wait_process_frames(1)
	await _tap(&"group_3")
	Input.action_release(&"selection_modifier")
	assert_eq(_picker.highlighted_index(), 2, "Ctrl + 3 still picks card 3")
	assert_true(_selection.group_members(3).is_empty(), "and stores nothing in group 3")


func test_after_leaving_range_the_same_digit_recalls_the_group_again() -> void:
	await _setup(true)
	await _at_the_castle()
	E2eSupport.teleport_king(_map, FAR_AWAY)
	await wait_process_frames(3)
	assert_false(_picker.is_showing(), "the cards are gone")
	watch_signals(_selection)
	await _tap(&"group_2")
	assert_signal_emitted_with_parameters(_selection, "group_recalled", [2])
	assert_eq(_selection.selected(), [BARRACKS] as Array[StringName], "the stored squad")


func test_while_the_castle_is_unaffordable_the_digit_recalls_the_group() -> void:
	await _setup(false)
	await _at_the_castle()
	assert_false(_picker.is_showing(), "no cards without the gold")
	watch_signals(_selection)
	await _tap(&"group_2")
	assert_signal_emitted_with_parameters(_selection, "group_recalled", [2])
	assert_eq(_selection.selected(), [BARRACKS] as Array[StringName], "the stored squad")


func test_key_zero_still_recalls_its_group_while_the_cards_show() -> void:
	await _setup(true)
	_selection.select_only([BARRACKS] as Array[StringName], _ctx.squads.squad_ids())
	assert_true(_selection.store_group(10), "stored in group 10 (key 0)")
	_selection.clear()
	await _at_the_castle()
	watch_signals(_selection)
	await _tap(&"group_0")
	assert_signal_emitted_with_parameters(_selection, "group_recalled", [10])
