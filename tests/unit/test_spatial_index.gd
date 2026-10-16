extends GutTest
## PLAT-01 / T-04-05: the spatial indexes answer exactly what the shipped scans did. Each test keeps
## a reference copy of the scan it replaces and compares the two on seeded random worlds with ties,
## so a grid that disagrees anywhere fails here before any replay digest moves.

const MAP_PATH := "res://data/maps/prototype_map.tres"
const FOOTMAN_PATH := "res://data/units/footman.tres"
const GRUNT_PATH := "res://data/enemies/grunt.tres"
const HOUSE_PATH := "res://data/buildings/house.tres"
const WORLD_SEED: int = 20261016
const QUERY_COUNT: int = 300
const UNIT_COUNT: int = 25
const SPREAD: float = 40.0
const ENEMY_AT := Vector2(100.0, 100.0)
const ENEMY_COUNT: int = 300
const ENEMY_REACHES: Array[float] = [2.0, 7.0, 10.5, 22.0]
const ENEMY_QUERIES_PER_REACH: int = 50
## Far outside the random spread, so only the two enemies placed around it are ever near it.
const TIE_POINT := Vector2(200.0, 200.0)

var _events: SimEvents
var _map: MapConfig
var _castle: CastleState
var _buildings: BuildingSystem
var _units: UnitSystem
var _index: StructureIndex


func before_each() -> void:
	_events = SimEvents.new()
	_index = StructureIndex.new()


## The prototype map with every plot built at tier 1 and UNIT_COUNT footmen at seeded positions.
func _prototype_world(rng: RandomNumberGenerator) -> void:
	_map = load(MAP_PATH)
	_castle = CastleState.new(_map, _events)
	_buildings = BuildingSystem.new(_map, _events)
	for spot_id: StringName in _buildings.spot_ids():
		_buildings.apply_next_tier(spot_id)
	_units = UnitSystem.new(_events)
	var footman: UnitDef = load(FOOTMAN_PATH)
	for _unit: int in range(UNIT_COUNT):
		var pos: Vector2 = Vector2(
			rng.randf_range(-SPREAD, SPREAD), rng.randf_range(-SPREAD, SPREAD)
		)
		_units.spawn(footman, &"squad", 0, pos)


## Two house plots and nothing else near ENEMY_AT: centre 4.5 m from it, radius 1.5, edge 3.0.
func _tie_world(spots: Array[Vector3]) -> void:
	_map = MapConfig.new()
	_map.buildings = [load(HOUSE_PATH)]
	var defs: Array[BuildSpotDef] = []
	for index: int in range(spots.size()):
		var spot: BuildSpotDef = BuildSpotDef.new()
		spot.id = StringName("plot_%d" % index)
		spot.position = spots[index]
		spot.building_id = &"house"
		defs.append(spot)
	_map.spots = defs
	_castle = CastleState.new(_map, _events)
	_buildings = BuildingSystem.new(_map, _events)
	for spot: BuildSpotDef in defs:
		_buildings.apply_next_tier(spot.id)
	_units = UnitSystem.new(_events)


## The shipped EnemySystem._pick_nearest_structure, kept verbatim as the reference: Vector3i(kind,
## id, found) with the index's kind codes.
func _reference(pos: Vector2, aggro: float) -> Vector3i:
	var best_edge: float = INF
	var found: Vector3i = StructureIndex.NONE
	for unit_id: int in _units.ids():
		if not _units.is_alive(unit_id):
			continue
		var unit_centre: Vector2 = _units.position_of(unit_id)
		var unit_edge: float = pos.distance_to(unit_centre) - _units.def_of(unit_id).radius
		if unit_edge <= aggro and unit_edge < best_edge:
			best_edge = unit_edge
			found = Vector3i(StructureIndex.KIND_UNIT, unit_id, 1)
	for spot_id: StringName in _buildings.standing_spot_ids():
		var spot: BuildSpotDef = _buildings.get_spot(spot_id)
		var centre: Vector2 = Vector2(spot.position.x, spot.position.z)
		var edge: float = pos.distance_to(centre) - _buildings.radius_of(spot_id)
		if edge <= aggro and edge < best_edge:
			best_edge = edge
			found = Vector3i(StructureIndex.KIND_BUILDING, _buildings.spot_index(spot_id), 1)
	var castle_edge: float = pos.distance_to(_castle.get_position()) - _castle.get_radius()
	if castle_edge <= aggro and castle_edge < best_edge:
		found = Vector3i(StructureIndex.KIND_CASTLE, 0, 1)
	return found


func _compare_random_queries(aggro: float, rng: RandomNumberGenerator) -> Array[int]:
	var mismatches: int = 0
	var hits: int = 0
	for _query: int in range(QUERY_COUNT):
		var pos: Vector2 = Vector2(
			rng.randf_range(-SPREAD, SPREAD), rng.randf_range(-SPREAD, SPREAD)
		)
		var expected: Vector3i = _reference(pos, aggro)
		if _index.nearest(pos, aggro) != expected:
			mismatches += 1
		if expected.z == 1:
			hits += 1
	return [mismatches, hits]


func test_structure_index_matches_the_shipped_scan_at_aggro_range_6() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = WORLD_SEED
	_prototype_world(rng)
	_index.rebuild(_units, _buildings, _castle)
	var result: Array[int] = _compare_random_queries(6.0, rng)
	assert_eq(result[0], 0, "no mismatch against the reference scan")
	assert_gt(result[1], 20, "the random queries really found structures")


func test_structure_index_matches_the_shipped_scan_at_aggro_range_10() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = WORLD_SEED + 1
	_prototype_world(rng)
	_index.rebuild(_units, _buildings, _castle)
	var result: Array[int] = _compare_random_queries(10.0, rng)
	assert_eq(result[0], 0, "no mismatch against the reference scan")
	assert_gt(result[1], 40, "the random queries really found structures")


func test_structure_index_skips_a_dead_unit_and_a_fallen_building() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = WORLD_SEED + 2
	_prototype_world(rng)
	for unit_id: int in _units.ids():
		if unit_id % 2 == 0:
			_units.damage(unit_id, 100000, &"enemy")
	_buildings.damage_building(&"house_1", 100000)
	_index.rebuild(_units, _buildings, _castle)
	var result: Array[int] = _compare_random_queries(10.0, rng)
	assert_eq(result[0], 0, "dead units and fallen buildings are never candidates")


func test_a_unit_wins_a_tie_with_a_building_at_the_same_edge() -> void:
	_tie_world([Vector3(104.5, 0.0, 100.0)])
	var unit_def: UnitDef = (load(FOOTMAN_PATH) as UnitDef).duplicate()
	unit_def.radius = 0.5
	var unit_id: int = _units.spawn(unit_def, &"squad", 0, ENEMY_AT + Vector2(0.0, 3.5))
	_index.rebuild(_units, _buildings, _castle)
	var grunt: EnemyDef = load(GRUNT_PATH)
	var answer: Vector3i = _index.nearest(ENEMY_AT, grunt.aggro_range)
	assert_eq(answer, Vector3i(StructureIndex.KIND_UNIT, unit_id, 1), "the unit")
	assert_eq(answer, _reference(ENEMY_AT, grunt.aggro_range), "as the shipped scan")


func test_the_earlier_spot_wins_a_tie_between_two_buildings() -> void:
	_tie_world([Vector3(104.5, 0.0, 100.0), Vector3(95.5, 0.0, 100.0)])
	_index.rebuild(_units, _buildings, _castle)
	var aggro: float = (load(GRUNT_PATH) as EnemyDef).aggro_range
	assert_eq(
		_index.nearest(ENEMY_AT, aggro), Vector3i(StructureIndex.KIND_BUILDING, 0, 1), "spot 0"
	)
	_tie_world([Vector3(95.5, 0.0, 100.0), Vector3(104.5, 0.0, 100.0)])
	_index.rebuild(_units, _buildings, _castle)
	assert_eq(
		_index.nearest(ENEMY_AT, aggro),
		Vector3i(StructureIndex.KIND_BUILDING, 0, 1),
		"spot 0 again, whichever side it is on"
	)


func test_nothing_in_range_reports_none() -> void:
	_tie_world([Vector3(104.5, 0.0, 100.0)])
	_index.rebuild(_units, _buildings, _castle)
	var far: Vector2 = Vector2(500.0, 500.0)
	assert_eq(_index.nearest(far, 10.0), StructureIndex.NONE, "no candidate near the point")
	assert_eq(_reference(far, 10.0), StructureIndex.NONE, "the reference agrees")


func test_the_castle_is_found_when_it_is_the_only_thing_in_range() -> void:
	_tie_world([])
	_index.rebuild(_units, _buildings, _castle)
	var near_castle: Vector2 = _castle.get_position() + Vector2(_castle.get_radius() + 2.0, 0.0)
	assert_eq(
		_index.nearest(near_castle, 6.0), Vector3i(StructureIndex.KIND_CASTLE, 0, 1), "the castle"
	)


# --- EnemyIndex behind TargetQuery.nearest_enemy ---


## The shipped TargetQuery.nearest_enemy, kept verbatim as the reference.
func _reference_nearest_enemy(enemies: EnemySystem, pos: Vector2, reach: float) -> int:
	var best_id: int = -1
	var best_d2: float = INF
	var limit: float = reach * reach
	for id: int in enemies.ids():
		if not enemies.is_alive(id):
			continue
		var d2: float = pos.distance_squared_to(enemies.position_of(id))
		if d2 <= limit and d2 < best_d2:
			best_d2 = d2
			best_id = id
	return best_id


## ENEMY_COUNT grunts at seeded positions, then two placed exactly equidistant from TIE_POINT (far
## outside the random spread) so the lower id must win there.
func _enemy_field(rng: RandomNumberGenerator) -> EnemySystem:
	var enemies: EnemySystem = EnemySystem.new(_events)
	var grunt: EnemyDef = load(GRUNT_PATH)
	for _enemy: int in range(ENEMY_COUNT):
		var pos: Vector2 = Vector2(
			rng.randf_range(-SPREAD, SPREAD), rng.randf_range(-SPREAD, SPREAD)
		)
		enemies.spawn(grunt, pos)
	enemies.spawn(grunt, TIE_POINT + Vector2(3.0, 0.0))
	enemies.spawn(grunt, TIE_POINT + Vector2(-3.0, 0.0))
	return enemies


## Counts queries whose answer differs from the reference at each reach; returns [mismatches, hits].
func _compare_enemy_queries(enemies: EnemySystem, rng: RandomNumberGenerator) -> Array[int]:
	var mismatches: int = 0
	var hits: int = 0
	for reach: float in ENEMY_REACHES:
		for _query: int in range(ENEMY_QUERIES_PER_REACH):
			var pos: Vector2 = Vector2(
				rng.randf_range(-SPREAD, SPREAD), rng.randf_range(-SPREAD, SPREAD)
			)
			var expected: int = _reference_nearest_enemy(enemies, pos, reach)
			if TargetQuery.nearest_enemy(enemies, pos, reach) != expected:
				mismatches += 1
			if expected >= 0:
				hits += 1
	return [mismatches, hits]


func test_nearest_enemy_matches_the_shipped_scan_at_reaches_2_7_10_5_and_22() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = WORLD_SEED + 10
	var enemies: EnemySystem = _enemy_field(rng)
	var result: Array[int] = _compare_enemy_queries(enemies, rng)
	assert_eq(result[0], 0, "no mismatch against the reference scan over 200 queries")
	assert_gt(result[1], 100, "the queries really found enemies")


func test_two_equidistant_enemies_go_to_the_lower_id() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = WORLD_SEED + 11
	var enemies: EnemySystem = _enemy_field(rng)
	var ids: Array[int] = enemies.ids()
	var lower: int = ids[ids.size() - 2]
	assert_eq(TargetQuery.nearest_enemy(enemies, TIE_POINT, 3.0), lower, "the lower id, at reach")
	assert_eq(TargetQuery.nearest_enemy(enemies, TIE_POINT, 10.5), lower, "and with room to spare")
	assert_eq(TargetQuery.nearest_enemy(enemies, TIE_POINT, 2.99), -1, "just outside both")


func test_a_dead_enemy_that_is_not_removed_yet_is_never_returned() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = WORLD_SEED + 12
	var enemies: EnemySystem = _enemy_field(rng)
	var ids: Array[int] = enemies.ids()
	var lower: int = ids[ids.size() - 2]
	var upper: int = ids[ids.size() - 1]
	assert_eq(TargetQuery.nearest_enemy(enemies, TIE_POINT, 5.0), lower, "alive: the lower id")
	enemies.damage(lower, 100000, &"tower")
	assert_eq(TargetQuery.nearest_enemy(enemies, TIE_POINT, 5.0), upper, "the dead one is skipped")
	enemies.damage(upper, 100000, &"tower")
	assert_eq(TargetQuery.nearest_enemy(enemies, TIE_POINT, 5.0), -1, "both dead, none left")
	var result: Array[int] = _compare_enemy_queries(enemies, rng)
	assert_eq(result[0], 0, "still the reference's answers")


func test_the_answers_follow_remove_dead_a_spawn_and_a_step_that_moves_enemies() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = WORLD_SEED + 13
	var enemies: EnemySystem = _enemy_field(rng)
	var first: Array[int] = _compare_enemy_queries(enemies, rng)
	assert_eq(first[0], 0, "fresh field")
	for id: int in enemies.ids():
		if id % 3 == 0:
			enemies.damage(id, 100000, &"tower")
	enemies.remove_dead()
	var after_removal: Array[int] = _compare_enemy_queries(enemies, rng)
	assert_eq(after_removal[0], 0, "after remove_dead")
	enemies.spawn(load(GRUNT_PATH), TIE_POINT)
	assert_eq(
		TargetQuery.nearest_enemy(enemies, TIE_POINT, 0.5),
		enemies.ids()[enemies.count() - 1],
		"a new enemy is found at once"
	)
	var castle: CastleState = CastleState.new(MapConfig.new(), _events)
	var hits: PendingHits = PendingHits.new()
	for tick: int in range(1, 31):
		enemies.step(tick, castle, null, hits)
	var after_steps: Array[int] = _compare_enemy_queries(enemies, rng)
	assert_eq(after_steps[0], 0, "after 30 steps moved the field")
	enemies.clear()
	assert_eq(TargetQuery.nearest_enemy(enemies, Vector2.ZERO, 50.0), -1, "an empty field")


func test_living_within_lists_every_enemy_in_reach_in_ascending_order() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = WORLD_SEED + 14
	var enemies: EnemySystem = _enemy_field(rng)
	for reach: float in ENEMY_REACHES:
		for _query: int in range(10):
			var pos: Vector2 = Vector2(
				rng.randf_range(-SPREAD, SPREAD), rng.randf_range(-SPREAD, SPREAD)
			)
			var listed: PackedInt64Array = enemies.living_within(pos, reach)
			for index: int in range(1, listed.size()):
				assert_gt(listed[index], listed[index - 1], "ascending ids")
			for id: int in enemies.ids():
				if pos.distance_to(enemies.position_of(id)) <= reach:
					assert_true(id in listed, "enemy %d in reach %s is a candidate" % [id, reach])
