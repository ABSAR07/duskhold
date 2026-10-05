extends GutTest
## The tracer night in the real scene: a seeded one-night map, the king parked in front of the west
## route, and the enemy puppets following the simulation from spawn to death to dawn.

const FIXTURE := "res://tests/fixtures/fixture_map_one_night.tres"
const KING_AT := Vector3(-4.5, 0.0, 0.0)
const NIGHT_TIMEOUT_S: float = 30.0


func _spawn_seeded_map() -> MapRoot:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	var map_root: MapRoot = scene.instantiate()
	map_root.map_config = load(FIXTURE)
	map_root.fixed_run_seed = 1
	add_child_autofree(map_root)
	await wait_process_frames(2)
	return map_root


func test_puppets_follow_the_enemies_through_the_night_to_dawn() -> void:
	var map_root: MapRoot = await _spawn_seeded_map()
	var ctx: RunContext = map_root.get_context()
	var views: EnemyViews = map_root.get_node("EnemyViews")
	assert_eq(map_root.get_run_seed(), 1, "the fixed seed is used")
	E2eSupport.teleport_king(map_root, KING_AT)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night starts")

	var started: int = Time.get_ticks_msec()
	var timeout_ms: int = roundi(NIGHT_TIMEOUT_S * 1000.0)
	var frames_with_enemies: int = 0
	while (
		ctx.run_manager.get_phase() != RunManager.RunPhase.DAWN
		and Time.get_ticks_msec() - started < timeout_ms
	):
		await wait_process_frames(1)
		if ctx.get_enemy_count() > 0:
			frames_with_enemies += 1
			assert_eq(views.view_count(), ctx.get_enemy_count(), "one puppet per live enemy")

	assert_gt(frames_with_enemies, 0, "the enemies were on the field")
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "dawn within the timeout")
	assert_eq(views.view_count(), 0, "no puppet outlives its enemy")
