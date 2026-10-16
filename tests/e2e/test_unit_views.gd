extends GutTest
## The army in the real scene (PLAT-01): with both military plots built every living unit is one
## instance of its type's batch, footmen and archers each have a batch of their own, a hurt unit
## shows a hurt-only bar that the dawn restore takes away, and an archer shot at night puts an
## arrow in the air. UnitViews holds only batches, never a node per unit. Counts, positions and
## bars are read from the views' CPU mirror because the headless renderer reads a MultiMesh back as
## zeros (RESEARCH F6), and there is no skinned bake headless, so the types wear the capsule here.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const RAISE_TIMEOUT_S: float = 1.0
const ARROW_TIMEOUT_S: float = 30.0
const GROUND_SLACK: float = 0.001
const BAR_EPSILON: float = 0.0001
const HIT: int = 3
## Two unit types and the bar batch: the batches UnitViews owns.
const TYPE_BATCHES: int = 2


func _spawn_squad_map() -> MapRoot:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	var map_root: MapRoot = scene.instantiate()
	map_root.map_config = load(FIXTURE)
	map_root.fixed_run_seed = 1
	add_child_autofree(map_root)
	await wait_process_frames(2)
	return map_root


func _raise_both_squads(map_root: MapRoot, views: UnitViews) -> void:
	var ctx: RunContext = map_root.get_context()
	assert_eq(ctx.commands.submit(BuildIntent.new(&"barracks_1")), CommandProcessor.OK, "barracks")
	assert_eq(ctx.commands.submit(BuildIntent.new(&"archery_1")), CommandProcessor.OK, "range")
	var raised: Callable = func() -> bool: return views.view_count() == 8
	assert_true(await E2eSupport.wait_until(self, raised, RAISE_TIMEOUT_S), "eight units drawn")


func test_every_living_unit_is_one_batch_instance_and_no_node_stands_per_unit() -> void:
	var map_root: MapRoot = await _spawn_squad_map()
	var ctx: RunContext = map_root.get_context()
	var views: UnitViews = map_root.get_node("UnitViews")
	await _raise_both_squads(map_root, views)
	assert_eq(ctx.get_unit_count(), 8, "the simulation fields eight units")
	assert_eq(views.view_count(), ctx.get_unit_count(), "one instance per living unit")
	var footmen: int = 0
	var archers: int = 0
	for unit_id: int in ctx.squads.get_units().ids():
		assert_true(views.has_view(unit_id), "unit %d is drawn" % unit_id)
		if ctx.squads.get_units().def_of(unit_id).id == &"footman":
			footmen += 1
		else:
			archers += 1
	assert_eq(footmen, 4, "four footmen")
	assert_eq(archers, 4, "four archers")
	var batches: int = 0
	for child: Node in views.get_children():
		assert_true(child is CrowdBatch, "%s is a batch, not a unit node" % child.name)
		batches += 1
	assert_eq(batches, TYPE_BATCHES + 1, "a batch per unit type and one for the bars")
	assert_false(views.has_view(1000000), "an unknown unit is not drawn")


func test_each_type_has_its_own_batch_and_headless_wears_the_capsule() -> void:
	var map_root: MapRoot = await _spawn_squad_map()
	var views: UnitViews = map_root.get_node("UnitViews")
	await _raise_both_squads(map_root, views)
	var footmen: CrowdBatch = views.get_node("Units_footman") as CrowdBatch
	var archers: CrowdBatch = views.get_node("Units_archer") as CrowdBatch
	assert_not_null(footmen, "a footman batch")
	assert_not_null(archers, "an archer batch")
	if footmen == null or archers == null:
		return
	assert_eq(footmen.count(), 4, "four footmen in theirs")
	assert_eq(archers.count(), 4, "four archers in theirs")
	assert_eq(views.mesh_source_of(&"footman"), UnitViews.SOURCE_CAPSULE, "no bake headless")
	assert_eq(views.mesh_source_of(&"archer"), UnitViews.SOURCE_CAPSULE, "no bake headless")
	assert_eq(views.mesh_source_of(&"nobody"), &"", "an unknown type has no source")
	assert_gt(footmen.multimesh.mesh.get_surface_count(), 1, "the body and the sword are merged")


func test_a_drawn_unit_stays_within_a_step_of_the_simulation() -> void:
	var map_root: MapRoot = await _spawn_squad_map()
	var ctx: RunContext = map_root.get_context()
	var views: UnitViews = map_root.get_node("UnitViews")
	await _raise_both_squads(map_root, views)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night starts")
	var worst: float = 0.0
	var limit: float = 0.0
	for _frame: int in range(30):
		await wait_process_frames(1)
		for unit_id: int in ctx.squads.get_units().ids():
			if not views.has_view(unit_id):
				continue
			var def: UnitDef = ctx.squads.get_units().def_of(unit_id)
			var sim: Vector2 = ctx.squads.get_units().position_of(unit_id)
			var drawn: Vector3 = views.puppet_position(unit_id)
			worst = maxf(worst, Vector2(drawn.x, drawn.z).distance_to(sim))
			limit = maxf(limit, def.move_speed * SimClock.STEP + GROUND_SLACK)
	assert_lte(worst, limit, "never further than one step of walking from the simulation")


func test_an_archer_shot_at_night_puts_an_arrow_in_the_air() -> void:
	var map_root: MapRoot = await _spawn_squad_map()
	var ctx: RunContext = map_root.get_context()
	var vfx: ProjectileVfx = map_root.get_node("ProjectileVfx")
	assert_eq(ctx.commands.submit(BuildIntent.new(&"archery_1")), CommandProcessor.OK, "range")
	await wait_process_frames(3)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night starts")
	var arrow_seen: Array[bool] = [false]
	var probe: Callable = func() -> bool:
		if ctx.squads.get_units().count() > 0 and vfx.live_count() > 0:
			arrow_seen[0] = true
		return arrow_seen[0]
	assert_true(await E2eSupport.wait_until(self, probe, ARROW_TIMEOUT_S), "an arrow flew")


func test_a_hurt_unit_shows_a_bar_filled_to_its_health_until_the_dawn_restore() -> void:
	var map_root: MapRoot = await _spawn_squad_map()
	var ctx: RunContext = map_root.get_context()
	var views: UnitViews = map_root.get_node("UnitViews")
	assert_eq(ctx.commands.submit(BuildIntent.new(&"barracks_1")), CommandProcessor.OK, "barracks")
	var raised: Callable = func() -> bool: return views.view_count() == 4
	assert_true(await E2eSupport.wait_until(self, raised, RAISE_TIMEOUT_S), "four units drawn")
	var unit_id: int = ctx.squads.unit_ids_of(&"barracks_1")[0]
	assert_eq(views.bar_ratio_of(unit_id), -1.0, "a whole unit shows no bar")
	ctx.squads.damage_unit(unit_id, HIT, &"test")
	var max_health: int = ctx.squads.get_units().def_of(unit_id).max_health
	var expected: float = float(max_health - HIT) / float(max_health)
	assert_almost_eq(views.bar_ratio_of(unit_id), expected, BAR_EPSILON, "the bar is hp / max")
	await wait_process_frames(2)
	assert_eq(views.bar_count(), 1, "one bar is drawn, for the one hurt unit")
	ctx.squads.restore_for_dawn()
	assert_eq(views.bar_ratio_of(unit_id), -1.0, "the dawn restore hides it again")
	await wait_process_frames(2)
	assert_eq(views.bar_count(), 0, "and no bar is drawn")
