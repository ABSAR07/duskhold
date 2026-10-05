extends GutTest
## D-11 as extended by BLDG-07: standing buildings are targets in the enemies' path. Hand-built
## night (EnemySystem, CastleState, BuildingSystem and PendingHits, no RunContext). Numbers come
## from grunt.tres and house.tres; the castle is the MapConfig default (radius 3.5) at the origin.
## Split from test_enemy_targeting.gd, which already holds the castle and king cases.

const GRUNT_PATH := "res://data/enemies/grunt.tres"
const KING_PATH := "res://data/king/king.tres"
const HOUSE_PATH := "res://data/buildings/house.tres"
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
## Where the king stands when he is nowhere near any test enemy.
const KING_FAR := Vector2(500.0, 500.0)
## Slack for "standing at the stop distance": float32 positions land a hair off the exact value.
const EDGE_EPSILON: float = 0.02

var _grunt: EnemyDef
var _house: BuildingDef
var _map: MapConfig
var _events: SimEvents
var _castle: CastleState
var _buildings: BuildingSystem
var _king: KingState
var _enemies: EnemySystem
var _hits: PendingHits


func before_each() -> void:
	_grunt = load(GRUNT_PATH)
	_house = load(HOUSE_PATH)
	_map = MapConfig.new()
	_build()


func _build() -> void:
	_events = SimEvents.new()
	_castle = CastleState.new(_map, _events)
	_buildings = BuildingSystem.new(_map, _events)
	_king = KingState.new(load(KING_PATH), KING_FAR, _events, load(TUNING_PATH))
	_king.report_position(KING_FAR)
	_enemies = EnemySystem.new(_events)
	_hits = PendingHits.new()


## One night step in the DR-8 order: enemies decide and move, due hits resolve, the dead leave.
func _tick(tick: int) -> void:
	_enemies.step(tick, _castle, _king, _hits, _buildings)
	for hit: PendingHits.Hit in _hits.take_due(tick):
		if hit.target_kind == PendingHits.KIND_CASTLE:
			_castle.damage(hit.amount)
		elif hit.target_kind == PendingHits.KIND_KING:
			_king.take_damage(hit.amount)
		elif hit.target_kind == PendingHits.KIND_BUILDING:
			_buildings.damage_building(_buildings.spot_at_index(hit.target_id), hit.amount)
	_enemies.remove_dead()


func _king_target() -> Dictionary:
	return {"kind": PendingHits.KIND_KING, "id": 0}


func _castle_target() -> Dictionary:
	return {"kind": PendingHits.KIND_CASTLE, "id": 0}


## Stands one House on each position (XZ metres) in the order given, house_1 first. The castle is
## the default one at the origin. Rebuilds every system, so call it before spawning enemies.
func _with_houses(positions: Array[Vector2]) -> void:
	_map.buildings = [_house] as Array[BuildingDef]
	var spots: Array[BuildSpotDef] = []
	for index: int in range(positions.size()):
		var spot: BuildSpotDef = BuildSpotDef.new()
		spot.id = StringName("house_%d" % (index + 1))
		spot.building_id = &"house"
		spot.position = Vector3(positions[index].x, 0.0, positions[index].y)
		spots.append(spot)
	_map.spots = spots
	_build()
	for spot_id: StringName in _buildings.spot_ids():
		_buildings.apply_next_tier(spot_id)


func _building_target(index: int) -> Dictionary:
	return {"kind": PendingHits.KIND_BUILDING, "id": index}


## Where an enemy stands when the castle edge is `edge` metres away, due +x of the castle.
func _at_castle_edge(edge: float) -> Vector2:
	return Vector2(_map.castle_radius + edge, 0.0)


func test_an_enemy_targets_a_house_nearer_than_the_castle() -> void:
	var here: Vector2 = _at_castle_edge(1.0)
	_with_houses([here + Vector2(0.0, _house.body_radius + 0.5)] as Array[Vector2])
	var id: int = _enemies.spawn(_grunt, here)
	_tick(0)
	assert_eq(
		_enemies.target_of(id), _building_target(0), "the House edge is nearer than the castle"
	)


func test_an_enemy_targets_the_castle_when_it_is_nearer_than_the_house() -> void:
	var here: Vector2 = _at_castle_edge(1.0)
	_with_houses([here + Vector2(0.0, _house.body_radius + 3.0)] as Array[Vector2])
	var id: int = _enemies.spawn(_grunt, here)
	_tick(0)
	assert_eq(_enemies.target_of(id), _castle_target(), "the castle edge is nearer")


func test_a_house_outside_aggro_range_is_not_a_target() -> void:
	var here: Vector2 = _at_castle_edge(_grunt.aggro_range + 5.0)
	_with_houses(
		[here + Vector2(0.0, _house.body_radius + _grunt.aggro_range + 0.5)] as Array[Vector2]
	)
	var id: int = _enemies.spawn(_grunt, here)
	_tick(0)
	assert_eq(_enemies.target_of(id), {}, "nothing is inside aggro range, so it keeps marching")


func test_a_house_edge_exactly_at_aggro_range_is_a_target() -> void:
	var here: Vector2 = _at_castle_edge(_grunt.aggro_range + 5.0)
	_with_houses([here + Vector2(0.0, _house.body_radius + _grunt.aggro_range)] as Array[Vector2])
	var id: int = _enemies.spawn(_grunt, here)
	_tick(0)
	assert_eq(_enemies.target_of(id), _building_target(0), "aggro range is inclusive")


func test_at_equal_edge_distance_a_house_beats_the_castle() -> void:
	var here: Vector2 = _at_castle_edge(4.0)
	_with_houses([here + Vector2(0.0, _house.body_radius + 4.0)] as Array[Vector2])
	var id: int = _enemies.spawn(_grunt, here)
	_tick(0)
	assert_eq(_enemies.target_of(id), _building_target(0), "the castle comes last on a tie")


func test_at_equal_edge_distance_the_earlier_spot_wins() -> void:
	var here: Vector2 = _at_castle_edge(5.0)
	var reach: float = _house.body_radius + 4.0
	_with_houses([here + Vector2(0.0, reach), here + Vector2(0.0, -reach)] as Array[Vector2])
	var id: int = _enemies.spawn(_grunt, here)
	_tick(0)
	assert_eq(_enemies.target_of(id), _building_target(0), "house_1 is earlier in spot order")


func test_a_nearer_later_spot_beats_an_earlier_one() -> void:
	var here: Vector2 = _at_castle_edge(5.0)
	var near: float = _house.body_radius + 2.0
	var far: float = _house.body_radius + 4.0
	_with_houses([here + Vector2(0.0, far), here + Vector2(0.0, -near)] as Array[Vector2])
	var id: int = _enemies.spawn(_grunt, here)
	_tick(0)
	assert_eq(_enemies.target_of(id), _building_target(1), "nearest edge first, then spot order")


func test_a_fallen_house_stops_being_a_target_and_the_next_candidate_takes_over() -> void:
	var here: Vector2 = _at_castle_edge(30.0)
	var reach: float = _house.body_radius + 3.0
	_with_houses([here + Vector2(0.0, reach), here + Vector2(0.0, -reach - 1.0)] as Array[Vector2])
	var id: int = _enemies.spawn(_grunt, here)
	_tick(0)
	assert_eq(_enemies.target_of(id), _building_target(0), "the nearer House first")
	_buildings.damage_building(&"house_1", _house.tier_def(1).max_health)
	_tick(1)
	assert_eq(_enemies.target_of(id), _building_target(1), "it moves on to the next House")
	_buildings.damage_building(&"house_2", _house.tier_def(1).max_health)
	_tick(2)
	assert_eq(_enemies.target_of(id), {}, "with every House down and the castle out of reach")


func test_a_fallen_house_is_not_chosen_in_the_first_place() -> void:
	var here: Vector2 = _at_castle_edge(1.0)
	_with_houses([here + Vector2(0.0, _house.body_radius + 0.5)] as Array[Vector2])
	_buildings.damage_building(&"house_1", _house.tier_def(1).max_health)
	var id: int = _enemies.spawn(_grunt, here)
	_tick(0)
	assert_eq(_enemies.target_of(id), _castle_target(), "rubble is no target; the castle is")


func test_an_enemy_walks_to_a_house_and_strikes_it_on_the_attack_cadence() -> void:
	var house_pos: Vector2 = _at_castle_edge(30.0) + Vector2(0.0, 8.0)
	_with_houses([house_pos] as Array[Vector2])
	var id: int = _enemies.spawn(_grunt, house_pos + Vector2(0.0, 5.0))
	var interval: int = SimClock.ticks(_grunt.attack_interval)
	var hp_after: Array[int] = []
	_events.building_damaged.connect(
		func(_spot: StringName, _amount: int, hp: int, _max: int) -> void: hp_after.append(hp)
	)
	for tick: int in range(0, 40 + interval * 2):
		_tick(tick)
	assert_eq(_enemies.target_of(id), _building_target(0), "attacking house_1")
	var stand_off: float = _house.body_radius + _grunt.attack_range
	assert_almost_eq(
		_enemies.position_of(id).distance_to(house_pos), stand_off, EDGE_EPSILON, "at its edge"
	)
	assert_gte(hp_after.size(), 2, "it struck repeatedly")
	if hp_after.size() < 2:
		return
	var max_hp: int = _house.tier_def(1).max_health
	assert_eq(hp_after[0], max_hp - _grunt.attack_damage, "each strike takes attack_damage")
	assert_eq(hp_after[1], max_hp - _grunt.attack_damage * 2, "and the next one the same again")


func test_a_king_entering_aggro_range_pulls_an_enemy_off_a_house() -> void:
	var here: Vector2 = _at_castle_edge(30.0)
	_with_houses([here + Vector2(0.0, _house.body_radius + _grunt.attack_range)] as Array[Vector2])
	var id: int = _enemies.spawn(_grunt, here)
	var rescan_ticks: int = SimClock.ticks(_grunt.retarget_interval_seconds)
	_tick(0)
	assert_eq(_enemies.target_of(id), _building_target(0), "on the House while the king is far")
	_king.report_position(here + Vector2(-(_grunt.aggro_range - 1.0), 0.0))
	var switched_at: int = -1
	for tick: int in range(1, rescan_ticks * 2):
		_tick(tick)
		if switched_at < 0 and _enemies.target_of(id) == _king_target():
			switched_at = tick
	assert_eq(switched_at, rescan_ticks - id, "he pulls it on its next rescan tick")
