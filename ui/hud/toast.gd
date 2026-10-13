class_name Toast
extends Label
## UI-SPEC "Toast": one line of Body 22 text (white, outline 6, no panel) in the hint-strip slot,
## y 504..536 at 1280x720, below the protected centre. A toast fades in over 0.1 s, holds 1.2 s
## (1.5 s for an error) and fades out over 0.3 s; a newer toast replaces the one showing, so there
## is never more than one. `set_line` shows a persistent line in the same slot (the armed-point
## prompt of plan 03-07); a toast temporarily replaces the line and the line returns when it ends.
## Display only: it never touches the simulation. The controllers that have something to say (the
## command keys, the selection) declare a `feedback(text, is_error)` signal and the toast connects
## to every one of them when the run binds.

const SELECT_FIRST := "Select a squad first"
const CANT_GO_THERE := "Can't go there. Click a point on the visible ground."
const ARMED_ATTACK := "Click a point to attack-move"
const ARMED_PATROL := "Click a point to patrol"
const ARMED_PAD := "Aim with the right stick, release to confirm"
const GROUP_SAVED := "Group %d saved"
const GROUP_EMPTY := "Group %d is empty"
const QUEUE_CLOSED := "Nothing can be queued after Hold, Follow or Patrol"
const PATROL_FULL := "A patrol takes up to %d points"
const HOLD_SECONDS: float = 1.2
const ERROR_SECONDS: float = 1.5
const FADE_IN_SECONDS: float = 0.1
const FADE_OUT_SECONDS: float = 0.3

var _line: String = ""
var _toast_active: bool = false
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_show_line_or_nothing()


## Connects every `feedback` source under the map (the command keys and the selection controller)
## and every `prompt` source (the selection controller's armed-point line).
func bind_run(_ctx: RunContext, map_root: MapRoot) -> void:
	for node: Node in map_root.find_children("*", "", true, false):
		if node.has_signal(&"feedback"):
			node.connect(&"feedback", _on_feedback)
		if node.has_signal(&"prompt"):
			node.connect(&"prompt", _on_prompt)


## The error line for a squad order the command gate refused with `reason`, or an empty string when
## the reason has no player-facing copy (the controllers already check the ground and the
## selection, so only a closed queue reaches the player). Every controller that submits a squad
## order runs the result of `submit` through this.
static func refusal_text(reason: StringName) -> String:
	if reason == CommandProcessor.QUEUE_CLOSED:
		return QUEUE_CLOSED
	return ""


## Shows `message` for `seconds`, replacing any toast that is showing.
func show_toast(message: String, seconds: float = HOLD_SECONDS) -> void:
	_stop_tween()
	_toast_active = true
	text = message
	modulate.a = 0.0
	visible = true
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, FADE_IN_SECONDS)
	_tween.tween_interval(maxf(seconds, 0.0))
	_tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_SECONDS)
	_tween.tween_callback(_end_toast)


## An error holds a little longer than a plain toast.
func show_error(message: String) -> void:
	show_toast(message, ERROR_SECONDS)


## A persistent line in the slot until `clear_line`; a toast in progress is not interrupted.
func set_line(message: String) -> void:
	_line = message
	if not _toast_active:
		_show_line_or_nothing()


func clear_line() -> void:
	_line = ""
	if not _toast_active:
		_show_line_or_nothing()


## What the slot reads right now: the toast, else the line, else an empty string. Test hook.
func current_text() -> String:
	return text if visible else ""


## True while a toast or an armed line holds the slot (the command hints yield it).
func is_occupied() -> bool:
	return _toast_active or not _line.is_empty()


## An empty prompt clears the line.
func _on_prompt(message: String) -> void:
	if message.is_empty():
		clear_line()
	else:
		set_line(message)


func _on_feedback(message: String, is_error: bool) -> void:
	if is_error:
		show_error(message)
	else:
		show_toast(message)


func _end_toast() -> void:
	_tween = null
	_toast_active = false
	_show_line_or_nothing()


func _show_line_or_nothing() -> void:
	_stop_tween()
	modulate.a = 1.0
	text = _line
	visible = not _line.is_empty()


func _stop_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
