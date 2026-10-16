extends GutTest
## Data contract for the pathing tunables (ENMY-04, plan 04-06): the shipped values are pinned, a
## fresh NavTuning reads like the shipped data, the prototype map references the resource and a map
## that names none gets the defaults. Plan 04-07 added the wall decision and stuck numbers beside
## the seven of plan 04-06; both groups are pinned here.

const TUNING := "res://data/tuning/nav_tuning.tres"
const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const SQUADS_FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const EPSILON: float = 0.0001


func _tuning() -> NavTuning:
	return load(TUNING)


func test_the_shipped_numbers() -> void:
	var tuning: NavTuning = _tuning()
	assert_almost_eq(tuning.cell_size, 2.0, EPSILON, "2 m cells")
	assert_almost_eq(tuning.bounds_margin, 10.0, EPSILON, "10 m around the content")
	assert_almost_eq(tuning.goal_margin, 0.8, EPSILON, "goal cells within radius plus 0.8 m")
	assert_eq(tuning.field_cache_size, 8, "eight cached goal fields")
	assert_almost_eq(tuning.goal_quantum, 4.0, EPSILON, "4 m goal quantum")
	assert_eq(tuning.field_builds_per_tick, 1, "one goal field build per tick")
	assert_almost_eq(tuning.field_refresh_seconds, 0.5, EPSILON, "half a second refresh")


func test_the_wall_decision_and_stuck_numbers() -> void:
	var tuning: NavTuning = _tuning()
	assert_almost_eq(tuning.wall_decision_seconds, 0.5, EPSILON, "a segment is judged every 0.5 s")
	assert_almost_eq(tuning.wall_notice_range, 12.0, EPSILON, "12 m to notice a wall")
	assert_eq(tuning.wall_neighbour_span, 2, "two segments either side count the crowd")
	assert_almost_eq(tuning.wall_hysteresis_seconds, 0.5, EPSILON, "half a second of slack")
	assert_almost_eq(tuning.stuck_seconds, 3.0, EPSILON, "three seconds without progress")
	assert_almost_eq(tuning.stuck_progress_m, 0.5, EPSILON, "half a metre counts as progress")


func test_a_fresh_tuning_reads_like_the_shipped_data() -> void:
	var fresh: NavTuning = NavTuning.new()
	var shipped: NavTuning = _tuning()
	assert_almost_eq(fresh.cell_size, shipped.cell_size, EPSILON, "cell size")
	assert_almost_eq(fresh.bounds_margin, shipped.bounds_margin, EPSILON, "margin")
	assert_almost_eq(fresh.goal_margin, shipped.goal_margin, EPSILON, "goal margin")
	assert_eq(fresh.field_cache_size, shipped.field_cache_size, "cache size")
	assert_almost_eq(fresh.goal_quantum, shipped.goal_quantum, EPSILON, "quantum")
	assert_eq(fresh.field_builds_per_tick, shipped.field_builds_per_tick, "builds per tick")
	assert_almost_eq(
		fresh.field_refresh_seconds, shipped.field_refresh_seconds, EPSILON, "refresh seconds"
	)
	assert_almost_eq(fresh.wall_decision_seconds, shipped.wall_decision_seconds, EPSILON, "cadence")
	assert_almost_eq(fresh.wall_notice_range, shipped.wall_notice_range, EPSILON, "notice range")
	assert_eq(fresh.wall_neighbour_span, shipped.wall_neighbour_span, "neighbour span")
	assert_almost_eq(
		fresh.wall_hysteresis_seconds, shipped.wall_hysteresis_seconds, EPSILON, "hysteresis"
	)
	assert_almost_eq(fresh.stuck_seconds, shipped.stuck_seconds, EPSILON, "stuck seconds")
	assert_almost_eq(fresh.stuck_progress_m, shipped.stuck_progress_m, EPSILON, "stuck progress")


func test_the_prototype_map_references_the_resource() -> void:
	var map: MapConfig = load(PROTOTYPE_MAP)
	assert_not_null(map.nav_tuning, "the prototype map names its pathing tunables")
	assert_eq(map.nav_tuning.resource_path, TUNING, "the shipped resource")


func test_a_map_with_no_tuning_gets_the_defaults() -> void:
	var map: MapConfig = load(SQUADS_FIXTURE)
	assert_null(map.nav_tuning, "the fixture names none")
	var used: NavTuning = NavGrid.tuning_of(map)
	assert_not_null(used, "so the grid uses the defaults")
	assert_almost_eq(used.cell_size, 2.0, EPSILON, "2 m cells")
	assert_same(
		NavGrid.tuning_of(load(PROTOTYPE_MAP)),
		(load(PROTOTYPE_MAP) as MapConfig).nav_tuning,
		"the map's own"
	)
