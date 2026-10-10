extends GutTest
## INPT-02 / D-24, T-03-17: the pure device rule. Every boundary is pinned on an injected clock: a
## stick at abs 0.5 switches and 0.49 does not, 8 px of mouse motion inside 0.25 s switches and 7 px
## or 8 px spread over a longer time does not, and a second switch inside 0.25 s of the last is
## ignored while one at 0.25 s applies.

const KEYBOARD: int = GlyphResolver.DEVICE_KEYBOARD
const PAD: int = GlyphResolver.DEVICE_PAD

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


## A model that is on the pad, its switch made at t = 0.
func _on_pad() -> DeviceModel:
	var model: DeviceModel = DeviceModel.new()
	assert_true(model.feed(_pad_button(), 0.0), "a pad press switches")
	return model


func test_the_constants_are_the_ui_spec_values() -> void:
	assert_eq(DeviceModel.SWITCH_MIN_INTERVAL_S, 0.25, "one switch per 0.25 s")
	assert_eq(DeviceModel.AXIS_THRESHOLD, 0.5, "axis threshold")
	assert_eq(DeviceModel.MOTION_THRESHOLD_PX, 8.0, "mouse motion threshold")


func test_it_starts_on_the_keyboard_and_a_key_there_changes_nothing() -> void:
	assert_eq(_model.device(), KEYBOARD, "starts on keyboard")
	assert_false(_model.feed(_key(), 0.0), "a key on the keyboard is no switch")
	assert_eq(_model.device(), KEYBOARD, "still keyboard")


func test_a_pad_button_press_switches_to_the_pad() -> void:
	assert_true(_model.feed(_pad_button(), 0.0), "the switch is reported")
	assert_eq(_model.device(), PAD, "now the pad")
	assert_false(_model.feed(_pad_button(), 1.0), "a second pad press is no switch")


func test_a_release_or_an_echo_counts_for_nothing() -> void:
	assert_false(_model.feed(_pad_button(false), 0.0), "a pad button release")
	assert_false(_model.feed(_key(false), 0.0), "a key release")
	var pad: DeviceModel = _on_pad()
	assert_false(pad.feed(_key(true, true), 1.0), "a key echo")
	assert_false(pad.feed(_key(false), 1.0), "a key release")
	assert_false(pad.feed(_click(false), 1.0), "a mouse button release")
	assert_eq(pad.device(), PAD, "the pad stays")


func test_a_key_inside_the_debounce_is_ignored_and_one_at_a_quarter_second_applies() -> void:
	var model: DeviceModel = _on_pad()
	assert_false(model.feed(_key(), 0.1), "0.1 s after the switch is ignored")
	assert_eq(model.device(), PAD, "still the pad")
	assert_false(model.feed(_key(), 0.249), "just under 0.25 s is ignored")
	assert_true(model.feed(_key(), 0.25), "0.25 s applies")
	assert_eq(model.device(), KEYBOARD, "back on the keyboard")


func test_a_stick_at_half_travel_switches_and_just_under_does_not() -> void:
	assert_false(_model.feed(_stick(0.49), 1.0), "0.49 is no switch")
	assert_eq(_model.device(), KEYBOARD, "still keyboard")
	assert_true(_model.feed(_stick(0.5), 1.0), "0.5 switches")
	assert_eq(_model.device(), PAD, "the pad")
	var other: DeviceModel = DeviceModel.new()
	assert_false(other.feed(_stick(-0.49), 1.0), "-0.49 is no switch")
	assert_true(other.feed(_stick(-0.5), 1.0), "-0.5 switches, the direction does not matter")


func test_mouse_motion_of_eight_pixels_inside_the_window_switches_and_seven_does_not() -> void:
	var seven: DeviceModel = _on_pad()
	assert_false(seven.feed(_motion(7.0), 1.0), "7 px is no switch")
	assert_eq(seven.device(), PAD, "still the pad")
	var eight: DeviceModel = _on_pad()
	assert_true(eight.feed(_motion(8.0), 1.0), "8 px switches")
	assert_eq(eight.device(), KEYBOARD, "keyboard")


func test_motion_adds_up_inside_a_quarter_second_but_not_across_it() -> void:
	var spread: DeviceModel = _on_pad()
	assert_false(spread.feed(_motion(4.0), 1.0), "the first 4 px")
	assert_false(spread.feed(_motion(4.0), 1.3), "the next 4 px, 0.3 s later, do not add up")
	assert_eq(spread.device(), PAD, "the pad stays")
	var together: DeviceModel = _on_pad()
	assert_false(together.feed(_motion(4.0), 1.0), "the first 4 px")
	assert_true(together.feed(_motion(4.0), 1.2), "4 more inside the window switch")
	assert_eq(together.device(), KEYBOARD, "keyboard")


func test_a_mouse_button_press_counts_as_the_keyboard() -> void:
	var model: DeviceModel = _on_pad()
	assert_true(model.feed(_click(), 1.0), "a click switches")
	assert_eq(model.device(), KEYBOARD, "mouse input is keyboard")


func test_the_debounce_covers_every_kind_of_switch() -> void:
	var model: DeviceModel = _on_pad()
	assert_false(model.feed(_click(), 0.1), "a click inside the debounce")
	assert_false(model.feed(_motion(20.0), 0.2), "a big motion inside the debounce")
	assert_true(model.feed(_motion(20.0), 0.3), "the same motion later applies")


func test_a_pad_disconnect_while_on_the_pad_falls_back_to_the_keyboard() -> void:
	var model: DeviceModel = _on_pad()
	assert_true(model.on_pad_disconnected(0.05), "the fallback is not held up by the debounce")
	assert_eq(model.device(), KEYBOARD, "keyboard")
	assert_false(model.on_pad_disconnected(5.0), "a disconnect on the keyboard changes nothing")


func test_events_that_say_nothing_about_the_device_are_ignored() -> void:
	var action: InputEventAction = InputEventAction.new()
	action.action = &"ability"
	action.pressed = true
	assert_false(_model.feed(action, 0.0), "an action event")
	assert_false(_on_pad().feed(action, 5.0), "and again on the pad")
