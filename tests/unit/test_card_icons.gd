extends GutTest
## UI-02, D-07: every card of the castle ladder carries its own first-party icon (a CC0 SVG under
## assets/first_party/card_icons/ named after the card id, logged in ASSETS.md), and the card row
## draws that icon plus the Kenney key tile of the key that picks the card. A card with no icon
## draws an empty slot, pushes no error and stays valid.

const CASTLE_PATH := "res://data/buildings/castle_center.tres"
const FIXTURE := "res://tests/fixtures/fixture_map_castle.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const ICON_DIR := "res://assets/first_party/card_icons/"
const KEY_TILE_DIR := "res://assets/third_party/kenney_input_prompts/keyboard_mouse/"
const ASSETS_MD := "res://ASSETS.md"
const CASTLE: StringName = &"castle_plot"
const CARD_COUNT: int = 12


func _castle_cards() -> Array[ChoiceDef]:
	var def: BuildingDef = load(CASTLE_PATH)
	var cards: Array[ChoiceDef] = []
	for tier: int in range(2, 5):
		cards.append_array(def.tier_def(tier).choices)
	return cards


func _context() -> RunContext:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate(true)
	map.starting_gold = 100
	return RunContext.new(map, load(TUNING))


## A card row that has drawn the four tier II cards, shown without a run behind it.
func _row_with(content: Array[Dictionary]) -> CardRow:
	var row: CardRow = CardRow.new()
	add_child_autofree(row)
	row._build_cards(content)
	row.visible = true
	return row


func test_the_castle_ladder_has_twelve_cards() -> void:
	assert_eq(_castle_cards().size(), CARD_COUNT, "four at each of the three upgrades")


func test_every_card_has_an_icon_named_after_its_id_under_the_first_party_folder() -> void:
	for card: ChoiceDef in _castle_cards():
		assert_not_null(card.icon, "%s has an icon" % card.id)
		if card.icon != null:
			var wanted: String = ICON_DIR + String(card.id) + ".svg"
			assert_eq(card.icon.resource_path, wanted, "%s: its own file" % card.id)


func test_every_icon_file_loads_as_a_texture_with_a_size() -> void:
	for card: ChoiceDef in _castle_cards():
		var path: String = ICON_DIR + String(card.id) + ".svg"
		assert_true(FileAccess.file_exists(path), "%s exists" % path)
		var texture: Texture2D = load(path) as Texture2D
		assert_not_null(texture, "%s imports as a texture" % path)
		if texture != null:
			assert_gt(texture.get_width(), 0, "%s has a width" % card.id)
			assert_gt(texture.get_height(), 0, "%s has a height" % card.id)


func test_no_two_cards_share_an_icon_file() -> void:
	var seen: Dictionary = {}
	for card: ChoiceDef in _castle_cards():
		if card.icon != null:
			seen[card.icon.resource_path] = true
	assert_eq(seen.size(), CARD_COUNT, "twelve cards, twelve icons")


func test_the_card_row_draws_each_cards_icon() -> void:
	var content: Array[Dictionary] = CardRowModel.cards(_context(), CASTLE, -1)
	var row: CardRow = _row_with(content)
	assert_eq(row.card_count(), 4, "four cards drawn")
	for index: int in range(content.size()):
		assert_not_null(row.icon_of(index), "card %d draws an icon" % (index + 1))
		assert_eq(row.icon_of(index), content[index]["icon"], "card %d: its own icon" % (index + 1))


func test_the_card_row_draws_the_kenney_key_tile_of_the_key_that_picks_each_card() -> void:
	var row: CardRow = _row_with(CardRowModel.cards(_context(), CASTLE, -1))
	for index: int in range(4):
		var tile: Sprite3D = row.get_node_or_null("Card%d/KeyTile" % (index + 1)) as Sprite3D
		assert_not_null(tile, "card %d has a key tile" % (index + 1))
		if tile != null:
			var wanted: String = KEY_TILE_DIR + "keyboard_%d.png" % (index + 1)
			assert_eq(
				tile.texture.resource_path, wanted, "card %d: key %d" % [index + 1, index + 1]
			)


func test_a_card_with_no_icon_draws_an_empty_slot_and_no_error() -> void:
	var content: Array[Dictionary] = CardRowModel.cards(_context(), CASTLE, -1)
	for card: Dictionary in content:
		card["icon"] = null
	var row: CardRow = _row_with(content)
	assert_eq(row.card_count(), 4, "the cards are still drawn")
	for index: int in range(4):
		assert_null(row.icon_of(index), "card %d has no icon" % (index + 1))
		assert_not_null(row.get_node_or_null("Card%d/IconSlot" % (index + 1)), "an empty slot")
		assert_null(row.get_node_or_null("Card%d/Icon" % (index + 1)), "and no sprite over it")


func test_icon_of_answers_null_for_an_index_that_addresses_no_card() -> void:
	var row: CardRow = _row_with(CardRowModel.cards(_context(), CASTLE, -1))
	assert_null(row.icon_of(-1), "negative")
	assert_null(row.icon_of(4), "past the last card")


func test_a_card_without_an_icon_still_validates() -> void:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	for building: BuildingDef in map.buildings:
		for tier: BuildingTierDef in building.tiers:
			for card: ChoiceDef in tier.choices:
				card.icon = null
	assert_eq(map.validate().size(), 0, "a null icon is an empty slot, not an error")


func test_the_assets_log_names_the_first_party_card_icons_as_cc0() -> void:
	var text: String = FileAccess.get_file_as_string(ASSETS_MD)
	var start: int = text.find("## First-party assets")
	assert_gt(start, -1, "ASSETS.md has a First-party assets section")
	var section: String = text.substr(maxi(start, 0))
	assert_true(section.contains("assets/first_party/card_icons/"), "it names the folder")
	assert_true(section.contains("CC0-1.0"), "and the licence")
	assert_false(
		section.contains("| Name |"), "prose bullets only: no table rows to confuse the log"
	)
