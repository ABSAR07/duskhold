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
##
## The castle routing (is_sealed with its probe off a blocking wall, castle_cost_at,
## castle_distance_cm, detour_ticks, straight_ticks and march_step) runs in C++ through one
## NativeRoute (PLAT-01, plan 04-18, native/src/native_field.cpp), which refresh() keeps pointed at
## the castle field; the methods below keep their signatures and delegate.

var _map: MapConfig
var _walls: WallSystem
var _tuning: NavTuning
var _grid: NavGrid
var _castle_field: FlowField
## The break-or-detour decision of plan 04-07 (D-07, D-08), fed by EnemySystem once per step.
var _decision: WallDecision
## The read-only stuck-enemy flags of plan 04-07 (D-09), updated by NightSim after the enemy phase.
var _stuck: StuckTracker
## The squads' goal-field cache, created on the first routed walk.
var _squad_cache: GoalFieldCache
## The wall version the grid and the castle field were last built for.
var _built_version: int = -1
var _field_version: int = 0
## The castle routing in C++: the grid and wall mirrors, the castle and, once it exists, the field.
var _route: NativeRoute = NativeRoute.new()


func _init(map: MapConfig, walls: WallSystem) -> void:
	_map = map
	_walls = walls
	_tuning = NavGrid.tuning_of(map)
	_grid = NavGrid.new(map, _tuning)
	_decision = WallDecision.new(walls, _tuning)
	var castle: Vector2 = Vector2.ZERO
	if map != null:
		castle = Vector2(map.castle_position.x, map.castle_position.z)
	_stuck = StuckTracker.new(_tuning, _tuning.cell_size, castle)
	var wall_mirror: NativeWalls = walls.native() if walls != null else null
	_route.set_world(_grid.native(), wall_mirror, castle, _tuning.cell_size)


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
		_route.set_castle_field(_castle_field.native())
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
	return _route.is_sealed(pos)


## The cost of the route from `pos` to the castle (10 per cell, 14 per diagonal); FlowField.INF_COST
## when there is none or no field exists.
func castle_cost_at(pos: Vector2) -> int:
	return _route.castle_cost_at(pos)


## The per-segment time to destruction and the break-or-detour rule (D-07, D-08).
func decision() -> WallDecision:
	return _decision


## Which enemies have made no progress toward the castle (D-09); read-only.
func stuck() -> StuckTracker:
	return _stuck


## The straight distance from `pos` to the castle's centre in whole centimetres.
func castle_distance_cm(pos: Vector2) -> int:
	return _route.castle_distance_cm(pos)


## Ticks an enemy at `pos` needs to walk the castle field's route to the castle at
## `speed_cm_per_s`, rounded up; SimClock.MAX_TICKS when there is no route (sealed, or no field).
func detour_ticks(pos: Vector2, speed_cm_per_s: int) -> int:
	return _route.detour_ticks(pos, speed_cm_per_s)


## Ticks an enemy at `pos` needs to walk the straight line to the castle's centre at
## `speed_cm_per_s`, rounded up.
func straight_ticks(pos: Vector2, speed_cm_per_s: int) -> int:
	return _route.straight_ticks(pos, speed_cm_per_s)


## The step of an enemy at `pos` marching on the castle round the walls, `max_distance` long: the
## field direction, or the exact straight step of EnemySystem.desired_step when there is no field
## or no direction there.
func march_step(pos: Vector2, max_distance: float) -> Vector2:
	return _route.march_step(pos, max_distance)


## The step of a unit or the bot king at `pos` walking to `goal`, `max_distance` long, for a circle
## of `radius` metres and a target of `goal_radius`. While a wall stands and the straight line is
## blocked the step follows the flow field toward the goal, taken from `cache` (the facade's own
## cache when null) at `tick`; with no wall, a clear line, no field this tick (its build budget is
## spent, T-04-15) or no direction, it is exactly EnemySystem.desired_step. `known_blocked` lets a
## caller that cached the line test say so: -1 tests now, 0 the line is clear, 1 it is blocked.
func walk_step(
	pos: Vector2,
	goal: Vector2,
	max_distance: float,
	radius: float,
	goal_radius: float,
	tick: int,
	cache: GoalFieldCache = null,
	known_blocked: int = -1
) -> Vector2:
	if not has_intact_walls() or not _grid.is_ready():
		return EnemySystem.desired_step(pos, goal, max_distance)
	var blocked: int = known_blocked
	if blocked < 0:
		blocked = 1 if first_blocking(pos, goal, radius) >= 0 else 0
	if blocked == 0:
		return EnemySystem.desired_step(pos, goal, max_distance)
	var used: GoalFieldCache = cache if cache != null else _own_cache()
	var field: FlowField = used.field_for(goal, goal_radius, tick)
	if field != null:
		var direction: Vector2 = field.direction_at(pos)
		if direction != Vector2.ZERO:
			return direction * maxf(max_distance, 0.0)
	return EnemySystem.desired_step(pos, goal, max_distance)


## A goal-field cache of a caller's own over the shared grid, so the caller never spends the budget
## of the squads' cache (the bot king keeps one).
func new_goal_cache() -> GoalFieldCache:
	return GoalFieldCache.new(_grid, _tuning)


## The key of the goal-quantum square holding `goal`; goals with one key share a cached field.
func goal_key(goal: Vector2) -> int:
	return GoalFieldCache.key_of(goal, _tuning.goal_quantum)


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


func _own_cache() -> GoalFieldCache:
	if _squad_cache == null:
		_squad_cache = new_goal_cache()
	return _squad_cache
