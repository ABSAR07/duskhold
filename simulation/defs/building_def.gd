class_name BuildingDef
extends Resource
## A building type and its linear tier ladder. Index 0 of `tiers` is tier I (the build).

## How a building's dawn income is paid (D-12, ECON-03). FLAT pays its tier's dawn_income every dawn
## it stands (BuildingSystem.dawn_income_by_spot). Every other curve is paid by IncomeState, which
## keeps the per-plot state it needs: DECLINING (the Gold Mine) pays less at each dawn it pays,
## BOATS (the Fishing Harbor) gains one paying boat per dawn up to its tier's cap, AWAKENED (the
## Shrine) pays only once it has woken, after enough enemies died within its wake radius. A curve is
## paid by exactly one of the two, so nothing is ever paid twice.
enum IncomeCurve { FLAT, DECLINING, BOATS, AWAKENED }

const ROMAN_NUMERALS: Array[String] = ["I", "II", "III", "IV", "V"]

@export var id: StringName = &""
@export var display_name: String = ""
@export var tiers: Array[BuildingTierDef] = []
## Radius of the building's footprint in metres; enemies stop at this plus their own attack range.
@export var body_radius: float = 1.0
## The unit this building's squad fields; empty for non-military buildings.
@export var unit_id: StringName = &""
## Metres from the plot centre toward the castle where the squad's formation centres.
@export var post_distance: float = 0.0
## How this building's income is paid (see IncomeCurve). FLAT for every building that pays the same
## amount at each dawn it stands, and for every building that pays nothing.
@export var income_curve: IncomeCurve = IncomeCurve.FLAT
## The StatStack ids the building's attack reads its damage and its reach through (D-15). Towers
## keep the defaults so their numbers do not move; the Shrine names shrine.damage and shrine.range,
## so its own modifiers (the mutual synergy, a Golden Age card) never touch a tower. Ignored by a
## building whose tiers do not attack.
@export var damage_stat: StringName = &"tower.damage"
@export var range_stat: StringName = &"tower.range"


func max_tier() -> int:
	return tiers.size()


## Tier definition for a 1-based tier; null when out of range.
func tier_def(tier: int) -> BuildingTierDef:
	if tier < 1 or tier > tiers.size():
		return null
	return tiers[tier - 1]


## "House II" style label (Roman numerals I to V, digits beyond that).
func tier_label(tier: int) -> String:
	var numeral: String = str(tier)
	if tier >= 1 and tier <= ROMAN_NUMERALS.size():
		numeral = ROMAN_NUMERALS[tier - 1]
	return "%s %s" % [display_name, numeral]


## True when the building pays gold at dawn at that 1-based tier, whatever its curve: the
## crossed-coin marker (LOOP-05, D-14) asks this, so a rebuilt Mine is marked like a rebuilt House.
## A BOATS building pays when its tier names gold per boat.
func pays_income(tier: int) -> bool:
	var tier_data: BuildingTierDef = tier_def(tier)
	if tier_data == null:
		return false
	if income_curve == IncomeCurve.BOATS:
		return tier_data.boat_income > 0
	return tier_data.dawn_income > 0


## What the player reads for that 1-based tier next to its cost, aware of the income curve. A
## DECLINING building says how its payout falls ("Pays 3 gold, then 1 less each dawn, never below
## 1", read from the tier's dawn_income, income_step and income_floor); a BOATS building says how
## its boats grow ("+1 boat each dawn, up to 3, 1 gold each"); an AWAKENED building says what wakes
## it ("Wakes after 100 enemy health falls within 18 m, then shoots and pays 1"); every other curve
## falls back to the tier's own effect line. Empty for a tier the building does not have.
func tier_effect_line(tier: int) -> String:
	var tier_data: BuildingTierDef = tier_def(tier)
	if tier_data == null:
		return ""
	if income_curve == IncomeCurve.DECLINING:
		return (
			"Pays %d gold, then %d less each dawn, never below %d"
			% [tier_data.dawn_income, tier_data.income_step, tier_data.income_floor]
		)
	if income_curve == IncomeCurve.BOATS:
		return (
			"+1 boat each dawn, up to %d, %d gold each"
			% [tier_data.boat_cap, tier_data.boat_income]
		)
	if income_curve == IncomeCurve.AWAKENED:
		return (
			"Wakes after %d enemy health falls within %d m, then shoots and pays %d"
			% [tier_data.wake_threshold_hp, roundi(tier_data.wake_radius), tier_data.dawn_income]
		)
	return tier_data.effect_line()
