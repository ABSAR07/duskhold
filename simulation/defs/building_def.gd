class_name BuildingDef
extends Resource
## A building type and its linear tier ladder. Index 0 of `tiers` is tier I (the build).

const ROMAN_NUMERALS: Array[String] = ["I", "II", "III", "IV", "V"]

@export var id: StringName = &""
@export var display_name: String = ""
@export var tiers: Array[BuildingTierDef] = []


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
