class_name NightSim
extends RefCounted
## Orchestrates one night in a fixed order (DR-8): spawn, the nav grid and castle field rebuilt when
## the walls changed (once per step), king, squads (creation order, units in id
## order), towers (spot order), castle, enemies (id order, then pushed out of the intact wall
## segments; the read-only stuck flags are refreshed), resolve due hits (a wall segment that
## reaches 0 breaks here), remove the dead enemies, remove the dead units. Outside the night
## `step_day` steps the army alone. Pure RefCounted code on integer ticks (DR-1, DR-3); the only
## randomness is the night's seeded spawn stream, drawn at spawn time in spawn order (DR-4).

var _map: MapConfig
var _events: SimEvents
var _king: KingState
var _castle: CastleState
var _buildings: BuildingSystem
var _walls: WallSystem
var _pathing: Pathing
var _run_seed: int
var _enemies: EnemySystem
var _towers: TowerSystem
var _stat_stack: StatStack
var _squads: SquadSystem
var _castle_attack: CastleAttack
var _hits: PendingHits = PendingHits.new()
var _schedule: WaveSchedule
var _spawn_rng: RandomNumberGenerator
var _night_number: int = 0
var _start_tick: int = 0
var _next_night_tick: int = 0
var _awaiting_first_step: bool = false


func _init(
	map: MapConfig,
	events: SimEvents,
	king: KingState,
	run_seed: int,
	castle: CastleState = null,
	buildings: BuildingSystem = null,
	squads: SquadSystem = null,
	walls: WallSystem = null,
	stat_stack: StatStack = null
) -> void:
	_map = map
	_stat_stack = stat_stack if stat_stack != null else StatStack.new()
	_events = events
	_king = king
	_castle = castle if castle != null else CastleState.new(map, events, _stat_stack)
	_buildings = buildings if buildings != null else BuildingSystem.new(map, events, _stat_stack)
	_walls = walls if walls != null else WallSystem.new(map, _buildings, events, _stat_stack)
	_pathing = Pathing.new(map, _walls)
	_run_seed = run_seed
	_squads = squads if squads != null else SquadSystem.new(map, _buildings, events, _stat_stack)
	_enemies = EnemySystem.new(events)
	_towers = TowerSystem.new(_buildings, events, _stat_stack)
	_castle_attack = CastleAttack.new(map, _castle, events)


## True when the map authors its own nights; otherwise the Phase 1 timed night applies.
func has_authored_nights() -> bool:
	return not _map.nights.is_empty()


## How many nights the map authors (0 on a map that keeps the Phase 1 timed night).
func total_nights() -> int:
	return _map.nights.size()


## Loads night `night_number` (1-based). The next `step` call is night tick 0.
func begin_night(night_number: int) -> void:
	_night_number = night_number
	_schedule = WaveSchedule.new(_map, night_number)
	_spawn_rng = SimRng.make(_run_seed, night_number, SimRng.STREAM_SPAWN)
	_hits.clear()
	_enemies.clear()
	_pathing.stuck().clear()
	_king.begin_night()
	_squads.begin_night()
	_towers.begin_night()
	_castle_attack.begin_night()
	_next_night_tick = 0
	_awaiting_first_step = true


## Advances the night by one step. `tick` is the run's tick; the night keeps its own clock.
func step(tick: int) -> void:
	if _schedule == null:
		return
	if _awaiting_first_step:
		_start_tick = tick
		_awaiting_first_step = false
	var night_tick: int = tick - _start_tick
	_spawn_due(night_tick)
	_pathing.refresh()
	_king.step(night_tick, _enemies, _hits)
	_squads.step(night_tick, _enemies, _hits, true, _king.get_position(), _pathing)
	_towers.step(night_tick, _enemies, _hits)
	_castle_attack.step(night_tick, _enemies, _hits)
	_enemies.step(night_tick, _castle, _king, _hits, _buildings, _squads.get_units(), _pathing)
	_pathing.stuck().update(night_tick, _enemies, _pathing)
	_resolve_hits(night_tick)
	_enemies.remove_dead()
	_squads.remove_dead()
	_next_night_tick = night_tick + 1


## Advances the army by one step outside the night: units fill their seats and settle at their
## slots, and a slam armed by day resolves with the same code as at night (it hits nothing, since no
## enemy lives outside the night). `tick` is the run tick.
func step_day(tick: int) -> void:
	_pathing.refresh()
	_king.resolve_ability(tick, _enemies, _hits)
	_squads.step(tick, _enemies, _hits, false, _king.get_position(), _pathing)
	_resolve_hits(tick)
	_enemies.remove_dead()
	_squads.remove_dead()


## True once every group has finished spawning and no enemy is alive.
func is_cleared() -> bool:
	return _schedule != null and _schedule.is_finished() and _enemies.count() == 0


func enemy_count() -> int:
	return _enemies.count()


func spawned_count() -> int:
	return _schedule.spawned_count() if _schedule != null else 0


func total_count() -> int:
	return _schedule.total_count() if _schedule != null else 0


## Enemies of this night that have not died yet, including those still to spawn.
func remaining_count() -> int:
	return total_count() - _enemies.died_count()


## Ticks until the next spawn; -1 when nothing is left to spawn.
func ticks_until_next_spawn() -> int:
	if _schedule == null:
		return -1
	return _schedule.ticks_until_next(_next_night_tick)


func get_enemies() -> EnemySystem:
	return _enemies


func get_squads() -> SquadSystem:
	return _squads


func get_walls() -> WallSystem:
	return _walls


## The steering and solidity facade the enemies, squads, king and bots share.
func get_pathing() -> Pathing:
	return _pathing


## Dawn (LOOP-04, D-05): heals every hurt wall segment and rebuilds every broken one for free.
## Returns the wall plots that changed in MapConfig order; see WallSystem.restore_all.
func restore_walls() -> Array[StringName]:
	return _walls.restore_all()


func get_night_number() -> int:
	return _night_number


func end_night() -> void:
	_hits.clear()


func _spawn_due(night_tick: int) -> void:
	for entry: WaveSchedule.Entry in _schedule.take_due(night_tick):
		var spawn_point: SpawnPointDef = _map.find_spawn_point(entry.spawn_point_id)
		var def: EnemyDef = _map.find_enemy(entry.enemy_id)
		var scatter: float = spawn_point.scatter_radius
		var offset_x: float = _spawn_rng.randf_range(-scatter, scatter)
		var offset_z: float = _spawn_rng.randf_range(-scatter, scatter)
		var pos: Vector2 = Vector2(
			spawn_point.position.x + offset_x, spawn_point.position.z + offset_z
		)
		_enemies.spawn(def, pos)


func _resolve_hits(night_tick: int) -> void:
	for hit: PendingHits.Hit in _hits.take_due(night_tick):
		if hit.target_kind == PendingHits.KIND_ENEMY:
			_enemies.damage(hit.target_id, hit.amount, hit.attacker_kind)
		elif hit.target_kind == PendingHits.KIND_CASTLE:
			_castle.damage(hit.amount)
		elif hit.target_kind == PendingHits.KIND_KING:
			_king.take_damage(hit.amount)
		elif hit.target_kind == PendingHits.KIND_BUILDING:
			_buildings.damage_building(_buildings.spot_at_index(hit.target_id), hit.amount)
		elif hit.target_kind == PendingHits.KIND_UNIT:
			_squads.damage_unit(hit.target_id, hit.amount, hit.attacker_kind)
		elif hit.target_kind == PendingHits.KIND_WALL:
			_walls.damage_segment(hit.target_id, hit.amount)
