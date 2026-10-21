class_name UnitSystem
extends RefCounted
## Every friendly unit alive, addressed by an id that only ever grows and is never reused (the same
## Pattern 3 as EnemySystem: callers never touch the storage, so Phase 4 can swap it for packed
## arrays behind this API). Positions are Vector2 on the XZ plane. Iteration is always in ascending
## id order (DR-6). The mutating calls other than `damage` and `remove_dead` belong to SquadSystem,
## the only system that moves and targets units.

## Added to twice the largest radius for the push-apart grid's cell edge (see EnemySystem).
const SEPARATION_CELL_SLACK: float = 0.001

var _events: SimEvents
var _stats: StatStack
var _records: Dictionary = {}
var _order: Array[int] = []
var _next_id: int = 1
## Bumped by every writer that may change an id, a position or a def; the read view is stale while
## its version differs.
var _changes: int = 0
var _view: UnitReadView = UnitReadView.new()


func _init(events: SimEvents, stat_stack: StatStack = null) -> void:
	_events = events
	_stats = stat_stack if stat_stack != null else StatStack.new()
	_stats.changed.connect(_on_stats_changed)


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
	record.health = _max_health_of(def)
	_next_id += 1
	_records[record.id] = record
	_order.append(record.id)
	_changes += 1
	_events.unit_spawned.emit(record.id, squad_id, def.id, pos)
	return record.id


## Ids of the units on the field, ascending. A copy.
func ids() -> Array[int]:
	return _order.duplicate()


## The army as packed arrays (ids ascending, with previous and current positions and each unit's
## def), refilled only when something changed since the last read. The same object every time, so a
## caller reads it and never keeps it across a step. Emits no signal and writes nothing back.
func read_view() -> UnitReadView:
	if _view.version == _changes:
		return _view
	var total: int = _order.size()
	_view.ids.resize(total)
	_view.previous.resize(total)
	_view.current.resize(total)
	_view.def_slots.resize(total)
	_view.defs.clear()
	var slot_of_def: Dictionary = {}
	for index: int in range(total):
		var record: Record = _records[_order[index]]
		_view.ids[index] = record.id
		_view.previous[index] = record.previous
		_view.current[index] = record.position
		var def_slot: int = slot_of_def.get(record.def, -1)
		if def_slot < 0:
			def_slot = _view.defs.size()
			slot_of_def[record.def] = def_slot
			_view.defs.append(record.def)
		_view.def_slots[index] = def_slot
	_view.version = _changes
	return _view


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
		_changes += 1
		_events.unit_died.emit(id, record.squad_id, record.position, record.killer_kind)


## Writer for SquadSystem: a living unit is back at its def max_health (the dawn restore). A dead
## or unknown id is ignored.
func heal_to_full(id: int) -> void:
	var record: Record = _records.get(id) as Record
	if record != null and record.health > 0:
		record.health = _max_health_of(record.def)


## Writer for SquadSystem: remembers every unit position as "one step ago", before the step moves
## anyone.
func begin_step() -> void:
	_changes += 1
	for id: int in _order:
		var record: Record = _records[id]
		record.previous = record.position


## Writer for SquadSystem: moves a unit. Ignored for an unknown id.
func set_position_of(id: int, pos: Vector2) -> void:
	var record: Record = _records.get(id) as Record
	if record != null:
		record.position = pos
		_changes += 1


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


## Pushes overlapping units apart (DR-6, DR-8). The pass itself is Separation.displacements_bucketed
## (equal to Separation.displacements), shared with EnemySystem; the displacements are applied
## together, so the result does not depend on iteration side effects.
func separate() -> void:
	var alive: Array[Record] = []
	for id: int in _order:
		var record: Record = _records[id]
		if record.health > 0:
			alive.append(record)
	if alive.size() < 2:
		return
	var positions: PackedVector2Array = PackedVector2Array()
	var radii: PackedFloat64Array = PackedFloat64Array()
	var ids: PackedInt64Array = PackedInt64Array()
	var largest: float = 0.0
	for record: Record in alive:
		positions.append(record.position)
		radii.append(record.def.radius)
		ids.append(record.id)
		largest = maxf(largest, record.def.radius)
	var cell: float = 2.0 * largest + SEPARATION_CELL_SLACK
	var pushes: PackedVector2Array = Separation.displacements_bucketed(positions, radii, ids, cell)
	for index: int in range(alive.size()):
		alive[index].position += pushes[index]
	_changes += 1


## A unit type's maximum health with every unit.max_health modifier applied.
func _max_health_of(def: UnitDef) -> int:
	return _stats.int_value(&"unit.max_health", maxi(def.max_health, 1))


## A change of unit.max_health: every living unit gains the gain of its type's maximum, and a loss
## clamps it into [1, max]. Emits nothing: a refresh is neither a hit nor a heal.
func _on_stats_changed(stats: Array[StringName]) -> void:
	if not stats.has(&"unit.max_health"):
		return
	for id: int in _order:
		var record: Record = _records[id]
		if record.health <= 0:
			continue
		var base: int = maxi(record.def.max_health, 1)
		var gain: int = _stats.int_value(&"unit.max_health", base)
		gain -= _stats.previous_int_value(&"unit.max_health", base)
		record.health = clampi(record.health + gain, 1, _max_health_of(record.def))


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
