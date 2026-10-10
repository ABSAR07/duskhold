class_name AbilityController
extends Node
## Polled input for the weapon's active ability (D-17, KING-04). One press of the ability action
## (Q or pad X) submits one ActivateAbilityIntent to the command gate; the slam needs no aiming
## and the mouse plays no part (D-11). A refused press reports its reason through `denied` so the
## HUD can shake the icon, and changes nothing.
##
## The press edge is read in _process from Input.is_action_just_pressed with a fallback on the
## action level: a scripted Input.action_press makes no input event, so the fallback keeps
## replays and tests working (Pitfall 6). A held key is one press, never a stream.

## Emitted when a press was refused; `reason` is the CommandProcessor reason value.
signal denied(reason: StringName)

const ACTION: StringName = &"ability"

var _ctx: RunContext
var _was_pressed: bool = false


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	_ctx = ctx


func _process(_delta: float) -> void:
	if _ctx == null:
		return
	var pressed: bool = Input.is_action_pressed(ACTION)
	var edge: bool = Input.is_action_just_pressed(ACTION) or (pressed and not _was_pressed)
	_was_pressed = pressed
	if not edge:
		return
	var result: StringName = _ctx.commands.submit(ActivateAbilityIntent.new())
	if result != CommandProcessor.OK:
		denied.emit(result)
