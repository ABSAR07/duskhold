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
## The pathing facade of the step in progress; null when the caller has none (Phase 3 behaviour).
var _pathing: Pathing


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
	record.per_300 = WallDecision.damage_per_300(
		def.attack_damage, SimClock.ticks(def.attack_interval)
	)
	record.speed_cm = roundi(def.move_speed * 100.0)
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
## units, byte for byte the Phase 2 behaviour. `pathing` may be null; then no wall is solid and no
## enemy attacks one. While no wall segment stands the step is the same code as without `pathing`.
## Otherwise an enemy whose straight line to its goal crosses an intact segment attacks that
## segment (the sealed case of D-07), and after the push-apart every enemy is pushed out of the
## intact segments (D-04), except one whose def sets ignores_walls.
func step(
	tick: int,
	castle: CastleState,
	king: KingState,
	hits: PendingHits,
	buildings: BuildingSystem = null,
	units: UnitSystem = null,
	pathing: Pathing = null
) -> void:
	_units = units
	_pathing = pathing
	_mark_changed()
	for id: int in _order:
		var record: Record = _records[id]
		record.previous = record.position
	if castle.is_destroyed():
		return
	_structures.rebuild(units, buildings, castle)
	if _walls_are_solid():
		_publish_wall_times(tick)
	for id: int in _order:
		var record: Record = _records[id]
		if record.health <= 0:
			continue
		_choose_target(record, tick, castle, king, buildings)
		_advance_and_strike(record, tick, castle, king, hits, buildings)
	_separate()
	if _walls_are_solid():
		_push_out_of_walls()
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
## While a wall stands the line to the target matters, per kind of enemy (owner decision of
## 2026-10-19, UAT test 13, gap G-04-7): a default melee enemy (_breaks_to_targets) breaks through
## to a king, unit or building it can reach only through a wall, remembering that target while it
## attacks the segment in the way; a target in sight still wins, the castle is never a target behind
## a wall and the target-less castle march keeps the 04-07 break-or-detour rule. A ranged enemy
## shoots over walls within its attack range, and an enemy with drops_blocked_targets keeps the
## 04-06 rule: a target it has no clear line to is dropped and it marches on the castle.
func _choose_target(
	record: Record, tick: int, castle: CastleState, king: KingState, buildings: BuildingSystem
) -> void:
	if record.behind_kind != &"":
		_release_held_wall(record, tick, castle, king, buildings)
	var chosen: bool = _choose_base_target(record, tick, castle, king, buildings)
	if _walls_are_solid() and not record.def.ignores_walls:
		_target_walls_in_the_way(record, tick, chosen, castle, king, buildings)


## The target choice of Phase 3, unchanged. True when it assigned a target on this call (the king
## or the nearest structure), false when it kept the committed one or found none.
func _choose_base_target(
	record: Record, tick: int, castle: CastleState, king: KingState, buildings: BuildingSystem
) -> bool:
	var valid: bool = record.target_kind != &"" and _target_valid(record, castle, king, buildings)
	var rescan: bool = is_rescan_tick(tick, record.id, record.rescan_ticks)
	if valid and rescan and not _target_in_sight(record, castle, king, buildings):
		valid = false
	if valid and not rescan:
		return false
	if valid and record.target_kind == PendingHits.KIND_KING:
		return false
	if (
		_king_up(king)
		and record.position.distance_to(king.get_position()) <= record.def.aggro_range
		and _can_see(record, king.get_position(), king.get_def().body_radius)
	):
		record.target_kind = PendingHits.KIND_KING
		record.target_id = 0
		record.behind_kind = &""
		return true
	if valid:
		return false
	record.target_kind = &""
	record.target_id = 0
	record.behind_kind = &""
	_pick_nearest_structure(record)
	return record.target_kind != &""


## D-07 and D-08: an enemy whose straight line to its goal crosses an intact segment attacks that
## segment when breaking it is faster than the detour (or there is none), until it breaks, then
## walks on through the hole; otherwise it marches round on the castle field. A target chosen on
## this call is line-tested at once and a held target on the enemy's own rescan tick. An enemy with
## no target tests its line to the castle only on its rescan tick, caches the answer on the record
## and decides once it is within the notice range, so 300 marchers pay about 20 line tests a tick.
## An enemy already attacking a segment gives it up on a rescan tick only when the detour wins by
## more than the hysteresis (WallDecision.keep_breaking). A default melee enemy with a king, unit
## or building target (_breaks_to_targets) takes the segment its centre line crosses (radius 0, so a
## line that only grazes a gap's edge is clear), remembers the target in behind_kind and keeps the
## segment until _release_held_wall lets it go: the castle detour never frees it.
func _target_walls_in_the_way(
	record: Record,
	tick: int,
	chosen: bool,
	castle: CastleState,
	king: KingState,
	buildings: BuildingSystem
) -> void:
	var rescan: bool = is_rescan_tick(tick, record.id, record.rescan_ticks)
	if record.target_kind == PendingHits.KIND_WALL:
		if record.behind_kind != &"" or not rescan or _keeps_breaking(record):
			return
		record.wall_given_up = record.target_id
		record.target_kind = &""
		record.target_id = 0
	if record.target_kind == &"":
		_aim_at_walls(record, rescan, castle)
		return
	record.wall_seg = -1
	if not chosen and not rescan:
		return
	var breaks: bool = _breaks_to_targets(record)
	if breaks and record.target_kind == PendingHits.KIND_CASTLE:
		return
	var goal: Vector2 = _goal_of(record, castle, king, buildings)
	if _shoots_over(record, goal, _goal_radius_of(record, castle, king, buildings)):
		return
	var held_kind: StringName = record.target_kind
	var held_id: int = record.target_id
	var line_radius: float = 0.0 if breaks else record.def.radius
	_take_wall(
		record, _pathing.first_blocking(record.position, goal, line_radius), record.def.leash_range
	)
	if breaks and record.target_kind == PendingHits.KIND_WALL:
		record.behind_kind = held_kind
		record.behind_id = held_id


## True for a default melee enemy while walls stand: no projectile, it does not pass over walls and
## its def does not keep the 04-06 rule (drops_blocked_targets). Such an enemy breaks the wall in
## its way to reach a king, unit or building target (G-04-7).
func _breaks_to_targets(record: Record) -> bool:
	return (
		_walls_are_solid()
		and not record.def.ignores_walls
		and not record.def.drops_blocked_targets
		and record.def.projectile_speed <= 0.0
	)


## Lets go of a segment held for a target (record.behind_kind set) and puts the target back, when
## the segment no longer stands or, on the enemy's rescan tick, when the centre line to the target
## no longer crosses it. When the target itself is gone (dead, fallen, knocked out or past the
## leash) the enemy is left without one and chooses again. Otherwise the held segment stays.
func _release_held_wall(
	record: Record, tick: int, castle: CastleState, king: KingState, buildings: BuildingSystem
) -> void:
	var segment: int = record.target_id
	record.target_kind = record.behind_kind
	record.target_id = record.behind_id
	var release: bool = false
	if not _target_valid(record, castle, king, buildings):
		record.target_kind = &""
		record.target_id = 0
		release = true
	elif not _pathing.walls().is_intact(segment):
		release = true
	elif is_rescan_tick(tick, record.id, record.rescan_ticks):
		var goal: Vector2 = _goal_of(record, castle, king, buildings)
		release = _pathing.first_blocking(record.position, goal, 0.0) != segment
	if release:
		record.behind_kind = &""
		record.behind_id = 0
		record.wall_seg = -1
	else:
		record.target_kind = PendingHits.KIND_WALL
		record.target_id = segment


## The target-less marcher's side of the wall rule. On its rescan tick it refreshes the segment in
## the way of its line to the castle, whether a way round exists (castle_blocked) and whether it is
## aggroed onto that segment (wall_seg, within the notice range of its face). Aggroed, it takes the
## segment on any tick when breaking it is faster than its detour, or when it is sealed.
func _aim_at_walls(record: Record, rescan: bool, castle: CastleState) -> void:
	if rescan:
		record.castle_blocker = _pathing.first_blocking(
			record.position, castle.get_position(), record.def.radius
		)
		record.castle_blocked = (
			record.castle_blocker >= 0 and not _pathing.is_sealed(record.position)
		)
		record.wall_seg = -1
		if (
			record.castle_blocker >= 0
			and (
				_wall_edge(record.position, record.castle_blocker)
				<= _pathing.decision().notice_range()
			)
		):
			record.wall_seg = record.castle_blocker
	if record.wall_seg < 0 or not _pathing.walls().is_intact(record.wall_seg):
		return
	if not _breaking_is_faster(record, record.wall_seg):
		return
	_take_wall(
		record, record.wall_seg, minf(_pathing.decision().notice_range(), record.def.leash_range)
	)


## True when the time to destroy `segment` plus the straight walk to the castle is shorter than the
## detour from where the enemy stands, or there is no detour (D-07). An enemy that gave a segment up
## does not take it again while a way round exists: the crowd near it thins as the others walk
## through, so the estimate dithers around the break-even and would flip it back and forth.
func _breaking_is_faster(record: Record, segment: int) -> bool:
	var ticks: Vector3i = _wall_ticks(record, segment)
	if segment == record.wall_given_up and ticks.z < SimClock.MAX_TICKS:
		return false
	return WallDecision.should_break(ticks.x, ticks.y, ticks.z)


## True while an enemy attacking a segment should go on with it (hysteresis).
func _keeps_breaking(record: Record) -> bool:
	var ticks: Vector3i = _wall_ticks(record, record.target_id)
	return WallDecision.keep_breaking(
		ticks.x, ticks.y, ticks.z, _pathing.decision().hysteresis_ticks()
	)


## The time to destruction of `segment`, the straight walk to the castle and the detour for this
## enemy, in ticks, as (x, y, z).
func _wall_ticks(record: Record, segment: int) -> Vector3i:
	return Vector3i(
		_pathing.decision().ttd_of(segment),
		_pathing.straight_ticks(record.position, record.speed_cm),
		_pathing.detour_ticks(record.position, record.speed_cm)
	)


## D-08: counts every living enemy aggroed onto a standing segment, in ascending id, and publishes
## the time to destruction of the segments due on this tick.
func _publish_wall_times(tick: int) -> void:
	var decision: WallDecision = _pathing.decision()
	decision.begin_tick(tick)
	for id: int in _order:
		var record: Record = _records[id]
		if record.health > 0 and record.wall_seg >= 0:
			if _pathing.walls().is_intact(record.wall_seg):
				decision.add_attacker(record.wall_seg, record.per_300)
			else:
				record.wall_seg = -1
	decision.end_tick()


## Makes `segment` the record's target when it still stands and its face is within `reach`.
func _take_wall(record: Record, segment: int, reach: float) -> void:
	if segment < 0 or not _pathing.walls().is_intact(segment):
		return
	if _wall_edge(record.position, segment) > reach:
		return
	record.target_kind = PendingHits.KIND_WALL
	record.target_id = segment
	record.wall_seg = segment


## Distance from `pos` to the face of the segment; negative inside its solid.
func _wall_edge(pos: Vector2, segment: int) -> float:
	var nearest: Vector2 = _pathing.closest_point(segment, pos)
	return pos.distance_to(nearest) - _pathing.walls().half_thickness_of(segment)


## Where the record's target stands: the king, the unit or building, else the castle.
func _goal_of(
	record: Record, castle: CastleState, king: KingState, buildings: BuildingSystem
) -> Vector2:
	if record.target_kind == PendingHits.KIND_KING:
		return king.get_position()
	if record.target_kind == PendingHits.KIND_BUILDING:
		var spot: BuildSpotDef = buildings.get_spot(buildings.spot_at_index(record.target_id))
		return Vector2(spot.position.x, spot.position.z)
	if record.target_kind == PendingHits.KIND_UNIT:
		return _units.position_of(record.target_id)
	return castle.get_position()


## The radius of the record's target: the king's body, the unit or building, else the castle.
func _goal_radius_of(
	record: Record, castle: CastleState, king: KingState, buildings: BuildingSystem
) -> float:
	if record.target_kind == PendingHits.KIND_KING:
		return king.get_def().body_radius
	if record.target_kind == PendingHits.KIND_BUILDING:
		return buildings.radius_of(buildings.spot_at_index(record.target_id))
	if record.target_kind == PendingHits.KIND_UNIT:
		return _units.def_of(record.target_id).radius
	return castle.get_radius()


## True while an enemy may keep or choose a target at `centre` under the 04-06 rule (RESEARCH Open
## Question 3): no wall stands, the def passes over walls, the straight line is clear of every
## intact segment, or the enemy is ranged and the target's edge is within its attack range. A
## default melee enemy no longer asks (owner decision of 2026-10-19, G-04-7: it breaks through to
## the target); a ranged enemy and one with drops_blocked_targets still do.
func _can_see(record: Record, centre: Vector2, target_radius: float) -> bool:
	if not _walls_are_solid() or record.def.ignores_walls:
		return true
	if _pathing.first_blocking(record.position, centre, record.def.radius) < 0:
		return true
	return _shoots_over(record, centre, target_radius)


## True for a ranged enemy (projectile_speed above 0) whose target's edge is within its attack
## range: its shots arc over a wall in between.
func _shoots_over(record: Record, centre: Vector2, target_radius: float) -> bool:
	if record.def.projectile_speed <= 0.0:
		return false
	return record.position.distance_to(centre) - target_radius <= record.def.attack_range


## True while the held target is in sight. A wall target always is.
func _target_in_sight(
	record: Record, castle: CastleState, king: KingState, buildings: BuildingSystem
) -> bool:
	if record.target_kind == PendingHits.KIND_WALL:
		return true
	return _can_see(
		record,
		_goal_of(record, castle, king, buildings),
		_goal_radius_of(record, castle, king, buildings)
	)


## True when a pathing facade was given and a wall segment stands somewhere.
func _walls_are_solid() -> bool:
	return _pathing != null and _pathing.has_intact_walls()


## D-04: after the push-apart every living enemy, in ascending id, is moved out of the intact
## segments, unless its def lets it pass over them.
func _push_out_of_walls() -> void:
	for id: int in _order:
		var record: Record = _records[id]
		if record.health > 0 and not record.def.ignores_walls:
			record.position = _pathing.push_out(record.position, record.def.radius)


## Sets the target to the nearest living unit, standing building or the castle by edge distance
## (centre distance minus radius), if one is within aggro_range. The answer comes from the
## StructureIndex, which tests the candidates in the shipped order: a strictly smaller edge distance
## is needed to replace an earlier candidate, so units are tried first (in id order), then
## buildings in spot order and the castle last.
func _pick_nearest_structure(record: Record) -> void:
	var found: Vector3i
	if _breaks_to_targets(record):
		found = _structures.nearest_visible(
			record.position, record.def.aggro_range, _pathing, 0.0, -1.0
		)
		if found.z == 0:
			found = _structures.nearest_through_walls(record.position, record.def.aggro_range)
	elif _walls_are_solid() and not record.def.ignores_walls:
		var ranged_reach: float = -1.0
		if record.def.projectile_speed > 0.0:
			ranged_reach = record.def.attack_range
		found = _structures.nearest_visible(
			record.position, record.def.aggro_range, _pathing, record.def.radius, ranged_reach
		)
	else:
		found = _structures.nearest(record.position, record.def.aggro_range)
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
		return _castle_target_valid(record, castle)
	if record.target_kind == PendingHits.KIND_BUILDING:
		return _building_target_valid(record, buildings)
	if record.target_kind == PendingHits.KIND_UNIT:
		return _unit_target_valid(record)
	if record.target_kind == PendingHits.KIND_WALL:
		return _wall_target_valid(record)
	return false


## The castle is a valid target while it stands and is inside leash_range.
func _castle_target_valid(record: Record, castle: CastleState) -> bool:
	if castle.is_destroyed():
		return false
	var to_castle: float = record.position.distance_to(castle.get_position())
	return to_castle <= record.def.leash_range + castle.get_radius()


## The king is a valid target while he is up and inside leash_range.
func _king_target_valid(record: Record, king: KingState) -> bool:
	if not _king_up(king):
		return false
	return record.position.distance_to(king.get_position()) <= record.def.leash_range


## A wall target is valid while its segment stands and its face is inside leash_range.
func _wall_target_valid(record: Record) -> bool:
	if _pathing == null or not _pathing.walls().is_intact(record.target_id):
		return false
	return _wall_edge(record.position, record.target_id) <= record.def.leash_range


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
	elif record.target_kind == PendingHits.KIND_WALL:
		goal = _pathing.closest_point(record.target_id, record.position)
		goal_radius = _pathing.walls().half_thickness_of(record.target_id)
	var attacking: bool = record.target_kind != &""
	var stop_distance: float = goal_radius + record.def.attack_range
	var remaining: float = record.position.distance_to(goal) - stop_distance
	if remaining > 0.0:
		var reach: float = minf(record.def.move_speed * SimClock.STEP, remaining)
		if record.castle_blocked and not attacking and _walls_are_solid():
			record.position += _pathing.march_step(record.position, reach)
		else:
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
	## The intact segment across its straight line to the castle as of its last rescan tick, or -1
	## (D-07): a marching enemy pays a line test once per rescan period, not once per tick.
	var castle_blocker: int = -1
	## True while that line is blocked and a way round exists (ENMY-04): a target-less enemy then
	## follows the castle flow field instead of the straight line. Refreshed with castle_blocker.
	var castle_blocked: bool = false
	## Damage per 10 s (300 ticks) and speed in cm/s, cached at spawn for the wall decision.
	var per_300: int = 0
	var speed_cm: int = 0
	## The standing segment it is aggroed onto (blocking its way within the notice range, or being
	## attacked), or -1 (D-07, D-08).
	var wall_seg: int = -1
	## The segment it gave up for the detour (hysteresis), which it does not take again, or -1.
	var wall_given_up: int = -1
	## While it attacks a segment standing between it and a king, unit or building target (G-04-7),
	## that target's kind (empty otherwise) and id: the segment is held for it, and the target comes
	## back when the segment breaks.
	var behind_kind: StringName = &""
	var behind_id: int = 0
