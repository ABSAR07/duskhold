class_name CastleState
extends RefCounted
## The castle's health. Stub for the RED commit: the real damage rules arrive with the GREEN commit.

var _position: Vector2
var _radius: float
var _health: int
var _max_health: int
var _events: SimEvents


func _init(map: MapConfig, events: SimEvents) -> void:
	_position = Vector2(map.castle_position.x, map.castle_position.z)
	_radius = map.castle_radius
	_max_health = map.castle_max_health
	_health = _max_health
	_events = events


func get_position() -> Vector2:
	return _position


func get_radius() -> float:
	return _radius


func get_health() -> int:
	return _health


func get_max_health() -> int:
	return _max_health


func is_destroyed() -> bool:
	return false


func damage(_amount: int) -> void:
	pass


func repair() -> void:
	_health = _max_health
