class_name UnitReadView
extends RefCounted
## The friendly army as packed arrays for the batches that draw it (PLAT-01, review IN-07): one slot
## per unit in ascending id order, with where it stood one step ago and where it stands now, and
## which of the distinct unit types it is. `def_slots[i]` indexes `defs`, which lists each unit type
## once in the order it was first met, so a reader that needs a per-type table builds it from
## `defs` alone instead of asking the system about every unit.
## UnitSystem.read_view() owns the one instance and refills it only when an id, a position or a
## def changed, so `version` stays the same between reads of an unchanged army. Read-only for
## callers: it is a copy, nothing written here reaches the simulation.

var ids: PackedInt64Array = PackedInt64Array()
var previous: PackedVector2Array = PackedVector2Array()
var current: PackedVector2Array = PackedVector2Array()
## Each unit's index into `defs`.
var def_slots: PackedInt32Array = PackedInt32Array()
## The distinct unit types in first-seen order.
var defs: Array[UnitDef] = []
var version: int = 0
