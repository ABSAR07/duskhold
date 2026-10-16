extends GutTest
## D-04, D-05: an intact segment is solid to a circle and blocks a straight line; a broken or
## unbuilt one does neither. The wall under test is one straight run along z = 0 from x = 0 to
## x = 12 in four segments of 3 m, with a second run beyond it that has a gap in the middle.

const WALL_PATH := "res://data/buildings/wall.tres"
const RUN_ID: StringName = &"wall_line"
const HALF: float = 0.4
const RADIUS: float = 0.5
const TOLERANCE: float = 0.0001

var _events: SimEvents
var _buildings: BuildingSystem
var _walls: WallSystem


func before_each() -> void:
	var map: MapConfig = MapConfig.new()
	map.id = &"solids"
	var wall: BuildingDef = load(WALL_PATH)
	map.buildings.append(wall)
	map.spots.append(_plot(RUN_ID, PackedVector2Array([Vector2(0.0, 0.0), Vector2(12.0, 0.0)])))
	var split: PackedVector2Array = PackedVector2Array([Vector2(0.0, 10.0), Vector2(18.0, 10.0)])
	map.spots.append(_plot(&"wall_split", split, PackedVector2Array([Vector2(6.0, 12.0)])))
	_events = SimEvents.new()
	_buildings = BuildingSystem.new(map, _events)
	_walls = WallSystem.new(map, _buildings, _events)


func _plot(
	id: StringName, points: PackedVector2Array, gaps: PackedVector2Array = PackedVector2Array()
) -> BuildSpotDef:
	var run: WallRunDef = WallRunDef.new()
	run.points = points
	run.gaps = gaps
	run.half_thickness = HALF
	var spot: BuildSpotDef = BuildSpotDef.new()
	spot.id = id
	spot.building_id = &"wall"
	spot.wall_run = run
	return spot


func _build(spot_id: StringName = RUN_ID) -> void:
	_buildings.apply_next_tier(spot_id)


func _distance_to_segment(segment: int, pos: Vector2) -> float:
	return pos.distance_to(WallSolids.closest_point(_walls, segment, pos))


func test_a_circle_in_the_middle_of_a_segment_is_pushed_to_exactly_the_reach() -> void:
	_build()
	var pushed: Vector2 = WallSolids.push_out(_walls, Vector2(1.5, 0.2), RADIUS)
	assert_almost_eq(pushed.x, 1.5, TOLERANCE, "pushed straight out along the normal")
	assert_almost_eq(pushed.y, HALF + RADIUS, TOLERANCE, "to half thickness plus radius")
	var below: Vector2 = WallSolids.push_out(_walls, Vector2(1.5, -0.3), RADIUS)
	assert_almost_eq(below.y, -(HALF + RADIUS), TOLERANCE, "and out of the other face")


func test_a_circle_near_an_end_is_pushed_away_from_the_endpoint() -> void:
	_build()
	var pushed: Vector2 = WallSolids.push_out(_walls, Vector2(12.3, 0.1), RADIUS)
	assert_gt(pushed.x, 12.3, "pushed further from the wall, not along it")
	assert_almost_eq(pushed.distance_to(Vector2(12.0, 0.0)), HALF + RADIUS, TOLERANCE, "round end")


func test_a_centre_exactly_on_the_segment_goes_to_its_left_normal() -> void:
	_build()
	var pushed: Vector2 = WallSolids.push_out(_walls, Vector2(4.5, 0.0), RADIUS)
	assert_almost_eq(pushed.x, 4.5, TOLERANCE, "along the normal only")
	assert_almost_eq(pushed.y, HALF + RADIUS, TOLERANCE, "the left of a segment running +x is +z")


func test_a_circle_that_overlaps_nothing_comes_back_unchanged() -> void:
	_build()
	var clear: Vector2 = Vector2(3.3, 2.0)
	assert_eq(WallSolids.push_out(_walls, clear, RADIUS), clear, "clear of the wall")
	var far: Vector2 = Vector2(80.0, -40.0)
	assert_eq(WallSolids.push_out(_walls, far, RADIUS), far, "far from it")


func test_unbuilt_and_broken_segments_push_nothing() -> void:
	var inside: Vector2 = Vector2(1.5, 0.2)
	assert_eq(WallSolids.push_out(_walls, inside, RADIUS), inside, "nothing is built yet")
	_build()
	_walls.damage_segment(0, 1000)
	assert_eq(WallSolids.push_out(_walls, inside, RADIUS), inside, "a hole pushes nothing")
	var next_to_it: Vector2 = Vector2(4.5, 0.2)
	assert_ne(WallSolids.push_out(_walls, next_to_it, RADIUS), next_to_it, "its neighbour does")


func test_a_circle_pushed_by_one_segment_is_not_left_inside_the_next() -> void:
	_build()
	var pushed: Vector2 = WallSolids.push_out(_walls, Vector2(3.05, 0.1), RADIUS)
	for segment: int in range(4):
		assert_gte(_distance_to_segment(segment, pushed), HALF + RADIUS - TOLERANCE, "clear of all")


func test_closest_point_is_clamped_to_the_ends() -> void:
	assert_eq(WallSolids.closest_point(_walls, 0, Vector2(-5.0, 4.0)), Vector2(0.0, 0.0), "before")
	assert_eq(WallSolids.closest_point(_walls, 0, Vector2(1.0, 4.0)), Vector2(1.0, 0.0), "above")
	assert_eq(WallSolids.closest_point(_walls, 0, Vector2(9.0, 4.0)), Vector2(3.0, 0.0), "after")
	assert_eq(WallSolids.closest_point(_walls, 99, Vector2(9.0, 4.0)), Vector2.ZERO, "no such one")


func test_a_line_through_a_run_is_blocked_by_the_segment_it_crosses() -> void:
	_build()
	var blocker: int = WallSolids.first_blocking(
		_walls, Vector2(7.0, 5.0), Vector2(7.0, -5.0), RADIUS
	)
	assert_eq(blocker, 2, "x = 7 crosses the third segment, which spans 6 to 9")


func test_a_line_through_a_gap_with_clearance_is_clear() -> void:
	_build(&"wall_split")
	var line_through: int = WallSolids.first_blocking(
		_walls, Vector2(9.0, 15.0), Vector2(9.0, 5.0), RADIUS
	)
	assert_eq(line_through, -1, "the gap from 6 to 12 is wide enough for a grunt at x = 9")
	var grazing: int = WallSolids.first_blocking(
		_walls, Vector2(6.3, 15.0), Vector2(6.3, 5.0), RADIUS
	)
	assert_ne(grazing, -1, "a line closer to the end than half thickness plus radius is blocked")


func test_of_two_crossed_segments_the_nearer_one_blocks() -> void:
	_build()
	var from_above: int = WallSolids.first_blocking(
		_walls, Vector2(3.0, 4.0), Vector2(3.0, -4.0), 0.5
	)
	assert_eq(from_above, 0, "the segment ending at x = 3 is met, ties to the lower index")
	var slanted: int = WallSolids.first_blocking(
		_walls, Vector2(-2.0, 2.0), Vector2(14.0, -2.0), 0.1
	)
	assert_between(slanted, 0, 3, "a slanted line crosses one of them")


func test_a_clear_line_and_a_broken_run_block_nothing() -> void:
	_build()
	assert_eq(WallSolids.first_blocking(_walls, Vector2(0.0, 5.0), Vector2(12.0, 5.0), 0.5), -1)
	_walls.damage_segment(2, 1000)
	assert_eq(WallSolids.first_blocking(_walls, Vector2(7.0, 5.0), Vector2(7.0, -5.0), 0.5), -1)
	assert_eq(WallSolids.first_blocking(_walls, Vector2(4.0, 5.0), Vector2(4.0, -5.0), 0.5), 1)


func test_with_no_intact_segment_nothing_is_solid() -> void:
	var from: Vector2 = Vector2(7.0, 5.0)
	assert_eq(WallSolids.first_blocking(_walls, from, Vector2(7.0, -5.0), RADIUS), -1)
	assert_eq(WallSolids.push_out(_walls, Vector2(1.5, 0.1), RADIUS), Vector2(1.5, 0.1))


func test_a_circle_walking_straight_at_the_wall_never_gets_through() -> void:
	_build()
	var pos: Vector2 = Vector2(4.5, 6.0)
	var step: Vector2 = Vector2(0.0, -0.107)
	for _tick: int in range(300):
		pos = WallSolids.push_out(_walls, pos + step, RADIUS)
		assert_gt(pos.y, 0.0, "still on the near side of the wall")
	assert_almost_eq(pos.y, HALF + RADIUS, 0.001, "pressed against its face")


func test_a_circle_sliding_along_the_wall_over_a_joint_stays_outside() -> void:
	_build()
	var pos: Vector2 = Vector2(1.0, 5.0)
	var step: Vector2 = Vector2(0.03, -0.1)
	for _tick: int in range(150):
		pos = WallSolids.push_out(_walls, pos + step, RADIUS)
		assert_gt(pos.y, 0.0, "never across the line of the wall")
	assert_gt(pos.x, 3.5, "it slid past the joint at x = 3")


func test_the_pathing_facade_answers_like_the_solids_and_is_inert_without_walls() -> void:
	var pathing: Pathing = Pathing.new(MapConfig.new(), _walls)
	assert_false(pathing.has_intact_walls(), "nothing built")
	assert_eq(pathing.push_out(Vector2(1.5, 0.1), RADIUS), Vector2(1.5, 0.1), "bit for bit")
	assert_eq(pathing.first_blocking(Vector2(7.0, 5.0), Vector2(7.0, -5.0), RADIUS), -1)
	_build()
	assert_true(pathing.has_intact_walls(), "now there are")
	assert_eq(pathing.first_blocking(Vector2(7.0, 5.0), Vector2(7.0, -5.0), RADIUS), 2)
	assert_eq(pathing.closest_point(2, Vector2(7.0, 5.0)), Vector2(7.0, 0.0), "same closest point")
	assert_same(pathing.walls(), _walls, "the same system")
