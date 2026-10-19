class_name FlowField
extends RefCounted
## An integer cost field over a NavGrid toward one goal (ENMY-04, RESEARCH Pattern 7 and F4): the
## cost of every open cell to the goal, built with Dial's bucket algorithm, and a direction per cell
## read lazily and blended bilinearly. Pure RefCounted code under simulation/: only integer costs,
## `+ - * /` and `sqrt` (DR-7), no Dictionary iteration, no clock or scene tree.
##
## The reads (cost_at, is_reached, direction_at and the per-cell direction cache behind it) run in
## C++ (PLAT-01, plan 04-18, native/src/native_field.cpp): build() finishes the costs here and hands
## them to the field's NativeField together with the grid's native mirror. The neighbour weighting
## of a direction (WALL_PENALTY 25, MIN_DIRECTION_LENGTH 0.000001, the unit offsets) lives there.
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

## The C++ side of the reads: the costs it was handed and the lazily filled direction cache.
var _native: NativeField = NativeField.new()
var _cost: PackedInt32Array = PackedInt32Array()
var _built_version: int = -1
var _reached: int = -1
var _goal: Vector2 = Vector2.ZERO
var _offsets: PackedInt32Array = PackedInt32Array()
var _steps: PackedInt32Array = PackedInt32Array([10, 10, 10, 10, 14, 14, 14, 14])


## Builds the field toward `goal`: the open cells whose centres lie within `goal_radius + margin`
## of it cost 0 (the open cell nearest to it when none does), every other reachable cell the
## cheapest route to one of them. Replaces the previous build.
func build(grid: NavGrid, goal: Vector2, goal_radius: float, margin: float) -> void:
	_goal = goal
	_built_version = grid.version()
	_reached = -1
	var width: int = grid.width()
	var count: int = width * grid.height()
	_cost.resize(count)
	_cost.fill(INF_COST)
	_offsets = PackedInt32Array(
		[1, -1, width, -width, width + 1, width - 1, -width + 1, -width - 1]
	)
	if grid.is_ready():
		var goals: PackedInt32Array = _goal_cells(grid, goal, goal_radius + margin)
		_dial(grid.blocked_mask(), goals, width)
	_native.set_costs(_cost, grid.native())


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
	return _native.cost_at(pos)


## True when a route from `pos` reaches the goal.
func is_reached(pos: Vector2) -> bool:
	return _native.is_reached(pos)


## The unit direction to walk from `pos` toward the goal: the four surrounding cell directions
## blended bilinearly and normalised. The zero vector when they are all zero (inside the goal,
## unreached, outside the grid). Each cell's direction is computed from the grid's live blocked mask
## the first time the cell is asked and kept until the next build().
func direction_at(pos: Vector2) -> Vector2:
	return _native.direction_at(pos)


## The C++ reads of this field, for the native callers of plan 04-19.
func native() -> NativeField:
	return _native


## How many open cells the last build reached (cost below INF_COST), the goal cells included.
## Blocked cells and the border are never reached. Read-only: counted once per build, on first ask.
func reached_count() -> int:
	if _reached < 0:
		_reached = 0
		for cost: int in _cost:
			if cost < INF_COST:
				_reached += 1
	return _reached


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
