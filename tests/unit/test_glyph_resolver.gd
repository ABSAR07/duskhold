extends GutTest
## INPT-02, D-24: GlyphResolver turns an action and a device into the Kenney tile of its first
## binding on that device, or a readable keycap text when the pack has no tile for it. Keys go
## through the layout label resolver (a stand-in here, because headless Godot cannot switch layout).

const KEYS := GlyphResolver.TILE_ROOT + "/keyboard_mouse/"
const PAD := GlyphResolver.TILE_ROOT + "/xbox/"
const KEYBOARD: int = GlyphResolver.DEVICE_KEYBOARD
const PAD_DEVICE: int = GlyphResolver.DEVICE_PAD
const MIN_ACTIONS_CHECKED: int = 40

var _identity: Callable = func(physical: int) -> int: return physical


func _key(physical: Key) -> InputEventKey:
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = physical
	return key


func _tile(action: StringName, device: int) -> String:
	return GlyphResolver.tile_path(GlyphResolver.first_event(action, device), _identity)


func test_every_gameplay_action_resolves_to_an_existing_tile_or_a_keycap() -> void:
	var checked: int = 0
	for action: StringName in InputMap.get_actions():
		if String(action).begins_with("ui_"):
			continue
		var bound_somewhere: bool = false
		for device: int in [KEYBOARD, PAD_DEVICE]:
			var event: InputEvent = GlyphResolver.first_event(action, device)
			if event == null:
				continue
			bound_somewhere = true
			var path: String = GlyphResolver.tile_path(event, _identity)
			if path != "":
				assert_true(
					ResourceLoader.exists(path), "%s device %d tile exists" % [action, device]
				)
			var text: String = GlyphResolver.keycap_text(event, _identity)
			assert_false(text.is_empty(), "%s device %d has keycap text" % [action, device])
			assert_ne(text, GlyphResolver.UNBOUND_TEXT, "%s device %d is bound" % [action, device])
		assert_true(bound_somewhere, "%s is bound on at least one device" % action)
		checked += 1
	assert_gte(checked, MIN_ACTIONS_CHECKED, "the whole action table was walked")


func test_the_shipped_keyboard_and_pad_bindings_all_have_a_tile() -> void:
	# A shipped binding with no tile would fall back to a keycap and hide a verb's real glyph.
	for action: StringName in InputMap.get_actions():
		if String(action).begins_with("ui_"):
			continue
		for device: int in [KEYBOARD, PAD_DEVICE]:
			var event: InputEvent = GlyphResolver.first_event(action, device)
			if event != null:
				assert_ne(
					GlyphResolver.tile_path(event, _identity),
					"",
					"%s device %d has a tile" % [action, device]
				)


func test_a_key_maps_to_its_keyboard_tile() -> void:
	assert_eq(_tile(&"ability", KEYBOARD), KEYS + "keyboard_q.png", "Q")
	assert_eq(_tile(&"start_night", KEYBOARD), KEYS + "keyboard_n.png", "N")
	assert_eq(_tile(&"squad_cycle", KEYBOARD), KEYS + "keyboard_tab.png", "Tab")
	assert_eq(_tile(&"command_cancel", KEYBOARD), KEYS + "keyboard_escape.png", "Escape")
	assert_eq(_tile(&"sprint", KEYBOARD), KEYS + "keyboard_shift.png", "Shift")
	assert_eq(_tile(&"selection_modifier", KEYBOARD), KEYS + "keyboard_ctrl.png", "Ctrl")
	assert_eq(_tile(&"toggle_debug_overlay", KEYBOARD), KEYS + "keyboard_f3.png", "F3")
	assert_eq(_tile(&"select_all", KEYBOARD), KEYS + "keyboard_f2.png", "F2")
	assert_eq(_tile(&"group_3", KEYBOARD), KEYS + "keyboard_3.png", "digit 3")
	assert_eq(_tile(&"zoom_in", KEYBOARD), KEYS + "keyboard_equals.png", "equals")
	assert_eq(_tile(&"zoom_out", KEYBOARD), KEYS + "keyboard_minus.png", "minus")


func test_the_mouse_buttons_map_to_the_mouse_tiles() -> void:
	assert_eq(_tile(&"squad_move", KEYBOARD), KEYS + "mouse_right.png", "right button")
	var left: InputEventMouseButton = InputEventMouseButton.new()
	left.button_index = MOUSE_BUTTON_LEFT
	assert_eq(GlyphResolver.tile_path(left, _identity), KEYS + "mouse_left.png", "left button")


func test_pad_buttons_map_to_the_xbox_tiles() -> void:
	assert_eq(_tile(&"ability", PAD_DEVICE), PAD + "xbox_button_x.png", "X")
	assert_eq(_tile(&"start_night", PAD_DEVICE), PAD + "xbox_button_y.png", "Y")
	assert_eq(_tile(&"action_build", PAD_DEVICE), PAD + "xbox_button_a.png", "A")
	assert_eq(_tile(&"command_cancel", PAD_DEVICE), PAD + "xbox_button_b.png", "B")
	assert_eq(_tile(&"command_layer", PAD_DEVICE), PAD + "xbox_lb.png", "LB")
	assert_eq(_tile(&"sprint", PAD_DEVICE), PAD + "xbox_rb.png", "RB")
	assert_eq(_tile(&"group_mode", PAD_DEVICE), PAD + "xbox_button_start.png", "Start")
	assert_eq(_tile(&"toggle_debug_overlay", PAD_DEVICE), PAD + "xbox_button_back.png", "Back")
	assert_eq(_tile(&"select_type", PAD_DEVICE), PAD + "xbox_stick_r_press.png", "R3")


func test_the_d_pad_buttons_map_to_the_four_d_pad_tiles() -> void:
	assert_eq(_tile(&"squad_follow", PAD_DEVICE), PAD + "xbox_dpad_up.png", "up")
	assert_eq(_tile(&"squad_hold", PAD_DEVICE), PAD + "xbox_dpad_down.png", "down")
	assert_eq(_tile(&"squad_rally", PAD_DEVICE), PAD + "xbox_dpad_left.png", "left")
	assert_eq(_tile(&"squad_cycle", PAD_DEVICE), PAD + "xbox_dpad_right.png", "right")


func test_the_triggers_and_sticks_map_to_their_tiles() -> void:
	assert_eq(_tile(&"command_queue", PAD_DEVICE), PAD + "xbox_rt.png", "right trigger")
	assert_eq(_tile(&"fast_forward", PAD_DEVICE), PAD + "xbox_lt.png", "left trigger")
	assert_eq(_tile(&"move_left", PAD_DEVICE), PAD + "xbox_ls.png", "left stick")
	assert_eq(_tile(&"move_back", PAD_DEVICE), PAD + "xbox_ls.png", "left stick, other axis")
	assert_eq(_tile(&"cursor_right", PAD_DEVICE), PAD + "xbox_rs.png", "right stick")
	assert_eq(_tile(&"cursor_up", PAD_DEVICE), PAD + "xbox_rs.png", "right stick, other axis")


func test_a_layout_label_resolver_picks_the_tile_by_the_cap_label_not_the_qwerty_position() -> void:
	# AZERTY prints A where QWERTY has Q.
	var azerty: Callable = func(physical: int) -> int:
		return KEY_A if physical == KEY_Q else physical
	var event: InputEvent = GlyphResolver.first_event(&"ability", KEYBOARD)
	assert_eq(GlyphResolver.tile_path(event, azerty), KEYS + "keyboard_a.png", "tile")
	assert_eq(GlyphResolver.keycap_text(event, azerty), "A", "keycap text")


func test_an_action_with_no_binding_on_a_device_is_unbound_there() -> void:
	assert_null(GlyphResolver.first_event(&"select_type", KEYBOARD), "R3 has no keyboard key")
	assert_eq(
		GlyphResolver.keycap_text(null, _identity), GlyphResolver.UNBOUND_TEXT, "unbound text"
	)
	assert_eq(GlyphResolver.tile_path(null, _identity), "", "and no tile")
	assert_null(GlyphResolver.first_event(&"cursor_left", KEYBOARD), "a pad-only action")
	assert_null(GlyphResolver.first_event(&"no_such_action", KEYBOARD), "an unknown action")
	assert_not_null(GlyphResolver.first_event(&"squad_move", KEYBOARD), "a bound one is found")


func test_a_key_the_pack_has_no_tile_for_falls_back_to_a_text_keycap() -> void:
	var minus: InputEventKey = _key(KEY_KP_SUBTRACT)
	assert_eq(GlyphResolver.tile_path(minus, _identity), "", "no keypad minus tile")
	var text: String = GlyphResolver.keycap_text(minus, _identity)
	assert_false(text.is_empty(), "but a readable text")
	assert_ne(text, GlyphResolver.UNBOUND_TEXT, "which is not the unbound text")
	var backspace: InputEventKey = _key(KEY_BACKSPACE)
	assert_eq(GlyphResolver.tile_path(backspace, _identity), "", "no backspace tile")
	assert_eq(GlyphResolver.keycap_text(backspace, _identity), "Backspace", "long key name")


func test_a_key_chord_has_no_single_tile_and_reads_with_its_modifier() -> void:
	var chord: InputEventKey = _key(KEY_N)
	chord.ctrl_pressed = true
	assert_eq(GlyphResolver.tile_path(chord, _identity), "", "a chord is a keycap")
	assert_eq(GlyphResolver.keycap_text(chord, _identity), "Ctrl+N", "modifier kept")


func test_a_blank_key_event_reads_as_unbound() -> void:
	assert_eq(
		GlyphResolver.keycap_text(InputEventKey.new(), _identity),
		GlyphResolver.UNBOUND_TEXT,
		"a key event that names no key"
	)


func test_buttons_and_axes_without_a_tile_get_their_names() -> void:
	var middle: InputEventMouseButton = InputEventMouseButton.new()
	middle.button_index = MOUSE_BUTTON_MIDDLE
	assert_eq(GlyphResolver.tile_path(middle, _identity), "", "no middle button tile")
	assert_eq(GlyphResolver.keycap_text(middle, _identity), middle.as_text(), "named")
	var l3: InputEventJoypadButton = InputEventJoypadButton.new()
	l3.button_index = JOY_BUTTON_LEFT_STICK
	assert_eq(GlyphResolver.tile_path(l3, _identity), "", "no left stick press tile")
	assert_eq(GlyphResolver.keycap_text(l3, _identity), "L3", "named")
	var trigger: InputEventJoypadMotion = InputEventJoypadMotion.new()
	trigger.axis = JOY_AXIS_TRIGGER_RIGHT
	trigger.axis_value = 1.0
	assert_eq(GlyphResolver.keycap_text(trigger, _identity), "RT", "trigger name")
	var left: InputEventJoypadMotion = InputEventJoypadMotion.new()
	left.axis = JOY_AXIS_LEFT_X
	left.axis_value = -1.0
	var right: InputEventJoypadMotion = InputEventJoypadMotion.new()
	right.axis = JOY_AXIS_LEFT_X
	right.axis_value = 1.0
	assert_ne(
		GlyphResolver.keycap_text(left, _identity),
		GlyphResolver.keycap_text(right, _identity),
		"the two ways to push one stick axis read differently"
	)
