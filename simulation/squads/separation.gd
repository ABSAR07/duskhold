class_name Separation
extends RefCounted
## The push-apart pass of UnitSystem.separate and EnemySystem._separate (DR-6, DR-8, review IN-03):
## the one routine both systems apply, so the two cannot drift. It returns displacements and moves
## nothing; each system adds them to its own records.
##
## The routine lives in C++ (PLAT-01, plan 04-15): native/src/native_separation.cpp, reached through
## NativeSim.separation_displacements and NativeSim.separation_displacements_bucketed. This class is
## the stable GDScript API in front of it and the only caller. The determinism contract is
## unchanged. Positions are read from one snapshot. Every pair, in ascending index order (the
## systems pass their circles in ascending id order), adds half the overlap to each member's
## displacement along their difference; a zero difference uses a fixed axis chosen by the lower id's
## parity, never a random one. The displacements are applied together by the caller, so the result
## does not depend on iteration side effects. Determinism-sensitive: the replay goldens depend on
## every operation in the native routine, which follows the GDScript it replaced line by line under
## the exact_port_rules (single-precision Vector2, double scalars, narrowing at each operator), and
## which tests/unit/test_separation_pins.gd pins by sha256 on the GDScript results that existed
## before any native code. Change none of it without replaying all goldens.


## One displacement per circle (all zero for fewer than two). `positions`, `radii` and `ids` are
## parallel arrays in ascending id order: precondition, all three the same size. The assert below
## checks it in debug builds only (GDScript strips assert from release exports), so this note is
## the durable statement of it; both callers build the three arrays in lockstep. Arrays of
## different sizes reach the native routine in a release build and give an all-zero result.
static func displacements(
	positions: PackedVector2Array, radii: PackedFloat64Array, ids: PackedInt64Array
) -> PackedVector2Array:
	assert(
		radii.size() == positions.size() and ids.size() == positions.size(),
		"Separation.displacements: positions, radii and ids must be parallel arrays"
	)
	return NativeSim.separation_displacements(positions, radii, ids)


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
	return NativeSim.separation_displacements_bucketed(positions, radii, ids, cell)
