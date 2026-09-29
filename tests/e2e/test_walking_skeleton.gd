extends GutTest
## Tracer proof: ride the king to the House plot and hold the action key to build it, driven
## through Input.action_press on the real prototype map scene (headless display driver).

const MAP_SCENE_PATH := "res://presentation/map/prototype_map.tscn"
const RIDE_TIMEOUT_S: float = 5.0


func after_each() -> void:
	E2eSupport.release_all_actions()


func test_main_scene_is_prototype_map() -> void:
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene")
	assert_eq(main_scene, MAP_SCENE_PATH, "project boots straight into the prototype map")


func test_ride_to_house_plot_and_hold_builds_it() -> void:
	var scene: PackedScene = load(MAP_SCENE_PATH)
	var map_root: MapRoot = add_child_autofree(scene.instantiate())
	await wait_process_frames(2)

	var ctx: RunContext = map_root.get_context()
	var spot_id: StringName = ctx.buildings.spot_ids()[0]
	var cost: int = ctx.buildings.next_action_cost(spot_id)
	var start_gold: int = ctx.economy.get_gold()
	assert_gt(cost, 0, "the House has a tier I price")
	assert_true(start_gold >= cost, "starting gold covers the first House")

	var arrived: bool = await E2eSupport.ride_until_focused(self, map_root, spot_id, RIDE_TIMEOUT_S)
	assert_true(arrived, "the king rode into range of the House plot")

	var hold_seconds: float = float(cost) * ctx.tuning.coin_drip_interval + 0.5
	await E2eSupport.hold_action_seconds(self, &"action_build", hold_seconds)
	await wait_process_frames(2)

	var new_gold: int = start_gold - cost
	assert_eq(ctx.economy.get_gold(), new_gold, "gold dropped by the tier I cost")
	assert_eq(ctx.buildings.current_tier(spot_id), 1, "a tier I House stands on the plot")
	var views: BuildingViews = map_root.get_node("BuildingViews")
	assert_not_null(views.get_view(spot_id), "the House has a world view")
	var gold_label: Label = map_root.get_node("HUD").get_node("%GoldLabel")
	assert_eq(gold_label.text, "Gold: %d" % new_gold, "the HUD shows the new gold")


func test_teleported_king_focuses_the_plot() -> void:
	var scene: PackedScene = load(MAP_SCENE_PATH)
	var map_root: MapRoot = add_child_autofree(scene.instantiate())
	await wait_process_frames(2)
	var ctx: RunContext = map_root.get_context()
	var spot_id: StringName = ctx.buildings.spot_ids()[0]
	E2eSupport.teleport_king(map_root, ctx.buildings.get_spot(spot_id).position)
	await wait_process_frames(2)
	assert_eq(map_root.get_build_hold().get_focused_spot(), spot_id, "teleport lands in range")


func test_a_stalled_frame_advances_the_simulation_by_at_most_the_clamp() -> void:
	var scene: PackedScene = load(MAP_SCENE_PATH)
	var map_root: MapRoot = add_child_autofree(scene.instantiate())
	await wait_process_frames(2)
	var ctx: RunContext = map_root.get_context()
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	var before: float = ctx.run_manager.get_elapsed()

	map_root._process(100.0)

	assert_almost_eq(
		ctx.run_manager.get_elapsed() - before, MapRoot.MAX_SIM_STEP, 0.0001, "one stall, one clamp"
	)
	assert_eq(
		ctx.run_manager.get_phase(),
		RunManager.RunPhase.NIGHT,
		"a stalled frame does not end the night"
	)
