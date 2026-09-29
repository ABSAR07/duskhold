extends GutTest
## WR-01: a MapRoot binds only the run-bound nodes in its own subtree, so a second map in the tree
## never re-binds or duplicates the first map's views.

const CASTLE_NAME := "CastleCenter"
const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const RICH_GOLD: int = 50
const HOUSE_SPOT: StringName = &"house_1"


func after_each() -> void:
	E2eSupport.release_all_actions()


func _castle_count(map_root: MapRoot) -> int:
	var views: BuildingViews = map_root.get_node("BuildingViews") as BuildingViews
	var count: int = 0
	for child: Node in views.get_children():
		if child.name == CASTLE_NAME:
			count += 1
	return count


func test_a_second_map_does_not_duplicate_the_first_maps_views() -> void:
	var first: MapRoot = await E2eSupport.spawn_map(self)
	assert_eq(_castle_count(first), 1, "one castle before a second map exists")
	var views: BuildingViews = first.get_node("BuildingViews") as BuildingViews
	var children_before: int = views.get_child_count()

	var second: MapRoot = await E2eSupport.spawn_map(self)
	assert_eq(_castle_count(first), 1, "the first map still has exactly one castle")
	assert_eq(_castle_count(second), 1, "the second map has its own castle")
	assert_eq(views.get_child_count(), children_before, "no extra markers on the first map")


func test_a_second_map_does_not_hear_the_first_maps_phase_changes() -> void:
	var first: MapRoot = await E2eSupport.spawn_map(self)
	var second: MapRoot = await E2eSupport.spawn_map(self)
	var first_gold_before: int = first.get_context().economy.get_gold()
	var second_gold_before: int = second.get_context().economy.get_gold()

	var map: MapConfig = (load(PROTOTYPE_MAP) as MapConfig).duplicate(true)
	map.starting_gold = RICH_GOLD
	var rich: MapRoot = await E2eSupport.spawn_map(self, map)
	assert_eq(rich.get_context().economy.get_gold(), RICH_GOLD, "the third map is rich")
	assert_eq(first.get_context().economy.get_gold(), first_gold_before, "first map unchanged")
	assert_eq(second.get_context().economy.get_gold(), second_gold_before, "second unchanged")
	var hud_label: Label = first.get_node("HUD").find_child("GoldLabel", true, false) as Label
	assert_eq(
		hud_label.text,
		"Gold: %d" % first_gold_before,
		"the first map's HUD still shows the first map's gold, not the rich map's"
	)
