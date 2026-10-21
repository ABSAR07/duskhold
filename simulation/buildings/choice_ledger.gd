class_name ChoiceLedger
extends RefCounted
## Which card was picked at which spot, and the arming of its modifiers (BLDG-05, D-05). Listens to
## choice_picked, which CommandProcessor emits right after the building_built of the purchase, finds
## the card in that spot's tier, hands its modifiers to the StatStack under the card's id (so the
## picked card is a named source, active once for the rest of the run) and remembers the pick.
## A pick is permanent: nothing here removes a source, and a card that is not offered at the spot's
## tier (CommandProcessor refuses it first) arms nothing.
## RefCounted, no tree and no clock: it is part of the replayable simulation.

var _buildings: BuildingSystem
var _stats: StatStack
var _map: MapConfig
## spot id -> picked card ids in pick order.
var _picks: Dictionary = {}
var _all: Array[StringName] = []


func _init(
	map: MapConfig, buildings: BuildingSystem, events: SimEvents, stat_stack: StatStack
) -> void:
	_map = map
	_buildings = buildings
	_stats = stat_stack
	events.choice_picked.connect(_on_choice_picked)


## The cards picked at the spot, in pick order. A copy; empty for a spot with none.
func picks_of(spot_id: StringName) -> Array[StringName]:
	var picked: Array[StringName] = []
	picked.assign(_picks.get(spot_id, []))
	return picked


## Every card picked this run, in pick order. A copy.
func all_picks() -> Array[StringName]:
	return _all.duplicate()


## The card with that id among every card of every building tier of the map; null when none has it.
func find_choice(choice_id: StringName) -> ChoiceDef:
	if choice_id == &"":
		return null
	for building_def: BuildingDef in _map.buildings:
		if building_def == null:
			continue
		for tier_def: BuildingTierDef in building_def.tiers:
			var card: ChoiceDef = _card_in(tier_def, choice_id)
			if card != null:
				return card
	return null


## The card of `tier_def` with that id; null when the tier is empty or has no such card.
func _card_in(tier_def: BuildingTierDef, choice_id: StringName) -> ChoiceDef:
	if tier_def == null:
		return null
	for card: ChoiceDef in tier_def.choices:
		if card != null and card.id == choice_id:
			return card
	return null


func _on_choice_picked(spot_id: StringName, tier: int, choice_id: StringName) -> void:
	var building_def: BuildingDef = _buildings.get_building_def_for_spot(spot_id)
	if building_def == null:
		return
	var card: ChoiceDef = _card_in(building_def.tier_def(tier), choice_id)
	if card == null:
		return
	_stats.add_source(choice_id, card.modifiers)
	if not _picks.has(spot_id):
		_picks[spot_id] = []
	(_picks[spot_id] as Array).append(choice_id)
	_all.append(choice_id)
