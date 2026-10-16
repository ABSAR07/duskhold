class_name WallSolids
extends RefCounted
## The solid test of the walls (D-04, RESEARCH Pattern 6): where a circle may stand and which
## segment is in the way of a straight line. Static and pure: it reads a WallSystem and changes
## nothing, so the enemies, the squads, the king and the bots all apply the same rule.
##
## Only intact segments are solid (D-05): a broken or unbuilt one pushes nothing and blocks nothing.
## Determinism-sensitive like Separation: only `+ - * /` and `sqrt` are used (DR-7), candidates are
## visited in ascending segment index, and a position exactly on a segment is pushed along the
## segment's fixed left normal, never a random side.

## A circle is pushed out of one segment at a time; a push can land it in a neighbour, so the pass
## repeats this many times at most.
const MAX_PASSES: int = 3
## Added to the reach of a bucket query so float rounding on a cell border never hides a segment.
const REACH_MARGIN: float = 0.01


## The point of the segment nearest `pos`, clamped to its two ends. An index out of range gives the
## zero vector.
static func closest_point(walls: WallSystem, segment: int, pos: Vector2) -> Vector2:
	return _closest_on(walls.segment_start(segment), walls.segment_end(segment), pos)


## `pos` moved out of every intact segment it overlaps, so a circle of `radius` metres at the result
## is at least half_thickness + radius from each of them. A position that overlaps none is returned
## exactly as given, bit for bit, so a map with no intact wall never feels this function.
static func push_out(walls: WallSystem, pos: Vector2, radius: float) -> Vector2:
	if walls.intact_count() == 0:
		return pos
	var result: Vector2 = pos
	var near: PackedInt32Array = walls.segments_near(pos, radius + REACH_MARGIN)
	if near.is_empty():
		return pos
	for _pass: int in range(MAX_PASSES):
		var moved: bool = false
		for segment: int in near:
			if not walls.is_intact(segment):
				continue
			var pushed: Vector2 = _pushed_from(walls, segment, result, radius)
			if pushed != result:
				result = pushed
				moved = true
		if not moved:
			break
	return result


## The intact segment a circle of `radius` metres would hit walking the straight line from `from`
## to `to`: the one nearest to `from`, ties to the lower index. -1 when the line is clear. A segment
## blocks when the line passes closer than half_thickness + radius to it.
static func first_blocking(walls: WallSystem, from: Vector2, to: Vector2, radius: float) -> int:
	if walls.intact_count() == 0:
		return -1
	var middle: Vector2 = (from + to) * 0.5
	var reach: float = from.distance_to(to) * 0.5 + radius + REACH_MARGIN
	var best: int = -1
	var best_distance: float = INF
	for segment: int in walls.segments_near(middle, reach):
		if not walls.is_intact(segment):
			continue
		var start: Vector2 = walls.segment_start(segment)
		var end: Vector2 = walls.segment_end(segment)
		if _segments_distance(from, to, start, end) >= walls.half_thickness_of(segment) + radius:
			continue
		var distance: float = from.distance_to(_closest_on(start, end, from))
		if distance < best_distance:
			best_distance = distance
			best = segment
	return best


## `pos` moved out of one segment when it overlaps it, else `pos` itself.
static func _pushed_from(walls: WallSystem, segment: int, pos: Vector2, radius: float) -> Vector2:
	var start: Vector2 = walls.segment_start(segment)
	var end: Vector2 = walls.segment_end(segment)
	var nearest: Vector2 = _closest_on(start, end, pos)
	var reach: float = walls.half_thickness_of(segment) + radius
	var offset: Vector2 = pos - nearest
	var squared: float = offset.length_squared()
	if squared >= reach * reach:
		return pos
	if squared > 0.0:
		return nearest + offset / sqrt(squared) * reach
	var along: Vector2 = end - start
	var length: float = along.length()
	if length <= 0.0:
		return nearest + Vector2.RIGHT * reach
	return nearest + Vector2(-along.y, along.x) / length * reach


static func _closest_on(start: Vector2, end: Vector2, pos: Vector2) -> Vector2:
	var along: Vector2 = end - start
	var squared: float = along.length_squared()
	if squared <= 0.0:
		return start
	var t: float = clampf((pos - start).dot(along) / squared, 0.0, 1.0)
	return start + along * t


static func _point_distance(pos: Vector2, start: Vector2, end: Vector2) -> float:
	return pos.distance_to(_closest_on(start, end, pos))


## The least distance between two segments: 0.0 when they cross, else the least of the four
## end-to-segment distances.
static func _segments_distance(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> float:
	var side_c: float = (b - a).cross(c - a)
	var side_d: float = (b - a).cross(d - a)
	var side_a: float = (d - c).cross(a - c)
	var side_b: float = (d - c).cross(b - c)
	if side_c * side_d < 0.0 and side_a * side_b < 0.0:
		return 0.0
	return minf(
		minf(_point_distance(a, c, d), _point_distance(b, c, d)),
		minf(_point_distance(c, a, b), _point_distance(d, a, b))
	)
