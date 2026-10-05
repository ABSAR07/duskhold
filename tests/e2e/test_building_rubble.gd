extends GutTest
## BLDG-07 / D-12 on the real scene: a hurt building shows a health bar, a fallen one collapses and
## leaves rubble on its plot, a building nobody hit shows no bar. The fixture map has one House and
## one Tower; one group of grunts spawns beside the House while the king stands far away.

const FIXTURE := "res://tests/fixtures/fixture_map_one_night.tres"
const HOUSE_SPOT: StringName = &"house_1"
const TOWER_SPOT: StringName = &"tower_1"
const RICH_GOLD: int = 100
const GRUNTS: int = 4
const GRUNT_GAP_SECONDS: float = 0.4
const SPAWN_BESIDE_HOUSE := Vector3(-3.5, 0.0, 0.0)
const SPAWN_SCATTER: float = 0.3
const KING_AWAY := Vector3(60.0, 0.0, 60.0)
## Real-time ceiling for the grunts to reach and hit the House.
const HIT_TIMEOUT_S: float = 8.0
## Real-time slack on top of the collapse time.
const COLLAPSE_SLACK_S: float = 0.5
const FILL_EPSILON: float = 0.0001


func after_each() -> void:
	E2eSupport.release_all_actions()


## The fixture map with night 1 reduced to one group of grunts arriving beside house_1, spaced out
## so the House is hit several times before it falls. A deep copy (DR-12).
func _attack_map() -> MapConfig:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	map.starting_gold = RICH_GOLD
	var house_position: Vector3 = map.spots[0].position
	var spawn_point: SpawnPointDef = map.spawn_points[0]
	spawn_point.position = house_position + SPAWN_BESIDE_HOUSE
	spawn_point.scatter_radius = SPAWN_SCATTER
	var group: SpawnGroupDef = map.nights[0].groups[0]
	group.count = GRUNTS
	group.start_delay_seconds = 0.0
	group.interval_seconds = GRUNT_GAP_SECONDS
	return map


## The scene with both buildings standing and the king out of the grunts' reach.
func _spawn_defended_map() -> MapRoot:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	var map_root: MapRoot = scene.instantiate()
	map_root.map_config = _attack_map()
	map_root.fixed_run_seed = 1
	add_child_autofree(map_root)
	await wait_process_frames(2)
	var ctx: RunContext = map_root.get_context()
	for spot_id: StringName in [HOUSE_SPOT, TOWER_SPOT]:
		assert_eq(ctx.commands.submit(BuildIntent.new(spot_id)), CommandProcessor.OK, "built")
	E2eSupport.teleport_king(map_root, KING_AWAY)
	return map_root


func _views(map_root: MapRoot) -> BuildingViews:
	return map_root.get_node("BuildingViews") as BuildingViews


func _start_night(map_root: MapRoot) -> void:
	var result: StringName = map_root.get_context().commands.submit(StartNightIntent.new())
	assert_eq(result, CommandProcessor.OK, "the night starts")


func test_a_building_nobody_hit_shows_no_bar() -> void:
	var map_root: MapRoot = await _spawn_defended_map()
	var views: BuildingViews = _views(map_root)
	for spot_id: StringName in [HOUSE_SPOT, TOWER_SPOT]:
		var bar: HealthBar3D = views.get_health_bar(spot_id)
		assert_not_null(bar, "%s has a health bar" % spot_id)
		if bar != null:
			assert_false(bar.visible, "%s shows no bar at full health" % spot_id)
			assert_gt(bar.position.y, 0.0, "%s bar floats above the ground" % spot_id)
	assert_null(views.get_health_bar(&"house_2"), "an empty plot has no bar")


func test_the_house_bar_shows_after_the_first_hit_and_the_untouched_tower_stays_clean() -> void:
	var map_root: MapRoot = await _spawn_defended_map()
	var ctx: RunContext = map_root.get_context()
	var views: BuildingViews = _views(map_root)
	var house_bar: HealthBar3D = views.get_health_bar(HOUSE_SPOT)
	var tower_bar: HealthBar3D = views.get_health_bar(TOWER_SPOT)
	if house_bar == null or tower_bar == null:
		fail_test("both buildings should carry a bar")
		return
	_start_night(map_root)
	var max_hp: int = ctx.buildings.max_health_of(HOUSE_SPOT)
	var hit: Callable = func() -> bool: return ctx.buildings.health_of(HOUSE_SPOT) < max_hp
	assert_true(await E2eSupport.wait_until(self, hit, HIT_TIMEOUT_S), "the grunts hit the House")
	assert_true(house_bar.visible, "the bar shows once the House is hurt")
	var hp: int = ctx.buildings.health_of(HOUSE_SPOT)
	assert_almost_eq(house_bar.get_fill_ratio(), float(hp) / float(max_hp), FILL_EPSILON, "fill")
	assert_false(tower_bar.visible, "the Tower nobody hit shows no bar")


func test_a_fallen_house_collapses_into_rubble_and_loses_its_bar() -> void:
	var map_root: MapRoot = await _spawn_defended_map()
	var ctx: RunContext = map_root.get_context()
	var views: BuildingViews = _views(map_root)
	var standing: Node3D = views.get_view(HOUSE_SPOT)
	assert_false(standing.has_meta(&"rubble"), "the standing House is not rubble")
	_start_night(map_root)
	var fallen: Callable = func() -> bool: return ctx.buildings.is_destroyed(HOUSE_SPOT)
	assert_true(await E2eSupport.wait_until(self, fallen, HIT_TIMEOUT_S), "the House falls")
	var rubble_up: Callable = func() -> bool:
		var view: Node3D = views.get_view(HOUSE_SPOT)
		return view != null and view.get_meta(&"rubble", false)
	var window_s: float = RubbleView.COLLAPSE_SECONDS + COLLAPSE_SLACK_S
	assert_true(await E2eSupport.wait_until(self, rubble_up, window_s), "rubble within the window")
	var rubble: Node3D = views.get_view(HOUSE_SPOT)
	assert_true(rubble is RubbleView, "the plot holds a RubbleView")
	assert_null(views.get_health_bar(HOUSE_SPOT), "the bar is gone")
	assert_true(
		rubble.find_children("*", "HealthBar3D", true, false).is_empty(), "no bar on rubble"
	)
	await wait_seconds(window_s)
	assert_false(is_instance_valid(standing), "the collapsed House was freed")
	var slabs: Node3D = (rubble as RubbleView).get_slabs() if rubble is RubbleView else null
	assert_not_null(slabs, "the rubble has its slabs")
	if slabs != null:
		assert_almost_eq(slabs.scale.y, 1.0, FILL_EPSILON, "the slabs finished settling")


func test_upgrading_a_house_still_replaces_its_view_and_gives_the_new_view_a_bar() -> void:
	var map_root: MapRoot = await _spawn_defended_map()
	var ctx: RunContext = map_root.get_context()
	var views: BuildingViews = _views(map_root)
	var old_view: Node3D = views.get_view(HOUSE_SPOT)
	var old_bar: HealthBar3D = views.get_health_bar(HOUSE_SPOT)
	assert_eq(ctx.commands.submit(BuildIntent.new(HOUSE_SPOT)), CommandProcessor.OK, "upgraded")
	await wait_process_frames(1)
	var new_view: Node3D = views.get_view(HOUSE_SPOT)
	assert_ne(new_view, old_view, "the view was replaced")
	assert_eq(new_view.get_meta(&"tier"), 2, "at tier II")
	var new_bar: HealthBar3D = views.get_health_bar(HOUSE_SPOT)
	assert_not_null(new_bar, "the new view carries a bar")
	assert_ne(new_bar, old_bar, "a fresh one")
	if new_bar != null:
		assert_false(new_bar.visible, "hidden: the upgrade stands at full health")
