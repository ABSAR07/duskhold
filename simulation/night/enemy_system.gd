class_name EnemySystem
extends RefCounted
## Every enemy alive in the current night, addressed by an id that only ever grows and is never
## reused (Pattern 3: callers never touch the storage, so Phase 4 can swap it for packed arrays).
## Positions are Vector2 on the XZ plane. Iteration is always in ascending id order (DR-6).

## An enemy counts as arrived when it is within this many metres of its stop distance, so float32
## positions that land a hair short still strike.
const ARRIVE_EPSILON: float = 0.001
## Added to twice the largest radius for the push-apart grid's cell edge, so a pair exactly at
## touching distance never straddles two cells more than the pass looks.
const SEPARATION_CELL_SLACK: float = 0.001

var _events: SimEvents
var _records: Dictionary = {}
var _order: Array[int] = []
var _next_id: int = 1
var _died_total: int = 0
## The friendly units of the step in progress; null when the caller has none (Phase 2 behaviour).
var _units: UnitSystem
## The nearest-structure grid, rebuilt once per step: structures do not move in the enemy phase.
var _structures: StructureIndex = StructureIndex.new()
## The grid of living enemies behind TargetQuery.nearest_enemy, rebuilt on the first query after
## the field changed.
var _grid: EnemyIndex = EnemyIndex.new()
var _grid_dirty: bool = true
## Counts the changes that can alter the read view; the view carries the count it was built at.
var _changes: int = 0
var _view: CrowdReadView = CrowdReadView.new()


func _init(events: SimEvents) -> void:
	_events = events


## The straight-line step an enemy at `pos` takes toward `goal`, at most `max_distance` long. The
## one steering seam: Phase 4 replaces this body with a flow-field sample.
static func desired_step(pos: Vector2, goal: Vector2, max_distance: float) -> Vector2:
	return pos.move_toward(goal, maxf(max_distance, 0.0)) - pos


## True on the ticks where enemy `id` looks for a better target: (tick + id) % rescan_ticks == 0, so
## enemies with different ids rescan on different ticks and the cost is spread (Pitfall 5).
static func is_rescan_tick(tick: int, id: int, rescan_ticks: int) -> bool:
	return rescan_ticks > 0 and (tick + id) % rescan_ticks == 0


## Adds an enemy and returns its id; emits enemy_spawned.
func spawn(def: EnemyDef, pos: Vector2) -> int:
	var record: Record = Record.new()
	record.id = _next_id
	record.def = def
	record.position = pos
	record.previous = pos
	record.health = def.max_health
	record.rescan_ticks = maxi(SimClock.ticks(def.retarget_interval_seconds), 1)
	_next_id += 1
	_records[record.id] = record
	_order.append(record.id)
	_mark_changed()
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


## What enemy `id` is attacking or walking toward: {"kind": StringName, "id": int}, a fresh
## Dictionary per call; empty while it marches without a target and for an unknown id. Read-only
## (the debug overlay and the path gizmo read it).
func target_of(id: int) -> Dictionary:
	var record: Record = _records.get(id) as Record
	if record == null or record.target_kind == &"":
		return {}
	return {"kind": record.target_kind, "id": record.target_id}


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


## The enemy phase of a night step (DR-8). Every living enemy, in id order, chooses a target
## (committed until it is invalid or a staggered rescan finds a better one), walks toward it and
## stops at `target radius + attack_range`, then strikes through the pending-hit queue once per
## attack_interval. After all of them moved, overlapping enemies are pushed apart. A destroyed
## castle leaves nothing to march on, so the field stands still. `king` may be null in tests that
## have none; then nobody targets him. `buildings` may be null in tests that have none; then the
## castle is the only structure to attack. `units` may be null; then nobody targets friendly
## units, byte for byte the Phase 2 behaviour.
func step(
	tick: int,
	castle: CastleState,
	king: KingState,
	hits: PendingHits,
	buildings: BuildingSystem = null,
	units: UnitSystem = null
) -> void:
	_units = units
	_mark_changed()
	for id: int in _order:
		var record: Record = _records[id]
		record.previous = record.position
	if castle.is_destroyed():
		return
	_structures.rebuild(units, buildings, castle)
	for id: int in _order:
		var record: Record = _records[id]
		if record.health <= 0:
			continue
		_choose_target(record, tick, castle, king, buildings)
		_advance_and_strike(record, tick, castle, king, hits, buildings)
	_separate()
	_mark_changed()


## Ids of the enemies whose grid cell lies within `reach` of `pos`'s cell, ascending: a superset of
## the living enemies within `reach` metres, for the caller to narrow with its own exact test. Dead
## enemies that have not been removed yet may be listed. Read-only; rebuilds the grid first when
## the field changed since the last query.
func living_within(pos: Vector2, reach: float) -> PackedInt64Array:
	if _grid_dirty:
		var ids: PackedInt64Array = PackedInt64Array()
		var positions: PackedVector2Array = PackedVector2Array()
		for id: int in _order:
			var record: Record = _records[id]
			if record.health > 0:
				ids.append(id)
				positions.append(record.position)
		_grid.rebuild(ids, positions)
		_grid_dirty = false
	return _grid.within(pos, reach)


## The enemy field as packed arrays (ids ascending, with previous and current positions), refilled
## only when something changed since the last read. The same object every time, so a caller reads
## it and never keeps it across a step. Emits no signal.
func read_view() -> CrowdReadView:
	if _view.version == _changes:
		return _view
	var count: int = _order.size()
	_view.ids.resize(count)
	_view.previous.resize(count)
	_view.current.resize(count)
	for slot: int in range(count):
		var record: Record = _records[_order[slot]]
		_view.ids[slot] = record.id
		_view.previous[slot] = record.previous
		_view.current[slot] = record.position
	_view.version = _changes
	return _view


## Removes dead enemies in ascending id order and emits enemy_died for each.
func remove_dead() -> void:
	_mark_changed()
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
		_mark_changed()
		_events.enemy_died.emit(id, record.def.id, record.position, record.killer_kind)


## Empties the field for a new night. Ids keep growing: they are never reused.
func clear() -> void:
	_records.clear()
	_order.clear()
	_died_total = 0
	_mark_changed()


## D-11 target choice (Pitfall 5: commit to a target). It runs when the enemy has no target, when
## its target went invalid, and on the enemy's own staggered rescan tick. In priority order:
##   1. keep a king target that is still up and inside leash_range;
##   2. the king, when he is up and inside aggro_range (this is how he pulls enemies off whatever
##      they were attacking);
##   3. keep any other valid target;
##   4. the thing whose edge is nearest inside aggro_range: a living unit, a standing building or
##      the castle, ties going to a unit first (the lower id among units), then the earlier spot,
##      and the castle last, so units and outer buildings shield the castle;
##   5. none: the enemy keeps marching on the castle.
func _choose_target(
	record: Record, tick: int, castle: CastleState, king: KingState, buildings: BuildingSystem
) -> void:
	var valid: bool = record.target_kind != &"" and _target_valid(record, castle, king, buildings)
	if valid and not is_rescan_tick(tick, record.id, record.rescan_ticks):
		return
	if valid and record.target_kind == PendingHits.KIND_KING:
		return
	if (
		_king_up(king)
		and record.position.distance_to(king.get_position()) <= record.def.aggro_range
	):
		record.target_kind = PendingHits.KIND_KING
		record.target_id = 0
		return
	if valid:
		return
	record.target_kind = &""
	record.target_id = 0
	_pick_nearest_structure(record)


## Sets the target to the nearest living unit, standing building or the castle by edge distance
## (centre distance minus radius), if one is within aggro_range. The answer comes from the
## StructureIndex, which tests the candidates in the shipped order: a strictly smaller edge distance
## is needed to replace an earlier candidate, so units are tried first (in id order), then
## buildings in spot order and the castle last.
func _pick_nearest_structure(record: Record) -> void:
	var found: Vector3i = _structures.nearest(record.position, record.def.aggro_range)
	if found.z == 0:
		return
	if found.x == StructureIndex.KIND_UNIT:
		record.target_kind = PendingHits.KIND_UNIT
	elif found.x == StructureIndex.KIND_BUILDING:
		record.target_kind = PendingHits.KIND_BUILDING
	else:
		record.target_kind = PendingHits.KIND_CASTLE
	record.target_id = found.y


## Distance from `pos` to the edge of the building on the spot; negative inside its footprint.
func _building_edge(pos: Vector2, buildings: BuildingSystem, spot_id: StringName) -> float:
	var spot: BuildSpotDef = buildings.get_spot(spot_id)
	var centre: Vector2 = Vector2(spot.position.x, spot.position.z)
	return pos.distance_to(centre) - buildings.radius_of(spot_id)


## Distance from `pos` to the edge of unit `unit_id`; negative inside its footprint.
func _unit_edge(pos: Vector2, unit_id: int) -> float:
	return pos.distance_to(_units.position_of(unit_id)) - _units.def_of(unit_id).radius


## True while the record's current target can still be attacked and is not beyond the leash. The
## king stops being valid the moment he is down, a building the moment it falls.
func _target_valid(
	record: Record, castle: CastleState, king: KingState, buildings: BuildingSystem
) -> bool:
	if record.target_kind == PendingHits.KIND_KING:
		return _king_target_valid(record, king)
	if record.target_kind == PendingHits.KIND_CASTLE:
		if castle.is_destroyed():
			return false
		var to_castle: float = record.position.distance_to(castle.get_position())
		return to_castle <= record.def.leash_range + castle.get_radius()
	if record.target_kind == PendingHits.KIND_BUILDING:
		return _building_target_valid(record, buildings)
	if record.target_kind == PendingHits.KIND_UNIT:
		return _unit_target_valid(record)
	return false


## The king is a valid target while he is up and inside leash_range.
func _king_target_valid(record: Record, king: KingState) -> bool:
	if not _king_up(king):
		return false
	return record.position.distance_to(king.get_position()) <= record.def.leash_range


## A unit target is valid while it lives and its edge is inside leash_range.
func _unit_target_valid(record: Record) -> bool:
	if _units == null or not _units.is_alive(record.target_id):
		return false
	return _unit_edge(record.position, record.target_id) <= record.def.leash_range


## A building target is valid while it still stands and its edge is inside leash_range.
func _building_target_valid(record: Record, buildings: BuildingSystem) -> bool:
	if buildings == null:
		return false
	var spot_id: StringName = buildings.spot_at_index(record.target_id)
	if spot_id == &"" or buildings.current_tier(spot_id) == 0 or buildings.is_destroyed(spot_id):
		return false
	return _building_edge(record.position, buildings, spot_id) <= record.def.leash_range


## The field changed: the grid and the read view are stale until the next query or read.
func _mark_changed() -> void:
	_changes += 1
	_grid_dirty = true


func _king_up(king: KingState) -> bool:
	return king != null and not king.is_down()


## Walks toward the target (or the castle while there is none) and, once at its stop distance and
## off cooldown, queues one hit: a melee enemy's lands this tick, a ranged enemy's (projectile_speed
## above 0) lands SimClock.flight_ticks(distance to the target's centre, projectile_speed) later.
func _advance_and_strike(
	record: Record,
	tick: int,
	castle: CastleState,
	king: KingState,
	hits: PendingHits,
	buildings: BuildingSystem
) -> void:
	var goal: Vector2 = castle.get_position()
	var goal_radius: float = castle.get_radius()
	if record.target_kind == PendingHits.KIND_KING:
		goal = king.get_position()
		goal_radius = king.get_def().body_radius
	elif record.target_kind == PendingHits.KIND_BUILDING:
		var spot_id: StringName = buildings.spot_at_index(record.target_id)
		var spot_position: Vector3 = buildings.get_spot(spot_id).position
		goal = Vector2(spot_position.x, spot_position.z)
		goal_radius = buildings.radius_of(spot_id)
	elif record.target_kind == PendingHits.KIND_UNIT:
		goal = _units.position_of(record.target_id)
		goal_radius = _units.def_of(record.target_id).radius
	var attacking: bool = record.target_kind != &""
	var stop_distance: float = goal_radius + record.def.attack_range
	var remaining: float = record.position.distance_to(goal) - stop_distance
	if remaining > 0.0:
		var reach: float = minf(record.def.move_speed * SimClock.STEP, remaining)
		record.position += desired_step(record.position, goal, reach)
		remaining = record.position.distance_to(goal) - stop_distance
	if not attacking or remaining > ARRIVE_EPSILON or tick < record.cooldown_ready_tick:
		return
	var flight: int = SimClock.flight_ticks(
		record.position.distance_to(goal), record.def.projectile_speed
	)
	hits.enqueue(
		tick + flight,
		PendingHits.KIND_ENEMY,
		record.id,
		record.target_kind,
		record.target_id,
		record.def.attack_damage
	)
	_events.attack_fired.emit(
		PendingHits.KIND_ENEMY, record.id, record.target_kind, record.target_id, flight
	)
	record.cooldown_ready_tick = tick + SimClock.ticks(record.def.attack_interval)


## Pushes overlapping enemies apart (Pitfall 6, DR-6, DR-8). The pass itself is
## Separation.displacements_bucketed (equal to Separation.displacements), shared with UnitSystem;
## the displacements are applied together, so the result does not depend on iteration side effects.
func _separate() -> void:
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


## One enemy's state. Private to the system.
class Record:
	extends RefCounted
	var id: int = 0
	var def: EnemyDef
	var position: Vector2 = Vector2.ZERO
	var previous: Vector2 = Vector2.ZERO
	var health: int = 0
	var killer_kind: StringName = &""
	## What it is attacking or walking toward: kind (empty while marching) and id.
	var target_kind: StringName = &""
	var target_id: int = 0
	## First tick on which its next strike may land.
	var cooldown_ready_tick: int = 0
	## Ticks between its target rescans, fixed at spawn from its def's retarget interval.
	var rescan_ticks: int = 1
