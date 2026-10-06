extends GutTest
## KING-03 and D-13 on the real scene: every tower and skirmisher shot shows a projectile that
## flies for exactly the simulation's flight time, the king's passive strike shows a slash, and
## enemies show their wounds. The fixture map has a House and a Tower; its grunts walk past the
## tower. Events the simulation does not produce on its own are emitted by the test.

const FIXTURE := "res://tests/fixtures/fixture_map_one_night.tres"
const TOWER_SPOT: StringName = &"tower_1"
const RICH_GOLD: int = 100
const KING_AWAY := Vector3(60.0, 0.0, 60.0)
## The fixture's west spawn point: standing on it, the king is in reach of every grunt that spawns.
const KING_AT_SPAWN := Vector3(-30.0, 0.0, 0.0)
const FIRST_SHOT_TIMEOUT_S: float = 12.0
## Real-time slack on top of a projectile's flight, and the longest a slash may last.
const FLIGHT_SLACK_S: float = 0.2
const SLASH_LIFETIME_S: float = 0.3
const FLOOD_SHOTS: int = 200
const FLOOD_FLIGHT_TICKS: int = 30
const GRUNT_ID: int = 9001
const SKIRMISHER_ID: int = 9002
const PUPPET_AT := Vector2(5.0, 5.0)
const FLASH_SETTLE_S: float = 0.5
const FILL_EPSILON: float = 0.0001
const COLOR_EPSILON: float = 0.001
## The top of the castle model: the keep box with its turret on it.
const KEEP_TOP: float = BuildingViews.KEEP_SIZE.y + BuildingViews.TURRET_HEIGHT


func after_each() -> void:
	E2eSupport.release_all_actions()


func _fixture_copy() -> MapConfig:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	map.starting_gold = RICH_GOLD
	return map


func _spawn_map(map: MapConfig, king_at: Vector3) -> MapRoot:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	var map_root: MapRoot = scene.instantiate()
	map_root.map_config = map
	map_root.fixed_run_seed = 1
	add_child_autofree(map_root)
	await wait_process_frames(2)
	E2eSupport.teleport_king(map_root, king_at)
	return map_root


func _vfx(map_root: MapRoot) -> ProjectileVfx:
	return map_root.get_node_or_null("ProjectileVfx") as ProjectileVfx


func _start_night(map_root: MapRoot) -> void:
	var result: StringName = map_root.get_context().commands.submit(StartNightIntent.new())
	assert_eq(result, CommandProcessor.OK, "the night starts")


func test_a_tower_shot_shows_a_projectile_that_lives_exactly_its_flight() -> void:
	var map_root: MapRoot = await _spawn_map(_fixture_copy(), KING_AWAY)
	var ctx: RunContext = map_root.get_context()
	var vfx: ProjectileVfx = _vfx(map_root)
	assert_not_null(vfx, "the scene has a ProjectileVfx")
	if vfx == null:
		return
	assert_eq(ctx.commands.submit(BuildIntent.new(TOWER_SPOT)), CommandProcessor.OK, "built")
	var shot: Dictionary = {"flight": -1, "live_at_fire": -1}
	ctx.events.attack_fired.connect(
		func(kind: StringName, _id: int, _tk: StringName, _tid: int, flight: int) -> void:
			if kind == &"building" and shot["flight"] < 0:
				shot["flight"] = flight
				shot["live_at_fire"] = vfx.live_count()
	)
	_start_night(map_root)
	var fired: Callable = func() -> bool: return shot["flight"] >= 0
	assert_true(await E2eSupport.wait_until(self, fired, FIRST_SHOT_TIMEOUT_S), "the tower shot")
	assert_gt(shot["flight"], 0, "an arrow takes time to fly")
	assert_gte(shot["live_at_fire"], 1, "the projectile exists the moment the shot is fired")
	await wait_process_frames(1)
	assert_gte(vfx.live_count(), 1, "and is still in the air a frame later")
	var gone: Callable = func() -> bool: return vfx.live_count() == 0
	var window_s: float = ProjectileVfx.flight_seconds(shot["flight"]) + FLIGHT_SLACK_S
	assert_true(await E2eSupport.wait_until(self, gone, window_s), "freed within flight + 0.2 s")


func test_a_skirmisher_shot_flies_as_a_violet_arrow() -> void:
	var map_root: MapRoot = await _spawn_map(E2eSupport.shipped_prototype_map(), KING_AWAY)
	var ctx: RunContext = map_root.get_context()
	var vfx: ProjectileVfx = _vfx(map_root)
	assert_not_null(vfx, "the scene has a ProjectileVfx")
	if vfx == null:
		return
	var def: EnemyDef = ctx.map.find_enemy(&"ranged")
	var id: int = ctx.night.get_enemies().spawn(def, PUPPET_AT)
	ctx.events.attack_fired.emit(&"enemy", id, &"building", 0, FLOOD_FLIGHT_TICKS)
	assert_eq(vfx.live_count(), 1, "one projectile for one shot")
	var arrows: Array[Node] = vfx.find_children("*", "MeshInstance3D", true, false)
	assert_eq(arrows.size(), 1, "one arrow mesh")
	if arrows.is_empty():
		return
	var material: StandardMaterial3D = (arrows[0] as MeshInstance3D).mesh.material
	assert_almost_eq(material.albedo_color.r, ProjectileVfx.SKIRMISHER_COLOR.r, COLOR_EPSILON, "r")
	assert_almost_eq(material.albedo_color.g, ProjectileVfx.SKIRMISHER_COLOR.g, COLOR_EPSILON, "g")
	assert_almost_eq(material.albedo_color.b, ProjectileVfx.SKIRMISHER_COLOR.b, COLOR_EPSILON, "b")


func test_a_castle_shot_flies_as_a_gold_arrow_from_the_keep() -> void:
	var map_root: MapRoot = await _spawn_map(E2eSupport.shipped_prototype_map(), KING_AWAY)
	var ctx: RunContext = map_root.get_context()
	var vfx: ProjectileVfx = _vfx(map_root)
	assert_not_null(vfx, "the scene has a ProjectileVfx")
	if vfx == null:
		return
	var id: int = ctx.night.get_enemies().spawn(ctx.map.find_enemy(&"grunt"), PUPPET_AT)
	ctx.events.attack_fired.emit(&"castle", 0, &"enemy", id, FLOOD_FLIGHT_TICKS)
	assert_eq(vfx.live_count(), 1, "one projectile for one castle shot")
	var arrows: Array[Node] = vfx.find_children("*", "MeshInstance3D", true, false)
	assert_eq(arrows.size(), 1, "one arrow mesh")
	if arrows.is_empty():
		return
	var arrow: MeshInstance3D = arrows[0] as MeshInstance3D
	var material: StandardMaterial3D = arrow.mesh.material
	assert_almost_eq(material.albedo_color.r, ProjectileVfx.TOWER_COLOR.r, COLOR_EPSILON, "r")
	assert_almost_eq(material.albedo_color.g, ProjectileVfx.TOWER_COLOR.g, COLOR_EPSILON, "g")
	assert_almost_eq(material.albedo_color.b, ProjectileVfx.TOWER_COLOR.b, COLOR_EPSILON, "b")
	var castle: Vector2 = ctx.castle.get_position()
	assert_almost_eq(arrow.global_position.x, castle.x, COLOR_EPSILON, "starts over the castle x")
	assert_almost_eq(arrow.global_position.z, castle.y, COLOR_EPSILON, "starts over the castle z")
	assert_almost_eq(
		arrow.global_position.y, KEEP_TOP, COLOR_EPSILON, "starts at the top of the keep"
	)
	var gone: Callable = func() -> bool: return vfx.live_count() == 0
	var window_s: float = ProjectileVfx.flight_seconds(FLOOD_FLIGHT_TICKS) + FLIGHT_SLACK_S
	assert_true(await E2eSupport.wait_until(self, gone, window_s), "freed after its flight")


func test_a_flood_of_shots_never_passes_the_cap_and_all_of_them_free_themselves() -> void:
	var map_root: MapRoot = await _spawn_map(_fixture_copy(), KING_AWAY)
	var vfx: ProjectileVfx = _vfx(map_root)
	assert_not_null(vfx, "the scene has a ProjectileVfx")
	if vfx == null:
		return
	var events: SimEvents = map_root.get_context().events
	for _i: int in range(FLOOD_SHOTS):
		events.attack_fired.emit(&"building", 0, &"enemy", 1, FLOOD_FLIGHT_TICKS)
		assert_lte(vfx.live_count(), ProjectileVfx.MAX_PROJECTILES, "never above the cap")
	assert_eq(vfx.live_count(), ProjectileVfx.MAX_PROJECTILES, "the cap is reached and held")
	var gone: Callable = func() -> bool: return vfx.live_count() == 0
	var window_s: float = ProjectileVfx.flight_seconds(FLOOD_FLIGHT_TICKS) + FLIGHT_SLACK_S
	assert_true(await E2eSupport.wait_until(self, gone, window_s), "every projectile frees itself")


func test_the_kings_passive_attack_shows_a_slash_that_frees_itself() -> void:
	var map_root: MapRoot = await _spawn_map(_fixture_copy(), KING_AT_SPAWN)
	var ctx: RunContext = map_root.get_context()
	var vfx: ProjectileVfx = _vfx(map_root)
	assert_not_null(vfx, "the scene has a ProjectileVfx")
	if vfx == null:
		return
	var strike: Dictionary = {"slashes": -1}
	ctx.events.attack_fired.connect(
		func(kind: StringName, _id: int, _tk: StringName, _tid: int, flight: int) -> void:
			if kind == &"king" and strike["slashes"] < 0:
				strike["slashes"] = vfx.slash_count()
				assert_eq(flight, 0, "the king's strike lands at once")
	)
	_start_night(map_root)
	var struck: Callable = func() -> bool: return strike["slashes"] >= 0
	assert_true(await E2eSupport.wait_until(self, struck, FIRST_SHOT_TIMEOUT_S), "the king struck")
	assert_gte(strike["slashes"], 1, "a slash shows at the king when he strikes")
	assert_eq(vfx.live_count(), 0, "a slash is not a projectile")
	await wait_seconds(SLASH_LIFETIME_S)
	assert_eq(vfx.slash_count(), 0, "and it is gone within 0.3 s")


func _spawn_puppets() -> Dictionary:
	var map_root: MapRoot = await _spawn_map(E2eSupport.shipped_prototype_map(), KING_AWAY)
	var ctx: RunContext = map_root.get_context()
	var views: EnemyViews = map_root.get_node("EnemyViews")
	ctx.events.enemy_spawned.emit(GRUNT_ID, &"grunt", PUPPET_AT)
	ctx.events.enemy_spawned.emit(SKIRMISHER_ID, &"ranged", PUPPET_AT + Vector2(3.0, 0.0))
	return {"ctx": ctx, "views": views}


func _body(view: Node3D) -> MeshInstance3D:
	return view.get_node_or_null("Body") as MeshInstance3D


func test_a_grunt_and_a_skirmisher_have_their_own_colour_and_silhouette() -> void:
	var setup: Dictionary = await _spawn_puppets()
	var views: EnemyViews = setup["views"]
	var grunt: MeshInstance3D = _body(views.get_view(GRUNT_ID))
	var skirmisher: MeshInstance3D = _body(views.get_view(SKIRMISHER_ID))
	var grunt_mesh: CapsuleMesh = grunt.mesh as CapsuleMesh
	var skirmisher_mesh: CapsuleMesh = skirmisher.mesh as CapsuleMesh
	assert_gt(skirmisher_mesh.height, grunt_mesh.height, "the skirmisher is taller")
	assert_lt(skirmisher_mesh.radius, grunt_mesh.radius, "and narrower")
	var grunt_color: Color = (grunt_mesh.material as StandardMaterial3D).albedo_color
	var skirmisher_color: Color = (skirmisher_mesh.material as StandardMaterial3D).albedo_color
	assert_ne(grunt_color, skirmisher_color, "with a colour of its own")
	assert_almost_eq(skirmisher_color.b, EnemyViews.SKIRMISHER_COLOR.b, COLOR_EPSILON, "violet")


func test_an_enemy_bar_is_hidden_until_it_is_hit_and_the_hit_flashes_the_body() -> void:
	var setup: Dictionary = await _spawn_puppets()
	var ctx: RunContext = setup["ctx"]
	var views: EnemyViews = setup["views"]
	var puppet: Node3D = views.get_view(GRUNT_ID)
	var bars: Array[Node] = puppet.find_children("*", "HealthBar3D", true, false)
	assert_eq(bars.size(), 1, "one bar per puppet")
	if bars.is_empty():
		return
	var bar: HealthBar3D = bars[0] as HealthBar3D
	assert_false(bar.visible, "no bar on an unhurt enemy")
	var material: StandardMaterial3D = (_body(puppet).mesh as CapsuleMesh).material
	assert_almost_eq(
		material.emission_energy_multiplier, EnemyViews.EMISSION_ENERGY, COLOR_EPSILON, "calm"
	)
	var max_hp: int = ctx.map.find_enemy(&"grunt").max_health
	ctx.events.enemy_damaged.emit(GRUNT_ID, 2, max_hp - 2)
	assert_true(bar.visible, "the bar shows once the enemy is hurt")
	assert_almost_eq(bar.get_fill_ratio(), float(max_hp - 2) / float(max_hp), FILL_EPSILON, "fill")
	assert_gt(material.emission_energy_multiplier, EnemyViews.EMISSION_ENERGY, "the hit flashes")
	var other: Array[Node] = views.get_view(SKIRMISHER_ID).find_children(
		"*", "HealthBar3D", true, false
	)
	assert_false((other[0] as HealthBar3D).visible, "an enemy nobody hit shows no bar")
	await wait_seconds(FLASH_SETTLE_S)
	assert_almost_eq(
		material.emission_energy_multiplier, EnemyViews.EMISSION_ENERGY, COLOR_EPSILON, "settled"
	)


func test_a_dying_enemy_leaves_a_puff_that_frees_itself() -> void:
	var setup: Dictionary = await _spawn_puppets()
	var ctx: RunContext = setup["ctx"]
	var views: EnemyViews = setup["views"]
	ctx.events.enemy_died.emit(GRUNT_ID, &"grunt", PUPPET_AT, &"king")
	assert_null(views.get_view(GRUNT_ID), "the puppet is gone")
	assert_eq(views.puff_count(), 1, "a puff marks the spot")
	await wait_seconds(EnemyViews.PUFF_SECONDS + FLIGHT_SLACK_S)
	assert_eq(views.puff_count(), 0, "and it frees itself")
