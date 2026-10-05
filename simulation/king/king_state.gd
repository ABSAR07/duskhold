class_name KingState
extends RefCounted
## The king as the night simulation sees him: a position it is told and a passive attack it makes.
## Movement stays in presentation (the King node) or in a scripted bot; both feed the position in
## through `report_position`, the only position input (DR-10).

var _def: KingDef
var _events: SimEvents
var _position: Vector2
var _cooldown_ready_tick: int = 0


func _init(def: KingDef, spawn: Vector2, events: SimEvents) -> void:
	_def = def
	_position = spawn
	_events = events


func get_def() -> KingDef:
	return _def


## Where the king stands, in XZ metres.
func report_position(pos: Vector2) -> void:
	_position = pos


func get_position() -> Vector2:
	return _position


## A new night: the passive attack is ready at once.
func begin_night() -> void:
	_cooldown_ready_tick = 0


## Attacks the nearest enemy in range when the cooldown has elapsed. The hit arrives this very
## tick, so it resolves with the others before dead enemies are removed. With no enemy in range
## nothing happens and no cooldown is consumed, so an enemy entering range is hit that same tick.
func step(tick: int, enemies: EnemySystem, hits: PendingHits) -> void:
	if tick < _cooldown_ready_tick:
		return
	var target_id: int = enemies.nearest_in_range(_position, _def.attack_range)
	if target_id < 0:
		return
	hits.enqueue(
		tick, PendingHits.KIND_KING, 0, PendingHits.KIND_ENEMY, target_id, _def.attack_damage
	)
	_events.attack_fired.emit(PendingHits.KIND_KING, 0, PendingHits.KIND_ENEMY, target_id, 0)
	_cooldown_ready_tick = tick + SimClock.ticks(_def.attack_interval)
