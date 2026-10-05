extends GutTest
## D-13: towers fire at the nearest enemy in range on a fixed cadence, the hit lands after the
## arrow's flight time on the target's id, and a fallen tower stops. Hand-built night (TowerSystem,
## BuildingSystem, EnemySystem and PendingHits, no RunContext). Numbers come from tower.tres and
## grunt.tres; the one pinned literal is the 6 m / 18 m/s flight of 10 ticks.

const TOWER_PATH := "res://data/buildings/tower.tres"
const HOUSE_PATH := "res://data/buildings/house.tres"
const GRUNT_PATH := "res://data/enemies/grunt.tres"
const TOUGH_HEALTH: int = 100000
## Where tower_1 stands; the castle at the origin is out of the way and never stepped.
const TOWER_AT := Vector2(40.0, 0.0)

var _tower: BuildingDef
var _house: BuildingDef
var _grunt: EnemyDef
var _map: MapConfig
var _events: SimEvents
var _buildings: BuildingSystem
var _towers: TowerSystem
var _enemies: EnemySystem
var _hits: PendingHits


func before_each() -> void:
	_tower = load(TOWER_PATH)
	_house = load(HOUSE_PATH)
	_grunt = load(GRUNT_PATH)
	_map = MapConfig.new()
	_map.buildings = [_tower, _house] as Array[BuildingDef]
	_map.spots = [_spot(&"tower_1", &"tower", TOWER_AT)] as Array[BuildSpotDef]
	_build()


func _spot(id: StringName, building_id: StringName, at: Vector2) -> BuildSpotDef:
	var spot: BuildSpotDef = BuildSpotDef.new()
	spot.id = id
	spot.building_id = building_id
	spot.position = Vector3(at.x, 0.0, at.y)
	return spot


func _build() -> void:
	_events = SimEvents.new()
	_buildings = BuildingSystem.new(_map, _events)
	_towers = TowerSystem.new(_buildings, _events)
	_towers.begin_night()
	_enemies = EnemySystem.new(_events)
	_hits = PendingHits.new()


## One night step in the DR-8 order: towers decide, due hits resolve, the dead leave.
func _tick(tick: int) -> void:
	_towers.step(tick, _enemies, _hits)
	for hit: PendingHits.Hit in _hits.take_due(tick):
		if hit.target_kind == PendingHits.KIND_ENEMY:
			_enemies.damage(hit.target_id, hit.amount, hit.attacker_kind)
	_enemies.remove_dead()


func _tough_grunt() -> EnemyDef:
	var def: EnemyDef = _grunt.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	def.max_health = TOUGH_HEALTH
	return def


## Spawns a tough grunt `distance` metres east of the tower.
func _spawn_at(distance: float, def: EnemyDef = null) -> int:
	return _enemies.spawn(def if def != null else _tough_grunt(), TOWER_AT + Vector2(distance, 0.0))


## Records every attack_fired as [attacker_kind, attacker_id, target_kind, target_id, flight].
func _record_shots() -> Array:
	var shots: Array = []
	_events.attack_fired.connect(
		func(kind: StringName, id: int, target_kind: StringName, target: int, flight: int) -> void:
			shots.append([kind, id, target_kind, target, flight])
	)
	return shots


func _stand_tower(tier: int = 1) -> void:
	for _i: int in range(tier):
		_buildings.apply_next_tier(&"tower_1")


func test_the_pinned_flight_for_six_metres_at_arrow_speed_one_is_ten_ticks() -> void:
	assert_eq(SimClock.flight_ticks(6.0, _tower.tier_def(1).projectile_speed), 10, "6 m at 18 m/s")


func test_a_tower_fires_at_the_nearest_enemy_on_tick_zero_and_the_hit_lands_after_the_flight(
) -> void:
	_stand_tower()
	var tier: BuildingTierDef = _tower.tier_def(1)
	var id: int = _spawn_at(6.0)
	var shots: Array = _record_shots()
	var flight: int = SimClock.flight_ticks(6.0, tier.projectile_speed)
	_tick(0)
	assert_eq(
		shots,
		[[&"building", _buildings.spot_index(&"tower_1"), &"enemy", id, flight]],
		"one shot at tick 0 carrying the flight time"
	)
	for tick: int in range(1, flight):
		_tick(tick)
	assert_eq(_enemies.health_of(id), TOUGH_HEALTH, "nothing lands while the arrow flies")
	_tick(flight)
	assert_eq(_enemies.health_of(id), TOUGH_HEALTH - tier.attack_damage, "it lands on the tick")


func test_the_next_shot_comes_one_attack_interval_after_the_first() -> void:
	_stand_tower()
	_spawn_at(6.0)
	var shots: Array = _record_shots()
	var interval: int = SimClock.ticks(_tower.tier_def(1).attack_interval)
	var fired_at: Array[int] = []
	for tick: int in range(0, interval * 2 + 1):
		var before: int = shots.size()
		_tick(tick)
		if shots.size() > before:
			fired_at.append(tick)
	assert_eq(fired_at, [0, interval, interval * 2] as Array[int], "a fixed cadence")


func test_with_no_enemy_in_range_nothing_fires_and_no_cooldown_is_spent() -> void:
	_stand_tower()
	_spawn_at(_tower.tier_def(1).attack_range + 5.0)
	var shots: Array = _record_shots()
	for tick: int in range(0, 40):
		_tick(tick)
	assert_eq(shots.size(), 0, "nothing in range, nothing fired")
	var near: int = _spawn_at(3.0)
	_tick(40)
	assert_eq(shots.size(), 1, "an enemy that comes into range is shot at that same tick")
	assert_eq(shots[0][3], near, "and it is the one in range")


func test_two_enemies_at_equal_distance_the_lower_id_is_shot() -> void:
	_stand_tower()
	var first: int = _spawn_at(5.0)
	_enemies.spawn(_tough_grunt(), TOWER_AT + Vector2(-5.0, 0.0))
	var shots: Array = _record_shots()
	_tick(0)
	assert_eq(shots.size(), 1, "one shot")
	assert_eq(shots[0][3], first, "the lower id")


func test_the_nearer_enemy_is_shot_before_the_lower_id() -> void:
	_stand_tower()
	_spawn_at(6.0)
	var near: int = _spawn_at(2.0)
	var shots: Array = _record_shots()
	_tick(0)
	assert_eq(shots[0][3], near, "nearest first")


func test_an_enemy_at_exactly_attack_range_is_shot_and_one_beyond_is_not() -> void:
	_stand_tower()
	var reach: float = _tower.tier_def(1).attack_range
	_spawn_at(reach + 0.01)
	var shots: Array = _record_shots()
	_tick(0)
	assert_eq(shots.size(), 0, "0.01 m beyond the range is safe")
	var edge: int = _spawn_at(reach)
	_tick(1)
	assert_eq(shots.size(), 1, "exactly at the range is shot")
	assert_eq(shots[0][3], edge, "the one at the edge")


func test_a_shot_whose_target_dies_before_arrival_lands_nowhere() -> void:
	_stand_tower()
	var id: int = _spawn_at(6.0)
	var damaged: Array[int] = []
	_events.enemy_damaged.connect(
		func(enemy_id: int, _amount: int, _hp: int) -> void: damaged.append(enemy_id)
	)
	_tick(0)
	_enemies.damage(id, TOUGH_HEALTH, &"king")
	_enemies.remove_dead()
	assert_eq(damaged.size(), 1, "only the king's blow so far")
	for tick: int in range(1, SimClock.flight_ticks(6.0, _tower.tier_def(1).projectile_speed) + 2):
		_tick(tick)
	assert_eq(damaged.size(), 1, "the arrow found nobody: no further enemy_damaged")


func test_a_destroyed_tower_does_not_shoot() -> void:
	_stand_tower()
	_spawn_at(4.0)
	_buildings.damage_building(&"tower_1", _tower.tier_def(1).max_health)
	assert_true(_buildings.is_destroyed(&"tower_1"), "the tower fell")
	var shots: Array = _record_shots()
	for tick: int in range(0, 40):
		_tick(tick)
	assert_eq(shots.size(), 0, "rubble does not shoot")


func test_an_unbuilt_tower_plot_does_not_shoot() -> void:
	_spawn_at(4.0)
	var shots: Array = _record_shots()
	for tick: int in range(0, 40):
		_tick(tick)
	assert_eq(shots.size(), 0, "an empty plot does not shoot")


func test_a_house_does_not_shoot() -> void:
	_map.spots = [_spot(&"house_1", &"house", TOWER_AT)] as Array[BuildSpotDef]
	_build()
	_buildings.apply_next_tier(&"house_1")
	_spawn_at(4.0)
	var shots: Array = _record_shots()
	for tick: int in range(0, 40):
		_tick(tick)
	assert_eq(shots.size(), 0, "a House has no attack")


func test_a_tower_that_falls_mid_night_stops_at_once() -> void:
	_stand_tower()
	_spawn_at(4.0)
	var shots: Array = _record_shots()
	_tick(0)
	assert_eq(shots.size(), 1, "it shot while it stood")
	_buildings.damage_building(&"tower_1", _tower.tier_def(1).max_health)
	var interval: int = SimClock.ticks(_tower.tier_def(1).attack_interval)
	for tick: int in range(1, interval * 3):
		_tick(tick)
	assert_eq(shots.size(), 1, "and never again")


func test_a_tier_two_tower_shoots_harder_and_faster_than_tier_one() -> void:
	var one: BuildingTierDef = _tower.tier_def(1)
	var two: BuildingTierDef = _tower.tier_def(2)
	var dps_one: float = float(one.attack_damage) / float(SimClock.ticks(one.attack_interval))
	var dps_two: float = float(two.attack_damage) / float(SimClock.ticks(two.attack_interval))
	assert_gt(dps_two, dps_one, "D-13: tier II deals more damage per tick than tier I")
	_stand_tower(2)
	var id: int = _spawn_at(6.0)
	var shots: Array = _record_shots()
	_tick(0)
	assert_eq(shots[0][4], SimClock.flight_ticks(6.0, two.projectile_speed), "the faster arrow")
	for tick: int in range(1, shots[0][4] + 1):
		_tick(tick)
	assert_eq(_enemies.health_of(id), TOUGH_HEALTH - two.attack_damage, "tier II damage lands")
	var fired_at: Array[int] = []
	for tick: int in range(shots[0][4] + 1, SimClock.ticks(two.attack_interval) * 2 + 1):
		var before: int = shots.size()
		_tick(tick)
		if shots.size() > before:
			fired_at.append(tick)
	assert_eq(
		fired_at,
		(
			[SimClock.ticks(two.attack_interval), SimClock.ticks(two.attack_interval) * 2]
			as Array[int]
		),
		"on the tier II interval"
	)


func test_an_enemy_killed_by_a_tower_is_credited_to_a_building() -> void:
	_stand_tower()
	var weak: EnemyDef = _grunt.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	weak.max_health = _tower.tier_def(1).attack_damage
	_spawn_at(4.0, weak)
	var killers: Array[StringName] = []
	_events.enemy_died.connect(
		func(_id: int, _def: StringName, _pos: Vector2, killer: StringName) -> void:
			killers.append(killer)
	)
	for tick: int in range(0, 30):
		_tick(tick)
	assert_eq(killers, [&"building"] as Array[StringName], "killer kind building")


func test_two_towers_each_shoot_in_spot_order() -> void:
	_map.spots = (
		[
			_spot(&"tower_1", &"tower", TOWER_AT),
			_spot(&"tower_2", &"tower", TOWER_AT + Vector2(0.0, 2.0))
		]
		as Array[BuildSpotDef]
	)
	_build()
	_buildings.apply_next_tier(&"tower_1")
	_buildings.apply_next_tier(&"tower_2")
	_spawn_at(4.0)
	var shots: Array = _record_shots()
	_tick(0)
	assert_eq(shots.size(), 2, "both towers fire")
	assert_eq(shots[0][1], 0, "tower_1 first")
	assert_eq(shots[1][1], 1, "then tower_2")


func test_begin_night_makes_every_tower_ready_again() -> void:
	_stand_tower()
	_spawn_at(4.0)
	var shots: Array = _record_shots()
	_tick(0)
	_tick(1)
	assert_eq(shots.size(), 1, "the tower is cooling down on tick 1")
	_towers.begin_night()
	_tick(2)
	assert_eq(shots.size(), 2, "a new night starts with every tower ready")
