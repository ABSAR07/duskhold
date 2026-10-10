class_name SquadSystem
extends RefCounted
## The friendly army (UNIT-04). One squad per military plot (Barracks, Archery Range), created the
## first time its building stands, kept for the rest of the run. By day a squad is filled to the
## seats its building tier fields and every unit stands at its formation slot around the squad's
## post. At night a free unit looks for an enemy within guard_range of the squad anchor on its
## own staggered rescan tick, commits to it until it dies or leaves leash_range of the anchor
## (never swapping to a nearer enemy), strikes through PendingHits once per attack_interval, and
## walks back to its slot when nothing is valid. Squads are stepped in creation order and their
## units in ascending id (DR-6), between the king and the towers (DR-8). No trigonometry, no
## engine clock, no global RNG (DR-1 to DR-10).

## Guard against a bad data file, not a tuning value: a squad never raises more units than this,
## whatever its building tier asks for (threat T-03-01).
const MAX_UNITS_PER_SQUAD: int = 50
## A unit counts as arrived when it is within this many metres of its stop distance, so float32
## positions that land a hair short still strike.
const ARRIVE_EPSILON: float = 0.001

var _map: MapConfig
var _buildings: BuildingSystem
var _events: SimEvents
var _units: UnitSystem
var _squads: Dictionary = {}
var _order: Array[StringName] = []


func _init(map: MapConfig, buildings: BuildingSystem, events: SimEvents) -> void:
	_map = map
	_buildings = buildings
	_events = events
	_units = UnitSystem.new(events)


func get_units() -> UnitSystem:
	return _units


## Squad ids (military spot ids) in creation order. A copy.
func squad_ids() -> Array[StringName]:
	return _order.duplicate()


## The unit type the squad fields; null for an unknown squad.
func unit_def_of(squad_id: StringName) -> UnitDef:
	var squad: Squad = _squads.get(squad_id) as Squad
	return squad.unit_def if squad != null else null


## Units of the squad that are alive; 0 for an unknown squad.
func alive_count(squad_id: StringName) -> int:
	var squad: Squad = _squads.get(squad_id) as Squad
	if squad == null:
		return 0
	var alive: int = 0
	for unit_id: int in squad.unit_ids:
		if _units.is_alive(unit_id):
			alive += 1
	return alive


## Seats the squad currently has; 0 for an unknown squad.
func max_count(squad_id: StringName) -> int:
	var squad: Squad = _squads.get(squad_id) as Squad
	return squad.cap if squad != null else 0


## Ids of the squad living units, ascending. A fresh array; empty for an unknown squad.
func unit_ids_of(squad_id: StringName) -> Array[int]:
	var result: Array[int] = []
	var squad: Squad = _squads.get(squad_id) as Squad
	if squad == null:
		return result
	for unit_id: int in squad.unit_ids:
		if _units.is_alive(unit_id):
			result.append(unit_id)
	return result


## Where the squad formation centres; the zero vector for an unknown squad.
func anchor_of(squad_id: StringName) -> Vector2:
	var squad: Squad = _squads.get(squad_id) as Squad
	return squad.anchor if squad != null else Vector2.ZERO


## Dawn: every squad is back to full numbers and health. Inert until the life cycle lands.
func restore_for_dawn() -> void:
	pass


## 0..1 toward the next replacement; 0 when none runs.
func replacement_progress(_squad_id: StringName) -> float:
	return 0.0


## A new night: attack cooldowns and targets are cleared. Stance, orders and the anchor are never
## touched here (D-14). A building finished in the very step the night began has had no day step to
## raise its squad, so its free seats are filled now; once the night runs they are never refilled
## by this call.
func begin_night() -> void:
	_sync(false)
	for unit_id: int in _units.ids():
		_units.set_target(unit_id, -1)
		_units.set_cooldown_ready(unit_id, 0)


## One step of the whole army. `tick` is the night tick at night and the run tick otherwise;
## `night` says whether enemies are to be fought. By day every free seat is filled at once and
## units only settle at their slots.
func step(tick: int, enemies: EnemySystem, hits: PendingHits, night: bool) -> void:
	_units.begin_step()
	_sync(night)
	for squad_id: StringName in _order:
		var squad: Squad = _squads[squad_id]
		for unit_id: int in squad.unit_ids:
			if _units.is_alive(unit_id):
				_step_unit(squad, unit_id, tick, enemies, hits, night)
	_units.separate()


## Forwards a landed hit to the unit; a hit on a gone unit drops silently.
func damage_unit(id: int, amount: int, killer_kind: StringName) -> void:
	_units.damage(id, amount, killer_kind)


## Removes dead units (unit_died, ascending id) and frees their formation slots.
func remove_dead() -> void:
	_units.remove_dead()
	for squad_id: StringName in _order:
		var squad: Squad = _squads[squad_id]
		var kept: Array[int] = []
		for unit_id: int in squad.unit_ids:
			if _units.def_of(unit_id) != null:
				kept.append(unit_id)
		squad.unit_ids = kept


## Polls the buildings in MapConfig spot order: a military plot whose building stands at tier 1 or
## above gets a squad the first time, and its seat count follows the tier. By day every free seat is
## filled (pull-based, so dawn rebuilds and upgrades need no listener, DR-11).
func _sync(night: bool) -> void:
	for spot_id: StringName in _buildings.spot_ids():
		var building_def: BuildingDef = _buildings.get_building_def_for_spot(spot_id)
		if building_def == null or building_def.unit_id == &"":
			continue
		var tier: int = _buildings.current_tier(spot_id)
		var tier_def: BuildingTierDef = building_def.tier_def(tier)
		var unit_def: UnitDef = _map.find_unit(building_def.unit_id)
		if tier_def == null or unit_def == null:
			continue
		var squad: Squad = _squads.get(spot_id) as Squad
		if squad == null:
			squad = _make_squad(spot_id, building_def, unit_def)
		squad.tier = tier
		squad.cap = clampi(tier_def.squad_size, 0, MAX_UNITS_PER_SQUAD)
		if not night:
			_fill(squad)


func _make_squad(spot_id: StringName, building_def: BuildingDef, unit_def: UnitDef) -> Squad:
	var squad: Squad = Squad.new()
	squad.id = spot_id
	squad.unit_def = unit_def
	var spot_position: Vector3 = _buildings.get_spot(spot_id).position
	var plot: Vector2 = Vector2(spot_position.x, spot_position.z)
	var castle: Vector2 = Vector2(_map.castle_position.x, _map.castle_position.z)
	var toward: Vector2 = castle - plot
	squad.home = plot
	if toward.length_squared() > 0.0:
		squad.home = plot + toward.normalized() * building_def.post_distance
	squad.anchor = squad.home
	_squads[spot_id] = squad
	_order.append(spot_id)
	return squad


## Seats a new unit in every free slot up to the squad cap, lowest slot first.
func _fill(squad: Squad) -> void:
	while _living_count(squad) < squad.cap:
		var slot: int = _lowest_free_slot(squad)
		var offset: Vector2 = SquadFormation.slot_offset(
			slot, squad.cap, squad.unit_def.formation_spacing
		)
		var unit_id: int = _units.spawn(squad.unit_def, squad.id, slot, squad.anchor + offset)
		squad.unit_ids.append(unit_id)


func _living_count(squad: Squad) -> int:
	var living: int = 0
	for unit_id: int in squad.unit_ids:
		if _units.is_alive(unit_id):
			living += 1
	return living


func _lowest_free_slot(squad: Squad) -> int:
	var taken: Dictionary = {}
	for unit_id: int in squad.unit_ids:
		if _units.is_alive(unit_id):
			taken[_units.slot_of(unit_id)] = true
	var slot: int = 0
	while taken.has(slot):
		slot += 1
	return slot


## One unit decides and acts: target choice (commit, leash, staggered rescan), then walk and strike,
## or walk back to its slot.
func _step_unit(
	squad: Squad, unit_id: int, tick: int, enemies: EnemySystem, hits: PendingHits, night: bool
) -> void:
	var def: UnitDef = squad.unit_def
	var target: int = _units.target_of(unit_id)
	if night:
		target = _choose_target(squad, unit_id, target, tick, enemies)
	else:
		target = -1
	_units.set_target(unit_id, target)
	if target < 0:
		_walk_to_slot(squad, unit_id)
		return
	var goal: Vector2 = enemies.position_of(target)
	var stop_distance: float = def.attack_range
	if def.projectile_speed <= 0.0:
		stop_distance += enemies.def_of(target).radius
	var here: Vector2 = _units.position_of(unit_id)
	var remaining: float = here.distance_to(goal) - stop_distance
	if remaining > 0.0:
		var reach: float = minf(def.move_speed * SimClock.STEP, remaining)
		here += EnemySystem.desired_step(here, goal, reach)
		_units.set_position_of(unit_id, here)
		remaining = here.distance_to(goal) - stop_distance
	if remaining > ARRIVE_EPSILON or tick < _units.cooldown_ready_of(unit_id):
		return
	var flight: int = SimClock.flight_ticks(here.distance_to(goal), def.projectile_speed)
	hits.enqueue(
		tick + flight,
		PendingHits.KIND_UNIT,
		unit_id,
		PendingHits.KIND_ENEMY,
		target,
		def.attack_damage
	)
	_events.attack_fired.emit(
		PendingHits.KIND_UNIT, unit_id, PendingHits.KIND_ENEMY, target, flight
	)
	_units.set_cooldown_ready(unit_id, tick + SimClock.ticks(def.attack_interval))


## Keeps a committed target while it is alive and within leash_range of the anchor; otherwise looks
## for the nearest enemy within guard_range of the anchor, but only on the unit own staggered
## rescan tick (Pitfall 5). Returns the enemy id, or -1.
func _choose_target(
	squad: Squad, unit_id: int, current: int, tick: int, enemies: EnemySystem
) -> int:
	var def: UnitDef = squad.unit_def
	if current >= 0 and enemies.is_alive(current):
		var limit: float = def.leash_range * def.leash_range
		if squad.anchor.distance_squared_to(enemies.position_of(current)) <= limit:
			return current
	var rescan_ticks: int = maxi(SimClock.ticks(def.retarget_interval_seconds), 1)
	if not EnemySystem.is_rescan_tick(tick, unit_id, rescan_ticks):
		return -1
	return TargetQuery.nearest_enemy(enemies, squad.anchor, def.guard_range)


## With nothing to fight a unit walks back to its formation slot around the anchor.
func _walk_to_slot(squad: Squad, unit_id: int) -> void:
	var def: UnitDef = squad.unit_def
	var slot_position: Vector2 = (
		squad.anchor
		+ SquadFormation.slot_offset(_units.slot_of(unit_id), squad.cap, def.formation_spacing)
	)
	var here: Vector2 = _units.position_of(unit_id)
	var reach: float = def.move_speed * SimClock.STEP
	_units.set_position_of(unit_id, here + EnemySystem.desired_step(here, slot_position, reach))
