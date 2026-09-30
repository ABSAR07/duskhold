extends GutTest
## D-11 / D-12 / BLDG-06 on the real scene: the day ends only through the hold-to-confirm
## start_night input, a placeholder night with its own mood and banner follows, then dawn and a
## new day. Every duration is read from loop_tuning.tres.

const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const ACTION: StringName = &"start_night"
const RICH_GOLD: int = 20
const SLOW_DRIP_S: float = 1.0
const WAIT_SLACK_S: float = 3.0
const HOUSE_SPOT: StringName = &"house_1"
const PAYING_SPOT: StringName = &"house_2"
const NEAR_OFFSET := Vector3(0.5, 0.0, 0.0)
const NIGHT_BANNER := "Night 1 — no enemies yet"
## A partial hold is this share of start_night_hold_seconds, so it stays short of the full hold
## whatever the tuning says.
const PARTIAL_HOLD_FRACTION: float = 0.3
## Ticks the sim this far past the end of a phase to be sure it has ended.
const PAST_END_S: float = 0.1
const OVERSHOOT_S: float = 0.3
const SETTLE_SLACK_S: float = 0.3

var _tuning: LoopTuning
var _saved_events: Array[InputEvent] = []


func before_each() -> void:
	_tuning = load(TUNING)
	_saved_events = InputMap.action_get_events(ACTION)


func after_each() -> void:
	E2eSupport.release_all_actions()
	InputMap.action_erase_events(ACTION)
	for event: InputEvent in _saved_events:
		InputMap.action_add_event(ACTION, event)


func _hud(map_root: MapRoot) -> Node:
	return map_root.get_node("HUD")


func _prompt(map_root: MapRoot) -> Label:
	return _hud(map_root).get_node_or_null("%StartNightPrompt") as Label


func _fill(map_root: MapRoot) -> ProgressBar:
	return _hud(map_root).get_node_or_null("%StartNightFill") as ProgressBar


func _banner(map_root: MapRoot) -> Label:
	return _hud(map_root).get_node_or_null("%PhaseBanner") as Label


func _gold_label(map_root: MapRoot) -> Label:
	return _hud(map_root).get_node_or_null("%GoldLabel") as Label


func _night_hold(map_root: MapRoot) -> StartNightHoldController:
	return map_root.find_child("StartNightHold", true, false) as StartNightHoldController


func _lighting(map_root: MapRoot) -> DayNightLighting:
	return map_root.find_child("Lighting", true, false) as DayNightLighting


func _spot_label(map_root: MapRoot) -> Node3D:
	return map_root.find_child("SpotLabel", true, false) as Node3D


func _sun(map_root: MapRoot) -> DirectionalLight3D:
	return map_root.find_child("Sun", true, false) as DirectionalLight3D


func _environment(map_root: MapRoot) -> Environment:
	return (map_root.find_child("WorldEnvironment", true, false) as WorldEnvironment).environment


func _in_phase(ctx: RunContext, phase: RunManager.RunPhase) -> bool:
	return ctx.run_manager.get_phase() == phase


func _start_night_now(ctx: RunContext) -> void:
	assert_eq(
		ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "the night is started"
	)


func test_a_tap_fills_the_prompt_but_releasing_early_keeps_the_day() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var ctx: RunContext = map_root.get_context()
	var night_hold: StartNightHoldController = _night_hold(map_root)
	var fill: ProgressBar = _fill(map_root)
	assert_not_null(night_hold, "the map has a StartNightHold node")
	assert_not_null(fill, "the HUD has a start-night fill bar")
	if night_hold == null or fill == null:
		return

	Input.action_press(ACTION)
	await wait_seconds(_tuning.start_night_hold_seconds * PARTIAL_HOLD_FRACTION)
	assert_gt(night_hold.get_ratio(), 0.0, "the ratio fills while held")
	assert_lt(night_hold.get_ratio(), 1.0, "but a short hold is not enough")
	assert_gt(fill.value, 0.0, "the bar fills while held")
	Input.action_release(ACTION)
	await wait_process_frames(2)

	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAY, "still day")
	assert_eq(night_hold.get_ratio(), 0.0, "the ratio reset on release")
	assert_eq(fill.value, 0.0, "the bar reset on release")


func test_a_full_hold_starts_the_night_with_its_banner_and_mood() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var ctx: RunContext = map_root.get_context()
	var night_hold: StartNightHoldController = _night_hold(map_root)
	var lighting: DayNightLighting = _lighting(map_root)
	var prompt: Label = _prompt(map_root)
	var banner: Label = _banner(map_root)
	var fill: ProgressBar = _fill(map_root)
	var spot_label: Node3D = _spot_label(map_root)
	assert_not_null(night_hold, "the map has a StartNightHold node")
	assert_not_null(lighting, "the Lighting node runs DayNightLighting")
	assert_not_null(prompt, "the HUD has a start-night prompt")
	assert_not_null(banner, "the HUD has a phase banner")
	assert_not_null(fill, "the HUD has a start-night fill bar")
	assert_not_null(spot_label, "the map has a spot label")
	if (
		night_hold == null
		or lighting == null
		or prompt == null
		or banner == null
		or fill == null
		or spot_label == null
	):
		return
	E2eSupport.teleport_king(map_root, ctx.buildings.get_spot(HOUSE_SPOT).position + NEAR_OFFSET)
	await wait_process_frames(2)
	assert_true(spot_label.visible, "the spot label shows by day next to a plot")
	assert_true(prompt.visible, "the prompt shows by day")
	assert_false(banner.visible, "no banner by day")
	assert_eq(lighting.get_mood(), &"day", "day mood by day")
	watch_signals(night_hold)

	await E2eSupport.hold_action_seconds(
		self, ACTION, _tuning.start_night_hold_seconds + OVERSHOOT_S
	)
	await wait_process_frames(2)

	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.NIGHT, "the night began")
	assert_signal_emit_count(night_hold, "night_requested", 1, "requested exactly once")
	assert_eq(ctx.run_manager.get_night_number(), 1, "one night started, not several")
	assert_true(banner.visible, "the banner shows at night")
	assert_eq(banner.text, NIGHT_BANNER, "the banner text")
	assert_eq(lighting.get_mood(), &"night", "night mood")
	assert_false(spot_label.visible, "the spot label is hidden at night")
	assert_false(prompt.visible, "the start-night prompt is hidden at night")
	assert_false(fill.visible, "and so is its fill bar")


func test_the_night_hands_back_to_a_new_day_through_dawn() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var ctx: RunContext = map_root.get_context()
	var lighting: DayNightLighting = _lighting(map_root)
	var prompt: Label = _prompt(map_root)
	var banner: Label = _banner(map_root)
	var gold_label: Label = _gold_label(map_root)
	assert_not_null(lighting, "the Lighting node runs DayNightLighting")
	assert_not_null(prompt, "the HUD has a start-night prompt")
	assert_not_null(banner, "the HUD has a phase banner")
	if lighting == null or prompt == null or banner == null:
		return
	assert_string_contains(prompt.text, "Night 1", "the prompt names the coming night")
	_start_night_now(ctx)

	var dawn: bool = await E2eSupport.wait_until(
		self,
		_in_phase.bind(ctx, RunManager.RunPhase.DAWN),
		_tuning.placeholder_night_seconds + WAIT_SLACK_S
	)
	assert_true(dawn, "dawn arrived after the night")
	assert_eq(lighting.get_mood(), &"dawn", "dawn mood")
	assert_false(banner.visible, "the banner is gone at dawn")

	var day: bool = await E2eSupport.wait_until(
		self, _in_phase.bind(ctx, RunManager.RunPhase.DAY), _tuning.dawn_seconds + WAIT_SLACK_S
	)
	assert_true(day, "a new day arrived after dawn")
	assert_eq(ctx.run_manager.get_day_number(), 2, "day two")
	assert_eq(lighting.get_mood(), &"day", "day mood again")
	assert_true(prompt.visible, "the prompt is back")
	assert_string_contains(prompt.text, "Night 2", "the prompt names the next night")
	assert_eq(gold_label.text, "Gold: %d" % ctx.economy.get_gold(), "HUD gold matches the ledger")


func test_the_sun_settles_on_the_night_mood_and_back() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var ctx: RunContext = map_root.get_context()
	var lighting: DayNightLighting = _lighting(map_root)
	assert_not_null(lighting, "the Lighting node runs DayNightLighting")
	if lighting == null:
		return
	var sun: DirectionalLight3D = _sun(map_root)
	var environment: Environment = _environment(map_root)
	assert_almost_eq(sun.light_energy, lighting.day_sun_energy, 0.01, "day sun by day")
	_start_night_now(ctx)

	await wait_seconds(lighting.transition_seconds + SETTLE_SLACK_S)

	assert_almost_eq(sun.light_energy, lighting.night_sun_energy, 0.01, "night sun energy")
	assert_almost_eq(sun.light_color.b, lighting.night_sun_color.b, 0.01, "night sun colour")
	assert_almost_eq(
		environment.ambient_light_energy, lighting.night_ambient_energy, 0.01, "night ambient"
	)


func test_a_fresh_run_starts_in_day_lighting_even_after_a_night() -> void:
	var first: MapRoot = await E2eSupport.spawn_map(self)
	var lighting: DayNightLighting = _lighting(first)
	assert_not_null(lighting, "the Lighting node runs DayNightLighting")
	if lighting == null:
		return
	var day_ambient: float = lighting.day_ambient_energy
	var day_sun: float = lighting.day_sun_energy
	_start_night_now(first.get_context())
	await wait_seconds(lighting.transition_seconds + SETTLE_SLACK_S)
	first.queue_free()
	await wait_process_frames(2)

	var second: MapRoot = await E2eSupport.spawn_map(self)

	assert_almost_eq(
		_environment(second).ambient_light_energy,
		day_ambient,
		0.01,
		"the shared scene resource was not left in night lighting"
	)
	assert_almost_eq(_sun(second).light_energy, day_sun, 0.01, "day sun")


func test_a_build_hold_is_cancelled_when_the_night_starts() -> void:
	var map: MapConfig = (load(PROTOTYPE_MAP) as MapConfig).duplicate(true)
	map.starting_gold = RICH_GOLD
	var slow: LoopTuning = _tuning.duplicate(true)
	slow.coin_drip_interval = SLOW_DRIP_S
	var map_root: MapRoot = await E2eSupport.spawn_map(self, map, slow)
	var ctx: RunContext = map_root.get_context()
	var hold: BuildHoldController = map_root.get_build_hold()
	# A House already standing on another plot, so dawn has income to pay and the gold check below
	# can tell a payout bug from no payout at all.
	assert_eq(ctx.commands.submit(BuildIntent.new(PAYING_SPOT)), CommandProcessor.OK, "a House")
	var gold_before: int = ctx.economy.get_gold()
	var dawn_income: int = 0
	for amount: int in ctx.buildings.dawn_income_by_spot().values():
		dawn_income += amount
	assert_gt(dawn_income, 0, "the standing House pays at dawn")
	E2eSupport.teleport_king(map_root, ctx.buildings.get_spot(HOUSE_SPOT).position + NEAR_OFFSET)
	await wait_process_frames(2)
	watch_signals(hold)
	Input.action_press(&"action_build")
	var dripped: bool = await E2eSupport.wait_until(
		self, func() -> bool: return hold.get_coins_paid() >= 1, WAIT_SLACK_S + SLOW_DRIP_S
	)
	assert_true(dripped, "a coin was in flight")

	_start_night_now(ctx)
	await wait_process_frames(3)

	assert_signal_emitted(hold, "hold_cancelled", "the hold was cancelled at once")
	assert_false(hold.is_holding(), "the hold ended")
	ctx.run_manager.tick(slow.placeholder_night_seconds + PAST_END_S)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "dawn reached")
	assert_eq(ctx.economy.get_gold(), gold_before + dawn_income, "only dawn income moved gold")
	assert_null(ctx.buildings.get_instance(HOUSE_SPOT), "nothing was built on the plot")
	Input.action_release(&"action_build")


func test_holding_start_night_outside_the_day_does_nothing() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var ctx: RunContext = map_root.get_context()
	var night_hold: StartNightHoldController = _night_hold(map_root)
	var fill: ProgressBar = _fill(map_root)
	assert_not_null(night_hold, "the map has a StartNightHold node")
	assert_not_null(fill, "the HUD has a start-night fill bar")
	if night_hold == null or fill == null:
		return
	_start_night_now(ctx)
	watch_signals(night_hold)
	watch_signals(ctx.events)

	Input.action_press(ACTION)
	await wait_seconds(_tuning.start_night_hold_seconds * PARTIAL_HOLD_FRACTION)

	assert_eq(night_hold.get_ratio(), 0.0, "no fill outside the day")
	assert_eq(fill.value, 0.0, "the bar stays empty")
	assert_signal_not_emitted(night_hold, "night_requested")
	assert_signal_not_emitted(ctx.events, "command_rejected")
	assert_eq(ctx.run_manager.get_night_number(), 1, "still the first night")
	Input.action_release(ACTION)


func test_a_key_still_held_when_the_day_returns_needs_a_fresh_press() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var ctx: RunContext = map_root.get_context()
	var night_hold: StartNightHoldController = _night_hold(map_root)
	assert_not_null(night_hold, "the map has a StartNightHold node")
	if night_hold == null:
		return
	_start_night_now(ctx)
	Input.action_press(ACTION)
	await wait_process_frames(2)
	ctx.run_manager.tick(_tuning.placeholder_night_seconds + PAST_END_S)
	ctx.run_manager.tick(_tuning.dawn_seconds)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAY, "the day is back")
	watch_signals(night_hold)

	await wait_seconds(_tuning.start_night_hold_seconds + OVERSHOOT_S)

	assert_signal_not_emitted(night_hold, "night_requested")
	assert_eq(ctx.run_manager.get_night_number(), 1, "no second night began by itself")
	Input.action_release(ACTION)


func test_the_prompt_names_the_default_start_night_bindings() -> void:
	# The project.godot defaults, set here so no rebind left by another test can change the text.
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_N
	var button: InputEventJoypadButton = InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_Y
	InputMap.action_erase_events(ACTION)
	InputMap.action_add_event(ACTION, key)
	InputMap.action_add_event(ACTION, button)
	var map_root: MapRoot = await E2eSupport.spawn_map(self, null, _tuning)

	assert_eq(
		_prompt(map_root).text, "Hold N / (Y) to start Night 1", "keyboard key, then gamepad button"
	)


func test_the_prompt_names_the_key_by_the_layout_label_not_the_qwerty_position() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, null, _tuning)
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_N
	key.ctrl_pressed = true
	# A layout that prints B where QWERTY has N (headless Godot cannot switch layouts).
	var hud: Hud = _hud(map_root) as Hud
	hud.physical_label_resolver = func(physical: int) -> int:
		return KEY_B if physical == KEY_N else physical

	var text: String = await _prompt_after_rebind(map_root, key)

	assert_eq(text, "Hold Ctrl+B to start Night 1", "the cap's label, modifier kept")


func test_the_prompt_follows_a_runtime_rebind_of_start_night() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, null, _tuning)
	var rebound: InputEventKey = InputEventKey.new()
	rebound.physical_keycode = KEY_M
	InputMap.action_erase_events(ACTION)
	InputMap.action_add_event(ACTION, rebound)

	await wait_process_frames(2)

	assert_eq(_prompt(map_root).text, "Hold M to start Night 1", "the new key is named, no pad")


func test_the_prompt_follows_a_bound_key_edited_in_place() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, null, _tuning)
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_N
	InputMap.action_erase_events(ACTION)
	InputMap.action_add_event(ACTION, key)
	await wait_process_frames(2)
	assert_eq(_prompt(map_root).text, "Hold N to start Night 1", "the first key is named")

	# The same event object, edited: the InputMap's event list still holds the identical instance.
	key.physical_keycode = KEY_M
	await wait_process_frames(2)

	assert_eq(_prompt(map_root).text, "Hold M to start Night 1", "the edit shows up in the prompt")


## Rebinds start_night to `event` alone and returns the prompt text once the HUD has noticed.
func _prompt_after_rebind(map_root: MapRoot, event: InputEvent) -> String:
	InputMap.action_erase_events(ACTION)
	InputMap.action_add_event(ACTION, event)
	await wait_process_frames(2)
	return _prompt(map_root).text


func test_the_prompt_names_a_trigger_or_mouse_button_binding() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, null, _tuning)
	var trigger: InputEventJoypadMotion = InputEventJoypadMotion.new()
	trigger.axis = JOY_AXIS_TRIGGER_RIGHT
	trigger.axis_value = 1.0
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_MIDDLE

	var stick_left: InputEventJoypadMotion = InputEventJoypadMotion.new()
	stick_left.axis = JOY_AXIS_LEFT_X
	stick_left.axis_value = -1.0
	var stick_right: InputEventJoypadMotion = InputEventJoypadMotion.new()
	stick_right.axis = JOY_AXIS_LEFT_X
	stick_right.axis_value = 1.0

	var trigger_text: String = await _prompt_after_rebind(map_root, trigger)
	var click_text: String = await _prompt_after_rebind(map_root, click)
	var left_text: String = await _prompt_after_rebind(map_root, stick_left)
	var right_text: String = await _prompt_after_rebind(map_root, stick_right)

	assert_eq(trigger_text, "Hold (RT) to start Night 1", "a trigger binding is named, not unbound")
	assert_eq(click_text, "Hold %s to start Night 1" % click.as_text(), "a mouse button is named")
	assert_eq(left_text, "Hold (Axis 0-) to start Night 1", "a stick pushed one way")
	assert_eq(right_text, "Hold (Axis 0+) to start Night 1", "and the other way reads differently")


func test_the_prompt_keeps_key_modifiers_and_skips_an_event_that_names_no_key() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, null, _tuning)
	var chord: InputEventKey = InputEventKey.new()
	chord.physical_keycode = KEY_N
	chord.ctrl_pressed = true
	var blank: InputEventKey = InputEventKey.new()

	var chord_text: String = await _prompt_after_rebind(map_root, chord)
	var blank_text: String = await _prompt_after_rebind(map_root, blank)

	assert_eq(chord_text, "Hold Ctrl+N to start Night 1", "the modifier is part of the hint")
	assert_eq(blank_text, "Hold (unbound) to start Night 1", "no stray separator or blank name")
