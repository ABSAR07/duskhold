extends GutTest
## INPT-02 / D-24, T-03-17: the pure device rule, amended by the owner decision of 2026-10-16. No
## pad button, stick or trigger event switches the device: the model starts on the keyboard and
## never leaves it, so no later key, click, motion or disconnect reports a switch either. The
## thresholds of the shipped rule stay pinned as constants.

const KEYBOARD: int = GlyphResolver.DEVICE_KEYBOARD

var _model: DeviceModel


func before_each() -> void:
	_model = DeviceModel.new()


func _pad_button(pressed: bool = true) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_A
	event.pressed = pressed
	return event


func _key(pressed: bool = true, echo: bool = false) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = KEY_Q
	event.pressed = pressed
	event.echo = echo
	return event


func _stick(value: float) -> InputEventJoypadMotion:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_RIGHT_X
	event.axis_value = value
	return event


func _motion(pixels: float) -> InputEventMouseMotion:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.relative = Vector2(pixels, 0.0)
	return event


func _click(pressed: bool = true) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	return event


## A model that has just been fed a pad press at t = 0 (which is no switch).
func _after_pad_press() -> DeviceModel:
	var model: DeviceModel = DeviceModel.new()
	assert_false(model.feed(_pad_button(), 0.0), "a pad press is no switch")
	return model


func test_the_constants_are_the_ui_spec_values() -> void:
	assert_eq(DeviceModel.SWITCH_MIN_INTERVAL_S, 0.25, "one switch per 0.25 s")
	assert_eq(DeviceModel.AXIS_THRESHOLD, 0.5, "axis threshold")
	assert_eq(DeviceModel.MOTION_THRESHOLD_PX, 8.0, "mouse motion threshold")
	assert_false(DeviceModel.PAD_PROMPTS_SUPPORTED, "pad prompts are unsupported")


func test_it_starts_on_the_keyboard_and_a_key_there_changes_nothing() -> void:
	assert_eq(_model.device(), KEYBOARD, "starts on keyboard")
	assert_false(_model.feed(_key(), 0.0), "a key on the keyboard is no switch")
	assert_eq(_model.device(), KEYBOARD, "still keyboard")


func test_a_pad_button_press_keeps_the_keyboard() -> void:
	assert_false(_model.feed(_pad_button(), 0.0), "the first pad press is no switch")
	assert_false(_model.feed(_pad_button(), 1.0), "a second pad press is no switch")
	assert_eq(_model.device(), KEYBOARD, "still the keyboard")


func test_a_release_or_an_echo_counts_for_nothing() -> void:
	assert_false(_model.feed(_pad_button(false), 0.0), "a pad button release")
	assert_false(_model.feed(_key(false), 0.0), "a key release")
	var pad: DeviceModel = _after_pad_press()
	assert_false(pad.feed(_key(true, true), 1.0), "a key echo")
	assert_false(pad.feed(_key(false), 1.0), "a key release")
	assert_false(pad.feed(_click(false), 1.0), "a mouse button release")
	assert_eq(pad.device(), KEYBOARD, "the keyboard stays")


func test_keys_after_a_pad_press_never_switch_at_any_delay() -> void:
	var model: DeviceModel = _after_pad_press()
	assert_false(model.feed(_key(), 0.1), "0.1 s after the pad press")
	assert_false(model.feed(_key(), 0.249), "just under 0.25 s")
	assert_false(model.feed(_key(), 0.25), "0.25 s")
	assert_eq(model.device(), KEYBOARD, "the keyboard")


func test_a_stick_at_any_travel_keeps_the_keyboard() -> void:
	for value: float in [0.49, 0.5, -0.49, -0.5, 1.0]:
		assert_false(_model.feed(_stick(value), 1.0), "a stick at %s is no switch" % value)
	assert_eq(_model.device(), KEYBOARD, "still keyboard")


func test_mouse_motion_after_a_pad_press_is_no_switch() -> void:
	var seven: DeviceModel = _after_pad_press()
	assert_false(seven.feed(_motion(7.0), 1.0), "7 px is no switch")
	assert_eq(seven.device(), KEYBOARD, "still the keyboard")
	var eight: DeviceModel = _after_pad_press()
	assert_false(eight.feed(_motion(8.0), 1.0), "8 px is no switch either")
	assert_eq(eight.device(), KEYBOARD, "keyboard")


func test_motion_inside_or_across_the_window_is_no_switch() -> void:
	var spread: DeviceModel = _after_pad_press()
	assert_false(spread.feed(_motion(4.0), 1.0), "the first 4 px")
	assert_false(spread.feed(_motion(4.0), 1.3), "the next 4 px, 0.3 s later")
	assert_eq(spread.device(), KEYBOARD, "the keyboard stays")
	var together: DeviceModel = _after_pad_press()
	assert_false(together.feed(_motion(4.0), 1.0), "the first 4 px")
	assert_false(together.feed(_motion(4.0), 1.2), "4 more inside the window")
	assert_eq(together.device(), KEYBOARD, "keyboard")


func test_a_mouse_button_press_after_a_pad_press_is_no_switch() -> void:
	var model: DeviceModel = _after_pad_press()
	assert_false(model.feed(_click(), 1.0), "a click is no switch")
	assert_eq(model.device(), KEYBOARD, "mouse input is keyboard")


func test_no_event_kind_switches_after_a_pad_press() -> void:
	var model: DeviceModel = _after_pad_press()
	assert_false(model.feed(_click(), 0.1), "a click")
	assert_false(model.feed(_motion(20.0), 0.2), "a big motion")
	assert_false(model.feed(_motion(20.0), 0.3), "the same motion later")
	assert_false(model.feed(_pad_button(), 0.6), "a pad press")
	assert_false(model.feed(_stick(1.0), 0.9), "a full stick")
	assert_eq(model.device(), KEYBOARD, "keyboard throughout")


func test_a_pad_disconnect_changes_nothing() -> void:
	var model: DeviceModel = _after_pad_press()
	assert_false(model.on_pad_disconnected(0.05), "a disconnect inside the old debounce")
	assert_false(model.on_pad_disconnected(5.0), "and later")
	assert_eq(model.device(), KEYBOARD, "keyboard")


func test_events_that_say_nothing_about_the_device_are_ignored() -> void:
	var action: InputEventAction = InputEventAction.new()
	action.action = &"ability"
	action.pressed = true
	assert_false(_model.feed(action, 0.0), "an action event")
	assert_false(_after_pad_press().feed(action, 5.0), "and again after a pad press")
