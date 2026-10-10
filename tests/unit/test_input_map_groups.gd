extends GutTest
## Input Map contract for the control-group actions of plan 03-08 (D-10, Pitfall 5): ten digit
## actions group_1 .. group_9 and group_0 (key 0 is group 10) plus one selection_modifier action
## on Ctrl, branched in code instead of Ctrl + digit chord actions. Keyboard only; their pad path
## is plan 03-09's group mode. The no-shared-binding scan in test_input_map covers them too.

const GROUP_ACTIONS: Array[StringName] = [
	&"group_1",
	&"group_2",
	&"group_3",
	&"group_4",
	&"group_5",
	&"group_6",
	&"group_7",
	&"group_8",
	&"group_9",
	&"group_0",
	&"selection_modifier",
]
const GROUP_KEYS: Dictionary = {
	&"group_1": [KEY_1],
	&"group_2": [KEY_2],
	&"group_3": [KEY_3],
	&"group_4": [KEY_4],
	&"group_5": [KEY_5],
	&"group_6": [KEY_6],
	&"group_7": [KEY_7],
	&"group_8": [KEY_8],
	&"group_9": [KEY_9],
	&"group_0": [KEY_0],
	&"selection_modifier": [KEY_CTRL],
}
const DEADZONE: float = 0.5


func _keys_of(action: StringName) -> Array[int]:
	var keys: Array[int] = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			keys.append((event as InputEventKey).physical_keycode)
	return keys


func test_the_group_actions_are_keyboard_only_digits_plus_the_ctrl_modifier() -> void:
	for action: StringName in GROUP_ACTIONS:
		assert_true(InputMap.has_action(action), "%s exists in the Input Map" % action)
		var expected: Array = GROUP_KEYS[action]
		var actual: Array[int] = _keys_of(action)
		assert_eq(actual.size(), expected.size(), "%s key count" % action)
		for key: int in expected:
			assert_true(actual.has(key), "%s is bound to physical key %d" % [action, key])
		assert_eq(
			InputMap.action_get_events(action).size(), expected.size(), "%s is keys only" % action
		)
		assert_almost_eq(InputMap.action_get_deadzone(action), DEADZONE, 0.0001, str(action))


## Pitfall 5: the engine matches a bare-digit action against Ctrl + digit too, so there is no
## Ctrl + digit chord action; the code reads selection_modifier when a digit goes down.
func test_a_ctrl_digit_event_matches_the_digit_action_and_the_modifier_is_its_own_action() -> void:
	var key: InputEventKey = InputEventKey.new()
	key.pressed = true
	key.physical_keycode = KEY_1
	key.ctrl_pressed = true
	assert_true(InputMap.event_is_action(key, &"group_1"), "Ctrl + 1 still matches group_1")
	assert_false(InputMap.event_is_action(key, &"group_2"), "and no other digit")
	var ctrl: InputEventKey = InputEventKey.new()
	ctrl.pressed = true
	ctrl.physical_keycode = KEY_CTRL
	assert_true(InputMap.event_is_action(ctrl, &"selection_modifier"), "Ctrl is the modifier")
	assert_false(InputMap.event_is_action(ctrl, &"group_1"), "and not a digit")
