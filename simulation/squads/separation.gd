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

## The narrowest cell the bucketed pass accepts, so a zero radius cannot ask for endless cells.
const MIN_CELL: float = 0.001
const KEY_OFFSET: int = 1 << 19
const KEY_STRIDE: int = 1 << 20


## One displacement per circle (all zero for fewer than two). `positions`, `radii` and `ids` are
## parallel arrays in ascending id order: precondition, all three the same size. The assert below
## checks it in debug builds only (GDScript strips assert from release exports), so this note is
## the durable statement of it; both callers build the three arrays in lockstep.
static func displacements(
	positions: PackedVector2Array, radii: PackedFloat64Array, ids: PackedInt64Array
) -> PackedVector2Array:
	assert(
		radii.size() == positions.size() and ids.size() == positions.size(),
		"Separation.displacements: positions, radii and ids must be parallel arrays"
	)
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


## The same displacements as `displacements`, bit for bit, from a grid instead of every pair: for
## each circle only the circles in the cells around it are visited, in ascending partner order, so
## every addition happens in the order the O(n^2) loops produce (that order is the contract: float
## addition is not associative, and the replay goldens depend on it). For a partner `other` below
## `index` the shipped pair has `index` second (`delta = positions[index] - positions[other]`,
## added); for one above it has `index` first (`delta = positions[other] - positions[index]`,
## subtracted). `cell` is a performance parameter, normally 2 * the largest radius plus a hair; it
## decides how many cells are visited (twice the largest radius, in cells), never an answer.
static func displacements_bucketed(
	positions: PackedVector2Array, radii: PackedFloat64Array, ids: PackedInt64Array, cell: float
) -> PackedVector2Array:
	assert(
		radii.size() == positions.size() and ids.size() == positions.size(),
		"Separation.displacements_bucketed: positions, radii and ids must be parallel arrays"
	)
	var count: int = positions.size()
	var displacement: PackedVector2Array = PackedVector2Array()
	displacement.resize(count)
	if count < 2:
		return displacement
	var edge: float = maxf(cell, MIN_CELL)
	var cells: Dictionary = {}
	var largest: float = 0.0
	for index: int in range(count):
		largest = maxf(largest, radii[index])
		var key: int = _cell_key(
			floori(positions[index].x / edge), floori(positions[index].y / edge)
		)
		if not cells.has(key):
			var fresh: Array[int] = []
			cells[key] = fresh
		(cells[key] as Array[int]).append(index)
	var span: int = maxi(ceili(2.0 * largest / edge), 1)
	for index: int in range(count):
		displacement[index] = _partner_sum(index, positions, radii, ids, cells, edge, span)
	return displacement


## The displacement of circle `index`: its partners from the cells within `span` of its own, in
## ascending partner order, with the expressions of `displacements`.
static func _partner_sum(
	index: int,
	positions: PackedVector2Array,
	radii: PackedFloat64Array,
	ids: PackedInt64Array,
	cells: Dictionary,
	edge: float,
	span: int
) -> Vector2:
	var cell_x: int = floori(positions[index].x / edge)
	var cell_y: int = floori(positions[index].y / edge)
	var partners: Array[int] = []
	for offset_x: int in range(-span, span + 1):
		for offset_y: int in range(-span, span + 1):
			var bucket: Variant = cells.get(_cell_key(cell_x + offset_x, cell_y + offset_y))
			if bucket != null:
				partners.append_array(bucket as Array[int])
	partners.sort()
	var total: Vector2 = Vector2.ZERO
	for other: int in partners:
		if other == index:
			continue
		var first: int = mini(index, other)
		var second: int = maxi(index, other)
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
		if other < index:
			total += direction * push
		else:
			total -= direction * push
	return total


static func _cell_key(cell_x: int, cell_y: int) -> int:
	return (cell_x + KEY_OFFSET) * KEY_STRIDE + (cell_y + KEY_OFFSET)
