class_name SelectionMath
extends RefCounted
## Pure screen-space picking for squad selection, free of any Camera or Node so a test can feed it
## points directly (RESEARCH "Pure box select"). The controller projects each unit to the screen
## and hands the points over keyed by squad id.


## The squad with a unit point nearest `click`, or &"" when none is within `radius` pixels. The
## radius is inclusive (a point exactly `radius` away hits). `points_by_squad` maps a squad id to an
## array of screen points (one per unit) and is walked in insertion order, which is creation order,
## so when two squads are equally near the one created first wins.
static func nearest_squad_at(
	points_by_squad: Dictionary, click: Vector2, radius: float
) -> StringName:
	var best_id: StringName = &""
	var best_distance: float = radius * radius
	var found: bool = false
	for squad_id: StringName in points_by_squad:
		for point: Vector2 in points_by_squad[squad_id]:
			var distance: float = click.distance_squared_to(point)
			if distance > radius * radius:
				continue
			if not found or distance < best_distance:
				found = true
				best_distance = distance
				best_id = squad_id
	return best_id
