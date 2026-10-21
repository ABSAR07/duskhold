extends GutTest
## PLAT-01 (plan 04-18, exact_port_rules 10, threats T-04-47 and T-04-48): the native grid mirror
## and the native field reads answer what the GDScript answered for bad input (-1 for no cell,
## INF_COST, the zero vector, false) instead of reading out of bounds, and the grid mirror never
## drifts from NavGrid: layout, border, blocked and owner masks agree cell for cell after a
## rebuild.

const GAP_FIXTURE := "res://tests/fixtures/fixture_map_walls_gap.tres"
const RUN: StringName = &"wall_west"
const CASTLE := Vector2(0.0, 0.0)
const BREAK_DAMAGE: int = 1000000


func _gap_world() -> Dictionary:
	var map: MapConfig = load(GAP_FIXTURE)
	var events: SimEvents = SimEvents.new()
	var buildings: BuildingSystem = BuildingSystem.new(map, events)
	var walls: WallSystem = WallSystem.new(map, buildings, events)
	buildings.apply_next_tier(RUN)
	var grid: NavGrid = NavGrid.new(map)
	grid.rebuild(walls)
	return {"map": map, "walls": walls, "grid": grid}


func _blocked_bytes(count: int) -> PackedByteArray:
	var blocked: PackedByteArray = PackedByteArray()
	blocked.resize(count)
	return blocked


func _owners(count: int) -> PackedInt32Array:
	var owners: PackedInt32Array = PackedInt32Array()
	owners.resize(count)
	owners.fill(-1)
	return owners


func test_a_fresh_grid_mirror_is_unarmed_and_answers_no_cell() -> void:
	var grid: NativeGrid = NativeGrid.new()
	assert_false(grid.is_armed(), "not armed")
	assert_false(grid.is_ready(), "not ready")
	assert_eq(grid.cell_of(Vector2(1.0, 1.0)), -1, "no cell")
	assert_true(grid.is_blocked(0), "every index reads blocked with no mask")
	assert_false(grid.is_border(0), "and none is a border")
	assert_eq(grid.owner_of(0), -1, "and nobody owns it")
	assert_eq(grid.width(), 0, "no width")
	assert_eq(grid.height(), 0, "no height")


func test_a_layout_that_cannot_size_a_grid_stays_unarmed() -> void:
	var grid: NativeGrid = NativeGrid.new()
	grid.set_layout(true, Vector2.ZERO, 2.0, 0, 5)
	assert_false(grid.is_armed(), "a zero width arms nothing")
	grid.set_layout(true, Vector2.ZERO, 2.0, 5, -1)
	assert_false(grid.is_armed(), "a negative height arms nothing")
	grid.set_layout(true, Vector2.ZERO, 0.0, 5, 5)
	assert_false(grid.is_armed(), "a zero cell arms nothing")
	grid.set_layout(true, Vector2.ZERO, -2.0, 5, 5)
	assert_false(grid.is_armed(), "a negative cell arms nothing")
	grid.set_layout(true, Vector2.ZERO, NAN, 5, 5)
	assert_false(grid.is_armed(), "a NaN cell arms nothing")
	grid.set_layout(true, Vector2.ZERO, INF, 5, 5)
	assert_false(grid.is_armed(), "an infinite cell arms nothing")
	grid.set_layout(true, Vector2.ZERO, 2.0, 4294967296, 4294967296)
	assert_false(grid.is_armed(), "a grid whose cell count overflows arms nothing")
	grid.set_layout(false, Vector2.ZERO, 2.0, 5, 5)
	assert_false(grid.is_armed(), "an unarmed layout stays unarmed")
	grid.set_masks(_blocked_bytes(25), _owners(25))
	assert_false(grid.is_ready(), "and masks do not ready it")


func test_masks_of_the_wrong_size_are_refused() -> void:
	var grid: NativeGrid = NativeGrid.new()
	grid.set_layout(true, Vector2(-5.0, -5.0), 2.0, 5, 5)
	assert_true(grid.is_armed(), "armed")
	assert_false(grid.is_ready(), "not ready before masks")
	grid.set_masks(_blocked_bytes(24), _owners(25))
	assert_false(grid.is_ready(), "a short blocked mask is refused")
	grid.set_masks(_blocked_bytes(25), _owners(26))
	assert_false(grid.is_ready(), "a long owner mask is refused")
	grid.set_masks(_blocked_bytes(25), _owners(25))
	assert_true(grid.is_ready(), "masks of width x height are taken")
	assert_eq(grid.cell_of(Vector2(-4.9, -4.9)), 0, "the first cell")
	assert_eq(grid.cell_of(Vector2(5.1, 5.1)), -1, "past the last one")
	assert_eq(grid.cell_of(Vector2(-5.1, 0.0)), -1, "before the first column")
	assert_eq(grid.cell_of(Vector2(NAN, 0.0)), -1, "a NaN position")
	assert_eq(grid.cell_of(Vector2(INF, 0.0)), -1, "an infinite position")
	assert_true(grid.is_blocked(-1), "a negative index reads blocked")
	assert_true(grid.is_blocked(25), "and so does one past the end")
	assert_eq(grid.owner_of(-1), -1, "no owner below the masks")
	assert_eq(grid.owner_of(25), -1, "or above them")


func test_the_border_ring_is_the_outer_cells() -> void:
	var grid: NativeGrid = NativeGrid.new()
	grid.set_layout(true, Vector2.ZERO, 1.0, 4, 3)
	for cell: int in range(12):
		var cell_x: int = cell % 4
		var cell_y: int = cell / 4
		var expected: bool = cell_x == 0 or cell_y == 0 or cell_x == 3 or cell_y == 2
		assert_eq(grid.is_border(cell), expected, "cell %d" % cell)


func test_an_unbuilt_field_answers_unreached_with_no_direction() -> void:
	var field: NativeField = NativeField.new()
	assert_eq(field.cost_at(Vector2(1.0, 2.0)), FlowField.INF_COST, "no cost")
	assert_false(field.is_reached(Vector2(1.0, 2.0)), "not reached")
	assert_eq(field.direction_at(Vector2(1.0, 2.0)), Vector2.ZERO, "no direction")
	field.set_costs(PackedInt32Array([0, 0, 0, 0]), null)
	assert_eq(field.cost_at(Vector2(1.0, 2.0)), FlowField.INF_COST, "no grid, no cost")
	assert_eq(field.direction_at(Vector2(1.0, 2.0)), Vector2.ZERO, "and no direction")


func test_costs_that_do_not_cover_the_grid_never_read_out_of_bounds() -> void:
	var world: Dictionary = _gap_world()
	var grid: NavGrid = world["grid"]
	var field: NativeField = NativeField.new()
	field.set_costs(PackedInt32Array([0, 10, 20]), grid.native())
	var far_cell: Vector2 = grid.centre_of(grid.width() * grid.height() - grid.width() - 3)
	assert_eq(field.cost_at(far_cell), FlowField.INF_COST, "a cell past the costs is unreached")
	assert_eq(field.direction_at(far_cell), Vector2.ZERO, "and has no direction")
	field.set_costs(PackedInt32Array(), grid.native())
	assert_eq(field.direction_at(CASTLE), Vector2.ZERO, "an empty cost array gives no direction")


func test_non_finite_positions_are_unreached() -> void:
	var world: Dictionary = _gap_world()
	var grid: NavGrid = world["grid"]
	var field: FlowField = FlowField.new()
	field.build(grid, CASTLE, 3.5, 0.8)
	for bad: Vector2 in [
		Vector2(NAN, 0.0), Vector2(0.0, NAN), Vector2(INF, 0.0), Vector2(0.0, -INF)
	]:
		assert_eq(field.cost_at(bad), FlowField.INF_COST, "cost at %s" % bad)
		assert_false(field.is_reached(bad), "reached at %s" % bad)


func test_the_grid_mirror_agrees_with_nav_grid_cell_for_cell_after_every_rebuild() -> void:
	var world: Dictionary = _gap_world()
	var grid: NavGrid = world["grid"]
	var walls: WallSystem = world["walls"]
	_assert_mirrored(grid, "after the first rebuild")
	for segment: int in range(0, walls.segment_count(), 3):
		walls.damage_segment(segment, BREAK_DAMAGE)
	grid.rebuild(walls)
	_assert_mirrored(grid, "after segments broke")
	for segment: int in range(walls.segment_count()):
		walls.damage_segment(segment, BREAK_DAMAGE)
	grid.rebuild(walls)
	_assert_mirrored(grid, "after every segment broke")


func test_an_unarmed_nav_grid_has_an_unarmed_mirror() -> void:
	var tuning: NavTuning = NavTuning.new()
	tuning.cell_size = 0.0
	var grid: NavGrid = NavGrid.new(MapConfig.new(), tuning)
	assert_false(grid.is_armed(), "a cell size of zero sizes no grid")
	assert_not_null(grid.native(), "but the mirror exists")
	assert_false(grid.native().is_armed(), "unarmed")
	assert_false(grid.native().is_ready(), "and not ready")
	assert_eq(grid.native().cell_of(Vector2.ZERO), -1, "so it holds no cell")


func _assert_mirrored(grid: NavGrid, label: String) -> void:
	var mirror: NativeGrid = grid.native()
	assert_eq(mirror.is_ready(), grid.is_ready(), "%s: ready" % label)
	assert_eq(mirror.width(), grid.width(), "%s: width" % label)
	assert_eq(mirror.height(), grid.height(), "%s: height" % label)
	assert_eq(mirror.cell_size(), grid.cell_size(), "%s: cell size" % label)
	assert_eq(mirror.origin(), grid.origin(), "%s: origin" % label)
	var mismatches: int = 0
	for cell: int in range(-2, grid.width() * grid.height() + 2):
		if mirror.is_blocked(cell) != grid.is_blocked(cell):
			mismatches += 1
		if mirror.owner_of(cell) != grid.owner_of(cell):
			mismatches += 1
		if cell >= 0 and cell < grid.width() * grid.height():
			if mirror.is_border(cell) != grid.is_border(cell):
				mismatches += 1
			if mirror.cell_of(grid.centre_of(cell)) != grid.cell_of(grid.centre_of(cell)):
				mismatches += 1
	assert_eq(mismatches, 0, "%s: every cell agrees" % label)


func test_a_route_with_nothing_set_answers_no_route() -> void:
	var route: NativeRoute = NativeRoute.new()
	var pos: Vector2 = Vector2(3.0, 4.0)
	assert_false(route.has_intact_walls(), "no walls")
	assert_false(route.is_sealed(pos), "nothing is sealed without walls")
	assert_eq(route.castle_cost_at(pos), FlowField.INF_COST, "no field, no cost")
	assert_eq(route.detour_ticks(pos, 300), SimClock.MAX_TICKS, "and no detour")
	assert_eq(route.probe_of(pos), pos, "a position reads where it stands")
	assert_eq(route.castle_distance_cm(pos), 500, "the castle defaults to the origin")
	assert_eq(route.straight_ticks(pos, 300), WallDecision.walk_ticks(500, 300), "straight ticks")
	assert_eq(route.straight_ticks(pos, 0), SimClock.MAX_TICKS, "a zero speed never arrives")
	assert_eq(route.march_step(pos, 1.0), EnemySystem.desired_step(pos, Vector2.ZERO, 1.0), "step")


func test_the_ticks_agree_with_walk_ticks_for_every_speed() -> void:
	var world: Dictionary = _gap_world()
	var pathing: Pathing = Pathing.new(world["map"], world["walls"])
	pathing.refresh()
	var points: Array[Vector2] = [
		Vector2(-25.0, 0.0), Vector2(-15.0, 3.0), Vector2(6.0, 0.0), Vector2(900.0, -700.0)
	]
	for pos: Vector2 in points:
		for speed: int in [-5, 0, 1, 300, 320, 100000]:
			assert_eq(
				pathing.straight_ticks(pos, speed),
				WallDecision.walk_ticks(pathing.castle_distance_cm(pos), speed),
				"straight at %s speed %d" % [pos, speed]
			)
		assert_eq(pathing.detour_ticks(pos, 0), SimClock.MAX_TICKS, "a zero speed never arrives")
	assert_lt(pathing.detour_ticks(Vector2(-25.0, 0.0), 300), SimClock.MAX_TICKS, "a route exists")
	assert_eq(pathing.detour_ticks(Vector2(900.0, -700.0), 300), SimClock.MAX_TICKS, "outside")


func test_march_without_a_field_is_the_straight_step() -> void:
	var map: MapConfig = load(GAP_FIXTURE)
	var events: SimEvents = SimEvents.new()
	var walls: WallSystem = WallSystem.new(map, BuildingSystem.new(map, events), events)
	var pathing: Pathing = Pathing.new(map, walls)
	pathing.refresh()
	assert_null(pathing.castle_field(), "no wall stands, no field")
	for pos: Vector2 in [Vector2(-25.0, 0.0), Vector2(0.0, 0.0), Vector2(7.5, -3.25)]:
		for reach: float in [-1.0, 0.0, 0.107, 1.0, 1000.0]:
			assert_eq(pathing.march_step(pos, reach), EnemySystem.desired_step(pos, CASTLE, reach))
	assert_false(pathing.is_sealed(Vector2(-25.0, 0.0)), "and nothing is sealed")


func test_a_pathing_without_walls_or_map_still_answers() -> void:
	var pathing: Pathing = Pathing.new(MapConfig.new(), null)
	pathing.refresh()
	assert_false(pathing.is_sealed(Vector2(1.0, 1.0)), "not sealed")
	assert_eq(pathing.castle_cost_at(Vector2(1.0, 1.0)), FlowField.INF_COST, "no cost")
	assert_eq(pathing.detour_ticks(Vector2(1.0, 1.0), 300), SimClock.MAX_TICKS, "no detour")
