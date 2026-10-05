class_name SpawnTelegraph
extends Control
## RED-phase shell: the real telegraph replaces this in the GREEN commit.

const EDGE_MARGIN_PX: float = 48.0


static func markers_for(_map: MapConfig, _next_night: int) -> Array:
	return []


static func place(
	projected: Vector2, _behind: bool, _viewport: Rect2, _margin: float
) -> Dictionary:
	return {"position": projected, "on_screen": true, "angle": 0.0}


func marker_count() -> int:
	return 0


func marker_text(_spawn_point_id: StringName) -> String:
	return ""


func is_marker_on_screen(_spawn_point_id: StringName) -> bool:
	return false
