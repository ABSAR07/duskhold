class_name TargetQuery
extends RefCounted
## Nearest-target queries behind one seam: every "who is closest" question the night asks goes
## through here. The enemy question is answered in C++ by EnemySystem.nearest_living (PLAT-01, plan
## 04-20) from its grid, without the callers noticing; the loops that stood here are gone. Pure
## functions over the EnemySystem API; nothing is stored.


## Id of the living enemy nearest `pos` whose centre is within `reach` (inclusive, squared-distance
## compare), or -1. Equally near enemies: the lower id wins (ids are scanned ascending and only a
## strictly nearer one replaces the best). Only the enemies in the grid cells around `pos` are
## tested, which includes every enemy within `reach`, so the answer is the full scan's.
static func nearest_enemy(enemies: EnemySystem, pos: Vector2, reach: float) -> int:
	return enemies.nearest_living(pos, reach)


## Like nearest_enemy, but only an enemy whose straight line from `pos` is clear of every intact
## wall segment counts, for a walker of `radius` metres (a melee unit cannot hit what it cannot
## reach). The nearest such enemy wins, equally near ones go to the lower id, and only a candidate
## that would improve the best pays for a line test. With no wall standing, or no `pathing`, it is
## exactly nearest_enemy.
static func nearest_enemy_clear(
	enemies: EnemySystem, pos: Vector2, reach: float, pathing: Pathing, radius: float
) -> int:
	if pathing == null or not pathing.has_intact_walls():
		return nearest_enemy(enemies, pos, reach)
	return enemies.nearest_living(pos, reach, radius, pathing.walls())
