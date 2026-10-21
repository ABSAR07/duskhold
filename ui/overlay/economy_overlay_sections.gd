class_name EconomyOverlaySections
extends RefCounted
## The debug overlay's Economy section (ECON-03, DEV-03): the castle's tier with the names of the
## cards picked there, and one row per standing declining building (the Gold Mine) with the dawns it
## has paid and what it pays next. Read-only: every row builder is a pure read of the RunContext, so
## collecting them emits no event and changes no simulation value. `register` hooks the section into
## a DebugOverlay after the Stats section. Plans 05-08 and 05-09 add the Harbor and Shrine rows.

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
## none", or "no tiers" on a map without a castle plot), then one "<spot>: paid N, next M" row for
## each declining building that stands on its plot, in MapConfig order.
static func economy_rows(ctx: RunContext) -> Array:
	var rows: Array = [[CASTLE_LABEL, _castle_text(ctx)]]
	for spot_id: StringName in ctx.buildings.spot_ids():
		var building_def: BuildingDef = ctx.buildings.get_building_def_for_spot(spot_id)
		if building_def == null or building_def.income_curve != BuildingDef.IncomeCurve.DECLINING:
			continue
		if ctx.buildings.current_tier(spot_id) < 1:
			continue
		var paid: int = ctx.income.mine_paid_dawns(spot_id)
		rows.append([String(spot_id), "paid %d, next %d" % [paid, ctx.income.next_payout(spot_id)]])
	return rows


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
