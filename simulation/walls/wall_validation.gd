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
## Ranges the pathing tunables may take (T-04-13, T-04-15): a cell of 0.5 to 8 m, a cache of 1 to 32
## goal fields, 1 to 4 builds per tick and a refresh of 0.1 to 10 s.
const MIN_CELL_SIZE: float = 0.5
const MAX_CELL_SIZE: float = 8.0
const MAX_BOUNDS_MARGIN: float = 100.0
const MAX_GOAL_MARGIN: float = 10.0
const MIN_GOAL_QUANTUM: float = 0.5
const MAX_GOAL_QUANTUM: float = 64.0
const MIN_CACHE_SIZE: int = 1
const MAX_CACHE_SIZE: int = 32
const MIN_BUILDS_PER_TICK: int = 1
const MAX_BUILDS_PER_TICK: int = 4
const MIN_REFRESH_SECONDS: float = 0.1
const MAX_REFRESH_SECONDS: float = 10.0
## Ranges of the wall decision and stuck numbers (plan 04-07): seconds from one tick to 10, a
## notice range above 0 to 50 m, 0 to 10 neighbours, stuck seconds 0.5 to 60 and progress above 0
## to 10 m.
const MAX_DECISION_SECONDS: float = 10.0
const MAX_NOTICE_RANGE: float = 50.0
const MAX_NEIGHBOUR_SPAN: int = 10
const MIN_STUCK_SECONDS: float = 0.5
const MAX_STUCK_SECONDS: float = 60.0
const MAX_STUCK_PROGRESS: float = 10.0


## Every wall error of `map`, in plot order; empty when its wall plots are well formed.
static func errors(map: MapConfig) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var total_segments: float = 0.0
	var has_walls: bool = false
	var grid_gap: float = _grid_gap(map)
	for spot: BuildSpotDef in map.spots:
		if spot == null or spot.wall_run == null:
			continue
		has_walls = true
		out.append_array(_building_errors(map, spot))
		var run_errors: PackedStringArray = PackedStringArray()
		var pieces: float = _run_errors(spot.id, spot.wall_run, grid_gap, run_errors)
		out.append_array(run_errors)
		total_segments += pieces
	if total_segments > float(MAX_SEGMENTS_PER_MAP):
		out.append(
			(
				"the wall plots make %d segments, more than the %d allowed on one map"
				% [int(total_segments), MAX_SEGMENTS_PER_MAP]
			)
		)
	if has_walls:
		out.append_array(_nav_errors(map))
	return out


## What a wall map needs of its pathing: sane tunables and a nav grid inside NavGrid.MAX_NAV_CELLS.
## A map with no wall plot never builds a grid, so it is not asked for one.
static func _nav_errors(map: MapConfig) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var tuning: NavTuning = NavGrid.tuning_of(map)
	_float_error(out, "cell_size", tuning.cell_size, MIN_CELL_SIZE, MAX_CELL_SIZE)
	_float_error(out, "bounds_margin", tuning.bounds_margin, 0.0, MAX_BOUNDS_MARGIN)
	_float_error(out, "goal_margin", tuning.goal_margin, 0.0, MAX_GOAL_MARGIN)
	_float_error(out, "goal_quantum", tuning.goal_quantum, MIN_GOAL_QUANTUM, MAX_GOAL_QUANTUM)
	_float_error(
		out,
		"field_refresh_seconds",
		tuning.field_refresh_seconds,
		MIN_REFRESH_SECONDS,
		MAX_REFRESH_SECONDS
	)
	_int_error(out, "field_cache_size", tuning.field_cache_size, MIN_CACHE_SIZE, MAX_CACHE_SIZE)
	_int_error(
		out,
		"field_builds_per_tick",
		tuning.field_builds_per_tick,
		MIN_BUILDS_PER_TICK,
		MAX_BUILDS_PER_TICK
	)
	_decision_errors(out, tuning)
	var sizeable: bool = (
		is_finite(tuning.cell_size)
		and tuning.cell_size > 0.0
		and is_finite(tuning.bounds_margin)
		and tuning.bounds_margin >= 0.0
	)
	if sizeable:
		var cells: int = NavGrid.cell_count_for(map, tuning)
		if cells > NavGrid.MAX_NAV_CELLS:
			out.append("nav grid of %d cells exceeds %d" % [cells, NavGrid.MAX_NAV_CELLS])
	return out


## The wall decision and stuck numbers of plan 04-07 (D-07 to D-09), each inside its range.
static func _decision_errors(out: PackedStringArray, tuning: NavTuning) -> void:
	_float_error(
		out,
		"wall_decision_seconds",
		tuning.wall_decision_seconds,
		SimClock.STEP,
		MAX_DECISION_SECONDS
	)
	_float_error(
		out,
		"wall_hysteresis_seconds",
		tuning.wall_hysteresis_seconds,
		SimClock.STEP,
		MAX_DECISION_SECONDS
	)
	_above_zero_error(out, "wall_notice_range", tuning.wall_notice_range, MAX_NOTICE_RANGE)
	_int_error(out, "wall_neighbour_span", tuning.wall_neighbour_span, 0, MAX_NEIGHBOUR_SPAN)
	_float_error(out, "stuck_seconds", tuning.stuck_seconds, MIN_STUCK_SECONDS, MAX_STUCK_SECONDS)
	_above_zero_error(out, "stuck_progress_m", tuning.stuck_progress_m, MAX_STUCK_PROGRESS)


static func _above_zero_error(
	out: PackedStringArray, field: String, value: float, high: float
) -> void:
	if not is_finite(value):
		out.append("nav tuning %s is not finite" % field)
	elif value <= 0.0 or value > high:
		out.append("nav tuning %s is %s, expected above 0 to %s" % [field, value, high])


static func _float_error(
	out: PackedStringArray, field: String, value: float, low: float, high: float
) -> void:
	if not is_finite(value):
		out.append("nav tuning %s is not finite" % field)
	elif value < low or value > high:
		out.append("nav tuning %s is %s, expected %s to %s" % [field, value, low, high])


static func _int_error(
	out: PackedStringArray, field: String, value: int, low: int, high: int
) -> void:
	if value < low or value > high:
		out.append("nav tuning %s is %d, expected %d to %d" % [field, value, low, high])


## The wall building must be a plain ladder of health: at least one tier, every tier with health
## above zero (a segment with no health never counts as built, review WR-04), and no income, no
## attack, no squad.
static func _building_errors(map: MapConfig, spot: BuildSpotDef) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for building_def: BuildingDef in map.buildings:
		if building_def == null or building_def.id != spot.building_id:
			continue
		if building_def.tiers.is_empty():
			out.append(
				"wall plot '%s' uses building '%s' which has no tiers" % [spot.id, building_def.id]
			)
			return out
		for index: int in range(building_def.tiers.size()):
			var tier: BuildingTierDef = building_def.tiers[index]
			if tier == null:
				continue
			if tier.max_health <= 0:
				out.append(
					(
						"wall plot '%s' uses building '%s' whose tier %d has no health"
						% [spot.id, building_def.id, index + 1]
					)
				)
				return out
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
static func _run_errors(
	spot_id: StringName, run: WallRunDef, grid_gap: float, out: PackedStringArray
) -> float:
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
	if not _gaps_ok(label, run, total, grid_gap, out):
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


## The part of the narrowest routable gap that does not depend on the run: one grid cell plus twice
## the largest agent radius the nav grid keeps clear of a wall (review WR-01). NavGrid blocks every
## cell centre within half_thickness + that radius of an intact segment, so a gap leaves
## width - 2 * (half_thickness + radius) of open centre line, and a cell centre is only guaranteed
## to fall inside it when that is at least one cell wide. 0 when the cell size is not usable (the
## nav tuning ranges report it). The radius is NavGrid.largest_radius_of, which leaves the king's
## larger body out (see its note, review IN-04).
static func _grid_gap(map: MapConfig) -> float:
	var cell: float = NavGrid.tuning_of(map).cell_size
	var radius: float = NavGrid.largest_radius_of(map)
	if not is_finite(cell) or cell <= 0.0 or not is_finite(radius):
		return 0.0
	return cell + 2.0 * radius


## The narrowest gap of `run` the pathing can route through: MIN_GAP_METRES, or more when the grid
## needs it (`grid_gap` plus twice the run's half thickness).
static func _min_gap(run: WallRunDef, grid_gap: float) -> float:
	var half: float = 0.0
	if is_finite(run.half_thickness) and run.half_thickness > 0.0:
		if run.half_thickness <= MAX_HALF_THICKNESS:
			half = run.half_thickness
	return maxf(MIN_GAP_METRES, grid_gap + 2.0 * half)


## Checks every gap; false when one is not finite (the others cannot be ordered then).
static func _gaps_ok(
	label: String, run: WallRunDef, total: float, grid_gap: float, out: PackedStringArray
) -> bool:
	var spans: Array[Vector2] = []
	var minimum: float = _min_gap(run, grid_gap)
	for index: int in range(run.gaps.size()):
		var gap: Vector2 = run.gaps[index]
		if not is_finite(gap.x) or not is_finite(gap.y):
			out.append("%s gap %d is not finite" % [label, index + 1])
			return false
		var low: float = minf(gap.x, gap.y)
		var high: float = maxf(gap.x, gap.y)
		if high - low < minimum:
			out.append(
				(
					"%s gap %d is %s m wide, under the %s m minimum"
					% [label, index + 1, high - low, minimum]
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
