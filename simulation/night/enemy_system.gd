class_name EnemySystem
extends RefCounted
## Every enemy alive in the current night, addressed by an id that only ever grows and is never
## reused (Pattern 3: callers never touch the storage, so Phase 4 can swap it for packed arrays).
## Positions are Vector2 on the XZ plane. Iteration is always in ascending id order (DR-6).

## An enemy counts as arrived when it is within this many metres of its stop distance, so float32
## positions that land a hair short still strike.
const ARRIVE_EPSILON: float = 0.001

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
## have none; then nobody targets him.
func step(tick: int, castle: CastleState, king: KingState, hits: PendingHits) -> void:
	for id: int in _order:
		var record: Record = _records[id]
		record.previous = record.position
	if castle.is_destroyed():
		return
	for id: int in _order:
		var record: Record = _records[id]
		if record.health <= 0:
			continue
		_choose_target(record, tick, castle, king)
		_advance_and_strike(record, tick, castle, king, hits)
	_separate()


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


## D-11 target choice (Pitfall 5: commit to a target). It runs when the enemy has no target, when
## its target went invalid, and on the enemy's own staggered rescan tick. In priority order:
##   1. keep a king target that is still up and inside leash_range;
##   2. the king, when he is up and inside aggro_range (this is how he pulls enemies off whatever
##      they were attacking);
##   3. keep any other valid target;
##   4. the castle, once it is inside aggro range plus its own radius;
##   5. none: the enemy keeps marching on the castle.
## Plan 02-04 adds standing buildings between 3 and 4.
func _choose_target(record: Record, tick: int, castle: CastleState, king: KingState) -> void:
	var valid: bool = record.target_kind != &"" and _target_valid(record, castle, king)
	var rescan_ticks: int = maxi(SimClock.ticks(record.def.retarget_interval_seconds), 1)
	if valid and not is_rescan_tick(tick, record.id, rescan_ticks):
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
	var to_castle: float = record.position.distance_to(castle.get_position())
	if to_castle <= record.def.aggro_range + castle.get_radius():
		record.target_kind = PendingHits.KIND_CASTLE
		record.target_id = 0


## True while the record's current target can still be attacked and is not beyond the leash. The
## king stops being valid the moment he is down.
func _target_valid(record: Record, castle: CastleState, king: KingState) -> bool:
	if record.target_kind == PendingHits.KIND_KING:
		if not _king_up(king):
			return false
		return record.position.distance_to(king.get_position()) <= record.def.leash_range
	if record.target_kind == PendingHits.KIND_CASTLE:
		if castle.is_destroyed():
			return false
		var to_castle: float = record.position.distance_to(castle.get_position())
		return to_castle <= record.def.leash_range + castle.get_radius()
	return false


func _king_up(king: KingState) -> bool:
	return king != null and not king.is_down()


## Walks toward the target (or the castle while there is none) and, once at its stop distance and
## off cooldown, queues one melee hit that lands this tick.
func _advance_and_strike(
	record: Record, tick: int, castle: CastleState, king: KingState, hits: PendingHits
) -> void:
	var goal: Vector2 = castle.get_position()
	var goal_radius: float = castle.get_radius()
	if record.target_kind == PendingHits.KIND_KING:
		goal = king.get_position()
		goal_radius = king.get_def().body_radius
	var attacking: bool = record.target_kind != &""
	var stop_distance: float = goal_radius + record.def.attack_range
	var remaining: float = record.position.distance_to(goal) - stop_distance
	if remaining > 0.0:
		var reach: float = minf(record.def.move_speed * SimClock.STEP, remaining)
		record.position += desired_step(record.position, goal, reach)
		remaining = record.position.distance_to(goal) - stop_distance
	if not attacking or remaining > ARRIVE_EPSILON or tick < record.cooldown_ready_tick:
		return
	hits.enqueue(
		tick,
		PendingHits.KIND_ENEMY,
		record.id,
		record.target_kind,
		record.target_id,
		record.def.attack_damage
	)
	_events.attack_fired.emit(
		PendingHits.KIND_ENEMY, record.id, record.target_kind, record.target_id, 0
	)
	record.cooldown_ready_tick = tick + SimClock.ticks(record.def.attack_interval)


## Pushes overlapping enemies apart (Pitfall 6). Positions are snapshotted once; every pair, in
## ascending id order, adds half the overlap to each member's displacement along their difference
## (a zero difference uses a fixed axis chosen by the lower id's parity, never a random one); the
## displacements are applied together, so the result does not depend on iteration side effects
## (DR-6, DR-8).
func _separate() -> void:
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
