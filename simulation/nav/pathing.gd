class_name Pathing
extends RefCounted
## The one steering and solidity facade the enemies, squads, king and bots use (RESEARCH Pattern 7).
## It answers where a circle may stand, which segment is in the way of a straight line and, since
## plan 04-06, which way round the walls an enemy marching on the castle should go: the nav grid
## and the castle flow field are rebuilt by refresh() once per step after the wall version changed
## (T-04-14), and march_step reads the field. With no intact segment every question is answered as
## if there were no walls, nothing is built, and a position comes back bit for bit as it went in
## (the replay goldens depend on it). Pure RefCounted code under simulation/: no clock, scene tree
## or engine navigation (DR-1 to DR-10).

var _map: MapConfig
var _walls: WallSystem
var _tuning: NavTuning
var _grid: NavGrid
var _castle_field: FlowField
## The wall version the grid and the castle field were last built for.
var _built_version: int = -1
var _field_version: int = 0


func _init(map: MapConfig, walls: WallSystem) -> void:
	_map = map
	_walls = walls
	_tuning = NavGrid.tuning_of(map)
	_grid = NavGrid.new(map, _tuning)


## True while at least one wall segment stands anywhere.
func has_intact_walls() -> bool:
	return _walls != null and _walls.intact_count() > 0


## The wall system this facade answers from.
func walls() -> WallSystem:
	return _walls


## Rebuilds the nav grid and the castle field when the wall version changed since they were built,
## at most once per call and so once per step however many segments fell. With no intact segment and
## nothing built yet it builds nothing. A grid over NavGrid.MAX_NAV_CELLS is never armed: no field
## exists and every step stays straight.
func refresh() -> void:
	if _walls == null or not _grid.is_armed() or _walls.version() == _built_version:
		return
	_built_version = _walls.version()
	if not has_intact_walls() and _castle_field == null:
		return
	_grid.rebuild(_walls)
	if _castle_field == null:
		_castle_field = FlowField.new()
	_castle_field.build(
		_grid,
		Vector2(_map.castle_position.x, _map.castle_position.z),
		_map.castle_radius,
		_tuning.goal_margin
	)
	_field_version += 1


## Counts the castle field rebuilds; a reader that cached something per field knows when to redo it.
func field_version() -> int:
	return _field_version


## The nav grid, armed or not.
func grid() -> NavGrid:
	return _grid


## The castle flow field; null until the first wall stood and while the grid is not armed.
func castle_field() -> FlowField:
	return _castle_field


## True while walls stand and no route is known from `pos` to the castle: the castle field is
## missing (an unarmed grid, or not refreshed yet) or the cell of `pos` is walled off from it. A
## sealed enemy attacks the segment in its way instead of walking round.
func is_sealed(pos: Vector2) -> bool:
	if not has_intact_walls():
		return false
	return _castle_field == null or not _castle_field.is_reached(pos)


## The cost of the route from `pos` to the castle (10 per cell, 14 per diagonal); FlowField.INF_COST
## when there is none or no field exists.
func castle_cost_at(pos: Vector2) -> int:
	return _castle_field.cost_at(pos) if _castle_field != null else FlowField.INF_COST


## The step of an enemy at `pos` marching on the castle round the walls, `max_distance` long: the
## field direction, or the exact straight step of EnemySystem.desired_step when there is no field
## or no direction there.
func march_step(pos: Vector2, max_distance: float) -> Vector2:
	if _castle_field != null:
		var direction: Vector2 = _castle_field.direction_at(pos)
		if direction != Vector2.ZERO:
			return direction * maxf(max_distance, 0.0)
	return EnemySystem.desired_step(
		pos, Vector2(_map.castle_position.x, _map.castle_position.z), max_distance
	)


## `pos` moved out of every intact segment, for a circle of `radius` metres; unchanged when no
## segment stands.
func push_out(pos: Vector2, radius: float) -> Vector2:
	if not has_intact_walls():
		return pos
	return WallSolids.push_out(_walls, pos, radius)


## The intact segment in the way of a circle of `radius` metres walking from `from` to `to`; -1
## when the line is clear.
func first_blocking(from: Vector2, to: Vector2, radius: float) -> int:
	if not has_intact_walls():
		return -1
	return WallSolids.first_blocking(_walls, from, to, radius)


## The point of the segment nearest `pos`.
func closest_point(segment: int, pos: Vector2) -> Vector2:
	if _walls == null:
		return Vector2.ZERO
	return WallSolids.closest_point(_walls, segment, pos)
