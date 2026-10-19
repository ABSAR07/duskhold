class_name StuckTracker
extends RefCounted
## Which enemies have stopped getting anywhere (ENMY-04, D-09, RESEARCH Pattern 10). An enemy with
## no target whose progress toward the castle has not improved by stuck_progress_m for
## stuck_seconds is flagged; one with a target resets, and one that creeps forward in a queue keeps
## resetting because a small improvement is all it takes. Progress is the castle field's cost at
## the enemy's cell where the field reaches it, else the straight distance in centimetres.
##
## The tracker runs in C++ (PLAT-01, plan 04-20): native/src/native_stuck.cpp keeps the entries
## and walks the enemy read view (ids, which enemies hold a target, which are alive, positions)
## against the castle field. It is an exact port of the GDScript tracker this file held until that
## plan (git show 5f6cd94:simulation/nav/stuck_tracker.gd), pinned by tests/unit/test_stuck_pins.gd
## computed on the GDScript before the port. This class keeps the public API.
##
## Strictly read-only (RESEARCH Pitfall 10): update() reads the enemy read view and the castle
## field, keeps its own state and emits no event and writes nothing into any enemy or the
## pathing, so the replay digests do not depend on it. The headless gate test and the debug
## overlay read the flags. Integers only, in ascending id order; pure RefCounted code under
## simulation/ (DR-1 to DR-10).

var _native: NativeStuck = NativeStuck.new()


## `castle` is the castle's ground position (Pathing passes the map's); the distance to it is the
## progress measure where the castle field does not reach an enemy.
func _init(tuning: NavTuning, cell_size: float, castle: Vector2 = Vector2.ZERO) -> void:
	_native.configure(tuning.stuck_seconds, tuning.stuck_progress_m, cell_size, castle)


## Looks at every living enemy of the step just taken, in ascending id order, and refreshes the
## flags. Enemies that are gone are forgotten.
func update(tick: int, enemies: EnemySystem, pathing: Pathing) -> void:
	var view: CrowdReadView = enemies.read_view()
	var field: FlowField = pathing.castle_field()
	var native_field: NativeField = null
	if field != null:
		native_field = field.native()
	_native.update(tick, view.ids, view.targeted, view.living, view.current, native_field)


## Forgets every enemy and flag, and the longest streak, for a new night.
func clear() -> void:
	_native.clear()


func is_stuck(id: int) -> bool:
	return _native.is_stuck(id)


func stuck_count() -> int:
	return _native.stuck_count()


## The flagged enemies of the last update, ascending. A copy.
func stuck_ids() -> PackedInt64Array:
	return _native.stuck_ids()


## Ticks the enemy has made no progress for as of the last update; 0 for an unknown id.
func streak_of(id: int) -> int:
	return _native.streak_of(id)


## The longest no-progress streak any enemy reached since the last clear, in ticks.
func longest_streak_ticks() -> int:
	return _native.longest_streak_ticks()


## Ticks of no progress after which an enemy is flagged (stuck_seconds).
func threshold_ticks() -> int:
	return _native.threshold_ticks()
