extends GutTest
## UI-02, D-06: the pure content of the world-space card row. The cards of the next tier of a spot
## come in the tier's authored order with their ids, names and flavour lines; only the highlighted
## one is flagged; a plot with no cards to offer gives none; digit n addresses card n.

const FIXTURE := "res://tests/fixtures/fixture_map_castle.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const CASTLE: StringName = &"castle_plot"
const HOUSE: StringName = &"house_1"
const MAX_FLAVOUR_CHARACTERS: int = 70

var _ctx: RunContext


func before_each() -> void:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate(true)
	map.starting_gold = 100
	_ctx = RunContext.new(map, load(TUNING))


func _tier_two_cards() -> Array[ChoiceDef]:
	var def: BuildingDef = load("res://data/buildings/castle_center.tres")
	return def.tier_def(2).choices


func test_the_castle_offers_four_cards_in_the_authored_order() -> void:
	var shown: Array[Dictionary] = CardRowModel.cards(_ctx, CASTLE, -1)
	var authored: Array[ChoiceDef] = _tier_two_cards()
	assert_eq(shown.size(), 4, "four cards")
	for index: int in range(mini(shown.size(), authored.size())):
		assert_eq(shown[index]["id"], authored[index].id, "card %d id" % (index + 1))
		assert_eq(shown[index]["name"], authored[index].display_name, "name")
		assert_eq(shown[index]["flavour"], authored[index].flavour, "flavour")
		assert_eq(shown[index]["icon"], authored[index].icon, "icon")


func test_the_four_cards_are_royal_training_commander_masons_and_prosperity() -> void:
	var ids: Array[StringName] = []
	for card: Dictionary in CardRowModel.cards(_ctx, CASTLE, -1):
		ids.append(card["id"])
	assert_eq(ids, [&"royal_training", &"commander", &"masons", &"prosperity"] as Array[StringName])


func test_no_card_is_highlighted_when_the_index_is_minus_one() -> void:
	for card: Dictionary in CardRowModel.cards(_ctx, CASTLE, -1):
		assert_false(card["highlighted"], "%s is not highlighted" % card["id"])


func test_only_the_card_at_the_index_is_highlighted() -> void:
	var shown: Array[Dictionary] = CardRowModel.cards(_ctx, CASTLE, 2)
	for index: int in range(shown.size()):
		assert_eq(shown[index]["highlighted"], index == 2, "card %d" % (index + 1))


func test_an_index_past_the_last_card_highlights_none() -> void:
	for card: Dictionary in CardRowModel.cards(_ctx, CASTLE, 9):
		assert_false(card["highlighted"], "none")


func test_a_house_plot_has_no_cards() -> void:
	assert_true(CardRowModel.cards(_ctx, HOUSE, -1).is_empty(), "a plain tier shows none")


func test_an_unknown_spot_has_no_cards() -> void:
	assert_true(CardRowModel.cards(_ctx, &"nowhere", -1).is_empty(), "unknown")


func test_each_castle_tier_shows_its_own_four_cards_and_the_top_shows_none() -> void:
	assert_eq(_ctx.commands.submit(BuildIntent.new(CASTLE, &"masons")), CommandProcessor.OK)
	var third: Array[Dictionary] = CardRowModel.cards(_ctx, CASTLE, -1)
	assert_eq(third.size(), 4, "tier III offers four")
	assert_eq(third[0]["id"], &"headsmans_edge", "its own first card")
	assert_eq(_ctx.commands.submit(BuildIntent.new(CASTLE, &"engineers")), CommandProcessor.OK)
	var fourth: Array[Dictionary] = CardRowModel.cards(_ctx, CASTLE, -1)
	assert_eq(fourth.size(), 4, "tier IV offers four")
	assert_eq(fourth[0]["id"], &"iron_discipline", "its own first card")
	assert_eq(_ctx.commands.submit(BuildIntent.new(CASTLE, &"golden_age")), CommandProcessor.OK)
	assert_true(CardRowModel.cards(_ctx, CASTLE, -1).is_empty(), "tier IV is the top")


func test_digits_one_to_four_address_cards_one_to_four() -> void:
	for digit: int in range(1, 5):
		assert_eq(CardRowModel.index_for_digit(digit, 4), digit - 1, "digit %d" % digit)


func test_a_digit_that_addresses_no_card_gives_minus_one() -> void:
	assert_eq(CardRowModel.index_for_digit(0, 4), -1, "zero")
	assert_eq(CardRowModel.index_for_digit(5, 4), -1, "above the card count")
	assert_eq(CardRowModel.index_for_digit(3, 2), -1, "above a short row")
	assert_eq(CardRowModel.index_for_digit(-1, 4), -1, "negative")


func test_every_flavour_line_is_short_and_every_name_is_set() -> void:
	for card: ChoiceDef in _tier_two_cards():
		assert_false(card.display_name.is_empty(), "%s has a name" % card.id)
		assert_false(card.flavour.is_empty(), "%s has a flavour line" % card.id)
		assert_lte(card.flavour.length(), MAX_FLAVOUR_CHARACTERS, "%s flavour" % card.id)
		assert_false(card.modifiers.is_empty(), "%s does something" % card.id)


func test_every_card_carries_the_numbers_line_of_its_modifiers() -> void:
	var shown: Array[Dictionary] = CardRowModel.cards(_ctx, CASTLE, -1)
	var authored: Array[ChoiceDef] = _tier_two_cards()
	for index: int in range(mini(shown.size(), authored.size())):
		assert_eq(
			shown[index]["effect_line"], authored[index].effect_line(), "card %d" % (index + 1)
		)
		assert_false((shown[index]["effect_line"] as String).is_empty(), "it says something")


func test_every_card_carries_the_key_that_picks_it() -> void:
	var shown: Array[Dictionary] = CardRowModel.cards(_ctx, CASTLE, -1)
	for index: int in range(shown.size()):
		var label: String = "card %d is picked by key %d" % [index + 1, index + 1]
		assert_eq(shown[index]["key_hint"], index + 1, label)


func test_hit_test_returns_the_card_whose_rectangle_holds_the_point() -> void:
	var rects: Array[Rect2] = [Rect2(0, 0, 10, 10), Rect2(10, 0, 10, 10)]
	assert_eq(CardRowModel.hit_test(rects, Vector2(5, 5)), 0, "inside the first")
	assert_eq(CardRowModel.hit_test(rects, Vector2(15, 5)), 1, "inside the second")
	assert_eq(CardRowModel.hit_test(rects, Vector2(0, 0)), 0, "the top left corner is inside")


func test_hit_test_gives_a_shared_edge_to_the_lower_index() -> void:
	var rects: Array[Rect2] = [Rect2(0, 0, 10, 10), Rect2(10, 0, 10, 10)]
	assert_eq(CardRowModel.hit_test(rects, Vector2(10, 5)), 0, "the edge both share")
	assert_eq(CardRowModel.hit_test(rects, Vector2(20, 5)), 1, "the far edge belongs to the last")


func test_hit_test_gives_overlapping_rectangles_to_the_lower_index() -> void:
	var rects: Array[Rect2] = [Rect2(0, 0, 10, 10), Rect2(5, 0, 10, 10)]
	assert_eq(CardRowModel.hit_test(rects, Vector2(7, 5)), 0, "inside both")
	assert_eq(CardRowModel.hit_test(rects, Vector2(12, 5)), 1, "inside the second only")


func test_hit_test_gives_minus_one_outside_every_rectangle_and_for_no_rectangle() -> void:
	var rects: Array[Rect2] = [Rect2(0, 0, 10, 10), Rect2(10, 0, 10, 10)]
	assert_eq(CardRowModel.hit_test(rects, Vector2(25, 5)), -1, "to the right")
	assert_eq(CardRowModel.hit_test(rects, Vector2(5, 11)), -1, "below")
	assert_eq(CardRowModel.hit_test([] as Array[Rect2], Vector2(5, 5)), -1, "an empty list")
