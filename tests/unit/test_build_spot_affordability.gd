extends GutTest
## BLDG-02: a build is accepted exactly when gold covers the tier cost, and only then.
## Gold for the edge cases comes from a MapConfig duplicate; Economy has no gold setter.

const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"


func _context_with_gold(gold: int) -> RunContext:
	var map: MapConfig = (load(PROTOTYPE_MAP) as MapConfig).duplicate(true)
	map.starting_gold = gold
	return RunContext.new(map, load(TUNING))


func test_one_gold_short_is_cannot_afford() -> void:
	var probe: RunContext = _context_with_gold(0)
	var spot_id: StringName = probe.buildings.spot_ids()[0]
	var cost: int = probe.buildings.next_action_cost(spot_id)
	var ctx: RunContext = _context_with_gold(cost - 1)
	assert_eq(ctx.commands.validate_build(spot_id), CommandProcessor.CANNOT_AFFORD, "check")
	assert_eq(ctx.commands.submit(BuildIntent.new(spot_id)), CommandProcessor.CANNOT_AFFORD)
	assert_eq(ctx.economy.get_gold(), cost - 1, "gold unchanged")
	assert_eq(ctx.buildings.current_tier(spot_id), 0, "plot stays empty")


func test_exact_gold_is_ok_and_leaves_zero_with_the_next_tier_priced() -> void:
	var probe: RunContext = _context_with_gold(0)
	var spot_id: StringName = probe.buildings.spot_ids()[0]
	var cost: int = probe.buildings.next_action_cost(spot_id)
	var ctx: RunContext = _context_with_gold(cost)
	assert_eq(ctx.commands.validate_build(spot_id), CommandProcessor.OK, "check")
	assert_eq(ctx.commands.submit(BuildIntent.new(spot_id)), CommandProcessor.OK, "accepted")
	assert_eq(ctx.economy.get_gold(), 0, "gold is spent to exactly zero")
	var tier_two: BuildingTierDef = ctx.buildings.get_building_def_for_spot(spot_id).tier_def(2)
	assert_eq(ctx.buildings.next_action_cost(spot_id), tier_two.cost, "next price is tier II")


func test_starting_gold_pays_for_two_houses_or_one_tower() -> void:
	var start_gold: int = (load(PROTOTYPE_MAP) as MapConfig).starting_gold
	var houses: RunContext = _context_with_gold(start_gold)
	var house_spots: Array[StringName] = []
	var tower_spots: Array[StringName] = []
	for spot_id: StringName in houses.buildings.spot_ids():
		if houses.buildings.get_spot(spot_id).building_id == &"house":
			house_spots.append(spot_id)
		else:
			tower_spots.append(spot_id)
	assert_gt(tower_spots.size(), 0, "the map has tower plots")
	if tower_spots.is_empty() or house_spots.size() < 2:
		return
	assert_eq(houses.commands.submit(BuildIntent.new(house_spots[0])), CommandProcessor.OK)
	assert_eq(houses.commands.submit(BuildIntent.new(house_spots[1])), CommandProcessor.OK)
	assert_eq(
		houses.commands.submit(BuildIntent.new(tower_spots[0])),
		CommandProcessor.CANNOT_AFFORD,
		"two Houses leave no room for a tower"
	)
	var tower: RunContext = _context_with_gold(start_gold)
	assert_eq(tower.commands.submit(BuildIntent.new(tower_spots[0])), CommandProcessor.OK)
	assert_eq(
		tower.commands.submit(BuildIntent.new(house_spots[0])),
		CommandProcessor.CANNOT_AFFORD,
		"a tower leaves no room for a House"
	)
