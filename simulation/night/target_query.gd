class_name TargetQuery
extends RefCounted
## Nearest-target queries behind one seam: every "who is closest" question the night asks goes
## through here. Phase 4 replaces the bodies with a spatial hash without touching the callers
## (RESEARCH Pattern 3). Pure functions over the id-based EnemySystem API; nothing is stored.


## Id of the living enemy nearest `pos` whose centre is within `reach` (inclusive, squared-distance
## compare), or -1. Equally near enemies: the lower id wins (ids are scanned ascending and only a
## strictly nearer one replaces the best).
static func nearest_enemy(enemies: EnemySystem, pos: Vector2, reach: float) -> int:
	var best_id: int = -1
	var best_d2: float = INF
	var limit: float = reach * reach
	for id: int in enemies.ids():
		if not enemies.is_alive(id):
			continue
		var d2: float = pos.distance_squared_to(enemies.position_of(id))
		if d2 <= limit and d2 < best_d2:
			best_d2 = d2
			best_id = id
	return best_id
