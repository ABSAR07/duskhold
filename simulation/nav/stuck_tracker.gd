class_name StuckTracker
extends RefCounted
## Which enemies have stopped getting anywhere (ENMY-04, D-09, RESEARCH Pattern 10). An enemy with
## no target whose progress toward the castle has not improved by stuck_progress_m for
## stuck_seconds is flagged; one with a target resets, and one that creeps forward in a queue keeps
## resetting because a small improvement is all it takes. Progress is the castle field's cost at
## the enemy's cell where the field reaches it, else the straight distance in centimetres.
##
## Strictly read-only (RESEARCH Pitfall 10): update() reads the enemies and the pathing, keeps its
## own state and emits no event and writes nothing into any record, so the replay digests do not
## depend on it. The headless gate test and the debug overlay read the flags. Integers only, in
## ascending id order; pure RefCounted code under simulation/ (DR-1 to DR-10).

## The two units progress is measured in. A change of unit restarts an enemy's watermark.
const UNIT_CENTIMETRES: int = 0
const UNIT_FIELD_COST: int = 1

var _threshold_ticks: int = 0
var _needed_cost: int = 0
var _needed_cm: int = 0
var _entries: Dictionary = {}
var _stuck: PackedInt64Array = PackedInt64Array()
var _longest: int = 0


func _init(tuning: NavTuning, cell_size: float) -> void:
	_threshold_ticks = maxi(SimClock.ticks(tuning.stuck_seconds), 1)
	_needed_cost = maxi(
		roundi(tuning.stuck_progress_m * float(FlowField.STEP_ORTHOGONAL) / cell_size), 1
	)
	_needed_cm = maxi(roundi(tuning.stuck_progress_m * 100.0), 1)


## Looks at every living enemy of the step just taken, in ascending id order, and refreshes the
## flags. Enemies that are gone are forgotten.
func update(tick: int, enemies: EnemySystem, pathing: Pathing) -> void:
	_stuck = PackedInt64Array()
	var seen: int = 0
	for id: int in enemies.ids():
		if not enemies.is_alive(id):
			continue
		seen += 1
		var entry: Entry = _entries.get(id) as Entry
		if entry == null:
			entry = Entry.new()
			_entries[id] = entry
		entry.stamp = tick
		_observe(entry, id, enemies, pathing)
		_longest = maxi(_longest, entry.streak)
		if entry.streak >= _threshold_ticks:
			_stuck.append(id)
	if _entries.size() > seen:
		_forget_unseen(tick)


## Forgets every enemy and flag, and the longest streak, for a new night.
func clear() -> void:
	_entries.clear()
	_stuck = PackedInt64Array()
	_longest = 0


func is_stuck(id: int) -> bool:
	var entry: Entry = _entries.get(id) as Entry
	return entry != null and entry.streak >= _threshold_ticks


func stuck_count() -> int:
	return _stuck.size()


## The flagged enemies of the last update, ascending. A copy.
func stuck_ids() -> PackedInt64Array:
	return _stuck.duplicate()


## Ticks the enemy has made no progress for as of the last update; 0 for an unknown id.
func streak_of(id: int) -> int:
	var entry: Entry = _entries.get(id) as Entry
	return entry.streak if entry != null else 0


## The longest no-progress streak any enemy reached since the last clear, in ticks.
func longest_streak_ticks() -> int:
	return _longest


## Ticks of no progress after which an enemy is flagged (stuck_seconds).
func threshold_ticks() -> int:
	return _threshold_ticks


func _observe(entry: Entry, id: int, enemies: EnemySystem, pathing: Pathing) -> void:
	if not enemies.target_of(id).is_empty():
		entry.streak = 0
		entry.unit = -1
		return
	var position: Vector2 = enemies.position_of(id)
	var progress: int = pathing.castle_cost_at(position)
	var unit: int = UNIT_FIELD_COST
	var needed: int = _needed_cost
	if progress >= FlowField.INF_COST:
		progress = pathing.castle_distance_cm(position)
		unit = UNIT_CENTIMETRES
		needed = _needed_cm
	if entry.unit != unit:
		entry.unit = unit
		entry.best = progress
		entry.streak = 1
	elif progress <= entry.best - needed:
		entry.best = progress
		entry.streak = 0
	else:
		entry.streak += 1


func _forget_unseen(tick: int) -> void:
	var gone: Array[int] = []
	for id: int in _entries:
		if (_entries[id] as Entry).stamp != tick:
			gone.append(id)
	for id: int in gone:
		_entries.erase(id)


## One enemy's watermark: the best progress so far, the streak without improvement, the unit the
## progress is in and the update it was last seen on.
class Entry:
	extends RefCounted
	var best: int = 0
	var streak: int = 0
	var unit: int = -1
	var stamp: int = -1
