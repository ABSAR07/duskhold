class_name StuckTracker
extends RefCounted
## Which enemies have stopped getting anywhere (ENMY-04, D-09). Read-only: it reads the enemies and
## the pathing, keeps its own state and emits nothing. RED stub: nothing is ever flagged yet.

var _threshold_ticks: int = 0


func _init(tuning: NavTuning, _cell_size: float) -> void:
	_threshold_ticks = maxi(SimClock.ticks(tuning.stuck_seconds), 1)


func update(_tick: int, _enemies: EnemySystem, _pathing: Pathing) -> void:
	pass


func clear() -> void:
	pass


func is_stuck(_id: int) -> bool:
	return false


func stuck_count() -> int:
	return 0


func stuck_ids() -> PackedInt64Array:
	return PackedInt64Array()


func streak_of(_id: int) -> int:
	return 0


func longest_streak_ticks() -> int:
	return 0


func threshold_ticks() -> int:
	return _threshold_ticks
