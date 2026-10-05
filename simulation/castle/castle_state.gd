class_name CastleState
extends RefCounted
## The castle's health. Integer hit points from MapConfig.castle_max_health; the castle is the one
## thing the night is lost on, so `castle_destroyed` fires exactly once, at the hit that takes the
## last point. What the loss does (the results screen) arrives with the run-end plan; this class
## only reports it.

var _position: Vector2
var _radius: float
var _health: int
var _max_health: int
var _destroyed: bool = false
var _events: SimEvents


func _init(map: MapConfig, events: SimEvents) -> void:
	_position = Vector2(map.castle_position.x, map.castle_position.z)
	_radius = map.castle_radius
	_max_health = maxi(map.castle_max_health, 1)
	_health = _max_health
	_events = events


## Where the castle centre stands, in XZ metres.
func get_position() -> Vector2:
	return _position


func get_radius() -> float:
	return _radius


func get_health() -> int:
	return _health


func get_max_health() -> int:
	return _max_health


func is_destroyed() -> bool:
	return _destroyed


## Removes up to `amount` hit points (never below 0) and emits castle_damaged with the points
## actually lost; the hit that reaches 0 then emits castle_destroyed, once. A hit on a destroyed
## castle, or a non-positive amount, is dropped.
func damage(amount: int) -> void:
	if _destroyed or amount <= 0:
		return
	var lost: int = mini(amount, _health)
	_health -= lost
	_events.castle_damaged.emit(lost, _health, _max_health)
	if _health == 0:
		_destroyed = true
		_events.castle_destroyed.emit()


## Full health again (the dawn repair). Clears the destroyed flag; emits nothing.
func repair() -> void:
	_health = _max_health
	_destroyed = false
