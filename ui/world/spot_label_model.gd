class_name SpotLabelModel
extends RefCounted
## Pure content of the world-space spot label (D-07): what holding at a spot would buy, at what
## cost and with what effect. Reads RunContext data only; it never mutates it and creates no Nodes.

const MAX_TIER_TEXT := "Max tier"


## Keys: title, cost, paid, effect, affordable, max_tier, status_line.
## `title` names the NEXT purchasable tier; at the top tier it is the current tier and
## `status_line` reads "Max tier". `paid` is `coins_paid` clamped to [0, cost]. `affordable` is
## true when the gold covers the cost or a hold there is already under way (a hold only starts
## when the price is payable), and always true when nothing is left to buy.
static func describe(ctx: RunContext, spot_id: StringName, coins_paid: int) -> Dictionary:
	var content: Dictionary = {
		"title": "",
		"cost": 0,
		"paid": 0,
		"effect": "",
		"affordable": false,
		"max_tier": false,
		"status_line": "",
	}
	var building_def: BuildingDef = ctx.buildings.get_building_def_for_spot(spot_id)
	if building_def == null:
		return content
	var tier: int = ctx.buildings.current_tier(spot_id)
	var next_tier: BuildingTierDef = building_def.tier_def(tier + 1)
	if next_tier == null:
		content["title"] = building_def.tier_label(tier)
		content["max_tier"] = true
		content["affordable"] = true
		content["status_line"] = MAX_TIER_TEXT
		return content
	content["title"] = building_def.tier_label(tier + 1)
	content["cost"] = next_tier.cost
	content["paid"] = clampi(coins_paid, 0, next_tier.cost)
	content["effect"] = next_tier.effect_line()
	content["affordable"] = ctx.economy.can_afford(next_tier.cost) or coins_paid > 0
	return content
