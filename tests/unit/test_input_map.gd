extends GutTest
## Input Map contract (T-01-09, T-01-18): every gameplay action has a keyboard and a gamepad
## binding, no gameplay action has a mouse binding, build / start-night share no key or button
## (D-11), and no two gameplay actions (zoom included) share a key, button or stick direction.
## Values are compared against engine constants, never integer literals.

const GAMEPLAY_ACTIONS: Array[StringName] = [
	&"move_left",
	&"move_right",
	&"move_forward",
	&"move_back",
	&"sprint",
	&"action_build",
	&"start_night",
	&"toggle_debug_overlay",
	&"zoom_in",
	&"zoom_out",
]

const EXPECTED_KEYS: Dictionary = {
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
	&"move_forward": [KEY_W, KEY_UP],
	&"move_back": [KEY_S, KEY_DOWN],
	&"sprint": [KEY_SHIFT],
	&"action_build": [KEY_SPACE, KEY_E],
	&"start_night": [KEY_N],
	&"toggle_debug_overlay": [KEY_F3],
	&"zoom_in": [KEY_EQUAL, KEY_KP_ADD],
	&"zoom_out": [KEY_MINUS, KEY_KP_SUBTRACT],
}

const EXPECTED_BUTTONS: Dictionary = {
	&"sprint": [JOY_BUTTON_RIGHT_SHOULDER],
	&"action_build": [JOY_BUTTON_A],
	&"start_night": [JOY_BUTTON_Y],
	&"toggle_debug_overlay": [JOY_BUTTON_BACK],
	&"zoom_in": [],
	&"zoom_out": [],
}

# Stick bindings as [axis, sign].
const EXPECTED_AXES: Dictionary = {
	&"move_left": [JOY_AXIS_LEFT_X, -1.0],
	&"move_right": [JOY_AXIS_LEFT_X, 1.0],
	&"move_forward": [JOY_AXIS_LEFT_Y, -1.0],
	&"move_back": [JOY_AXIS_LEFT_Y, 1.0],
	&"zoom_in": [JOY_AXIS_RIGHT_Y, -1.0],
	&"zoom_out": [JOY_AXIS_RIGHT_Y, 1.0],
}

const MOVE_DEADZONE: float = 0.2
const ZOOM_DEADZONE: float = 0.3


func _keys_of(action: StringName) -> Array[int]:
	var keys: Array[int] = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			keys.append((event as InputEventKey).physical_keycode)
	return keys


func _buttons_of(action: StringName) -> Array[int]:
	var buttons: Array[int] = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			buttons.append((event as InputEventJoypadButton).button_index)
	return buttons


func _project_actions() -> Array[StringName]:
	var actions: Array[StringName] = []
	for action: StringName in InputMap.get_actions():
		if not String(action).begins_with("ui_"):
			actions.append(action)
	return actions


func test_every_gameplay_action_exists() -> void:
	for action: StringName in GAMEPLAY_ACTIONS:
		assert_true(InputMap.has_action(action), "%s exists in the Input Map" % action)


func test_every_gameplay_action_has_a_keyboard_binding() -> void:
	for action: StringName in GAMEPLAY_ACTIONS:
		assert_gt(_keys_of(action).size(), 0, "%s has a keyboard binding" % action)


func test_every_gameplay_action_has_a_gamepad_binding() -> void:
	for action: StringName in GAMEPLAY_ACTIONS:
		var pad_events: int = 0
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				pad_events += 1
		assert_gt(pad_events, 0, "%s has a gamepad binding" % action)


func test_keyboard_bindings_match_the_binding_table() -> void:
	for action: StringName in EXPECTED_KEYS:
		var expected: Array = EXPECTED_KEYS[action]
		var actual: Array[int] = _keys_of(action)
		assert_eq(actual.size(), expected.size(), "%s key count" % action)
		for key: int in expected:
			assert_true(actual.has(key), "%s is bound to physical key %d" % [action, key])


func test_gamepad_button_bindings_match_the_binding_table() -> void:
	for action: StringName in EXPECTED_BUTTONS:
		var expected: Array = EXPECTED_BUTTONS[action]
		var actual: Array[int] = _buttons_of(action)
		assert_eq(actual.size(), expected.size(), "%s button count" % action)
		for button: int in expected:
			assert_true(actual.has(button), "%s is bound to joypad button %d" % [action, button])


func test_stick_bindings_match_the_binding_table() -> void:
	for action: StringName in EXPECTED_AXES:
		var expected: Array = EXPECTED_AXES[action]
		var found: bool = false
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventJoypadMotion:
				var motion: InputEventJoypadMotion = event
				if motion.axis == expected[0] and is_equal_approx(motion.axis_value, expected[1]):
					found = true
		assert_true(found, "%s is bound to stick axis %d" % [action, expected[0]])


func test_movement_deadzone_is_point_two() -> void:
	for action: StringName in [&"move_left", &"move_right", &"move_forward", &"move_back"]:
		assert_almost_eq(InputMap.action_get_deadzone(action), MOVE_DEADZONE, 0.0001, str(action))


func test_zoom_deadzone_is_point_three() -> void:
	for action: StringName in [&"zoom_in", &"zoom_out"]:
		assert_almost_eq(InputMap.action_get_deadzone(action), ZOOM_DEADZONE, 0.0001, str(action))


func test_no_two_gameplay_actions_share_a_key_button_or_stick_direction() -> void:
	var owners: Dictionary = {}
	for action: StringName in GAMEPLAY_ACTIONS:
		for event: InputEvent in InputMap.action_get_events(action):
			var token: String = ""
			if event is InputEventKey:
				token = "key %d" % (event as InputEventKey).physical_keycode
			elif event is InputEventJoypadButton:
				token = "button %d" % (event as InputEventJoypadButton).button_index
			elif event is InputEventJoypadMotion:
				var motion: InputEventJoypadMotion = event
				token = "axis %d sign %d" % [motion.axis, signf(motion.axis_value)]
			if token == "":
				continue
			assert_false(
				owners.has(token) and owners[token] != action,
				"%s is on both %s and %s" % [token, owners.get(token, ""), action]
			)
			owners[token] = action


func test_no_project_action_has_a_mouse_binding() -> void:
	for action: StringName in _project_actions():
		for event: InputEvent in InputMap.action_get_events(action):
			assert_false(event is InputEventMouseButton, "%s has no mouse button" % action)
			assert_false(event is InputEventMouseMotion, "%s has no mouse motion" % action)


func test_build_and_start_night_share_no_key() -> void:
	var build_keys: Array[int] = _keys_of(&"action_build")
	for key: int in _keys_of(&"start_night"):
		assert_false(build_keys.has(key), "physical key %d is on both build and start_night" % key)


func test_build_and_start_night_share_no_joypad_button() -> void:
	var build_buttons: Array[int] = _buttons_of(&"action_build")
	for button: int in _buttons_of(&"start_night"):
		assert_false(build_buttons.has(button), "joypad button %d is on both actions" % button)
