class_name EnemyIndex
extends RefCounted
## A uniform grid of the living enemies behind TargetQuery.nearest_enemy (PLAT-01, RESEARCH
## Pattern 1 item 2): the towers, the castle, the king and the squads each ask "who is nearest"
## once per tick, and a scan of every enemy per question is what a 300-enemy night cannot afford.
## The grid only narrows the candidates to the cells around the query point; the caller applies
## its own exact test to them, so the answer is the scan's answer. Only occupied cells exist, so
## memory follows the enemy count, never the map size (T-04-06). `+ - * /` and `floori` only (DR-7).

## A performance parameter, never data: the cell edge in metres. It changes how many candidates a
## query returns, never which one the caller picks.
const CELL: float = 8.0
## Covers float32 rounding on the border of the cell block.
const REACH_MARGIN: float = 0.01
const KEY_OFFSET: int = 1 << 19
const KEY_STRIDE: int = 1 << 20

## Cell key -> Array[int] of slots into _ids, ascending (callers pass ids in ascending order).
var _cells: Dictionary = {}
var _ids: PackedInt64Array = PackedInt64Array()


## Rebuilds the grid. `ids` and `positions` are parallel; pass ids in ascending order.
func rebuild(ids: PackedInt64Array, positions: PackedVector2Array) -> void:
	_cells.clear()
	_ids = ids
	for slot: int in range(ids.size()):
		var key: int = _key(floori(positions[slot].x / CELL), floori(positions[slot].y / CELL))
		if not _cells.has(key):
			var fresh: Array[int] = []
			_cells[key] = fresh
		(_cells[key] as Array[int]).append(slot)


## Every indexed id whose cell lies within `reach` of `pos`'s cell, ascending. A superset of the
## enemies within `reach` metres of `pos`: the caller keeps those passing its own distance test.
func within(pos: Vector2, reach: float) -> PackedInt64Array:
	var span: int = ceili((maxf(reach, 0.0) + REACH_MARGIN) / CELL)
	var cell_x: int = floori(pos.x / CELL)
	var cell_y: int = floori(pos.y / CELL)
	var slots: Array[int] = []
	var block: int = 2 * span + 1
	if block * block > _cells.size():
		# A reach wider than the field: visit the occupied cells instead of an empty block.
		for bucket: Array[int] in _cells.values():
			slots.append_array(bucket)
	else:
		for offset_x: int in range(-span, span + 1):
			for offset_y: int in range(-span, span + 1):
				var bucket: Variant = _cells.get(_key(cell_x + offset_x, cell_y + offset_y))
				if bucket != null:
					slots.append_array(bucket as Array[int])
	slots.sort()
	var found: PackedInt64Array = PackedInt64Array()
	found.resize(slots.size())
	for index: int in range(slots.size()):
		found[index] = _ids[slots[index]]
	return found


static func _key(cell_x: int, cell_y: int) -> int:
	return (cell_x + KEY_OFFSET) * KEY_STRIDE + (cell_y + KEY_OFFSET)
