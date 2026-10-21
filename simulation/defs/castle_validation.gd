class_name CastleValidation
extends RefCounted
## What MapConfig.validate() says about the castle plot (T-05-07, BLDG-08, D-01, D-04): the castle
## building must have at least two tiers (tier I is the map's own castle, the upgrades are bought),
## its tier I must carry no cards (tier I is never bought, so a card there could never be picked),
## and the plot must lie within MAX_PLOT_DISTANCE_M of the keep's edge. More than one castle plot,
## a castle plot that is also a wall plot and a plot naming an unknown building are already
## reported by MapConfig.validate() itself, so they are not repeated here. Pure: it reads the map
## and never mutates it. Only `+ - * /` and comparisons are used.

## How far beyond the keep's radius the castle plot may stand, in metres.
const MAX_PLOT_DISTANCE_M: float = 3.0


## Every castle-plot problem of `map`; empty when the castle plot is well formed.
static func problems(map: MapConfig) -> Array[String]:
	var out: Array[String] = []
	for spot: BuildSpotDef in map.spots:
		if spot == null or not spot.is_castle:
			continue
		_check_building(map, spot, out)
		_check_distance(map, spot, out)
	return out


## The plot's building has two tiers or more, and its tier I carries no cards. An unknown building
## id is MapConfig's own report.
static func _check_building(map: MapConfig, spot: BuildSpotDef, out: Array[String]) -> void:
	for building_def: BuildingDef in map.buildings:
		if building_def == null or building_def.id != spot.building_id:
			continue
		if building_def.tiers.size() < 2:
			out.append("castle building '%s' has fewer than two tiers" % building_def.id)
		var first: BuildingTierDef = (
			building_def.tiers[0] if not building_def.tiers.is_empty() else null
		)
		if first != null and not first.choices.is_empty():
			out.append(
				(
					"castle building '%s' tier 1 carries cards, but tier I is never bought"
					% building_def.id
				)
			)
		return


## The plot lies within castle_radius + MAX_PLOT_DISTANCE_M of the castle, on the ground plane. A
## radius that is not a positive finite number is MapConfig's own report, so it is not measured.
static func _check_distance(map: MapConfig, spot: BuildSpotDef, out: Array[String]) -> void:
	if not is_finite(map.castle_radius) or map.castle_radius <= 0.0:
		return
	var dx: float = spot.position.x - map.castle_position.x
	var dz: float = spot.position.z - map.castle_position.z
	var limit: float = map.castle_radius + MAX_PLOT_DISTANCE_M
	if dx * dx + dz * dz > limit * limit:
		out.append(
			(
				"castle plot '%s' is more than %s m from the castle (%s m at most from its centre)"
				% [spot.id, MAX_PLOT_DISTANCE_M, limit]
			)
		)
