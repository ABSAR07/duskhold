class_name ChoiceValidation
extends RefCounted
## What MapConfig.validate() says about branching-choice cards (T-05-07, T-05-08): one readable
## string per problem, so bad card data is reported instead of armed. It walks every tier of every
## building and reports a null or empty-id choice, a card id that appears twice anywhere in the map
## (once, naming both places: a card is offered once per run, D-02), a card with no name or no
## modifiers, a name over MAX_NAME_LENGTH or a flavour over MAX_FLAVOUR_LENGTH (counted with
## String.length(), Unicode code points), every problem of every modifier, and, for the castle
## plot's building, a tier above I that does not offer exactly CASTLE_CHOICES_PER_TIER cards (D-01,
## one pick of four). Pure: it reads the map and never mutates it.

const MAX_NAME_LENGTH: int = 24
const MAX_FLAVOUR_LENGTH: int = 70
const CASTLE_CHOICES_PER_TIER: int = 4


## Every card problem of `map`, in building and tier order; empty when its cards are well formed.
static func problems(map: MapConfig) -> Array[String]:
	var out: Array[String] = []
	var places: Dictionary = {}
	var reported: Dictionary = {}
	for building_def: BuildingDef in map.buildings:
		if building_def == null:
			continue
		for index: int in range(building_def.tiers.size()):
			var tier: BuildingTierDef = building_def.tiers[index]
			if tier == null:
				continue
			var place: String = "building '%s' tier %d" % [building_def.id, index + 1]
			for card: ChoiceDef in tier.choices:
				if card == null:
					out.append("%s has an empty choice entry" % place)
					continue
				_check_id(card, place, places, reported, out)
				_check_text(card, out)
				_check_modifiers(card, out)
	_check_castle_counts(map, out)
	return out


## An empty id, or an id already seen at another place (reported once, naming both places).
static func _check_id(
	card: ChoiceDef, place: String, places: Dictionary, reported: Dictionary, out: Array[String]
) -> void:
	if card.id == &"":
		out.append("%s has a choice with an empty id" % place)
		return
	if not places.has(card.id):
		places[card.id] = place
		return
	if reported.has(card.id):
		return
	reported[card.id] = true
	out.append("card id '%s' appears twice: %s and %s" % [card.id, places[card.id], place])


## The name and the flavour line: present (the name) and within their length limits.
static func _check_text(card: ChoiceDef, out: Array[String]) -> void:
	if card.display_name.is_empty():
		out.append("card '%s' has no name" % card.id)
	elif card.display_name.length() > MAX_NAME_LENGTH:
		out.append(
			(
				"card '%s' name is %d characters, at most %d"
				% [card.id, card.display_name.length(), MAX_NAME_LENGTH]
			)
		)
	if card.flavour.length() > MAX_FLAVOUR_LENGTH:
		out.append(
			(
				"card '%s' flavour is %d characters, at most %d"
				% [card.id, card.flavour.length(), MAX_FLAVOUR_LENGTH]
			)
		)


## At least one modifier, and every modifier valid (an unknown stat id or a value out of range).
static func _check_modifiers(card: ChoiceDef, out: Array[String]) -> void:
	if card.modifiers.is_empty():
		out.append("card '%s' has no modifiers" % card.id)
	for modifier: StatModifierDef in card.modifiers:
		if modifier == null:
			out.append("card '%s' has an empty modifier entry" % card.id)
			continue
		for problem: String in modifier.problems():
			out.append("card '%s': %s" % [card.id, problem])


## Each tier above I of the castle plot's building offers exactly CASTLE_CHOICES_PER_TIER cards.
static func _check_castle_counts(map: MapConfig, out: Array[String]) -> void:
	var checked: Dictionary = {}
	for spot: BuildSpotDef in map.spots:
		if spot == null or not spot.is_castle or checked.has(spot.building_id):
			continue
		checked[spot.building_id] = true
		for building_def: BuildingDef in map.buildings:
			if building_def == null or building_def.id != spot.building_id:
				continue
			for index: int in range(1, building_def.tiers.size()):
				var tier: BuildingTierDef = building_def.tiers[index]
				if tier != null and tier.choices.size() != CASTLE_CHOICES_PER_TIER:
					out.append(
						(
							"castle building '%s' tier %d has %d cards, expected %d"
							% [
								building_def.id,
								index + 1,
								tier.choices.size(),
								CASTLE_CHOICES_PER_TIER
							]
						)
					)
