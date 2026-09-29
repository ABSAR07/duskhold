extends GutTest
## The model-swap seam (plan 01-07): catalog lookups and the primitive fallback.

const CATALOG_PATH := "res://presentation/buildings/building_view_catalog.tres"
const STUB_SCENE_PATH := "user://stub_building_view.tscn"


func _scene() -> PackedScene:
	var root: Node3D = Node3D.new()
	root.name = "Stub"
	var scene: PackedScene = PackedScene.new()
	scene.pack(root)
	root.free()
	return scene


func _entry(building_id: StringName, tier: int, scene: PackedScene) -> BuildingViewEntry:
	var entry: BuildingViewEntry = BuildingViewEntry.new()
	entry.building_id = building_id
	entry.tier = tier
	entry.scene = scene
	return entry


func test_find_returns_null_when_absent() -> void:
	var catalog: BuildingViewCatalog = BuildingViewCatalog.new()
	assert_null(catalog.find(&"house", 1))
	assert_null(catalog.find_castle())


func test_find_matches_building_and_tier() -> void:
	var house_1: PackedScene = _scene()
	var house_2: PackedScene = _scene()
	var catalog: BuildingViewCatalog = BuildingViewCatalog.new()
	catalog.entries = [_entry(&"house", 1, house_1), _entry(&"house", 2, house_2)]
	assert_eq(catalog.find(&"house", 1), house_1)
	assert_eq(catalog.find(&"house", 2), house_2)
	assert_null(catalog.find(&"house", 3), "tier without an entry")
	assert_null(catalog.find(&"tower", 1), "building without an entry")


func test_find_castle_returns_the_castle_scene() -> void:
	var castle: PackedScene = _scene()
	var catalog: BuildingViewCatalog = BuildingViewCatalog.new()
	catalog.castle_scene = castle
	assert_eq(catalog.find_castle(), castle)


func test_default_catalog_resource_loads() -> void:
	var catalog: BuildingViewCatalog = load(CATALOG_PATH)
	assert_not_null(catalog)


func test_views_use_a_catalog_scene_and_fall_back_to_primitive() -> void:
	var views: BuildingViews = BuildingViews.new()
	add_child_autofree(views)
	var catalog: BuildingViewCatalog = BuildingViewCatalog.new()
	var stub: PackedScene = _scene()
	# A packed-in-memory scene has no path; give it one so the recorded source is checkable.
	stub.take_over_path(STUB_SCENE_PATH)
	catalog.entries = [_entry(&"house", 1, stub)]
	views.catalog = catalog
	var modelled: Node3D = views._make_visual(&"house", 1)
	assert_eq(modelled.get_meta(&"view_source"), STUB_SCENE_PATH, "the model's path is recorded")
	modelled.free()
	var fallback: Node3D = views._make_visual(&"house", 2)
	assert_eq(fallback.get_meta(&"view_source"), BuildingViews.VIEW_SOURCE_PRIMITIVE)
	fallback.free()
	views.catalog = null
	var no_catalog: Node3D = views._make_visual(&"house", 1)
	assert_eq(no_catalog.get_meta(&"view_source"), BuildingViews.VIEW_SOURCE_PRIMITIVE)
	no_catalog.free()


func test_a_model_scene_with_a_non_3d_root_falls_back_and_is_not_leaked() -> void:
	var views: BuildingViews = BuildingViews.new()
	add_child_autofree(views)
	var plain_root: Node = Node.new()
	var plain_scene: PackedScene = PackedScene.new()
	plain_scene.pack(plain_root)
	plain_root.free()
	var catalog: BuildingViewCatalog = BuildingViewCatalog.new()
	catalog.entries = [_entry(&"house", 1, plain_scene)]
	views.catalog = catalog
	var orphans_before: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))

	var view: Node3D = views._make_visual(&"house", 1)

	assert_eq(view.get_meta(&"view_source"), BuildingViews.VIEW_SOURCE_PRIMITIVE, "primitive")
	var orphans_after: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	# The primitive view itself (a Node3D plus its body) is the only node still alive.
	assert_lte(orphans_after - orphans_before, 2, "the rejected instance was freed, not leaked")
	view.free()
