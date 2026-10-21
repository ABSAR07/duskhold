extends GutTest
## T-04-11: MapConfig.validate() reports bad wall data instead of arming it. Every bad case edits a
## deep copy of the shipped map and calls validate() directly (never through RunContext, whose
## push_error would fail the test). The unmodified copy reports nothing.

const WEST: int = 10
const NORTH: int = 12
const RING: int = 13
## A path of exactly 201 pieces at the shortest allowed segment (one more than the run cap).
const OVER_CAP_HALF_LENGTH: float = 50.25
const FULL_RUN_LENGTH: float = 100.0
const EXTRA_RUNS: int = 5


func _map() -> MapConfig:
	return E2eSupport.shipped_prototype_map()


func _run(map: MapConfig, index: int) -> WallRunDef:
	return map.spots[index].wall_run


## Asserts validate() reports exactly one error and that it contains every needle.
func _assert_one_error(map: MapConfig, needles: Array[String], label: String) -> void:
	var errors: PackedStringArray = map.validate()
	assert_eq(errors.size(), 1, "%s reports exactly one error: %s" % [label, errors])
	if errors.size() == 1:
		for needle: String in needles:
			assert_string_contains(errors[0], needle, "%s names '%s'" % [label, needle])


func _line(x_from: float, x_to: float, z: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x_from, z), Vector2(x_to, z)])


func test_the_unmodified_copy_reports_nothing() -> void:
	assert_eq(_map().validate(), PackedStringArray(), "the shipped map is clean")
	assert_eq(WallValidation.errors(_map()), PackedStringArray(), "and so are its walls")


func test_a_non_finite_point_is_reported_once() -> void:
	for bad: float in [NAN, INF, -INF]:
		var map: MapConfig = _map()
		var points: PackedVector2Array = _run(map, WEST).points.duplicate()
		points[0] = Vector2(bad, 5.0)
		_run(map, WEST).points = points
		_assert_one_error(map, ["wall_west", "point"], "a point of %s" % bad)


func test_a_single_point_run_is_reported() -> void:
	var map: MapConfig = _map()
	_run(map, WEST).points = PackedVector2Array([Vector2(1.0, 2.0)])
	_assert_one_error(map, ["wall_west", "at least 2"], "one point")


func test_an_empty_run_is_reported() -> void:
	var map: MapConfig = _map()
	_run(map, NORTH).points = PackedVector2Array()
	_assert_one_error(map, ["wall_north", "at least 2"], "no points")


func test_a_segment_length_outside_half_a_metre_to_twenty_is_reported() -> void:
	for bad: float in [0.2, 25.0, 0.0, -3.0]:
		var map: MapConfig = _map()
		_run(map, WEST).segment_length = bad
		_assert_one_error(map, ["wall_west", "segment_length"], "a length of %s" % bad)


func test_a_non_finite_segment_length_is_reported_once() -> void:
	for bad: float in [NAN, INF]:
		var map: MapConfig = _map()
		_run(map, WEST).segment_length = bad
		_assert_one_error(map, ["wall_west", "segment_length"], "a length of %s" % bad)


func test_a_half_thickness_outside_zero_to_two_metres_is_reported() -> void:
	for bad: float in [0.0, 3.0, -0.4]:
		var map: MapConfig = _map()
		_run(map, WEST).half_thickness = bad
		_assert_one_error(map, ["wall_west", "half_thickness"], "a half thickness of %s" % bad)


func test_a_non_finite_half_thickness_is_reported_once() -> void:
	var map: MapConfig = _map()
	_run(map, WEST).half_thickness = NAN
	_assert_one_error(map, ["wall_west", "half_thickness"], "a NaN half thickness")


func test_a_gap_under_three_metres_is_reported() -> void:
	var map: MapConfig = _map()
	_run(map, WEST).gaps = PackedVector2Array([Vector2(16.0, 18.5)])
	_assert_one_error(map, ["wall_west", "gap 1", "minimum"], "a 2.5 m gap")


## One 2 m cell plus twice (0.4 m half thickness + 0.5 m largest agent radius) is 3.8 m: a 3 m gap
## leaves 1.2 m of open centre line, narrower than a cell (review WR-01).
func test_a_gap_the_grid_cannot_route_is_reported_and_a_wider_one_is_accepted() -> void:
	var map: MapConfig = _map()
	_run(map, WEST).gaps = PackedVector2Array([Vector2(16.0, 19.0)])
	_assert_one_error(map, ["wall_west", "gap 1", "3.8"], "a 3 m gap")
	_run(map, WEST).gaps = PackedVector2Array([Vector2(16.0, 19.7)])
	_assert_one_error(map, ["wall_west", "gap 1", "minimum"], "a 3.7 m gap")
	_run(map, WEST).gaps = PackedVector2Array([Vector2(16.0, 19.9)])
	assert_eq(map.validate().size(), 0, "3.9 m is wide enough for one cell")


func test_a_gap_past_the_end_of_the_path_is_reported() -> void:
	var map: MapConfig = _map()
	_run(map, WEST).gaps = PackedVector2Array([Vector2(34.0, 38.0)])
	_assert_one_error(map, ["wall_west", "gap 1", "outside the path"], "a gap past the end")


func test_a_gap_before_the_start_of_the_path_is_reported() -> void:
	var map: MapConfig = _map()
	_run(map, WEST).gaps = PackedVector2Array([Vector2(-2.0, 2.0)])
	_assert_one_error(map, ["wall_west", "gap 1", "outside the path"], "a gap before the start")


func test_two_overlapping_gaps_are_reported_once() -> void:
	var map: MapConfig = _map()
	_run(map, WEST).gaps = PackedVector2Array([Vector2(10.0, 14.0), Vector2(12.0, 16.0)])
	_assert_one_error(map, ["wall_west", "overlap"], "overlapping gaps")


func test_a_non_finite_gap_is_reported_once() -> void:
	var map: MapConfig = _map()
	_run(map, WEST).gaps = PackedVector2Array([Vector2(NAN, 20.0)])
	_assert_one_error(map, ["wall_west", "gap 1", "finite"], "a NaN gap")


func test_a_run_of_two_hundred_and_one_segments_is_reported() -> void:
	var map: MapConfig = _map()
	var run: WallRunDef = _run(map, NORTH)
	run.points = _line(-OVER_CAP_HALF_LENGTH, OVER_CAP_HALF_LENGTH, -60.5)
	run.segment_length = WallValidation.MIN_SEGMENT_LENGTH
	run.gaps = PackedVector2Array()
	_assert_one_error(map, ["wall_north", "201 segments", "allowed in one run"], "201 segments")


func test_a_run_of_exactly_two_hundred_segments_is_accepted() -> void:
	var map: MapConfig = _map()
	var run: WallRunDef = _run(map, NORTH)
	run.points = _line(0.0, FULL_RUN_LENGTH, -60.5)
	run.segment_length = WallValidation.MIN_SEGMENT_LENGTH
	run.gaps = PackedVector2Array()
	assert_eq(run.segment_count(), WallRunDef.MAX_SEGMENTS_PER_RUN, "the cap itself expands")
	assert_eq(map.validate().size(), 0, "and validates clean")


func test_runs_that_together_pass_a_thousand_segments_are_reported_once() -> void:
	var map: MapConfig = _map()
	for index: int in range(EXTRA_RUNS):
		var run: WallRunDef = WallRunDef.new()
		run.points = _line(0.0, FULL_RUN_LENGTH, float(index))
		run.segment_length = WallValidation.MIN_SEGMENT_LENGTH
		var spot: BuildSpotDef = BuildSpotDef.new()
		spot.id = StringName("wall_extra_%d" % index)
		spot.building_id = &"wall"
		spot.wall_run = run
		map.spots.append(spot)
	_assert_one_error(
		map, ["wall plots", "more than the 1000"], "five full runs plus the shipped 52"
	)


func test_a_wall_plot_pointing_at_the_tower_building_is_reported() -> void:
	var map: MapConfig = _map()
	map.spots[RING].building_id = &"tower"
	_assert_one_error(
		map, ["wall_ring", "tower", "pays income, attacks or fields a squad"], "tower"
	)


func test_a_wall_plot_pointing_at_a_house_is_reported() -> void:
	var map: MapConfig = _map()
	map.spots[RING].building_id = &"house"
	_assert_one_error(map, ["wall_ring", "house"], "house")


func test_a_wall_plot_pointing_at_a_barracks_is_reported() -> void:
	var map: MapConfig = _map()
	map.spots[RING].building_id = &"barracks"
	_assert_one_error(map, ["wall_ring", "barracks"], "barracks")
