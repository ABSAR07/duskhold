extends GutTest
## INPT-02 / D-24 on the real scene (squad fixture, both squads built and selected): touching the
## pad makes every on-screen prompt (the start-night glyph, the slam badge and the command hints)
## show pad tiles in the same frame, and touching the keyboard or mouse switches them all back. The
## tracker runs on a hand-stepped clock so the 0.25 s debounce is stepped, not waited for. Events
## go through Input.parse_input_event and are flushed, so they reach the tracker exactly as real
## ones do. The mouse cursor itself cannot be read back under the headless display server (its
## mouse mode is not stored), so the test reads the hidden flag the tracker asked for; the real
## window is checked on a screenshot scenario.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const BARRACKS: StringName = &"barracks_1"
const ARCHERY: StringName = &"archery_1"
const SETTLE_FRAMES: int = 3
const RAISE_TIMEOUT_S: float = 2.0
const KEYBOARD: int = GlyphResolver.DEVICE_KEYBOARD
const PAD: int = GlyphResolver.DEVICE_PAD

var _map: MapRoot
var _tracker: LastDeviceTracker
var _hints: CommandHints
var _widget: KingWidget
var _now: float = 1.0


func after_each() -> void:
	E2eSupport.release_all_actions()


func _setup() -> void:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	_map = scene.instantiate()
	_map.map_config = load(FIXTURE)
	_map.fixed_run_seed = 1
	_map.handle_results_actions = false
	add_child_autofree(_map)
	await wait_process_frames(SETTLE_FRAMES)
	var ctx: RunContext = _map.get_context()
	var views: UnitViews = _map.get_node("UnitViews")
	assert_eq(ctx.commands.submit(BuildIntent.new(BARRACKS)), CommandProcessor.OK, "barracks")
	assert_eq(ctx.commands.submit(BuildIntent.new(ARCHERY)), CommandProcessor.OK, "range")
	var raised: Callable = func() -> bool: return views.view_count() == 8
	assert_true(await E2eSupport.wait_until(self, raised, RAISE_TIMEOUT_S), "eight puppets")
	_map.get_selection().select_all(ctx.squads.squad_ids())
	await wait_process_frames(SETTLE_FRAMES)
	_tracker = _map.get_device_tracker()
	assert_not_null(_tracker, "the map has a device tracker")
	_tracker.time_source = func() -> float: return _now
	_hints = _map.find_child("CommandHints", true, false) as CommandHints
	_widget = _map.find_child("KingWidget", true, false) as KingWidget


func _send(event: InputEvent) -> void:
	Input.parse_input_event(event.duplicate())
	Input.flush_buffered_events()


## Presses and releases an unbound pad button one second of tracker time after the last touch.
func _touch_pad() -> void:
	_now += 1.0
	var button: InputEventJoypadButton = InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_LEFT_STICK
	button.pressed = true
	_send(button)
	button.pressed = false
	_send(button)


## Presses and releases an unbound key one second of tracker time after the last touch.
func _touch_keyboard() -> void:
	_now += 1.0
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_F12
	key.keycode = KEY_F12
	key.pressed = true
	_send(key)
	key.pressed = false
	_send(key)


func _start_night_glyph() -> PromptGlyph:
	return _map.get_node("HUD").get_node("%StartNightGlyph") as PromptGlyph


func _hint_glyph(word: String, part: String = "Key") -> PromptGlyph:
	return _hints.get_item(word).get_node(part) as PromptGlyph


func test_the_tracker_starts_on_the_keyboard_and_every_prompt_shows_keyboard_glyphs() -> void:
	await _setup()
	assert_eq(_tracker.device(), KEYBOARD, "starts on keyboard")
	assert_false(_tracker.cursor_hidden(), "the cursor is shown")
	assert_eq(_start_night_glyph().shown_text(), "keyboard_n", "start night")
	assert_eq(_widget.get_ability_glyph().shown_text(), "keyboard_q", "the slam badge")
	assert_eq(_hint_glyph("Follow").shown_text(), "keyboard_f", "follow")
	assert_eq(_hint_glyph("Move").shown_text(), "mouse_right", "move")


func test_a_pad_button_switches_every_prompt_to_pad_tiles_in_the_same_frame() -> void:
	await _setup()
	_touch_pad()
	# No frame has passed since the press: the one signal switched them all.
	assert_eq(_tracker.device(), PAD, "now the pad")
	assert_true(_tracker.cursor_hidden(), "the cursor hides while the pad is active")
	assert_eq(_start_night_glyph().shown_text(), "xbox_button_y", "start night")
	assert_eq(_widget.get_ability_glyph().shown_text(), "xbox_button_x", "the slam badge")
	assert_eq(_hint_glyph("Follow").shown_text(), "xbox_dpad_up", "follow")
	assert_eq(_hint_glyph("Hold").shown_text(), "xbox_dpad_down", "hold")
	assert_eq(_hint_glyph("Rally").shown_text(), "xbox_dpad_left", "rally")
	assert_eq(_hint_glyph("Move").shown_text(), "xbox_dpad_up", "move, behind the layer glyph")
	assert_eq(_hint_glyph("Move", "Layer").shown_text(), "xbox_lb", "the layer glyph")
	assert_eq(_hint_glyph("Queue").shown_text(), "xbox_rt", "queue")


func test_a_key_press_switches_every_prompt_back_and_shows_the_cursor() -> void:
	await _setup()
	_touch_pad()
	_touch_keyboard()
	assert_eq(_tracker.device(), KEYBOARD, "back on the keyboard")
	assert_false(_tracker.cursor_hidden(), "the cursor is back")
	assert_eq(_start_night_glyph().shown_text(), "keyboard_n", "start night")
	assert_eq(_widget.get_ability_glyph().shown_text(), "keyboard_q", "the slam badge")
	assert_eq(_hint_glyph("Hold").shown_text(), "keyboard_h", "hold")
	assert_eq(_hint_glyph("Queue").shown_text(), "keyboard_shift", "queue")


func test_mouse_input_counts_as_the_keyboard() -> void:
	await _setup()
	_touch_pad()
	_now += 1.0
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.relative = Vector2(20.0, 0.0)
	motion.position = Vector2(100.0, 100.0)
	_send(motion)
	assert_eq(_tracker.device(), KEYBOARD, "moving the mouse switches back")
	assert_eq(_start_night_glyph().shown_text(), "keyboard_n", "and the prompts follow")
	_touch_pad()
	_now += 1.0
	var middle: InputEventMouseButton = InputEventMouseButton.new()
	middle.button_index = MOUSE_BUTTON_MIDDLE
	middle.pressed = true
	_send(middle)
	middle.pressed = false
	_send(middle)
	assert_eq(_tracker.device(), KEYBOARD, "so does a mouse button")


func test_a_second_switch_inside_a_quarter_second_is_ignored() -> void:
	await _setup()
	_touch_pad()
	_now += 0.1
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_F12
	key.pressed = true
	_send(key)
	assert_eq(_tracker.device(), PAD, "the pad stays inside the debounce")
	assert_eq(_start_night_glyph().shown_text(), "xbox_button_y", "and so do the prompts")
	_now += 0.15
	_send(key)
	assert_eq(_tracker.device(), KEYBOARD, "at 0.25 s the switch applies")


func test_the_pad_disconnecting_falls_back_to_the_keyboard() -> void:
	await _setup()
	_touch_pad()
	Input.joy_connection_changed.emit(7, false)
	assert_eq(_tracker.device(), PAD, "a different pad leaving changes nothing")
	Input.joy_connection_changed.emit(0, false)
	assert_eq(_tracker.device(), KEYBOARD, "the pad in use leaving falls back")
	assert_false(_tracker.cursor_hidden(), "and the cursor returns")
	assert_eq(_start_night_glyph().shown_text(), "keyboard_n", "with the keyboard prompts")


func test_the_tracker_is_last_in_the_tree_so_it_sees_input_first() -> void:
	await _setup()
	var controller: Node = _map.get_node("SelectionController")
	assert_gt(_tracker.get_index(), controller.get_index(), "after the controllers, first to see")
	assert_true(_tracker.is_in_group(&"run_bound"), "bound to the run")
