class_name StatStack
extends RefCounted
## The one stat-modifier stack every bonus in the game goes through (META-08, D-15). Each stat has
## three buckets filled by named sources:
##
##   final = (base + sum(flat)) * (1 + sum(percent) / 100) * product(multiplier / 100)
##
## The order a source was added in never changes a result, only its bucket does. Integer stats are
## computed as one exact integer fraction and rounded once, half up, at the end; a stat whose base
## is 1 or more never falls below 1 and one whose base is 0 or less never falls below 0. A stat
## with no modifier returns its base untouched, so an empty stack moves no number and no digest.
## docs/STAT_MODIFIERS.md is the written contract; test_stat_contract fails if either loses the
## formula line. Pure RefCounted code on integers and + - * / only (DR-1 to DR-10); bad input
## returns false, never push_error.

## Announces the sorted ids of the stats whose sums moved, after one add_source or remove_source.
signal changed(stats: Array[StringName])

## |base + sum(flat)| is clamped to this before multiplying, so no product overflows int64.
const MAX_ABS_BASE: int = 100000
## At most this many multipliers on one stat (across all sources).
const MAX_MULTIPLIERS_PER_STAT: int = 4
## The percent sum of one stat stays within these bounds (a removal that leaves the raw sum
## outside them is clamped when read).
const PERCENT_SUM_MIN: int = -90
const PERCENT_SUM_MAX: int = 1000
const _PERCENT_BASE: int = 100

## Source id -> its modifiers (copies, so a later edit of the original changes nothing).
var _sources: Dictionary = {}
## Stat id -> {flat: int, pct: int, mults: Array[int] ascending}; only stats with a modifier.
var _sums: Dictionary = {}
## Stat id -> the sums it had before the last change, for the stats that moved.
var _previous: Dictionary = {}


## Gives `source_id` this list of modifiers, replacing any earlier list of the same id. Returns
## false and changes nothing when any modifier is invalid (unknown stat, value out of range), when
## a stat would carry more than MAX_MULTIPLIERS_PER_STAT multipliers, or when a percent sum would
## leave PERCENT_SUM_MIN..PERCENT_SUM_MAX. Emits `changed` once with the stats whose sums moved
## (nothing when none moved).
func add_source(source_id: StringName, mods: Array[StatModifierDef]) -> bool:
	var copies: Array[StatModifierDef] = []
	for mod: StatModifierDef in mods:
		if mod == null or not mod.problems().is_empty():
			return false
		copies.append(_copy_of(mod))
	var next_sources: Dictionary = _sources.duplicate()
	next_sources[source_id] = copies
	var touched: Array[StringName] = _stats_of(copies)
	for stat: StringName in _stats_of(_list_of(source_id)):
		if not touched.has(stat):
			touched.append(stat)
	var next_sums: Dictionary = {}
	for stat: StringName in touched:
		var sums: Dictionary = _compute_sums(stat, next_sources)
		if not _sums_within_limits(sums):
			return false
		next_sums[stat] = sums
	_apply(next_sources, next_sums, touched)
	return true


## Drops every modifier `source_id` contributed. An unknown id changes nothing and emits nothing.
func remove_source(source_id: StringName) -> void:
	if not _sources.has(source_id):
		return
	var touched: Array[StringName] = _stats_of(_list_of(source_id))
	var next_sources: Dictionary = _sources.duplicate()
	next_sources.erase(source_id)
	var next_sums: Dictionary = {}
	for stat: StringName in touched:
		next_sums[stat] = _compute_sums(stat, next_sources)
	_apply(next_sources, next_sums, touched)


func has_source(source_id: StringName) -> bool:
	return _sources.has(source_id)


## Every source id, sorted.
func source_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for source_id: StringName in _sources:
		ids.append(source_id)
	return StatIds.sorted(ids)


## The integer stat `stat` with its modifiers applied to `base`. With no modifier it is `base`.
func int_value(stat: StringName, base: int) -> int:
	return _int_from(_sums.get(stat, {}), base)


## The float stat `stat` with its modifiers applied to `base`. With no modifier it is `base`
## itself, bit for bit.
func float_value(stat: StringName, base: float) -> float:
	var sums: Dictionary = _sums.get(stat, {})
	if sums.is_empty():
		return base
	var value: float = (base + float(sums["flat"])) * (1.0 + float(_pct_of(sums)) / 100.0)
	for mult: int in sums["mults"]:
		value = value * (float(mult) / 100.0)
	return value


## What int_value would have answered before the change `changed` is announcing; inside a handler
## it is the old value, outside it equals int_value for a stat the last change did not touch.
func previous_int_value(stat: StringName, base: int) -> int:
	if _previous.has(stat):
		return _int_from(_previous[stat], base)
	return int_value(stat, base)


## True when at least one modifier names `stat`.
func is_modified(stat: StringName) -> bool:
	return _sums.has(stat)


## Every stat that has a modifier, sorted.
func modified_stats() -> Array[StringName]:
	var ids: Array[StringName] = []
	for stat: StringName in _sums:
		ids.append(stat)
	return StatIds.sorted(ids)


## The bucket sums of `stat` as {flat: int, pct: int, mults: Array[int]} (a copy; multipliers
## ascending). All zero and empty for a stat with no modifier.
func sums_of(stat: StringName) -> Dictionary:
	var sums: Dictionary = _sums.get(stat, {})
	var mults: Array[int] = []
	if sums.is_empty():
		return {"flat": 0, "pct": 0, "mults": mults}
	mults.assign(sums["mults"])
	return {"flat": sums["flat"], "pct": sums["pct"], "mults": mults}


func _int_from(sums: Dictionary, base: int) -> int:
	if sums.is_empty():
		return base
	var numerator: int = maxi(clampi(base + int(sums["flat"]), -MAX_ABS_BASE, MAX_ABS_BASE), 0)
	numerator *= _PERCENT_BASE + _pct_of(sums)
	var denominator: int = _PERCENT_BASE
	for mult: int in sums["mults"]:
		numerator *= mult
		denominator *= _PERCENT_BASE
	@warning_ignore("integer_division")
	var rounded: int = (numerator * 2 + denominator) / (2 * denominator)
	return maxi(rounded, 1) if base >= 1 else maxi(rounded, 0)


func _pct_of(sums: Dictionary) -> int:
	return clampi(int(sums["pct"]), PERCENT_SUM_MIN, PERCENT_SUM_MAX)


func _list_of(source_id: StringName) -> Array[StatModifierDef]:
	var list: Array[StatModifierDef] = []
	if _sources.has(source_id):
		list.assign(_sources[source_id])
	return list


func _stats_of(mods: Array[StatModifierDef]) -> Array[StringName]:
	var stats: Array[StringName] = []
	for mod: StatModifierDef in mods:
		if not stats.has(mod.stat):
			stats.append(mod.stat)
	return stats


func _copy_of(mod: StatModifierDef) -> StatModifierDef:
	var copy: StatModifierDef = StatModifierDef.new()
	copy.stat = mod.stat
	copy.bucket = mod.bucket
	copy.value = mod.value
	return copy


## The bucket sums of `stat` over `sources`, or an empty Dictionary when no modifier names it.
func _compute_sums(stat: StringName, sources: Dictionary) -> Dictionary:
	var flat: int = 0
	var pct: int = 0
	var mults: Array[int] = []
	var found: bool = false
	for source_id: StringName in sources:
		for mod: StatModifierDef in sources[source_id]:
			if mod.stat != stat:
				continue
			found = true
			match mod.bucket:
				StatModifierDef.Bucket.FLAT:
					flat += mod.value
				StatModifierDef.Bucket.PERCENT:
					pct += mod.value
				StatModifierDef.Bucket.MULTIPLIER:
					mults.append(mod.value)
	if not found:
		return {}
	mults.sort()
	return {"flat": flat, "pct": pct, "mults": mults}


func _sums_within_limits(sums: Dictionary) -> bool:
	if sums.is_empty():
		return true
	if (sums["mults"] as Array[int]).size() > MAX_MULTIPLIERS_PER_STAT:
		return false
	var pct: int = int(sums["pct"])
	return pct >= PERCENT_SUM_MIN and pct <= PERCENT_SUM_MAX


func _same_sums(a: Dictionary, b: Dictionary) -> bool:
	if a.is_empty() or b.is_empty():
		return a.is_empty() and b.is_empty()
	return a["flat"] == b["flat"] and a["pct"] == b["pct"] and a["mults"] == b["mults"]


## Commits a validated change: snapshots the sums that moved, swaps in the new state and announces
## the sorted moved stats.
func _apply(next_sources: Dictionary, next_sums: Dictionary, touched: Array[StringName]) -> void:
	var moved: Array[StringName] = []
	var snapshots: Dictionary = {}
	for stat: StringName in touched:
		var before: Dictionary = _sums.get(stat, {})
		if not _same_sums(before, next_sums[stat]):
			moved.append(stat)
			snapshots[stat] = before
	_sources = next_sources
	for stat: StringName in touched:
		var sums: Dictionary = next_sums[stat]
		if sums.is_empty():
			_sums.erase(stat)
		else:
			_sums[stat] = sums
	if moved.is_empty():
		return
	_previous = snapshots
	changed.emit(StatIds.sorted(moved))
