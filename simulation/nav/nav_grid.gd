class_name NavGrid
extends RefCounted
## The ground as a grid of cells (ENMY-04, RESEARCH Pattern 7): which cells an intact wall segment
## blocks and which segment owns each blocked cell. The castle field and the goal fields are built
## over it. Pure RefCounted code under simulation/: no scene tree, clock or engine navigation
## (DR-1 to DR-10); only `+ - * /`, `sqrt`, `floor` and `ceil` are used (DR-7).
##
## The grid covers the map's content (castle, king spawn, every spot, spawn point and wall end)
## plus a margin, never ground_half_extent, which may be 10,000 m (T-04-13). A grid that would
## exceed MAX_NAV_CELLS is not armed and allocates nothing: the map runs on straight steps only.
## A one-cell border is always blocked, so a neighbour index never leaves the arrays. Nothing is
## allocated before the first rebuild(), and a map with no wall never calls it.
##
## A cell is blocked when its centre lies within the segment's half thickness plus `inflate` (the
## largest ground agent radius on the map) of an intact segment. With cells wider than that band a
## straight wall could fall between two columns of centres and leak, so a cell is also blocked
## when the move from its centre to a neighbour's would cut a segment's centre line (RESEARCH F5:
## no route may leak through a wall at any angle or offset). The flow field never steps diagonally
## past a blocked orthogonal neighbour.

## A guard against a bad data file, like MapConfig.MAX_ENEMIES_PER_NIGHT: above this many cells the
## grid is not armed.
const MAX_NAV_CELLS: int = 40000
## The inflate used when a map names no enemy or unit.
const DEFAULT_INFLATE: float = 0.5
## Metres a segment is lengthened at an end it shares with another intact segment, so a move that
## passes exactly through a joint is caught by the crossing test (float rounding on the joint).
const JOINT_EXTENSION: float = 0.02
const CENTIMETRES: float = 100.0
## Forward neighbours of the crossing test: east, south, south-east, south-west (dx, dz).
const FORWARD_DX: Array[int] = [1, 0, 1, -1]
const FORWARD_DZ: Array[int] = [0, 1, 1, 1]

var _cell: float = 2.0
var _origin: Vector2 = Vector2.ZERO
var _width: int = 0
var _height: int = 0
var _armed: bool = false
var _inflate: float = DEFAULT_INFLATE
var _blocked: PackedByteArray = PackedByteArray()
var _owner: PackedInt32Array = PackedInt32Array()
var _version: int = 0
## The C++ copy of the layout and the masks (native/src/native_field.cpp), refreshed at the end of
## every rebuild(), so the native field reads see the mask the GDScript reads see.
var _native: NativeGrid = NativeGrid.new()


func _init(map: MapConfig, tuning: NavTuning = null) -> void:
	var used: NavTuning = tuning if tuning != null else tuning_of(map)
	var layout: PackedFloat64Array = _layout(map, used)
	_inflate = largest_radius_of(map)
	if layout.is_empty() or layout[2] * layout[3] > float(MAX_NAV_CELLS):
		return
	_cell = used.cell_size
	_origin = Vector2(layout[0], layout[1])
	_width = int(layout[2])
	_height = int(layout[3])
	_armed = true
	_native.set_layout(true, _origin, _cell, _width, _height)


## The pathing tunables of a map: its own, else the defaults.
static func tuning_of(map: MapConfig) -> NavTuning:
	if map != null and map.nav_tuning != null:
		return map.nav_tuning
	return NavTuning.new()


## How many cells the grid over `map` would have, border included, computed without allocating. A
## map whose numbers cannot size a grid (a NaN, a zero or negative cell size, nothing finite to
## cover) reports MAX_NAV_CELLS + 1, and a huge count saturates at 2,000,000,000.
static func cell_count_for(map: MapConfig, tuning: NavTuning) -> int:
	var layout: PackedFloat64Array = _layout(map, tuning)
	if layout.is_empty():
		return MAX_NAV_CELLS + 1
	return int(minf(layout[2] * layout[3], 2000000000.0))


## True when the grid fits MAX_NAV_CELLS and can be rebuilt.
func is_armed() -> bool:
	return _armed


## True once rebuild() has run on an armed grid, so the masks exist.
func is_ready() -> bool:
	return _armed and _version > 0


## Counts the rebuilds; every field built over the grid carries the count it was built at.
func version() -> int:
	return _version


func width() -> int:
	return _width


func height() -> int:
	return _height


## Cells the masks hold: 0 until the first rebuild, and always 0 on an unarmed grid.
func allocated_cells() -> int:
	return _blocked.size()


## The edge of a cell in metres.
func cell_size() -> float:
	return _cell


## The corner of the grid with the least coordinates, in metres.
func origin() -> Vector2:
	return _origin


## The blocked mask itself (1 = blocked), shared and never modified by the caller.
func blocked_mask() -> PackedByteArray:
	return _blocked


## The C++ mirror of the layout and the masks, in step with the last rebuild().
func native() -> NativeGrid:
	return _native


## Index of the cell holding `pos`, border cells included; -1 outside the grid or when unarmed.
func cell_of(pos: Vector2) -> int:
	if not _armed:
		return -1
	var cell_x: int = floori((pos.x - _origin.x) / _cell)
	var cell_y: int = floori((pos.y - _origin.y) / _cell)
	if cell_x < 0 or cell_y < 0 or cell_x >= _width or cell_y >= _height:
		return -1
	return cell_y * _width + cell_x


## The centre of a cell in metres.
@warning_ignore("integer_division")
func centre_of(cell: int) -> Vector2:
	var cell_x: int = cell % _width
	var cell_y: int = cell / _width
	return _origin + Vector2((float(cell_x) + 0.5) * _cell, (float(cell_y) + 0.5) * _cell)


## True for a blocked cell, a border cell and an index outside the grid.
func is_blocked(cell: int) -> bool:
	return cell < 0 or cell >= _blocked.size() or _blocked[cell] != 0


## True for the always-blocked outer ring of cells.
@warning_ignore("integer_division")
func is_border(cell: int) -> bool:
	var cell_x: int = cell % _width
	var cell_y: int = cell / _width
	return cell_x == 0 or cell_y == 0 or cell_x == _width - 1 or cell_y == _height - 1


## The wall segment that blocked the cell; -1 for an open cell and the border.
func owner_of(cell: int) -> int:
	return _owner[cell] if cell >= 0 and cell < _owner.size() else -1


## Re-rasterises every intact segment of `walls`, then bumps version(). Allocates the masks on the
## first call. Does nothing on an unarmed grid.
func rebuild(walls: WallSystem) -> void:
	if not _armed or walls == null:
		return
	if _blocked.is_empty():
		_blocked.resize(_width * _height)
		_owner.resize(_width * _height)
	_blocked.fill(0)
	_owner.fill(-1)
	_mark_border()
	var joints: Dictionary = _joints_of(walls)
	for segment: int in range(walls.segment_count()):
		if walls.is_intact(segment):
			_mark_near(walls, segment)
	for segment: int in range(walls.segment_count()):
		if walls.is_intact(segment):
			_mark_crossed(walls, segment, joints)
	_version += 1
	_native.set_masks(_blocked, _owner)


## The least and greatest cell index of a box of metres, clamped to the inner cells.
func _cell_range(low: Vector2, high: Vector2) -> Rect2i:
	var first_x: int = clampi(floori((low.x - _origin.x) / _cell), 1, _width - 2)
	var first_y: int = clampi(floori((low.y - _origin.y) / _cell), 1, _height - 2)
	var last_x: int = clampi(floori((high.x - _origin.x) / _cell), 1, _width - 2)
	var last_y: int = clampi(floori((high.y - _origin.y) / _cell), 1, _height - 2)
	return Rect2i(first_x, first_y, last_x - first_x, last_y - first_y)


func _mark_border() -> void:
	for cell_x: int in range(_width):
		_blocked[cell_x] = 1
		_blocked[(_height - 1) * _width + cell_x] = 1
	for cell_y: int in range(_height):
		_blocked[cell_y * _width] = 1
		_blocked[cell_y * _width + _width - 1] = 1


func _block(cell: int, segment: int) -> void:
	_blocked[cell] = 1
	if _owner[cell] < 0:
		_owner[cell] = segment


## Blocks the cells whose centres lie within half thickness plus inflate of the segment.
func _mark_near(walls: WallSystem, segment: int) -> void:
	var start: Vector2 = walls.segment_start(segment)
	var end: Vector2 = walls.segment_end(segment)
	var reach: float = walls.half_thickness_of(segment) + _inflate
	var low: Vector2 = Vector2(minf(start.x, end.x), minf(start.y, end.y)) - Vector2(reach, reach)
	var high: Vector2 = Vector2(maxf(start.x, end.x), maxf(start.y, end.y)) + Vector2(reach, reach)
	var box: Rect2i = _cell_range(low, high)
	for cell_y: int in range(box.position.y, box.position.y + box.size.y + 1):
		for cell_x: int in range(box.position.x, box.position.x + box.size.x + 1):
			var cell: int = cell_y * _width + cell_x
			var centre: Vector2 = centre_of(cell)
			if centre.distance_to(WallSolids.closest_point(walls, segment, centre)) <= reach:
				_block(cell, segment)


## Blocks the first cell of every move to a neighbour that cuts the segment's centre line, so no
## route leaks between two columns of centres that both lie outside the near band.
func _mark_crossed(walls: WallSystem, segment: int, joints: Dictionary) -> void:
	var start: Vector2 = walls.segment_start(segment)
	var end: Vector2 = walls.segment_end(segment)
	var along: Vector2 = end - start
	if along.length_squared() <= 0.0:
		return
	var direction: Vector2 = along.normalized()
	if int(joints.get(_key_of(start), 0)) > 1:
		start -= direction * JOINT_EXTENSION
	if int(joints.get(_key_of(end), 0)) > 1:
		end += direction * JOINT_EXTENSION
	var low: Vector2 = Vector2(minf(start.x, end.x), minf(start.y, end.y))
	var high: Vector2 = Vector2(maxf(start.x, end.x), maxf(start.y, end.y))
	var box: Rect2i = _cell_range(low - Vector2(_cell, _cell), high + Vector2(_cell, _cell))
	for cell_y: int in range(box.position.y, box.position.y + box.size.y + 1):
		for cell_x: int in range(box.position.x, box.position.x + box.size.x + 1):
			var cell: int = cell_y * _width + cell_x
			if _blocked[cell] == 0 and _move_cuts(cell, cell_x, cell_y, start, end):
				_block(cell, segment)


## True when a move from `cell` to one of its four forward neighbours (both open) crosses the line
## from `start` to `end` properly (touching an end does not count).
func _move_cuts(cell: int, cell_x: int, cell_y: int, start: Vector2, end: Vector2) -> bool:
	var here: Vector2 = centre_of(cell)
	for index: int in range(FORWARD_DX.size()):
		var next_x: int = cell_x + FORWARD_DX[index]
		var next_y: int = cell_y + FORWARD_DZ[index]
		if next_x < 0 or next_x >= _width or next_y >= _height:
			continue
		var next: int = next_y * _width + next_x
		if _blocked[next] != 0:
			continue
		var there: Vector2 = centre_of(next)
		var side_start: float = (there - here).cross(start - here)
		var side_end: float = (there - here).cross(end - here)
		var side_here: float = (end - start).cross(here - start)
		var side_there: float = (end - start).cross(there - start)
		if side_start * side_end < 0.0 and side_here * side_there < 0.0:
			return true
	return false


## How many intact segments end at each point, keyed by the point in centimetres.
func _joints_of(walls: WallSystem) -> Dictionary:
	var counts: Dictionary = {}
	for segment: int in range(walls.segment_count()):
		if not walls.is_intact(segment):
			continue
		for point: Vector2 in [walls.segment_start(segment), walls.segment_end(segment)]:
			var key: int = _key_of(point)
			counts[key] = int(counts.get(key, 0)) + 1
	return counts


static func _key_of(point: Vector2) -> int:
	return CellKey.pack(roundi(point.x * CENTIMETRES), roundi(point.y * CENTIMETRES))


## The largest radius among the map's enemies and units; DEFAULT_INFLATE when it names none.
## WallValidation reads it to size the narrowest routable gap.
static func largest_radius_of(map: MapConfig) -> float:
	var largest: float = 0.0
	if map == null:
		return DEFAULT_INFLATE
	for enemy: EnemyDef in map.enemies:
		if enemy != null and is_finite(enemy.radius):
			largest = maxf(largest, enemy.radius)
	for unit: UnitDef in map.units:
		if unit != null and is_finite(unit.radius):
			largest = maxf(largest, unit.radius)
	return largest if largest > 0.0 else DEFAULT_INFLATE


## [origin x, origin z, cells along x, cells along z] of the grid over the map's content, or an
## empty array when the numbers cannot size one. The cell counts are floats so a huge map is
## measured without overflowing.
static func _layout(map: MapConfig, tuning: NavTuning) -> PackedFloat64Array:
	var none: PackedFloat64Array = PackedFloat64Array()
	if map == null or tuning == null:
		return none
	var cell: float = tuning.cell_size
	var margin: float = tuning.bounds_margin
	if not is_finite(cell) or cell <= 0.0 or not is_finite(margin) or margin < 0.0:
		return none
	var bounds: PackedVector2Array = _content_bounds(map)
	if bounds.is_empty():
		return none
	var origin_x: float = floorf((bounds[0].x - margin) / cell) * cell - cell
	var origin_z: float = floorf((bounds[0].y - margin) / cell) * cell - cell
	var cells_x: float = ceilf((bounds[1].x + margin - origin_x) / cell) + 1.0
	var cells_z: float = ceilf((bounds[1].y + margin - origin_z) / cell) + 1.0
	return PackedFloat64Array([origin_x, origin_z, cells_x, cells_z])


## [least, greatest] corner of everything the grid must cover; empty when nothing finite exists.
static func _content_bounds(map: MapConfig) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	points.append(Vector2(map.castle_position.x, map.castle_position.z))
	points.append(Vector2(map.king_spawn.x, map.king_spawn.z))
	for spot: BuildSpotDef in map.spots:
		if spot == null:
			continue
		points.append(Vector2(spot.position.x, spot.position.z))
		if spot.wall_run != null:
			points.append_array(spot.wall_run.points)
	for spawn_point: SpawnPointDef in map.spawn_points:
		if spawn_point == null:
			continue
		var scatter: float = (
			spawn_point.scatter_radius if is_finite(spawn_point.scatter_radius) else 0.0
		)
		var at: Vector2 = Vector2(spawn_point.position.x, spawn_point.position.z)
		points.append(at - Vector2(scatter, scatter))
		points.append(at + Vector2(scatter, scatter))
	var low: Vector2 = Vector2(INF, INF)
	var high: Vector2 = Vector2(-INF, -INF)
	for point: Vector2 in points:
		if not is_finite(point.x) or not is_finite(point.y):
			continue
		low = Vector2(minf(low.x, point.x), minf(low.y, point.y))
		high = Vector2(maxf(high.x, point.x), maxf(high.y, point.y))
	if not is_finite(low.x) or not is_finite(high.x):
		return PackedVector2Array()
	return PackedVector2Array([low, high])
