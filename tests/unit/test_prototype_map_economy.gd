extends GutTest
## D-09 and research Open Question 1 (RESOLVED): the prototype map's plot counts, pinned in one
## place. The castle plot is infrastructure: the map ends the phase with 22 buildable plots and 23
## spots (the 22 plus the castle plot). After plan 05-02 it had 15 spots: the fourteen Phase 4 plots
## and castle_plot appended after them (so no PendingHits building index moves). Plan 05-06
## appended gold_mine_1 as spot 16 (index 15). Plans 05-07 to 05-09 add their plots and raise the
## numbers below, this file being the single place they change.
##
## It also carries the generic geometry rules every plot Phase 5 adds must pass (D-09, P3): at least
## 12 m from every spawn-to-castle road segment (a grunt notices a building within 6 m, a skirmisher
## within 9 m), 3 m from every wall run and outside every authored gap, and inside the nav content
## box so NavGrid keeps its layout. Plans 05-07 to 05-09 only append their plot ids to
## PHASE_FIVE_PLOT_IDS and the rules then cover them.

const PROTOTYPE := "res://data/maps/prototype_map.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const CASTLE: StringName = &"castle_plot"
const SPOT_COUNT: int = 16
const BUILDABLE_PLOT_COUNT: int = 15
const CASTLE_PLOT_INDEX: int = 14
## The plots Phase 5 appends after the castle plot, in spot order (index 15 on).
const PHASE_FIVE_PLOT_IDS: Array[StringName] = [&"gold_mine_1"]
const FIRST_PHASE_FIVE_INDEX: int = 15
const MINE: StringName = &"gold_mine_1"
const MINE_AT := Vector3(-30.0, 0.0, 30.0)
## The generic geometry rules (RESEARCH E5, P3).
const MIN_ROAD_CLEARANCE_M: float = 12.0
const MIN_WALL_RUN_CLEARANCE_M: float = 3.0
const GAP_SAMPLE_STEP_M: float = 0.5
const CONTENT_MAX_ABS_X: float = 66.3
const CONTENT_MIN_Z: float = -66.0
const CONTENT_MAX_Z: float = 38.79
## The castle plot stands this far (at most) outside the keep's edge.
const MAX_GAP_TO_KEEP_M: float = 3.0


func _map() -> MapConfig:
	return load(PROTOTYPE)


func _ground(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z)


func _castle_spots(map: MapConfig) -> Array[BuildSpotDef]:
	var found: Array[BuildSpotDef] = []
	for spot: BuildSpotDef in map.spots:
		if spot.is_castle:
			found.append(spot)
	return found


func _spot(map: MapConfig, spot_id: StringName) -> BuildSpotDef:
	for spot: BuildSpotDef in map.spots:
		if spot.id == spot_id:
			return spot
	return null


## Distance in metres from `point` to the segment a-b, all on the ground plane.
func _to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	return point.distance_to(Geometry2D.get_closest_point_to_segment(point, a, b))


func _road_distance(map: MapConfig, point: Vector2) -> float:
	var nearest: float = INF
	var castle: Vector2 = _ground(map.castle_position)
	for spawn: SpawnPointDef in map.spawn_points:
		nearest = minf(nearest, _to_segment(point, _ground(spawn.position), castle))
	return nearest


func _run_distance(run: WallRunDef, point: Vector2) -> float:
	var nearest: float = INF
	for index: int in range(1, run.points.size()):
		nearest = minf(nearest, _to_segment(point, run.points[index - 1], run.points[index]))
	return nearest


## The point `distance` metres along the run's polyline (the last vertex past the end).
func _run_point_at(run: WallRunDef, distance: float) -> Vector2:
	var walked: float = 0.0
	for index: int in range(1, run.points.size()):
		var from: Vector2 = run.points[index - 1]
		var to: Vector2 = run.points[index]
		var length: float = from.distance_to(to)
		if distance <= walked + length and length > 0.0:
			return from.lerp(to, (distance - walked) / length)
		walked += length
	return run.points[run.points.size() - 1]


## Distance from `point` to the nearest sampled point of any authored gap of the run.
func _gap_distance(run: WallRunDef, point: Vector2) -> float:
	var nearest: float = INF
	for gap: Vector2 in run.gaps:
		var at: float = minf(gap.x, gap.y)
		while at <= maxf(gap.x, gap.y):
			nearest = minf(nearest, point.distance_to(_run_point_at(run, at)))
			at += GAP_SAMPLE_STEP_M
	return nearest


func _phase_five_spots(map: MapConfig) -> Array[BuildSpotDef]:
	var found: Array[BuildSpotDef] = []
	for spot_id: StringName in PHASE_FIVE_PLOT_IDS:
		found.append(_spot(map, spot_id))
	return found


func test_the_map_has_sixteen_spots() -> void:
	assert_eq(_map().spots.size(), SPOT_COUNT, "14 Phase 4 plots, the castle plot, the Gold Mine")


func test_exactly_one_spot_is_the_castle_plot_and_it_follows_the_phase_four_plots() -> void:
	var map: MapConfig = _map()
	var castle_spots: Array[BuildSpotDef] = _castle_spots(map)
	assert_eq(castle_spots.size(), 1, "one castle plot")
	assert_eq(map.spots[CASTLE_PLOT_INDEX].id, CASTLE, "it is spot 15 (index 14)")
	assert_true(map.spots[CASTLE_PLOT_INDEX].is_castle, "marked in data")
	assert_eq(map.spots[CASTLE_PLOT_INDEX].building_id, &"castle_center", "buys the castle")


func test_fifteen_buildable_plots_besides_the_castle() -> void:
	var buildable: int = 0
	for spot: BuildSpotDef in _map().spots:
		if not spot.is_castle:
			buildable += 1
	assert_eq(buildable, BUILDABLE_PLOT_COUNT, "the 14 Phase 4 plots and the Gold Mine")


func test_the_shipped_map_validates_clean() -> void:
	var errors: PackedStringArray = _map().validate()
	assert_eq(errors.size(), 0, "no validation error: %s" % [errors])


func test_the_castle_plot_id_is_not_the_reserved_payout_key() -> void:
	assert_ne(CASTLE, MapConfig.CASTLE_PAYOUT_KEY, "castle is reserved for the payout")


func test_the_castle_plot_is_clear_of_the_king_spawn() -> void:
	var map: MapConfig = _map()
	var tuning: LoopTuning = load(TUNING)
	var plot: BuildSpotDef = _castle_spots(map)[0]
	var apart: float = _ground(plot.position).distance_to(_ground(map.king_spawn))
	assert_gt(apart, tuning.interaction_radius, "the castle label does not pop up at spawn")


func test_the_castle_plot_stands_just_outside_the_keep() -> void:
	var map: MapConfig = _map()
	var plot: BuildSpotDef = _castle_spots(map)[0]
	var apart: float = _ground(plot.position).distance_to(_ground(map.castle_position))
	assert_gt(apart, map.castle_radius, "outside the keep")
	assert_lt(apart, map.castle_radius + MAX_GAP_TO_KEEP_M, "and within a few metres of it")


func test_the_castle_plot_is_inside_the_ring_wall() -> void:
	var map: MapConfig = _map()
	var plot: Vector2 = _ground(_castle_spots(map)[0].position)
	for spot: BuildSpotDef in map.spots:
		if spot.id == &"wall_ring":
			for point: Vector2 in spot.wall_run.points:
				assert_lt(plot.distance_to(_ground(map.castle_position)), point.length(), "inside")
			return
	fail_test("the map has no ring wall")


func test_the_phase_five_plots_follow_the_castle_plot_in_order() -> void:
	var map: MapConfig = _map()
	for offset: int in range(PHASE_FIVE_PLOT_IDS.size()):
		var spot: BuildSpotDef = map.spots[FIRST_PHASE_FIVE_INDEX + offset]
		assert_eq(spot.id, PHASE_FIVE_PLOT_IDS[offset], "plot %d is %s" % [offset, spot.id])
		assert_false(spot.is_castle, "and it is not the castle plot")
	var expected: int = FIRST_PHASE_FIVE_INDEX + PHASE_FIVE_PLOT_IDS.size()
	assert_eq(map.spots.size(), expected, "nothing else follows")


func test_the_gold_mine_is_spot_sixteen_where_the_plan_puts_it() -> void:
	var mine: BuildSpotDef = _map().spots[FIRST_PHASE_FIVE_INDEX]
	assert_eq(mine.id, MINE, "index 15")
	assert_eq(mine.building_id, &"gold_mine", "it takes the Gold Mine")
	assert_eq(mine.position, MINE_AT, "at (-30, 0, 30)")
	assert_null(mine.wall_run, "and is no wall plot")


func test_every_phase_five_plot_is_twelve_metres_from_every_road() -> void:
	var map: MapConfig = _map()
	for spot: BuildSpotDef in _phase_five_spots(map):
		var apart: float = _road_distance(map, _ground(spot.position))
		assert_gte(apart, MIN_ROAD_CLEARANCE_M, "%s is %.1f m from a road" % [spot.id, apart])


func test_every_phase_five_plot_is_three_metres_from_every_wall_run() -> void:
	var map: MapConfig = _map()
	for spot: BuildSpotDef in _phase_five_spots(map):
		for other: BuildSpotDef in map.spots:
			if other.wall_run == null:
				continue
			var apart: float = _run_distance(other.wall_run, _ground(spot.position))
			var note: String = "%s is %.1f m from %s" % [spot.id, apart, other.id]
			assert_gte(apart, MIN_WALL_RUN_CLEARANCE_M, note)


func test_no_phase_five_plot_lies_in_an_authored_gap() -> void:
	var map: MapConfig = _map()
	for spot: BuildSpotDef in _phase_five_spots(map):
		for other: BuildSpotDef in map.spots:
			if other.wall_run == null:
				continue
			var apart: float = _gap_distance(other.wall_run, _ground(spot.position))
			var note: String = "%s is %.1f m from a gap of %s" % [spot.id, apart, other.id]
			assert_gte(apart, MIN_WALL_RUN_CLEARANCE_M, note)


func test_every_phase_five_plot_is_inside_the_nav_content_box() -> void:
	for spot: BuildSpotDef in _phase_five_spots(_map()):
		assert_lte(absf(spot.position.x), CONTENT_MAX_ABS_X, "%s: |x| inside the box" % spot.id)
		assert_gte(spot.position.z, CONTENT_MIN_Z, "%s: z above the box floor" % spot.id)
		assert_lte(spot.position.z, CONTENT_MAX_Z, "%s: z below the box ceiling" % spot.id)


func test_the_geometry_rules_catch_a_plot_on_a_road() -> void:
	var map: MapConfig = _map()
	var on_road: Vector2 = Vector2(-30.0, 11.0)
	assert_lt(_road_distance(map, on_road), MIN_ROAD_CLEARANCE_M, "a plot on the west road fails")
	assert_gte(_road_distance(map, _ground(MINE_AT)), MIN_ROAD_CLEARANCE_M, "the Mine passes")
