extends GutTest
## ECON-03 to ECON-06, D-11 to D-13: the economy data contract. The Gold Mine's, the Mill's, the
## Field's, the Fishing Harbor's and the Shrine's numbers, their plots and the pond are pinned
## here and nowhere else (the behaviour tests set their own on a deep copy). D-12 fixes the step and
## the floor: each paying dawn pays 1 less, down to a floor of 1, never 0. The Mine's cost 4, first
## payout 3 and health 20, the Mill's, the Field's, the Harbor's and the Shrine's numbers are the
## planner's starting numbers; plan 05-11 refits them with the bots, and does it by
## editing this file in the same commit (a deliberate retune, never a silent one). Plan 05-11
## measured them (05-BALANCE-REPORT.md) and the order lever of the D-15 ladder met the bar, so it
## fitted none of them: every number below is still the planner's starting number. The .tres
## files store IncomeCurve as its integer, so the enum order is pinned too.

const MINE_PATH := "res://data/buildings/gold_mine.tres"
const MILL_PATH := "res://data/buildings/mill.tres"
const FIELD_PATH := "res://data/buildings/field.tres"
const HARBOR_PATH := "res://data/buildings/fishing_harbor.tres"
const SHRINE_PATH := "res://data/buildings/shrine.tres"
const MAP_PATH := "res://data/maps/prototype_map.tres"
const CATALOG_PATH := "res://presentation/buildings/building_view_catalog.tres"
const FLAT_BUILDING_PATHS: Array[String] = [
	"res://data/buildings/house.tres",
	"res://data/buildings/tower.tres",
	"res://data/buildings/barracks.tres",
	"res://data/buildings/archery_range.tres",
	"res://data/buildings/wall.tres",
	"res://data/buildings/castle_center.tres",
	"res://data/buildings/mill.tres",
	"res://data/buildings/field.tres",
]
const COST: int = 4
const FIRST_PAYOUT: int = 3
const STEP: int = 1
const FLOOR: int = 1
const MAX_HEALTH: int = 20
const BODY_RADIUS: float = 1.5
const EFFECT_LINE := "Pays 3 gold, then 1 less each dawn, never below 1"
## The Mill (D-12, D-13): three FLAT tiers; the last needs the castle at tier II (D-03), the first
## shipped top tier to be gated.
const MILL_COSTS: Array[int] = [3, 4, 6]
const MILL_INCOMES: Array[int] = [1, 2, 3]
const MILL_HEALTHS: Array[int] = [15, 20, 25]
const MILL_CASTLE_TIERS: Array[int] = [0, 0, 2]
const MILL_BODY_RADIUS: float = 1.5
## The Field (D-10): one FLAT tier. The cost is 2, not 1, because the cheapest shipped hold must
## last at least 0.5 s (UAT G-01-4, test_loop_tuning_contract) and a 1 gold hold lasts 0.25 s.
const FIELD_COST: int = 2
const FIELD_INCOME: int = 1
const FIELD_HEALTH: int = 8
const FIELD_BODY_RADIUS: float = 1.2
const FIELD_PLOTS: Array[StringName] = [&"field_1", &"field_2", &"field_3"]
## The Fishing Harbor (D-12, ECON-05): two BOATS tiers; the second needs castle tier II (D-03).
const HARBOR_COSTS: Array[int] = [3, 6]
const HARBOR_CAPS: Array[int] = [3, 5]
const HARBOR_BOAT_GOLD: Array[int] = [1, 1]
const HARBOR_HEALTHS: Array[int] = [18, 24]
const HARBOR_CASTLE_TIERS: Array[int] = [0, 2]
const HARBOR_BODY_RADIUS: float = 1.5
## The visual-only pond (D-11): at the south edge of the built-up area, the Harbor on its shore.
const POND_CENTER := Vector2(0.0, 30.0)
const POND_RADIUS: float = 8.0

## The Shrine (plan 05-09), [ASSUMED] starting numbers that plan 05-11 fits with the bots.
const SHRINE_COST: int = 3
const SHRINE_INCOME: int = 1
const SHRINE_DAMAGE: int = 3
const SHRINE_REACH: float = 9.0
const SHRINE_INTERVAL: float = 1.1
const SHRINE_BOLT_SPEED: float = 20.0
const SHRINE_HEALTH: int = 30
const SHRINE_WAKE_RADIUS: float = 18.0
const SHRINE_WAKE_THRESHOLD: int = 100
const SHRINE_SYNERGY: int = 20
const SHRINE_BODY_RADIUS: float = 1.2


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


func test_the_mill_has_three_flat_tiers_that_pay_per_tier() -> void:
	var mill: BuildingDef = load(MILL_PATH)
	assert_eq(mill.id, &"mill", "the id")
	assert_eq(mill.display_name, "Mill", "the name")
	assert_eq(mill.max_tier(), 3, "three tiers")
	assert_eq(mill.income_curve, BuildingDef.IncomeCurve.FLAT, "FLAT")
	assert_eq(mill.body_radius, MILL_BODY_RADIUS, "its footprint")
	for index: int in range(MILL_COSTS.size()):
		var tier: BuildingTierDef = mill.tier_def(index + 1)
		assert_eq(tier.cost, MILL_COSTS[index], "tier %d cost" % (index + 1))
		assert_eq(tier.dawn_income, MILL_INCOMES[index], "tier %d payout" % (index + 1))
		assert_eq(tier.max_health, MILL_HEALTHS[index], "tier %d health" % (index + 1))
		assert_eq(tier.requires_castle_tier, MILL_CASTLE_TIERS[index], "tier %d gate" % (index + 1))
		assert_eq(tier.attack_damage, 0, "a Mill does not shoot")
		assert_true(mill.pays_income(index + 1), "tier %d pays" % (index + 1))


func test_only_the_top_mill_tier_needs_the_castle() -> void:
	var mill: BuildingDef = load(MILL_PATH)
	assert_eq(
		mill.tier_def(mill.max_tier()).requires_castle_tier, 2, "the last tier needs castle II"
	)
	for index: int in range(1, mill.max_tier()):
		assert_eq(mill.tier_def(index).requires_castle_tier, 0, "tier %d is always buyable" % index)


func test_the_field_has_one_flat_tier_paying_one_gold() -> void:
	var field: BuildingDef = load(FIELD_PATH)
	assert_eq(field.id, &"field", "the id")
	assert_eq(field.display_name, "Field", "the name")
	assert_eq(field.max_tier(), 1, "one tier")
	assert_eq(field.income_curve, BuildingDef.IncomeCurve.FLAT, "FLAT")
	assert_eq(field.body_radius, FIELD_BODY_RADIUS, "its footprint")
	var tier: BuildingTierDef = field.tier_def(1)
	assert_eq(tier.cost, FIELD_COST, "cost")
	assert_eq(tier.dawn_income, FIELD_INCOME, "pays a flat gold")
	assert_eq(tier.max_health, FIELD_HEALTH, "health")
	assert_eq(tier.requires_castle_tier, 0, "a Field needs no castle tier, only the Mill")


func test_the_map_lists_the_mill_the_fields_and_their_plots() -> void:
	var map: MapConfig = load(MAP_PATH)
	var listed: Array[StringName] = []
	for building_def: BuildingDef in map.buildings:
		listed.append(building_def.id)
	assert_true(listed.has(&"mill") and listed.has(&"field"), "both are in the map's list")
	for field_id: StringName in FIELD_PLOTS:
		var plot: BuildSpotDef = null
		for spot: BuildSpotDef in map.spots:
			if spot.id == field_id:
				plot = spot
		assert_not_null(plot, "%s exists" % field_id)
		if plot != null:
			assert_eq(plot.building_id, &"field", "%s takes the Field" % field_id)
			assert_eq(plot.requires_spot, &"mill_1", "%s needs the Mill's plot" % field_id)
			assert_eq(plot.requires_spot_tier, 1, "at tier 1 or more")
	for spot: BuildSpotDef in map.spots:
		if spot.id == &"mill_1":
			assert_eq(spot.building_id, &"mill", "mill_1 takes the Mill")
			assert_eq(spot.requires_spot, &"", "and is never locked itself")


func test_the_catalog_has_models_for_the_mill_tiers_and_the_field() -> void:
	var catalog: BuildingViewCatalog = load(CATALOG_PATH)
	for tier: int in range(1, 4):
		assert_not_null(catalog.find(&"mill", tier), "Mill tier %d has a model" % tier)
	assert_null(catalog.find(&"mill", 4), "and there is no Mill tier IV")
	assert_not_null(catalog.find(&"field", 1), "the Field has a model")
	assert_null(catalog.find(&"field", 2), "and no second tier")


func test_the_fishing_harbor_has_two_boats_tiers_gated_at_castle_two() -> void:
	var harbor: BuildingDef = load(HARBOR_PATH)
	assert_eq(harbor.id, &"fishing_harbor", "the id")
	assert_eq(harbor.display_name, "Fishing Harbor", "the name")
	assert_eq(harbor.max_tier(), 2, "two tiers")
	assert_eq(harbor.income_curve, BuildingDef.IncomeCurve.BOATS, "BOATS")
	assert_eq(harbor.body_radius, HARBOR_BODY_RADIUS, "its footprint")
	for index: int in range(HARBOR_COSTS.size()):
		var tier: BuildingTierDef = harbor.tier_def(index + 1)
		assert_eq(tier.cost, HARBOR_COSTS[index], "tier %d cost" % (index + 1))
		assert_eq(tier.boat_cap, HARBOR_CAPS[index], "tier %d boat cap" % (index + 1))
		assert_eq(tier.boat_income, HARBOR_BOAT_GOLD[index], "tier %d gold per boat" % (index + 1))
		assert_eq(tier.max_health, HARBOR_HEALTHS[index], "tier %d health" % (index + 1))
		assert_eq(
			tier.requires_castle_tier, HARBOR_CASTLE_TIERS[index], "tier %d gate" % (index + 1)
		)
		assert_eq(tier.dawn_income, 0, "a Harbor pays through its boats only")
		assert_eq(tier.income_step, 0, "and has no decline")
		assert_true(harbor.pays_income(index + 1), "tier %d pays" % (index + 1))


func test_the_map_lists_the_harbor_its_plot_and_the_pond() -> void:
	var map: MapConfig = load(MAP_PATH)
	var listed: bool = false
	for building_def: BuildingDef in map.buildings:
		listed = listed or building_def.id == &"fishing_harbor"
	assert_true(listed, "the building is in the map's list")
	var plot: BuildSpotDef = null
	for spot: BuildSpotDef in map.spots:
		if spot.id == &"harbor_1":
			plot = spot
	assert_not_null(plot, "the plot exists")
	if plot != null:
		assert_eq(plot.building_id, &"fishing_harbor", "it takes the Harbor")
		assert_eq(plot.position, Vector3(0.0, 0.0, 20.5), "at (0, 0, 20.5)")
		assert_eq(plot.requires_spot, &"", "and is never locked")
	assert_eq(map.pond_center, POND_CENTER, "the pond is centred at (0, 30)")
	assert_eq(map.pond_radius, POND_RADIUS, "with radius 8")


func test_the_catalog_has_models_for_both_harbor_tiers() -> void:
	var catalog: BuildingViewCatalog = load(CATALOG_PATH)
	assert_not_null(catalog.find(&"fishing_harbor", 1), "tier I has a model")
	assert_not_null(catalog.find(&"fishing_harbor", 2), "tier II has a model")
	assert_null(catalog.find(&"fishing_harbor", 3), "and there is no tier III")


func test_the_shrine_has_one_awakened_tier_with_the_pinned_numbers() -> void:
	var shrine: BuildingDef = load(SHRINE_PATH)
	assert_eq(shrine.id, &"shrine", "the id")
	assert_eq(shrine.display_name, "Shrine", "the name")
	assert_eq(shrine.max_tier(), 1, "one tier")
	assert_eq(shrine.income_curve, BuildingDef.IncomeCurve.AWAKENED, "AWAKENED")
	assert_eq(shrine.body_radius, SHRINE_BODY_RADIUS, "its footprint")
	assert_eq(shrine.damage_stat, &"shrine.damage", "its damage stat")
	assert_eq(shrine.range_stat, &"shrine.range", "its range stat")
	var tier: BuildingTierDef = shrine.tier_def(1)
	assert_eq(tier.cost, SHRINE_COST, "cost")
	assert_eq(tier.dawn_income, SHRINE_INCOME, "pays once awake")
	assert_eq(tier.attack_damage, SHRINE_DAMAGE, "attack damage")
	assert_eq(tier.attack_range, SHRINE_REACH, "attack range")
	assert_eq(tier.attack_interval, SHRINE_INTERVAL, "attack interval")
	assert_eq(tier.projectile_speed, SHRINE_BOLT_SPEED, "bolt speed")
	assert_eq(tier.max_health, SHRINE_HEALTH, "health")
	assert_eq(tier.wake_radius, SHRINE_WAKE_RADIUS, "wake radius")
	assert_eq(tier.wake_threshold_hp, SHRINE_WAKE_THRESHOLD, "wake threshold")
	assert_eq(tier.synergy_percent, SHRINE_SYNERGY, "synergy")
	assert_eq(tier.requires_castle_tier, 0, "never gated")
	assert_true(shrine.pays_income(1), "the crossed coin applies")


func test_the_map_lists_the_shrine_its_two_plots_and_the_catalog_has_its_model() -> void:
	var map: MapConfig = load(MAP_PATH)
	var listed: bool = false
	for building_def: BuildingDef in map.buildings:
		listed = listed or building_def.id == &"shrine"
	assert_true(listed, "the building is in the map's list")
	for plot_id: StringName in [&"shrine_west", &"shrine_east"]:
		var found: bool = false
		for spot: BuildSpotDef in map.spots:
			if spot.id == plot_id:
				found = true
				assert_eq(spot.building_id, &"shrine", "%s takes the Shrine" % plot_id)
		assert_true(found, "%s is on the map" % plot_id)
	var catalog: BuildingViewCatalog = load(CATALOG_PATH)
	assert_not_null(catalog.find(&"shrine", 1), "tier I has a model")
	assert_null(catalog.find(&"shrine", 2), "and there is no tier II")


func test_no_other_building_has_wake_data_or_its_own_stat_ids() -> void:
	var paths: Array[String] = FLAT_BUILDING_PATHS.duplicate()
	paths.append_array([MINE_PATH, HARBOR_PATH])
	for path: String in paths:
		var building_def: BuildingDef = load(path)
		assert_eq(
			building_def.damage_stat, &"tower.damage", "%s keeps the tower damage stat" % path
		)
		assert_eq(building_def.range_stat, &"tower.range", "%s keeps the tower range stat" % path)
		for index: int in range(building_def.max_tier()):
			var tier: BuildingTierDef = building_def.tier_def(index + 1)
			assert_eq(tier.wake_radius, 0.0, "%s tier %d has no wake radius" % [path, index + 1])
			assert_eq(tier.wake_threshold_hp, 0, "%s tier %d has no threshold" % [path, index + 1])
			assert_eq(tier.synergy_percent, 0, "%s tier %d has no synergy" % [path, index + 1])
