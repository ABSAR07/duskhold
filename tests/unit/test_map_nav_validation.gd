extends GutTest
## T-04-13, T-04-15: MapConfig.validate() reports a nav grid over NavGrid.MAX_NAV_CELLS and
## out-of-range pathing numbers instead of letting them size an allocation or a cache. Every bad
## case edits a deep copy of the shipped map and calls validate() directly (never through
## RunContext, whose push_error would fail the test).

const FAR_SPOT: float = 5000.0
const NAV_FIELDS: Array[String] = [
	"cell_size",
	"bounds_margin",
	"goal_margin",
	"field_cache_size",
	"goal_quantum",
	"field_builds_per_tick",
	"field_refresh_seconds"
]


func _map() -> MapConfig:
	var map: MapConfig = E2eSupport.shipped_prototype_map()
	map.nav_tuning = (map.nav_tuning.duplicate() as NavTuning)
	return map


## Asserts validate() reports exactly one error and that it contains every needle.
func _assert_one_error(map: MapConfig, needles: Array[String], label: String) -> void:
	var errors: PackedStringArray = map.validate()
	assert_eq(errors.size(), 1, "%s reports exactly one error: %s" % [label, errors])
	if errors.size() == 1:
		for needle: String in needles:
			assert_string_contains(errors[0], needle, "%s names '%s'" % [label, needle])


func test_the_unmodified_copy_reports_nothing() -> void:
	assert_eq(_map().validate(), PackedStringArray(), "the shipped map is clean")


func test_a_map_whose_spots_reach_5000_m_is_reported_with_its_cell_count() -> void:
	var map: MapConfig = _map()
	map.spots[0].position = Vector3(FAR_SPOT, 0.0, 0.0)
	var cells: int = NavGrid.cell_count_for(map, NavGrid.tuning_of(map))
	assert_gt(cells, NavGrid.MAX_NAV_CELLS, "the grid would be over the cap")
	_assert_one_error(
		map, ["nav grid of %d cells" % cells, "exceeds %d" % NavGrid.MAX_NAV_CELLS], "a far spot"
	)


func test_a_map_with_no_wall_plot_is_not_asked_for_a_grid() -> void:
	var map: MapConfig = E2eSupport.shipped_prototype_map()
	var plots: Array[BuildSpotDef] = []
	for spot: BuildSpotDef in map.spots:
		if spot.wall_run == null:
			plots.append(spot)
	map.spots = plots
	plots[0].position = Vector3(FAR_SPOT, 0.0, 0.0)
	assert_eq(map.validate(), PackedStringArray(), "nothing to route round, nothing to cap")


func test_a_cell_size_outside_half_a_metre_to_eight_is_reported() -> void:
	for bad: float in [0.25, 9.0, NAN, INF, 0.0, -2.0]:
		var map: MapConfig = _map()
		map.nav_tuning.cell_size = bad
		var errors: PackedStringArray = map.validate()
		var found: bool = false
		for line: String in errors:
			found = found or line.contains("cell_size")
		assert_true(found, "a cell size of %s is named: %s" % [bad, errors])


func test_a_cache_size_outside_1_to_32_is_reported() -> void:
	for bad: int in [0, -1, 33]:
		var map: MapConfig = _map()
		map.nav_tuning.field_cache_size = bad
		_assert_one_error(map, ["field_cache_size"], "a cache of %d" % bad)


func test_builds_per_tick_outside_1_to_4_are_reported() -> void:
	for bad: int in [0, 5]:
		var map: MapConfig = _map()
		map.nav_tuning.field_builds_per_tick = bad
		_assert_one_error(map, ["field_builds_per_tick"], "%d builds" % bad)


func test_a_refresh_time_outside_a_tenth_to_ten_seconds_is_reported() -> void:
	for bad: float in [0.05, 11.0, NAN, INF]:
		var map: MapConfig = _map()
		map.nav_tuning.field_refresh_seconds = bad
		_assert_one_error(map, ["field_refresh_seconds"], "refresh of %s" % bad)


func test_a_non_finite_or_negative_margin_or_quantum_is_reported() -> void:
	var map: MapConfig = _map()
	map.nav_tuning.bounds_margin = NAN
	_assert_one_error(map, ["bounds_margin"], "a NaN margin")
	map = _map()
	map.nav_tuning.goal_margin = -1.0
	_assert_one_error(map, ["goal_margin"], "a negative goal margin")
	map = _map()
	map.nav_tuning.goal_quantum = 0.0
	_assert_one_error(map, ["goal_quantum"], "a zero quantum")


func test_the_shipped_numbers_are_all_inside_their_ranges() -> void:
	var tuning: NavTuning = load("res://data/tuning/nav_tuning.tres")
	for field: String in NAV_FIELDS:
		assert_true(is_finite(float(tuning.get(field))), "%s is finite" % field)
	assert_eq(_map().validate(), PackedStringArray(), "and validate() agrees")
