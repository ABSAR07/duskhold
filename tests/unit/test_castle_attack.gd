extends GutTest
## G-02-1 point 2 (owner decision 2026-10-06): the standing castle shoots the nearest enemy within
## castle_attack_range every castle_attack_interval, three hits to kill a grunt and two to kill a
## skirmisher, and it reaches a skirmisher shooting at it. Hand-built night (CastleAttack,
## CastleState, EnemySystem and PendingHits, no RunContext) copied from test_tower_combat.gd, plus
## one NightSim run for the step order. Shipped enemy numbers come from the .tres files; the pinned
## literals are the castle's own numbers and the 6 m / 18 m/s flight of 10 ticks.

const GRUNT_PATH := "res://data/enemies/grunt.tres"
const RANGED_PATH := "res://data/enemies/ranged.tres"
const TOWER_PATH := "res://data/buildings/tower.tres"
const HOUSE_PATH := "res://data/buildings/house.tres"
const KING_PATH := "res://data/king/king.tres"
const DAMAGE: int = 2
const REACH: float = 11.0
const INTERVAL_S: float = 1.5
const PROJECTILE_SPEED: float = 18.0
const TOUGH_HEALTH: int = 100000
const JUST_BEYOND_REACH: float = 11.01
const INTERVAL_TICKS: int = 45
const FAR_FROM_THE_FIGHT := Vector2(0.0, 80.0)
## Each way a castle attack number can disarm the castle: [field, value].
const DISARMING: Array = [
	["castle_attack_damage", 0],
	["castle_attack_damage", -1],
	["castle_attack_range", 0.0],
	["castle_attack_range", -1.0],
	["castle_attack_interval", 0.0],
	["castle_attack_interval", -1.0],
]

var _map: MapConfig
var _events: SimEvents
var _castle: CastleState
var _attack: CastleAttack
var _enemies: EnemySystem
var _hits: PendingHits
var _shots: Array = []


func before_each() -> void:
	_map = _armed_map()
	_build()


func _armed_map() -> MapConfig:
	var map: MapConfig = MapConfig.new()
	map.castle_attack_damage = DAMAGE
	map.castle_attack_range = REACH
	map.castle_attack_interval = INTERVAL_S
	map.castle_projectile_speed = PROJECTILE_SPEED
	return map


func _build() -> void:
	_events = SimEvents.new()
	_castle = CastleState.new(_map, _events)
	_attack = CastleAttack.new(_map, _castle, _events)
	_attack.begin_night()
	_enemies = EnemySystem.new(_events)
	_hits = PendingHits.new()
	_shots = _record_shots()


## One night step in the DR-8 order: the castle decides, due hits resolve, the dead leave.
func _tick(tick: int) -> void:
	_attack.step(tick, _enemies, _hits)
	for hit: PendingHits.Hit in _hits.take_due(tick):
		if hit.target_kind == PendingHits.KIND_ENEMY:
			_enemies.damage(hit.target_id, hit.amount, hit.attacker_kind)
	_enemies.remove_dead()


func _tough_grunt() -> EnemyDef:
	var def: EnemyDef = (load(GRUNT_PATH) as EnemyDef).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	def.max_health = TOUGH_HEALTH
	return def


## Spawns a tough grunt `distance` metres east of the castle at the origin.
func _spawn_at(distance: float, def: EnemyDef = null) -> int:
	return _enemies.spawn(def if def != null else _tough_grunt(), Vector2(distance, 0.0))


## Records every attack_fired as [attacker_kind, attacker_id, target_kind, target_id, flight].
func _record_shots() -> Array:
	var shots: Array = []
	_events.attack_fired.connect(
		func(kind: StringName, id: int, target_kind: StringName, target: int, flight: int) -> void:
			shots.append([kind, id, target_kind, target, flight])
	)
	return shots


func test_the_pinned_flight_for_six_metres_at_the_castle_arrow_speed_is_ten_ticks() -> void:
	assert_eq(SimClock.flight_ticks(6.0, PROJECTILE_SPEED), 10, "6 m at 18 m/s")
	assert_eq(SimClock.ticks(INTERVAL_S), INTERVAL_TICKS, "1.5 s is 45 ticks")


func test_the_castle_fires_at_an_enemy_in_reach_on_tick_zero_and_the_hit_lands_after_the_flight(
) -> void:
	var id: int = _spawn_at(6.0)
	var flight: int = SimClock.flight_ticks(6.0, PROJECTILE_SPEED)
	_tick(0)
	assert_eq(
		_shots,
		[[PendingHits.KIND_CASTLE, 0, PendingHits.KIND_ENEMY, id, flight]],
		"one shot at tick 0 from the castle (id 0) carrying the flight time"
	)
	for tick: int in range(1, flight):
		_tick(tick)
	assert_eq(_enemies.health_of(id), TOUGH_HEALTH, "nothing lands while the arrow flies")
	_tick(flight)
	assert_eq(_enemies.health_of(id), TOUGH_HEALTH - DAMAGE, "it lands on the tick")


func test_the_next_shot_comes_one_attack_interval_after_the_first() -> void:
	_spawn_at(6.0)
	var fired_at: Array[int] = []
	for tick: int in range(0, INTERVAL_TICKS * 2 + 1):
		var before: int = _shots.size()
		_tick(tick)
		if _shots.size() > before:
			fired_at.append(tick)
	assert_eq(fired_at, [0, INTERVAL_TICKS, INTERVAL_TICKS * 2] as Array[int], "every 45 ticks")


func test_with_no_enemy_in_reach_nothing_fires_and_an_enemy_entering_is_shot_at_once() -> void:
	_spawn_at(JUST_BEYOND_REACH + 5.0)
	for tick: int in range(0, INTERVAL_TICKS * 2):
		_tick(tick)
	assert_eq(_shots.size(), 0, "an enemy out of reach is never shot")
	var entering: int = _enemies.spawn(_tough_grunt(), Vector2(REACH - 1.0, 0.0))
	_tick(INTERVAL_TICKS * 2)
	assert_eq(_shots.size(), 1, "the enemy that came into reach is shot on the tick it enters")
	if _shots.size() == 1:
		assert_eq(_shots[0][3], entering, "and it is that one, not the far one")


func test_an_enemy_exactly_at_the_reach_is_shot_and_one_just_beyond_it_is_not() -> void:
	var at_edge: int = _spawn_at(REACH)
	_tick(0)
	assert_eq(_shots.size(), 1, "11.0 m is in reach")
	if _shots.size() == 1:
		assert_eq(_shots[0][3], at_edge, "that one")
	_build()
	_spawn_at(JUST_BEYOND_REACH)
	_tick(0)
	assert_eq(_shots.size(), 0, "11.01 m is out of reach")


func test_equally_near_enemies_the_lower_id_is_shot() -> void:
	var low: int = _spawn_at(6.0)
	var high: int = _enemies.spawn(_tough_grunt(), Vector2(-6.0, 0.0))
	_tick(0)
	assert_lt(low, high, "the first spawned has the lower id")
	assert_eq(_shots.size(), 1, "one shot")
	if _shots.size() == 1:
		assert_eq(_shots[0][3], low, "equally near: the lower id")


func test_a_nearer_enemy_is_shot_before_a_lower_id() -> void:
	var far: int = _spawn_at(9.0)
	var near: int = _spawn_at(4.0)
	_tick(0)
	assert_lt(far, near, "the far one has the lower id")
	assert_eq(_shots.size(), 1, "one shot")
	if _shots.size() == 1:
		assert_eq(_shots[0][3], near, "the nearer enemy wins")


func test_a_shipped_grunt_dies_on_exactly_the_third_castle_hit() -> void:
	_assert_dies_on_hit(load(GRUNT_PATH) as EnemyDef, 3)


func test_a_shipped_skirmisher_dies_on_exactly_the_second_castle_hit() -> void:
	_assert_dies_on_hit(load(RANGED_PATH) as EnemyDef, 2)


func _assert_dies_on_hit(def: EnemyDef, hits_needed: int) -> void:
	var killers: Array[StringName] = []
	_events.enemy_died.connect(
		func(_id: int, _def_id: StringName, _pos: Vector2, killer: StringName) -> void:
			killers.append(killer)
	)
	var id: int = _spawn_at(6.0, def)
	var landed: int = 0
	for tick: int in range(0, INTERVAL_TICKS * (hits_needed + 1)):
		var health_before: int = _enemies.health_of(id)
		_tick(tick)
		if _enemies.health_of(id) < health_before or not _enemies.is_alive(id):
			landed += 1
		if not _enemies.is_alive(id):
			break
	assert_eq(landed, hits_needed, "%s needs %d castle hits" % [def.id, hits_needed])
	assert_eq(_shots.size(), hits_needed, "and the castle shot exactly that many times")
	assert_eq(killers, [PendingHits.KIND_CASTLE] as Array[StringName], "the castle gets the kill")


func test_a_destroyed_castle_fires_nothing() -> void:
	_spawn_at(6.0)
	_castle.damage(_castle.get_max_health())
	assert_true(_castle.is_destroyed(), "the castle fell")
	for tick: int in range(0, INTERVAL_TICKS * 2):
		_tick(tick)
	assert_eq(_shots.size(), 0, "a fallen castle does not shoot")


func test_the_castle_is_armed_only_with_damage_range_and_interval_above_zero() -> void:
	assert_true(_attack.is_armed(), "the pinned numbers arm it")
	for case: Array in DISARMING:
		var map: MapConfig = _armed_map()
		map.set(case[0], case[1])
		var attack: CastleAttack = CastleAttack.new(map, CastleState.new(map, _events), _events)
		assert_false(attack.is_armed(), "%s at %s disarms it" % [case[0], case[1]])


func test_an_unarmed_castle_never_fires() -> void:
	for case: Array in DISARMING:
		_map = _armed_map()
		_map.set(case[0], case[1])
		_build()
		_spawn_at(6.0)
		for tick: int in range(0, INTERVAL_TICKS * 2):
			_tick(tick)
		assert_eq(_shots.size(), 0, "%s at %s: the castle never fires" % [case[0], case[1]])


func test_a_new_night_makes_the_castle_ready_again_after_a_mid_cooldown_night() -> void:
	_spawn_at(6.0)
	_tick(0)
	assert_eq(_shots.size(), 1, "it fired on tick 0 and is cooling down")
	_attack.begin_night()
	_tick(0)
	assert_eq(_shots.size(), 2, "begin_night made it ready on night tick 0 again")


func test_a_tower_and_the_castle_fire_before_any_enemy_in_that_order_through_night_sim() -> void:
	var map: MapConfig = _armed_map()
	map.buildings = [load(TOWER_PATH), load(HOUSE_PATH)] as Array[BuildingDef]
	var spot: BuildSpotDef = BuildSpotDef.new()
	spot.id = &"tower_1"
	spot.building_id = &"tower"
	spot.position = Vector3(14.0, 0.0, 0.0)
	map.spots = [spot] as Array[BuildSpotDef]
	var events: SimEvents = SimEvents.new()
	var buildings: BuildingSystem = BuildingSystem.new(map, events)
	buildings.apply_next_tier(&"tower_1")
	var king: KingState = KingState.new(load(KING_PATH), FAR_FROM_THE_FIGHT, events)
	var castle: CastleState = CastleState.new(map, events)
	var night: NightSim = NightSim.new(map, events, king, 1, castle, buildings)
	night.begin_night(1)
	var skirmisher: EnemyDef = (load(RANGED_PATH) as EnemyDef).duplicate_deep(
		Resource.DEEP_DUPLICATE_ALL
	)
	skirmisher.max_health = TOUGH_HEALTH
	night.get_enemies().spawn(skirmisher, Vector2(9.0, 0.0))
	var kinds: Array[StringName] = []
	events.attack_fired.connect(
		func(kind: StringName, _id: int, _tk: StringName, _tid: int, _flight: int) -> void:
			kinds.append(kind)
	)
	night.step(0)
	var expected: Array[StringName] = [
		PendingHits.KIND_BUILDING, PendingHits.KIND_CASTLE, PendingHits.KIND_ENEMY
	]
	assert_eq(kinds, expected, "tower, then castle, then the enemy's own attack, on night tick 0")
