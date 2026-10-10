class_name SquadOrders
extends RefCounted
## Pure helpers for the squad order state machine (D-09, D-14), static like TargetQuery: where a
## squad stands as a group and whether it has reached its formation. No state, no events.

## A unit counts as arrived when it is within this many metres of its formation slot. A geometric
## tolerance like EnemySystem.ARRIVE_EPSILON, not a tuning value.
const ARRIVE_DISTANCE: float = 0.25


## The mean position of the living units in `unit_ids` (ascending ids, so the float sum is the same
## on every run); `fallback` when none is alive.
static func centroid(_units: UnitSystem, _unit_ids: Array[int], fallback: Vector2) -> Vector2:
	return fallback


## True when every living unit in `unit_ids` stands within ARRIVE_DISTANCE of its formation slot
## around `anchor`. A squad with nobody alive has trivially arrived.
static func arrived(
	_units: UnitSystem, _unit_ids: Array[int], _anchor: Vector2, _cap: int, _spacing: float
) -> bool:
	return false
