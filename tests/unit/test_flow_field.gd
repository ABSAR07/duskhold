extends GutTest
## ENMY-04: the castle flow field is an integer Dial field over the nav grid. Goal cells cost 0, an
## orthogonal step 10 and a diagonal 14, a route behind a wall takes the gap, a walled-off region
## costs INF_COST and has no direction, directions beside the wall bend toward the gap, and two
## builds over one grid give identical cost arrays (DR-1 to DR-10).

const GAP_FIXTURE := "res://tests/fixtures/fixture_map_walls_gap.tres"
const RING_FIXTURE := "res://tests/fixtures/fixture_map_walls.tres"
const RUN: StringName = &"wall_west"
const RING: StringName = &"wall_ring"
const CASTLE := Vector2(0.0, 0.0)
const GAP_CENTRE := Vector2(-20.0, 4.0)

var _events: SimEvents
var _walls: WallSystem


func before_each() -> void:
	_events = SimEvents.new()


func _grid_for(fixture: String, plot: StringName) -> NavGrid:
	var map: MapConfig = load(fixture)
	var buildings: BuildingSystem = BuildingSystem.new(map, _events)
	_walls = WallSystem.new(map, buildings, _events)
	buildings.apply_next_tier(plot)
	var grid: NavGrid = NavGrid.new(map)
	grid.rebuild(_walls)
	return grid


func _castle_field(grid: NavGrid) -> FlowField:
	var field: FlowField = FlowField.new()
	field.build(grid, CASTLE, 3.5, 0.8)
	return field


func test_goal_cells_cost_nothing_and_steps_cost_10_and_14() -> void:
	var grid: NavGrid = _grid_for(GAP_FIXTURE, RUN)
	var field: FlowField = FlowField.new()
	field.build(grid, Vector2(-5.0, -5.0), 0.0, 0.0)
	var costs: PackedInt32Array = field.costs()
	var goal: int = costs.find(0)
	assert_gte(goal, 0, "a goal cell exists when the goal is a point")
	assert_eq(costs.count(0), 1, "and it is only one cell")
	var width: int = grid.width()
	assert_eq(costs[goal + 1], FlowField.STEP_ORTHOGONAL, "east of the goal")
	assert_eq(costs[goal - width], FlowField.STEP_ORTHOGONAL, "north of it")
	assert_eq(costs[goal + width + 1], FlowField.STEP_DIAGONAL, "south-east of it")
	assert_eq(costs[goal - width - 1], FlowField.STEP_DIAGONAL, "north-west of it")
	assert_eq(costs[goal + 2], 2 * FlowField.STEP_ORTHOGONAL, "two cells east")
	assert_eq(FlowField.STEP_ORTHOGONAL, 10, "the orthogonal step is pinned")
	assert_eq(FlowField.STEP_DIAGONAL, 14, "and the diagonal one")


func test_the_castle_goal_covers_every_open_cell_within_radius_plus_margin() -> void:
	var grid: NavGrid = _grid_for(GAP_FIXTURE, RUN)
	var field: FlowField = _castle_field(grid)
	for cell: int in range(grid.width() * grid.height()):
		var centre: Vector2 = grid.centre_of(cell)
		if grid.is_blocked(cell):
			continue
		if centre.distance_to(CASTLE) <= 3.5 + 0.8:
			assert_eq(field.costs()[cell], 0, "inside the goal radius costs nothing")
	assert_eq(field.cost_at(CASTLE), 0, "the castle centre")
	assert_eq(field.built_version(), grid.version(), "the field remembers the grid version")


func test_a_cell_behind_the_wall_pays_for_the_detour_through_the_gap() -> void:
	var grid: NavGrid = _grid_for(GAP_FIXTURE, RUN)
	var field: FlowField = _castle_field(grid)
	var west: int = field.cost_at(Vector2(-25.0, 0.0))
	var east: int = field.cost_at(Vector2(-15.0, 0.0))
	var through_gap: int = field.cost_at(Vector2(-21.0, 4.0)) + field.cost_at(Vector2(-25.0, 0.0))
	assert_lt(west, FlowField.INF_COST, "the west side is reached")
	assert_lt(east, FlowField.INF_COST, "so is the east side")
	var straight_cells: int = 5
	assert_gt(
		west,
		east + straight_cells * FlowField.STEP_ORTHOGONAL,
		"the west costs more than the straight metres: it goes round through the gap"
	)
	assert_gt(through_gap, 0, "the gap cell is on a route")
	var gap_cost: int = field.cost_at(Vector2(-19.0, 4.0))
	assert_lt(gap_cost, east + 6 * FlowField.STEP_ORTHOGONAL, "the east side of the gap is near")


func test_a_walled_off_region_is_unreached_and_has_no_direction() -> void:
	var grid: NavGrid = _grid_for(RING_FIXTURE, RING)
	var field: FlowField = FlowField.new()
	field.build(grid, Vector2(-30.0, 0.0), 0.5, 0.8)
	var inside: Vector2 = Vector2(0.0, 0.0)
	assert_eq(field.cost_at(inside), FlowField.INF_COST, "inside the ring costs INF_COST")
	assert_false(field.is_reached(inside), "and is not reached")
	assert_eq(field.direction_at(inside), Vector2.ZERO, "with no direction")
	assert_true(field.is_reached(Vector2(-20.0, 0.0)), "outside the ring is reached")
	var castle_field: FlowField = _castle_field(grid)
	assert_false(castle_field.is_reached(Vector2(-25.0, 0.0)), "the castle is sealed from outside")
	assert_true(castle_field.is_reached(Vector2(6.0, 0.0)), "but not from inside")


func test_the_direction_beside_the_wall_points_toward_the_gap() -> void:
	var grid: NavGrid = _grid_for(GAP_FIXTURE, RUN)
	var field: FlowField = _castle_field(grid)
	for at: Vector2 in [Vector2(-22.0, 0.0), Vector2(-23.0, -3.0), Vector2(-24.0, 8.0)]:
		var direction: Vector2 = field.direction_at(at)
		assert_almost_eq(direction.length(), 1.0, 0.001, "a unit direction at %s" % str(at))
		var to_gap: Vector2 = (GAP_CENTRE - at).normalized()
		assert_gt(direction.dot(to_gap), 0.0, "it bends toward the gap from %s" % str(at))
	var east_side: Vector2 = field.direction_at(Vector2(-15.0, 3.0))
	assert_gt(east_side.dot((CASTLE - Vector2(-15.0, 3.0)).normalized()), 0.5, "east: straight in")


func test_following_the_field_from_the_spawn_crosses_the_wall_line_in_the_gap() -> void:
	var grid: NavGrid = _grid_for(GAP_FIXTURE, RUN)
	var field: FlowField = _castle_field(grid)
	var at: Vector2 = Vector2(-30.0, 0.0)
	var crossed_at: float = INF
	for _step: int in range(600):
		var before: Vector2 = at
		at += field.direction_at(at) * 0.1
		if before.x < -20.0 and at.x >= -20.0:
			crossed_at = before.y + (at.y - before.y) * ((-20.0 - before.x) / (at.x - before.x))
			break
	assert_lt(crossed_at, INF, "the walk crosses x = -20")
	assert_gt(crossed_at, 2.0, "inside the gap, above its south end")
	assert_lt(crossed_at, 6.0, "and below its north end")


func test_two_builds_over_one_grid_give_identical_cost_arrays() -> void:
	var grid: NavGrid = _grid_for(GAP_FIXTURE, RUN)
	var first: FlowField = _castle_field(grid)
	var second: FlowField = _castle_field(grid)
	assert_eq(first.costs(), second.costs(), "the same costs")
	second.build(grid, CASTLE, 3.5, 0.8)
	assert_eq(first.costs(), second.costs(), "and again after a rebuild of the same field")
	var other: FlowField = FlowField.new()
	other.build(grid, Vector2(8.0, 5.0), 1.0, 0.8)
	assert_ne(first.costs(), other.costs(), "another goal gives another field")


func test_a_field_over_an_unbuilt_grid_reaches_nothing() -> void:
	var map: MapConfig = load(GAP_FIXTURE)
	var grid: NavGrid = NavGrid.new(map)
	var field: FlowField = FlowField.new()
	field.build(grid, CASTLE, 3.5, 0.8)
	assert_false(field.is_reached(Vector2(-25.0, 0.0)), "no mask, no route")
	assert_eq(field.direction_at(Vector2(-25.0, 0.0)), Vector2.ZERO, "and no direction")
	assert_eq(field.cost_at(Vector2(9999.0, 0.0)), FlowField.INF_COST, "a far point is INF_COST")


func test_a_blocked_cell_reads_the_cheapest_open_neighbour() -> void:
	var grid: NavGrid = _grid_for(GAP_FIXTURE, RUN)
	var field: FlowField = _castle_field(grid)
	var cell: int = -1
	for index: int in range(grid.width() * grid.height()):
		if not grid.is_border(index) and grid.is_blocked(index) and grid.owner_of(index) >= 0:
			cell = index
			break
	assert_gte(cell, 0, "a blocked cell exists")
	var cost: int = field.cost_at(grid.centre_of(cell))
	assert_lt(cost, FlowField.INF_COST, "a wall-side position still has a cost")
	assert_true(field.is_reached(grid.centre_of(cell)), "and is reached")
