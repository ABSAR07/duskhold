extends GutTest
## D-08: the ranged attacker stops at its attack_range, shoots on the same targeting rules as the
## grunt and its hit lands after the projectile's flight time on the target's id. Hand-built night
## (EnemySystem, CastleState, BuildingSystem, KingState and PendingHits, no RunContext). Numbers
## come from ranged.tres, grunt.tres and house.tres.

const RANGED_PATH := "res://data/enemies/ranged.tres"
const GRUNT_PATH := "res://data/enemies/grunt.tres"
const KING_PATH := "res://data/king/king.tres"
const HOUSE_PATH := "res://data/buildings/house.tres"
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
## The House stands far from the castle at the origin so only the House is in aggro range.
const HOUSE_AT := Vector2(40.0, 0.0)
const KING_FAR := Vector2(500.0, 500.0)
## Slack for "standing at the stop distance": float32 positions land a hair off the exact value.
const EDGE_EPSILON: float = 0.02
## Ticks that cover the walk to the stand-off and two shots, before the House can fall.
const STAND_OFF_TICKS: int = 100

var _ranged: EnemyDef
var _grunt: EnemyDef
var _house: BuildingDef
var _map: MapConfig
var _events: SimEvents
var _castle: CastleState
var _buildings: BuildingSystem
var _king: KingState
var _enemies: EnemySystem
var _hits: PendingHits
var _now: int = 0


func before_each() -> void:
	_ranged = load(RANGED_PATH)
	_grunt = load(GRUNT_PATH)
	_house = load(HOUSE_PATH)
	_map = MapConfig.new()
	_map.buildings = [_house] as Array[BuildingDef]
	var spot: BuildSpotDef = BuildSpotDef.new()
	spot.id = &"house_1"
	spot.building_id = &"house"
	spot.position = Vector3(HOUSE_AT.x, 0.0, HOUSE_AT.y)
	_map.spots = [spot] as Array[BuildSpotDef]
	_events = SimEvents.new()
	_castle = CastleState.new(_map, _events)
	_buildings = BuildingSystem.new(_map, _events)
	_buildings.apply_next_tier(&"house_1")
	_king = KingState.new(load(KING_PATH), KING_FAR, _events, load(TUNING_PATH))
	_king.report_position(KING_FAR)
	_enemies = EnemySystem.new(_events)
	_hits = PendingHits.new()
	_now = 0


## One night step in the DR-8 order: enemies decide and move, due hits resolve, the dead leave.
func _tick(tick: int) -> void:
	_now = tick
	_enemies.step(tick, _castle, _king, _hits, _buildings)
	for hit: PendingHits.Hit in _hits.take_due(tick):
		if hit.target_kind == PendingHits.KIND_CASTLE:
			_castle.damage(hit.amount)
		elif hit.target_kind == PendingHits.KIND_KING:
			_king.take_damage(hit.amount)
		elif hit.target_kind == PendingHits.KIND_BUILDING:
			_buildings.damage_building(_buildings.spot_at_index(hit.target_id), hit.amount)
	_enemies.remove_dead()


## A skirmisher ten metres north of the House: inside aggro range of its edge, outside the castle's.
func _spawn_ranged() -> int:
	return _enemies.spawn(_ranged, HOUSE_AT + Vector2(0.0, 10.0))


## Records every shot as {tick, kind, id, target_kind, target_id, flight, distance_to_house}.
func _record_shots() -> Array:
	var shots: Array = []
	_events.attack_fired.connect(
		func(kind: StringName, id: int, target_kind: StringName, target: int, flight: int) -> void:
			(
				shots
				. append(
					{
						"tick": _now,
						"kind": kind,
						"id": id,
						"target_kind": target_kind,
						"target_id": target,
						"flight": flight,
						"distance": _enemies.position_of(id).distance_to(HOUSE_AT),
					}
				)
			)
	)
	return shots


func test_a_skirmisher_stops_at_its_attack_range_from_the_house_edge() -> void:
	var id: int = _spawn_ranged()
	for tick: int in range(0, STAND_OFF_TICKS):
		_tick(tick)
	var stop: float = _house.body_radius + _ranged.attack_range
	assert_almost_eq(
		_enemies.position_of(id).distance_to(HOUSE_AT),
		stop,
		EDGE_EPSILON,
		"it halts at the stand-off"
	)
	assert_gt(stop, _house.body_radius + _grunt.attack_range, "well outside melee reach")


func test_its_first_shot_flies_for_the_flight_time_to_the_house() -> void:
	_spawn_ranged()
	var shots: Array = _record_shots()
	for tick: int in range(0, 200):
		_tick(tick)
	assert_gt(shots.size(), 0, "it shot")
	if shots.is_empty():
		return
	var shot: Dictionary = shots[0]
	assert_eq(shot["kind"], &"enemy", "an enemy attack")
	assert_eq(shot["target_kind"], PendingHits.KIND_BUILDING, "at the House")
	assert_eq(shot["target_id"], 0, "spot index 0")
	assert_gt(shot["flight"], 0, "a ranged shot is never instant")
	assert_eq(
		shot["flight"],
		SimClock.flight_ticks(shot["distance"], _ranged.projectile_speed),
		"from distance"
	)


func test_the_hit_lands_exactly_flight_ticks_after_the_shot() -> void:
	_spawn_ranged()
	var shots: Array = _record_shots()
	var landed_at: Array[int] = []
	_events.building_damaged.connect(
		func(_spot: StringName, _amount: int, _hp: int, _max: int) -> void: landed_at.append(_now)
	)
	for tick: int in range(0, 200):
		_tick(tick)
	assert_gt(landed_at.size(), 0, "the House was hit")
	if shots.is_empty() or landed_at.is_empty():
		return
	assert_gt(shots[0]["flight"], 0, "the arrow takes time")
	assert_eq(landed_at[0], shots[0]["tick"] + shots[0]["flight"], "arrival = shot + flight")
	assert_eq(
		_buildings.max_health_of(&"house_1") - _buildings.health_of(&"house_1"),
		_ranged.attack_damage * landed_at.size(),
		"each landed shot takes attack_damage"
	)


func test_it_shoots_again_every_attack_interval() -> void:
	_spawn_ranged()
	var shots: Array = _record_shots()
	for tick: int in range(0, 300):
		_tick(tick)
	assert_gte(shots.size(), 3, "several shots")
	if shots.size() < 3:
		return
	var interval: int = SimClock.ticks(_ranged.attack_interval)
	assert_eq(shots[1]["tick"] - shots[0]["tick"], interval, "the interval between shots 1 and 2")
	assert_eq(shots[2]["tick"] - shots[1]["tick"], interval, "and between shots 2 and 3")


func test_a_hit_on_a_house_destroyed_in_the_meantime_drops() -> void:
	_spawn_ranged()
	var shots: Array = _record_shots()
	var damaged: Array[int] = []
	_events.building_damaged.connect(
		func(_spot: StringName, amount: int, _hp: int, _max: int) -> void: damaged.append(amount)
	)
	for tick: int in range(0, 200):
		_tick(tick)
		if not shots.is_empty():
			break
	assert_eq(shots.size(), 1, "the first arrow is in the air")
	_buildings.damage_building(&"house_1", _buildings.max_health_of(&"house_1"))
	var total_before: int = damaged.size()
	for tick: int in range(_now + 1, _now + 1 + shots[0]["flight"] + 5):
		_tick(tick)
	assert_eq(damaged.size(), total_before, "the arrow found only rubble and was dropped")
	assert_eq(shots.size(), 1, "and it did not fire at the rubble")


func test_a_skirmisher_shoots_the_king_from_range_and_the_hit_arrives_later() -> void:
	var here: Vector2 = Vector2(-60.0, 60.0)
	_king.report_position(here + Vector2(_ranged.aggro_range - 1.0, 0.0))
	var id: int = _enemies.spawn(_ranged, here)
	var shots: Array = _record_shots()
	var hurt_at: Array[int] = []
	_events.king_damaged.connect(
		func(_amount: int, _hp: int, _max: int) -> void: hurt_at.append(_now)
	)
	for tick: int in range(0, 200):
		_tick(tick)
	assert_gt(shots.size(), 0, "it shot the king")
	assert_gt(hurt_at.size(), 0, "and the king took damage")
	if shots.is_empty() or hurt_at.is_empty():
		return
	assert_eq(shots[0]["id"], id, "this enemy")
	assert_eq(shots[0]["target_kind"], PendingHits.KIND_KING, "at the king")
	assert_gt(shots[0]["flight"], 0, "the arrow takes time")
	assert_eq(hurt_at[0], shots[0]["tick"] + shots[0]["flight"], "after the flight")
	assert_gt(
		_enemies.position_of(id).distance_to(_king.get_position()),
		_king.get_def().body_radius + _grunt.attack_range,
		"standing off at range, not in melee"
	)


func test_a_grunt_still_strikes_at_once() -> void:
	_enemies.spawn(_grunt, HOUSE_AT + Vector2(0.0, 5.0))
	var shots: Array = _record_shots()
	for tick: int in range(0, 200):
		_tick(tick)
	assert_gt(shots.size(), 0, "the grunt attacked")
	if shots.is_empty():
		return
	assert_eq(shots[0]["flight"], 0, "a melee strike lands this tick")
