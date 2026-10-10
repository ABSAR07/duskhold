class_name PadCursorController
extends Node
## The pad's right-stick ground cursor for the point verbs (D-12). Inert skeleton.

signal feedback(text: String, is_error: bool)
signal prompt(text: String)

@export var cursor_speed_px_per_s: float = 900.0


func bind_run(_ctx: RunContext, _map_root: MapRoot) -> void:
	pass


func is_active() -> bool:
	return false


func cursor_position() -> Vector2:
	return Vector2.ZERO


func cancel() -> bool:
	return false
