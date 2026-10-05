class_name TowerSystem
extends RefCounted
## Tower fire control (D-13). RED-phase shell: the behavior lands in the GREEN commit.

var _buildings: BuildingSystem
var _events: SimEvents


func _init(buildings: BuildingSystem, events: SimEvents) -> void:
	_buildings = buildings
	_events = events


func begin_night() -> void:
	pass


func step(_tick: int, _enemies: EnemySystem, _hits: PendingHits) -> void:
	pass
