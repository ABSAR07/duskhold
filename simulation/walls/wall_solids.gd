class_name WallSolids
extends RefCounted
## The solid test of the walls (D-04, RESEARCH Pattern 6): where a circle may stand and which
## segment is in the way of a straight line. Static and pure: it reads a WallSystem and changes
## nothing, so the enemies, the squads, the king and the bots all apply the same rule.
##
## Only intact segments are solid (D-05): a broken or unbuilt one pushes nothing and blocks nothing.
## The rule itself lives in native/src/native_walls.cpp (PLAT-01, plan 04-17) and runs on the
## mirror of the segments that WallSystem keeps in step with every health change; these functions
## keep the GDScript API for the callers. Determinism-sensitive like Separation: only `+ - * /` and
## `sqrt` are used (DR-7), candidates are visited in ascending segment index, and a position
## exactly on a segment is pushed along the segment's fixed left normal, never a random side.
## tests/unit/test_wall_geometry_pins.gd holds the digests of the answers.


## The point of the segment nearest `pos`, clamped to its two ends. An index out of range gives the
## zero vector.
static func closest_point(walls: WallSystem, segment: int, pos: Vector2) -> Vector2:
	return walls.native().closest_point(segment, pos)


## `pos` moved out of every intact segment it overlaps, so a circle of `radius` metres at the result
## is at least half_thickness + radius from each of them. A position that overlaps none is returned
## exactly as given, bit for bit, so a map with no intact wall never feels this function. A circle
## is pushed out of one segment at a time and a push can land it in a neighbour, so the pass repeats
## three times at most over the candidates taken once at the start.
static func push_out(walls: WallSystem, pos: Vector2, radius: float) -> Vector2:
	return walls.native().push_out(pos, radius)


## The intact segment a circle of `radius` metres would hit walking the straight line from `from`
## to `to`: the one nearest to `from`, ties to the lower index. -1 when the line is clear. A segment
## blocks when the line passes closer than half_thickness + radius to it.
static func first_blocking(walls: WallSystem, from: Vector2, to: Vector2, radius: float) -> int:
	return walls.native().first_blocking(from, to, radius)
