class_name EconomyValidation
extends RefCounted
## What MapConfig.validate() says about income-curve data (T-05-13, ECON-03, D-12): one readable
## string per problem, so bad curve numbers are reported instead of armed. A DECLINING building
## (the Gold Mine) needs, on every tier, an income_step and an income_floor of 1 or more (a payout
## that never falls, or one that falls to 0, breaks D-12), a first payout (dawn_income) that is not
## below its floor, and no curve value above MAX_CURVE_VALUE. A building whose curve does not use
## the step and the floor must leave both at 0: a value there is a field set on the wrong curve.
## Plans 05-08 and 05-09 extend this for the Harbor's boats and the Shrine's wake data. Pure: it
## reads the map and never mutates it.

## The largest value any curve field may hold. Keeps every payout well inside an int.
const MAX_CURVE_VALUE: int = 1000


## Every curve problem of `map`, in building and tier order; empty when the data is well formed. A
## null building or tier is skipped: the other helpers report those.
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
			else:
				_check_unused(building_def, place, tier, out)
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


## A tier of a building whose curve does not decline: income_step and income_floor stay 0.
static func _check_unused(
	building_def: BuildingDef, place: String, tier: BuildingTierDef, out: Array[String]
) -> void:
	var curve: String = BuildingDef.IncomeCurve.keys()[building_def.income_curve]
	for field: String in ["income_step", "income_floor"]:
		var value: int = tier.get(field)
		if value != 0:
			out.append(
				(
					"%s sets %s %d but its curve is %s, which does not use it"
					% [place, field, value, curve]
				)
			)
