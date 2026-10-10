extends GutTest
## D-24 / UI-SPEC E7: PromptGlyph shows the tile of an action's binding on the device it is rendered
## for at a fixed 24 or 32 px, and a text keycap when the pack has no tile or the action has no
## binding there. The glyph never scales with text; a long key name widens the keycap only.

const TEMP_ACTION: StringName = &"test_prompt_glyph_temp"
const KEYBOARD: int = GlyphResolver.DEVICE_KEYBOARD
const PAD: int = GlyphResolver.DEVICE_PAD


func after_each() -> void:
	if InputMap.has_action(TEMP_ACTION):
		InputMap.erase_action(TEMP_ACTION)


func _glyph(action: StringName, size: int = 24) -> PromptGlyph:
	var glyph: PromptGlyph = PromptGlyph.new()
	glyph.action = action
	glyph.glyph_size = size
	add_child_autofree(glyph)
	return glyph


func _bind_temp(event: InputEvent) -> void:
	InputMap.add_action(TEMP_ACTION)
	InputMap.action_add_event(TEMP_ACTION, event)


func test_a_bound_action_shows_its_tile_at_the_fixed_size() -> void:
	var glyph: PromptGlyph = _glyph(&"ability")
	glyph.render(KEYBOARD)
	assert_false(glyph.is_keycap(), "a tile, not a keycap")
	assert_eq(glyph.shown_text(), "keyboard_q", "the Q tile")
	assert_eq(glyph.custom_minimum_size, Vector2(24, 24), "24 px square")
	glyph.render(PAD)
	assert_eq(glyph.shown_text(), "xbox_button_x", "the pad tile for the same action")
	assert_eq(glyph.device(), PAD, "and the device it was rendered for")


func test_the_start_night_size_is_32_square() -> void:
	var glyph: PromptGlyph = _glyph(&"start_night", 32)
	glyph.render(PAD)
	assert_eq(glyph.custom_minimum_size, Vector2(32, 32), "32 px square")
	assert_eq(glyph.shown_text(), "xbox_button_y", "the Y tile")


func test_an_action_unbound_on_the_device_shows_the_unbound_keycap() -> void:
	var glyph: PromptGlyph = _glyph(&"select_type")
	glyph.render(KEYBOARD)
	assert_true(glyph.is_keycap(), "a keycap")
	assert_eq(glyph.shown_text(), GlyphResolver.UNBOUND_TEXT, "reading unbound")
	glyph.render(PAD)
	assert_false(glyph.is_keycap(), "bound on the pad, so a tile")
	assert_eq(glyph.shown_text(), "xbox_stick_r_press", "the R3 tile")


func test_a_binding_present_on_one_device_only_is_unbound_on_the_other() -> void:
	var glyph: PromptGlyph = _glyph(&"selection_modifier")
	glyph.render(KEYBOARD)
	assert_eq(glyph.shown_text(), "keyboard_ctrl", "the key on the keyboard")
	glyph.render(PAD)
	assert_true(glyph.is_keycap(), "the pad has nothing")
	assert_eq(glyph.shown_text(), GlyphResolver.UNBOUND_TEXT, "so it reads unbound")


func test_a_binding_with_no_tile_falls_back_to_the_text_keycap() -> void:
	var minus: InputEventKey = InputEventKey.new()
	minus.physical_keycode = KEY_KP_SUBTRACT
	_bind_temp(minus)
	var glyph: PromptGlyph = _glyph(TEMP_ACTION)
	glyph.render(KEYBOARD)
	assert_true(glyph.is_keycap(), "no keypad minus tile")
	assert_eq(glyph.shown_text(), "Kp Subtract", "the key name")
	assert_gte(glyph.custom_minimum_size.x, 24.0, "at least the glyph size wide")
	assert_gte(glyph.custom_minimum_size.y, 24.0, "and tall")


func test_a_long_key_name_widens_the_keycap_without_clipping() -> void:
	var backspace: InputEventKey = InputEventKey.new()
	backspace.physical_keycode = KEY_BACKSPACE
	_bind_temp(backspace)
	var glyph: PromptGlyph = _glyph(TEMP_ACTION)
	glyph.render(KEYBOARD)
	var label: Label = glyph.get_node("Keycap/Text") as Label
	assert_eq(label.text, "Backspace", "the long name")
	assert_gt(glyph.custom_minimum_size.x, 48.0, "wider than two tiles")
	assert_gte(glyph.size.x, label.get_combined_minimum_size().x, "the keycap holds the whole name")


func test_the_label_resolver_names_the_key_by_the_cap_label() -> void:
	var glyph: PromptGlyph = _glyph(&"ability")
	glyph.label_resolver = func(physical: int) -> int:
		return KEY_A if physical == KEY_Q else physical
	glyph.render(KEYBOARD)
	assert_eq(glyph.shown_text(), "keyboard_a", "AZERTY prints A on the Q key")


func test_a_runtime_rebind_is_noticed_while_the_glyph_is_on_screen() -> void:
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_N
	_bind_temp(key)
	var glyph: PromptGlyph = _glyph(TEMP_ACTION)
	glyph.render(KEYBOARD)
	assert_eq(glyph.shown_text(), "keyboard_n", "first the N key")
	key.physical_keycode = KEY_M
	await wait_process_frames(2)
	assert_eq(glyph.shown_text(), "keyboard_m", "the edit made in place shows up")
	InputMap.action_erase_events(TEMP_ACTION)
	var other: InputEventKey = InputEventKey.new()
	other.physical_keycode = KEY_B
	InputMap.action_add_event(TEMP_ACTION, other)
	await wait_process_frames(2)
	assert_eq(glyph.shown_text(), "keyboard_b", "and so does a replaced binding")
