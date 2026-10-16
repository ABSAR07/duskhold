class_name GoalFieldCache
extends RefCounted
## RED-phase stub: the real cache lands in the GREEN commit.


func _init(_grid: NavGrid, _tuning: NavTuning) -> void:
	pass


static func key_of(_goal: Vector2, _quantum: float) -> int:
	return 0


func size() -> int:
	return 0


func field_for(_goal: Vector2, _goal_radius: float, _tick: int) -> FlowField:
	return null
