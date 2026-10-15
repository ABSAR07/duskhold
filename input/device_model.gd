class_name DeviceModel
extends RefCounted
## Gamepad support is unsupported since 2026-10-16 (owner decision); kept as shipped, not extended.
## INPT-02 / D-24: which device the player touched last, as a pure rule with an injected clock so
## it is testable without a window. A key press, any mouse button or at least 8 px of mouse motion
## inside 0.25 s means keyboard; a pad button, or a stick or trigger at abs(value) >= 0.5, means
## pad. A switch happens at most once per 0.25 s, so a drifting stick or a bumped mouse cannot make
## the prompts flicker (T-03-17). It starts on keyboard and falls back to it when the pad that was
## in use disconnects. Presentation only: the simulation never reads it.

const SWITCH_MIN_INTERVAL_S: float = 0.25
## Above the 0.2 deadzone of the cursor actions, so a resting stick never counts.
const AXIS_THRESHOLD: float = 0.5
const MOTION_THRESHOLD_PX: float = 8.0
## Mouse motion counts only when it adds up to the threshold inside this window.
const MOTION_WINDOW_S: float = 0.25
## While false, a pad event is still classified by `_device_of` but never applied, so `device()`
## stays GlyphResolver.DEVICE_KEYBOARD whatever the last event was, and every PromptGlyph and the
## CommandHints strip keep their keyboard glyphs while a pad drives the game. Pad input itself
## (PadChords, PadCursorController, the pad bindings in project.godot) is untouched. True restores
## the shipped Phase 3 switching.
const PAD_PROMPTS_SUPPORTED: bool = false

var _device: int = GlyphResolver.DEVICE_KEYBOARD
var _last_switch_s: float = -INF
var _motion_px: float = 0.0
var _motion_start_s: float = -INF


## GlyphResolver.DEVICE_KEYBOARD or DEVICE_PAD. Always DEVICE_KEYBOARD while
## PAD_PROMPTS_SUPPORTED is false.
func device() -> int:
	return _device


## Feeds one input event at time `now_s`. True only when the event switched the device.
func feed(event: InputEvent, now_s: float) -> bool:
	var wanted: int = _device_of(event, now_s)
	if wanted == GlyphResolver.DEVICE_PAD and not PAD_PROMPTS_SUPPORTED:
		return false
	if wanted < 0 or wanted == _device:
		return false
	return _switch(wanted, now_s)


## The pad in use disconnected: back to the keyboard. True when that changed the device.
func on_pad_disconnected(now_s: float) -> bool:
	if _device != GlyphResolver.DEVICE_PAD:
		return false
	return _switch(GlyphResolver.DEVICE_KEYBOARD, now_s, true)


## The device an event points at, or -1 when it says nothing about the device.
func _device_of(event: InputEvent, now_s: float) -> int:
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		return GlyphResolver.DEVICE_KEYBOARD if key.pressed and not key.echo else -1
	if event is InputEventMouseButton:
		return GlyphResolver.DEVICE_KEYBOARD if (event as InputEventMouseButton).pressed else -1
	if event is InputEventMouseMotion:
		return _motion_device(event as InputEventMouseMotion, now_s)
	if event is InputEventJoypadButton:
		return GlyphResolver.DEVICE_PAD if (event as InputEventJoypadButton).pressed else -1
	if event is InputEventJoypadMotion:
		var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
		return GlyphResolver.DEVICE_PAD if absf(motion.axis_value) >= AXIS_THRESHOLD else -1
	return -1


## Adds the motion to the running total of the current window and answers keyboard once the total
## reaches the threshold. A window opens with the first motion and closes MOTION_WINDOW_S later.
func _motion_device(motion: InputEventMouseMotion, now_s: float) -> int:
	if now_s - _motion_start_s > MOTION_WINDOW_S:
		_motion_start_s = now_s
		_motion_px = 0.0
	_motion_px += motion.relative.length()
	if _motion_px >= MOTION_THRESHOLD_PX:
		return GlyphResolver.DEVICE_KEYBOARD
	return -1


## Applies a switch unless the last one was under SWITCH_MIN_INTERVAL_S ago (a forced one, the pad
## going away, always applies because the pad is no longer there to show).
func _switch(wanted: int, now_s: float, forced: bool = false) -> bool:
	if not forced and now_s - _last_switch_s < SWITCH_MIN_INTERVAL_S:
		return false
	_device = wanted
	_last_switch_s = now_s
	_motion_px = 0.0
	return true
