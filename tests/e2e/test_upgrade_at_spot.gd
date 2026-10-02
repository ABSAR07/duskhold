extends GutTest
## BLDG-04 on the real scene: hold to build, release, hold again to upgrade. Also checks the
## spawned world nodes: castle landmark, one colour-coded marker per spot, per-tier visuals.

const MAP_SCENE_PATH := "res://presentation/map/prototype_map.tscn"
const RIDE_TIMEOUT_S: float = 5.0
const EXTRA_GOLD: int = 20
const HOLD_SLACK_S: float = 0.5


func after_each() -> void:
	E2eSupport.release_all_actions()


func _spawn_map() -> MapRoot:
	var scene: PackedScene = load(MAP_SCENE_PATH)
	var map_root: MapRoot = add_child_autofree(scene.instantiate())
	await wait_process_frames(2)
	return map_root


func _hold_seconds_for(ctx: RunContext, cost: int) -> float:
	return ctx.tuning.build_hold_seconds(cost) + HOLD_SLACK_S


func _body_mesh(view: Node3D) -> Mesh:
	for child: Node in view.get_children():
		if child is MeshInstance3D:
			return (child as MeshInstance3D).mesh
	return null


func _marker_color(map_root: MapRoot, spot_id: StringName) -> Color:
	var marker: MeshInstance3D = map_root.get_node("BuildingViews/Spot_%s" % spot_id)
	var material: StandardMaterial3D = marker.mesh.material as StandardMaterial3D
	return material.albedo_color


func test_hold_then_hold_again_upgrades_the_house_to_tier_two() -> void:
	var map_root: MapRoot = await _spawn_map()
	var ctx: RunContext = map_root.get_context()
	var spot_id: StringName = ctx.buildings.spot_ids()[0]
	var house: BuildingDef = ctx.buildings.get_building_def_for_spot(spot_id)
	ctx.economy.grant(EXTRA_GOLD)
	var start_gold: int = ctx.economy.get_gold()

	var arrived: bool = await E2eSupport.ride_until_focused(self, map_root, spot_id, RIDE_TIMEOUT_S)
	assert_true(arrived, "the king rode into range of the plot")
	await E2eSupport.hold_action_seconds(
		self, &"action_build", _hold_seconds_for(ctx, house.tier_def(1).cost)
	)
	await wait_process_frames(2)
	assert_eq(ctx.buildings.current_tier(spot_id), 1, "first hold builds tier I")

	await E2eSupport.hold_action_seconds(
		self, &"action_build", _hold_seconds_for(ctx, house.tier_def(2).cost)
	)
	await wait_process_frames(2)

	var views: BuildingViews = map_root.get_node("BuildingViews")
	var view: Node3D = map_root.get_node("BuildingViews/Building_%s" % spot_id)
	assert_eq(view.get_meta(&"tier"), 2, "the view node shows tier II")
	assert_eq(views.get_view(spot_id), view, "get_view returns the tier II view")
	var spent: int = house.tier_def(1).cost + house.tier_def(2).cost
	assert_eq(ctx.economy.get_gold(), start_gold - spent, "gold fell by tier I plus tier II")


func test_scene_has_a_castle_landmark_and_a_marker_for_every_spot() -> void:
	var map_root: MapRoot = await _spawn_map()
	var ctx: RunContext = map_root.get_context()
	var castle: Node3D = map_root.get_node_or_null("BuildingViews/CastleCenter") as Node3D
	assert_not_null(castle, "a CastleCenter landmark exists under BuildingViews")
	if castle != null:
		assert_eq(castle.position, ctx.map.castle_position, "castle stands at castle_position")
	for spot_id: StringName in ctx.buildings.spot_ids():
		var marker: Node = map_root.get_node_or_null("BuildingViews/Spot_%s" % spot_id)
		assert_not_null(marker, "marker Spot_%s exists" % spot_id)
	assert_eq(ctx.buildings.spot_ids().size(), 8, "the prototype map has 8 spots")


func test_markers_are_colour_coded_by_building_type() -> void:
	var map_root: MapRoot = await _spawn_map()
	var ctx: RunContext = map_root.get_context()
	var house_color: Color = Color.BLACK
	var tower_color: Color = Color.BLACK
	var have_house: bool = false
	var have_tower: bool = false
	for spot_id: StringName in ctx.buildings.spot_ids():
		var color: Color = _marker_color(map_root, spot_id)
		if ctx.buildings.get_spot(spot_id).building_id == &"house":
			if have_house:
				assert_eq(color, house_color, "%s matches the other House plots" % spot_id)
			house_color = color
			have_house = true
		else:
			if have_tower:
				assert_eq(color, tower_color, "%s matches the other tower plots" % spot_id)
			tower_color = color
			have_tower = true
	assert_ne(house_color, tower_color, "House and tower plots read differently at a glance")


## Plan 01-07 ships CC0 models in the default catalog, so this test clears the catalog to keep
## covering the primitive fallback (a tier the catalog lacks); test_building_models covers models.
func test_primitive_fallback_tower_is_a_cylinder_and_house_a_box_that_grows_with_tier() -> void:
	var map_root: MapRoot = await _spawn_map()
	var ctx: RunContext = map_root.get_context()
	var views: BuildingViews = map_root.get_node("BuildingViews")
	views.catalog = null
	ctx.economy.grant(EXTRA_GOLD)
	var house_spot: StringName = &"house_1"
	var tower_spot: StringName = &"tower_1"
	ctx.commands.submit(BuildIntent.new(house_spot))
	ctx.commands.submit(BuildIntent.new(tower_spot))

	var tower_view: Node3D = views.get_view(tower_spot)
	assert_not_null(tower_view, "the tower has a view")
	assert_eq(tower_view.get_meta(&"building_id"), &"tower", "tower view records its type")
	assert_true(_body_mesh(tower_view) is CylinderMesh, "a tower is drawn as a cylinder")

	var house_view: Node3D = views.get_view(house_spot)
	assert_eq(house_view.get_meta(&"building_id"), &"house", "House view records its type")
	var tier_one_box: BoxMesh = _body_mesh(house_view) as BoxMesh
	assert_not_null(tier_one_box, "a House is drawn as a box")
	var tier_one_height: float = tier_one_box.size.y
	ctx.commands.submit(BuildIntent.new(house_spot))
	var tier_two_box: BoxMesh = _body_mesh(views.get_view(house_spot)) as BoxMesh
	assert_gt(tier_two_box.size.y, tier_one_height, "a higher tier House is taller")
	# Let the replaced tier I view finish its queue_free before GUT counts orphans.
	await wait_process_frames(1)
