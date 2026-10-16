extends GutTest
## KING-03, D-13 and PLAT-01 on the real scene: every tower and skirmisher shot flies as one
## instance of the arrow batch for exactly the simulation's flight time, tinted by who fired it,
## and the king's passive strike shows a slash. The fixture map has a House and a Tower; its grunts
## walk past the tower. Events the simulation does not produce on its own are emitted by the test.
## Arrows are read from the vfx's CPU mirror because the headless renderer reads a MultiMesh back as
## zeros (RESEARCH F6).

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
## More shots than the ring holds, all in one burst.
const FLOOD_SHOTS: int = ProjectileVfx.MAX_PROJECTILES + 88
const FLOOD_FLIGHT_TICKS: int = 30
const PUPPET_AT := Vector2(5.0, 5.0)
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


func _assert_color(actual: Color, expected: Color, label: String) -> void:
	assert_almost_eq(actual.r, expected.r, COLOR_EPSILON, "%s r" % label)
	assert_almost_eq(actual.g, expected.g, COLOR_EPSILON, "%s g" % label)
	assert_almost_eq(actual.b, expected.b, COLOR_EPSILON, "%s b" % label)


func test_a_tower_shot_shows_an_arrow_that_lives_exactly_its_flight() -> void:
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
	assert_gte(shot["live_at_fire"], 1, "the arrow exists the moment the shot is fired")
	await wait_process_frames(1)
	assert_gte(vfx.live_count(), 1, "and is still in the air a frame later")
	assert_gte(vfx.arrow_count(), 1, "and drawn")
	_assert_color(vfx.arrow_color_at(0), ProjectileVfx.TOWER_COLOR, "a tower arrow is gold")
	var gone: Callable = func() -> bool: return vfx.live_count() == 0
	var window_s: float = ProjectileVfx.flight_seconds(shot["flight"]) + FLIGHT_SLACK_S
	assert_true(await E2eSupport.wait_until(self, gone, window_s), "freed within flight + 0.2 s")
	await wait_process_frames(2)
	assert_eq(vfx.arrow_count(), 0, "and then nothing is drawn")


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
	await wait_process_frames(1)
	assert_eq(vfx.arrow_count(), 1, "one arrow drawn")
	_assert_color(vfx.arrow_color_at(0), ProjectileVfx.SKIRMISHER_COLOR, "a skirmisher arrow")


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
	await wait_process_frames(1)
	assert_eq(vfx.arrow_count(), 1, "one arrow drawn")
	_assert_color(vfx.arrow_color_at(0), ProjectileVfx.TOWER_COLOR, "a castle arrow is gold")
	var castle: Vector2 = ctx.castle.get_position()
	var launch: Vector3 = vfx.arrow_launch_at(0)
	assert_almost_eq(launch.x, castle.x, COLOR_EPSILON, "starts over the castle x")
	assert_almost_eq(launch.z, castle.y, COLOR_EPSILON, "starts over the castle z")
	assert_almost_eq(launch.y, KEEP_TOP, COLOR_EPSILON, "starts at the top of the keep")
	var gone: Callable = func() -> bool: return vfx.live_count() == 0
	var window_s: float = ProjectileVfx.flight_seconds(FLOOD_FLIGHT_TICKS) + FLIGHT_SLACK_S
	assert_true(await E2eSupport.wait_until(self, gone, window_s), "freed after its flight")


func test_a_flood_of_shots_never_passes_the_cap_and_all_of_them_drain() -> void:
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
	await wait_process_frames(1)
	assert_eq(vfx.arrow_count(), ProjectileVfx.MAX_PROJECTILES, "512 arrows drawn, no more")
	var gone: Callable = func() -> bool: return vfx.live_count() == 0
	var window_s: float = ProjectileVfx.flight_seconds(FLOOD_FLIGHT_TICKS) + FLIGHT_SLACK_S
	assert_true(await E2eSupport.wait_until(self, gone, window_s), "every arrow lands and frees")
	await wait_process_frames(2)
	assert_eq(vfx.arrow_count(), 0, "and the batch is empty again")
	events.attack_fired.emit(&"building", 0, &"enemy", 1, FLOOD_FLIGHT_TICKS)
	assert_eq(vfx.live_count(), 1, "a shot after the drain flies again")


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
