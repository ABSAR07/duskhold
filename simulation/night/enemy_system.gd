class_name EnemySystem
extends RefCounted
## Every enemy alive in the current night, addressed by an id that only ever grows and is never
## reused (Pattern 3: callers never touch the storage). Positions are Vector2 on the XZ plane.
## Iteration is always in ascending id order (DR-6).
##
## The storage and the whole enemy step run in C++ (PLAT-01, plan 04-19):
## native/src/native_enemies.cpp keeps the enemies and the grid behind living_within, and
## native/src/enemy_step.cpp is the step (the D-08 wall times, every target choice with the
## held-for-target rule of plan 04-12 and the castle march's break-or-detour rule, the walk and
## strike, the push-apart and the push out of the walls). It is an exact port of the GDScript step
## this file held until plan 04-19 (git show 2483384:simulation/night/enemy_system.gd), proven tick
## by tick by the traces of tools/stress/enemy_trace.gd committed in
## tests/fixtures/trace/enemy_step_refs.txt. What stays GDScript is this facade: the 18 public
## methods, the def table the native step reads (refreshed from every registered EnemyDef at the
## start of each step, because the numbers were read live from the resource), the events, the hit
## queue and the killer kinds. A missing native library is the hard error of plan 04-14, never a
## fallback.

## The kind words of a target, indexed by the small integers the native store uses (the
## EnemyTargetKind enum of native_enemies.h): none, king, unit, building, castle, wall.
const KIND_NAMES: Array[StringName] = [
	&"",
	PendingHits.KIND_KING,
	PendingHits.KIND_UNIT,
	PendingHits.KIND_BUILDING,
	PendingHits.KIND_CASTLE,
	PendingHits.KIND_WALL,
]
## Values per strike the native walk pass answers: arrival tick, attacker id, target kind, target
## id, damage and flight ticks (NativeEnemies.STRIKE_STRIDE).
const STRIKE_STRIDE: int = 6
## EnemyDef flags for the native def table.
const FLAG_IGNORES_WALLS: int = 1
const FLAG_DROPS_BLOCKED_TARGETS: int = 2

var _events: SimEvents
## The enemies and the step in C++.
var _native: NativeEnemies = NativeEnemies.new()
## The defs the native table was filled from, indexed by the table index; _def_slots is the reverse.
var _defs: Array[EnemyDef] = []
var _def_slots: Dictionary = {}
## The attacker kind that landed the lethal hit, by enemy id, until the enemy is removed.
var _killers: Dictionary = {}
var _died_total: int = 0
## The nearest-structure grid, rebuilt once per step: structures do not move in the enemy phase.
var _structures: StructureIndex = StructureIndex.new()
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
	var index: int = _def_index(def)
	var id: int = _native.spawn(
		index,
		pos,
		def.max_health,
		maxi(SimClock.ticks(def.retarget_interval_seconds), 1),
		WallDecision.damage_per_300(def.attack_damage, SimClock.ticks(def.attack_interval)),
		roundi(def.move_speed * 100.0)
	)
	_mark_changed()
	_events.enemy_spawned.emit(id, def.id, pos)
	return id


## Ids of the enemies on the field, ascending. A copy.
func ids() -> Array[int]:
	var listed: Array[int] = []
	listed.assign(_native.ids())
	return listed


func count() -> int:
	return _native.count()


## How many enemies have been removed as dead since the last clear.
func died_count() -> int:
	return _died_total


func is_alive(id: int) -> bool:
	return _native.is_alive(id)


## What enemy `id` is attacking or walking toward: {"kind": StringName, "id": int}, a fresh
## Dictionary per call; empty while it marches without a target and for an unknown id. Read-only
## (the debug overlay and the path gizmo read it).
func target_of(id: int) -> Dictionary:
	var target: PackedInt64Array = _native.target_of(id)
	if target.is_empty():
		return {}
	return {"kind": KIND_NAMES[target[0]], "id": target[1]}


## Zero vector for an unknown id.
func position_of(id: int) -> Vector2:
	return _native.position_of(id)


## Where the enemy stood one step ago; the puppet interpolates from here.
func previous_position_of(id: int) -> Vector2:
	return _native.previous_of(id)


## Null for an unknown id.
func def_of(id: int) -> EnemyDef:
	var index: int = _native.def_index_of(id)
	return _defs[index] if index >= 0 else null


## 0 for an unknown id.
func health_of(id: int) -> int:
	return _native.health_of(id)


## Removes `amount` hit points (never below 0) and emits enemy_damaged. An unknown or already dead
## id, or a non-positive amount, is ignored: a hit on a gone target drops silently. The killing
## attacker's kind is remembered for the enemy_died event.
func damage(id: int, amount: int, killer_kind: StringName) -> void:
	var left: int = _native.damage(id, amount)
	if left < 0:
		return
	if left == 0:
		_killers[id] = killer_kind
		_mark_changed()
	_events.enemy_damaged.emit(id, amount, left)


## The enemy phase of a night step (DR-8). Every living enemy, in id order, chooses a target
## (committed until it is invalid or a staggered rescan finds a better one), walks toward it and
## stops at `target radius + attack_range`, then strikes through the pending-hit queue once per
## attack_interval. After all of them moved, overlapping enemies are pushed apart. A destroyed
## castle leaves nothing to march on, so the field stands still. `king` may be null in tests that
## have none; then nobody targets him. `buildings` may be null in tests that have none; then the
## castle is the only structure to attack. `units` may be null; then nobody targets friendly
## units, byte for byte the Phase 2 behaviour. `pathing` may be null; then no wall is solid and no
## enemy attacks one. While no wall segment stands the step is the same code as without `pathing`.
## Otherwise an enemy whose straight line to its goal crosses an intact segment attacks that
## segment (the sealed case of D-07), and after the push-apart every enemy is pushed out of the
## intact segments (D-04), except one whose def sets ignores_walls. The rules are in
## native/src/enemy_step.cpp; this method drives them in the order the GDScript step had: the
## previous-position copy, the destroyed-castle return, the structure snapshot, the native
## target-and-walk pass, each strike enqueued and announced (attack_fired) in ascending attacker
## id, then the native push-apart pass.
func step(
	tick: int,
	castle: CastleState,
	king: KingState,
	hits: PendingHits,
	buildings: BuildingSystem = null,
	units: UnitSystem = null,
	pathing: Pathing = null
) -> void:
	_mark_changed()
	_native.begin_step()
	if castle.is_destroyed():
		return
	_structures.rebuild(units, buildings, castle)
	var solid: bool = pathing != null and pathing.has_intact_walls()
	_refresh_defs()
	_hand_over_world(pathing)
	var king_up: bool = king != null and not king.is_down()
	var king_position: Vector2 = Vector2.ZERO
	var king_radius: float = 0.0
	if king_up:
		king_position = king.get_position()
		king_radius = king.get_def().body_radius
	var strikes: PackedInt64Array = _native.walk_pass(
		tick, castle.get_position(), castle.get_radius(), king_up, king_position, king_radius, solid
	)
	_emit_strikes(strikes, hits)
	_native.separate_pass(solid)
	_mark_changed()


## Ids of the enemies whose grid cell lies within `reach` of `pos`'s cell, ascending: a superset of
## the living enemies within `reach` metres, for the caller to narrow with its own exact test. Dead
## enemies that have not been removed yet may be listed. Read-only; the grid is rebuilt first when
## the field changed since the last query.
func living_within(pos: Vector2, reach: float) -> PackedInt64Array:
	return _native.living_within(pos, reach)


## The id of the living enemy nearest `pos` whose centre is within `reach` (inclusive, squared
## distances compared; equally near enemies go to the lower id), or -1: the answer of every
## "nearest enemy" question of the night, in C++ (plan 04-20). With `walls` standing (at least one
## intact segment) only an enemy whose straight line from `pos` is clear of every intact segment,
## for a walker of `radius` metres, counts; only a candidate that would improve the best pays for
## the line test. Read-only; TargetQuery is the seam the callers use.
func nearest_living(
	pos: Vector2, reach: float, radius: float = -1.0, walls: WallSystem = null
) -> int:
	var mirror: NativeWalls = null
	if walls != null and walls.intact_count() > 0:
		mirror = walls.native()
	return _native.nearest_living(pos, reach, radius, mirror)


## The enemy field as packed arrays (ids ascending, with previous and current positions), refilled
## only when something changed since the last read. The same object every time, so a caller reads
## it and never keeps it across a step. Emits no signal.
func read_view() -> CrowdReadView:
	if _view.version == _changes:
		return _view
	_view.ids = _native.view_ids()
	_view.previous = _native.view_previous()
	_view.current = _native.view_current()
	_view.targeted = _native.view_targeted()
	_view.living = _native.view_living()
	_view.version = _changes
	return _view


## Removes dead enemies in ascending id order and emits enemy_died for each.
func remove_dead() -> void:
	_mark_changed()
	for id: int in _native.dead_ids():
		var def: EnemyDef = _defs[_native.def_index_of(id)]
		var pos: Vector2 = _native.position_of(id)
		var killer: StringName = _killers.get(id, &"")
		_killers.erase(id)
		_native.remove(id)
		_died_total += 1
		_mark_changed()
		_events.enemy_died.emit(id, def.id, pos, killer)


## Empties the field for a new night. Ids keep growing: they are never reused.
func clear() -> void:
	_native.clear()
	_killers.clear()
	_died_total = 0
	_mark_changed()


## The field changed: the read view is stale until the next read (the native grid tracks its own).
func _mark_changed() -> void:
	_changes += 1


## The table index of `def`, registering it (and filling its row) the first time it is seen.
func _def_index(def: EnemyDef) -> int:
	if _def_slots.has(def):
		return _def_slots[def]
	var index: int = _defs.size()
	_defs.append(def)
	_def_slots[def] = index
	_push_def(index)
	return index


## Copies the numbers of the def at `index` into the native table.
func _push_def(index: int) -> void:
	var def: EnemyDef = _defs[index]
	var flags: int = 0
	if def.ignores_walls:
		flags |= FLAG_IGNORES_WALLS
	if def.drops_blocked_targets:
		flags |= FLAG_DROPS_BLOCKED_TARGETS
	var numbers: PackedFloat64Array = PackedFloat64Array(
		[
			def.move_speed,
			def.radius,
			def.attack_range,
			def.aggro_range,
			def.leash_range,
			def.projectile_speed,
			def.attack_interval,
		]
	)
	_native.set_def(index, numbers, def.attack_damage, flags)


## The numbers were read live from each def in GDScript, so every step refreshes the table.
func _refresh_defs() -> void:
	for index: int in range(_defs.size()):
		_push_def(index)


## Hands the native step the wall mirror, the castle route, the decision and the structure
## snapshot of this step (null for what a caller without pathing does not have). The route lives
## in Pathing's private member: the facade is at its 20-method cap, so it gets no accessor.
func _hand_over_world(pathing: Pathing) -> void:
	var walls: NativeWalls = null
	var route: NativeRoute = null
	var decision: NativeWallDecision = null
	if pathing != null:
		if pathing.walls() != null:
			walls = pathing.walls().native()
		route = pathing._route
		decision = pathing.decision().native()
	_native.set_world(walls, route, decision, _structures.native())


## Queues each strike of the walk pass and announces it, in ascending attacker id.
func _emit_strikes(strikes: PackedInt64Array, hits: PendingHits) -> void:
	for base: int in range(0, strikes.size(), STRIKE_STRIDE):
		var kind: StringName = KIND_NAMES[strikes[base + 2]]
		hits.enqueue(
			strikes[base],
			PendingHits.KIND_ENEMY,
			strikes[base + 1],
			kind,
			strikes[base + 3],
			strikes[base + 4]
		)
		_events.attack_fired.emit(
			PendingHits.KIND_ENEMY, strikes[base + 1], kind, strikes[base + 3], strikes[base + 5]
		)
