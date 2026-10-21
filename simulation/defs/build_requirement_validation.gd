class_name BuildRequirementValidation
extends RefCounted
## What MapConfig.validate() says about build requirements (T-05-11, BLDG-09, D-03, D-10, Pitfall
## 9): one readable string per requirement that can never be met, so impossible gating is reported
## instead of silently locking a plot for good. Reported: a castle tier requirement below 0, or
## above the castle building's top tier (only on a map with a castle plot: without one a castle
## requirement never applies); a tier of the castle's own building that needs the castle at its own
## tier or higher (the castle would have to be bought before itself); a requires_spot naming the
## plot itself or a spot the map does not have; a requires_spot_tier outside 1..the required
## building's top tier; and a requirement cycle, reported once. Pure: it reads the map and never
## mutates it.


## Every requirement problem of `map`, in building, then spot, then cycle order; empty when well
## formed.
static func problems(map: MapConfig) -> Array[String]:
	var out: Array[String] = []
	var castle_building: BuildingDef = _castle_building(map)
	for building_def: BuildingDef in map.buildings:
		if building_def != null:
			_check_castle_tiers(building_def, building_def == castle_building, castle_building, out)
	var by_id: Dictionary = {}
	for spot: BuildSpotDef in map.spots:
		if spot != null and not by_id.has(spot.id):
			by_id[spot.id] = spot
	for spot: BuildSpotDef in map.spots:
		if spot != null and spot.requires_spot != &"":
			_check_spot(map, spot, by_id, out)
	_check_cycles(map, by_id, out)
	return out


## The building of the map's castle plot, or null when there is no plot or its building is unknown.
static func _castle_building(map: MapConfig) -> BuildingDef:
	for spot: BuildSpotDef in map.spots:
		if spot == null or not spot.is_castle:
			continue
		for building_def: BuildingDef in map.buildings:
			if building_def != null and building_def.id == spot.building_id:
				return building_def
		return null
	return null


## Each tier's requires_castle_tier: never negative; at most the castle's top tier when the map has
## a castle plot; and, for the castle's own building, below the tier itself.
static func _check_castle_tiers(
	building_def: BuildingDef, is_castle: bool, castle_building: BuildingDef, out: Array[String]
) -> void:
	for index: int in range(building_def.tiers.size()):
		var tier: BuildingTierDef = building_def.tiers[index]
		if tier == null:
			continue
		var place: String = "building '%s' tier %d" % [building_def.id, index + 1]
		var needed: int = tier.requires_castle_tier
		if needed < 0:
			out.append("%s requires castle tier %d, expected 0 or more" % [place, needed])
		elif castle_building != null and needed > castle_building.max_tier():
			out.append(
				(
					"%s requires castle tier %d, but the castle has only %d tiers"
					% [place, needed, castle_building.max_tier()]
				)
			)
		elif is_castle and index >= 1 and needed > index:
			out.append(
				(
					"castle %s requires castle tier %d, which is not below the tier itself"
					% [place, needed]
				)
			)


## One spot's requires_spot: not the plot itself, a spot the map has, and a tier within the required
## building's tiers. An unknown building is MapConfig's own report, so its tiers are not measured.
static func _check_spot(
	map: MapConfig, spot: BuildSpotDef, by_id: Dictionary, out: Array[String]
) -> void:
	if spot.requires_spot == spot.id:
		out.append("spot '%s' requires itself" % spot.id)
		return
	if not by_id.has(spot.requires_spot):
		out.append(
			(
				"spot '%s' requires spot '%s', which the map does not have"
				% [spot.id, spot.requires_spot]
			)
		)
		return
	var required: BuildSpotDef = by_id[spot.requires_spot]
	for building_def: BuildingDef in map.buildings:
		if building_def == null or building_def.id != required.building_id:
			continue
		if spot.requires_spot_tier < 1 or spot.requires_spot_tier > building_def.max_tier():
			out.append(
				(
					"spot '%s' requires spot '%s' at tier %d, expected 1 to %d"
					% [spot.id, required.id, spot.requires_spot_tier, building_def.max_tier()]
				)
			)
		return


## A cycle in the requires_spot chains, each reported once with its members in chain order. Each
## spot has at most one requirement, so a depth-first walk in MapConfig order finds every cycle. A
## plot that requires itself is already reported by _check_spot and is not a cycle here.
static func _check_cycles(map: MapConfig, by_id: Dictionary, out: Array[String]) -> void:
	var state: Dictionary = {}
	for start: BuildSpotDef in map.spots:
		if start == null or state.has(start.id):
			continue
		var path: Array[StringName] = []
		var current: StringName = start.id
		while current != &"" and not state.has(current):
			state[current] = 1
			path.append(current)
			current = _next_required(by_id, current)
		if current != &"" and state[current] == 1:
			var members: PackedStringArray = PackedStringArray()
			for spot_id: StringName in path.slice(path.find(current)):
				members.append(String(spot_id))
			out.append(
				(
					"spots %s require each other in a cycle: %s -> %s"
					% [", ".join(members), " -> ".join(members), members[0]]
				)
			)
		for spot_id: StringName in path:
			state[spot_id] = 2


## The spot `spot_id` requires, or &"" when it requires none, itself, or a spot the map lacks.
static func _next_required(by_id: Dictionary, spot_id: StringName) -> StringName:
	var spot: BuildSpotDef = by_id.get(spot_id) as BuildSpotDef
	if spot == null or spot.requires_spot == spot_id or not by_id.has(spot.requires_spot):
		return &""
	return spot.requires_spot
