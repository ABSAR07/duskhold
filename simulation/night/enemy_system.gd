class_name EnemySystem
extends RefCounted
## Every enemy alive in the current night, addressed by an id that only ever grows and is never
## reused (Pattern 3: callers never touch the storage, so Phase 4 can swap it for packed arrays).
## Positions are Vector2 on the XZ plane. Iteration is always in ascending id order (DR-6).

var _events: SimEvents
var _records: Dictionary = {}
var _order: Array[int] = []
var _next_id: int = 1
var _died_total: int = 0


func _init(events: SimEvents) -> void:
	_events = events


## The straight-line step an enemy at `pos` takes toward `goal`, at most `max_distance` long. The
## one steering seam: Phase 4 replaces this body with a flow-field sample.
static func desired_step(pos: Vector2, goal: Vector2, max_distance: float) -> Vector2:
	return pos.move_toward(goal, maxf(max_distance, 0.0)) - pos


## Adds an enemy and returns its id; emits enemy_spawned.
func spawn(def: EnemyDef, pos: Vector2) -> int:
	var record: Record = Record.new()
	record.id = _next_id
	record.def = def
	record.position = pos
	record.previous = pos
	record.health = def.max_health
	_next_id += 1
	_records[record.id] = record
	_order.append(record.id)
	_events.enemy_spawned.emit(record.id, def.id, pos)
	return record.id


## Ids of the enemies on the field, ascending. A copy.
func ids() -> Array[int]:
	return _order.duplicate()


func count() -> int:
	return _order.size()


## How many enemies have been removed as dead since the last clear.
func died_count() -> int:
	return _died_total


func is_alive(id: int) -> bool:
	var record: Record = _records.get(id) as Record
	return record != null and record.health > 0


## Stub for the RED commit.
static func is_rescan_tick(_tick: int, _id: int, _rescan_ticks: int) -> bool:
	return false


## Stub for the RED commit.
func target_of(_id: int) -> Dictionary:
	return {}


## Zero vector for an unknown id.
func position_of(id: int) -> Vector2:
	var record: Record = _records.get(id) as Record
	return record.position if record != null else Vector2.ZERO


## Where the enemy stood one step ago; the puppet interpolates from here.
func previous_position_of(id: int) -> Vector2:
	var record: Record = _records.get(id) as Record
	return record.previous if record != null else Vector2.ZERO


## Null for an unknown id.
func def_of(id: int) -> EnemyDef:
	var record: Record = _records.get(id) as Record
	return record.def if record != null else null


## 0 for an unknown id.
func health_of(id: int) -> int:
	var record: Record = _records.get(id) as Record
	return record.health if record != null else 0


## Removes `amount` hit points (never below 0) and emits enemy_damaged. An unknown or already dead
## id, or a non-positive amount, is ignored: a hit on a gone target drops silently. The killing
## attacker's kind is remembered for the enemy_died event.
func damage(id: int, amount: int, killer_kind: StringName) -> void:
	var record: Record = _records.get(id) as Record
	if record == null or record.health <= 0 or amount <= 0:
		return
	record.health = maxi(record.health - amount, 0)
	if record.health == 0:
		record.killer_kind = killer_kind
	_events.enemy_damaged.emit(id, amount, record.health)


## Id of the living enemy nearest `pos` whose centre is within `reach` (inclusive, squared-distance
## compare), or -1. Equally near enemies: the lower id wins (ids are scanned ascending and only a
## strictly nearer one replaces the best).
func nearest_in_range(pos: Vector2, reach: float) -> int:
	var best_id: int = -1
	var best_d2: float = INF
	var limit: float = reach * reach
	for id: int in _order:
		var record: Record = _records[id]
		if record.health <= 0:
			continue
		var d2: float = pos.distance_squared_to(record.position)
		if d2 <= limit and d2 < best_d2:
			best_d2 = d2
			best_id = id
	return best_id


## Moves every living enemy (id order) one step toward the castle; it waits at the castle's edge,
## `castle_radius + attack_range` from the centre. Castle damage arrives in a later plan.
func step(_tick: int, castle: CastleState, _hits: PendingHits) -> void:
	var castle_pos: Vector2 = castle.get_position()
	var castle_radius: float = castle.get_radius()
	for id: int in _order:
		var record: Record = _records[id]
		record.previous = record.position
		if record.health <= 0:
			continue
		var stop_distance: float = castle_radius + record.def.attack_range
		var remaining: float = record.position.distance_to(castle_pos) - stop_distance
		if remaining <= 0.0:
			continue
		var reach: float = minf(record.def.move_speed * SimClock.STEP, remaining)
		record.position += desired_step(record.position, castle_pos, reach)


## Removes dead enemies in ascending id order and emits enemy_died for each.
func remove_dead() -> void:
	var dead: Array[int] = []
	for id: int in _order:
		var record: Record = _records[id]
		if record.health <= 0:
			dead.append(id)
	for id: int in dead:
		var record: Record = _records[id]
		_records.erase(id)
		_order.erase(id)
		_died_total += 1
		_events.enemy_died.emit(id, record.def.id, record.position, record.killer_kind)


## Empties the field for a new night. Ids keep growing: they are never reused.
func clear() -> void:
	_records.clear()
	_order.clear()
	_died_total = 0


## One enemy's state. Private to the system.
class Record:
	extends RefCounted
	var id: int = 0
	var def: EnemyDef
	var position: Vector2 = Vector2.ZERO
	var previous: Vector2 = Vector2.ZERO
	var health: int = 0
	var killer_kind: StringName = &""
