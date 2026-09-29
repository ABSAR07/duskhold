class_name StartNightHoldController
extends Node
## Hold-to-confirm start-night input (D-11). There is no day timer: the day ends only when the
## player holds the dedicated start_night action for start_night_hold_seconds, anywhere on the map.
## It is a separate action from the build key, so the two never conflict. When the hold fills, one
## StartNightIntent goes to the command gate. Releasing early resets the fill, input is ignored
## outside the day, and a key still down when the day returns needs a fresh press.

signal progress_changed(ratio: float)
signal night_requested

const ACTION: StringName = &"start_night"
const MIN_HOLD_SECONDS: float = 0.001

var _ctx: RunContext
var _held: float = 0.0
var _ratio: float = 0.0
var _await_release: bool = false


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	_ctx = ctx


## Fill of the hold, from 0.0 to 1.0.
func get_ratio() -> float:
	return _ratio


func _process(delta: float) -> void:
	if _ctx == null:
		return
	var pressed: bool = Input.is_action_pressed(ACTION)
	if not _ctx.run_manager.is_build_allowed():
		_set_held(0.0)
		_await_release = pressed
		return
	if not pressed:
		_await_release = false
		_set_held(0.0)
		return
	if _await_release:
		return
	_set_held(_held + delta)
	if _held >= maxf(_ctx.tuning.start_night_hold_seconds, MIN_HOLD_SECONDS):
		_confirm()


func _confirm() -> void:
	_await_release = true
	_set_held(0.0)
	if _ctx.commands.submit(StartNightIntent.new()) == CommandProcessor.OK:
		night_requested.emit()


func _set_held(seconds: float) -> void:
	_held = seconds
	var seconds_needed: float = maxf(_ctx.tuning.start_night_hold_seconds, MIN_HOLD_SECONDS)
	var ratio: float = clampf(_held / seconds_needed, 0.0, 1.0)
	if is_equal_approx(ratio, _ratio):
		return
	_ratio = ratio
	progress_changed.emit(_ratio)
