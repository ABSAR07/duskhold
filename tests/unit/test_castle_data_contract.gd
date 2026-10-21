extends GutTest
## The shipped castle numbers, pinned on purpose (D-01, D-04, BLDG-08): four tiers on the rising
## cost line 6 / 10 / 16, health 100 / 140 / 200 above the map's 70, arrow damage 3 / 4 / 5 and
## dawn income 2 / 3 / 4 above the map's 2 and 1, the arrow's reach, interval and speed unchanged
## from the map's. Tier I carries only its (never charged) cost: its health, arrow and income are
## the map's own castle fields, so no number has two homes. These are the plan 05-02 starting
## points; plan 05-11 fits them with the bots and re-pins them here deliberately.

const CASTLE_PATH := "res://data/buildings/castle_center.tres"
const MAP_PATH := "res://data/maps/prototype_map.tres"
const COSTS: Array[int] = [6, 10, 16]
const HEALTH: Array[int] = [100, 140, 200]
const ARROW_DAMAGE: Array[int] = [3, 4, 5]
const DAWN_INCOME: Array[int] = [2, 3, 4]
const TIER_TWO_CARDS: Array[StringName] = [
	&"royal_training", &"commander", &"masons", &"prosperity"
]
const MAX_FLAVOUR_CHARACTERS: int = 70


func _def() -> BuildingDef:
	return load(CASTLE_PATH)


func test_the_castle_has_four_tiers() -> void:
	assert_eq(_def().id, &"castle_center", "id")
	assert_eq(_def().max_tier(), 4, "four tiers (D-01)")


func test_tiers_two_to_four_follow_the_rising_cost_line() -> void:
	for index: int in range(COSTS.size()):
		assert_eq(_def().tier_def(index + 2).cost, COSTS[index], "tier %d cost" % (index + 2))


func test_health_rises_above_the_maps_castle_each_tier() -> void:
	var map: MapConfig = load(MAP_PATH)
	var floor_health: int = map.castle_max_health
	for index: int in range(HEALTH.size()):
		var health: int = _def().tier_def(index + 2).max_health
		assert_eq(health, HEALTH[index], "tier %d health" % (index + 2))
		assert_gt(health, floor_health, "and above the tier before it")
		floor_health = health


func test_the_arrow_and_the_income_grow_with_the_tier_and_keep_the_maps_reach() -> void:
	var map: MapConfig = load(MAP_PATH)
	for index: int in range(ARROW_DAMAGE.size()):
		var tier: BuildingTierDef = _def().tier_def(index + 2)
		assert_eq(tier.attack_damage, ARROW_DAMAGE[index], "tier %d arrow damage" % (index + 2))
		assert_eq(tier.dawn_income, DAWN_INCOME[index], "tier %d income" % (index + 2))
		assert_eq(tier.attack_range, map.castle_attack_range, "reach is the map's")
		assert_eq(tier.attack_interval, map.castle_attack_interval, "interval is the map's")
		assert_eq(tier.projectile_speed, map.castle_projectile_speed, "speed is the map's")


func test_tier_one_carries_no_number_the_map_already_owns() -> void:
	var tier: BuildingTierDef = _def().tier_def(1)
	var defaults: BuildingTierDef = BuildingTierDef.new()
	assert_eq(tier.attack_damage, defaults.attack_damage, "no arrow of its own")
	assert_eq(tier.dawn_income, defaults.dawn_income, "no income of its own")
	assert_true(tier.choices.is_empty(), "and no cards")


func test_tier_two_offers_the_four_abilities_and_tiers_three_and_four_four_more_each() -> void:
	var ids: Array[StringName] = []
	for card: ChoiceDef in _def().tier_def(2).choices:
		ids.append(card.id)
	assert_eq(ids, TIER_TWO_CARDS, "four cards in the authored order")
	assert_eq(_def().tier_def(3).choices.size(), 4, "tier III offers four (test_ability_data)")
	assert_eq(_def().tier_def(4).choices.size(), 4, "tier IV offers four (test_ability_data)")


func test_every_card_is_valid_data() -> void:
	var seen: Dictionary = {}
	for card: ChoiceDef in _def().tier_def(2).choices:
		assert_false(seen.has(card.id), "%s is unique" % card.id)
		seen[card.id] = true
		assert_lte(card.flavour.length(), MAX_FLAVOUR_CHARACTERS, "%s flavour length" % card.id)
		assert_null(card.icon, "%s has no icon yet (plan 05-04)" % card.id)
		var stack: StatStack = StatStack.new()
		assert_true(
			stack.add_source(card.id, card.modifiers), "%s is accepted by the stack" % card.id
		)
		for mod: StatModifierDef in card.modifiers:
			assert_eq(mod.problems().size(), 0, "%s modifier %s is valid" % [card.id, mod.stat])


func test_the_shipped_map_validates_clean_with_the_castle_plot() -> void:
	var map: MapConfig = load(MAP_PATH)
	assert_eq(map.validate().size(), 0, "no validation error: %s" % [map.validate()])
