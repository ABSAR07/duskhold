extends GutTest
## RESEARCH Pitfall 5: a wall plot is not an ordinary building. It is never a target or a tower's
## quarry, never pays at dawn, and the scene gives it no model, only its plot marker.

const FIXTURE := "res://tests/fixtures/fixture_map_walls.tres"
const GRUNT_PATH := "res://data/enemies/grunt.tres"
const RING: StringName = &"wall_ring"
const TOWER: StringName = &"tower_1"
const WATCH_TICKS: int = 90
const VIEW_TIMEOUT_S: float = 1.0


func _context() -> RunContext:
	var tuning: LoopTuning = load("res://data/tuning/loop_tuning.tres")
	return RunContext.new(load(FIXTURE), tuning, 1)


func test_a_built_wall_plot_is_not_a_standing_building_and_pays_nothing() -> void:
	var ctx: RunContext = _context()
	ctx.commands.submit(BuildIntent.new(RING))
	ctx.commands.submit(BuildIntent.new(TOWER))
	var standing: Array[StringName] = ctx.buildings.standing_spot_ids()
	assert_eq(standing, [TOWER] as Array[StringName], "only the tower stands as a building")
	assert_false(ctx.buildings.dawn_income_by_spot().has(RING), "the wall pays no dawn income")
	assert_eq(ctx.buildings.current_tier(RING), 1, "but the plot is built")


func test_an_enemy_beside_the_wall_plot_never_targets_it_as_a_building() -> void:
	var ctx: RunContext = _context()
	ctx.commands.submit(BuildIntent.new(RING))
	ctx.commands.submit(StartNightIntent.new())
	var enemies: EnemySystem = ctx.night.get_enemies()
	var plot: Vector3 = ctx.buildings.get_spot(RING).position
	var grunt: EnemyDef = load(GRUNT_PATH)
	var id: int = enemies.spawn(grunt, Vector2(plot.x + 1.0, plot.z))
	var ring_index: int = ctx.buildings.spot_index(RING)
	for _tick: int in range(WATCH_TICKS):
		ctx.step()
		if not enemies.is_alive(id):
			break
		var target: Dictionary = enemies.target_of(id)
		var is_the_plot: bool = (
			target.get("kind", &"") == PendingHits.KIND_BUILDING
			and target.get("id", -1) == ring_index
		)
		assert_false(is_the_plot, "the plot is never a building target")


func test_the_scene_draws_no_model_for_a_wall_plot_but_keeps_its_marker() -> void:
	var map: MapConfig = load(FIXTURE)
	var map_root: MapRoot = await E2eSupport.spawn_map(self, map.duplicate_deep())
	var ctx: RunContext = map_root.get_context()
	var views: BuildingViews = map_root.get_node("BuildingViews")
	assert_eq(ctx.commands.submit(BuildIntent.new(RING)), CommandProcessor.OK, "wall built")
	assert_eq(ctx.commands.submit(BuildIntent.new(TOWER)), CommandProcessor.OK, "tower built")
	var tower_drawn: Callable = func() -> bool: return views.get_view(TOWER) != null
	assert_true(await E2eSupport.wait_until(self, tower_drawn, VIEW_TIMEOUT_S), "tower modelled")
	assert_null(views.get_view(RING), "no model for the wall plot")
	assert_null(views.get_health_bar(RING), "and no bar")
	assert_not_null(views.get_node_or_null("Spot_wall_ring"), "the plot marker stays")
