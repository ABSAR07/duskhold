class_name Pathing
extends RefCounted
## The one steering and solidity facade the enemies, squads, king and bots use (RESEARCH Pattern 7).
## In this plan it answers from the walls alone: where a circle may stand and which segment is in
## the way of a straight line. Plan 04-06 adds the flow field behind the same calls, so no caller
## changes. With no intact segment every question is answered as if there were no walls, and a
## position comes back bit for bit as it went in (the replay goldens depend on it).
## Pure RefCounted code under simulation/: no clock, scene tree or engine navigation
## (DR-1 to DR-10).

var _walls: WallSystem


func _init(_map: MapConfig, walls: WallSystem) -> void:
	_walls = walls


## True while at least one wall segment stands anywhere.
func has_intact_walls() -> bool:
	return _walls != null and _walls.intact_count() > 0


## The wall system this facade answers from.
func walls() -> WallSystem:
	return _walls


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
