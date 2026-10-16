class_name WallSystem
extends RefCounted
## The wall segments of every wall plot, each with its own health (D-02). A sibling of
## BuildingSystem, which is at the public-method cap: it learns of a purchase through the
## building_built signal and never calls BuildingSystem back except to read a tier.
##
## Segment indices are global, ascend in MapConfig spot order and are never reused (the rule enemy
## ids follow), so a hit names its target by index. Geometry is kept in integer centimetres and
## handed out as metres, so every machine sees the same numbers. Detached from the scene tree and
## the clock; no randomness (DR-1 to DR-10).
##
## A segment is unbuilt (max health 0), standing (health above 0) or broken (built, health 0). A
## broken segment is a hole open to everyone until dawn (D-05): a tier purchase raises its maximum
## but leaves it broken, and only restore_all() makes it whole again.

## A performance parameter, never data: the edge in metres of the static bucket grid behind
## segments_near. It changes how many segments are looked at, never which ones are solid.
const BUCKET_CELL: float = 4.0
const CENTIMETRES: float = 100.0
const KEY_OFFSET: int = 1 << 19
const KEY_STRIDE: int = 1 << 20

var _events: SimEvents
var _buildings: BuildingSystem
## Per segment: owner plot, endpoints in metres (from centimetres), half thickness, health.
var _owner: Array[StringName] = []
var _starts: PackedVector2Array = PackedVector2Array()
var _ends: PackedVector2Array = PackedVector2Array()
var _half: PackedFloat64Array = PackedFloat64Array()
var _health: PackedInt32Array = PackedInt32Array()
var _max_health: PackedInt32Array = PackedInt32Array()
## Wall plot id -> PackedInt32Array of its segments, ascending; and the wall plots in map order.
var _runs: Dictionary = {}
var _run_order: Array[StringName] = []
## Bucket key -> Array[int] of the segments whose inflated box touches the cell, ascending.
var _buckets: Dictionary = {}
var _intact: int = 0
var _version: int = 0


func _init(map: MapConfig, buildings: BuildingSystem, events: SimEvents) -> void:
	_events = events
	_buildings = buildings
	for spot: BuildSpotDef in map.spots:
		if spot == null or spot.wall_run == null or spot.id == &"" or _runs.has(spot.id):
			continue
		_add_run(spot)
	events.building_built.connect(_on_building_built)


## A purchase on a wall plot: every segment of the run takes the per-segment maximum of the tier.
## An unbuilt segment and a standing one are filled to it; a broken one stays at 0 until dawn
## (D-05). Bumps version(). Emits nothing: building_built already records the purchase. A plot that
## is not a wall plot is ignored.
func on_building_built(spot_id: StringName, _building_id: StringName, tier: int) -> void:
	var segments: PackedInt32Array = segments_of(spot_id)
	if segments.is_empty():
		return
	var tier_def: BuildingTierDef = _tier_def(spot_id, tier)
	if tier_def == null:
		return
	for segment: int in segments:
		var was_built: bool = _max_health[segment] > 0
		_max_health[segment] = tier_def.max_health
		if not was_built or _health[segment] > 0:
			_health[segment] = tier_def.max_health
	_recount()
	_version += 1


func segment_count() -> int:
	return _owner.size()


## How many segments stand (health above 0) right now.
func intact_count() -> int:
	return _intact


## Changes whenever a purchase, a break or a dawn restore changes which segments stand, so a
## cache keyed on it knows when to rebuild.
func version() -> int:
	return _version


## The wall plot that owns `segment`; &"" for an index out of range.
func spot_of(segment: int) -> StringName:
	return _owner[segment] if _valid(segment) else &""


## The segments of a wall plot, ascending; empty for any other plot.
func segments_of(spot_id: StringName) -> PackedInt32Array:
	var found: Variant = _runs.get(spot_id)
	return found as PackedInt32Array if found != null else PackedInt32Array()


## One end of the segment in metres; the zero vector for an index out of range.
func segment_start(segment: int) -> Vector2:
	return _starts[segment] if _valid(segment) else Vector2.ZERO


## The other end of the segment in metres; the zero vector for an index out of range.
func segment_end(segment: int) -> Vector2:
	return _ends[segment] if _valid(segment) else Vector2.ZERO


## Half the solid's width in metres; 0.0 for an index out of range.
func half_thickness_of(segment: int) -> float:
	return _half[segment] if _valid(segment) else 0.0


## True while the segment stands: built and not broken.
func is_intact(segment: int) -> bool:
	return _valid(segment) and _health[segment] > 0


## Hit points left on the segment; 0 when unbuilt, broken or out of range.
func health_of(segment: int) -> int:
	return _health[segment] if _valid(segment) else 0


## Hit points the segment stands at with its run's current tier; 0 while unbuilt.
func max_health_of(segment: int) -> int:
	return _max_health[segment] if _valid(segment) else 0


## The segments whose solid could reach a circle of radius `reach` metres around `pos`, ascending,
## standing or not: a superset for the caller to narrow with its own exact test. Read-only.
func segments_near(pos: Vector2, reach: float) -> PackedInt32Array:
	var found: PackedInt32Array = PackedInt32Array()
	if _buckets.is_empty() or not is_finite(reach) or reach < 0.0:
		return found
	var low_x: int = floori((pos.x - reach) / BUCKET_CELL)
	var high_x: int = floori((pos.x + reach) / BUCKET_CELL)
	var low_y: int = floori((pos.y - reach) / BUCKET_CELL)
	var high_y: int = floori((pos.y + reach) / BUCKET_CELL)
	for cell_x: int in range(low_x, high_x + 1):
		for cell_y: int in range(low_y, high_y + 1):
			var bucket: Variant = _buckets.get(_key(cell_x, cell_y))
			if bucket != null:
				for segment: int in bucket as Array:
					found.append(segment)
	if high_x > low_x or high_y > low_y:
		found = _sorted_unique(found)
	return found


## Removes up to `amount` hit points (never below 0) from a standing segment and emits
## wall_damaged with the points actually lost; the hit that reaches 0 then emits
## wall_segment_broken, once, and the segment becomes a hole. A hit on a broken or unbuilt segment,
## an unknown index or a non-positive amount is dropped silently, as a hit on a thing that is gone
## always is.
func damage_segment(segment: int, amount: int) -> void:
	if not is_intact(segment) or amount <= 0:
		return
	var lost: int = mini(amount, _health[segment])
	_health[segment] -= lost
	_events.wall_damaged.emit(
		_owner[segment], segment, lost, _health[segment], _max_health[segment]
	)
	if _health[segment] == 0:
		_intact -= 1
		_version += 1
		_events.wall_segment_broken.emit(_owner[segment], segment)


## Dawn (LOOP-04, D-05): every built run with a segment below its maximum is whole again, broken
## segments included, for no gold. Returns the plots that changed in MapConfig order and emits
## walls_restored with them once; a second call, or a dawn with nothing to restore, returns an empty
## array and emits nothing. Bumps version() when a broken segment came back.
func restore_all() -> Array[StringName]:
	var changed: Array[StringName] = []
	var holes_closed: bool = false
	for spot_id: StringName in _run_order:
		var touched: bool = false
		for segment: int in _runs[spot_id] as PackedInt32Array:
			if _max_health[segment] > 0 and _health[segment] < _max_health[segment]:
				holes_closed = holes_closed or _health[segment] == 0
				_health[segment] = _max_health[segment]
				touched = true
		if touched:
			changed.append(spot_id)
	if holes_closed:
		_recount()
		_version += 1
	if not changed.is_empty():
		_events.walls_restored.emit(changed)
	return changed


func _on_building_built(spot_id: StringName, building_id: StringName, new_tier: int) -> void:
	on_building_built(spot_id, building_id, new_tier)


func _valid(segment: int) -> bool:
	return segment >= 0 and segment < _owner.size()


func _tier_def(spot_id: StringName, tier: int) -> BuildingTierDef:
	var building_def: BuildingDef = _buildings.get_building_def_for_spot(spot_id)
	return building_def.tier_def(tier) if building_def != null else null


func _recount() -> void:
	_intact = 0
	for health: int in _health:
		if health > 0:
			_intact += 1


## Appends the expanded segments of a wall plot, in path order, and buckets each one.
func _add_run(spot: BuildSpotDef) -> void:
	var expanded: PackedInt32Array = spot.wall_run.expand()
	var segments: PackedInt32Array = PackedInt32Array()
	for index: int in range(0, expanded.size(), 4):
		var segment: int = _owner.size()
		var start: Vector2 = Vector2(
			float(expanded[index]) / CENTIMETRES, float(expanded[index + 1]) / CENTIMETRES
		)
		var end: Vector2 = Vector2(
			float(expanded[index + 2]) / CENTIMETRES, float(expanded[index + 3]) / CENTIMETRES
		)
		_owner.append(spot.id)
		_starts.append(start)
		_ends.append(end)
		_half.append(spot.wall_run.half_thickness)
		_health.append(0)
		_max_health.append(0)
		segments.append(segment)
		_bucket(segment, start, end, spot.wall_run.half_thickness)
	_runs[spot.id] = segments
	_run_order.append(spot.id)


## Puts the segment in every cell its box, inflated by the half thickness, touches.
func _bucket(segment: int, start: Vector2, end: Vector2, half: float) -> void:
	var low_x: int = floori((minf(start.x, end.x) - half) / BUCKET_CELL)
	var high_x: int = floori((maxf(start.x, end.x) + half) / BUCKET_CELL)
	var low_y: int = floori((minf(start.y, end.y) - half) / BUCKET_CELL)
	var high_y: int = floori((maxf(start.y, end.y) + half) / BUCKET_CELL)
	for cell_x: int in range(low_x, high_x + 1):
		for cell_y: int in range(low_y, high_y + 1):
			var key: int = _key(cell_x, cell_y)
			if not _buckets.has(key):
				var fresh: Array[int] = []
				_buckets[key] = fresh
			(_buckets[key] as Array[int]).append(segment)


func _key(cell_x: int, cell_y: int) -> int:
	return (cell_x + KEY_OFFSET) * KEY_STRIDE + (cell_y + KEY_OFFSET)


func _sorted_unique(values: PackedInt32Array) -> PackedInt32Array:
	var sorted: PackedInt32Array = values.duplicate()
	sorted.sort()
	var unique: PackedInt32Array = PackedInt32Array()
	for value: int in sorted:
		if unique.is_empty() or unique[unique.size() - 1] != value:
			unique.append(value)
	return unique
