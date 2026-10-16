class_name WallValidation
extends RefCounted
## What MapConfig.validate() says about wall plots (T-04-11): one readable string per problem, so
## bad authored geometry is reported instead of arming a wall. A run that fails WallRunDef.expand()
## has no segments, so bad data cannot arm a wall even when it is not reported here. Pure: it reads
## the map and never mutates it. Only `+ - * /`, `sqrt` and comparisons are used (DR-7).

## The narrowest gap an enemy may be asked to squeeze through, in metres (RESEARCH A3).
const MIN_GAP_METRES: float = 3.0
## The most segments all wall plots of one map may expand to together.
const MAX_SEGMENTS_PER_MAP: int = 1000
## Segment length bounds in metres, and the widest allowed half thickness.
const MIN_SEGMENT_LENGTH: float = 0.5
const MAX_SEGMENT_LENGTH: float = 20.0
const MAX_HALF_THICKNESS: float = 2.0


## Every wall error of `map`, in plot order; empty when its wall plots are well formed.
static func errors(map: MapConfig) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var total_segments: float = 0.0
	for spot: BuildSpotDef in map.spots:
		if spot == null or spot.wall_run == null:
			continue
		out.append_array(_building_errors(map, spot))
		var run_errors: PackedStringArray = PackedStringArray()
		var pieces: float = _run_errors(spot.id, spot.wall_run, run_errors)
		out.append_array(run_errors)
		total_segments += pieces
	if total_segments > float(MAX_SEGMENTS_PER_MAP):
		out.append(
			(
				"the wall plots make %d segments, more than the %d allowed on one map"
				% [int(total_segments), MAX_SEGMENTS_PER_MAP]
			)
		)
	return out


## The wall building must be a plain ladder of health: no income, no attack, no squad.
static func _building_errors(map: MapConfig, spot: BuildSpotDef) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for building_def: BuildingDef in map.buildings:
		if building_def == null or building_def.id != spot.building_id:
			continue
		for index: int in range(building_def.tiers.size()):
			var tier: BuildingTierDef = building_def.tiers[index]
			if tier == null:
				continue
			if tier.dawn_income > 0 or tier.attack_damage > 0 or tier.squad_size > 0:
				(
					out
					. append(
						(
							(
								"wall plot '%s' uses building '%s' whose tier %d pays income, attacks or "
								+ "fields a squad"
							)
							% [spot.id, building_def.id, index + 1]
						)
					)
				)
				return out
	return out


## Appends the errors of one run to `out`; returns the segments it expands to (0 when the data is
## unusable, so a broken run adds nothing to the map total).
static func _run_errors(spot_id: StringName, run: WallRunDef, out: PackedStringArray) -> float:
	var label: String = "wall plot '%s'" % spot_id
	var usable: bool = true
	if not _points_ok(label, run, out):
		usable = false
	if not is_finite(run.segment_length):
		out.append("%s segment_length is not finite" % label)
		usable = false
	elif run.segment_length < MIN_SEGMENT_LENGTH or run.segment_length > MAX_SEGMENT_LENGTH:
		out.append(
			(
				"%s segment_length is %s, expected %s to %s m"
				% [label, run.segment_length, MIN_SEGMENT_LENGTH, MAX_SEGMENT_LENGTH]
			)
		)
		usable = false
	if not is_finite(run.half_thickness):
		out.append("%s half_thickness is not finite" % label)
	elif run.half_thickness <= 0.0 or run.half_thickness > MAX_HALF_THICKNESS:
		out.append(
			(
				"%s half_thickness is %s, expected above 0 and at most %s m"
				% [label, run.half_thickness, MAX_HALF_THICKNESS]
			)
		)
	if not usable:
		return 0.0
	var total: float = _path_length(run.points)
	if not _gaps_ok(label, run, total, out):
		return 0.0
	var pieces: float = _piece_count(run, total)
	if pieces > float(WallRunDef.MAX_SEGMENTS_PER_RUN):
		out.append(
			(
				"%s makes %d segments, more than the %d allowed in one run"
				% [label, int(pieces), WallRunDef.MAX_SEGMENTS_PER_RUN]
			)
		)
	return pieces


static func _points_ok(label: String, run: WallRunDef, out: PackedStringArray) -> bool:
	if run.points.size() < 2:
		out.append("%s run has %d points, it needs at least 2" % [label, run.points.size()])
		return false
	for point: Vector2 in run.points:
		if (
			not is_finite(point.x)
			or not is_finite(point.y)
			or absf(point.x) > WallRunDef.MAX_COORDINATE_M
			or absf(point.y) > WallRunDef.MAX_COORDINATE_M
		):
			out.append("%s run has a point that is not finite or too far from the origin" % label)
			return false
	return true


## Checks every gap; false when one is not finite (the others cannot be ordered then).
static func _gaps_ok(label: String, run: WallRunDef, total: float, out: PackedStringArray) -> bool:
	var spans: Array[Vector2] = []
	for index: int in range(run.gaps.size()):
		var gap: Vector2 = run.gaps[index]
		if not is_finite(gap.x) or not is_finite(gap.y):
			out.append("%s gap %d is not finite" % [label, index + 1])
			return false
		var low: float = minf(gap.x, gap.y)
		var high: float = maxf(gap.x, gap.y)
		if high - low < MIN_GAP_METRES:
			out.append(
				(
					"%s gap %d is %s m wide, under the %s m minimum"
					% [label, index + 1, high - low, MIN_GAP_METRES]
				)
			)
		if low < 0.0 or high > total:
			out.append(
				(
					"%s gap %d (%s to %s m) lies outside the path (0 to %s m)"
					% [label, index + 1, low, high, total]
				)
			)
		spans.append(Vector2(low, high))
	spans.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	for index: int in range(1, spans.size()):
		if spans[index].x < spans[index - 1].y:
			out.append("%s has two gaps that overlap" % label)
			break
	return true


## Segments the run expands to, counted without WallRunDef.expand() (which returns nothing past its
## cap): each solid stretch outside the clipped, merged gaps is cut into ceil(length / segment).
static func _piece_count(run: WallRunDef, total: float) -> float:
	var spans: Array[Vector2] = []
	for gap: Vector2 in run.gaps:
		var low: float = maxf(minf(gap.x, gap.y), 0.0)
		var high: float = minf(maxf(gap.x, gap.y), total)
		if high > low:
			spans.append(Vector2(low, high))
	spans.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var pieces: float = 0.0
	var cursor: float = 0.0
	for span: Vector2 in spans:
		if span.x > cursor:
			pieces += maxf(ceilf((span.x - cursor) / run.segment_length), 1.0)
		cursor = maxf(cursor, span.y)
	if cursor < total:
		pieces += maxf(ceilf((total - cursor) / run.segment_length), 1.0)
	return pieces


static func _path_length(points: PackedVector2Array) -> float:
	var total: float = 0.0
	for index: int in range(1, points.size()):
		var dx: float = float(points[index].x) - float(points[index - 1].x)
		var dz: float = float(points[index].y) - float(points[index - 1].y)
		total += sqrt(dx * dx + dz * dz)
	return total
