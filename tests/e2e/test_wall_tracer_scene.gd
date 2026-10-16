extends GutTest
## The wall tracer in the real scene (BLDG-10): a ring bought by day is drawn whole, the night's
## grunts break a segment, the broken piece becomes rubble, an enemy walks through the hole into the
## ring, and the night reaches dawn.

const FIXTURE := "res://tests/fixtures/fixture_map_walls.tres"
const RING: StringName = &"wall_ring"
const TOWER: StringName = &"tower_1"
const SEGMENTS: int = 32
const DRAW_TIMEOUT_S: float = 1.0
const NIGHT_TIMEOUT_S: float = 90.0
## An enemy inside this square on both axes is inside the ring (its walls stand at 12 m).
const INSIDE_LIMIT: float = 11.5


func _spawn_wall_map() -> MapRoot:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	var map_root: MapRoot = scene.instantiate()
	map_root.map_config = load(FIXTURE)
	map_root.fixed_run_seed = 1
	add_child_autofree(map_root)
	await wait_process_frames(2)
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
	var started: int = Time.get_ticks_msec()
	var timeout_ms: int = roundi(NIGHT_TIMEOUT_S * 1000.0)
	var checked_rubble: bool = false
	var saw_inside: bool = false
	while (
		ctx.run_manager.get_phase() != RunManager.RunPhase.DAWN
		and Time.get_ticks_msec() - started < timeout_ms
	):
		await wait_process_frames(1)
		saw_inside = saw_inside or _any_enemy_inside(ctx.night.get_enemies())
		if not broken.is_empty() and not checked_rubble:
			checked_rubble = true
			await wait_process_frames(2)
			assert_gte(views.rubble_count(), 1, "the broken segment is rubble")
			assert_eq(views.piece_count() + views.rubble_count(), SEGMENTS, "no piece is lost")
			assert_false(views.is_piece_drawn(broken[0]), "the broken segment is not a piece")
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "dawn within the timeout")
	assert_gte(broken.size(), 1, "the grunts broke a segment")
	assert_true(checked_rubble, "the rubble was checked")
	assert_true(saw_inside, "an enemy walked through the hole into the ring")
