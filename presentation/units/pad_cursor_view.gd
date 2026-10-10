class_name PadCursorView
extends Node3D
## The pad's ground cursor on the map (D-12). Inert skeleton.


func bind_run(_ctx: RunContext, _map_root: MapRoot) -> void:
	pass


func show_cursor(_king_ground: Vector3, _cursor_ground: Vector3) -> void:
	pass


func hide_cursor() -> void:
	pass


func is_visible_cursor() -> bool:
	return false


func cursor_ground() -> Vector3:
	return Vector3.ZERO


func line_length() -> float:
	return 0.0
