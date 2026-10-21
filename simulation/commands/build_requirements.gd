class_name BuildRequirements
extends RefCounted
## The one requirement check behind D-03 and D-10 (BLDG-09): whether the next tier of a plot is
## locked behind the castle's tier or behind another plot. Static and pure: it reads only public
## BuildingSystem getters, never mutates anything, and CommandProcessor calls it from validate_build
## right after MAX_TIER, before the price is looked at (a locked tier is locked whatever the gold).
## Castle requirements apply only on a map with a castle plot, so a fixture or replay map without
## one is never gated. A spot requirement applies to the plot's first build only.


## The castle plot's current tier, or 0 when the map has no castle plot.
static func castle_tier(map: MapConfig, buildings: BuildingSystem) -> int:
	var plot: BuildSpotDef = _castle_plot(map)
	if plot == null:
		return 0
	return buildings.current_tier(plot.id)


## CommandProcessor.OK, CASTLE_TIER when the next tier needs a higher castle than stands, or
## NEEDS_SPOT when the plot is still unbuilt and its required plot is below the required tier.
## OK too for an unknown spot or one with nothing left to buy: those have their own reasons.
static func rejection(map: MapConfig, buildings: BuildingSystem, spot_id: StringName) -> StringName:
	var spot: BuildSpotDef = buildings.get_spot(spot_id)
	var building_def: BuildingDef = buildings.get_building_def_for_spot(spot_id)
	if spot == null or building_def == null:
		return CommandProcessor.OK
	var tier: int = buildings.current_tier(spot_id)
	var next_tier: BuildingTierDef = building_def.tier_def(tier + 1)
	if next_tier == null:
		return CommandProcessor.OK
	var needed: int = next_tier.requires_castle_tier
	if needed > 0 and _castle_plot(map) != null and castle_tier(map, buildings) < needed:
		return CommandProcessor.CASTLE_TIER
	if tier == 0 and spot.requires_spot != &"":
		if buildings.current_tier(spot.requires_spot) < spot.requires_spot_tier:
			return CommandProcessor.NEEDS_SPOT
	return CommandProcessor.OK


## The map's castle plot, or null when it has none.
static func _castle_plot(map: MapConfig) -> BuildSpotDef:
	for spot: BuildSpotDef in map.spots:
		if spot != null and spot.is_castle:
			return spot
	return null
