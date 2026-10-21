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

const CENTIMETRES: float = 100.0

var _events: SimEvents
var _buildings: BuildingSystem
var _stats: StatStack
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
var _intact: int = 0
var _version: int = 0
## The C++ copy of the segments (native/src/native_walls.cpp): every health write below is mirrored
## into it with set_health, and WallSolids answers its queries from it.
var _native: NativeWalls = NativeWalls.new()


func _init(
	map: MapConfig, buildings: BuildingSystem, events: SimEvents, stat_stack: StatStack = null
) -> void:
	_events = events
	_buildings = buildings
	_stats = stat_stack if stat_stack != null else StatStack.new()
	for spot: BuildSpotDef in map.spots:
		if spot == null or spot.wall_run == null or spot.id == &"" or _runs.has(spot.id):
			continue
		_add_run(spot)
	_native.setup(_starts, _ends, _half)
	events.building_built.connect(_on_building_built)
	_stats.changed.connect(_on_stats_changed)


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
	var segment_health: int = _stats.int_value(&"wall.max_health", tier_def.max_health)
	for segment: int in segments:
		var was_built: bool = _max_health[segment] > 0
		_max_health[segment] = segment_health
		if not was_built or _health[segment] > 0:
			_health[segment] = segment_health
			_native.set_health(segment, _health[segment])
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


## The native mirror of the segments, in step with every health change; WallSolids asks it.
func native() -> NativeWalls:
	return _native


## The segments whose solid could reach a circle of radius `reach` metres around `pos`, ascending,
## standing or not: a superset for the caller to narrow with its own exact test. Read-only. The 4 m
## bucket grid behind it (a performance parameter, never data: it changes how many segments are
## looked at, never which ones are solid) lives in native/src/native_walls.cpp. Test-only: the
## native solids ask their own mirror, nothing in the game calls this (IN-10).
func segments_near(pos: Vector2, reach: float) -> PackedInt32Array:
	return _native.segments_near(pos, reach)


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
	_native.set_health(segment, _health[segment])
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
				_native.set_health(segment, _health[segment])
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


## A change of wall.max_health: every built run takes the new per-segment maximum. A standing
## segment gains the gain of the maximum (a hurt one stays hurt by the same amount) and a loss
## clamps it into [1, max]; a broken segment keeps its new maximum but stays broken until the dawn
## restore.
## Emits nothing and changes no segment's standing, so version() stays.
func _on_stats_changed(stats: Array[StringName]) -> void:
	if not stats.has(&"wall.max_health"):
		return
	for spot_id: StringName in _run_order:
		var segments: PackedInt32Array = _runs[spot_id]
		var tier_def: BuildingTierDef = _tier_def(spot_id, _buildings.current_tier(spot_id))
		if tier_def == null or segments.is_empty() or _max_health[segments[0]] <= 0:
			continue
		var new_max: int = _stats.int_value(&"wall.max_health", tier_def.max_health)
		for segment: int in segments:
			var gain: int = new_max - _max_health[segment]
			_max_health[segment] = new_max
			if _health[segment] > 0:
				_health[segment] = clampi(_health[segment] + gain, 1, new_max)
				_native.set_health(segment, _health[segment])


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


## Appends the expanded segments of a wall plot, in path order.
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
	_runs[spot.id] = segments
	_run_order.append(spot.id)
