class_name CastleState
extends RefCounted
## The castle's health and numbers. Integer hit points from MapConfig.castle_max_health; the castle
## is the one thing the night is lost on, so `castle_destroyed` fires exactly once, at the hit that
## takes the last point. What the loss does (the results screen) arrives with the run-end plan; this
## class only reports it.
##
## Every castle number a bonus can touch is read through the stat stack here (META-08): maximum
## health, arrow damage and reach, and the gold it pays at dawn. The arrow's interval and speed are
## the map's. A change of the maximum raises current health by the gain, as for every health stat.

var _position: Vector2
var _radius: float
var _health: int
var _max_health: int
var _destroyed: bool = false
var _events: SimEvents
var _map: MapConfig
var _stats: StatStack


func _init(map: MapConfig, events: SimEvents, stat_stack: StatStack = null) -> void:
	_map = map
	_position = Vector2(map.castle_position.x, map.castle_position.z)
	_radius = map.castle_radius
	_events = events
	_stats = stat_stack if stat_stack != null else StatStack.new()
	_max_health = _stat_max_health()
	_health = _max_health
	_stats.changed.connect(_on_stats_changed)


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


## Damage of one castle arrow: the map's castle_attack_damage through castle.arrow_damage.
func arrow_damage() -> int:
	return _stats.int_value(&"castle.arrow_damage", _map.castle_attack_damage)


## Reach of the castle arrow in metres: the map's castle_attack_range through castle.arrow_range.
func arrow_range() -> float:
	return _stats.float_value(&"castle.arrow_range", _map.castle_attack_range)


## Seconds between castle arrows: the map's castle_attack_interval (no stat touches it).
func arrow_interval() -> float:
	return _map.castle_attack_interval


## Metres per second of a castle arrow: the map's castle_projectile_speed (no stat touches it).
func arrow_speed() -> float:
	return _map.castle_projectile_speed


## Gold the castle pays at every dawn: the map's base_dawn_income through castle.base_income, never
## below 0.
func base_income() -> int:
	return maxi(_stats.int_value(&"castle.base_income", maxi(_map.base_dawn_income, 0)), 0)


func _stat_max_health() -> int:
	return _stats.int_value(&"castle.max_health", maxi(_map.castle_max_health, 1))


## A change of castle.max_health: the gain raises current health by the gain of the maximum and a
## loss clamps it into [1, max] while the castle stands. Emits nothing.
func _on_stats_changed(stats: Array[StringName]) -> void:
	if not stats.has(&"castle.max_health"):
		return
	var base: int = maxi(_map.castle_max_health, 1)
	var gain: int = _stat_max_health() - _stats.previous_int_value(&"castle.max_health", base)
	_max_health = _stat_max_health()
	if not _destroyed:
		_health = clampi(_health + gain, 1, _max_health)
