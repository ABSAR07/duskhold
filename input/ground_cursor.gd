class_name GroundCursor
extends RefCounted
## The pad's aiming point in screen space (D-12). Inert skeleton.


func start(_screen: Vector2) -> void:
	pass


func move(_stick: Vector2, _delta: float, _speed_px_per_s: float) -> void:
	pass


func clamp_to(_rect: Rect2, _margin_px: float) -> void:
	pass


func position() -> Vector2:
	return Vector2.ZERO


func is_active() -> bool:
	return false


func stop() -> void:
	pass
