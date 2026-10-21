class_name StatModifierDef
extends Resource
## One stat modifier as data (META-08, D-15): a stat id, a bucket and an integer value. A source
## (a castle ability, a Shrine buff, later a perk or a research buff) is a list of these handed to
## StatStack.add_source. Data only; the stacking order lives in StatStack and
## docs/STAT_MODIFIERS.md.

enum Bucket { FLAT, PERCENT, MULTIPLIER }

const FLAT_LIMIT: int = 100000
const PERCENT_MIN: int = -90
const PERCENT_MAX: int = 1000
const MULTIPLIER_MIN: int = 10
const MULTIPLIER_MAX: int = 400

## The stat this modifier changes; must be listed in StatIds.
@export var stat: StringName = &""
## FLAT adds stat units, PERCENT adds to the shared percent sum, MULTIPLIER multiplies last.
@export var bucket: Bucket = Bucket.FLAT
## FLAT: stat units. PERCENT: whole percent (+25 is +25%). MULTIPLIER: percent of x1 (150 is x1.5).
@export var value: int = 0


## Readable problems with this modifier, empty when it is valid: an unknown stat id, or a value
## outside the range of its bucket (the bounds that keep StatStack's integer product inside int64).
func problems() -> PackedStringArray:
	var found: PackedStringArray = PackedStringArray()
	if not StatIds.is_known(stat):
		found.append("unknown stat id '%s'" % stat)
	match bucket:
		Bucket.FLAT:
			if absi(value) > FLAT_LIMIT:
				found.append(
					(
						"flat value %d for '%s' is outside -%d..%d"
						% [value, stat, FLAT_LIMIT, FLAT_LIMIT]
					)
				)
		Bucket.PERCENT:
			if value < PERCENT_MIN or value > PERCENT_MAX:
				found.append(
					(
						"percent value %d for '%s' is outside %d..%d"
						% [value, stat, PERCENT_MIN, PERCENT_MAX]
					)
				)
		Bucket.MULTIPLIER:
			if value < MULTIPLIER_MIN or value > MULTIPLIER_MAX:
				found.append(
					(
						"multiplier %d for '%s' is outside %d..%d"
						% [value, stat, MULTIPLIER_MIN, MULTIPLIER_MAX]
					)
				)
	return found


## The player-facing line for this modifier: "+25% tower damage", "+1 king damage",
## "x1.5 king attack interval".
func effect_text() -> String:
	var label: String = StatIds.label(stat)
	match bucket:
		Bucket.PERCENT:
			return "%+d%% %s" % [value, label]
		Bucket.MULTIPLIER:
			return "x%s %s" % [multiplier_text(value), label]
	return "%+d %s" % [value, label]


## A multiplier value as the player reads it: 200 is "2", 150 is "1.5", 75 is "0.75".
static func multiplier_text(percent_of_one: int) -> String:
	if percent_of_one % 100 == 0:
		@warning_ignore("integer_division")
		return str(percent_of_one / 100)
	return String.num(percent_of_one / 100.0)
