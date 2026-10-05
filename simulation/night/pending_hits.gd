class_name PendingHits
extends RefCounted
## Decide-then-resolve damage queue (DR-8). During a tick every attacker only decides and enqueues
## a hit; the hits due this tick resolve together afterwards, in (arrival tick, enqueue order)
## order. A hit names its target by id, never by position, and the resolver drops it silently when
## the target is already gone.

const KIND_KING := &"king"
const KIND_ENEMY := &"enemy"
const KIND_CASTLE := &"castle"
const KIND_BUILDING := &"building"

var _hits: Array[Hit] = []
var _next_seq: int = 0


## Queues a hit. For KIND_BUILDING the id is the spot's index in BuildingSystem.spot_ids();
## KIND_KING and KIND_CASTLE use id 0.
func enqueue(
	arrival_tick: int,
	attacker_kind: StringName,
	attacker_id: int,
	target_kind: StringName,
	target_id: int,
	amount: int
) -> void:
	var hit: Hit = Hit.new()
	hit.arrival_tick = arrival_tick
	hit.seq = _next_seq
	hit.attacker_kind = attacker_kind
	hit.attacker_id = attacker_id
	hit.target_kind = target_kind
	hit.target_id = target_id
	hit.amount = amount
	_next_seq += 1
	_hits.append(hit)


## Removes and returns every hit with arrival_tick <= tick as Hit objects, in (arrival_tick, seq)
## order. The order is total because seq is unique, so the unstable sort cannot reorder ties.
func take_due(tick: int) -> Array:
	var due: Array[Hit] = []
	var remaining: Array[Hit] = []
	for hit: Hit in _hits:
		if hit.arrival_tick <= tick:
			due.append(hit)
		else:
			remaining.append(hit)
	_hits = remaining
	due.sort_custom(_before)
	return due


func clear() -> void:
	_hits.clear()


func size() -> int:
	return _hits.size()


func _before(a: Hit, b: Hit) -> bool:
	if a.arrival_tick != b.arrival_tick:
		return a.arrival_tick < b.arrival_tick
	return a.seq < b.seq


## One queued hit.
class Hit:
	extends RefCounted
	var arrival_tick: int = 0
	var seq: int = 0
	var attacker_kind: StringName = &""
	var attacker_id: int = 0
	var target_kind: StringName = &""
	var target_id: int = 0
	var amount: int = 0
