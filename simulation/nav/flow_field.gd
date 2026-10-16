class_name FlowField
extends RefCounted
## An integer cost field over a NavGrid toward one goal (ENMY-04, RESEARCH Pattern 7 and F4): the
## cost of every open cell to the goal, built with Dial's bucket algorithm, and a direction per cell
## read lazily and blended bilinearly. Pure RefCounted code under simulation/: only integer costs,
## `+ - * /` and `sqrt` (DR-7), no Dictionary iteration, no clock or scene tree.
##
## Step costs are 10 for an orthogonal and 14 for a diagonal move. A diagonal step is skipped when
## either orthogonal neighbour is blocked, so no route cuts a wall's corner. Every cell is finalised
## once, at the cost its bucket is popped at. Two builds over one grid give identical cost arrays.
## The buckets are flat parallel arrays: an Array of PackedInt32Arrays would append to copies (F4).

## The cost of a cell no route reaches (blocked, or walled off from the goal).
const INF_COST: int = 1 << 30
const STEP_ORTHOGONAL: int = 10
const STEP_DIAGONAL: int = 14
## Slots of the circular bucket ring: the longest step plus one, so a slot holds one distance.
const BUCKET_SLOTS: int = 15
## A blocked or unreached neighbour counts as this much dearer than the cell being read, so a
## direction bends away from walls.
const WALL_PENALTY: int = 25
## sqrt(0.5): the unit offset of a diagonal neighbour.
const DIAGONAL_UNIT: float = 0.7071067811865476
## A blended direction shorter than this is no direction at all.
const MIN_DIRECTION_LENGTH: float = 0.000001

var _grid: NavGrid
var _cost: PackedInt32Array = PackedInt32Array()
var _dir_x: PackedFloat32Array = PackedFloat32Array()
var _dir_y: PackedFloat32Array = PackedFloat32Array()
var _stamp: PackedInt32Array = PackedInt32Array()
var _generation: int = 0
var _built_version: int = -1
var _goal: Vector2 = Vector2.ZERO
var _offsets: PackedInt32Array = PackedInt32Array()
var _steps: PackedInt32Array = PackedInt32Array([10, 10, 10, 10, 14, 14, 14, 14])
var _unit_x: PackedFloat32Array = PackedFloat32Array(
	[1.0, -1.0, 0.0, 0.0, DIAGONAL_UNIT, -DIAGONAL_UNIT, DIAGONAL_UNIT, -DIAGONAL_UNIT]
)
var _unit_y: PackedFloat32Array = PackedFloat32Array(
	[0.0, 0.0, 1.0, -1.0, DIAGONAL_UNIT, DIAGONAL_UNIT, -DIAGONAL_UNIT, -DIAGONAL_UNIT]
)


## Builds the field toward `goal`: the open cells whose centres lie within `goal_radius + margin`
## of it cost 0 (the open cell nearest to it when none does), every other reachable cell the
## cheapest route to one of them. Replaces the previous build.
func build(grid: NavGrid, goal: Vector2, goal_radius: float, margin: float) -> void:
	_grid = grid
	_goal = goal
	_built_version = grid.version()
	var width: int = grid.width()
	var count: int = width * grid.height()
	_cost.resize(count)
	_cost.fill(INF_COST)
	_dir_x.resize(count)
	_dir_y.resize(count)
	_stamp.resize(count)
	_generation += 1
	_offsets = PackedInt32Array(
		[1, -1, width, -width, width + 1, width - 1, -width + 1, -width - 1]
	)
	if not grid.is_ready():
		return
	var goals: PackedInt32Array = _goal_cells(grid, goal, goal_radius + margin)
	_dial(grid.blocked_mask(), goals, width)


## The grid version this field was built at; a field is stale once the grid has been rebuilt.
func built_version() -> int:
	return _built_version


## The goal the field was built toward.
func goal() -> Vector2:
	return _goal


## The cost of the route from `pos` to the goal (10 per orthogonal cell, 14 per diagonal). A
## position in a blocked cell reads the cheapest open neighbour plus its step; INF_COST outside the
## grid, in a walled-off region and on the border.
func cost_at(pos: Vector2) -> int:
	if _grid == null:
		return INF_COST
	var cell: int = _grid.cell_of(pos)
	if cell < 0 or cell >= _cost.size():
		return INF_COST
	if _cost[cell] < INF_COST:
		return _cost[cell]
	if _grid.is_border(cell) or not _grid.is_blocked(cell):
		return INF_COST
	var best: int = INF_COST
	for index: int in range(_offsets.size()):
		var next: int = _cost[cell + _offsets[index]]
		if next < INF_COST:
			best = mini(best, next + _steps[index])
	return best


## True when a route from `pos` reaches the goal.
func is_reached(pos: Vector2) -> bool:
	return cost_at(pos) < INF_COST


## The unit direction to walk from `pos` toward the goal: the four surrounding cell directions
## blended bilinearly and normalised. The zero vector when they are all zero (inside the goal,
## unreached, outside the grid).
func direction_at(pos: Vector2) -> Vector2:
	if _grid == null or _cost.is_empty() or not _grid.is_ready():
		return Vector2.ZERO
	var size: float = _grid.cell_size()
	var origin: Vector2 = _grid.origin()
	var fraction_x: float = (pos.x - origin.x) / size - 0.5
	var fraction_y: float = (pos.y - origin.y) / size - 0.5
	var cell_x: int = floori(fraction_x)
	var cell_y: int = floori(fraction_y)
	var weight_x: float = fraction_x - float(cell_x)
	var weight_y: float = fraction_y - float(cell_y)
	var near: Vector2 = _cell_direction_at(cell_x, cell_y).lerp(
		_cell_direction_at(cell_x + 1, cell_y), weight_x
	)
	var far: Vector2 = _cell_direction_at(cell_x, cell_y + 1).lerp(
		_cell_direction_at(cell_x + 1, cell_y + 1), weight_x
	)
	var blended: Vector2 = near.lerp(far, weight_y)
	var squared: float = blended.length_squared()
	if squared <= MIN_DIRECTION_LENGTH * MIN_DIRECTION_LENGTH:
		return Vector2.ZERO
	return blended / sqrt(squared)


## RED stub.
func reached_count() -> int:
	return 0


## The cost array, for tests that compare two builds.
func costs() -> PackedInt32Array:
	return _cost


## Open cells whose centres lie within `reach` of `goal`; failing that the cell holding the goal
## or the nearest open cell among the nine around it. Ascending cell index.
func _goal_cells(grid: NavGrid, goal: Vector2, reach: float) -> PackedInt32Array:
	var goals: PackedInt32Array = PackedInt32Array()
	var width: int = grid.width()
	var size: float = grid.cell_size()
	var home: int = grid.cell_of(goal)
	if home < 0:
		return goals
	var span: int = ceili(maxf(reach, 0.0) / size) + 1
	var home_x: int = home % width
	var home_y: int = floori(float(home) / float(width))
	var nearest: int = -1
	var nearest_distance: float = INF
	for cell_y: int in range(maxi(home_y - span, 1), mini(home_y + span, grid.height() - 2) + 1):
		for cell_x: int in range(maxi(home_x - span, 1), mini(home_x + span, width - 2) + 1):
			var cell: int = cell_y * width + cell_x
			if grid.is_blocked(cell):
				continue
			var distance: float = grid.centre_of(cell).distance_to(goal)
			if distance <= reach:
				goals.append(cell)
			if absi(cell_x - home_x) <= 1 and absi(cell_y - home_y) <= 1:
				if distance < nearest_distance:
					nearest_distance = distance
					nearest = cell
	if goals.is_empty() and nearest >= 0:
		goals.append(nearest)
	return goals


## Dial's algorithm over a ring of BUCKET_SLOTS buckets. Entries are (cell, next) pairs in flat
## arrays; a cell can be queued more than once and its stale entries are skipped when popped.
func _dial(blocked: PackedByteArray, goals: PackedInt32Array, width: int) -> void:
	var head: PackedInt32Array = PackedInt32Array()
	head.resize(BUCKET_SLOTS)
	head.fill(-1)
	var entry_cell: PackedInt32Array = PackedInt32Array()
	var entry_next: PackedInt32Array = PackedInt32Array()
	entry_cell.resize(_cost.size() * 2)
	entry_next.resize(_cost.size() * 2)
	var used: int = 0
	var pending: int = 0
	for goal: int in goals:
		_cost[goal] = 0
		entry_cell[used] = goal
		entry_next[used] = head[0]
		head[0] = used
		used += 1
		pending += 1
	var side_a: PackedInt32Array = PackedInt32Array([1, -1, 1, -1])
	var side_b: PackedInt32Array = PackedInt32Array([width, width, -width, -width])
	var distance: int = 0
	while pending > 0:
		var slot: int = distance % BUCKET_SLOTS
		var entry: int = head[slot]
		if entry == -1:
			distance += 1
			continue
		head[slot] = entry_next[entry]
		pending -= 1
		var here: int = entry_cell[entry]
		if _cost[here] != distance:
			continue
		for index: int in range(8):
			var next: int = here + _offsets[index]
			if blocked[next] != 0:
				continue
			if (
				index >= 4
				and (
					blocked[here + side_a[index - 4]] != 0 or blocked[here + side_b[index - 4]] != 0
				)
			):
				continue
			var next_cost: int = distance + _steps[index]
			if next_cost >= _cost[next]:
				continue
			_cost[next] = next_cost
			if used >= entry_cell.size():
				entry_cell.resize(used * 2)
				entry_next.resize(used * 2)
			var next_slot: int = next_cost % BUCKET_SLOTS
			entry_cell[used] = next
			entry_next[used] = head[next_slot]
			head[next_slot] = used
			used += 1
			pending += 1


## The direction of cell (cell_x, cell_y); zero outside the grid.
func _cell_direction_at(cell_x: int, cell_y: int) -> Vector2:
	var width: int = _grid.width()
	if cell_x < 0 or cell_y < 0 or cell_x >= width or cell_y >= _grid.height():
		return Vector2.ZERO
	var cell: int = cell_y * width + cell_x
	if _stamp[cell] != _generation:
		_compute_direction(cell)
	return Vector2(_dir_x[cell], _dir_y[cell])


## Fills the direction of one cell. An open reached cell sums the unit offsets of its neighbours
## weighted by how much cheaper they are; a blocked cell points at its cheapest open neighbour; the
## border and unreached cells have none.
func _compute_direction(cell: int) -> void:
	_stamp[cell] = _generation
	_dir_x[cell] = 0.0
	_dir_y[cell] = 0.0
	if _grid.is_border(cell):
		return
	var here: int = _cost[cell]
	var blocked: PackedByteArray = _grid.blocked_mask()
	if blocked[cell] != 0:
		_point_at_cheapest(cell)
		return
	if here >= INF_COST:
		return
	var sum_x: float = 0.0
	var sum_y: float = 0.0
	for index: int in range(8):
		var next: int = cell + _offsets[index]
		var next_cost: int = here + WALL_PENALTY
		if blocked[next] == 0 and _cost[next] < INF_COST:
			next_cost = _cost[next]
		var gain: float = float(here - next_cost)
		sum_x += _unit_x[index] * gain
		sum_y += _unit_y[index] * gain
	var squared: float = sum_x * sum_x + sum_y * sum_y
	if squared <= 0.0:
		return
	var length: float = sqrt(squared)
	_dir_x[cell] = sum_x / length
	_dir_y[cell] = sum_y / length


## A blocked cell points at its cheapest reached neighbour (the first in neighbour order on a tie).
func _point_at_cheapest(cell: int) -> void:
	var best: int = INF_COST
	var best_index: int = -1
	for index: int in range(8):
		var next_cost: int = _cost[cell + _offsets[index]]
		if next_cost < best:
			best = next_cost
			best_index = index
	if best_index >= 0:
		_dir_x[cell] = _unit_x[best_index]
		_dir_y[cell] = _unit_y[best_index]
