extends GutTest
## D-03, BLDG-09: the castle gate on the shipped data, pinned on purpose. The last tier of every
## non-castle building with two or more tiers needs the castle at tier II: House III, Tower II,
## Barracks III, Archery Range III, Wall III (Phase 4 buildings, gated in plan 05-11 by this one
## data line each), Mill III and Fishing Harbor II (gated in plans 05-07 and 05-08). No other tier
## of any shipped building carries a castle requirement; the castle's own tiers carry none (a castle
## tier needing the castle would refer to itself); a one-tier building (Gold Mine, Field, Shrine)
## carries none. The pins are read from the shipped map's own building list, so a building added to
## the map later without a decision here fails loudly. D-01 is pinned beside the gate: the first
## castle upgrade costs more than the starting gold plus the first dawn's base income, so it is a
## real early trade-off and never a free day-one buy.

const MAP_PATH := "res://data/maps/prototype_map.tres"
const CASTLE_BUILDING: StringName = &"castle_center"
const GATE_TIER: int = 2
## Building id to the 1-based tier that needs the castle at GATE_TIER (the last tier).
const GATED_TIER: Dictionary = {
	&"house": 3,
	&"tower": 2,
	&"barracks": 3,
	&"archery_range": 3,
	&"wall": 3,
	&"mill": 3,
	&"fishing_harbor": 2,
}
const ONE_TIER_BUILDINGS: Array[StringName] = [&"gold_mine", &"field", &"shrine"]


func _map() -> MapConfig:
	return load(MAP_PATH)


func _def(building_id: StringName) -> BuildingDef:
	for building_def: BuildingDef in _map().buildings:
		if building_def.id == building_id:
			return building_def
	return null


func test_the_last_tier_of_every_gated_building_needs_castle_two() -> void:
	for building_id: StringName in GATED_TIER:
		var def: BuildingDef = _def(building_id)
		assert_not_null(def, "%s is on the shipped map" % building_id)
		if def == null:
			continue
		var tier: int = GATED_TIER[building_id]
		assert_eq(tier, def.max_tier(), "%s: the gated tier is the last one" % building_id)
		assert_eq(
			def.tier_def(tier).requires_castle_tier,
			GATE_TIER,
			"%s tier %d needs castle %d" % [building_id, tier, GATE_TIER]
		)


func test_no_other_tier_of_any_shipped_building_carries_a_castle_requirement() -> void:
	for def: BuildingDef in _map().buildings:
		for tier: int in range(1, def.max_tier() + 1):
			var expected: int = 0
			if def.id != CASTLE_BUILDING and GATED_TIER.get(def.id, 0) == tier:
				expected = GATE_TIER
			assert_eq(
				def.tier_def(tier).requires_castle_tier,
				expected,
				"%s tier %d: the requirement is %d" % [def.id, tier, expected]
			)


func test_every_non_castle_building_with_two_or_more_tiers_is_in_the_gate_table() -> void:
	for def: BuildingDef in _map().buildings:
		if def.id == CASTLE_BUILDING:
			continue
		if def.max_tier() >= 2:
			assert_true(GATED_TIER.has(def.id), "%s has a gated last tier" % def.id)
		else:
			assert_true(ONE_TIER_BUILDINGS.has(def.id), "%s is a known one-tier building" % def.id)
			assert_eq(def.tier_def(1).requires_castle_tier, 0, "%s is never gated" % def.id)


func test_the_castles_own_tiers_carry_no_castle_requirement() -> void:
	var castle: BuildingDef = _def(CASTLE_BUILDING)
	assert_not_null(castle, "the castle def is on the shipped map")
	if castle == null:
		return
	assert_eq(castle.max_tier(), 4, "four tiers")
	for tier: int in range(1, castle.max_tier() + 1):
		assert_eq(castle.tier_def(tier).requires_castle_tier, 0, "castle tier %d" % tier)


func test_the_gate_names_a_castle_tier_the_castle_can_reach() -> void:
	var castle: BuildingDef = _def(CASTLE_BUILDING)
	assert_lte(GATE_TIER, castle.max_tier(), "castle II exists")
	assert_gt(GATE_TIER, 1, "and is an upgrade, not the castle the run starts with")


func test_the_shipped_map_validates_with_the_gate_in_place() -> void:
	assert_eq(_map().validate().size(), 0, "no impossible requirement on the shipped map")


func test_the_first_castle_upgrade_costs_more_than_the_first_dawns_gold() -> void:
	## D-01: starting gold plus the base income of the first dawn is what a player holds at the
	## first chance to buy it, and the upgrade costs more than that.
	var map: MapConfig = _map()
	var castle: BuildingDef = _def(CASTLE_BUILDING)
	var first_dawn: int = map.starting_gold + map.base_dawn_income
	assert_gt(
		castle.tier_def(2).cost,
		first_dawn,
		(
			"castle II costs %d, above %d starting gold plus %d base income"
			% [castle.tier_def(2).cost, map.starting_gold, map.base_dawn_income]
		)
	)
