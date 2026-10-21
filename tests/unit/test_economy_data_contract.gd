extends GutTest
## ECON-03, D-12: the economy data contract. The Gold Mine's numbers and its plot are pinned here
## and nowhere else (the behaviour tests set their own on a deep copy). D-12 fixes the step and the
## floor: each paying dawn pays 1 less, down to a floor of 1, never 0. The cost 4, first payout 3
## and health 20 are the planner's starting numbers; plan 05-11 refits cost and first payout with
## the bots, and does it by editing this file in the same commit (a deliberate retune, never a
## silent one). The .tres files store IncomeCurve as its integer, so the enum order is pinned too.

const MINE_PATH := "res://data/buildings/gold_mine.tres"
const MAP_PATH := "res://data/maps/prototype_map.tres"
const CATALOG_PATH := "res://presentation/buildings/building_view_catalog.tres"
const FLAT_BUILDING_PATHS: Array[String] = [
	"res://data/buildings/house.tres",
	"res://data/buildings/tower.tres",
	"res://data/buildings/barracks.tres",
	"res://data/buildings/archery_range.tres",
	"res://data/buildings/wall.tres",
	"res://data/buildings/castle_center.tres",
]
const COST: int = 4
const FIRST_PAYOUT: int = 3
const STEP: int = 1
const FLOOR: int = 1
const MAX_HEALTH: int = 20
const BODY_RADIUS: float = 1.5
const EFFECT_LINE := "Pays 3 gold, then 1 less each dawn, never below 1"


func _mine() -> BuildingDef:
	return load(MINE_PATH)


func test_the_curve_enum_keeps_its_stored_integers() -> void:
	assert_eq(BuildingDef.IncomeCurve.FLAT, 0, "FLAT")
	assert_eq(BuildingDef.IncomeCurve.DECLINING, 1, "DECLINING")
	assert_eq(BuildingDef.IncomeCurve.BOATS, 2, "BOATS")
	assert_eq(BuildingDef.IncomeCurve.AWAKENED, 3, "AWAKENED")


func test_the_gold_mine_has_one_declining_tier() -> void:
	var mine: BuildingDef = _mine()
	assert_eq(mine.id, &"gold_mine", "the id")
	assert_eq(mine.display_name, "Gold Mine", "the name")
	assert_eq(mine.max_tier(), 1, "one tier")
	assert_eq(mine.income_curve, BuildingDef.IncomeCurve.DECLINING, "it declines")
	assert_eq(mine.body_radius, BODY_RADIUS, "its footprint")


func test_the_step_and_floor_are_the_decision_d12_wording() -> void:
	var tier: BuildingTierDef = _mine().tier_def(1)
	assert_eq(tier.income_step, STEP, "1 less at each later dawn it pays")
	assert_eq(tier.income_floor, FLOOR, "down to a floor of 1, never 0")


func test_the_cost_first_payout_and_health_are_pinned_until_the_fit() -> void:
	var tier: BuildingTierDef = _mine().tier_def(1)
	assert_eq(tier.cost, COST, "cost 4")
	assert_eq(tier.dawn_income, FIRST_PAYOUT, "the first payout 3")
	assert_eq(tier.max_health, MAX_HEALTH, "20 health")
	assert_eq(tier.attack_damage, 0, "a Mine does not shoot")
	assert_eq(tier.squad_size, 0, "and fields no squad")


func test_the_label_line_is_generated_from_that_data() -> void:
	assert_eq(_mine().tier_effect_line(1), EFFECT_LINE, "the line the player reads")
	assert_eq(_mine().tier_effect_line(2), "", "no second tier")


func test_the_mine_pays_income_at_tier_one_only() -> void:
	assert_true(_mine().pays_income(1), "tier I pays")
	assert_false(_mine().pays_income(0), "tier 0 is nothing")
	assert_false(_mine().pays_income(2), "and tier II does not exist")


func test_every_other_shipped_building_is_flat() -> void:
	for path: String in FLAT_BUILDING_PATHS:
		var building_def: BuildingDef = load(path)
		assert_eq(building_def.income_curve, BuildingDef.IncomeCurve.FLAT, "%s is FLAT" % path)
		for index: int in range(building_def.max_tier()):
			var tier: BuildingTierDef = building_def.tier_def(index + 1)
			assert_eq(tier.income_step, 0, "%s tier %d has no step" % [path, index + 1])
			assert_eq(tier.income_floor, 0, "%s tier %d has no floor" % [path, index + 1])


func test_the_map_lists_the_gold_mine_and_its_plot() -> void:
	var map: MapConfig = load(MAP_PATH)
	var listed: bool = false
	for building_def: BuildingDef in map.buildings:
		listed = listed or building_def.id == &"gold_mine"
	assert_true(listed, "the building is in the map's list")
	var plot: BuildSpotDef = null
	for spot: BuildSpotDef in map.spots:
		if spot.id == &"gold_mine_1":
			plot = spot
	assert_not_null(plot, "the plot exists")
	if plot != null:
		assert_eq(plot.building_id, &"gold_mine", "it takes the Mine")
		assert_eq(plot.position, Vector3(-30.0, 0.0, 30.0), "at (-30, 0, 30)")


func test_the_catalog_has_a_model_for_the_mine() -> void:
	var catalog: BuildingViewCatalog = load(CATALOG_PATH)
	assert_not_null(catalog.find(&"gold_mine", 1), "tier I has a model")
	assert_null(catalog.find(&"gold_mine", 2), "and there is no tier II")
