class_name SquadOrders
extends RefCounted
## Pure helpers for the squad order state machine (D-09, D-14), static like TargetQuery: where a
## squad stands as a group and whether it has reached its formation. No state, no events.

## A unit counts as arrived when it is within this many metres of its formation slot. A geometric
## tolerance like EnemySystem.ARRIVE_EPSILON, not a tuning value.
const ARRIVE_DISTANCE: float = 0.25
## A one-shot walk is abandoned this many seconds after the farthest unit could have reached its
## slot. A guard against formations that cannot all fit (two squads sent to one point push each
## other off their slots), not a tuning value.
const WALK_GRACE_SECONDS: float = 2.0


## True for the verbs the order state machine carries out: follow, hold, rally and the point verbs
## move, attack-move and patrol.
static func is_supported(verb: StringName) -> bool:
	return (
		verb == SquadOrder.VERB_FOLLOW
		or verb == SquadOrder.VERB_HOLD
		or verb == SquadOrder.VERB_RALLY
		or needs_points(verb)
	)


## True for the verbs that carry ground points: move, attack-move and patrol.
static func needs_points(verb: StringName) -> bool:
	return (
		verb == SquadOrder.VERB_MOVE
		or verb == SquadOrder.VERB_ATTACK_MOVE
		or verb == SquadOrder.VERB_PATROL
	)


## True for the walks that stay in the queue while they run: move and attack-move.
static func is_walk(verb: StringName) -> bool:
	return verb == SquadOrder.VERB_MOVE or verb == SquadOrder.VERB_ATTACK_MOVE


## True for the verbs nothing can follow in a queue (D-09): hold, follow and patrol never end.
static func is_terminal(verb: StringName) -> bool:
	return (
		verb == SquadOrder.VERB_HOLD
		or verb == SquadOrder.VERB_FOLLOW
		or verb == SquadOrder.VERB_PATROL
	)


## The stance a squad rests in once an order with this verb is its last: hold, follow and patrol
## rest in their own stance, a walk ends in post at the point it walked to.
static func stance_after(verb: StringName) -> StringName:
	if verb == SquadOrder.VERB_HOLD:
		return SquadOrder.STANCE_HOLD
	if verb == SquadOrder.VERB_FOLLOW:
		return SquadOrder.STANCE_FOLLOW
	if verb == SquadOrder.VERB_PATROL:
		return SquadOrder.STANCE_PATROL
	return SquadOrder.STANCE_POST


## The mean position of the living units in `unit_ids` (ascending ids, so the float sum is the same
## on every run); `fallback` when none is alive.
static func centroid(units: UnitSystem, unit_ids: Array[int], fallback: Vector2) -> Vector2:
	var total: Vector2 = Vector2.ZERO
	var living: int = 0
	for unit_id: int in unit_ids:
		if units.is_alive(unit_id):
			total += units.position_of(unit_id)
			living += 1
	if living == 0:
		return fallback
	return total / float(living)


## True when every living unit in `unit_ids` stands within ARRIVE_DISTANCE of its formation slot
## around `anchor`. A squad with nobody alive has trivially arrived.
static func arrived(
	units: UnitSystem, unit_ids: Array[int], anchor: Vector2, cap: int, spacing: float
) -> bool:
	return farthest_from_slot(units, unit_ids, anchor, cap, spacing) <= ARRIVE_DISTANCE


## How far, in metres, the unit farthest from its formation slot around `anchor` stands; 0 when
## nobody is alive.
static func farthest_from_slot(
	units: UnitSystem, unit_ids: Array[int], anchor: Vector2, cap: int, spacing: float
) -> float:
	var farthest: float = 0.0
	for unit_id: int in unit_ids:
		if not units.is_alive(unit_id):
			continue
		var slot: Vector2 = (
			anchor + SquadFormation.slot_offset(units.slot_of(unit_id), cap, spacing)
		)
		farthest = maxf(farthest, units.position_of(unit_id).distance_to(slot))
	return farthest
