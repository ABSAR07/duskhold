class_name StructureIndex
extends RefCounted
## The nearest-structure question of a target-less enemy, answered from a uniform grid instead of a
## scan of every unit, building and the castle (PLAT-01, RESEARCH Pattern 1 item 1). It is rebuilt
## once per EnemySystem.step, because nothing it holds moves or falls during the enemy phase (hits
## resolve after it, DR-8).
##
## The answer is exactly the shipped scan's: the candidates are tested in the shipped order (living
## units by ascending id, then standing buildings in spot order, then the castle) with the same
## test, `edge <= aggro_range and edge < best_edge`, and the same expressions
## (`pos.distance_to(centre) - radius`), so a tie goes to the earlier candidate. The grid only
## decides which of them are worth testing: every candidate whose edge could be inside the aggro
## range lies within `aggro_range + largest radius` of the query point, which is a bounded block of
## cells. Only `+ - * /` and `floori` are used (DR-7).

## What kind of structure a nearest() answer names.
const KIND_UNIT: int = 0
const KIND_BUILDING: int = 1
const KIND_CASTLE: int = 2
## A performance parameter, never data: the cell edge in metres. It changes how many candidates are
## tested, never which one wins.
const CELL: float = 12.0
## Covers float32 rounding between a distance and the cell arithmetic on the block's border.
const REACH_MARGIN: float = 0.01
const KEY_OFFSET: int = 1 << 19
const KEY_STRIDE: int = 1 << 20
## The answer when nothing is inside the aggro range (the found flag is 0).
const NONE: Vector3i = Vector3i(0, 0, 0)

## Cell key -> Array[int] of candidate indices, ascending (insertion order is the shipped order).
var _cells: Dictionary = {}
var _centres: PackedVector2Array = PackedVector2Array()
var _radii: PackedFloat64Array = PackedFloat64Array()
var _kinds: PackedInt32Array = PackedInt32Array()
var _ids: PackedInt32Array = PackedInt32Array()
var _largest_radius: float = 0.0


## Rebuilds the grid from the living units, the standing buildings and the castle. `units` and
## `buildings` may be null; then they hold no candidates, as in the shipped scan.
func rebuild(units: UnitSystem, buildings: BuildingSystem, castle: CastleState) -> void:
	_cells.clear()
	_centres.clear()
	_radii.clear()
	_kinds.clear()
	_ids.clear()
	_largest_radius = 0.0
	if units != null:
		for unit_id: int in units.ids():
			if units.is_alive(unit_id):
				_insert(
					units.position_of(unit_id), units.def_of(unit_id).radius, KIND_UNIT, unit_id
				)
	if buildings != null:
		for spot_id: StringName in buildings.standing_spot_ids():
			var spot: BuildSpotDef = buildings.get_spot(spot_id)
			var centre: Vector2 = Vector2(spot.position.x, spot.position.z)
			_insert(
				centre, buildings.radius_of(spot_id), KIND_BUILDING, buildings.spot_index(spot_id)
			)
	_insert(castle.get_position(), castle.get_radius(), KIND_CASTLE, 0)


## The structure with the smallest edge distance inside `aggro_range` of `pos`, as
## Vector3i(kind, id, 1); NONE when there is none. A unit or building id is the one the enemy's
## target carries (unit id, spot index); the castle's id is 0.
func nearest(pos: Vector2, aggro_range: float) -> Vector3i:
	var reach_cells: int = ceili((aggro_range + _largest_radius + REACH_MARGIN) / CELL)
	var cell_x: int = floori(pos.x / CELL)
	var cell_y: int = floori(pos.y / CELL)
	var candidates: Array[int] = []
	for offset_x: int in range(-reach_cells, reach_cells + 1):
		for offset_y: int in range(-reach_cells, reach_cells + 1):
			var bucket: Variant = _cells.get(_key(cell_x + offset_x, cell_y + offset_y))
			if bucket != null:
				candidates.append_array(bucket as Array[int])
	candidates.sort()
	var best_edge: float = INF
	var found: Vector3i = NONE
	for index: int in candidates:
		var edge: float = pos.distance_to(_centres[index]) - _radii[index]
		if edge <= aggro_range and edge < best_edge:
			best_edge = edge
			found = Vector3i(_kinds[index], _ids[index], 1)
	return found


func _insert(centre: Vector2, radius: float, kind: int, id: int) -> void:
	var index: int = _centres.size()
	_centres.append(centre)
	_radii.append(radius)
	_kinds.append(kind)
	_ids.append(id)
	_largest_radius = maxf(_largest_radius, radius)
	var key: int = _key(floori(centre.x / CELL), floori(centre.y / CELL))
	if not _cells.has(key):
		var fresh: Array[int] = []
		_cells[key] = fresh
	(_cells[key] as Array[int]).append(index)


static func _key(cell_x: int, cell_y: int) -> int:
	return (cell_x + KEY_OFFSET) * KEY_STRIDE + (cell_y + KEY_OFFSET)
