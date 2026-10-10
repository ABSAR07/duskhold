extends GutTest
## INPT-02, UNIT-09, UNIT-10, D-12: the squad commands on the gamepad, in the real scene on the
## squad fixture, both squads built. Pad events go through Input.parse_input_event as
## InputEventJoypadButton, so a D-pad press fires a bare action and its LB twin together, exactly as
## a real pad does, and PadChords picks one. D-pad up follow, down hold, left rally, right cycle;
## LB held turns up / right / down into the move, attack-move and patrol cursor verbs; R3 selects
## all and LB + R3 every squad of the cycled squad's type; holding Start enters group mode, where
## D-pad left / right steps the group number on the selected squad's badge, up recalls it and
## releasing Start stores it. Keyboard keys keep their meaning whatever the pad is holding, and
## using one leaves the selection and the groups alone (switching device mid-run).

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const BARRACKS: StringName = &"barracks_1"
const ARCHERY: StringName = &"archery_1"
const SETTLE_FRAMES: int = 3
const RAISE_TIMEOUT_S: float = 2.0
const STEPS_IN_A_LAP: int = 10

var _map: MapRoot
var _ctx: RunContext
var _selection: SelectionModel
var _toast: Toast
var _strip: SquadStrip
var _keys: CommandKeyController
var _ordered: Array[Array] = []
var _point_verbs: Array[Array] = []


func after_each() -> void:
	Engine.time_scale = 1.0
	E2eSupport.release_all_actions()
	for button: JoyButton in [
		JOY_BUTTON_LEFT_SHOULDER,
		JOY_BUTTON_START,
		JOY_BUTTON_DPAD_UP,
		JOY_BUTTON_DPAD_DOWN,
		JOY_BUTTON_DPAD_LEFT,
		JOY_BUTTON_DPAD_RIGHT,
		JOY_BUTTON_RIGHT_STICK,
	]:
		_pad(button, false)


func _setup() -> void:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	_map = scene.instantiate()
	_map.map_config = load(FIXTURE)
	_map.fixed_run_seed = 1
	_map.handle_results_actions = false
	add_child_autofree(_map)
	await wait_process_frames(SETTLE_FRAMES)
	_ctx = _map.get_context()
	var views: UnitViews = _map.get_node("UnitViews")
	assert_eq(_ctx.commands.submit(BuildIntent.new(BARRACKS)), CommandProcessor.OK, "barracks")
	assert_eq(_ctx.commands.submit(BuildIntent.new(ARCHERY)), CommandProcessor.OK, "range")
	var raised: Callable = func() -> bool: return views.view_count() == 8
	assert_true(await E2eSupport.wait_until(self, raised, RAISE_TIMEOUT_S), "eight puppets")
	_selection = _map.get_selection()
	_toast = _map.find_child("Toast", true, false) as Toast
	_strip = _map.find_child("SquadStrip", true, false) as SquadStrip
	_keys = _map.get_node("CommandKeyController") as CommandKeyController
	assert_not_null(_toast, "the HUD has a Toast")
	assert_not_null(_strip, "the HUD has the squad strip")
	_ordered = []
	_point_verbs = []
	_ctx.events.squad_ordered.connect(
		func(squad_id: StringName, verb: StringName, queued: bool, points: Array) -> void:
			_ordered.append([squad_id, verb, queued, points])
	)
	_keys.pad_point_verb.connect(
		func(verb: StringName, action: StringName) -> void: _point_verbs.append([verb, action])
	)


func _pad(button: JoyButton, pressed: bool) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)


## One press of a pad button: down for two frames, released, two more frames.
func _tap_pad(button: JoyButton) -> void:
	_pad(button, true)
	await wait_process_frames(2)
	_pad(button, false)
	await wait_process_frames(2)


## One press of an action by the keyboard path: down for two frames, released, two more frames.
func _tap_key(action: StringName) -> void:
	Input.action_press(action)
	await wait_process_frames(2)
	Input.action_release(action)
	await wait_process_frames(2)


func _select(ids: Array[StringName]) -> void:
	_selection.select_only(ids, _ctx.squads.squad_ids())


func _selected_is(ids: Array[StringName]) -> bool:
	return _selection.selected() == ids


func _badge_text(squad_id: StringName) -> String:
	var slot: SquadSlot = _strip.slot_for(squad_id)
	return slot.get_badge_label().text if slot.get_badge().visible else ""


func test_d_pad_right_selects_the_barracks_then_the_archery() -> void:
	await _setup()
	await _tap_pad(JOY_BUTTON_DPAD_RIGHT)
	assert_true(_selected_is([BARRACKS] as Array[StringName]), "the first squad")
	await _tap_pad(JOY_BUTTON_DPAD_RIGHT)
	assert_true(_selected_is([ARCHERY] as Array[StringName]), "the next squad")
	assert_eq(_ordered.size(), 0, "cycling orders nothing")
	assert_eq(_point_verbs.size(), 0, "and starts no cursor")


func test_d_pad_down_orders_hold_and_d_pad_up_follow_and_left_rally() -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	await _tap_pad(JOY_BUTTON_DPAD_DOWN)
	assert_eq(_ordered.size(), 1, "one order")
	assert_eq(_ordered[0][1], SquadOrder.VERB_HOLD, "hold")
	await _tap_pad(JOY_BUTTON_DPAD_UP)
	assert_eq(_ordered.size(), 2, "a second order")
	assert_eq(_ordered[1][1], SquadOrder.VERB_FOLLOW, "follow")
	await _tap_pad(JOY_BUTTON_DPAD_LEFT)
	assert_eq(_ordered.size(), 3, "a third order")
	assert_eq(_ordered[2][1], SquadOrder.VERB_RALLY, "rally")
	assert_eq(_point_verbs.size(), 0, "none of them asks for a ground point")


func test_lb_and_d_pad_down_does_not_hold_it_hands_patrol_to_the_cursor() -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	_pad(JOY_BUTTON_LEFT_SHOULDER, true)
	await wait_process_frames(2)
	await _tap_pad(JOY_BUTTON_DPAD_DOWN)
	_pad(JOY_BUTTON_LEFT_SHOULDER, false)
	await wait_process_frames(2)
	assert_eq(_ordered.size(), 1, "the tap is a patrol aimed at the king's feet, not a hold")
	assert_eq(_ordered[0][1], SquadOrder.VERB_PATROL, "patrol")
	assert_eq(_point_verbs.size(), 1, "one point verb")
	assert_eq(_point_verbs[0][0], SquadOrder.VERB_PATROL, "patrol")
	assert_eq(_point_verbs[0][1], &"squad_patrol", "released with the patrol action")


func test_lb_and_d_pad_up_and_right_hand_move_and_attack_move_to_the_cursor() -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	_pad(JOY_BUTTON_LEFT_SHOULDER, true)
	await wait_process_frames(2)
	await _tap_pad(JOY_BUTTON_DPAD_UP)
	await _tap_pad(JOY_BUTTON_DPAD_RIGHT)
	_pad(JOY_BUTTON_LEFT_SHOULDER, false)
	await wait_process_frames(2)
	assert_eq(_ordered.size(), 2, "a move and an attack-move, and no follow")
	assert_eq(_ordered[0][1], SquadOrder.VERB_MOVE, "move")
	assert_eq(_ordered[1][1], SquadOrder.VERB_ATTACK_MOVE, "attack-move")
	assert_true(
		_selected_is([BARRACKS] as Array[StringName]), "no cycle: the selection is untouched"
	)
	assert_eq(_point_verbs.size(), 2, "two point verbs")
	assert_eq(_point_verbs[0][0], SquadOrder.VERB_MOVE, "move")
	assert_eq(_point_verbs[1][0], SquadOrder.VERB_ATTACK_MOVE, "attack-move")


func test_keyboard_keys_keep_their_meaning_whatever_the_pad_is_holding() -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	_pad(JOY_BUTTON_LEFT_SHOULDER, true)
	await wait_process_frames(2)
	await _tap_key(&"squad_follow")
	assert_eq(_ordered.size(), 1, "F with LB held is still follow")
	assert_eq(_ordered[0][1], SquadOrder.VERB_FOLLOW, "follow")
	await _tap_key(&"squad_hold")
	assert_eq(_ordered.size(), 2, "H with LB held is still hold")
	assert_eq(_ordered[1][1], SquadOrder.VERB_HOLD, "hold")
	assert_eq(_point_verbs.size(), 0, "no keyboard key starts the pad cursor")
	_pad(JOY_BUTTON_LEFT_SHOULDER, false)
	await wait_process_frames(2)


func test_the_keyboard_attack_move_key_and_the_right_mouse_action_start_no_pad_cursor() -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	await _tap_key(&"squad_attack_move")
	await _tap_key(&"squad_move")
	assert_eq(_point_verbs.size(), 0, "A and the right button are not pad presses")
	var pointer: SelectionController = _map.get_node("SelectionController") as SelectionController
	assert_true(pointer.is_armed(), "the A key still arms attack-move for the next click")


func test_r3_selects_both_squads_and_lb_r3_selects_the_type_of_the_cycled_squad() -> void:
	await _setup()
	await _tap_pad(JOY_BUTTON_DPAD_RIGHT)
	assert_true(_selected_is([BARRACKS] as Array[StringName]), "the barracks is cycled")
	await _tap_pad(JOY_BUTTON_RIGHT_STICK)
	assert_true(_selected_is([BARRACKS, ARCHERY] as Array[StringName]), "R3 selects both")
	_pad(JOY_BUTTON_LEFT_SHOULDER, true)
	await wait_process_frames(2)
	await _tap_pad(JOY_BUTTON_RIGHT_STICK)
	_pad(JOY_BUTTON_LEFT_SHOULDER, false)
	await wait_process_frames(2)
	assert_true(
		_selected_is([BARRACKS] as Array[StringName]),
		"LB + R3 keeps only the squads of the cycled squad's type"
	)


func test_lb_r3_with_nothing_selected_says_select_a_squad_first() -> void:
	await _setup()
	_pad(JOY_BUTTON_LEFT_SHOULDER, true)
	await wait_process_frames(2)
	await _tap_pad(JOY_BUTTON_RIGHT_STICK)
	_pad(JOY_BUTTON_LEFT_SHOULDER, false)
	await wait_process_frames(2)
	assert_eq(_toast.current_text(), Toast.SELECT_FIRST, "the toast says what to do")
	assert_true(_selection.selected().is_empty(), "and nothing is selected")


func test_start_and_d_pad_right_twice_pulses_digit_two_and_releasing_start_stores_group_two(
) -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	_pad(JOY_BUTTON_START, true)
	await wait_process_frames(2)
	await _tap_pad(JOY_BUTTON_DPAD_RIGHT)
	assert_eq(_badge_text(BARRACKS), "1", "the first step shows 1")
	await _tap_pad(JOY_BUTTON_DPAD_RIGHT)
	var slot: SquadSlot = _strip.slot_for(BARRACKS)
	assert_eq(_badge_text(BARRACKS), "2", "the second step shows 2 on the selected squad's badge")
	assert_true(slot.is_group_editing(), "the badge pulses while the group is being edited")
	var border: Color = slot.badge_border_color()
	assert_eq(Color(border.r, border.g, border.b), Color("#8CEBFF"), "in the accent colour")
	assert_false(_strip.slot_for(ARCHERY).is_group_editing(), "the other badge does not")
	assert_true(_selection.group_members(2).is_empty(), "nothing is stored while Start is held")
	_pad(JOY_BUTTON_START, false)
	await wait_process_frames(2)
	assert_eq(_selection.group_members(2), [BARRACKS] as Array[StringName], "group 2 holds it")
	assert_eq(_toast.current_text(), "Group 2 saved", "the toast says so")
	assert_false(slot.is_group_editing(), "the pulse is gone")
	assert_eq(_badge_text(BARRACKS), "2", "the badge keeps the stored digit")
	assert_true(_selected_is([BARRACKS] as Array[StringName]), "storing keeps the selection")
	assert_eq(_ordered.size(), 0, "stepping the D-pad ordered nothing")


func test_start_and_d_pad_left_steps_back_through_zero_and_the_digits_wrap() -> void:
	await _setup()
	_select([ARCHERY] as Array[StringName])
	_pad(JOY_BUTTON_START, true)
	await wait_process_frames(2)
	await _tap_pad(JOY_BUTTON_DPAD_LEFT)
	assert_eq(_badge_text(ARCHERY), "0", "a step back from nothing wraps to 0")
	assert_eq(_ordered.size(), 0, "D-pad left is ignored as rally while Start is held")
	await _tap_pad(JOY_BUTTON_DPAD_LEFT)
	assert_eq(_badge_text(ARCHERY), "9", "then 9")
	await _tap_pad(JOY_BUTTON_DPAD_RIGHT)
	assert_eq(_badge_text(ARCHERY), "0", "and forward again to 0")
	await _tap_pad(JOY_BUTTON_DPAD_RIGHT)
	assert_eq(_badge_text(ARCHERY), "1", "0 wraps to 1")
	_pad(JOY_BUTTON_START, false)
	await wait_process_frames(2)
	assert_eq(_selection.group_members(1), [ARCHERY] as Array[StringName], "stored as group 1")
	assert_eq(_toast.current_text(), "Group 1 saved", "the toast says so")


func test_stepping_right_ten_times_is_a_lap_ending_on_zero() -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	_pad(JOY_BUTTON_START, true)
	await wait_process_frames(2)
	for step: int in range(STEPS_IN_A_LAP):
		await _tap_pad(JOY_BUTTON_DPAD_RIGHT)
	assert_eq(_badge_text(BARRACKS), "0", "1..9 then 0")
	_pad(JOY_BUTTON_START, false)
	await wait_process_frames(2)
	assert_eq(_selection.group_members(10), [BARRACKS] as Array[StringName], "key 0 is group 10")
	assert_eq(_toast.current_text(), "Group 0 saved", "the toast names the key")


func test_start_and_d_pad_up_recalls_the_shown_group_and_releasing_start_stores_nothing_more(
) -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	_selection.store_group(2)
	_select([ARCHERY] as Array[StringName])
	_pad(JOY_BUTTON_START, true)
	await wait_process_frames(2)
	await _tap_pad(JOY_BUTTON_DPAD_RIGHT)
	await _tap_pad(JOY_BUTTON_DPAD_RIGHT)
	assert_eq(_badge_text(ARCHERY), "2", "group 2 is shown")
	await _tap_pad(JOY_BUTTON_DPAD_UP)
	assert_true(_selected_is([BARRACKS] as Array[StringName]), "the group's squads are selected")
	assert_eq(_ordered.size(), 0, "D-pad up is not follow in group mode")
	_pad(JOY_BUTTON_START, false)
	await wait_process_frames(2)
	assert_eq(_selection.group_members(2), [BARRACKS] as Array[StringName], "group 2 is unchanged")
	assert_ne(_toast.current_text(), "Group 2 saved", "recalling is not saving")
	assert_false(_strip.slot_for(ARCHERY).is_group_editing(), "the pulse is gone")


func test_recalling_an_empty_group_in_group_mode_says_so_and_keeps_the_selection() -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	_pad(JOY_BUTTON_START, true)
	await wait_process_frames(2)
	await _tap_pad(JOY_BUTTON_DPAD_RIGHT)
	await _tap_pad(JOY_BUTTON_DPAD_UP)
	assert_eq(_toast.current_text(), "Group 1 is empty", "the toast says so")
	assert_true(_selected_is([BARRACKS] as Array[StringName]), "the selection is kept")
	_pad(JOY_BUTTON_START, false)
	await wait_process_frames(2)


func test_the_bare_d_pad_verbs_are_silent_while_start_is_held() -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	_pad(JOY_BUTTON_START, true)
	await wait_process_frames(2)
	await _tap_pad(JOY_BUTTON_DPAD_DOWN)
	assert_eq(_ordered.size(), 0, "no hold")
	assert_eq(_point_verbs.size(), 0, "and no cursor")
	_pad(JOY_BUTTON_START, false)
	await wait_process_frames(2)
	assert_true(_selection.group_members(1).is_empty(), "nothing was stepped, so nothing is stored")


func test_start_without_a_step_stores_nothing_and_says_nothing() -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	await _tap_pad(JOY_BUTTON_START)
	for group: int in range(1, 11):
		assert_true(_selection.group_members(group).is_empty(), "group %d is empty" % group)
	assert_eq(_toast.current_text(), "", "no toast")


func test_stepping_group_mode_with_nothing_selected_says_select_a_squad_first() -> void:
	await _setup()
	_pad(JOY_BUTTON_START, true)
	await wait_process_frames(2)
	await _tap_pad(JOY_BUTTON_DPAD_RIGHT)
	assert_eq(_toast.current_text(), Toast.SELECT_FIRST, "the toast says what to do")
	_pad(JOY_BUTTON_START, false)
	await wait_process_frames(2)
	for group: int in range(1, 11):
		assert_true(_selection.group_members(group).is_empty(), "group %d is empty" % group)


func test_using_the_keyboard_after_the_pad_leaves_the_selection_and_the_groups_alone() -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	_pad(JOY_BUTTON_START, true)
	await wait_process_frames(2)
	await _tap_pad(JOY_BUTTON_DPAD_RIGHT)
	_pad(JOY_BUTTON_START, false)
	await wait_process_frames(2)
	assert_eq(_selection.group_members(1), [BARRACKS] as Array[StringName], "stored on the pad")
	await _tap_key(&"squad_hold")
	assert_true(
		_selected_is([BARRACKS] as Array[StringName]), "the keyboard order kept the selection"
	)
	assert_eq(_selection.group_members(1), [BARRACKS] as Array[StringName], "and the group")
	await _tap_pad(JOY_BUTTON_DPAD_UP)
	assert_eq(_ordered.size(), 2, "the pad still works afterwards")
	assert_eq(_ordered[1][1], SquadOrder.VERB_FOLLOW, "follow")
	assert_true(_selected_is([BARRACKS] as Array[StringName]), "with the same selection")
