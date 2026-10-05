extends GutTest
## LOOP-04 / LOOP-05 / D-14 on the real scene: at dawn the rubble of a fallen building rises back
## into its model, and every rebuilt House wears a crossed-out coin while the coins of the Houses
## that stood fly to the gold counter. The coins fade when the day starts. The fixture map has
## one House and one Tower; a second House is added on the east side.

const FIXTURE := "res://tests/fixtures/fixture_map_one_night.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const HOUSE_A: StringName = &"house_1"
const HOUSE_B: StringName = &"house_2"
const TOWER: StringName = &"tower_1"
const HOUSE_B_AT := Vector3(9.0, 0.0, 9.0)
const RICH_GOLD: int = 100
## The king's hold point in front of the grunts' route (see test_night_loop.gd).
const KING_AT := Vector3(-4.5, 0.0, 0.0)
const GRUNTS: int = 2
const GRUNT_GAP_SECONDS: float = 0.5
const GRUNT_SPAWN_AT := Vector3(-12.0, 0.0, 0.0)
const SPAWN_SCATTER: float = 0.3
## Real-time ceiling for the king to kill the grunts and dawn to come.
const DAWN_TIMEOUT_S: float = 20.0
const VIEW_TIMEOUT_S: float = 1.0
const FADE_TIMEOUT_S: float = 1.0
const COINS_TIMEOUT_S: float = 2.0

var _tuning: LoopTuning


func before_each() -> void:
	_tuning = load(TUNING)


func after_each() -> void:
	E2eSupport.release_all_actions()


## The fixture map with a second House plot, a short first night the king can finish at once, and
## gold to build with. A deep copy (DR-12).
func _map() -> MapConfig:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	map.starting_gold = RICH_GOLD
	var spot: BuildSpotDef = BuildSpotDef.new()
	spot.id = HOUSE_B
	spot.position = HOUSE_B_AT
	spot.building_id = &"house"
	map.spots.insert(1, spot)
	var spawn_point: SpawnPointDef = map.spawn_points[0]
	spawn_point.position = GRUNT_SPAWN_AT
	spawn_point.scatter_radius = SPAWN_SCATTER
	var group: SpawnGroupDef = map.nights[0].groups[0]
	group.count = GRUNTS
	group.start_delay_seconds = 0.0
	group.interval_seconds = GRUNT_GAP_SECONDS
	return map


func _spawn() -> MapRoot:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	var map_root: MapRoot = scene.instantiate()
	map_root.map_config = _map()
	map_root.fixed_run_seed = 1
	add_child_autofree(map_root)
	await wait_process_frames(2)
	return map_root


## Builds `spots` to tier I, starts the night, parks the king where he kills the grunts, and takes
## the `fallen` spots down in the night. The scene then runs on its own clock.
func _night(map_root: MapRoot, built: Array[StringName], fallen: Array[StringName]) -> void:
	var ctx: RunContext = map_root.get_context()
	for spot_id: StringName in built:
		assert_eq(ctx.commands.submit(BuildIntent.new(spot_id)), CommandProcessor.OK, "built")
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	E2eSupport.teleport_king(map_root, KING_AT)
	for spot_id: StringName in fallen:
		ctx.buildings.damage_building(spot_id, ctx.buildings.max_health_of(spot_id))
		assert_true(ctx.buildings.is_destroyed(spot_id), "%s fell" % spot_id)


func _hud(map_root: MapRoot) -> Node:
	return map_root.get_node("HUD")


func _marker(map_root: MapRoot) -> DawnNoIncomeMarker:
	return _hud(map_root).get_node_or_null("%DawnNoIncomeMarker") as DawnNoIncomeMarker


func _vfx(map_root: MapRoot) -> DawnPayoutVfx:
	return _hud(map_root).get_node_or_null("%DawnPayoutVfx") as DawnPayoutVfx


func _views(map_root: MapRoot) -> BuildingViews:
	return map_root.get_node("BuildingViews") as BuildingViews


func _is_dawn(ctx: RunContext) -> bool:
	return ctx.run_manager.get_phase() == RunManager.RunPhase.DAWN


func _is_model(views: BuildingViews, spot_id: StringName, tier: int) -> bool:
	var view: Node3D = views.get_view(spot_id)
	return (
		view != null
		and not view is RubbleView
		and not view.has_meta(&"rubble")
		and view.get_meta(&"tier", 0) == tier
	)


func test_a_rebuilt_house_is_marked_while_the_standing_house_sends_its_coins() -> void:
	var map_root: MapRoot = await _spawn()
	var ctx: RunContext = map_root.get_context()
	await _night(map_root, [HOUSE_A, HOUSE_B], [HOUSE_B])
	var marker: DawnNoIncomeMarker = _marker(map_root)
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(marker, "the HUD has a DawnNoIncomeMarker")
	if marker == null or vfx == null:
		return
	assert_eq(marker.marker_count(), 0, "no mark while the night is on")

	var dawn: bool = await E2eSupport.wait_until(self, _is_dawn.bind(ctx), DAWN_TIMEOUT_S)

	assert_true(dawn, "the king finishes the night")
	assert_eq(marker.marker_count(), 1, "one crossed-out coin, over the rebuilt House")
	assert_eq(marker.marked_spots(), [HOUSE_B] as Array[StringName], "it is house_2's")
	var coins: Callable = func() -> bool: return vfx.get_spawned_count(HOUSE_A) > 0
	assert_true(await E2eSupport.wait_until(self, coins, COINS_TIMEOUT_S), "house_1's coins fly")
	assert_eq(vfx.get_spawned_count(HOUSE_B), 0, "no coin leaves the rebuilt House")


func test_the_rubble_is_replaced_by_the_model_at_its_tier_within_a_second_of_dawn() -> void:
	var map_root: MapRoot = await _spawn()
	var ctx: RunContext = map_root.get_context()
	var views: BuildingViews = _views(map_root)
	await _night(map_root, [HOUSE_A, HOUSE_B], [HOUSE_B])
	var rubble: Node3D = views.get_view(HOUSE_B)
	assert_true(rubble is RubbleView, "the fallen House lies in rubble")
	assert_true(await E2eSupport.wait_until(self, _is_dawn.bind(ctx), DAWN_TIMEOUT_S), "dawn")

	var model_up: Callable = _is_model.bind(views, HOUSE_B, 1)
	assert_true(await E2eSupport.wait_until(self, model_up, VIEW_TIMEOUT_S), "the model is back")

	var rebuilt: Node3D = views.get_view(HOUSE_B)
	assert_false(rebuilt is RubbleView, "no longer rubble")
	assert_true(_is_model(views, HOUSE_A, 1), "the House that stood was never swapped")
	var bar: HealthBar3D = views.get_health_bar(HOUSE_B)
	assert_not_null(bar, "the rebuilt House carries a bar again")
	if bar != null:
		assert_false(bar.visible, "hidden: it stands whole")
	await wait_seconds(RubbleView.COLLAPSE_SECONDS + 0.2)
	assert_false(is_instance_valid(rubble) and rubble.is_inside_tree(), "the rubble is gone")


func test_a_hurt_survivor_and_the_castle_show_full_bars_after_dawn() -> void:
	var map_root: MapRoot = await _spawn()
	var ctx: RunContext = map_root.get_context()
	var views: BuildingViews = _views(map_root)
	await _night(map_root, [HOUSE_A, HOUSE_B], [])
	ctx.buildings.damage_building(HOUSE_A, 1)
	ctx.castle.damage(5)
	assert_true(views.get_health_bar(HOUSE_A).visible, "the hurt House shows a bar")
	assert_true(views.get_castle_health_bar().visible, "so does the hurt castle")

	assert_true(await E2eSupport.wait_until(self, _is_dawn.bind(ctx), DAWN_TIMEOUT_S), "dawn")

	assert_false(views.get_health_bar(HOUSE_A).visible, "repaired: the House bar hides again")
	assert_false(views.get_castle_health_bar().visible, "and the castle bar")


func test_the_marks_fade_when_the_day_starts() -> void:
	var map_root: MapRoot = await _spawn()
	var ctx: RunContext = map_root.get_context()
	await _night(map_root, [HOUSE_A, HOUSE_B], [HOUSE_B])
	var marker: DawnNoIncomeMarker = _marker(map_root)
	if marker == null:
		fail_test("the HUD has a DawnNoIncomeMarker")
		return
	assert_true(await E2eSupport.wait_until(self, _is_dawn.bind(ctx), DAWN_TIMEOUT_S), "dawn")
	assert_eq(marker.marker_count(), 1, "marked through dawn")
	var day: Callable = func() -> bool: return ctx.run_manager.get_day_number() > 1
	assert_true(
		await E2eSupport.wait_until(self, day, _tuning.dawn_seconds + 1.0), "the day starts"
	)

	var gone: Callable = func() -> bool: return marker.marker_count() == 0
	assert_true(await E2eSupport.wait_until(self, gone, FADE_TIMEOUT_S), "the mark fades away")


func test_with_every_house_down_no_coin_flies_and_only_houses_get_a_mark() -> void:
	var map_root: MapRoot = await _spawn()
	var ctx: RunContext = map_root.get_context()
	await _night(map_root, [HOUSE_A, HOUSE_B, TOWER], [HOUSE_A, HOUSE_B, TOWER])
	var marker: DawnNoIncomeMarker = _marker(map_root)
	var vfx: DawnPayoutVfx = _vfx(map_root)
	if marker == null or vfx == null:
		fail_test("the HUD has the marker and the payout vfx")
		return

	assert_true(await E2eSupport.wait_until(self, _is_dawn.bind(ctx), DAWN_TIMEOUT_S), "dawn")

	assert_eq(marker.marker_count(), 2, "a mark over each rebuilt House, none over the Tower")
	assert_eq(marker.marked_spots(), [HOUSE_A, HOUSE_B] as Array[StringName], "in map order")
	assert_eq(vfx.live_coin_count(), 0, "no coin in the air")
	assert_eq(vfx.get_spawned_count(HOUSE_A) + vfx.get_spawned_count(HOUSE_B), 0, "none launched")
	assert_true(_is_model(_views(map_root), TOWER, 1), "the Tower is back, with no mark")
