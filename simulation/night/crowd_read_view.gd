class_name CrowdReadView
extends RefCounted
## The enemy field as packed arrays for the batches that draw it (PLAT-01, RESEARCH F3): one slot
## per enemy in ascending id order, with where it stood one step ago and where it stands now, and
## whether it holds a target and is alive (the stuck tracker reads those two).
## EnemySystem.read_view() owns the one instance and refills it only when the field changed, so
## `version` stays the same between reads of an unchanged field. Read-only for callers.

var ids: PackedInt64Array = PackedInt64Array()
var previous: PackedVector2Array = PackedVector2Array()
var current: PackedVector2Array = PackedVector2Array()
## 1 where the enemy holds a target, else 0.
var targeted: PackedByteArray = PackedByteArray()
## 1 where the enemy's health is above 0, else 0 (a dead enemy not yet removed is still listed).
var living: PackedByteArray = PackedByteArray()
var version: int = 0
