class_name LastDeviceTracker
extends Node
## Gamepad support is unsupported since 2026-10-16 (owner decision); kept as shipped, not extended.
## INPT-02 / D-24: the one place that knows which device the player touched last. It feeds every
## input event to a DeviceModel and emits `device_changed` on an applied switch; every PromptGlyph
## listens to that one signal, so all prompts switch in the same frame. While the pad is the active
## device the mouse cursor is hidden, and it comes back with the keyboard (and when the tracker
## leaves the tree, so a closed run never leaves the cursor hidden). It starts on keyboard, and a
## disconnect of the pad that was in use falls back to it.
## Device detection lives here, in the input layer; the simulation never reads it. It never marks an
## event handled, so it cannot steal input from any other node. It is the last child of the map so
## that it is also the first to see each event, before a controller that handles one.
## Since 2026-10-16 DeviceModel never reports the pad, so `device_changed` stays silent and the
## cursor stays shown.

## `device` is GlyphResolver.DEVICE_KEYBOARD or DEVICE_PAD.
signal device_changed(device: int)

## Seconds on the clock the model debounces against. Presentation time is fine here (the
## simulation scan covers res://simulation only); a test replaces it to step time by hand.
var time_source: Callable = _real_seconds

var _model: DeviceModel = DeviceModel.new()
var _pad_id: int = -1
var _bound: bool = false
var _cursor_hidden: bool = false


## Joins the run: watches pad connections so a disconnect of the active pad falls back to the
## keyboard. A repeat call is ignored.
func bind_run(_ctx: RunContext, _map_root: MapRoot) -> void:
	if _bound:
		return
	_bound = true
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


## GlyphResolver.DEVICE_KEYBOARD or DEVICE_PAD.
func device() -> int:
	return _model.device()


## True while the tracker has asked for the mouse cursor to be hidden (the pad is active). The
## engine mode itself cannot be read back under the headless display server, so tests read this.
func cursor_hidden() -> bool:
	return _cursor_hidden


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_pad_id = event.device
	var now: float = time_source.call()
	if _model.feed(event, now):
		_apply()


func _exit_tree() -> void:
	_cursor_hidden = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _apply() -> void:
	_cursor_hidden = _model.device() == GlyphResolver.DEVICE_PAD
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if _cursor_hidden else Input.MOUSE_MODE_VISIBLE
	device_changed.emit(_model.device())


func _on_joy_connection_changed(joy_id: int, connected: bool) -> void:
	if connected or joy_id != _pad_id:
		return
	var now: float = time_source.call()
	if _model.on_pad_disconnected(now):
		_apply()


func _real_seconds() -> float:
	return Time.get_ticks_msec() / 1000.0
