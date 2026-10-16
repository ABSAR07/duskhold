class_name TargetQuery
extends RefCounted
## Nearest-target queries behind one seam: every "who is closest" question the night asks goes
## through here. The enemy question reads its candidates from EnemySystem's grid (PLAT-01) without
## the callers noticing. Pure functions over the EnemySystem API; nothing is stored.


## Id of the living enemy nearest `pos` whose centre is within `reach` (inclusive, squared-distance
## compare), or -1. Equally near enemies: the lower id wins (ids are scanned ascending and only a
## strictly nearer one replaces the best). Only the enemies in the grid cells around `pos` are
## tested, which includes every enemy within `reach`, so the answer is the full scan's.
static func nearest_enemy(enemies: EnemySystem, pos: Vector2, reach: float) -> int:
	var best_id: int = -1
	var best_d2: float = INF
	var limit: float = reach * reach
	for id: int in enemies.living_within(pos, reach):
		if not enemies.is_alive(id):
			continue
		var d2: float = pos.distance_squared_to(enemies.position_of(id))
		if d2 <= limit and d2 < best_d2:
			best_d2 = d2
			best_id = id
	return best_id
