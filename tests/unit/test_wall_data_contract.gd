extends GutTest
## BLDG-10 / D-03: the shipped Wall, pinned on purpose. Three linear tiers (barricade, stone,
## reinforced) that differ only in price and in the health of each segment: costs 2 / 4 / 6 and
## health 3000 / 6000 / 9000 (a linear +3000). A wall pays no income, strikes nothing and fields
## no squad.
## Gap round G-05-2 (owner UAT decision 2026-10-25, plans 05-13 to 05-24): every health and damage
## number is 100 times larger, the owner's hard requirement, so percentages and rounding to the
## nearest unit work as written; the numbers below moved x100 and nothing else did; here: Wall
## health 3000 / 6000 / 9000.

const WALL_PATH := "res://data/buildings/wall.tres"
const MAP_PATH := "res://data/maps/prototype_map.tres"
const COSTS: Array[int] = [2, 4, 6]
const HEALTHS: Array[int] = [3000, 6000, 9000]


func _wall() -> BuildingDef:
	return load(WALL_PATH)


func test_the_wall_has_three_tiers() -> void:
	assert_eq(_wall().id, &"wall", "the building id")
	assert_eq(_wall().display_name, "Wall", "named Wall")
	assert_eq(_wall().max_tier(), 3, "barricade, stone wall, reinforced wall (D-03)")


func test_costs_are_two_four_and_six() -> void:
	for index: int in range(COSTS.size()):
		assert_eq(_wall().tier_def(index + 1).cost, COSTS[index], "tier %d cost" % (index + 1))


func test_health_per_segment_is_three_six_and_nine_thousand() -> void:
	for index: int in range(HEALTHS.size()):
		var health: int = _wall().tier_def(index + 1).max_health
		assert_eq(health, HEALTHS[index], "tier %d health" % (index + 1))


func test_health_rises_in_equal_steps() -> void:
	var wall: BuildingDef = _wall()
	var step: int = wall.tier_def(2).max_health - wall.tier_def(1).max_health
	assert_gt(step, 0, "each tier is stronger")
	assert_eq(wall.tier_def(3).max_health - wall.tier_def(2).max_health, step, "a linear rise")


func test_no_tier_pays_income_attacks_or_fields_a_squad() -> void:
	for tier: BuildingTierDef in _wall().tiers:
		assert_eq(tier.dawn_income, 0, "no income")
		assert_eq(tier.attack_damage, 0, "no attack")
		assert_eq(tier.squad_size, 0, "no squad")
	assert_eq(_wall().unit_id, &"", "and no unit")


func test_the_tier_labels_read_wall_one_two_three() -> void:
	var wall: BuildingDef = _wall()
	assert_eq(wall.tier_label(1), "Wall I", "tier I")
	assert_eq(wall.tier_label(2), "Wall II", "tier II")
	assert_eq(wall.tier_label(3), "Wall III", "tier III")


func test_the_wall_is_listed_by_the_prototype_map() -> void:
	var map: MapConfig = load(MAP_PATH)
	var listed: bool = false
	for building_def: BuildingDef in map.buildings:
		listed = listed or building_def.id == &"wall"
	assert_true(listed, "registered in the map buildings")
