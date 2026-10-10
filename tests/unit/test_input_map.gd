extends GutTest
## Input Map contract (T-01-09, T-01-18): every gameplay action has a keyboard and a gamepad
## binding, only the squad ground-point command (squad_move, the right mouse button, D-11) has a
## mouse binding, build / start-night share no key or button, and no two gameplay actions (zoom
## included) share a key, button or stick direction except the pairs listed in
## SHARED_BINDINGS_ALLOWED. The squad point commands of plan 03-07 (squad_move, squad_attack_move,
## squad_patrol, command_queue, command_cancel) are checked for keyboard and mouse here and gain
## their pad bindings in plan 03-09. The squad verbs (D-15) are F follow, H hold,
## R rally, Tab cycle and F2 select all, carried on the bare D-pad and R3; fast-forward moved from
## F to T to make room. Values are compared against engine constants, never integer literals.

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
	&"fast_forward",
	&"ability",
	&"squad_follow",
	&"squad_hold",
	&"squad_rally",
	&"squad_cycle",
	&"select_all",
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
	&"fast_forward": [KEY_T],
	&"ability": [KEY_Q],
	&"squad_follow": [KEY_F],
	&"squad_hold": [KEY_H],
	&"squad_rally": [KEY_R],
	&"squad_cycle": [KEY_TAB],
	&"select_all": [KEY_F2],
}

const EXPECTED_BUTTONS: Dictionary = {
	&"sprint": [JOY_BUTTON_RIGHT_SHOULDER],
	&"action_build": [JOY_BUTTON_A],
	&"start_night": [JOY_BUTTON_Y],
	&"toggle_debug_overlay": [JOY_BUTTON_BACK],
	&"zoom_in": [],
	&"zoom_out": [],
	&"fast_forward": [],
	&"ability": [JOY_BUTTON_X],
	&"squad_follow": [JOY_BUTTON_DPAD_UP],
	&"squad_hold": [JOY_BUTTON_DPAD_DOWN],
	&"squad_rally": [JOY_BUTTON_DPAD_LEFT],
	&"squad_cycle": [JOY_BUTTON_DPAD_RIGHT],
	&"select_all": [JOY_BUTTON_RIGHT_STICK],
}

# Stick bindings as [axis, sign].
const EXPECTED_AXES: Dictionary = {
	&"move_left": [JOY_AXIS_LEFT_X, -1.0],
	&"move_right": [JOY_AXIS_LEFT_X, 1.0],
	&"move_forward": [JOY_AXIS_LEFT_Y, -1.0],
	&"move_back": [JOY_AXIS_LEFT_Y, 1.0],
	&"zoom_in": [JOY_AXIS_RIGHT_Y, -1.0],
	&"zoom_out": [JOY_AXIS_RIGHT_Y, 1.0],
	&"fast_forward": [JOY_AXIS_TRIGGER_LEFT, 1.0],
}

const MOVE_DEADZONE: float = 0.2
const ZOOM_DEADZONE: float = 0.3
const FAST_FORWARD_DEADZONE: float = 0.5
const ABILITY_DEADZONE: float = 0.5
const SQUAD_ACTIONS: Array[StringName] = [
	&"squad_follow", &"squad_hold", &"squad_rally", &"squad_cycle", &"select_all"
]
## The point-command actions of plan 03-07: keyboard and mouse only until plan 03-09.
const COMMAND_ACTIONS: Array[StringName] = [
	&"squad_move", &"squad_attack_move", &"squad_patrol", &"command_queue", &"command_cancel"
]
const COMMAND_KEYS: Dictionary = {
	&"squad_move": [],
	# D-15 keeps A for attack-move (owner decision at the 03-07 checkpoint, not auto-mode).
	&"squad_attack_move": [KEY_A],
	&"squad_patrol": [KEY_P],
	&"command_queue": [KEY_SHIFT],
	&"command_cancel": [KEY_ESCAPE],
}
## Bindings two actions may share on purpose, as [first action, second action, binding token]. Each
## pair has a reason; every other collision fails the shared-binding test.
const SHARED_BINDINGS_ALLOWED: Array[Array] = [
	# D-09: the queue modifier is Shift, and Shift is also sprint; holding it for both is harmless.
	[&"sprint", &"command_queue", "key 4194325"],
	# D-15 keeps A for attack-move although A is also move_left. The owner chose this at the 03-07
	# checkpoint and decided that while a squad is selected the movement keys steer the selection,
	# not the king, so pressing A to arm attack-move never drifts him.
	[&"move_left", &"squad_attack_move", "key 65"],
]


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


## Fast-forward is a toggle (G-02-14) on the left trigger, an analog axis, so it reads like a button
## pressed from halfway down.
func test_fast_forward_deadzone_is_point_five() -> void:
	assert_almost_eq(
		InputMap.action_get_deadzone(&"fast_forward"), FAST_FORWARD_DEADZONE, 0.0001, "deadzone"
	)


## The weapon's active ability (D-17) is a press on a key or a face button, so it reads like the
## other buttons: halfway counts.
func test_ability_deadzone_is_point_five() -> void:
	assert_almost_eq(InputMap.action_get_deadzone(&"ability"), ABILITY_DEADZONE, 0.0001, "deadzone")


## The squad verbs are key and button presses, so halfway counts, like the other buttons.
func test_squad_command_deadzone_is_point_five() -> void:
	for action: StringName in SQUAD_ACTIONS:
		assert_almost_eq(
			InputMap.action_get_deadzone(action), ABILITY_DEADZONE, 0.0001, str(action)
		)


## F moved from fast-forward to follow: the F key no longer reaches fast-forward and T does.
func test_f_follows_and_t_fast_forwards() -> void:
	var key: InputEventKey = InputEventKey.new()
	key.pressed = true
	key.physical_keycode = KEY_F
	assert_true(InputMap.event_is_action(key, &"squad_follow"), "F is follow")
	assert_false(InputMap.event_is_action(key, &"fast_forward"), "F is no longer fast-forward")
	key.physical_keycode = KEY_T
	assert_true(InputMap.event_is_action(key, &"fast_forward"), "T is fast-forward")
	assert_false(InputMap.event_is_action(key, &"squad_follow"), "T is not follow")


func _is_allowed_pair(first: StringName, second: StringName, token: String) -> bool:
	for allowed: Array in SHARED_BINDINGS_ALLOWED:
		if allowed[2] != token:
			continue
		if (
			(allowed[0] == first and allowed[1] == second)
			or (allowed[0] == second and allowed[1] == first)
		):
			return true
	return false


func test_no_two_gameplay_actions_share_a_key_button_or_stick_direction() -> void:
	var owners: Dictionary = {}
	var every_action: Array[StringName] = GAMEPLAY_ACTIONS.duplicate()
	every_action.append_array(COMMAND_ACTIONS)
	for action: StringName in every_action:
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
			var shared: bool = owners.has(token) and owners[token] != action
			assert_false(
				shared and not _is_allowed_pair(owners[token], action, token),
				"%s is on both %s and %s" % [token, owners.get(token, ""), action]
			)
			owners[token] = action


func test_only_squad_move_has_a_mouse_binding_and_it_is_the_right_button() -> void:
	var moves: int = 0
	for action: StringName in _project_actions():
		for event: InputEvent in InputMap.action_get_events(action):
			assert_false(event is InputEventMouseMotion, "%s has no mouse motion" % action)
			if event is InputEventMouseButton:
				assert_eq(action, &"squad_move", "only squad_move has a mouse button")
				assert_eq(
					(event as InputEventMouseButton).button_index, MOUSE_BUTTON_RIGHT, "right"
				)
				moves += 1
	assert_eq(moves, 1, "squad_move has exactly one mouse binding")


func test_the_point_command_actions_exist_with_the_keys_of_the_table() -> void:
	for action: StringName in COMMAND_ACTIONS:
		assert_true(InputMap.has_action(action), "%s exists in the Input Map" % action)
		var expected: Array = COMMAND_KEYS[action]
		var actual: Array[int] = _keys_of(action)
		assert_eq(actual.size(), expected.size(), "%s key count" % action)
		for key: int in expected:
			assert_true(actual.has(key), "%s is bound to physical key %d" % [action, key])
		assert_almost_eq(
			InputMap.action_get_deadzone(action), ABILITY_DEADZONE, 0.0001, "%s deadzone" % action
		)


func test_attack_move_shares_a_with_move_left_by_the_owner_decision() -> void:
	var key: InputEventKey = InputEventKey.new()
	key.pressed = true
	key.physical_keycode = KEY_A
	assert_true(InputMap.event_is_action(key, &"squad_attack_move"), "A arms attack-move")
	assert_true(InputMap.event_is_action(key, &"move_left"), "and is still move_left")


func test_build_and_start_night_share_no_key() -> void:
	var build_keys: Array[int] = _keys_of(&"action_build")
	for key: int in _keys_of(&"start_night"):
		assert_false(build_keys.has(key), "physical key %d is on both build and start_night" % key)


func test_build_and_start_night_share_no_joypad_button() -> void:
	var build_buttons: Array[int] = _buttons_of(&"action_build")
	for button: int in _buttons_of(&"start_night"):
		assert_false(build_buttons.has(button), "joypad button %d is on both actions" % button)


## The results screen is operated through the menu actions (D-16): accept and left / right must work
## from the keyboard and the gamepad whatever the engine's built-in defaults are on a machine.
func test_the_menu_actions_have_keyboard_and_gamepad_bindings() -> void:
	var menu_keys: Dictionary = {
		&"ui_accept": KEY_ENTER, &"ui_left": KEY_LEFT, &"ui_right": KEY_RIGHT
	}
	var menu_buttons: Dictionary = {
		&"ui_accept": JOY_BUTTON_A,
		&"ui_left": JOY_BUTTON_DPAD_LEFT,
		&"ui_right": JOY_BUTTON_DPAD_RIGHT
	}
	for action: StringName in menu_keys:
		var keycodes: Array[int] = []
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				keycodes.append((event as InputEventKey).keycode)
		assert_true(keycodes.has(menu_keys[action]), "%s has its key" % action)
		assert_true(_buttons_of(action).has(menu_buttons[action]), "%s has a pad button" % action)
	for event: InputEvent in InputMap.action_get_events(&"ui_accept"):
		assert_false(event is InputEventMouseButton, "accept has no mouse binding")
