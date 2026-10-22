class_name EconomyOverlaySections
extends RefCounted
## The debug overlay's Economy section (ECON-03, ECON-05, ECON-06, DEV-03): the castle's tier with
## the names of the cards picked there, one row per standing declining building (the Gold Mine) with
## the dawns it has paid and what it pays next, one row per standing Fishing Harbor with its boats
## and its cap, and one row per built Shrine with its credit. Read-only: every row builder is a pure
## read of the RunContext, so collecting them emits no event and changes no simulation value.
## `register` hooks the section into a DebugOverlay after the Stats section.

const ECONOMY_TITLE := "Economy"
## The label of the castle row, and the value it shows on a map that has no castle plot.
const CASTLE_LABEL := "castle"
const NO_TIERS_TEXT := "no tiers"
## The picks text before any card has been picked.
const NO_PICKS_TEXT := "none"


## Registers the Economy section with `overlay`; it lists after the sections registered before it.
static func register(overlay: DebugOverlay, ctx: RunContext, _map_root: MapRoot) -> void:
	overlay.register_section(
		ECONOMY_TITLE, func() -> Array: return EconomyOverlaySections.economy_rows(ctx)
	)


## [label, value] rows, never empty: the castle row ("tier 2, picks Royal Training", "tier 1, picks
## none", or "no tiers" on a map without a castle plot), then, in MapConfig order, one "<spot>: paid
## N, next M" row for each declining building, one "<spot>: boats N of M" row for each Fishing
## Harbor that stands on its plot, and one "<spot>: asleep C of T" or "<spot>: awake C" row for
## each Shrine that has been built, standing or fallen (C is its credit, T its threshold).
static func economy_rows(ctx: RunContext) -> Array:
	var rows: Array = [[CASTLE_LABEL, _castle_text(ctx)]]
	for spot_id: StringName in ctx.buildings.spot_ids():
		var building_def: BuildingDef = ctx.buildings.get_building_def_for_spot(spot_id)
		var tier: int = ctx.buildings.current_tier(spot_id)
		if building_def == null or tier < 1:
			continue
		if building_def.income_curve == BuildingDef.IncomeCurve.DECLINING:
			var paid: int = ctx.income.mine_paid_dawns(spot_id)
			var next: int = ctx.income.next_payout(spot_id)
			rows.append([String(spot_id), "paid %d, next %d" % [paid, next]])
		elif building_def.income_curve == BuildingDef.IncomeCurve.BOATS:
			var cap: int = building_def.tier_def(tier).boat_cap
			rows.append([String(spot_id), "boats %d of %d" % [ctx.income.boats_of(spot_id), cap]])
		elif building_def.income_curve == BuildingDef.IncomeCurve.AWAKENED:
			rows.append([String(spot_id), _shrine_text(ctx, spot_id, building_def.tier_def(tier))])
	return rows


## "asleep 30 of 100" while the Shrine has not woken, "awake 112" once it has: its credit so far.
static func _shrine_text(ctx: RunContext, spot_id: StringName, tier: BuildingTierDef) -> String:
	var credit: int = ctx.income.kill_credit(spot_id)
	if ctx.income.is_awake(spot_id):
		return "awake %d" % credit
	return "asleep %d of %d" % [credit, tier.wake_threshold_hp]


## "tier 2, picks Royal Training": the castle's tier and the picked cards' names in pick order.
static func _castle_text(ctx: RunContext) -> String:
	if not ctx.castle.has_tiers():
		return NO_TIERS_TEXT
	var names: PackedStringArray = PackedStringArray()
	for choice_id: StringName in ctx.choices.picks_of(ctx.castle.plot_id()):
		var card: ChoiceDef = ctx.choices.find_choice(choice_id)
		names.append(card.display_name if card != null else String(choice_id))
	var picks: String = ", ".join(names) if not names.is_empty() else NO_PICKS_TEXT
	return "tier %d, picks %s" % [ctx.castle.tier(), picks]
