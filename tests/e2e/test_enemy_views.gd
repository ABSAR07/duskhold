extends GutTest
## PLAT-01 on the real scene: every live enemy is one instance of its archetype's batch, placed
## at the interpolated simulation position, flashing on a hit; EnemyViews holds only batches, never
## a node per enemy. Counts and colours are read from the views' CPU mirror because the headless
## renderer reads a MultiMesh back as zeros (RESEARCH F6).

const FIXTURE := "res://tests/fixtures/fixture_map_one_night.tres"
const KING_AT := Vector3(-4.5, 0.0, 0.0)
const NIGHT_TIMEOUT_S: float = 30.0
const GROUND_EPSILON: float = 0.001
const COLOR_EPSILON: float = 0.001
const SLACK_S: float = 0.2
const SPAWN_AT := Vector2(5.0, 5.0)
const EXTRA_ENEMIES: int = 40
const ARCHETYPE_BATCHES: int = 3
const BAR_EPSILON: float = 0.0001


func after_each() -> void:
	E2eSupport.release_all_actions()


func _spawn_night_map() -> MapRoot:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	var map_root: MapRoot = scene.instantiate()
	map_root.map_config = load(FIXTURE)
	map_root.fixed_run_seed = 1
	add_child_autofree(map_root)
	await wait_process_frames(2)
	return map_root


func _spawn_day_map() -> MapRoot:
	return await E2eSupport.spawn_map(self, E2eSupport.shipped_prototype_map())


func _batch(views: EnemyViews, batch_name: String) -> CrowdBatch:
	return views.get_node(batch_name) as CrowdBatch


func test_every_live_enemy_is_one_batch_instance_that_follows_the_simulation() -> void:
	var map_root: MapRoot = await _spawn_night_map()
	var ctx: RunContext = map_root.get_context()
	var views: EnemyViews = map_root.get_node("EnemyViews")
	E2eSupport.teleport_king(map_root, KING_AT)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night starts")
	var enemies: EnemySystem = ctx.night.get_enemies()
	var started: int = Time.get_ticks_msec()
	var timeout_ms: int = roundi(NIGHT_TIMEOUT_S * 1000.0)
	var frames_with_enemies: int = 0
	var worst_gap: float = 0.0
	var all_drawn: bool = true
	var all_near: bool = true
	while (
		ctx.run_manager.get_phase() != RunManager.RunPhase.DAWN
		and Time.get_ticks_msec() - started < timeout_ms
	):
		await wait_process_frames(1)
		if ctx.get_enemy_count() == 0:
			continue
		frames_with_enemies += 1
		assert_eq(views.view_count(), ctx.get_enemy_count(), "one instance per live enemy")
		for enemy_id: int in enemies.ids():
			if not views.has_view(enemy_id):
				all_drawn = false
				continue
			var def: EnemyDef = enemies.def_of(enemy_id)
			var drawn: Vector3 = views.puppet_position(enemy_id)
			var truth: Vector2 = enemies.position_of(enemy_id)
			var gap: float = Vector2(drawn.x, drawn.z).distance_to(truth)
			worst_gap = maxf(worst_gap, gap)
			if gap > def.move_speed * SimClock.STEP + GROUND_EPSILON:
				all_near = false
	assert_gt(frames_with_enemies, 0, "the enemies were on the field")
	assert_true(all_drawn, "every live enemy was drawn")
	assert_true(
		all_near, "the drawn position stays within a step of the simulation (%f)" % worst_gap
	)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "dawn within the timeout")
	assert_eq(views.view_count(), 0, "no instance outlives its enemy")


func test_enemy_views_holds_only_its_batches_and_never_a_node_per_enemy() -> void:
	var map_root: MapRoot = await _spawn_day_map()
	var ctx: RunContext = map_root.get_context()
	var views: EnemyViews = map_root.get_node("EnemyViews")
	var enemies: EnemySystem = ctx.night.get_enemies()
	for index: int in range(30):
		enemies.spawn(ctx.map.find_enemy(&"grunt"), SPAWN_AT + Vector2(float(index), 0.0))
	await wait_process_frames(2)
	assert_eq(views.view_count(), 30, "thirty enemies drawn")
	var batches: int = 0
	for child: Node in views.get_children():
		assert_true(child is CrowdBatch, "%s is a batch" % child.name)
		batches += 1
	assert_eq(batches, ARCHETYPE_BATCHES + 2, "three archetypes, the bars and the puffs")


func test_each_archetype_has_its_own_colour_and_silhouette() -> void:
	var map_root: MapRoot = await _spawn_day_map()
	var views: EnemyViews = map_root.get_node("EnemyViews")
	assert_eq(views.archetype_color_of(&"grunt"), EnemyViews.GRUNT_COLOR, "the grunt is red")
	assert_eq(
		views.archetype_color_of(&"ranged"), EnemyViews.SKIRMISHER_COLOR, "the skirmisher is violet"
	)
	assert_eq(views.archetype_color_of(&"brute"), EnemyViews.FALLBACK_COLOR, "anything else")
	var grunts: CrowdBatch = _batch(views, "Grunts")
	var skirmishers: CrowdBatch = _batch(views, "Skirmishers")
	var grunt_mesh: CapsuleMesh = grunts.multimesh.mesh as CapsuleMesh
	var skirmisher_mesh: CapsuleMesh = skirmishers.multimesh.mesh as CapsuleMesh
	assert_gt(skirmisher_mesh.height, grunt_mesh.height, "the skirmisher is taller")
	assert_lt(skirmisher_mesh.radius, grunt_mesh.radius, "and narrower")
	assert_eq(grunt_mesh.radial_segments, EnemyViews.CAPSULE_SIDES, "low-poly sides")
	assert_eq(grunt_mesh.rings, EnemyViews.CAPSULE_RINGS, "low-poly rings")
	var grunt_material: ShaderMaterial = grunts.material_override as ShaderMaterial
	var skirmisher_material: ShaderMaterial = skirmishers.material_override as ShaderMaterial
	var grunt_color: Color = grunt_material.get_shader_parameter(&"albedo")
	var skirmisher_color: Color = skirmisher_material.get_shader_parameter(&"albedo")
	assert_almost_eq(grunt_color.r, EnemyViews.GRUNT_COLOR.r, COLOR_EPSILON, "grunt shader colour")
	assert_almost_eq(skirmisher_color.b, EnemyViews.SKIRMISHER_COLOR.b, COLOR_EPSILON, "violet")
	assert_ne(grunt_color, skirmisher_color, "with a colour of its own")
	var energy: float = grunt_material.get_shader_parameter(&"calm_energy")
	assert_almost_eq(energy, EnemyViews.EMISSION_ENERGY, COLOR_EPSILON, "calm glow")


func test_spawned_enemies_land_in_the_batch_of_their_archetype() -> void:
	var map_root: MapRoot = await _spawn_day_map()
	var ctx: RunContext = map_root.get_context()
	var views: EnemyViews = map_root.get_node("EnemyViews")
	var enemies: EnemySystem = ctx.night.get_enemies()
	var grunt_id: int = enemies.spawn(ctx.map.find_enemy(&"grunt"), SPAWN_AT)
	var ranged_id: int = enemies.spawn(ctx.map.find_enemy(&"ranged"), SPAWN_AT + Vector2(3.0, 0.0))
	await wait_process_frames(2)
	assert_true(views.has_view(grunt_id), "the grunt is drawn")
	assert_true(views.has_view(ranged_id), "the skirmisher is drawn")
	assert_eq(_batch(views, "Grunts").count(), 1, "one grunt instance")
	assert_eq(_batch(views, "Skirmishers").count(), 1, "one skirmisher instance")
	assert_eq(_batch(views, "Others").count(), 0, "nothing in the fallback batch")
	var drawn: Vector3 = views.puppet_position(grunt_id)
	assert_almost_eq(drawn.x, SPAWN_AT.x, GROUND_EPSILON, "drawn where it spawned, x")
	assert_almost_eq(drawn.z, SPAWN_AT.y, GROUND_EPSILON, "and z")
	assert_eq(drawn.y, 0.0, "on the ground")
	assert_false(views.has_view(ranged_id + 1000), "an unknown id is not drawn")
	assert_eq(views.puppet_position(ranged_id + 1000), Vector3.ZERO, "and sits nowhere")


func test_a_hit_flashes_the_instance_and_settles() -> void:
	var map_root: MapRoot = await _spawn_day_map()
	var ctx: RunContext = map_root.get_context()
	var views: EnemyViews = map_root.get_node("EnemyViews")
	var enemies: EnemySystem = ctx.night.get_enemies()
	var def: EnemyDef = ctx.map.find_enemy(&"grunt")
	var hit_id: int = enemies.spawn(def, SPAWN_AT)
	var other_id: int = enemies.spawn(def, SPAWN_AT + Vector2(3.0, 0.0))
	await wait_process_frames(2)
	assert_eq(views.flash_of(hit_id), 0.0, "calm before the hit")
	ctx.events.enemy_damaged.emit(hit_id, 2, def.max_health - 2)
	assert_eq(views.flash_of(hit_id), 1.0, "the hit flashes at full strength")
	assert_eq(views.flash_of(other_id), 0.0, "an enemy nobody hit stays calm")
	await wait_process_frames(2)
	var batch: CrowdBatch = _batch(views, "Grunts")
	assert_gt(batch.custom_of(0).r, 0.0, "the instance carries the flash in its custom data")
	assert_eq(batch.custom_of(1).r, 0.0, "the other instance does not")
	await wait_seconds(EnemyViews.FLASH_SECONDS + SLACK_S)
	assert_eq(views.flash_of(hit_id), 0.0, "and it settles")
	assert_eq(batch.custom_of(0).r, 0.0, "back in the custom data too")


func test_more_enemies_than_the_cap_are_simulated_but_not_drawn() -> void:
	var map_root: MapRoot = await _spawn_day_map()
	var ctx: RunContext = map_root.get_context()
	var views: EnemyViews = map_root.get_node("EnemyViews")
	var enemies: EnemySystem = ctx.night.get_enemies()
	var total: int = EnemyViews.MAX_VIEWS + EXTRA_ENEMIES
	var def: EnemyDef = ctx.map.find_enemy(&"grunt")
	for index: int in range(total):
		enemies.spawn(
			def, SPAWN_AT + Vector2(float(index % 50), float(floori(float(index) / 50.0)))
		)
	await wait_process_frames(2)
	assert_eq(enemies.count(), total, "the simulation keeps every enemy")
	assert_eq(views.view_count(), EnemyViews.MAX_VIEWS, "the views stop at the cap")
	var shown: int = 0
	for child: Node in views.get_children():
		var batch: CrowdBatch = child as CrowdBatch
		if batch == null:
			continue
		assert_lte(batch.multimesh.visible_instance_count, batch.capacity(), "within capacity")
		shown += batch.multimesh.visible_instance_count
	assert_eq(shown, EnemyViews.MAX_VIEWS, "no more than the cap is shown")
	assert_true(views.has_view(1), "the oldest enemies are the ones drawn")
	assert_false(views.has_view(total), "the newest is the one left out")


func test_with_no_enemy_alive_every_batch_commits_nothing() -> void:
	var map_root: MapRoot = await _spawn_day_map()
	var views: EnemyViews = map_root.get_node("EnemyViews")
	await wait_process_frames(2)
	assert_eq(views.view_count(), 0, "nothing drawn")
	for child: Node in views.get_children():
		var batch: CrowdBatch = child as CrowdBatch
		if batch == null:
			continue
		assert_eq(batch.count(), 0, "%s holds nothing" % batch.name)
		assert_eq(batch.multimesh.visible_instance_count, 0, "%s shows nothing" % batch.name)


func test_a_killed_enemy_leaves_the_batch() -> void:
	var map_root: MapRoot = await _spawn_day_map()
	var ctx: RunContext = map_root.get_context()
	var views: EnemyViews = map_root.get_node("EnemyViews")
	var enemies: EnemySystem = ctx.night.get_enemies()
	var def: EnemyDef = ctx.map.find_enemy(&"grunt")
	var doomed: int = enemies.spawn(def, SPAWN_AT)
	var survivor: int = enemies.spawn(def, SPAWN_AT + Vector2(3.0, 0.0))
	await wait_process_frames(2)
	assert_eq(views.view_count(), 2, "both drawn")
	enemies.damage(doomed, def.max_health, &"king")
	await wait_process_frames(2)
	assert_false(views.has_view(doomed), "the dead enemy is no longer drawn")
	assert_true(views.has_view(survivor), "the other one is")
	assert_eq(views.view_count(), 1, "one instance left")


func test_a_hurt_enemy_shows_a_bar_filled_to_its_health_and_a_full_one_shows_none() -> void:
	var map_root: MapRoot = await _spawn_day_map()
	var ctx: RunContext = map_root.get_context()
	var views: EnemyViews = map_root.get_node("EnemyViews")
	var enemies: EnemySystem = ctx.night.get_enemies()
	var def: EnemyDef = ctx.map.find_enemy(&"grunt")
	var hurt_id: int = enemies.spawn(def, SPAWN_AT)
	var full_id: int = enemies.spawn(def, SPAWN_AT + Vector2(3.0, 0.0))
	await wait_process_frames(2)
	assert_eq(views.bar_count(), 0, "no bar on a field of unhurt enemies")
	assert_eq(views.bar_ratio_of(hurt_id), -1.0, "an unhurt enemy has no bar")
	ctx.events.enemy_damaged.emit(hurt_id, 2, def.max_health - 2)
	await wait_process_frames(2)
	var expected: float = float(def.max_health - 2) / float(def.max_health)
	assert_almost_eq(views.bar_ratio_of(hurt_id), expected, BAR_EPSILON, "filled to hp / max")
	assert_eq(views.bar_ratio_of(full_id), -1.0, "an enemy nobody hit shows no bar")
	assert_eq(views.bar_count(), 1, "one bar for the one hurt enemy")
	var bars: CrowdBatch = _batch(views, "Bars")
	var ground: Vector3 = views.puppet_position(hurt_id)
	var above: float = EnemyViews.PUPPET_HEIGHT + EnemyViews.BAR_CLEARANCE
	assert_almost_eq(bars.origin_of(0).x, ground.x, BAR_EPSILON, "over the enemy, x")
	assert_almost_eq(bars.origin_of(0).z, ground.z, BAR_EPSILON, "and z")
	assert_almost_eq(bars.origin_of(0).y, above, BAR_EPSILON, "above its head")
	assert_eq(bars.multimesh.visible_instance_count, 1, "and one bar is shown")


func test_the_bar_goes_with_a_killed_enemy() -> void:
	var map_root: MapRoot = await _spawn_day_map()
	var ctx: RunContext = map_root.get_context()
	var views: EnemyViews = map_root.get_node("EnemyViews")
	var enemies: EnemySystem = ctx.night.get_enemies()
	var def: EnemyDef = ctx.map.find_enemy(&"grunt")
	var id: int = enemies.spawn(def, SPAWN_AT)
	await wait_process_frames(2)
	ctx.events.enemy_damaged.emit(id, 1, 1)
	await wait_process_frames(2)
	assert_eq(views.bar_count(), 1, "the hurt enemy has a bar")
	enemies.damage(id, def.max_health, &"king")
	await wait_process_frames(2)
	assert_eq(views.bar_count(), 0, "a dead enemy shows no bar")
	assert_eq(views.bar_ratio_of(id), -1.0, "and has no ratio")


func test_a_dying_enemy_leaves_a_puff_that_fades_within_its_lifetime() -> void:
	var map_root: MapRoot = await _spawn_day_map()
	var ctx: RunContext = map_root.get_context()
	var views: EnemyViews = map_root.get_node("EnemyViews")
	var enemies: EnemySystem = ctx.night.get_enemies()
	var def: EnemyDef = ctx.map.find_enemy(&"grunt")
	var id: int = enemies.spawn(def, SPAWN_AT)
	await wait_process_frames(2)
	assert_eq(views.puff_count(), 0, "no puff yet")
	enemies.damage(id, def.max_health, &"king")
	assert_eq(views.puff_count(), 1, "a puff marks the spot")
	await wait_process_frames(2)
	assert_eq(views.puff_count(), 1, "and it is still there a frame later")
	await wait_seconds(EnemyViews.PUFF_SECONDS + SLACK_S)
	assert_eq(views.puff_count(), 0, "and it is gone within its lifetime")


func test_a_flood_of_deaths_in_one_frame_holds_the_puffs_at_the_cap() -> void:
	var map_root: MapRoot = await _spawn_day_map()
	var ctx: RunContext = map_root.get_context()
	var views: EnemyViews = map_root.get_node("EnemyViews")
	for index: int in range(DeathPuffBatch.MAX_PUFFS + 30):
		ctx.events.enemy_died.emit(7000 + index, &"grunt", SPAWN_AT, &"king")
	assert_eq(views.puff_count(), DeathPuffBatch.MAX_PUFFS, "128 puffs and no more")
	await wait_process_frames(2)
	assert_eq(views.puff_count(), DeathPuffBatch.MAX_PUFFS, "still held a frame later")
