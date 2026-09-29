extends GutTest
## ART-02 / D-01 on the real scene: the king, the House tiers, the tower tiers and the castle
## center render CC0 model wrapper scenes (plan 01-07), and the models are roughly scale-matched.

const MODEL_DIR := "res://presentation/buildings/models/"
const HOUSE_PATHS: Array[String] = [
	MODEL_DIR + "house_t1.tscn", MODEL_DIR + "house_t2.tscn", MODEL_DIR + "house_t3.tscn"
]
const TOWER_PATHS: Array[String] = [MODEL_DIR + "tower_t1.tscn", MODEL_DIR + "tower_t2.tscn"]
const CASTLE_PATH := MODEL_DIR + "castle_center.tscn"
const KING_MODEL_PATH := "res://presentation/king/king_model.tscn"
const EXTRA_GOLD: int = 500
const HOUSE_SPOT: StringName = &"house_1"
const TOWER_SPOT: StringName = &"tower_1"


func _spawn_views() -> Array:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var ctx: RunContext = map_root.get_context()
	ctx.economy.grant(EXTRA_GOLD)
	return [map_root, ctx, map_root.get_node("BuildingViews")]


## Height of every mesh under `node`, merged, in world units (scale of the wrappers included).
func _mesh_size(node: Node3D) -> Vector3:
	var boxes: Array[AABB] = []
	_collect_boxes(node, boxes)
	if boxes.is_empty():
		return Vector3.ZERO
	var merged: AABB = boxes[0]
	for box: AABB in boxes:
		merged = merged.merge(box)
	return merged.size


func _collect_boxes(node: Node, boxes: Array[AABB]) -> void:
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		boxes.append(mesh_instance.global_transform * mesh_instance.get_aabb())
	for child: Node in node.get_children():
		_collect_boxes(child, boxes)


func _build(ctx: RunContext, spot_id: StringName) -> void:
	ctx.commands.submit(BuildIntent.new(spot_id))


func test_every_house_tier_uses_its_wrapper_scene_and_grows() -> void:
	var setup: Array = await _spawn_views()
	var ctx: RunContext = setup[1]
	var views: BuildingViews = setup[2]
	var previous_height: float = 0.0
	for tier: int in range(1, 4):
		_build(ctx, HOUSE_SPOT)
		var view: Node3D = views.get_view(HOUSE_SPOT)
		assert_not_null(view, "tier %d House has a view" % tier)
		assert_eq(
			view.get_meta(&"view_source"), HOUSE_PATHS[tier - 1], "tier %d uses its wrapper" % tier
		)
		var size: Vector3 = _mesh_size(view)
		assert_gt(size.y, 0.0, "tier %d House has real mesh geometry" % tier)
		assert_gt(size.y, previous_height - 0.001, "tier %d is no shorter than the last" % tier)
		previous_height = size.y
		await wait_process_frames(1)


func test_house_tiers_two_and_three_are_bigger_than_tier_one() -> void:
	var setup: Array = await _spawn_views()
	var ctx: RunContext = setup[1]
	var views: BuildingViews = setup[2]
	_build(ctx, HOUSE_SPOT)
	var tier_one: Vector3 = _mesh_size(views.get_view(HOUSE_SPOT))
	_build(ctx, HOUSE_SPOT)
	var tier_two: Vector3 = _mesh_size(views.get_view(HOUSE_SPOT))
	_build(ctx, HOUSE_SPOT)
	var tier_three: Vector3 = _mesh_size(views.get_view(HOUSE_SPOT))
	assert_gt(tier_two.x, tier_one.x, "tier II House is wider than tier I")
	assert_gt(tier_three.y, tier_two.y, "tier III House is taller than tier II")
	await wait_process_frames(1)


func test_tower_tiers_use_their_wrapper_scenes_and_tier_two_is_taller() -> void:
	var setup: Array = await _spawn_views()
	var ctx: RunContext = setup[1]
	var views: BuildingViews = setup[2]
	_build(ctx, TOWER_SPOT)
	var tier_one_view: Node3D = views.get_view(TOWER_SPOT)
	assert_eq(tier_one_view.get_meta(&"view_source"), TOWER_PATHS[0], "tier I tower wrapper")
	var tier_one_height: float = _mesh_size(tier_one_view).y
	assert_gt(tier_one_height, 0.0, "tier I tower has real mesh geometry")
	_build(ctx, TOWER_SPOT)
	var tier_two_view: Node3D = views.get_view(TOWER_SPOT)
	assert_eq(tier_two_view.get_meta(&"view_source"), TOWER_PATHS[1], "tier II tower wrapper")
	assert_gt(_mesh_size(tier_two_view).y, tier_one_height, "tier II tower is taller")
	await wait_process_frames(1)


func test_castle_center_is_the_castle_wrapper_scene() -> void:
	var setup: Array = await _spawn_views()
	var views: BuildingViews = setup[2]
	var castle: Node3D = views.get_node_or_null("CastleCenter") as Node3D
	assert_not_null(castle, "the castle landmark exists")
	assert_eq(castle.get_meta(&"view_source"), CASTLE_PATH, "castle uses the keep wrapper")
	assert_gt(_mesh_size(castle).y, 0.0, "the keep has real mesh geometry")


func test_king_model_pivot_holds_the_composed_king_model() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var pivot: Node3D = map_root.get_king().get_node("Model")
	var king_model: Node3D = pivot.get_node_or_null("KingModel") as Node3D
	assert_not_null(king_model, "the Model pivot contains a KingModel instance")
	assert_eq(king_model.scene_file_path, KING_MODEL_PATH, "it instances king_model.tscn")
	assert_not_null(king_model.get_node_or_null("Horse"), "the king model has a horse")
	assert_not_null(king_model.get_node_or_null("Rider"), "the king model has a rider")


func test_king_reads_as_a_rider_smaller_than_a_house() -> void:
	var setup: Array = await _spawn_views()
	var map_root: MapRoot = setup[0]
	var ctx: RunContext = setup[1]
	var views: BuildingViews = setup[2]
	_build(ctx, HOUSE_SPOT)
	var house_size: Vector3 = _mesh_size(views.get_view(HOUSE_SPOT))
	var king_size: Vector3 = _mesh_size(map_root.get_king().get_node("Model"))
	assert_between(king_size.y, 2.0, 3.0, "rider plus horse is about 2.5 m tall")
	assert_lt(king_size.y, house_size.y, "the king is shorter than a tier I House")
	await wait_process_frames(1)
