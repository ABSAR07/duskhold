class_name Hud
extends CanvasLayer
## Gold readout, the start-night prompt and the night banner. Gold is the only currency the HUD
## shows and its label is always visible (ECON-01).
## While a hold is dripping, the readout shows the gold the player would have left
## (Economy gold minus the coins in flight). This is display only: Economy stays
## all-or-nothing and only changes when a BuildIntent is accepted (D-06).
## At dawn the Economy is credited at once, but the readout stays behind by the gold whose coins
## are still flying in, and ticks up as each one lands (D-12).

## Player-facing copy. The night banner is Phase-1 placeholder text: Phase 2 replaces it once
## waves exist.
const START_NIGHT_PROMPT := "Hold %s to start Night %d"
const NIGHT_BANNER := "Night %d — no enemies yet"
const UNBOUND_HINT := "(unbound)"
## Gamepad button names shown in the start-night hint, by JoyButton index. These are Xbox-style
## labels: on a PlayStation or Switch pad they are wrong (button 3 reads "Y", not "Triangle"/"X").
## Known Phase-1 limitation; later, key the names off Input.get_joy_name.
const PAD_BUTTON_NAMES: Dictionary = {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Back",
	JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
}
## Gamepad trigger names shown in the start-night hint, by JoyAxis index. Xbox-style like the
## buttons above, with the same limitation.
const AXIS_NAMES: Dictionary = {
	JOY_AXIS_TRIGGER_LEFT: "LT",
	JOY_AXIS_TRIGGER_RIGHT: "RT",
}

## Maps a physical keycode to the keycode the current keyboard layout prints on that key. A
## Callable so a test can stand in for a non-QWERTY layout, which headless Godot cannot switch to.
var physical_label_resolver: Callable = _layout_label

var _ctx: RunContext
var _pending: int = 0
var _payout_pending: int = 0
## The hint the prompt text was built from, to notice a runtime rebind.
var _hint: String = ""

@onready var _gold_label: Label = %GoldLabel
@onready var _start_night_prompt: Label = %StartNightPrompt
@onready var _start_night_fill: ProgressBar = %StartNightFill
@onready var _phase_banner: Label = %PhaseBanner
@onready var _payout_vfx: DawnPayoutVfx = %DawnPayoutVfx


## Binds the HUD to one run. MapRoot calls this once; a repeat call is ignored so no signal is
## ever connected twice.
func bind_run(ctx: RunContext, map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	var hold: BuildHoldController = map_root.get_build_hold()
	hold.hold_progress.connect(_on_hold_progress)
	hold.hold_cancelled.connect(_on_hold_cancelled)
	hold.hold_completed.connect(_on_hold_completed)
	ctx.events.gold_changed.connect(_on_gold_changed)
	ctx.events.phase_changed.connect(_on_phase_changed)
	ctx.events.night_started.connect(_on_night_started)
	ctx.events.day_started.connect(_on_day_started)
	_payout_vfx.payout_started.connect(_on_payout_started)
	_payout_vfx.coin_landed.connect(_on_coin_landed)
	var start_night_hold: StartNightHoldController = (
		map_root.find_child("StartNightHold", true, false) as StartNightHoldController
	)
	if start_night_hold != null:
		start_night_hold.progress_changed.connect(_on_start_night_progress)
	_refresh()
	_refresh_loop()


## The hint is derived from the bound events, so a changed hint is the trigger to rebuild the prompt
## text. Comparing the text, not the event objects, also catches an event edited in place. Nothing
## is rebuilt while the bindings are unchanged.
func _process(_delta: float) -> void:
	if _ctx == null or not _start_night_prompt.visible:
		return
	if _start_night_hint() != _hint:
		_refresh_prompt_text()


func _on_hold_progress(_spot_id: StringName, coins_paid: int, _cost: int) -> void:
	_pending = coins_paid
	_refresh()


func _on_hold_cancelled(_spot_id: StringName, _coins_refunded: int) -> void:
	_pending = 0
	_refresh()


func _on_hold_completed(_spot_id: StringName) -> void:
	_pending = 0
	_refresh()


func _on_gold_changed(_new_amount: int, _delta: int) -> void:
	_refresh()


## The VFX announces the gold its coins carry, so the readout lags by exactly what will land.
func _on_payout_started(carried_total: int) -> void:
	_payout_pending = maxi(carried_total, 0)
	_refresh()


func _on_coin_landed(amount: int) -> void:
	_payout_pending = maxi(_payout_pending - amount, 0)
	_refresh()


func _on_phase_changed(old_phase: int, _new_phase: int) -> void:
	# Backstop: whatever a coin left unreleased, the readout is back on the ledger once dawn ends.
	if old_phase == RunManager.RunPhase.DAWN and _payout_pending != 0:
		_payout_pending = 0
		_refresh()
	_refresh_loop()


func _on_night_started(_night_number: int) -> void:
	_refresh_loop()


func _on_day_started(_day_number: int) -> void:
	_refresh_loop()


func _on_start_night_progress(ratio: float) -> void:
	_start_night_fill.value = ratio


## The prompt shows only by day (D-11); the banner only during the night itself (D-12).
func _refresh_loop() -> void:
	var run_manager: RunManager = _ctx.run_manager
	var by_day: bool = run_manager.get_phase() == RunManager.RunPhase.DAY
	_start_night_prompt.visible = by_day
	_start_night_fill.visible = by_day
	if not by_day:
		_start_night_fill.value = 0.0
	_refresh_prompt_text()
	var at_night: bool = (
		run_manager.get_phase() == RunManager.RunPhase.NIGHT_TRANSITION
		or run_manager.get_phase() == RunManager.RunPhase.NIGHT
	)
	_phase_banner.visible = at_night
	_phase_banner.text = NIGHT_BANNER % run_manager.get_night_number()


func _refresh_prompt_text() -> void:
	_hint = _start_night_hint()
	_start_night_prompt.text = START_NIGHT_PROMPT % [_hint, _ctx.run_manager.get_night_number() + 1]


## The start-night keys as they are bound right now, e.g. "N / (Y)": keyboard keys first, gamepad
## buttons in parentheses. Read from the InputMap so a runtime rebind shows up in the prompt.
func _start_night_hint() -> String:
	var keys: PackedStringArray = PackedStringArray()
	var pad: PackedStringArray = PackedStringArray()
	for event: InputEvent in InputMap.action_get_events(&"start_night"):
		if event is InputEventKey:
			# Modifiers are part of the text ("Ctrl+N"), so the prompt names what actually triggers it.
			var key_text: String = _key_text(event as InputEventKey)
			if not key_text.is_empty():
				keys.append(key_text)
		elif event is InputEventMouseButton:
			keys.append(event.as_text())
		elif event is InputEventJoypadButton:
			var button: int = (event as InputEventJoypadButton).button_index
			pad.append("(%s)" % PAD_BUTTON_NAMES.get(button, "Pad %d" % button))
		elif event is InputEventJoypadMotion:
			var axis: int = (event as InputEventJoypadMotion).axis
			pad.append("(%s)" % AXIS_NAMES.get(axis, "Axis %d" % axis))
	var parts: PackedStringArray = keys + pad
	if parts.is_empty():
		return UNBOUND_HINT
	return " / ".join(parts)


## The default resolver. The headless display server has no keyboard layout (its call errors), so
## a physical key stays as it is there.
func _layout_label(physical: int) -> int:
	if DisplayServer.get_name() == "headless":
		return physical
	return DisplayServer.keyboard_get_label_from_physical(physical as Key)


## A key event's text, with modifiers; empty when it names no key at all. A physical key is named
## by the label the player's layout prints on that keycap, not by its US-QWERTY position, so the
## hint stays right on Dvorak or AZERTY.
func _key_text(key_event: InputEventKey) -> String:
	if key_event.physical_keycode != KEY_NONE:
		var label_key: int = physical_label_resolver.call(key_event.physical_keycode)
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


func _refresh() -> void:
	_gold_label.text = "Gold: %d" % maxi(_ctx.economy.get_gold() - _pending - _payout_pending, 0)
