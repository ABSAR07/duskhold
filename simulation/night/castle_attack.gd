class_name CastleAttack
extends RefCounted
## Skeleton for plan 02-15: the castle does not shoot yet.


func _init(_map: MapConfig, _castle: CastleState, _events: SimEvents) -> void:
	pass


func is_armed() -> bool:
	return false


func begin_night() -> void:
	pass


func step(_tick: int, _enemies: EnemySystem, _hits: PendingHits) -> void:
	pass
