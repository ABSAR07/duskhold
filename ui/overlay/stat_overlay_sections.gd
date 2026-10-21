class_name StatOverlaySections
extends RefCounted
## The debug overlay's Stats section (META-08, D-15): one row per stat that has a modifier, with its
## base and final value. Every row builder is a pure read of the RunContext's StatStack and of
## building data: collecting them emits no event and never calls add_source or remove_source
## (T-05-03). `register` hooks the section into a DebugOverlay after the squad section.

const STATS_TITLE := "Stats"
## The row shown when no stat has a modifier.
const NO_MODIFIERS_LABEL := "no modifiers"
## The value of the no-modifiers row.
const NONE_TEXT := "—"
## The stat ids whose base is read from the first standing attacking building.
const TOWER_DAMAGE := &"tower.damage"
const TOWER_RANGE := &"tower.range"


## Registers the Stats section with `overlay`; it lists after the sections registered before it.
static func register(overlay: DebugOverlay, ctx: RunContext, _map_root: MapRoot) -> void:
	overlay.register_section(
		STATS_TITLE, func() -> Array: return StatOverlaySections.stat_rows(ctx)
	)


## One [stat id, "<base> -> <final>"] row per modified stat, sorted by id. A stat with no single
## base (it differs per building or tier) prints its bucket sums instead: "flat +N, pct +N%, xM".
## One ["no modifiers", dash] row when the stack is empty.
static func stat_rows(ctx: RunContext) -> Array:
	var rows: Array = []
	var stack: StatStack = ctx.stat_stack
	for stat: StringName in stack.modified_stats():
		rows.append([String(stat), _value_text(ctx, stat)])
	if rows.is_empty():
		rows.append([NO_MODIFIERS_LABEL, NONE_TEXT])
	return rows


static func _value_text(ctx: RunContext, stat: StringName) -> String:
	var tier: BuildingTierDef = _first_standing_attacker_tier(ctx)
	if tier != null and stat == TOWER_DAMAGE:
		return "%d -> %d" % [tier.attack_damage, ctx.stat_stack.int_value(stat, tier.attack_damage)]
	if tier != null and stat == TOWER_RANGE:
		return (
			"%.2f -> %.2f"
			% [tier.attack_range, ctx.stat_stack.float_value(stat, tier.attack_range)]
		)
	var sums: Dictionary = ctx.stat_stack.sums_of(stat)
	var text: String = "flat %+d, pct %+d%%" % [int(sums["flat"]), int(sums["pct"])]
	for mult: int in sums["mults"]:
		text += ", x%s" % StatModifierDef.multiplier_text(mult)
	return text


## The current tier of the first standing building that attacks through the tower stats (a Shrine
## reads shrine.damage, so it is not one), in plot order; null when none.
static func _first_standing_attacker_tier(ctx: RunContext) -> BuildingTierDef:
	for spot_id: StringName in ctx.buildings.standing_spot_ids():
		var building: BuildingDef = ctx.buildings.get_building_def_for_spot(spot_id)
		if building == null or building.damage_stat != TOWER_DAMAGE:
			continue
		var tier: BuildingTierDef = building.tier_def(ctx.buildings.current_tier(spot_id))
		if tier != null and tier.attack_damage > 0:
			return tier
	return null
