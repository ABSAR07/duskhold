class_name CrowdReadView
extends RefCounted
## The enemy field as packed arrays for the batches that draw it (PLAT-01, RESEARCH F3): one slot
## per enemy in ascending id order, with where it stood one step ago and where it stands now.
## EnemySystem.read_view() owns the one instance and refills it only when the field changed, so
## `version` stays the same between reads of an unchanged field. Read-only for callers.

var ids: PackedInt64Array = PackedInt64Array()
var previous: PackedVector2Array = PackedVector2Array()
var current: PackedVector2Array = PackedVector2Array()
var version: int = 0
