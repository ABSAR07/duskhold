extends GutTest
## Tracer proof: ride the king to the House plot and hold the action key to build it, driven
## through Input.action_press on the real prototype map scene (headless display driver).

const MAP_SCENE_PATH := "res://presentation/map/prototype_map.tscn"
const RIDE_TIMEOUT_MS: int = 5000


func after_each() -> void:
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)


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

	var arrived: bool = await _ride_until_focused(map_root, spot_id)
	assert_true(arrived, "the king rode into range of the House plot")

	Input.action_press(&"action_build")
	await wait_seconds(float(cost) * ctx.tuning.coin_drip_interval + 0.5)
	Input.action_release(&"action_build")
	await wait_process_frames(2)

	var new_gold: int = start_gold - cost
	assert_eq(ctx.economy.get_gold(), new_gold, "gold dropped by the tier I cost")
	assert_eq(ctx.buildings.current_tier(spot_id), 1, "a tier I House stands on the plot")
	var views: BuildingViews = map_root.get_node("BuildingViews")
	assert_not_null(views.get_view(spot_id), "the House has a world view")
	var gold_label: Label = map_root.get_node("HUD").get_node("%GoldLabel")
	assert_eq(gold_label.text, "Gold: %d" % new_gold, "the HUD shows the new gold")


## Presses the move actions toward the spot and polls until the hold controller focuses it.
func _ride_until_focused(map_root: MapRoot, spot_id: StringName) -> bool:
	var ctx: RunContext = map_root.get_context()
	var king: King = map_root.get_king()
	var target: Vector3 = ctx.buildings.get_spot(spot_id).position
	var toward: Vector3 = target - king.global_position
	var direction: Vector2 = Vector2(toward.x, toward.z).normalized()
	Input.action_press(&"move_left", maxf(-direction.x, 0.0))
	Input.action_press(&"move_right", maxf(direction.x, 0.0))
	Input.action_press(&"move_forward", maxf(-direction.y, 0.0))
	Input.action_press(&"move_back", maxf(direction.y, 0.0))
	var started: int = Time.get_ticks_msec()
	var hold: BuildHoldController = map_root.get_build_hold()
	while hold.get_focused_spot() != spot_id and Time.get_ticks_msec() - started < RIDE_TIMEOUT_MS:
		await wait_process_frames(1)
	for action: StringName in [&"move_left", &"move_right", &"move_forward", &"move_back"]:
		Input.action_release(action)
	return hold.get_focused_spot() == spot_id
