extends GutTest
## ENMY-04: the goal-field cache behind squad and bot-king routing. Goals in one quantum square
## share a field, only field_builds_per_tick fields are built per tick and a request past the budget
## gets no field, the oldest inserted entry is evicted past field_cache_size, a field is refreshed
## after field_refresh_seconds and a grid rebuild drops every cached field (T-04-15).

const GAP_FIXTURE := "res://tests/fixtures/fixture_map_walls_gap.tres"
const RUN: StringName = &"wall_west"
const GOAL := Vector2(-6.5, -6.5)
const SAME_SQUARE := Vector2(-5.0, -5.5)
const GOAL_RADIUS: float = 0.5

var _walls: WallSystem
var _grid: NavGrid
var _tuning: NavTuning
var _cache: GoalFieldCache


func before_each() -> void:
	var map: MapConfig = load(GAP_FIXTURE)
	var events: SimEvents = SimEvents.new()
	var buildings: BuildingSystem = BuildingSystem.new(map, events)
	_walls = WallSystem.new(map, buildings, events)
	buildings.apply_next_tier(RUN)
	_tuning = NavGrid.tuning_of(map)
	_grid = NavGrid.new(map, _tuning)
	_grid.rebuild(_walls)
	_cache = GoalFieldCache.new(_grid, _tuning)


func test_two_goals_inside_one_quantum_share_the_field() -> void:
	var first: FlowField = _cache.field_for(GOAL, GOAL_RADIUS, 10)
	assert_not_null(first, "the first request builds")
	var second: FlowField = _cache.field_for(SAME_SQUARE, GOAL_RADIUS, 10)
	assert_same(second, first, "the same square, the same field, in the same tick")
	assert_eq(_cache.size(), 1, "one entry")
	assert_eq(
		GoalFieldCache.key_of(GOAL, _tuning.goal_quantum),
		GoalFieldCache.key_of(SAME_SQUARE, _tuning.goal_quantum),
		"the keys agree"
	)


func test_a_second_new_goal_in_the_same_tick_gets_no_field_and_is_built_next_tick() -> void:
	assert_not_null(_cache.field_for(GOAL, GOAL_RADIUS, 10), "the tick's one build")
	var other: Vector2 = Vector2(6.0, 6.0)
	assert_null(_cache.field_for(other, GOAL_RADIUS, 10), "a second goal waits")
	assert_eq(_cache.size(), 1, "and was not cached")
	var built: FlowField = _cache.field_for(other, GOAL_RADIUS, 11)
	assert_not_null(built, "the next tick builds it")
	assert_eq(_cache.size(), 2, "now two entries")


func test_a_ninth_goal_evicts_the_oldest() -> void:
	var first: FlowField = _cache.field_for(GOAL, GOAL_RADIUS, 0)
	for index: int in range(1, _tuning.field_cache_size):
		var goal: Vector2 = GOAL + Vector2(float(index) * 8.0, 0.0)
		assert_not_null(_cache.field_for(goal, GOAL_RADIUS, index), "goal %d" % index)
	assert_eq(_cache.size(), _tuning.field_cache_size, "the cache is full")
	var again: FlowField = _cache.field_for(GOAL, GOAL_RADIUS, 1)
	assert_same(again, first, "still cached while it fits")
	var ninth: Vector2 = GOAL + Vector2(float(_tuning.field_cache_size) * 8.0, 0.0)
	assert_not_null(_cache.field_for(ninth, GOAL_RADIUS, _tuning.field_cache_size), "the ninth")
	assert_eq(_cache.size(), _tuning.field_cache_size, "still at the cap")
	var rebuilt: FlowField = _cache.field_for(GOAL, GOAL_RADIUS, 40)
	assert_not_same(rebuilt, first, "the first goal was evicted and gets a field of its own")


func test_a_field_older_than_the_refresh_time_is_rebuilt_on_its_next_request() -> void:
	var refresh: int = SimClock.ticks(_tuning.field_refresh_seconds)
	var field: FlowField = _cache.field_for(GOAL, GOAL_RADIUS, 100)
	assert_eq(field.goal(), GOAL, "built toward the first goal")
	var young: FlowField = _cache.field_for(SAME_SQUARE, GOAL_RADIUS, 100 + refresh)
	assert_eq(young.goal(), GOAL, "not yet refreshed at the refresh time")
	var old: FlowField = _cache.field_for(SAME_SQUARE, GOAL_RADIUS, 100 + refresh + 1)
	assert_same(old, field, "refreshed in place")
	assert_eq(old.goal(), SAME_SQUARE, "toward the goal asked for now")


func test_a_grid_rebuild_invalidates_every_cached_field() -> void:
	var field: FlowField = _cache.field_for(GOAL, GOAL_RADIUS, 5)
	var version: int = field.built_version()
	_walls.damage_segment(1, 1000)
	_grid.rebuild(_walls)
	var rebuilt: FlowField = _cache.field_for(GOAL, GOAL_RADIUS, 6)
	assert_not_null(rebuilt, "a new tick has a build to spend")
	assert_eq(rebuilt.built_version(), _grid.version(), "built for the new grid")
	assert_ne(rebuilt.built_version(), version, "not the old one")


func test_a_request_over_the_budget_serves_a_still_valid_old_field() -> void:
	var refresh: int = SimClock.ticks(_tuning.field_refresh_seconds)
	assert_not_null(_cache.field_for(GOAL, GOAL_RADIUS, 0), "built at tick 0")
	var other: Vector2 = Vector2(6.0, 6.0)
	assert_not_null(_cache.field_for(other, GOAL_RADIUS, refresh + 5), "spends the build")
	var stale: FlowField = _cache.field_for(GOAL, GOAL_RADIUS, refresh + 5)
	assert_not_null(stale, "an old but valid field is better than none")
	_grid.rebuild(_walls)
	assert_null(_cache.field_for(GOAL, GOAL_RADIUS, refresh + 5), "but not one for an old grid")


func test_an_unbuilt_grid_gets_no_field() -> void:
	var map: MapConfig = load(GAP_FIXTURE)
	var bare: NavGrid = NavGrid.new(map, _tuning)
	var cache: GoalFieldCache = GoalFieldCache.new(bare, _tuning)
	assert_null(cache.field_for(GOAL, GOAL_RADIUS, 0), "no mask, no field")
	assert_eq(cache.size(), 0, "and nothing cached")
