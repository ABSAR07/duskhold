class_name CardRowModel
extends RefCounted
## Pure content of the world-space card row (UI-02, D-06, D-07): which cards the next tier of a spot
## offers, in the tier's authored order, and which one is highlighted, plus the mouse hit test on
## the cards' screen rectangles. Reads RunContext data only; it never mutates it and creates no
## Nodes.


## The cards the next tier on `spot_id` is bought with, left to right in the authored order. Each is
## a Dictionary with the keys id, name, flavour, effect_line (the exact numbers, generated from the
## card's modifiers), icon (Texture2D or null), key_hint (the digit 1 to 4 that picks it) and
## highlighted (true for the card at `highlighted_index` only). Empty for an unknown spot, a tier
## with no cards or a building at its top tier.
static func cards(
	ctx: RunContext, spot_id: StringName, highlighted_index: int
) -> Array[Dictionary]:
	var shown: Array[Dictionary] = []
	var building_def: BuildingDef = ctx.buildings.get_building_def_for_spot(spot_id)
	if building_def == null:
		return shown
	var tier_def: BuildingTierDef = building_def.tier_def(ctx.buildings.current_tier(spot_id) + 1)
	if tier_def == null:
		return shown
	for card: ChoiceDef in tier_def.choices:
		if card == null:
			continue
		(
			shown
			. append(
				{
					"id": card.id,
					"name": card.display_name,
					"flavour": card.flavour,
					"effect_line": card.effect_line(),
					"icon": card.icon,
					"key_hint": shown.size() + 1,
					"highlighted": shown.size() == highlighted_index,
				}
			)
		)
	return shown


## The card index (0-based) the digit key `digit` (1 to 9) addresses among `count` cards; -1 for a
## digit that addresses none (0, or above the card count).
static func index_for_digit(digit: int, count: int) -> int:
	if digit < 1 or digit > count:
		return -1
	return digit - 1


## The index of the first rectangle in `rects` that contains `point`, edges included, so a point on
## an edge two cards share belongs to the lower index and so does a point inside two overlapping
## cards; -1 when no rectangle contains it. The rectangles are the cards' screen rectangles in card
## order (CardRow.card_rects).
static func hit_test(rects: Array[Rect2], point: Vector2) -> int:
	for index: int in range(rects.size()):
		var rect: Rect2 = rects[index]
		if (
			point.x >= rect.position.x
			and point.x <= rect.end.x
			and point.y >= rect.position.y
			and point.y <= rect.end.y
		):
			return index
	return -1
