extends GutTest
## BLDG-08, UI-02 (Claude's discretion, research open question 4): the keep grows with the castle's
## tier. Buying castle tiers II, III and IV with a pick each swaps BuildingViews' keep to the
## catalog scene for that tier (composed from the Castle Kit pieces already in the repository), the
## hurt-only castle bar stays bound to the new keep, the castle plot still has no plot disc, and the
## fallen keep still collapses into rubble. The simulation is not touched by any of this.

const CASTLE: StringName = &"castle_plot"
const CATALOG_PATH := "res://presentation/buildings/building_view_catalog.tres"
const MODEL_DIR := "res://presentation/buildings/models/"
const KEEP_PATHS: Array[String] = [
	MODEL_DIR + "castle_center.tscn",
	MODEL_DIR + "castle_center_t2.tscn",
	MODEL_DIR + "castle_center_t3.tscn",
	MODEL_DIR + "castle_center_t4.tscn",
]
const PICKS: Array[StringName] = [&"masons", &"engineers", &"golden_age"]
const GRANTED_GOLD: int = 60

var _map: MapRoot
var _ctx: RunContext
var _views: BuildingViews


func _setup() -> void:
	_map = await E2eSupport.spawn_map(self)
	_ctx = _map.get_context()
	_views = _map.get_node("BuildingViews") as BuildingViews
	_ctx.economy.grant(GRANTED_GOLD)


func _keep() -> Node3D:
	return _views.get_node_or_null("CastleCenter") as Node3D


func _buy(tier_index: int) -> void:
	assert_eq(
		_ctx.commands.submit(BuildIntent.new(CASTLE, PICKS[tier_index])),
		CommandProcessor.OK,
		"castle tier %d bought" % (tier_index + 2)
	)


func _top_of(node: Node3D) -> float:
	var top: float = 0.0
	var to_local: Transform3D = node.global_transform.affine_inverse()
	for found: Node in node.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = found as MeshInstance3D
		var box: AABB = to_local * mesh_instance.global_transform * mesh_instance.get_aabb()
		top = maxf(top, box.end.y)
	return top


func test_the_catalog_has_a_keep_scene_for_each_castle_tier() -> void:
	var catalog: BuildingViewCatalog = load(CATALOG_PATH)
	for tier: int in range(2, 5):
		var scene: PackedScene = catalog.find(&"castle_center", tier)
		assert_not_null(scene, "castle_center tier %d has a scene" % tier)
		if scene != null:
			assert_eq(scene.resource_path, KEEP_PATHS[tier - 1], "tier %d: its own file" % tier)
	assert_eq(catalog.find_castle().resource_path, KEEP_PATHS[0], "tier I stays the landmark scene")


func test_the_keep_starts_as_the_tier_one_scene() -> void:
	await _setup()
	assert_not_null(_keep(), "the keep stands")
	assert_eq(_keep().get_meta(&"view_source"), KEEP_PATHS[0], "tier I")


func test_buying_each_castle_tier_swaps_the_keep_to_that_tiers_scene() -> void:
	await _setup()
	for index: int in range(PICKS.size()):
		_buy(index)
		await wait_process_frames(1)
		var keep: Node3D = _keep()
		assert_not_null(keep, "a keep stands after tier %d" % (index + 2))
		if keep != null:
			assert_eq(keep.get_meta(&"view_source"), KEEP_PATHS[index + 1], "tier %d" % (index + 2))


func test_there_is_only_ever_one_keep_and_it_stays_where_the_castle_is() -> void:
	await _setup()
	var at: Vector3 = _keep().position
	for index: int in range(PICKS.size()):
		_buy(index)
		await wait_process_frames(2)
	var keeps: int = 0
	for child: Node in _views.get_children():
		if String(child.name).begins_with("CastleCenter"):
			keeps += 1
	assert_eq(keeps, 1, "the old keep is gone")
	assert_eq(_keep().position, at, "the new keep stands on the same spot")


func test_the_keep_grows_taller_with_each_tier() -> void:
	await _setup()
	var heights: Array[float] = [_top_of(_keep())]
	for index: int in range(PICKS.size()):
		_buy(index)
		await wait_process_frames(2)
		heights.append(_top_of(_keep()))
	for index: int in range(1, heights.size()):
		assert_gt(heights[index], heights[index - 1], "tier %d is taller" % (index + 1))


func test_the_castle_bar_stays_bound_to_the_new_keep_and_shows_when_hurt() -> void:
	await _setup()
	for index: int in range(PICKS.size()):
		_buy(index)
		await wait_process_frames(2)
		var bar: HealthBar3D = _views.get_castle_health_bar()
		assert_not_null(bar, "the bar exists at tier %d" % (index + 2))
		assert_true(bar.is_inside_tree(), "and is in the tree")
		assert_eq(bar.get_parent(), _keep(), "as a child of the current keep")
	var bar_now: HealthBar3D = _views.get_castle_health_bar()
	assert_false(bar_now.visible, "hidden at full health")
	_ctx.castle.damage(5)
	assert_true(bar_now.visible, "shown once the castle is hurt")


func test_the_castle_plot_still_has_no_plot_disc() -> void:
	await _setup()
	for index: int in range(PICKS.size()):
		_buy(index)
		await wait_process_frames(1)
	assert_null(_views.get_node_or_null("Spot_castle_plot"), "no disc under the keep")
	assert_null(_views.get_view(CASTLE), "and no separate building view")


func test_the_fallen_keep_of_a_raised_castle_still_collapses_into_rubble() -> void:
	await _setup()
	_buy(0)
	await wait_process_frames(2)
	_ctx.castle.damage(_ctx.castle.get_health())
	await wait_process_frames(2)
	assert_not_null(_views.get_castle_rubble(), "rubble where the tier II keep stood")
	assert_false(_views.get_castle_health_bar().visible, "and the bar is gone")
