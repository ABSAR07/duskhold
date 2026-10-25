extends GutTest
## BLDG-08, UI-02, D-02, D-07: the castle's label names the next tier and what it gives, with each
## number read through the stat stack (health, arrow damage, gold at dawn), and lists the cards
## already picked in pick order. At the top tier it reads Max tier with all three picks. A card's
## own numbers line is generated from its modifiers. Expectations are read from castle_center.tres,
## so a retune of the castle numbers cannot break the test (test_castle_data_contract pins them).
## Gap round G-05-2 (owner UAT decision 2026-10-25, plans 05-13 to 05-24): every health and damage
## number is 100 times larger, the owner's hard requirement, so percentages and rounding to the
## nearest unit work as written; the numbers below moved x100 and nothing else did; here: the castle
## label's Health 10000 and Arrow 300, Royal Training's +100 king damage.

const FIXTURE := "res://tests/fixtures/fixture_map_castle.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const CASTLE_DEF := "res://data/buildings/castle_center.tres"
const CASTLE: StringName = &"castle_plot"
const HOUSE: StringName = &"house_1"
const RICH_GOLD: int = 200
const SEPARATOR := " · "

var _ctx: RunContext


func before_each() -> void:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate(true)
	map.starting_gold = RICH_GOLD
	_ctx = RunContext.new(map, load(TUNING))


func _tier(number: int) -> BuildingTierDef:
	return (load(CASTLE_DEF) as BuildingDef).tier_def(number)


func _label() -> Dictionary:
	return SpotLabelModel.describe(_ctx, CASTLE, 0)


func _effect_of(tier: BuildingTierDef) -> String:
	return (
		"Health %d · Arrow %d · %d gold at dawn"
		% [tier.max_health, tier.attack_damage, tier.dawn_income]
	)


func _buy(card: StringName) -> void:
	assert_eq(_ctx.commands.submit(BuildIntent.new(CASTLE, card)), CommandProcessor.OK, str(card))


func _card(card_id: StringName) -> ChoiceDef:
	return _ctx.choices.find_choice(card_id)


func test_at_tier_one_the_label_offers_castle_two_with_the_tier_two_numbers() -> void:
	var content: Dictionary = _label()
	assert_eq(content["title"], "Castle II", "the next tier")
	assert_eq(content["cost"], _tier(2).cost, "its price")
	assert_eq(content["effect"], _effect_of(_tier(2)), "its health, arrow and gold")
	assert_eq(content["picks"], "", "nothing picked yet")
	assert_eq(content["max_tier"], false, "three upgrades remain")


func test_the_shipped_tier_two_effect_reads_as_the_plan_says() -> void:
	assert_eq(_label()["effect"], "Health 10000 · Arrow 300 · 2 gold at dawn", "tier II as shipped")


func test_after_tier_two_the_title_is_castle_three_and_the_pick_is_listed() -> void:
	_buy(&"royal_training")
	var content: Dictionary = _label()
	assert_eq(content["title"], "Castle III", "title")
	assert_eq(content["effect"], _effect_of(_tier(3)), "the tier III numbers")
	assert_eq(content["picks"], "Royal Training", "the first pick")


func test_an_arrow_source_on_the_stack_changes_the_arrow_number_not_the_raw_tier_value() -> void:
	var mod: StatModifierDef = StatModifierDef.new()
	mod.stat = &"castle.arrow_damage"
	mod.bucket = StatModifierDef.Bucket.PERCENT
	mod.value = 100
	var mods: Array[StatModifierDef] = [mod]
	assert_true(_ctx.stat_stack.add_source(&"probe", mods), "the stack takes the source")
	var doubled: int = _ctx.stat_stack.int_value(&"castle.arrow_damage", _tier(2).attack_damage)
	assert_eq(doubled, _tier(2).attack_damage * 2, "the stack doubles the base")
	assert_eq(
		_label()["effect"],
		(
			"Health %d · Arrow %d · %d gold at dawn"
			% [_tier(2).max_health, doubled, _tier(2).dawn_income]
		),
		"the label shows the stack value"
	)


func test_a_gold_source_and_a_health_source_show_in_the_label_too() -> void:
	_buy(&"prosperity")
	var gain: int = (_card(&"prosperity").modifiers[0] as StatModifierDef).value
	var income: int = _ctx.stat_stack.int_value(&"castle.base_income", _tier(3).dawn_income)
	assert_eq(income, _tier(3).dawn_income + gain, "Prosperity adds its value")
	assert_eq(
		_label()["effect"],
		(
			"Health %d · Arrow %d · %d gold at dawn"
			% [_tier(3).max_health, _tier(3).attack_damage, income]
		),
		"so the label does"
	)


func test_at_tier_four_the_label_says_max_tier_with_all_three_picks_in_order() -> void:
	_buy(&"royal_training")
	_buy(&"engineers")
	_buy(&"golden_age")
	var content: Dictionary = _label()
	assert_eq(content["title"], "Castle IV", "the top tier")
	assert_eq(content["status_line"], "Max tier", "status")
	assert_eq(content["max_tier"], true, "flagged")
	assert_eq(content["effect"], "", "nothing left to buy")
	var names: PackedStringArray = ["Royal Training", "Engineers", "Golden Age"]
	assert_eq(content["picks"], SEPARATOR.join(names), "three names in pick order")


func test_the_picks_follow_the_order_they_were_made_in() -> void:
	_buy(&"masons")
	_buy(&"warded_mail")
	assert_eq(_label()["picks"], "Masons" + SEPARATOR + "Warded Mail", "two picks")


func test_a_house_plot_has_no_picks() -> void:
	_buy(&"royal_training")
	assert_eq(SpotLabelModel.describe(_ctx, HOUSE, 0)["picks"], "", "the House lists none")


func test_royal_training_reads_plus_25_percent_health_and_plus_100_damage() -> void:
	assert_eq(_card(&"royal_training").effect_line(), "+25% king health, +100 king damage", "line")


func test_headsmans_edge_reads_two_multipliers() -> void:
	var line: String = _card(&"headsmans_edge").effect_line()
	assert_eq(line, "x2 king damage, x1.5 king attack interval", "line")


func test_a_card_with_no_modifiers_has_an_empty_line() -> void:
	assert_eq(ChoiceDef.new().effect_line(), "", "empty")


func test_a_single_modifier_card_has_no_separator() -> void:
	assert_eq(_card(&"warded_mail").effect_line(), "x0.75 damage the king takes", "one part")
