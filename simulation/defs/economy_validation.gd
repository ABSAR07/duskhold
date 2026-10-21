class_name EconomyValidation
extends RefCounted
## What MapConfig.validate() says about income-curve and pond data (T-05-13, T-05-16, ECON-03,
## ECON-05, D-11, D-12): one readable string per problem, so bad numbers are reported instead of
## armed.
##
## A DECLINING building (the Gold Mine) needs, on every tier, an income_step and an income_floor of
## 1 or more (a payout that never falls, or one that falls to 0, breaks D-12), a first payout
## (dawn_income) that is not below its floor, and no curve value above MAX_CURVE_VALUE. A BOATS
## building (the Fishing Harbor) needs, on every tier, a boat_cap of 1 to MAX_BOAT_CAP and a
## boat_income of 1 to MAX_CURVE_VALUE. A building whose curve does not use a field must leave it at
## 0: a value there is a field set on the wrong curve.
##
## The pond (D-11) is visual only, but its numbers size a mesh and its place must stay clear of the
## play: a centre and radius that are finite, a radius of 0 to MAX_POND_RADIUS (0 means no pond), no
## plot and no spawn point inside the water, and every spawn-to-castle road segment at least
## pond_radius + POND_ROAD_CLEARANCE metres from the centre. Plan 05-09 extends this for the
## Shrine's wake data. Pure: it reads the map and never mutates it.

## The largest value any curve field may hold. Keeps every payout well inside an int.
const MAX_CURVE_VALUE: int = 1000
## The most boats a Fishing Harbor tier may hold (ECON-05): keeps the boat views and payout small.
const MAX_BOAT_CAP: int = 20
## The largest pond radius in metres (D-11); the water disc is a mesh sized from it.
const MAX_POND_RADIUS: float = 30.0
## The clear water kept between the pond's edge and every spawn-to-castle road segment, in metres.
const POND_ROAD_CLEARANCE: float = 10.0
## The widest wake radius in metres, the largest wake threshold in enemy health and the largest
## synergy percent a Shrine tier may hold (ECON-06, T-05-17).
const MAX_WAKE_RADIUS: float = 40.0
const MAX_WAKE_THRESHOLD: int = 100000
const MAX_SYNERGY_PERCENT: int = 100


## Every curve and pond problem of `map`, in building and tier order and then the pond's; empty when
## the data is well formed. A null building or tier is skipped: the other helpers report those.
static func problems(map: MapConfig) -> Array[String]:
	var out: Array[String] = []
	for building_def: BuildingDef in map.buildings:
		if building_def == null:
			continue
		for index: int in range(building_def.tiers.size()):
			var tier: BuildingTierDef = building_def.tiers[index]
			if tier == null:
				continue
			var place: String = "building '%s' tier %d" % [building_def.id, index + 1]
			if building_def.income_curve == BuildingDef.IncomeCurve.DECLINING:
				_check_declining(place, tier, out)
			elif building_def.income_curve == BuildingDef.IncomeCurve.BOATS:
				_check_boats(place, tier, out)
			_check_unused(building_def, place, tier, out)
	_check_pond(map, out)
	return out


## A declining tier: step and floor in 1..MAX_CURVE_VALUE, the first payout at most MAX_CURVE_VALUE
## and not below the floor.
static func _check_declining(place: String, tier: BuildingTierDef, out: Array[String]) -> void:
	for field: String in ["income_step", "income_floor"]:
		var value: int = tier.get(field)
		if value < 1 or value > MAX_CURVE_VALUE:
			out.append("%s %s is %d, expected 1 to %d" % [place, field, value, MAX_CURVE_VALUE])
	if tier.dawn_income > MAX_CURVE_VALUE:
		out.append(
			"%s dawn_income is %d, expected at most %d" % [place, tier.dawn_income, MAX_CURVE_VALUE]
		)
	if tier.income_floor >= 1 and tier.dawn_income < tier.income_floor:
		out.append(
			(
				"%s dawn_income %d is below its income_floor %d"
				% [place, tier.dawn_income, tier.income_floor]
			)
		)


## A boats tier: a cap of 1..MAX_BOAT_CAP and gold per boat of 1..MAX_CURVE_VALUE.
static func _check_boats(place: String, tier: BuildingTierDef, out: Array[String]) -> void:
	if tier.boat_cap < 1 or tier.boat_cap > MAX_BOAT_CAP:
		out.append("%s boat_cap is %d, expected 1 to %d" % [place, tier.boat_cap, MAX_BOAT_CAP])
	if tier.boat_income < 1 or tier.boat_income > MAX_CURVE_VALUE:
		out.append(
			"%s boat_income is %d, expected 1 to %d" % [place, tier.boat_income, MAX_CURVE_VALUE]
		)


## The fields a tier's curve does not use must stay 0: income_step and income_floor belong to
## DECLINING, boat_cap and boat_income to BOATS.
static func _check_unused(
	building_def: BuildingDef, place: String, tier: BuildingTierDef, out: Array[String]
) -> void:
	var curve: String = BuildingDef.IncomeCurve.keys()[building_def.income_curve]
	var unused: Array[String] = []
	if building_def.income_curve != BuildingDef.IncomeCurve.DECLINING:
		unused.append_array(["income_step", "income_floor"])
	if building_def.income_curve != BuildingDef.IncomeCurve.BOATS:
		unused.append_array(["boat_cap", "boat_income"])
	for field: String in unused:
		var value: int = tier.get(field)
		if value != 0:
			out.append(
				(
					"%s sets %s %d but its curve is %s, which does not use it"
					% [place, field, value, curve]
				)
			)


## The pond: finite numbers, a radius within 0..MAX_POND_RADIUS, nothing inside the water and every
## road clear of it. A radius of 0 means no pond, so only a centre that is not finite is reported.
static func _check_pond(map: MapConfig, out: Array[String]) -> void:
	var centre: Vector2 = map.pond_center
	var radius: float = map.pond_radius
	var finite_centre: bool = is_finite(centre.x) and is_finite(centre.y)
	if not finite_centre:
		out.append("pond_center is not finite (%s)" % centre)
	if not is_finite(radius):
		out.append("pond_radius is not finite (%s)" % radius)
		return
	if radius < 0.0:
		out.append("pond_radius is negative (%s)" % radius)
		return
	if radius > MAX_POND_RADIUS:
		out.append("pond_radius is %s, expected at most %s" % [radius, MAX_POND_RADIUS])
	if radius == 0.0 or not finite_centre:
		return
	for spot: BuildSpotDef in map.spots:
		if spot != null and _ground(spot.position).distance_to(centre) < radius:
			out.append("pond contains plot '%s'" % spot.id)
	for spawn_point: SpawnPointDef in map.spawn_points:
		if spawn_point != null and _ground(spawn_point.position).distance_to(centre) < radius:
			out.append("pond contains spawn point '%s'" % spawn_point.id)
	var wanted: float = radius + POND_ROAD_CLEARANCE
	var castle: Vector2 = _ground(map.castle_position)
	for spawn_point: SpawnPointDef in map.spawn_points:
		if spawn_point == null:
			continue
		var start: Vector2 = _ground(spawn_point.position)
		var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(centre, start, castle)
		var apart: float = nearest.distance_to(centre)
		if apart < wanted:
			out.append(
				(
					"pond is %.1f m from the road from spawn point '%s', expected at least %.1f"
					% [apart, spawn_point.id, wanted]
				)
			)


static func _ground(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z)
