extends GutTest
## D-06 / BLDG-10: the four wall plots of the prototype map, pinned from the shipped data. The road
## runs are placed by the clearance rule (each keeps MIN_RUN_CLEARANCE from its road tower and its
## road spawn point, on opposite sides of the line), the ring has a gap toward each road, and the
## ten Phase 1 to 3 plots keep their ids and places. Geometry is derived from the loaded .tres; the
## literals are the structural numbers the plan fixes.

const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
## The least distance a road run keeps from its tower and from its spawn point, in metres. It is
## more than the 3 m spawn scatter plus the 0.4 m half thickness plus the 0.5 m grunt radius.
const MIN_RUN_CLEARANCE: float = 5.0
const FIRST_WALL_PLOT: int = 10
const WALL_PLOT_IDS: Array[StringName] = [&"wall_west", &"wall_east", &"wall_north", &"wall_ring"]
const ROAD_RUNS: Array[StringName] = [&"wall_west", &"wall_east", &"wall_north"]
const ROAD_NAMES: Array[StringName] = [&"west", &"east", &"north"]
## The ring gaps are authored in path order: the west, north and east road crossings.
const RING_GAP_ROADS: Array[StringName] = [&"west", &"north", &"east"]
const TOWER_IDS: Array[StringName] = [&"tower_1", &"tower_2", &"tower_3"]
const OLD_PLOT_IDS: Array[StringName] = [
	&"house_1",
	&"house_2",
	&"house_3",
	&"house_4",
	&"house_5",
	&"tower_1",
	&"tower_2",
	&"tower_3",
	&"barracks_1",
	&"archery_1"
]
const OLD_PLOT_POSITIONS: Array[Vector3] = [
	Vector3(-9, 0, 9),
	Vector3(9, 0, 9),
	Vector3(-18, 0, -12),
	Vector3(18, 0, -12),
	Vector3(0, 0, -24),
	Vector3(-55, 0, 20),
	Vector3(55, 0, 20),
	Vector3(0, 0, -55),
	Vector3(-16, 0, -2),
	Vector3(16, 0, -2),
]
const PLOT_POSITIONS: Array[Vector3] = [
	Vector3(-58.27, 0, 21.19), Vector3(58.27, 0, 21.19), Vector3(0, 0, -58.5), Vector3(0, 0, -6.5)
]
const SEGMENTS: Array[int] = [12, 12, 12, 16]
const GAP_WIDTH_M: float = 4.0
## Metres from the castle at which each road run crosses its road.
const RUN_DISTANCES: Array[float] = [64.0, 64.0, 60.5]
const DISTANCE_TOLERANCE_M: float = 0.1
const POSITION_TOLERANCE_M: float = 0.01
const RING_DIRECTION_TOLERANCE_DEG: float = 5.0
## The king holds a road plot this far inside its gap, on the castle side.
const PLOT_INSET_M: float = 2.0
const INSET_TOLERANCE_M: float = 0.1
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"


func _map() -> MapConfig:
	return load(PROTOTYPE_MAP)


func _spot(map: MapConfig, spot_id: StringName) -> BuildSpotDef:
	for spot: BuildSpotDef in map.spots:
		if spot.id == spot_id:
			return spot
	return null


func _ground(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z)


## The point `distance` metres along the run polyline.
func _point_at(run: WallRunDef, distance: float) -> Vector2:
	var walked: float = 0.0
	for index: int in range(1, run.points.size()):
		var from: Vector2 = run.points[index - 1]
		var to: Vector2 = run.points[index]
		var length: float = from.distance_to(to)
		if distance <= walked + length or index == run.points.size() - 1:
			return from.lerp(to, clampf((distance - walked) / length, 0.0, 1.0))
		walked += length
	return run.points[run.points.size() - 1]


func _gap_centre(run: WallRunDef, gap_index: int) -> Vector2:
	var gap: Vector2 = run.gaps[gap_index]
	return _point_at(run, (gap.x + gap.y) * 0.5)


func _road_direction(map: MapConfig, road: StringName) -> Vector2:
	return _ground(map.find_spawn_point(road).position).normalized()


func test_the_wall_plots_are_appended_after_archery_1_in_order() -> void:
	var map: MapConfig = _map()
	assert_eq(map.spots.size(), FIRST_WALL_PLOT + WALL_PLOT_IDS.size(), "fourteen plots")
	for index: int in range(WALL_PLOT_IDS.size()):
		var spot: BuildSpotDef = map.spots[FIRST_WALL_PLOT + index]
		assert_eq(spot.id, WALL_PLOT_IDS[index], "plot %d id" % (FIRST_WALL_PLOT + index))
		assert_eq(spot.building_id, &"wall", "%s takes the Wall" % spot.id)
		assert_not_null(spot.wall_run, "%s carries a run" % spot.id)


func test_the_ten_earlier_plots_keep_their_ids_and_positions() -> void:
	var map: MapConfig = _map()
	for index: int in range(OLD_PLOT_IDS.size()):
		assert_eq(map.spots[index].id, OLD_PLOT_IDS[index], "plot %d keeps its id" % index)
		assert_eq(map.spots[index].position, OLD_PLOT_POSITIONS[index], "and its position")
		assert_null(map.spots[index].wall_run, "and is an ordinary plot")


func test_the_wall_plots_sit_where_the_plan_puts_them() -> void:
	var map: MapConfig = _map()
	for index: int in range(WALL_PLOT_IDS.size()):
		var at: Vector3 = _spot(map, WALL_PLOT_IDS[index]).position
		assert_almost_eq(at.x, PLOT_POSITIONS[index].x, POSITION_TOLERANCE_M, "x of %d" % index)
		assert_eq(at.y, 0.0, "on the ground")
		assert_almost_eq(at.z, PLOT_POSITIONS[index].z, POSITION_TOLERANCE_M, "z of %d" % index)


func test_the_outer_runs_make_twelve_segments_and_the_ring_sixteen() -> void:
	var map: MapConfig = _map()
	for index: int in range(WALL_PLOT_IDS.size()):
		var run: WallRunDef = _spot(map, WALL_PLOT_IDS[index]).wall_run
		assert_eq(run.segment_count(), SEGMENTS[index], "%s segments" % WALL_PLOT_IDS[index])
		assert_eq(run.segment_length, 3.0, "cut into 3 m pieces")
		assert_eq(run.half_thickness, 0.4, "0.4 m half thickness")


func test_every_gap_is_four_metres_wide() -> void:
	var map: MapConfig = _map()
	for spot_id: StringName in WALL_PLOT_IDS:
		var run: WallRunDef = _spot(map, spot_id).wall_run
		assert_gt(run.gaps.size(), 0, "%s has a gap" % spot_id)
		for gap: Vector2 in run.gaps:
			assert_almost_eq(gap.y - gap.x, GAP_WIDTH_M, POSITION_TOLERANCE_M, "%s gap" % spot_id)
			assert_gte(gap.y - gap.x, WallValidation.MIN_GAP_METRES, "and over the 3 m minimum")


func test_each_road_run_gap_is_centred_on_its_road_line_at_its_distance() -> void:
	var map: MapConfig = _map()
	for index: int in range(ROAD_RUNS.size()):
		var run: WallRunDef = _spot(map, ROAD_RUNS[index]).wall_run
		assert_eq(run.gaps.size(), 1, "%s has the one gap" % ROAD_RUNS[index])
		var centre: Vector2 = _gap_centre(run, 0)
		assert_almost_eq(
			centre.length(), RUN_DISTANCES[index], DISTANCE_TOLERANCE_M, "%d distance" % index
		)
		var road: Vector2 = _road_direction(map, ROAD_NAMES[index])
		assert_almost_eq(road.cross(centre), 0.0, DISTANCE_TOLERANCE_M, "on the road line")
		assert_gt(road.dot(centre), 0.0, "on the road side of the castle")


func test_the_north_run_lies_on_z_minus_sixty_point_five() -> void:
	var run: WallRunDef = _spot(_map(), &"wall_north").wall_run
	for point: Vector2 in run.points:
		assert_almost_eq(point.y, -60.5, POSITION_TOLERANCE_M, "every point is on z = -60.5")


func test_each_road_run_keeps_the_clearance_from_its_tower_and_its_spawn() -> void:
	var map: MapConfig = _map()
	var largest_radius: float = 0.0
	for enemy: EnemyDef in map.enemies:
		largest_radius = maxf(largest_radius, enemy.radius)
	for index: int in range(ROAD_RUNS.size()):
		var run: WallRunDef = _spot(map, ROAD_RUNS[index]).wall_run
		var tower: Vector2 = _ground(_spot(map, TOWER_IDS[index]).position)
		var spawn_def: SpawnPointDef = map.find_spawn_point(ROAD_NAMES[index])
		var spawn: Vector2 = _ground(spawn_def.position)
		var origin: Vector2 = run.points[0]
		var line: Vector2 = (run.points[run.points.size() - 1] - origin).normalized()
		var tower_side: float = line.cross(tower - origin)
		var spawn_side: float = line.cross(spawn - origin)
		assert_lt(tower_side * spawn_side, 0.0, "%d: tower and spawn on opposite sides" % index)
		assert_gte(absf(tower_side), MIN_RUN_CLEARANCE, "%d: clear of its tower" % index)
		assert_gte(absf(spawn_side), MIN_RUN_CLEARANCE, "%d: clear of its spawn" % index)
		var needed: float = spawn_def.scatter_radius + run.half_thickness + largest_radius
		assert_gt(absf(spawn_side), needed, "%d: the spawn scatter cannot touch the run" % index)


func test_each_road_plot_sits_two_metres_inside_its_gap_on_the_castle_side() -> void:
	var map: MapConfig = _map()
	for index: int in range(ROAD_RUNS.size()):
		var spot: BuildSpotDef = _spot(map, ROAD_RUNS[index])
		var centre: Vector2 = _gap_centre(spot.wall_run, 0)
		var plot: Vector2 = _ground(spot.position)
		assert_almost_eq(plot.distance_to(centre), PLOT_INSET_M, INSET_TOLERANCE_M, "inset")
		assert_lt(plot.length(), centre.length(), "%s is on the castle side" % spot.id)


func test_the_ring_has_a_gap_toward_each_road_within_five_degrees() -> void:
	var map: MapConfig = _map()
	var run: WallRunDef = _spot(map, &"wall_ring").wall_run
	assert_eq(run.gaps.size(), RING_GAP_ROADS.size(), "three gaps")
	for index: int in range(RING_GAP_ROADS.size()):
		var centre: Vector2 = _gap_centre(run, index)
		var road: Vector2 = _road_direction(map, RING_GAP_ROADS[index])
		var off_deg: float = rad_to_deg(absf(road.angle_to(centre)))
		assert_lt(off_deg, RING_DIRECTION_TOLERANCE_DEG, "gap %d faces its road" % index)
		assert_almost_eq(centre.length(), 9.0, 0.2, "and sits on the 9 m ring")


func test_the_ring_is_a_closed_sixteen_sided_polygon_of_radius_nine() -> void:
	var run: WallRunDef = _spot(_map(), &"wall_ring").wall_run
	assert_eq(run.points.size(), 17, "sixteen sides, first vertex repeated")
	assert_eq(run.points[0], run.points[16], "closed")
	for point: Vector2 in run.points:
		assert_almost_eq(point.length(), 9.0, 0.02, "every vertex is 9 m from the castle")


func test_the_ring_plot_is_inside_near_its_north_gap_and_clear_of_the_king_spawn() -> void:
	var map: MapConfig = _map()
	var spot: BuildSpotDef = _spot(map, &"wall_ring")
	var plot: Vector2 = _ground(spot.position)
	var tuning: LoopTuning = load(TUNING_PATH)
	assert_lt(plot.length(), 9.0, "inside the ring")
	assert_lt(plot.distance_to(_gap_centre(spot.wall_run, 1)), 3.0, "near the north gap")
	assert_gt(
		plot.distance_to(_ground(map.king_spawn)),
		tuning.interaction_radius,
		"clear of the king spawn so the label stays hidden at the start of a day"
	)


func test_no_plot_lies_inside_the_interaction_radius_of_another() -> void:
	var map: MapConfig = _map()
	var tuning: LoopTuning = load(TUNING_PATH)
	for a: int in range(map.spots.size()):
		for b: int in range(a + 1, map.spots.size()):
			var apart: float = _ground(map.spots[a].position).distance_to(
				_ground(map.spots[b].position)
			)
			assert_gt(apart, tuning.interaction_radius, "%s apart" % map.spots[b].id)


func test_the_shipped_map_validates_clean_with_the_wall_plots() -> void:
	var errors: PackedStringArray = _map().validate()
	assert_eq(errors.size(), 0, "no validation error: %s" % [errors])
	assert_eq(WallValidation.errors(_map()).size(), 0, "and no wall error")


func test_the_whole_map_makes_fifty_two_segments_within_the_map_cap() -> void:
	var total: int = 0
	for spot: BuildSpotDef in _map().spots:
		if spot.wall_run != null:
			total += spot.wall_run.segment_count()
	assert_eq(total, 52, "12 + 12 + 12 + 16")
	assert_lte(total, WallValidation.MAX_SEGMENTS_PER_MAP, "inside the map cap")


func test_the_farthest_plot_pair_still_rides_inside_the_twelve_to_eighteen_second_band() -> void:
	var map: MapConfig = _map()
	var king: KingDef = load("res://data/king/king.tres")
	var farthest: float = 0.0
	for a: BuildSpotDef in map.spots:
		for b: BuildSpotDef in map.spots:
			farthest = maxf(farthest, _ground(a.position).distance_to(_ground(b.position)))
	assert_between(farthest / king.walk_speed, 12.0, 18.0, "the ride in seconds (D-06)")
