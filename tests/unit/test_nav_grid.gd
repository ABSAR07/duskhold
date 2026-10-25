extends GutTest
## ENMY-04: the nav grid rasterises the intact wall segments. A straight run blocks the cells whose
## centres lie within half thickness plus the largest agent radius of it, the gap stays open, a
## broken segment opens after a rebuild, and no route leaks through a wall at any angle or offset
## (RESEARCH F5). The size of the grid is capped (T-04-13).
## Gap round G-05-2 (owner UAT decision 2026-10-25): every health and damage number is 100
## times larger; this test's felling blow moved with them so it fells what it felled before.

const GAP_FIXTURE := "res://tests/fixtures/fixture_map_walls_gap.tres"
const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const WALL_PATH := "res://data/buildings/wall.tres"
const GRUNT_PATH := "res://data/enemies/grunt.tres"
const RUN: StringName = &"wall_west"
const PLOT: StringName = &"plot"
const REACH: float = 0.4 + 0.5
const FAR_SPOT: float = 5000.0
const NEAR_EPSILON: float = 0.0001

var _events: SimEvents
var _buildings: BuildingSystem
var _walls: WallSystem


func before_each() -> void:
	_events = SimEvents.new()


## The gap fixture with its run built at tier I.
func _gap_world() -> MapConfig:
	var map: MapConfig = load(GAP_FIXTURE)
	_buildings = BuildingSystem.new(map, _events)
	_walls = WallSystem.new(map, _buildings, _events)
	_buildings.apply_next_tier(RUN)
	return map


## A map holding one closed run through `corners` (the last equals the first), built at tier I.
func _ring_map(corners: PackedVector2Array, cell: float) -> MapConfig:
	var run: WallRunDef = WallRunDef.new()
	run.points = corners
	run.segment_length = 3.0
	run.half_thickness = 0.4
	var spot: BuildSpotDef = BuildSpotDef.new()
	spot.id = PLOT
	spot.position = Vector3(corners[0].x, 0.0, corners[0].y)
	spot.building_id = &"wall"
	spot.wall_run = run
	var map: MapConfig = MapConfig.new()
	map.buildings = [load(WALL_PATH)] as Array[BuildingDef]
	map.spots = [spot] as Array[BuildSpotDef]
	map.enemies = [load(GRUNT_PATH)] as Array[EnemyDef]
	var tuning: NavTuning = NavTuning.new()
	tuning.cell_size = cell
	map.nav_tuning = tuning
	_buildings = BuildingSystem.new(map, _events)
	_walls = WallSystem.new(map, _buildings, _events)
	_buildings.apply_next_tier(PLOT)
	return map


## A closed square run of 24 m shifted by `shift` metres on both axes.
func _square(shift: float) -> PackedVector2Array:
	return PackedVector2Array(
		[
			Vector2(-12.0 + shift, -12.0 + shift),
			Vector2(12.0 + shift, -12.0 + shift),
			Vector2(12.0 + shift, 12.0 + shift),
			Vector2(-12.0 + shift, 12.0 + shift),
			Vector2(-12.0 + shift, -12.0 + shift)
		]
	)


func _built_grid(map: MapConfig) -> NavGrid:
	var grid: NavGrid = NavGrid.new(map)
	grid.rebuild(_walls)
	return grid


## The least distance from `pos` to any intact segment.
func _distance_to_walls(pos: Vector2) -> float:
	var least: float = INF
	for segment: int in range(_walls.segment_count()):
		if _walls.is_intact(segment):
			least = minf(least, pos.distance_to(WallSolids.closest_point(_walls, segment, pos)))
	return least


func _cells_owned_by(grid: NavGrid, segment: int) -> int:
	var total: int = 0
	for cell: int in range(grid.width() * grid.height()):
		if grid.owner_of(cell) == segment:
			total += 1
	return total


## True when a route from `outside` reaches `inside` over the grid built for these walls.
func _leaks(grid: NavGrid, outside: Vector2, inside: Vector2) -> bool:
	var field: FlowField = FlowField.new()
	field.build(grid, inside, 0.0, 0.0)
	return field.is_reached(outside)


func test_a_straight_run_blocks_the_cells_within_half_thickness_plus_the_agent_radius() -> void:
	var map: MapConfig = _ring_map(_square(0.5), 2.0)
	var grid: NavGrid = _built_grid(map)
	assert_true(grid.is_ready(), "built")
	var blocked_near: int = 0
	for cell: int in range(grid.width() * grid.height()):
		if grid.is_border(cell):
			continue
		var distance: float = _distance_to_walls(grid.centre_of(cell))
		if distance <= REACH:
			blocked_near += 1
			assert_true(grid.is_blocked(cell), "a cell %.2f m from a segment is blocked" % distance)
			assert_gte(grid.owner_of(cell), 0, "and names a segment")
	assert_gt(blocked_near, 0, "the run blocks something")


func test_a_run_between_two_columns_of_centres_still_blocks_its_crossings() -> void:
	var map: MapConfig = _gap_world()
	var grid: NavGrid = _built_grid(map)
	var near: int = 0
	var blocked: int = 0
	for cell: int in range(grid.width() * grid.height()):
		if grid.is_border(cell):
			continue
		if _distance_to_walls(grid.centre_of(cell)) <= REACH:
			near += 1
		if grid.is_blocked(cell):
			blocked += 1
	assert_eq(near, 0, "the centres sit 1 m either side of the wall, outside the band")
	assert_gt(blocked, 0, "yet the wall blocks the moves across it, so nothing leaks")


func test_every_blocked_cell_is_near_the_wall_and_names_a_segment_within_reach() -> void:
	var map: MapConfig = _gap_world()
	var grid: NavGrid = _built_grid(map)
	var limit: float = grid.cell_size() * 1.5
	for cell: int in range(grid.width() * grid.height()):
		if grid.is_border(cell) or not grid.is_blocked(cell):
			continue
		var distance: float = _distance_to_walls(grid.centre_of(cell))
		assert_lte(distance, limit, "blocked cells hug the wall (%.2f m)" % distance)
		var owner: int = grid.owner_of(cell)
		assert_true(_walls.is_intact(owner), "the owner is an intact segment")


func test_the_gap_stays_open() -> void:
	var map: MapConfig = _gap_world()
	var grid: NavGrid = _built_grid(map)
	var open: int = 0
	for cell: int in range(grid.width() * grid.height()):
		var centre: Vector2 = grid.centre_of(cell)
		if absf(centre.x + 20.0) <= 1.0 and centre.y >= 2.95 and centre.y <= 5.05:
			open += 0 if grid.is_blocked(cell) else 1
	assert_gt(open, 0, "a cell of the 4 m gap is open")
	var field: FlowField = FlowField.new()
	field.build(grid, Vector2(0.0, 0.0), 3.5, 0.8)
	assert_true(field.is_reached(Vector2(-25.0, 0.0)), "and the west side reaches the castle")


func test_the_border_is_always_blocked() -> void:
	var map: MapConfig = _gap_world()
	var grid: NavGrid = _built_grid(map)
	assert_true(grid.is_blocked(0), "the first cell")
	assert_true(grid.is_blocked(grid.width() * grid.height() - 1), "the last cell")
	assert_true(grid.is_border(grid.width() - 1), "the end of the first row")
	assert_eq(grid.owner_of(0), -1, "and owned by nobody")


func test_a_broken_segment_opens_after_a_rebuild() -> void:
	var map: MapConfig = _gap_world()
	var grid: NavGrid = _built_grid(map)
	var before: int = _cells_owned_by(grid, 2)
	var version: int = grid.version()
	assert_gt(before, 0, "segment 2 owns cells")
	_walls.damage_segment(2, 100000)
	assert_eq(_cells_owned_by(grid, 2), before, "the grid does not change until rebuilt")
	grid.rebuild(_walls)
	assert_eq(_cells_owned_by(grid, 2), 0, "the broken segment owns nothing")
	assert_eq(grid.version(), version + 1, "the rebuild bumps the version")
	assert_false(grid.is_blocked(grid.cell_of(Vector2(-20.0, -2.5))), "its middle is a hole")


func test_cell_count_for_the_prototype_map_is_below_the_cap() -> void:
	var map: MapConfig = load(PROTOTYPE_MAP)
	var count: int = NavGrid.cell_count_for(map, NavGrid.tuning_of(map))
	gut.p("prototype map nav grid: %d cells" % count)
	assert_lt(count, NavGrid.MAX_NAV_CELLS, "the shipped map fits")
	assert_gt(count, 0, "and has cells")
	assert_true(NavGrid.new(map).is_armed(), "so its grid is armed")


func test_a_grid_over_the_cap_is_not_armed_and_allocates_nothing() -> void:
	var map: MapConfig = (load(PROTOTYPE_MAP) as MapConfig).duplicate_deep(
		Resource.DEEP_DUPLICATE_ALL
	)
	map.spots[0].position = Vector3(FAR_SPOT, 0.0, 0.0)
	var count: int = NavGrid.cell_count_for(map, NavGrid.tuning_of(map))
	assert_gt(count, NavGrid.MAX_NAV_CELLS, "a spot 5000 m away needs more than the cap")
	var grid: NavGrid = NavGrid.new(map)
	assert_false(grid.is_armed(), "not armed")
	var events: SimEvents = SimEvents.new()
	var walls: WallSystem = WallSystem.new(map, BuildingSystem.new(map, events), events)
	grid.rebuild(walls)
	assert_eq(grid.allocated_cells(), 0, "nothing was allocated")
	assert_false(grid.is_ready(), "and it never becomes ready")
	assert_eq(grid.cell_of(Vector2.ZERO), -1, "no cell answers")


func test_a_bad_cell_size_is_not_armed() -> void:
	var map: MapConfig = load(PROTOTYPE_MAP)
	var tuning: NavTuning = NavTuning.new()
	tuning.cell_size = NAN
	assert_gt(NavGrid.cell_count_for(map, tuning), NavGrid.MAX_NAV_CELLS, "NaN cells size nothing")
	tuning.cell_size = 0.0
	assert_false(NavGrid.new(map, tuning).is_armed(), "zero cells size nothing")
	tuning.cell_size = -2.0
	assert_false(NavGrid.new(map, tuning).is_armed(), "negative cells size nothing")


func test_a_45_degree_ring_does_not_leak_at_1_2_and_3_m_cells() -> void:
	var diamond: PackedVector2Array = PackedVector2Array(
		[Vector2(0, -12), Vector2(12, 0), Vector2(0, 12), Vector2(-12, 0), Vector2(0, -12)]
	)
	for cell: float in [1.0, 2.0, 3.0]:
		var map: MapConfig = _ring_map(diamond, cell)
		var grid: NavGrid = _built_grid(map)
		assert_true(grid.is_ready(), "built at %.0f m" % cell)
		assert_false(
			_leaks(grid, Vector2(-16.0, 0.0), Vector2(0.0, 0.0)),
			"no route into the diamond at %.0f m cells" % cell
		)
		assert_true(
			_leaks(grid, Vector2(-16.0, 0.0), Vector2(-14.0, 6.0)),
			"the outside is connected at %.0f m cells" % cell
		)


func test_an_axis_aligned_ring_does_not_leak_at_any_offset_of_2_m_cells() -> void:
	for shift: float in [0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75]:
		var map: MapConfig = _ring_map(_square(shift), 2.0)
		var grid: NavGrid = _built_grid(map)
		assert_false(
			_leaks(grid, Vector2(-17.0, 0.0), Vector2(shift, shift)),
			"no route into the square shifted by %.2f m" % shift
		)


func test_a_thin_wall_at_30_degrees_does_not_leak_at_2_m_cells() -> void:
	var slant: PackedVector2Array = PackedVector2Array(
		[Vector2(-12, -7), Vector2(12, -7), Vector2(12, 7), Vector2(-12, 7), Vector2(-12, -7)]
	)
	var tilted: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in slant:
		tilted.append(Vector2(point.x * 0.866 - point.y * 0.5, point.x * 0.5 + point.y * 0.866))
	var map: MapConfig = _ring_map(tilted, 2.0)
	var grid: NavGrid = _built_grid(map)
	assert_false(_leaks(grid, Vector2(-17.0, 0.0), Vector2(0.0, 0.0)), "sealed")
