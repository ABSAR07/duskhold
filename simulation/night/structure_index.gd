class_name StructureIndex
extends RefCounted
## The nearest-structure question of a target-less enemy, answered from a uniform grid instead of a
## scan of every unit, building and the castle (PLAT-01, RESEARCH Pattern 1 item 1). It is rebuilt
## once per EnemySystem.step, because nothing it holds moves or falls during the enemy phase (hits
## resolve after it, DR-8).
##
## The grid, its arrays and the scan run in C++ (PLAT-01, plan 04-23,
## native/src/native_structures.cpp): rebuild gathers the snapshot from the units, the buildings
## and the castle in the shipped order (living units by ascending id, then standing buildings in
## spot order, the castle last) and hands it over, and the three queries delegate. The answer is
## exactly the shipped scan's: the candidates are tested in that order with the same test,
## `edge <= aggro_range and edge < best_edge`, and the same expressions
## (`pos.distance_to(centre) - radius`), so a tie goes to the earlier candidate.

## What kind of structure a nearest() answer names.
const KIND_UNIT: int = 0
const KIND_BUILDING: int = 1
const KIND_CASTLE: int = 2
## The answer when nothing is inside the aggro range (the found flag is 0).
const NONE: Vector3i = Vector3i(0, 0, 0)

## The C++ snapshot and the queries over it.
var _native: NativeStructures = NativeStructures.new()


## Rebuilds the grid from the living units, the standing buildings and the castle. `units` and
## `buildings` may be null; then they hold no candidates, as in the shipped scan.
func rebuild(units: UnitSystem, buildings: BuildingSystem, castle: CastleState) -> void:
	var unit_ids: PackedInt64Array = PackedInt64Array()
	var unit_positions: PackedVector2Array = PackedVector2Array()
	var unit_radii: PackedFloat64Array = PackedFloat64Array()
	if units != null:
		for unit_id: int in units.ids():
			if units.is_alive(unit_id):
				unit_ids.append(unit_id)
				unit_positions.append(units.position_of(unit_id))
				unit_radii.append(units.def_of(unit_id).radius)
	var building_indices: PackedInt32Array = PackedInt32Array()
	var building_centres: PackedVector2Array = PackedVector2Array()
	var building_radii: PackedFloat64Array = PackedFloat64Array()
	if buildings != null:
		for spot_id: StringName in buildings.standing_spot_ids():
			var spot: BuildSpotDef = buildings.get_spot(spot_id)
			building_indices.append(buildings.spot_index(spot_id))
			building_centres.append(Vector2(spot.position.x, spot.position.z))
			building_radii.append(buildings.radius_of(spot_id))
	_native.rebuild(
		unit_ids,
		unit_positions,
		unit_radii,
		building_indices,
		building_centres,
		building_radii,
		castle.get_position(),
		castle.get_radius()
	)


## The structure with the smallest edge distance inside `aggro_range` of `pos`, as
## Vector3i(kind, id, 1); NONE when there is none. A unit or building id is the one the enemy's
## target carries (unit id, spot index); the castle's id is 0.
func nearest(pos: Vector2, aggro_range: float) -> Vector3i:
	return _native.nearest(pos, aggro_range)


## nearest() for an enemy behind walls (ENMY-04, RESEARCH Open Question 3): a candidate counts only
## while the straight line from `pos` to its centre is clear of every intact segment for a walker
## of `radius` metres, or while the enemy is ranged (`ranged_reach` is its attack range, a negative
## number for a melee enemy) and the candidate's edge is within it. The same candidates in the same
## order with the same tests, so only a candidate that would improve the best pays for a line test.
## A default melee enemy (the owner's rule of 2026-10-19, G-04-7) asks with radius 0.0, so only a
## line through a segment's solid counts as blocked; the 04-06 radius is what a ranged enemy and an
## enemy with drops_blocked_targets still pass.
func nearest_visible(
	pos: Vector2, aggro_range: float, pathing: Pathing, radius: float, ranged_reach: float
) -> Vector3i:
	var walls: NativeWalls = null
	if pathing != null and pathing.walls() != null:
		walls = pathing.walls().native()
	return _native.nearest_visible(pos, aggro_range, walls, radius, ranged_reach)


## The nearest living unit or standing building inside `aggro_range` whatever walls stand between,
## the castle never (G-04-7): what a melee enemy breaks through to when nothing is in sight. The
## same candidates in the same order with the same `edge <= aggro_range and edge < best_edge` test.
func nearest_through_walls(pos: Vector2, aggro_range: float) -> Vector3i:
	return _native.nearest_through_walls(pos, aggro_range)


## The C++ snapshot, for the native enemy step and the tests.
func native() -> NativeStructures:
	return _native
