class_name StatIds
extends RefCounted
## The registry of legal stat ids (META-08, D-15): every stat a modifier may name, whether it is an
## integer or a float stat, and the player-facing label that effect text uses. A modifier naming an
## id that is not listed here is refused by StatStack.add_source and reported by
## StatModifierDef.problems(), which is the typo guard. docs/STAT_MODIFIERS.md lists the same ids
## with the file that reads each one; test_stat_contract fails if the two drift apart.

## Integer stats: id -> label. Read through StatStack.int_value.
const INT_STATS: Dictionary = {
	&"king.max_health": "king health",
	&"king.attack_damage": "king damage",
	&"king.slam_damage": "king slam damage",
	&"king.damage_taken": "damage the king takes",
	&"unit.max_health": "unit health",
	&"unit.attack_damage": "unit damage",
	&"building.max_health": "building health",
	&"wall.max_health": "wall health",
	&"tower.damage": "tower damage",
	&"shrine.damage": "shrine damage",
	&"castle.max_health": "castle health",
	&"castle.arrow_damage": "castle arrow damage",
	&"castle.base_income": "castle gold at dawn",
}
## Float stats: id -> label. Read through StatStack.float_value.
const FLOAT_STATS: Dictionary = {
	&"king.attack_interval": "king attack interval",
	&"squad.respawn_seconds": "unit return time",
	&"tower.range": "tower range",
	&"shrine.range": "shrine range",
	&"castle.arrow_range": "castle arrow range",
}


## True when `stat` is a registered stat id.
static func is_known(stat: StringName) -> bool:
	return INT_STATS.has(stat) or FLOAT_STATS.has(stat)


## True when `stat` is a registered integer stat (false for a float stat or an unknown id).
static func is_int(stat: StringName) -> bool:
	return INT_STATS.has(stat)


## The player-facing label of `stat`, or the id itself when it is not registered.
static func label(stat: StringName) -> String:
	if INT_STATS.has(stat):
		return String(INT_STATS[stat])
	if FLOAT_STATS.has(stat):
		return String(FLOAT_STATS[stat])
	return String(stat)


## Every registered stat id, sorted.
static func all() -> Array[StringName]:
	var ids: Array[StringName] = []
	for stat: StringName in INT_STATS:
		ids.append(stat)
	for stat: StringName in FLOAT_STATS:
		ids.append(stat)
	return sorted(ids)


## `ids` in alphabetical order, as a new array. Array.sort() on StringNames is not alphabetical (it
## compares the interned names, so the order depends on the run), so every sorted list in the
## simulation goes through here to stay deterministic.
static func sorted(ids: Array[StringName]) -> Array[StringName]:
	var names: Array[String] = []
	for id: StringName in ids:
		names.append(String(id))
	names.sort()
	var result: Array[StringName] = []
	for name_text: String in names:
		result.append(StringName(name_text))
	return result
