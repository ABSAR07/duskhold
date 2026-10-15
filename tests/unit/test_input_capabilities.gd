extends GutTest
## INPT-01, INPT-02, D-12: every in-run capability has a keyboard-and-mouse path and a gamepad path.
## The table names the Input Map actions behind each capability on each device; the tests check the
## actions exist, that the keyboard / mouse side has a key or mouse event and that the gamepad side
## has a joypad button or stick event, and that no project action is left out of the table. The one
## capability that is not an action, select one type by double-click, is a gesture marker backed by
## its own scene test, so a marker with no test fails here. The pad-only actions of plan 03-09
## (command layer, group mode, select type, the ground cursor) are pinned to their pad bindings.
## The pad column is unsupported since 2026-10-16 (owner decision); it pins the shipped bindings.

const CURSOR_ACTIONS: Array[StringName] = [
	&"cursor_left", &"cursor_right", &"cursor_up", &"cursor_down"
]
const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_forward", &"move_back"]
const GROUP_DIGITS: Array[StringName] = [
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
]
## The one capability that is a gesture and not an action: the left double-click.
const GESTURE_MARKERS: Dictionary = {
	"double_click": "res://tests/e2e/test_select_one_type.gd",
}
## The "pad" column of every row below pins the shipped pad bindings, which stay unsupported.
const PAD_COLUMN_STATUS: String = "unsupported since 2026-10-16 (owner decision)"
const CAPABILITIES: Dictionary = {
	"move": {"keys": MOVE_ACTIONS, "pad": MOVE_ACTIONS},
	"sprint": {"keys": [&"sprint"], "pad": [&"sprint"]},
	"build": {"keys": [&"action_build"], "pad": [&"action_build"]},
	"start night": {"keys": [&"start_night"], "pad": [&"start_night"]},
	"ability": {"keys": [&"ability"], "pad": [&"ability"]},
	"follow": {"keys": [&"squad_follow"], "pad": [&"squad_follow"]},
	"hold": {"keys": [&"squad_hold"], "pad": [&"squad_hold"]},
	"rally": {"keys": [&"squad_rally"], "pad": [&"squad_rally"]},
	"move order":
	{
		"keys": [&"squad_move"],
		"pad":
		[
			&"squad_move",
			&"command_layer",
			&"cursor_left",
			&"cursor_right",
			&"cursor_up",
			&"cursor_down"
		],
	},
	"attack-move":
	{
		"keys": [&"squad_attack_move"],
		"pad":
		[
			&"squad_attack_move",
			&"command_layer",
			&"cursor_left",
			&"cursor_right",
			&"cursor_up",
			&"cursor_down"
		],
	},
	"patrol":
	{
		"keys": [&"squad_patrol"],
		"pad":
		[
			&"squad_patrol",
			&"command_layer",
			&"cursor_left",
			&"cursor_right",
			&"cursor_up",
			&"cursor_down"
		],
	},
	"queue": {"keys": [&"command_queue"], "pad": [&"command_queue"]},
	"cancel": {"keys": [&"command_cancel"], "pad": [&"command_cancel"]},
	"cycle": {"keys": [&"squad_cycle"], "pad": [&"squad_cycle"]},
	"select all": {"keys": [&"select_all"], "pad": [&"select_all"]},
	"select one type": {"keys": ["double_click"], "pad": [&"select_type", &"command_layer"]},
	"store group":
	{
		"keys":
		[
			&"selection_modifier",
			&"group_1",
			&"group_2",
			&"group_3",
			&"group_4",
			&"group_5",
			&"group_6",
			&"group_7",
			&"group_8",
			&"group_9",
			&"group_0"
		],
		"pad": [&"group_mode", &"squad_rally", &"squad_cycle", &"squad_attack_move"],
	},
	"recall group":
	{
		"keys":
		[
			&"group_1",
			&"group_2",
			&"group_3",
			&"group_4",
			&"group_5",
			&"group_6",
			&"group_7",
			&"group_8",
			&"group_9",
			&"group_0"
		],
		"pad": [&"group_mode", &"squad_follow", &"squad_move"],
	},
	"fast-forward": {"keys": [&"fast_forward"], "pad": [&"fast_forward"]},
	"zoom": {"keys": [&"zoom_in", &"zoom_out"], "pad": [&"zoom_in", &"zoom_out"]},
	"overlay": {"keys": [&"toggle_debug_overlay"], "pad": [&"toggle_debug_overlay"]},
}
## Pad-only actions to their joypad button, or [axis, sign] for a stick direction.
const PAD_ONLY_BUTTONS: Dictionary = {
	&"command_layer": JOY_BUTTON_LEFT_SHOULDER,
	&"group_mode": JOY_BUTTON_START,
	&"select_type": JOY_BUTTON_RIGHT_STICK,
}
const PAD_ONLY_AXES: Dictionary = {
	&"cursor_left": [JOY_AXIS_RIGHT_X, -1.0],
	&"cursor_right": [JOY_AXIS_RIGHT_X, 1.0],
	&"cursor_up": [JOY_AXIS_RIGHT_Y, -1.0],
	&"cursor_down": [JOY_AXIS_RIGHT_Y, 1.0],
}
const BUTTON_DEADZONE: float = 0.5
const STICK_DEADZONE: float = 0.2


func _is_gesture(entry: Variant) -> bool:
	return entry is String and GESTURE_MARKERS.has(entry)


func _has_keyboard_or_mouse_event(action: StringName) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey or event is InputEventMouseButton:
			return true
	return false


func _has_pad_event(action: StringName) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return true
	return false


func test_the_pad_column_is_marked_unsupported() -> void:
	assert_string_contains(PAD_COLUMN_STATUS, "unsupported since 2026-10-16")


func test_every_action_named_in_the_table_exists_in_the_input_map() -> void:
	for capability: String in CAPABILITIES:
		for side: String in ["keys", "pad"]:
			for entry: Variant in CAPABILITIES[capability][side]:
				if _is_gesture(entry):
					continue
				assert_true(
					InputMap.has_action(entry), "%s (%s): %s exists" % [capability, side, entry]
				)


func test_every_capability_has_a_keyboard_or_mouse_path() -> void:
	for capability: String in CAPABILITIES:
		var entries: Array = CAPABILITIES[capability]["keys"]
		var reachable: bool = false
		for entry: Variant in entries:
			if _is_gesture(entry) or _has_keyboard_or_mouse_event(entry):
				reachable = true
		assert_true(reachable, "%s can be done on the keyboard and mouse" % capability)


func test_every_capability_has_a_gamepad_path_and_every_action_on_it_has_a_pad_event() -> void:
	for capability: String in CAPABILITIES:
		var entries: Array = CAPABILITIES[capability]["pad"]
		assert_gt(entries.size(), 0, "%s names its pad actions" % capability)
		for entry: Variant in entries:
			assert_true(_has_pad_event(entry), "%s: %s has a joypad event" % [capability, entry])


func test_every_gesture_marker_is_backed_by_a_scene_test_that_exists() -> void:
	var used: Array[String] = []
	for capability: String in CAPABILITIES:
		for entry: Variant in CAPABILITIES[capability]["keys"]:
			if entry is String:
				assert_true(
					GESTURE_MARKERS.has(entry), "%s: %s is a known marker" % [capability, entry]
				)
				used.append(entry)
	for marker: String in GESTURE_MARKERS:
		assert_true(used.has(marker), "the marker %s is used by a capability" % marker)
		assert_true(
			ResourceLoader.exists(GESTURE_MARKERS[marker]), "%s has its scene test" % marker
		)


func test_the_table_has_the_rows_the_plan_names() -> void:
	for capability: String in [
		"move",
		"sprint",
		"build",
		"start night",
		"ability",
		"follow",
		"hold",
		"rally",
		"move order",
		"attack-move",
		"patrol",
		"queue",
		"cancel",
		"cycle",
		"select all",
		"select one type",
		"store group",
		"recall group",
		"fast-forward",
		"zoom",
		"overlay",
	]:
		assert_true(CAPABILITIES.has(capability), "%s has a row" % capability)
	assert_eq(CAPABILITIES.size(), 21, "and the table has no other row")


## A new action added to the Input Map must say which capability it belongs to and how a pad player
## reaches it.
func test_every_project_action_belongs_to_a_capability() -> void:
	var known: Array = []
	for capability: String in CAPABILITIES:
		for side: String in ["keys", "pad"]:
			known.append_array(CAPABILITIES[capability][side])
	for action: StringName in InputMap.get_actions():
		if String(action).begins_with("ui_"):
			continue
		assert_true(known.has(action), "%s belongs to a capability in the table" % action)


func test_the_pad_only_actions_have_exactly_the_bindings_of_the_layout() -> void:
	for action: StringName in PAD_ONLY_BUTTONS:
		assert_true(InputMap.has_action(action), "%s exists" % action)
		var events: Array[InputEvent] = InputMap.action_get_events(action)
		assert_eq(events.size(), 1, "%s has one event" % action)
		var press: InputEventJoypadButton = events[0] as InputEventJoypadButton
		assert_not_null(press, "%s is a joypad button" % action)
		assert_eq(press.button_index, PAD_ONLY_BUTTONS[action], "%s button" % action)
		assert_almost_eq(InputMap.action_get_deadzone(action), BUTTON_DEADZONE, 0.0001, str(action))
	for action: StringName in PAD_ONLY_AXES:
		assert_true(InputMap.has_action(action), "%s exists" % action)
		var events: Array[InputEvent] = InputMap.action_get_events(action)
		assert_eq(events.size(), 1, "%s has one event" % action)
		var motion: InputEventJoypadMotion = events[0] as InputEventJoypadMotion
		assert_not_null(motion, "%s is a stick direction" % action)
		assert_eq(motion.axis, PAD_ONLY_AXES[action][0], "%s axis" % action)
		assert_almost_eq(motion.axis_value, PAD_ONLY_AXES[action][1], 0.0001, "%s sign" % action)
		assert_almost_eq(InputMap.action_get_deadzone(action), STICK_DEADZONE, 0.0001, str(action))


func test_the_group_digits_are_keyboard_only_and_the_pad_reaches_groups_through_group_mode(
) -> void:
	for action: StringName in GROUP_DIGITS:
		assert_false(_has_pad_event(action), "%s has no pad event, group mode covers it" % action)
	assert_true(_has_pad_event(&"group_mode"), "group mode is a pad button")


func test_the_cursor_actions_have_no_keyboard_or_mouse_binding() -> void:
	for action: StringName in CURSOR_ACTIONS:
		assert_false(_has_keyboard_or_mouse_event(action), "%s is the right stick only" % action)
