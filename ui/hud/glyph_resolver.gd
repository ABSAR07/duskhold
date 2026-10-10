class_name GlyphResolver
extends RefCounted
## INPT-02 / D-24: turns an action and a device into what a prompt shows. The first binding of the
## action on that device becomes a Kenney Input Prompts tile (CC0, white on transparent, drawn on a
## dark plate by PromptGlyph), or, when the pack has no tile for it, a readable text for a keycap.
## An action with no binding on the device reads "(unbound)".
##
## Keys are named by the label the player's layout prints on the keycap, not by their US-QWERTY
## position, so the prompts stay right on Dvorak and AZERTY. The label lookup is a Callable so a
## test can stand in for a non-QWERTY layout, which headless Godot cannot switch to.
## Presentation only: nothing here touches the simulation.

const DEVICE_KEYBOARD: int = 0
const DEVICE_PAD: int = 1
const TILE_ROOT := "res://assets/third_party/kenney_input_prompts"
const KEYBOARD_DIR := TILE_ROOT + "/keyboard_mouse/"
const PAD_DIR := TILE_ROOT + "/xbox/"
const UNBOUND_TEXT := "(unbound)"
const TILE_EXTENSION := ".png"

## Keys that have a tile but no single letter or digit, by keycode. Letters and digits are named by
## the character itself.
const NAMED_KEY_TILES: Dictionary = {
	KEY_SPACE: "space",
	KEY_SHIFT: "shift",
	KEY_CTRL: "ctrl",
	KEY_TAB: "tab",
	KEY_ESCAPE: "escape",
	KEY_ENTER: "enter",
	KEY_UP: "arrow_up",
	KEY_DOWN: "arrow_down",
	KEY_LEFT: "arrow_left",
	KEY_RIGHT: "arrow_right",
	KEY_F2: "f2",
	KEY_F3: "f3",
	KEY_EQUAL: "equals",
	KEY_MINUS: "minus",
	KEY_KP_ADD: "numpad_plus",
}
const MOUSE_TILES: Dictionary = {
	MOUSE_BUTTON_LEFT: "mouse_left",
	MOUSE_BUTTON_RIGHT: "mouse_right",
}
## Pad buttons by JoyButton index. The left stick press has no tile and reads "L3".
const PAD_BUTTON_TILES: Dictionary = {
	JOY_BUTTON_A: "xbox_button_a",
	JOY_BUTTON_B: "xbox_button_b",
	JOY_BUTTON_X: "xbox_button_x",
	JOY_BUTTON_Y: "xbox_button_y",
	JOY_BUTTON_BACK: "xbox_button_back",
	JOY_BUTTON_START: "xbox_button_start",
	JOY_BUTTON_RIGHT_STICK: "xbox_stick_r_press",
	JOY_BUTTON_LEFT_SHOULDER: "xbox_lb",
	JOY_BUTTON_RIGHT_SHOULDER: "xbox_rb",
	JOY_BUTTON_DPAD_UP: "xbox_dpad_up",
	JOY_BUTTON_DPAD_DOWN: "xbox_dpad_down",
	JOY_BUTTON_DPAD_LEFT: "xbox_dpad_left",
	JOY_BUTTON_DPAD_RIGHT: "xbox_dpad_right",
}
## Triggers and sticks by JoyAxis index. Both directions of a stick axis share the stick tile.
const AXIS_TILES: Dictionary = {
	JOY_AXIS_LEFT_X: "xbox_ls",
	JOY_AXIS_LEFT_Y: "xbox_ls",
	JOY_AXIS_RIGHT_X: "xbox_rs",
	JOY_AXIS_RIGHT_Y: "xbox_rs",
	JOY_AXIS_TRIGGER_LEFT: "xbox_lt",
	JOY_AXIS_TRIGGER_RIGHT: "xbox_rt",
}
## Gamepad button names for the keycap text, by JoyButton index. These are Xbox-style labels: on a
## PlayStation or Switch pad they are wrong (button 3 reads "Y", not "Triangle"). Known limitation
## until the controls menu of Phase 13.
const PAD_BUTTON_NAMES: Dictionary = {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Back",
	JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "D-pad up",
	JOY_BUTTON_DPAD_DOWN: "D-pad down",
	JOY_BUTTON_DPAD_LEFT: "D-pad left",
	JOY_BUTTON_DPAD_RIGHT: "D-pad right",
}
## Trigger names for the keycap text, by JoyAxis index.
const AXIS_NAMES: Dictionary = {
	JOY_AXIS_TRIGGER_LEFT: "LT",
	JOY_AXIS_TRIGGER_RIGHT: "RT",
}


## The first event bound to `action` that belongs to `device`: a key or mouse button for the
## keyboard, a pad button or axis for the pad. Null when the action is unknown or has none there.
static func first_event(action: StringName, device: int) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	for event: InputEvent in InputMap.action_get_events(action):
		if device == DEVICE_KEYBOARD and (event is InputEventKey or event is InputEventMouseButton):
			return event
		if (
			device == DEVICE_PAD
			and (event is InputEventJoypadButton or event is InputEventJoypadMotion)
		):
			return event
	return null


## The res:// path of the tile for `event`, or "" when the pack has none (a chord, a key the pack
## does not draw, a middle mouse button, a left stick press) or the file is missing.
static func tile_path(event: InputEvent, label_resolver: Callable) -> String:
	var path: String = ""
	if event is InputEventKey:
		var stem: String = _key_tile_name(event as InputEventKey, label_resolver)
		if not stem.is_empty():
			path = KEYBOARD_DIR + "keyboard_%s%s" % [stem, TILE_EXTENSION]
	elif event is InputEventMouseButton:
		var mouse: String = MOUSE_TILES.get((event as InputEventMouseButton).button_index, "")
		if not mouse.is_empty():
			path = KEYBOARD_DIR + mouse + TILE_EXTENSION
	elif event is InputEventJoypadButton:
		var button: String = PAD_BUTTON_TILES.get(
			(event as InputEventJoypadButton).button_index, ""
		)
		if not button.is_empty():
			path = PAD_DIR + button + TILE_EXTENSION
	elif event is InputEventJoypadMotion:
		var axis: String = AXIS_TILES.get((event as InputEventJoypadMotion).axis, "")
		if not axis.is_empty():
			path = PAD_DIR + axis + TILE_EXTENSION
	if path.is_empty() or not ResourceLoader.exists(path):
		return ""
	return path


## The text of a keycap for `event`: the key with its modifiers ("Ctrl+N"), a mouse button or pad
## button by name, a trigger by name, any other axis by index and direction. "(unbound)" for no
## event at all and for an event that names nothing.
static func keycap_text(event: InputEvent, label_resolver: Callable) -> String:
	var text: String = ""
	if event is InputEventKey:
		text = key_text(event as InputEventKey, label_resolver)
	elif event is InputEventMouseButton:
		text = event.as_text()
	elif event is InputEventJoypadButton:
		var button: int = (event as InputEventJoypadButton).button_index
		text = PAD_BUTTON_NAMES.get(button, "Pad %d" % button)
	elif event is InputEventJoypadMotion:
		text = axis_text(event as InputEventJoypadMotion)
	if text.is_empty():
		return UNBOUND_TEXT
	return text


## The default label resolver: the keycode the current keyboard layout prints on a physical key.
## The headless display server has no keyboard layout (its call errors), so a physical key stays as
## it is there.
static func layout_label(physical: int) -> int:
	if DisplayServer.get_name() == "headless":
		return physical
	return DisplayServer.keyboard_get_label_from_physical(physical as Key)


## The key a prompt names: the label of the physical key on the player's layout, else the keycode,
## else the key label. KEY_NONE when the event names no key.
static func _label_key(key_event: InputEventKey, label_resolver: Callable) -> int:
	if key_event.physical_keycode != KEY_NONE:
		var label_key: int = label_resolver.call(key_event.physical_keycode)
		if label_key != KEY_NONE:
			return label_key
		return key_event.physical_keycode
	if key_event.keycode != KEY_NONE:
		return key_event.keycode
	return key_event.key_label


## The tile name stem of a plain (modifier-free) key: a letter or digit by its character, the rest
## by the named table; empty when the pack has no tile for it.
static func _key_tile_name(key_event: InputEventKey, label_resolver: Callable) -> String:
	if key_event.get_modifiers_mask() != 0:
		return ""
	var key: int = _label_key(key_event, label_resolver)
	if key >= KEY_A and key <= KEY_Z:
		return char(key).to_lower()
	if key >= KEY_0 and key <= KEY_9:
		return char(key)
	return NAMED_KEY_TILES.get(key, "")


## A key event's text, with modifiers; empty when it names no key at all.
static func key_text(key_event: InputEventKey, label_resolver: Callable) -> String:
	if key_event.physical_keycode != KEY_NONE:
		var label_key: int = label_resolver.call(key_event.physical_keycode)
		if label_key != KEY_NONE:
			var labelled: String = OS.get_keycode_string(
				(label_key | key_event.get_modifiers_mask()) as Key
			)
			if not labelled.is_empty():
				return labelled
		return key_event.as_text_physical_keycode()
	if key_event.keycode != KEY_NONE:
		return key_event.as_text_keycode()
	if key_event.key_label != KEY_NONE:
		return key_event.as_text_key_label()
	return ""


## A joypad axis binding's name: a trigger by its name, any other axis by index and direction
## ("Axis 0-" and "Axis 0+" are the two ways to push one stick axis).
static func axis_text(motion: InputEventJoypadMotion) -> String:
	if AXIS_NAMES.has(motion.axis):
		return AXIS_NAMES[motion.axis]
	return "Axis %d%s" % [motion.axis, "-" if motion.axis_value < 0.0 else "+"]
