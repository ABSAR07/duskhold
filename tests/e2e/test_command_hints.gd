extends GutTest
## UI-01 / KING-04 (plan 03-10): the command hint strip. On the real scene (squad fixture) it is
## hidden until a squad is selected, then lists Follow, Hold, Rally, Move, Attack, Patrol and Queue
## left to right with the glyph of each action on the device in use (the pad point verbs as LB +
## D-pad pairs), and it yields the shared slot to a toast or an armed line. Its row is laid out in a
## 1280x720 SubViewport: y 504..536, 8 px above the squad strip, below the protected centre.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const HUD_SCENE := "res://ui/hud/hud.tscn"
const BARRACKS: StringName = &"barracks_1"
const ARCHERY: StringName = &"archery_1"
const WORDS: Array[String] = ["Follow", "Hold", "Rally", "Move", "Attack", "Patrol", "Queue"]
const BASE_SIZE := Vector2i(1280, 720)
const PROTECTED_RECT := Rect2(384.0, 96.0, 512.0, 404.0)
const SLOT_TOP: float = 504.0
const SLOT_BOTTOM: float = 536.0
const STRIP_TOP: float = 544.0
const CENTRE_X: float = 640.0
const CENTRE_TOLERANCE_PX: float = 1.0
const KEYBOARD_ROW_MAX_WIDTH: float = 700.0
const SETTLE_FRAMES: int = 3
const RAISE_TIMEOUT_S: float = 2.0
const TOAST_WAIT_S: float = 4.0

var _map: MapRoot
var _ctx: RunContext
var _selection: SelectionModel
var _hints: CommandHints
var _toast: Toast
var _tracker: LastDeviceTracker
var _now: float = 1.0


func after_each() -> void:
	E2eSupport.release_all_actions()


func _spawn(build: bool) -> void:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	_map = scene.instantiate()
	_map.map_config = load(FIXTURE)
	_map.fixed_run_seed = 1
	_map.handle_results_actions = false
	add_child_autofree(_map)
	await wait_process_frames(SETTLE_FRAMES)
	_ctx = _map.get_context()
	if build:
		var views: UnitViews = _map.get_node("UnitViews")
		assert_eq(_ctx.commands.submit(BuildIntent.new(BARRACKS)), CommandProcessor.OK, "barracks")
		assert_eq(_ctx.commands.submit(BuildIntent.new(ARCHERY)), CommandProcessor.OK, "range")
		var raised: Callable = func() -> bool: return views.view_count() == 8
		assert_true(await E2eSupport.wait_until(self, raised, RAISE_TIMEOUT_S), "eight puppets")
	_selection = _map.get_selection()
	_hints = _map.find_child("CommandHints", true, false) as CommandHints
	_toast = _map.find_child("Toast", true, false) as Toast
	_tracker = _map.get_device_tracker()
	_tracker.time_source = func() -> float: return _now
	assert_not_null(_hints, "the HUD has the command hints")
	assert_not_null(_toast, "the HUD has a toast")


func _select_all() -> void:
	_selection.select_all(_ctx.squads.squad_ids())
	await wait_process_frames(2)


func _touch_pad() -> void:
	_now += 1.0
	var button: InputEventJoypadButton = InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_LEFT_STICK
	button.pressed = true
	Input.parse_input_event(button.duplicate())
	Input.flush_buffered_events()
	button.pressed = false
	Input.parse_input_event(button.duplicate())
	Input.flush_buffered_events()


func _glyph(word: String, part: String = "Key") -> PromptGlyph:
	return _hints.get_item(word).get_node(part) as PromptGlyph


## A HUD alone in a 1280x720 viewport whose hints are shown for a made-up selection.
func _hud_in_base_viewport(selected: bool) -> Hud:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = BASE_SIZE
	add_child_autofree(viewport)
	var hud: Hud = (load(HUD_SCENE) as PackedScene).instantiate()
	viewport.add_child(hud)
	var hints: CommandHints = hud.find_child("CommandHints", true, false) as CommandHints
	var model: SelectionModel = SelectionModel.new()
	var ids: Array[StringName] = [BARRACKS, ARCHERY]
	if selected:
		model.select_all(ids)
	hints.set_selection(model)
	await wait_process_frames(SETTLE_FRAMES)
	return hud


func test_with_no_squad_built_the_hints_and_the_strip_are_hidden_and_show_no_placeholder() -> void:
	await _spawn(false)
	await wait_process_frames(SETTLE_FRAMES)
	var strip: SquadStrip = _map.find_child("SquadStrip", true, false) as SquadStrip
	assert_false(_hints.visible, "no hints without a squad")
	assert_eq(_hints.visible_item_count(), 0, "no items")
	assert_false(strip.visible, "no squad strip either")
	for label: Label in _hints.find_children("*", "Label", true, false):
		assert_false(label.is_visible_in_tree(), "no placeholder text: %s" % label.text)


func test_with_squads_built_but_nothing_selected_the_hints_stay_hidden() -> void:
	await _spawn(true)
	await wait_process_frames(SETTLE_FRAMES)
	assert_true((_map.find_child("SquadStrip", true, false) as SquadStrip).visible, "strip shows")
	assert_eq(_selection.selected().size(), 0, "nothing selected")
	assert_false(_hints.visible, "the hints wait for a selection")
	assert_eq(_hints.visible_item_count(), 0, "no items")


func test_a_selected_squad_shows_the_seven_verbs_in_order_with_keyboard_glyphs() -> void:
	await _spawn(true)
	await _select_all()
	assert_true(_hints.visible, "the hints show")
	assert_eq(_hints.visible_item_count(), 7, "seven items")
	assert_eq(_hints.item_words(), WORDS, "in reading order")
	var expected: Dictionary = {
		"Follow": "keyboard_f",
		"Hold": "keyboard_h",
		"Rally": "keyboard_r",
		"Move": "mouse_right",
		"Attack": "keyboard_a",
		"Patrol": "keyboard_p",
		"Queue": "keyboard_shift",
	}
	var last_x: float = -1.0
	for word: String in WORDS:
		assert_eq(_glyph(word).shown_text(), expected[word], "the glyph of %s" % word)
		var left: float = _hints.get_item(word).get_global_rect().position.x
		assert_gt(left, last_x, "%s sits right of the one before" % word)
		last_x = left
	for word: String in ["Move", "Attack", "Patrol"]:
		assert_false(_glyph(word, "Layer").visible, "no layer glyph on the keyboard: %s" % word)
		assert_false(_hints.get_item(word).get_node("Plus").visible, "and no plus: %s" % word)


func test_on_the_pad_the_point_verbs_show_lb_plus_the_d_pad() -> void:
	await _spawn(true)
	await _select_all()
	_touch_pad()
	await wait_process_frames(2)
	var expected: Dictionary = {
		"Follow": "xbox_dpad_up",
		"Hold": "xbox_dpad_down",
		"Rally": "xbox_dpad_left",
		"Move": "xbox_dpad_up",
		"Attack": "xbox_dpad_right",
		"Patrol": "xbox_dpad_down",
		"Queue": "xbox_rt",
	}
	assert_eq(_hints.item_words(), WORDS, "the same order on the pad")
	for word: String in WORDS:
		assert_eq(_glyph(word).shown_text(), expected[word], "the glyph of %s" % word)
	for word: String in ["Move", "Attack", "Patrol"]:
		var layer: PromptGlyph = _glyph(word, "Layer")
		var plus: Label = _hints.get_item(word).get_node("Plus") as Label
		assert_true(layer.visible, "the layer glyph shows: %s" % word)
		assert_eq(layer.shown_text(), "xbox_lb", "LB: %s" % word)
		assert_true(plus.visible, "joined by a plus: %s" % word)
		assert_eq(plus.text, "+", "the plus text: %s" % word)
		assert_lt(layer.get_global_rect().position.x, plus.get_global_rect().position.x, "LB first")
		assert_lt(plus.get_global_rect().position.x, _glyph(word).get_global_rect().position.x, "+")


func test_deselecting_hides_the_hints() -> void:
	await _spawn(true)
	await _select_all()
	assert_eq(_hints.visible_item_count(), 7, "shown")
	_selection.clear()
	await wait_process_frames(2)
	assert_false(_hints.visible, "hidden once nothing is selected")
	assert_eq(_hints.visible_item_count(), 0, "no items")


func test_a_toast_takes_the_slot_and_the_hints_return_when_it_ends() -> void:
	await _spawn(true)
	await _select_all()
	_toast.show_toast("Hello")
	await wait_process_frames(2)
	assert_false(_hints.visible, "the hints yield to the toast")
	assert_eq(_toast.current_text(), "Hello", "the toast is showing")
	assert_true(_toast.is_occupied(), "and holds the slot")
	var back: Callable = func() -> bool: return _hints.visible
	assert_true(await E2eSupport.wait_until(self, back, TOAST_WAIT_S), "the hints come back")
	assert_false(_toast.is_occupied(), "the slot is free again")
	assert_eq(_hints.visible_item_count(), 7, "all seven items")


func test_an_armed_line_replaces_the_hints_until_it_is_cleared() -> void:
	await _spawn(true)
	await _select_all()
	Input.action_press(&"squad_attack_move")
	await wait_process_frames(2)
	Input.action_release(&"squad_attack_move")
	await wait_process_frames(2)
	assert_eq(_toast.current_text(), Toast.ARMED_ATTACK, "the armed line shows")
	assert_true(_toast.is_occupied(), "and holds the slot")
	assert_false(_hints.visible, "the hints give way")
	_toast.clear_line()
	await wait_process_frames(2)
	assert_false(_toast.is_occupied(), "the line is gone")
	assert_true(_hints.visible, "and the hints return")


func test_a_second_toast_replaces_the_first_in_the_same_slot_while_the_hints_stay_hidden() -> void:
	await _spawn(true)
	await _select_all()
	_toast.show_toast("First")
	await wait_process_frames(2)
	_toast.show_toast("Second")
	await wait_process_frames(2)
	assert_eq(_toast.current_text(), "Second", "the newer toast replaced the first")
	assert_false(_hints.visible, "the hints stay hidden")
	assert_eq(_toast.offset_top, _hints.offset_top, "the same slot, top")
	assert_eq(_toast.offset_bottom, _hints.offset_bottom, "the same slot, bottom")


func test_the_row_sits_in_the_toast_slot_8_px_above_the_squad_strip() -> void:
	var hud: Hud = await _hud_in_base_viewport(true)
	var hints: CommandHints = hud.find_child("CommandHints", true, false) as CommandHints
	var strip: Control = hud.find_child("SquadStrip", true, false) as Control
	var king: Control = hud.find_child("KingWidget", true, false) as Control
	var rect: Rect2 = hints.get_global_rect()
	assert_true(hints.visible, "the hints show for a selection")
	assert_almost_eq(rect.position.y, SLOT_TOP, 0.5, "the row starts at y 504")
	assert_almost_eq(rect.end.y, SLOT_BOTTOM, 0.5, "and ends at y 536")
	assert_almost_eq(rect.get_center().x, CENTRE_X, CENTRE_TOLERANCE_PX, "centred")
	assert_false(rect.intersects(PROTECTED_RECT), "below the protected centre")
	assert_almost_eq(BASE_SIZE.y + strip.offset_top, STRIP_TOP, 0.5, "the strip starts at y 544")
	assert_almost_eq(STRIP_TOP - rect.end.y, 8.0, 0.5, "8 px above the strip")
	var king_rect: Rect2 = king.get_global_rect()
	for node: Node in king.find_children("*", "Control", true, false):
		king_rect = king_rect.merge((node as Control).get_global_rect())
	assert_false(rect.intersects(king_rect), "clear of the king widget")
	assert_lt(rect.size.x, KEYBOARD_ROW_MAX_WIDTH, "the seven items fit in about 610 px")
	for item_index: int in range(hints.get_child_count()):
		var item: Control = hints.get_child(item_index) as Control
		assert_true(rect.encloses(item.get_global_rect()), "item %d inside the row" % item_index)


func test_an_empty_selection_leaves_the_row_hidden_in_the_base_viewport() -> void:
	var hud: Hud = await _hud_in_base_viewport(false)
	var hints: CommandHints = hud.find_child("CommandHints", true, false) as CommandHints
	assert_false(hints.visible, "hidden")
	assert_eq(hints.visible_item_count(), 0, "no items")
	assert_eq(hints.mouse_filter, Control.MOUSE_FILTER_IGNORE, "it never takes the mouse")
