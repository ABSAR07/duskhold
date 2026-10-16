class_name WallRunDef
extends Resource
## An authored line of wall (D-01): a polyline, the longest piece, the gaps left open and the half
## width of the solid. The simulation expands it into segments once, at construction, so every
## machine ends with the same integer centimetres. Data only: every number lives in .tres (D-09).
## Only `+ - * /`, `sqrt` and rounding are used (DR-7); impossible data expands to nothing.

## The most segments one run may expand to; a guard against bad data, like MAX_ENEMIES_PER_NIGHT.
const MAX_SEGMENTS_PER_RUN: int = 200
## No coordinate may lie farther than this from the origin, in metres, so centimetres fit an int.
const MAX_COORDINATE_M: float = 100000.0
## Integer centimetres per metre, the quantisation of every stored endpoint.
const CENTIMETRES: float = 100.0

## Polyline vertices in metres on the XZ plane (x, z in a Vector2's x, y).
@export var points: PackedVector2Array = PackedVector2Array()
## The longest segment in metres. Each solid stretch is cut into equal pieces no longer than this.
@export var segment_length: float = 3.0
## Stretches with no wall, as (from_m, to_m) distances along the path. A gap keeps its authored
## width: the pieces on both sides end exactly at its edges.
@export var gaps: PackedVector2Array = PackedVector2Array()
## Half the solid's width in metres: anything closer than this plus its own radius is inside it.
@export var half_thickness: float = 0.4


## The segments of this run as [ax, az, bx, bz] integer centimetres per segment, in path order.
## Empty when the data is unusable: fewer than two points, a non-finite or far-flung coordinate, a
## non-positive or non-finite segment_length or half_thickness, a non-finite gap, a path of no
## length, or more than MAX_SEGMENTS_PER_RUN pieces.
func expand() -> PackedInt32Array:
	var none: PackedInt32Array = PackedInt32Array()
	if not _data_is_usable():
		return none
	var cumulative: PackedFloat64Array = _cumulative_lengths()
	var total: float = cumulative[cumulative.size() - 1]
	if total <= 0.0:
		return none
	var stretches: PackedFloat64Array = _solid_stretches(total)
	var pieces: int = 0
	for index: int in range(0, stretches.size(), 2):
		var needed: float = ceilf((stretches[index + 1] - stretches[index]) / segment_length)
		if needed > float(MAX_SEGMENTS_PER_RUN):
			return none
		pieces += maxi(int(needed), 1)
		if pieces > MAX_SEGMENTS_PER_RUN:
			return none
	var out: PackedInt32Array = PackedInt32Array()
	for index: int in range(0, stretches.size(), 2):
		var from_m: float = stretches[index]
		var to_m: float = stretches[index + 1]
		var count: int = maxi(ceili((to_m - from_m) / segment_length), 1)
		for piece: int in range(count):
			var start: float = from_m + (to_m - from_m) * (float(piece) / float(count))
			var end: float = from_m + (to_m - from_m) * (float(piece + 1) / float(count))
			var a: Vector2 = _point_at(start, cumulative)
			var b: Vector2 = _point_at(end, cumulative)
			out.append(roundi(a.x * CENTIMETRES))
			out.append(roundi(a.y * CENTIMETRES))
			out.append(roundi(b.x * CENTIMETRES))
			out.append(roundi(b.y * CENTIMETRES))
	return out


## How many segments expand() makes; 0 for unusable data.
func segment_count() -> int:
	@warning_ignore("integer_division")
	return expand().size() / 4


func _data_is_usable() -> bool:
	if points.size() < 2:
		return false
	if not is_finite(segment_length) or segment_length <= 0.0:
		return false
	if not is_finite(half_thickness) or half_thickness <= 0.0:
		return false
	for point: Vector2 in points:
		if not _coordinate_ok(point.x) or not _coordinate_ok(point.y):
			return false
	for gap: Vector2 in gaps:
		if not is_finite(gap.x) or not is_finite(gap.y):
			return false
	return true


func _coordinate_ok(value: float) -> bool:
	return is_finite(value) and absf(value) <= MAX_COORDINATE_M


## Distance along the path at each vertex: first 0.0, last the whole length.
func _cumulative_lengths() -> PackedFloat64Array:
	var cumulative: PackedFloat64Array = PackedFloat64Array([0.0])
	for index: int in range(1, points.size()):
		var dx: float = float(points[index].x) - float(points[index - 1].x)
		var dz: float = float(points[index].y) - float(points[index - 1].y)
		cumulative.append(cumulative[index - 1] + sqrt(dx * dx + dz * dz))
	return cumulative


## The solid parts of [0, total] outside the gaps, as (from, to) pairs in ascending order. The gaps
## are put in order and clipped to the path first; overlapping gaps count once.
func _solid_stretches(total: float) -> PackedFloat64Array:
	var spans: Array[Vector2] = []
	for gap: Vector2 in gaps:
		var low: float = maxf(minf(gap.x, gap.y), 0.0)
		var high: float = minf(maxf(gap.x, gap.y), total)
		if high > low:
			spans.append(Vector2(low, high))
	spans.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var stretches: PackedFloat64Array = PackedFloat64Array()
	var cursor: float = 0.0
	for span: Vector2 in spans:
		if span.x > cursor:
			stretches.append(cursor)
			stretches.append(span.x)
		cursor = maxf(cursor, span.y)
	if cursor < total:
		stretches.append(cursor)
		stretches.append(total)
	return stretches


## The point `distance` metres along the path; the last vertex past the end.
func _point_at(distance: float, cumulative: PackedFloat64Array) -> Vector2:
	var last: int = points.size() - 1
	for edge: int in range(last):
		var length: float = cumulative[edge + 1] - cumulative[edge]
		if length <= 0.0:
			continue
		if distance <= cumulative[edge + 1] or edge == last - 1:
			var t: float = clampf((distance - cumulative[edge]) / length, 0.0, 1.0)
			var ax: float = float(points[edge].x)
			var az: float = float(points[edge].y)
			var bx: float = float(points[edge + 1].x)
			var bz: float = float(points[edge + 1].y)
			return Vector2(ax + (bx - ax) * t, az + (bz - az) * t)
	return points[last]
