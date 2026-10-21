extends GutTest
## T-05-07, T-05-08, BLDG-05, BLDG-08, D-01, D-02: MapConfig.validate() reports bad card and castle
## data instead of arming it: a duplicate card id anywhere in the map (once, naming both places), a
## null or empty-id choice, a card with no name or no modifiers, a modifier with problems, a name
## over 24 or a flavour over 70 characters (String.length), a castle upgrade tier without exactly
## four cards, a castle building with fewer than two tiers or a tier I that carries cards, and a
## castle plot far from the castle. Each bad case edits a deep copy of the castle fixture and calls
## validate() directly, never through RunContext, whose push_error would fail the test. The second
## castle plot and the castle plot that is also a wall plot are pinned in test_castle_tiers.

const FIXTURE := "res://tests/fixtures/fixture_map_castle.tres"
const PROTOTYPE := "res://data/maps/prototype_map.tres"
const CASTLE_ID: StringName = &"castle_center"
const CASTLE_PLOT: StringName = &"castle_plot"
const NAME_LIMIT: int = 24
const FLAVOUR_LIMIT: int = 70
const FAR_PLOT := Vector3(0.0, 0.0, 30.0)


func _map() -> MapConfig:
	return (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)


func _building(map: MapConfig, building_id: StringName) -> BuildingDef:
	for building_def: BuildingDef in map.buildings:
		if building_def.id == building_id:
			return building_def
	return null


func _castle(map: MapConfig) -> BuildingDef:
	return _building(map, CASTLE_ID)


## The card in slot `slot` (0 to 3) of castle tier `tier` (1 based).
func _card(map: MapConfig, tier: int, slot: int) -> ChoiceDef:
	return _castle(map).tier_def(tier).choices[slot]


func _new_card(card_id: StringName) -> ChoiceDef:
	var mod: StatModifierDef = StatModifierDef.new()
	mod.stat = &"king.max_health"
	mod.value = 1
	var card: ChoiceDef = ChoiceDef.new()
	card.id = card_id
	card.display_name = "Extra"
	card.flavour = "An extra card."
	card.modifiers = [mod]
	return card


## Asserts validate() reports exactly one error and that it contains every needle.
func _assert_one_error(map: MapConfig, needles: Array[String], what: String) -> void:
	var errors: PackedStringArray = map.validate()
	assert_eq(errors.size(), 1, "%s: exactly one error, got %s" % [what, errors])
	if errors.size() == 1:
		for needle: String in needles:
			assert_string_contains(errors[0], needle, "%s names %s" % [what, needle])


func test_the_castle_fixture_validates_clean() -> void:
	var errors: PackedStringArray = _map().validate()
	assert_eq(errors.size(), 0, "no error: %s" % [errors])


func test_the_shipped_prototype_map_validates_clean() -> void:
	var errors: PackedStringArray = (load(PROTOTYPE) as MapConfig).validate()
	assert_eq(errors.size(), 0, "no error: %s" % [errors])


func test_a_prototype_copy_with_a_one_point_castle_still_validates_clean() -> void:
	var map: MapConfig = (load(PROTOTYPE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	map.castle_max_health = 1
	assert_eq(map.validate().size(), 0, "tier I reads the map, so a small castle is legal")


func test_a_duplicate_card_id_on_two_tiers_is_reported_once_naming_both_places() -> void:
	var map: MapConfig = _map()
	_card(map, 3, 0).id = _card(map, 2, 0).id
	_assert_one_error(map, ["royal_training", "castle_center", "tier 2", "tier 3"], "duplicate")


func test_two_cards_with_one_id_in_the_same_tier_are_reported_once() -> void:
	var map: MapConfig = _map()
	_card(map, 4, 1).id = _card(map, 4, 0).id
	_assert_one_error(map, ["iron_discipline", "tier 4"], "same tier")


func test_the_same_id_three_times_is_still_one_report() -> void:
	var map: MapConfig = _map()
	_card(map, 3, 0).id = _card(map, 2, 0).id
	_card(map, 4, 0).id = _card(map, 2, 0).id
	var errors: PackedStringArray = map.validate()
	assert_eq(errors.size(), 1, "reported once, got %s" % [errors])


func test_a_card_id_shared_with_another_building_is_reported() -> void:
	var map: MapConfig = _map()
	var house: BuildingDef = _building(map, &"house")
	var shared: Array[ChoiceDef] = [_new_card(_card(map, 2, 0).id)]
	house.tiers[0].choices = shared
	_assert_one_error(map, ["royal_training", "house", "castle_center"], "across buildings")


func test_a_null_choice_is_reported() -> void:
	var map: MapConfig = _map()
	_castle(map).tier_def(2).choices[1] = null
	_assert_one_error(map, ["castle_center", "tier 2", "empty"], "null card")


func test_a_card_with_an_empty_id_is_reported() -> void:
	var map: MapConfig = _map()
	_card(map, 2, 2).id = &""
	_assert_one_error(map, ["castle_center", "tier 2", "empty id"], "empty id")


func test_a_card_with_no_name_is_reported() -> void:
	var map: MapConfig = _map()
	_card(map, 3, 1).display_name = ""
	_assert_one_error(map, ["engineers", "no name"], "empty name")


func test_a_card_with_no_modifiers_is_reported() -> void:
	var map: MapConfig = _map()
	var none: Array[StatModifierDef] = []
	_card(map, 3, 2).modifiers = none
	_assert_one_error(map, ["war_horns", "no modifiers"], "empty modifiers")


func test_a_modifier_on_an_unregistered_stat_is_reported_with_the_stat_id() -> void:
	var map: MapConfig = _map()
	_card(map, 2, 0).modifiers[0].stat = &"king.typo"
	_assert_one_error(map, ["royal_training", "king.typo"], "unknown stat")


func test_a_modifier_outside_its_bucket_range_is_reported() -> void:
	var map: MapConfig = _map()
	_card(map, 3, 0).modifiers[0].value = StatModifierDef.MULTIPLIER_MAX + 1
	_assert_one_error(map, ["headsmans_edge", "outside"], "bad value")


func test_a_24_character_name_passes_and_a_25_character_name_is_reported() -> void:
	var map: MapConfig = _map()
	_card(map, 2, 0).display_name = "n".repeat(NAME_LIMIT)
	assert_eq(map.validate().size(), 0, "24 characters pass")
	_card(map, 2, 0).display_name = "n".repeat(NAME_LIMIT + 1)
	_assert_one_error(map, ["royal_training", "name", "25"], "25 characters")


func test_a_70_character_flavour_passes_and_a_71_character_flavour_is_reported() -> void:
	var map: MapConfig = _map()
	_card(map, 4, 3).flavour = "f".repeat(FLAVOUR_LIMIT)
	assert_eq(map.validate().size(), 0, "70 characters pass")
	_card(map, 4, 3).flavour = "f".repeat(FLAVOUR_LIMIT + 1)
	_assert_one_error(map, ["golden_age", "flavour", "71"], "71 characters")


func test_a_castle_upgrade_tier_with_three_cards_is_reported() -> void:
	var map: MapConfig = _map()
	var three: Array[ChoiceDef] = [_card(map, 3, 0), _card(map, 3, 1), _card(map, 3, 2)]
	_castle(map).tier_def(3).choices = three
	_assert_one_error(map, ["castle_center", "tier 3", "3 cards", "4"], "three cards")


func test_a_castle_upgrade_tier_with_five_cards_is_reported() -> void:
	var map: MapConfig = _map()
	_castle(map).tier_def(4).choices.append(_new_card(&"fifth"))
	_assert_one_error(map, ["castle_center", "tier 4", "5 cards"], "five cards")


func test_a_castle_building_with_one_tier_is_reported() -> void:
	var map: MapConfig = _map()
	var only: Array[BuildingTierDef] = [_castle(map).tiers[0]]
	_castle(map).tiers = only
	_assert_one_error(map, ["castle_center", "fewer than two tiers"], "one tier")


func test_a_castle_tier_one_that_carries_cards_is_reported() -> void:
	var map: MapConfig = _map()
	_castle(map).tier_def(1).choices.append(_new_card(&"extra"))
	_assert_one_error(map, ["castle_center", "tier 1", "cards"], "tier I with cards")


func test_a_castle_plot_far_from_the_castle_is_reported() -> void:
	var map: MapConfig = _map()
	for spot: BuildSpotDef in map.spots:
		if spot.id == CASTLE_PLOT:
			spot.position = FAR_PLOT
	_assert_one_error(map, ["castle_plot", "from the castle"], "far plot")
