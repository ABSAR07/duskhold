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
