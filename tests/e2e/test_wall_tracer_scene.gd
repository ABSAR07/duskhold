extends GutTest
## The wall tracer in the real scene (BLDG-10): a ring bought by day is drawn whole, the night's
## grunts break a segment, the broken piece becomes rubble, an enemy walks through the hole into the
## ring, and the night reaches dawn.

const FIXTURE := "res://tests/fixtures/fixture_map_walls.tres"
const RING: StringName = &"wall_ring"
const TOWER: StringName = &"tower_1"
const SEGMENTS: int = 32
const DRAW_TIMEOUT_S: float = 1.0
## The collapse of a broken piece takes 0.4 s of presentation time; this is a generous bound.
const COLLAPSE_TIMEOUT_S: float = 3.0
## The night is driven by simulation ticks, never by wall-clock time (review WR-07): the most
## simulated seconds it may take to reach dawn, a bound on the loop and not a timer.
const NIGHT_LIMIT_SIM_SECONDS: float = 180.0
## An enemy inside this square on both axes is inside the ring (its walls stand at 12 m).
const INSIDE_LIMIT: float = 11.5
const HALF_THICKNESS: float = 0.4
## The distance tolerance for the king's clearance.
const EPSILON: float = 0.001


func _spawn_wall_map() -> MapRoot:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	var map_root: MapRoot = scene.instantiate()
	map_root.map_config = load(FIXTURE)
	map_root.fixed_run_seed = 1
	add_child_autofree(map_root)
	await wait_process_frames(2)
	# The tests advance the simulation themselves with RunContext.step(); the root's own _process
	# would add real-time steps on top.
	map_root.set_process(false)
	return map_root


func _any_enemy_inside(enemies: EnemySystem) -> bool:
	for id: int in enemies.ids():
		var at: Vector2 = enemies.position_of(id)
		if absf(at.x) < INSIDE_LIMIT and absf(at.y) < INSIDE_LIMIT:
			return true
	return false


func test_a_bought_ring_is_drawn_broken_into_rubble_and_walked_through() -> void:
	var map_root: MapRoot = await _spawn_wall_map()
	var ctx: RunContext = map_root.get_context()
	var views: WallViews = map_root.get_node("WallViews")
	assert_eq(views.piece_count(), 0, "no wall before the purchase")
	assert_eq(ctx.commands.submit(BuildIntent.new(RING)), CommandProcessor.OK, "ring bought")
	assert_eq(ctx.commands.submit(BuildIntent.new(TOWER)), CommandProcessor.OK, "tower bought")
	var drawn: Callable = func() -> bool: return views.piece_count() == SEGMENTS
	assert_true(await E2eSupport.wait_until(self, drawn, DRAW_TIMEOUT_S), "32 pieces within 1 s")
	assert_eq(views.rubble_count(), 0, "and no rubble")
	assert_true(views.is_piece_drawn(0), "the first segment is drawn")

	var broken: Array[int] = []
	ctx.events.wall_segment_broken.connect(
		func(_spot: StringName, segment: int) -> void: broken.append(segment)
	)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night starts")
	var king_at: Vector3 = map_root.get_king().global_position
	ctx.king.report_position(Vector2(king_at.x, king_at.z))
	var steps: int = 0
	var max_steps: int = SimClock.ticks(NIGHT_LIMIT_SIM_SECONDS)
	var checked_rubble: bool = false
	var saw_inside: bool = false
	while ctx.run_manager.get_phase() != RunManager.RunPhase.DAWN and steps < max_steps:
		ctx.step()
		steps += 1
		saw_inside = saw_inside or _any_enemy_inside(ctx.night.get_enemies())
		if not broken.is_empty() and not checked_rubble:
			checked_rubble = true
			# Plan 04-05 (D-05): the broken piece sinks for 0.4 s before the rubble is drawn.
			var settled: Callable = func() -> bool: return views.rubble_count() >= 1
			await E2eSupport.wait_until(self, settled, COLLAPSE_TIMEOUT_S)
			assert_gte(views.rubble_count(), 1, "the broken segment is rubble")
			assert_eq(views.piece_count() + views.rubble_count(), SEGMENTS, "no piece is lost")
			assert_false(views.is_piece_drawn(broken[0]), "the broken segment is not a piece")
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "dawn within the timeout")
	assert_gte(broken.size(), 1, "the grunts broke a segment")
	assert_true(checked_rubble, "the rubble was checked")
	assert_true(saw_inside, "an enemy walked through the hole into the ring")


func test_the_king_dropped_on_a_segment_is_pushed_out_of_it() -> void:
	var map_root: MapRoot = await _spawn_wall_map()
	var ctx: RunContext = map_root.get_context()
	var views: WallViews = map_root.get_node("WallViews")
	assert_eq(ctx.commands.submit(BuildIntent.new(RING)), CommandProcessor.OK, "ring bought")
	var drawn: Callable = func() -> bool: return views.piece_count() == SEGMENTS
	assert_true(await E2eSupport.wait_until(self, drawn, DRAW_TIMEOUT_S), "32 pieces within 1 s")
	var king: King = map_root.get_king()
	var reach: float = HALF_THICKNESS + king.def.body_radius
	E2eSupport.teleport_king(map_root, Vector3(-12.0, 0.0, 0.3))
	await wait_physics_frames(2)
	var here: Vector2 = Vector2(king.global_position.x, king.global_position.z)
	var least: float = INF
	for segment: int in range(SEGMENTS):
		var nearest: Vector2 = WallSolids.closest_point(ctx.walls, segment, here)
		least = minf(least, here.distance_to(nearest))
	assert_gte(least, reach - EPSILON, "outside half thickness plus body radius after two frames")
