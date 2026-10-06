extends GutTest
## Input edges of the night fast-forward toggle (UAT G-02-14, owner decision 2026-10-07; diagnosis
## .planning/debug/fast-forward-toggle.md, probe A). One press is one toggle whatever its length or
## device: a long key hold toggles once, a press and release inside one frame toggles once, one
## pull of the left trigger toggles once, and a trigger hovering around its 0.5 deadzone does not
## toggle again until it has fallen below FastForwardController.REARM_STRENGTH (Godot applies no
## hysteresis to an action deadzone, so every upward crossing of 0.5 is a fresh press).

const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
const ACTION: StringName = &"fast_forward"
const SEED: int = 7
const HOLD_FRAMES: int = 20
const ONE_PULL: Array[float] = [0.6, 0.8, 1.0, 1.0, 0.7, 0.3, 0.0]
const HOVER: Array[float] = [0.45, 0.55, 0.45, 0.55, 0.45]

var _tuning: LoopTuning
var _changes: Array[Array] = []


func before_each() -> void:
	_tuning = load(TUNING_PATH)
	_changes = []
	Engine.time_scale = 1.0


func after_each() -> void:
	_feed_trigger(0.0)
	Engine.time_scale = 1.0
	E2eSupport.release_all_actions()


func _on_changed(active: bool, scale: float) -> void:
	_changes.append([active, scale])


## A shipped-map run whose night has started, with a controller owned by this test.
func _night_controller() -> FastForwardController:
	var ctx: RunContext = RunContext.new(E2eSupport.shipped_prototype_map(), _tuning, SEED)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	var controller: FastForwardController = FastForwardController.new()
	add_child_autofree(controller)
	controller.bind_run(ctx, null)
	controller.changed.connect(_on_changed)
	return controller


func _feed_trigger(value: float) -> void:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.device = 0
	event.axis = JOY_AXIS_TRIGGER_LEFT
	event.axis_value = value
	Input.parse_input_event(event)


## One trigger reading per process frame, like a real pad.
func _feed_trigger_values(values: Array[float]) -> void:
	for value: float in values:
		_feed_trigger(value)
		await wait_process_frames(1)


func test_a_long_key_hold_toggles_once() -> void:
	_night_controller()
	Input.action_press(ACTION)
	await wait_process_frames(HOLD_FRAMES)
	assert_eq(Engine.time_scale, 2.0, "switched on while the key is down")
	assert_eq(_changes, [[true, 2.0]] as Array[Array], "changed fired exactly once")
	Input.action_release(ACTION)
	await wait_process_frames(2)
	assert_eq(Engine.time_scale, 2.0, "and it is still on after the release")
	assert_eq(_changes, [[true, 2.0]] as Array[Array], "with no further change")


func test_a_press_and_release_inside_one_frame_toggles_once() -> void:
	_night_controller()
	await wait_process_frames(1)
	Input.action_press(ACTION)
	Input.action_release(ACTION)
	await wait_process_frames(2)
	assert_eq(Engine.time_scale, 2.0, "a sub-frame tap switches it on")
	assert_eq(_changes, [[true, 2.0]] as Array[Array], "exactly once")


func test_one_trigger_pull_toggles_once() -> void:
	_night_controller()
	await _feed_trigger_values(ONE_PULL)
	assert_eq(Engine.time_scale, 2.0, "one pull switches it on")
	assert_eq(_changes, [[true, 2.0]] as Array[Array], "and only once, however long the pull")


func test_a_trigger_hovering_at_its_deadzone_does_not_toggle_again() -> void:
	_night_controller()
	await _feed_trigger_values([0.6])
	assert_eq(_changes, [[true, 2.0]] as Array[Array], "the first pull switches it on")
	await _feed_trigger_values(HOVER)
	assert_eq(Engine.time_scale, 2.0, "hovering never fell below the re-arm strength")
	assert_eq(_changes, [[true, 2.0]] as Array[Array], "so nothing toggled again")
	await _feed_trigger_values([0.0, 0.9])
	assert_eq(Engine.time_scale, 1.0, "a full release and a fresh pull switches it off")
	assert_eq(_changes, [[true, 2.0], [false, 1.0]] as Array[Array], "two changes in all")


func test_the_rearm_strength_lies_between_zero_and_the_action_deadzone() -> void:
	var deadzone: float = InputMap.action_get_deadzone(ACTION)
	assert_gt(FastForwardController.REARM_STRENGTH, 0.0, "above a resting trigger")
	assert_lt(FastForwardController.REARM_STRENGTH, deadzone, "below the deadzone")
