class_name Separation
extends RefCounted
## The push-apart pass of UnitSystem.separate and EnemySystem._separate (DR-6, DR-8, review IN-03):
## the one routine both systems apply, so the two cannot drift. It returns displacements and moves
## nothing; each system adds them to its own records.
##
## Positions are read from one snapshot. Every pair, in ascending index order (the systems pass
## their circles in ascending id order), adds half the overlap to each member's displacement along
## their difference; a zero difference uses a fixed axis chosen by the lower id's parity, never a
## random one. The displacements are applied together by the caller, so the result does not depend
## on iteration side effects. Determinism-sensitive: the replay goldens depend on every operation
## below, so change none of them without replaying both goldens.


## One displacement per circle (all zero for fewer than two). `positions`, `radii` and `ids` are
## parallel arrays in ascending id order.
static func displacements(
	positions: PackedVector2Array, radii: PackedFloat64Array, ids: PackedInt64Array
) -> PackedVector2Array:
	var count: int = positions.size()
	var displacement: PackedVector2Array = PackedVector2Array()
	displacement.resize(count)
	for first: int in range(count):
		for second: int in range(first + 1, count):
			var min_gap: float = radii[first] + radii[second]
			var delta: Vector2 = positions[second] - positions[first]
			if absf(delta.x) >= min_gap:
				continue
			var d2: float = delta.length_squared()
			if d2 >= min_gap * min_gap:
				continue
			var direction: Vector2
			var gap: float = 0.0
			if d2 == 0.0:
				direction = Vector2.RIGHT if ids[first] % 2 == 0 else Vector2.DOWN
			else:
				gap = sqrt(d2)
				direction = delta / gap
			var push: float = (min_gap - gap) * 0.5
			displacement[first] -= direction * push
			displacement[second] += direction * push
	return displacement
