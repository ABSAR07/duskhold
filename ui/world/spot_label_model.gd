class_name SpotLabelModel
extends RefCounted
## Pure content of the world-space spot label (D-07): what holding at a spot would buy, at what
## cost and with what effect. Reads RunContext data only; it never mutates it and creates no Nodes.

const MAX_TIER_TEXT := "Max tier"


## Keys: title, cost, paid, effect, affordable, max_tier, status_line, picks.
## `title` names the NEXT purchasable tier; at the top tier it is the current tier and
## `status_line` reads "Max tier". `paid` is `coins_paid` clamped to [0, cost]. `affordable` is
## true when the gold covers the cost or a hold there is already under way (a hold only starts
## when the price is payable), and always true when nothing is left to buy. `picks` lists the
## display names of the cards picked at this plot in pick order joined with " · " (empty for a plot
## with none). The castle plot's `effect` reads its numbers through the stat stack, so the label
## shows what the castle will be, not the raw tier values. A declining building (the Gold Mine)
## says how its payout falls before it is built and, once built, what it pays at the next dawn. A
## Fishing Harbor at its top tier reads its boats and the next dawn's gold ("Boats 2 of 5, next
## dawn 3 gold"). A Shrine reads "Asleep: 30 of 100 enemy health" until it wakes, then "Awake". A
## next tier locked behind the castle or another plot (D-03, D-10) reads "Needs
## Castle II" / "Needs a Mill" in `status_line` with cost 0 and `affordable` true, so no price and
## no red coins show.
static func describe(ctx: RunContext, spot_id: StringName, coins_paid: int) -> Dictionary:
	var content: Dictionary = {
		"title": "",
		"cost": 0,
		"paid": 0,
		"effect": "",
		"affordable": false,
		"max_tier": false,
		"status_line": "",
		"picks": "",
	}
	var building_def: BuildingDef = ctx.buildings.get_building_def_for_spot(spot_id)
	if building_def == null:
		return content
	content["picks"] = _picks_line(ctx, spot_id)
	var tier: int = ctx.buildings.current_tier(spot_id)
	var next_tier: BuildingTierDef = building_def.tier_def(tier + 1)
	var run: WallRunDef = ctx.buildings.get_spot(spot_id).wall_run
	if next_tier == null:
		content["title"] = building_def.tier_label(tier)
		if run != null:
			content["effect"] = _wall_effect(run, building_def.tier_def(tier))
		elif building_def.income_curve == BuildingDef.IncomeCurve.DECLINING and ctx.income != null:
			content["effect"] = "Next dawn: %d gold" % ctx.income.next_payout(spot_id)
		elif building_def.income_curve == BuildingDef.IncomeCurve.BOATS and ctx.income != null:
			content["effect"] = (
				"Boats %d of %d, next dawn %d gold"
				% [
					ctx.income.boats_of(spot_id),
					building_def.tier_def(tier).boat_cap,
					ctx.income.next_payout(spot_id)
				]
			)
		elif building_def.income_curve == BuildingDef.IncomeCurve.AWAKENED and ctx.income != null:
			content["effect"] = _shrine_effect(ctx, spot_id, building_def.tier_def(tier))
		content["max_tier"] = true
		content["affordable"] = true
		content["status_line"] = MAX_TIER_TEXT
		return content
	content["title"] = building_def.tier_label(tier + 1)
	if run != null:
		content["effect"] = _wall_effect(run, next_tier)
	elif ctx.buildings.get_spot(spot_id).is_castle:
		content["effect"] = _castle_effect(ctx, next_tier)
	else:
		content["effect"] = building_def.tier_effect_line(tier + 1)
	var locked_line: String = _locked_line(ctx, spot_id, next_tier)
	if not locked_line.is_empty():
		content["status_line"] = locked_line
		content["affordable"] = true
		return content
	content["cost"] = next_tier.cost
	content["paid"] = clampi(coins_paid, 0, next_tier.cost)
	content["affordable"] = ctx.economy.can_afford(next_tier.cost) or coins_paid > 0
	return content


## "Needs Castle II" or "Needs a Mill" while the next purchase is locked behind the castle or behind
## another plot (D-03, D-10), else "". A locked plot shows no price (cost 0, so no coins) and is
## never red: it is not dear, it is closed. Read from the same gate the hold uses, so the label and
## the denied bump can never disagree.
static func _locked_line(ctx: RunContext, spot_id: StringName, tier: BuildingTierDef) -> String:
	var reason: StringName = ctx.commands.validate_build(spot_id)
	if reason == CommandProcessor.CASTLE_TIER:
		var numerals: Array[String] = BuildingDef.ROMAN_NUMERALS
		var needed: int = clampi(tier.requires_castle_tier, 1, numerals.size())
		return "Needs Castle %s" % numerals[needed - 1]
	if reason == CommandProcessor.NEEDS_SPOT:
		var required: BuildingDef = ctx.buildings.get_building_def_for_spot(
			ctx.buildings.get_spot(spot_id).requires_spot
		)
		return "Needs a %s" % (required.display_name if required != null else "building")
	return ""


## "12 segments, 3000 health each": what a wall plot's run is at the given tier. The segment count
## belongs to the plot's run and the health to the tier, so this lives here, not in effect_line().
static func _wall_effect(run: WallRunDef, tier: BuildingTierDef) -> String:
	if tier == null:
		return ""
	return "%d segments, %d health each" % [run.segment_count(), tier.max_health]


## "Health 10000 · Arrow 300 · 2 gold at dawn": what the castle becomes at `tier`, each number read
## through the stat stack (castle.max_health, castle.arrow_damage, castle.base_income) so a picked
## card that changes it shows in the label. Income never reads below 0, as at the dawn payout.
static func _castle_effect(ctx: RunContext, tier: BuildingTierDef) -> String:
	var stack: StatStack = ctx.stat_stack
	var health: int = stack.int_value(&"castle.max_health", tier.max_health)
	var arrow: int = stack.int_value(&"castle.arrow_damage", tier.attack_damage)
	var income: int = maxi(stack.int_value(&"castle.base_income", tier.dawn_income), 0)
	return "Health %d · Arrow %d · %d gold at dawn" % [health, arrow, income]


## "Asleep: 3000 of 10000 enemy health" while the Shrine is dormant, "Awake" once it has woken.
static func _shrine_effect(ctx: RunContext, spot_id: StringName, tier: BuildingTierDef) -> String:
	if ctx.income.is_awake(spot_id):
		return "Awake"
	return (
		"Asleep: %d of %d enemy health" % [ctx.income.kill_credit(spot_id), tier.wake_threshold_hp]
	)


## The names of the cards picked at the plot in pick order, joined with " · ". A card the map no
## longer lists reads as its id.
static func _picks_line(ctx: RunContext, spot_id: StringName) -> String:
	var names: PackedStringArray = PackedStringArray()
	for choice_id: StringName in ctx.choices.picks_of(spot_id):
		var card: ChoiceDef = ctx.choices.find_choice(choice_id)
		names.append(card.display_name if card != null else String(choice_id))
	return " · ".join(names)
