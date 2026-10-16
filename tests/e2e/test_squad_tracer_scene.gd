extends GutTest
## The Barracks squad in the real scene: a build by day raises four footman puppets within a
## second, the night is fought on the fixed step, and the puppets follow the simulation to dawn.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const SPOT := &"barracks_1"
const RAISE_TIMEOUT_S: float = 1.0
const NIGHT_TIMEOUT_S: float = 60.0


func _spawn_squad_map() -> MapRoot:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	var map_root: MapRoot = scene.instantiate()
	map_root.map_config = load(FIXTURE)
	map_root.fixed_run_seed = 1
	add_child_autofree(map_root)
	await wait_process_frames(2)
	return map_root


func test_a_built_barracks_raises_four_puppets_and_the_squad_fights_the_night() -> void:
	var map_root: MapRoot = await _spawn_squad_map()
	var ctx: RunContext = map_root.get_context()
	var views: UnitViews = map_root.get_node("UnitViews")
	assert_eq(views.view_count(), 0, "no unit before the building")
	assert_eq(ctx.commands.submit(BuildIntent.new(SPOT)), CommandProcessor.OK, "barracks built")
	var raised: Callable = func() -> bool: return views.view_count() == 4
	assert_true(await E2eSupport.wait_until(self, raised, RAISE_TIMEOUT_S), "four puppets by day")
	assert_eq(ctx.get_unit_count(), 4, "the simulation agrees")
	var unit_id: int = ctx.squads.unit_ids_of(SPOT)[0]
	assert_true(views.has_view(unit_id), "each unit is drawn")

	var seen_fight: Array[bool] = [false]
	ctx.events.enemy_died.connect(
		func(_id: int, _def: StringName, _pos: Vector2, killer: StringName) -> void:
			if killer == PendingHits.KIND_UNIT:
				seen_fight[0] = true
	)
	ctx.events.unit_died.connect(
		func(_id: int, _squad: StringName, _pos: Vector2, _killer: StringName) -> void:
			seen_fight[0] = true
	)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night starts")
	var started: int = Time.get_ticks_msec()
	var timeout_ms: int = roundi(NIGHT_TIMEOUT_S * 1000.0)
	while (
		ctx.run_manager.get_phase() != RunManager.RunPhase.DAWN
		and Time.get_ticks_msec() - started < timeout_ms
	):
		await wait_process_frames(1)
		assert_eq(views.view_count(), ctx.get_unit_count(), "one puppet per living unit")
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "dawn within the timeout")
	assert_true(seen_fight[0], "a unit killed an enemy or a unit fell")
	assert_eq(views.view_count(), ctx.get_unit_count(), "puppets match the army at dawn")
