class_name UnitSystem
extends RefCounted
## Every friendly unit alive, addressed by an id that only ever grows and is never reused (the same
## Pattern 3 as EnemySystem: callers never touch the storage, so Phase 4 can swap it for packed
## arrays behind this API). Positions are Vector2 on the XZ plane. Iteration is always in ascending
## id order (DR-6). The mutating calls other than `damage` and `remove_dead` belong to SquadSystem,
## the only system that moves and targets units.

var _events: SimEvents
var _records: Dictionary = {}
var _order: Array[int] = []
var _next_id: int = 1


func _init(events: SimEvents) -> void:
	_events = events


## Adds a unit of `def` to squad `squad_id`, seated in formation slot `slot`, and returns its id;
## emits unit_spawned.
func spawn(def: UnitDef, squad_id: StringName, slot: int, pos: Vector2) -> int:
	var record: Record = Record.new()
	record.id = _next_id
	record.squad_id = squad_id
	record.def = def
	record.slot = slot
	record.position = pos
	record.previous = pos
	record.health = def.max_health
	_next_id += 1
	_records[record.id] = record
	_order.append(record.id)
	_events.unit_spawned.emit(record.id, squad_id, def.id, pos)
	return record.id


## Ids of the units on the field, ascending. A copy.
func ids() -> Array[int]:
	return _order.duplicate()


func count() -> int:
	return _order.size()


func is_alive(id: int) -> bool:
	var record: Record = _records.get(id) as Record
	return record != null and record.health > 0


## Zero vector for an unknown id.
func position_of(id: int) -> Vector2:
	var record: Record = _records.get(id) as Record
	return record.position if record != null else Vector2.ZERO


## Where the unit stood one step ago; the puppet interpolates from here.
func previous_position_of(id: int) -> Vector2:
	var record: Record = _records.get(id) as Record
	return record.previous if record != null else Vector2.ZERO


## Null for an unknown id.
func def_of(id: int) -> UnitDef:
	var record: Record = _records.get(id) as Record
	return record.def if record != null else null


## 0 for an unknown id.
func health_of(id: int) -> int:
	var record: Record = _records.get(id) as Record
	return record.health if record != null else 0


## The squad (military spot id) the unit belongs to; empty for an unknown id.
func squad_of(id: int) -> StringName:
	var record: Record = _records.get(id) as Record
	return record.squad_id if record != null else &""


## The formation slot the unit holds; -1 for an unknown id.
func slot_of(id: int) -> int:
	var record: Record = _records.get(id) as Record
	return record.slot if record != null else -1


## The enemy id the unit is committed to; -1 while it has none and for an unknown id.
func target_of(id: int) -> int:
	var record: Record = _records.get(id) as Record
	return record.target_id if record != null else -1


## Removes `amount` hit points (never below 0) and emits unit_damaged. An unknown or already dead
## id, or a non-positive amount, is ignored: a hit on a gone unit drops silently. The killing
## attacker kind is remembered for the unit_died event.
func damage(id: int, amount: int, killer_kind: StringName) -> void:
	var record: Record = _records.get(id) as Record
	if record == null or record.health <= 0 or amount <= 0:
		return
	record.health = maxi(record.health - amount, 0)
	if record.health == 0:
		record.killer_kind = killer_kind
	_events.unit_damaged.emit(id, amount, record.health)


## Removes dead units in ascending id order and emits unit_died for each.
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
		_events.unit_died.emit(id, record.squad_id, record.position, record.killer_kind)


## Writer for SquadSystem: a living unit is back at its def max_health (the dawn restore). A dead
## or unknown id is ignored.
func heal_to_full(id: int) -> void:
	var record: Record = _records.get(id) as Record
	if record != null and record.health > 0:
		record.health = record.def.max_health


## Writer for SquadSystem: remembers every unit position as "one step ago", before the step moves
## anyone.
func begin_step() -> void:
	for id: int in _order:
		var record: Record = _records[id]
		record.previous = record.position


## Writer for SquadSystem: moves a unit. Ignored for an unknown id.
func set_position_of(id: int, pos: Vector2) -> void:
	var record: Record = _records.get(id) as Record
	if record != null:
		record.position = pos


## Writer for SquadSystem: commits a unit to an enemy id, or -1 for none.
func set_target(id: int, enemy_id: int) -> void:
	var record: Record = _records.get(id) as Record
	if record != null:
		record.target_id = enemy_id


## First tick on which the unit next strike may land; 0 for an unknown id.
func cooldown_ready_of(id: int) -> int:
	var record: Record = _records.get(id) as Record
	return record.cooldown_ready_tick if record != null else 0


## Writer for SquadSystem: sets the first tick on which the unit may strike again.
func set_cooldown_ready(id: int, tick: int) -> void:
	var record: Record = _records.get(id) as Record
	if record != null:
		record.cooldown_ready_tick = tick


## Pushes overlapping units apart. Positions are snapshotted once; every pair, in ascending id
## order, adds half the overlap to each member displacement along their difference (a zero
## difference uses a fixed axis chosen by the lower id parity, never a random one); the
## displacements are applied together, so the result does not depend on iteration side effects
## (DR-6, DR-8).
func separate() -> void:
	var alive: Array[Record] = []
	for id: int in _order:
		var record: Record = _records[id]
		if record.health > 0:
			alive.append(record)
	var count_alive: int = alive.size()
	if count_alive < 2:
		return
	var snapshot: PackedVector2Array = PackedVector2Array()
	snapshot.resize(count_alive)
	var displacement: PackedVector2Array = PackedVector2Array()
	displacement.resize(count_alive)
	for index: int in range(count_alive):
		snapshot[index] = alive[index].position
	for first: int in range(count_alive):
		for second: int in range(first + 1, count_alive):
			var min_gap: float = alive[first].def.radius + alive[second].def.radius
			var delta: Vector2 = snapshot[second] - snapshot[first]
			if absf(delta.x) >= min_gap:
				continue
			var d2: float = delta.length_squared()
			if d2 >= min_gap * min_gap:
				continue
			var direction: Vector2
			var gap: float = 0.0
			if d2 == 0.0:
				direction = Vector2.RIGHT if alive[first].id % 2 == 0 else Vector2.DOWN
			else:
				gap = sqrt(d2)
				direction = delta / gap
			var push: float = (min_gap - gap) * 0.5
			displacement[first] -= direction * push
			displacement[second] += direction * push
	for index: int in range(count_alive):
		alive[index].position += displacement[index]


## One unit state. Private to the system.
class Record:
	extends RefCounted
	var id: int = 0
	var squad_id: StringName = &""
	var def: UnitDef
	var slot: int = 0
	var position: Vector2 = Vector2.ZERO
	var previous: Vector2 = Vector2.ZERO
	var health: int = 0
	var killer_kind: StringName = &""
	## The enemy id it is committed to, or -1.
	var target_id: int = -1
	## First tick on which its next strike may land.
	var cooldown_ready_tick: int = 0
