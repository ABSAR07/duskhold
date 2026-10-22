class_name EconomyValidation
extends RefCounted
## What MapConfig.validate() says about income-curve and pond data (T-05-13, T-05-16, T-05-17,
## ECON-03, ECON-05, ECON-06, D-11, D-12): one readable string per problem, so bad numbers are
## reported instead of armed.
##
## A DECLINING building (the Gold Mine) needs, on every tier, an income_step and an income_floor of
## 1 or more (a payout that never falls, or one that falls to 0, breaks D-12), a first payout
## (dawn_income) that is not below its floor, and no curve value above MAX_CURVE_VALUE. A BOATS
## building (the Fishing Harbor) needs, on every tier, a boat_cap of 1 to MAX_BOAT_CAP and a
## boat_income of 1 to MAX_CURVE_VALUE. An AWAKENED building (the Shrine) needs, on every tier, a
## finite wake_radius above 0 and at most MAX_WAKE_RADIUS, a wake_threshold_hp of 1 to
## MAX_WAKE_THRESHOLD, a synergy_percent of 0 to MAX_SYNERGY_PERCENT and real attack numbers
## (damage, reach, an interval of at least one simulation step and a bolt speed). A building whose
## curve does not use a field must leave it at 0: a value there is a field set on the wrong curve.
## Every building's damage_stat must be a registered integer stat and its range_stat a registered
## float stat (StatIds), so a typo is reported instead of silently reading an unmodified stat.
##
## The pond (D-11) is visual only, but its numbers size a mesh and its place must stay clear of the
## play: a centre and radius that are finite, a radius of 0 to MAX_POND_RADIUS (0 means no pond), no
## plot and no spawn point inside the water, and every spawn-to-castle road segment at least
## pond_radius + POND_ROAD_CLEARANCE metres from the centre. Pure: it reads the map and never
## mutates it.

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
		_check_stat_ids(building_def, out)
		for index: int in range(building_def.tiers.size()):
			var tier: BuildingTierDef = building_def.tiers[index]
			if tier == null:
				continue
			var place: String = "building '%s' tier %d" % [building_def.id, index + 1]
			if building_def.income_curve == BuildingDef.IncomeCurve.DECLINING:
				_check_declining(place, tier, out)
			elif building_def.income_curve == BuildingDef.IncomeCurve.BOATS:
				_check_boats(place, tier, out)
			elif building_def.income_curve == BuildingDef.IncomeCurve.AWAKENED:
				_check_awakened(place, tier, out)
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


## An awakened tier: a finite wake radius above 0 and at most MAX_WAKE_RADIUS, a wake threshold of
## 1..MAX_WAKE_THRESHOLD, a synergy of 0..MAX_SYNERGY_PERCENT, the first payout at most
## MAX_CURVE_VALUE and attack numbers a tower could use: damage above 0, a finite reach above 0, a
## finite interval of at least one simulation step and a finite bolt speed above 0.
static func _check_awakened(place: String, tier: BuildingTierDef, out: Array[String]) -> void:
	if not is_finite(tier.wake_radius):
		out.append("%s wake_radius is not finite (%s)" % [place, tier.wake_radius])
	elif tier.wake_radius <= 0.0 or tier.wake_radius > MAX_WAKE_RADIUS:
		out.append(
			(
				"%s wake_radius is %s, expected above 0 and at most %s"
				% [place, tier.wake_radius, MAX_WAKE_RADIUS]
			)
		)
	if tier.wake_threshold_hp < 1 or tier.wake_threshold_hp > MAX_WAKE_THRESHOLD:
		out.append(
			(
				"%s wake_threshold_hp is %d, expected 1 to %d"
				% [place, tier.wake_threshold_hp, MAX_WAKE_THRESHOLD]
			)
		)
	if tier.synergy_percent < 0 or tier.synergy_percent > MAX_SYNERGY_PERCENT:
		out.append(
			(
				"%s synergy_percent is %d, expected 0 to %d"
				% [place, tier.synergy_percent, MAX_SYNERGY_PERCENT]
			)
		)
	if tier.dawn_income < 0 or tier.dawn_income > MAX_CURVE_VALUE:
		out.append(
			"%s dawn_income is %d, expected 0 to %d" % [place, tier.dawn_income, MAX_CURVE_VALUE]
		)
	if tier.attack_damage < 1:
		out.append("%s attack_damage is %d, expected 1 or more" % [place, tier.attack_damage])
	if not is_finite(tier.attack_range) or tier.attack_range <= 0.0:
		out.append(
			"%s attack_range is %s, expected a finite number above 0" % [place, tier.attack_range]
		)
	if not is_finite(tier.attack_interval) or tier.attack_interval < SimClock.STEP:
		out.append(
			(
				"%s attack_interval is %s, expected a finite number of at least %s"
				% [place, tier.attack_interval, SimClock.STEP]
			)
		)
	if not is_finite(tier.projectile_speed) or tier.projectile_speed <= 0.0:
		out.append(
			(
				"%s projectile_speed is %s, expected a finite number above 0"
				% [place, tier.projectile_speed]
			)
		)


## A building's attack reads its damage through an integer stat and its reach through a float stat,
## both registered in StatIds.
static func _check_stat_ids(building_def: BuildingDef, out: Array[String]) -> void:
	var place: String = "building '%s'" % building_def.id
	var damage: StringName = building_def.damage_stat
	var reach: StringName = building_def.range_stat
	if not StatIds.is_known(damage):
		out.append("%s damage_stat '%s' is not a known stat id" % [place, damage])
	elif not StatIds.is_int(damage):
		out.append("%s damage_stat '%s' is not an integer stat" % [place, damage])
	if not StatIds.is_known(reach):
		out.append("%s range_stat '%s' is not a known stat id" % [place, reach])
	elif StatIds.is_int(reach):
		out.append("%s range_stat '%s' is not a float stat" % [place, reach])


## The fields a tier's curve does not use must stay 0: income_step and income_floor belong to
## DECLINING, boat_cap and boat_income to BOATS, the three wake fields to AWAKENED.
static func _check_unused(
	building_def: BuildingDef, place: String, tier: BuildingTierDef, out: Array[String]
) -> void:
	var curve: String = BuildingDef.IncomeCurve.keys()[building_def.income_curve]
	var unused: Array[String] = []
	if building_def.income_curve != BuildingDef.IncomeCurve.DECLINING:
		unused.append_array(["income_step", "income_floor"])
	if building_def.income_curve != BuildingDef.IncomeCurve.BOATS:
		unused.append_array(["boat_cap", "boat_income"])
	if building_def.income_curve != BuildingDef.IncomeCurve.AWAKENED:
		unused.append_array(["wake_radius", "wake_threshold_hp", "synergy_percent"])
	for field: String in unused:
		# A Variant, because wake_radius is a float and a fraction must not truncate to 0.
		var value: Variant = tier.get(field)
		if value != 0:
			out.append(
				(
					"%s sets %s %s but its curve is %s, which does not use it"
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
