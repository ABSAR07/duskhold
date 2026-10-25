extends GutTest
## The twelve castle ability cards, pinned on purpose (BLDG-08, BLDG-05, D-01, D-02, D-07): four per
## upgrade tier (II, III, IV), each a run-wide passive made only of stat modifiers on systems that
## exist by Phase 5. The set and its numbers are Claude's draft under D-02 and the owner judges
## them at the end-of-phase check; a deliberate retune edits this table in the same commit, as the
## military data contract does. Plan 05-11 measured the cards with the bots and fitted none of them
## (the order lever of the D-15 ladder met the bar), so the table is still the draft.
## Three draft names were replaced under the CLAUDE.md IP rule (no Thronefall names):
## Assassin's Training is Headsman's Edge, Rallying Banner is War Horns and Magic Armor is
## Warded Mail (the king takes a quarter less damage through king.damage_taken x0.75).
## Gap round G-05-2 (owner UAT decision 2026-10-25, plans 05-13 to 05-24): every health and damage
## number is 100 times larger, the owner's hard requirement, so percentages and rounding to the
## nearest unit work as written; the numbers below moved x100 and nothing else did; here: Royal
## Training's flat +100 king damage, the king's 300 base and 800 with both cards.
## Gap round G-05-2 (owner UAT 2026-10-24 and 2026-10-25, plans 05-13 to 05-24), the card recuts:
## every card at a tier must be a viable pick, and the rescale cannot help a flat gold card.
## Prosperity +1 to +2: a flat dawn card is worth its value times the dawns left to pay, and the
## debug session measured +2 matching Masons on wins and gold while +1 trailed (plan 05-23
## re-measures it).
## Golden Age's income +2 to +4: a flat dawn card is worth its value times the paying dawns left,
## tier IV comes about one paying dawn after tier II's day-6 pick, so +4 pays about what
## Prosperity's +2 pays at its tier; its +25% shrine damage stays.
## Headsman's Edge interval x1.5 to x1.25: against the one-hit kills of the shipped roster the old
## card was a third slower for no extra kill on skirmishers and after Royal Training; the worst
## case is now a fifth slower and the best case, grunts without Royal Training, is 1000 against
## 600: one blow instead of two at 1.25 times the interval; its x2 king damage stays.

const CASTLE_PATH := "res://data/buildings/castle_center.tres"
const ABILITY_DIR := "res://data/abilities/"
const NAME_LIMIT: int = 24
const FLAVOUR_LIMIT: int = 70
const FLAT: StatModifierDef.Bucket = StatModifierDef.Bucket.FLAT
const PERCENT: StatModifierDef.Bucket = StatModifierDef.Bucket.PERCENT
const MULTIPLIER: StatModifierDef.Bucket = StatModifierDef.Bucket.MULTIPLIER
## The twelve ids in tier order: tier II, then III, then IV.
const IDS: Array[StringName] = [
	&"royal_training",
	&"commander",
	&"masons",
	&"prosperity",
	&"headsmans_edge",
	&"engineers",
	&"war_horns",
	&"warded_mail",
	&"iron_discipline",
	&"arrow_storm",
	&"master_builders",
	&"golden_age",
]
## id -> [display name, [[stat, bucket, value], ...]] in modifier order.
const CARDS: Dictionary = {
	&"royal_training":
	["Royal Training", [[&"king.max_health", PERCENT, 25], [&"king.attack_damage", FLAT, 100]]],
	&"commander":
	["Commander", [[&"unit.max_health", PERCENT, 25], [&"unit.attack_damage", PERCENT, 25]]],
	&"masons":
	["Masons", [[&"building.max_health", PERCENT, 30], [&"wall.max_health", PERCENT, 30]]],
	&"prosperity": ["Prosperity", [[&"castle.base_income", FLAT, 2]]],
	&"headsmans_edge":
	[
		"Headsman's Edge",
		[[&"king.attack_damage", MULTIPLIER, 200], [&"king.attack_interval", MULTIPLIER, 125]]
	],
	&"engineers": ["Engineers", [[&"tower.damage", PERCENT, 25], [&"tower.range", PERCENT, 15]]],
	&"war_horns": ["War Horns", [[&"squad.respawn_seconds", MULTIPLIER, 60]]],
	&"warded_mail": ["Warded Mail", [[&"king.damage_taken", MULTIPLIER, 75]]],
	&"iron_discipline":
	[
		"Iron Discipline",
		[[&"unit.attack_damage", MULTIPLIER, 150], [&"unit.max_health", MULTIPLIER, 130]]
	],
	&"arrow_storm":
	["Arrow Storm", [[&"castle.arrow_damage", PERCENT, 100], [&"castle.arrow_range", PERCENT, 25]]],
	&"master_builders":
	[
		"Master Builders",
		[[&"building.max_health", MULTIPLIER, 150], [&"wall.max_health", MULTIPLIER, 150]]
	],
	&"golden_age":
	["Golden Age", [[&"castle.base_income", FLAT, 4], [&"shrine.damage", PERCENT, 25]]],
}
## Names of the Phase 5 draft that echo Thronefall's own perks (CLAUDE.md IP rule).
const BANNED_NAMES: Array[String] = ["Assassin's Training", "Magic Armor", "Rallying Banner"]
const KING_BASE_DAMAGE: int = 300
const KING_DAMAGE_AFTER_BOTH: int = 800


func _def() -> BuildingDef:
	return load(CASTLE_PATH)


func _tier_cards(tier: int) -> Array[ChoiceDef]:
	return _def().tier_def(tier).choices


func _all_cards() -> Array[ChoiceDef]:
	var cards: Array[ChoiceDef] = []
	for tier: int in range(2, 5):
		cards.append_array(_tier_cards(tier))
	return cards


func _card(card_id: StringName) -> ChoiceDef:
	for card: ChoiceDef in _all_cards():
		if card.id == card_id:
			return card
	return null


func _ids_of(tier: int) -> Array[StringName]:
	var ids: Array[StringName] = []
	for card: ChoiceDef in _tier_cards(tier):
		ids.append(card.id)
	return ids


## Asserts card `card_id` carries exactly the pinned modifiers, in order.
func _assert_numbers(card_id: StringName) -> void:
	var card: ChoiceDef = _card(card_id)
	assert_not_null(card, "%s exists" % card_id)
	if card == null:
		return
	var pinned: Array = (CARDS[card_id] as Array)[1]
	assert_eq(card.display_name, (CARDS[card_id] as Array)[0], "%s name" % card_id)
	assert_eq(card.modifiers.size(), pinned.size(), "%s modifier count" % card_id)
	for index: int in range(mini(card.modifiers.size(), pinned.size())):
		var want: Array = pinned[index]
		var got: StatModifierDef = card.modifiers[index]
		assert_eq(got.stat, want[0], "%s modifier %d stat" % [card_id, index])
		assert_eq(got.bucket, want[1], "%s modifier %d bucket" % [card_id, index])
		assert_eq(got.value, want[2], "%s modifier %d value" % [card_id, index])


func _stat_set(card: ChoiceDef) -> String:
	var stats: Array[String] = []
	for modifier: StatModifierDef in card.modifiers:
		stats.append(String(modifier.stat))
	stats.sort()
	return ",".join(PackedStringArray(stats))


func test_the_castle_has_four_tiers_with_0_4_4_4_choices() -> void:
	assert_eq(_def().max_tier(), 4, "four tiers")
	var counts: Array[int] = []
	for tier: int in range(1, 5):
		counts.append(_tier_cards(tier).size())
	assert_eq(counts, [0, 4, 4, 4] as Array[int], "tier I buys nothing, each upgrade offers four")


func test_the_twelve_ids_are_in_tier_order() -> void:
	var found: Array[StringName] = []
	for tier: int in range(2, 5):
		found.append_array(_ids_of(tier))
	assert_eq(found, IDS, "royal_training ... golden_age")


func test_tier_two_cards_carry_the_pinned_numbers() -> void:
	for card_id: StringName in IDS.slice(0, 4):
		_assert_numbers(card_id)


func test_tier_three_cards_carry_the_pinned_numbers() -> void:
	for card_id: StringName in IDS.slice(4, 8):
		_assert_numbers(card_id)


func test_tier_four_cards_carry_the_pinned_numbers() -> void:
	for card_id: StringName in IDS.slice(8, 12):
		_assert_numbers(card_id)


func test_no_card_id_appears_twice_and_each_id_has_its_own_file() -> void:
	var seen: Dictionary = {}
	for card: ChoiceDef in _all_cards():
		assert_false(seen.has(card.id), "%s appears once" % card.id)
		seen[card.id] = true
		assert_true(
			FileAccess.file_exists(ABILITY_DIR + String(card.id) + ".tres"),
			"%s has data/abilities/%s.tres" % [card.id, card.id]
		)
	assert_eq(seen.size(), IDS.size(), "twelve distinct cards")


func test_the_four_cards_of_a_tier_touch_four_different_sets_of_stats() -> void:
	for tier: int in range(2, 5):
		var sets: Dictionary = {}
		for card: ChoiceDef in _tier_cards(tier):
			var key: String = _stat_set(card)
			assert_false(sets.has(key), "tier %d: %s repeats the line '%s'" % [tier, card.id, key])
			sets[key] = true
		assert_eq(sets.size(), 4, "tier %d has four distinct lines" % tier)


func test_every_modifier_is_valid_and_the_stack_accepts_every_card() -> void:
	for card: ChoiceDef in _all_cards():
		var stack: StatStack = StatStack.new()
		assert_true(stack.add_source(card.id, card.modifiers), "%s is armed" % card.id)
		for modifier: StatModifierDef in card.modifiers:
			assert_eq(modifier.problems().size(), 0, "%s: %s is valid" % [card.id, modifier.stat])


func test_every_numbers_line_is_the_modifiers_text_joined_in_order() -> void:
	for card: ChoiceDef in _all_cards():
		var parts: PackedStringArray = PackedStringArray()
		for modifier: StatModifierDef in card.modifiers:
			parts.append(modifier.effect_text())
		assert_eq(card.effect_line(), ", ".join(parts), "%s line is generated" % card.id)
		assert_false(card.effect_line().is_empty(), "%s says something" % card.id)


func test_royal_training_then_headsmans_edge_makes_king_damage_800_in_either_order() -> void:
	var forward: StatStack = StatStack.new()
	forward.add_source(&"royal_training", _card(&"royal_training").modifiers)
	forward.add_source(&"headsmans_edge", _card(&"headsmans_edge").modifiers)
	var reverse: StatStack = StatStack.new()
	reverse.add_source(&"headsmans_edge", _card(&"headsmans_edge").modifiers)
	reverse.add_source(&"royal_training", _card(&"royal_training").modifiers)
	var want: int = KING_DAMAGE_AFTER_BOTH
	assert_eq(forward.int_value(&"king.attack_damage", KING_BASE_DAMAGE), want, "flat first")
	assert_eq(reverse.int_value(&"king.attack_damage", KING_BASE_DAMAGE), want, "same either way")


func test_headsmans_edge_slows_the_blow_by_a_quarter() -> void:
	var stack: StatStack = StatStack.new()
	stack.add_source(&"headsmans_edge", _card(&"headsmans_edge").modifiers)
	assert_almost_eq(stack.float_value(&"king.attack_interval", 0.8), 1.0, 0.0001, "0.8 s to 1.0 s")


func test_every_name_and_flavour_fits_and_is_plain_text() -> void:
	for card: ChoiceDef in _all_cards():
		assert_false(card.display_name.is_empty(), "%s has a name" % card.id)
		assert_lte(card.display_name.length(), NAME_LIMIT, "%s name length" % card.id)
		assert_false(card.flavour.is_empty(), "%s has a flavour line" % card.id)
		assert_lte(card.flavour.length(), FLAVOUR_LIMIT, "%s flavour length" % card.id)
		assert_eq(
			card.flavour.to_utf8_buffer().size(),
			card.flavour.length(),
			"%s flavour is ASCII, so bytes and code points agree" % card.id
		)


func test_no_card_is_named_after_a_draft_name_that_echoes_a_thronefall_perk() -> void:
	for card: ChoiceDef in _all_cards():
		assert_false(
			BANNED_NAMES.has(card.display_name), "%s is not '%s'" % [card.id, card.display_name]
		)
	assert_eq(_card(&"headsmans_edge").display_name, "Headsman's Edge", "renamed")
	assert_eq(_card(&"war_horns").display_name, "War Horns", "renamed")
	assert_eq(_card(&"warded_mail").display_name, "Warded Mail", "renamed")


func test_warded_mail_lowers_the_damage_the_king_takes_by_a_quarter() -> void:
	var stack: StatStack = StatStack.new()
	stack.add_source(&"warded_mail", _card(&"warded_mail").modifiers)
	assert_eq(stack.int_value(&"king.damage_taken", 4), 3, "a blow of 4 lands as 3")
	assert_eq(stack.int_value(&"king.damage_taken", 8), 6, "a blow of 8 lands as 6")


func test_the_shipped_map_validates_clean_with_all_twelve_cards() -> void:
	var map: MapConfig = load("res://data/maps/prototype_map.tres")
	assert_eq(map.validate().size(), 0, "no error: %s" % [map.validate()])
