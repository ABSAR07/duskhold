extends GutTest
## ENMY-04, D-09: an enemy with no target whose progress toward the castle has not improved by
## stuck_progress_m for stuck_seconds is flagged; one that creeps forward in a queue is not; the
## tracker only reads (no event, no change to any enemy). The enemies here are a stand-in that
## answers the reads the tracker makes (the packed view since plan 04-20), so a test can hold or
## move them exactly.

const SQUADS_FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const GAP_FIXTURE := "res://tests/fixtures/fixture_map_walls_gap.tres"
const TUNING := "res://data/tuning/nav_tuning.tres"
const LOOP_TUNING := "res://data/tuning/loop_tuning.tres"
const RUN: StringName = &"wall_west"
const TOWER: StringName = &"tower_1"
const STUCK_TICKS: int = 90
const HALF_METRE_PERIOD: int = 75
const FAR := Vector2(-40.0, 0.0)
const FIELD_SPOT := Vector2(-25.0, 0.0)

var _pathing: Pathing
var _tracker: StuckTracker
var _enemies: FakeEnemies


## Answers ids(), count(), is_alive(), target_of() and position_of() from plain dictionaries.
class FakeEnemies:
	extends EnemySystem
	var spots: Dictionary = {}
	var targets: Dictionary = {}
	var dead: Dictionary = {}

	func _init() -> void:
		super(SimEvents.new())

	func put(id: int, pos: Vector2) -> void:
		spots[id] = pos

	func ids() -> Array[int]:
		var out: Array[int] = []
		for id: int in spots:
			out.append(id)
		out.sort()
		return out

	func count() -> int:
		return spots.size()

	func is_alive(id: int) -> bool:
		return spots.has(id) and not dead.has(id)

	func target_of(id: int) -> Dictionary:
		return targets.get(id, {})

	func position_of(id: int) -> Vector2:
		return spots.get(id, Vector2.ZERO)

	## The packed view of the same dictionaries (the tracker reads the view since plan 04-20).
	func read_view() -> CrowdReadView:
		var view: CrowdReadView = CrowdReadView.new()
		for id: int in ids():
			view.ids.append(id)
			view.previous.append(position_of(id))
			view.current.append(position_of(id))
			view.targeted.append(0 if target_of(id).is_empty() else 1)
			view.living.append(1 if is_alive(id) else 0)
		return view


func before_each() -> void:
	var map: MapConfig = load(SQUADS_FIXTURE)
	var events: SimEvents = SimEvents.new()
	_pathing = Pathing.new(map, WallSystem.new(map, BuildingSystem.new(map, events), events))
	_tracker = StuckTracker.new(load(TUNING), 2.0)
	_enemies = FakeEnemies.new()


func _update(times: int, tick: int = 0) -> void:
	for step: int in range(times):
		_tracker.update(tick + step, _enemies, _pathing)


func test_an_enemy_held_in_place_is_flagged_after_exactly_ninety_updates() -> void:
	_enemies.put(1, FAR)
	_update(STUCK_TICKS - 1)
	assert_false(_tracker.is_stuck(1), "not at 89")
	assert_eq(_tracker.stuck_count(), 0, "nobody is flagged yet")
	_update(1, STUCK_TICKS - 1)
	assert_true(_tracker.is_stuck(1), "flagged at 90")
	assert_eq(_tracker.stuck_ids(), PackedInt64Array([1]), "and listed")
	assert_eq(_tracker.streak_of(1), STUCK_TICKS, "after 90 ticks without progress")
	assert_eq(_tracker.threshold_ticks(), STUCK_TICKS, "3 s is 90 ticks")


func test_an_enemy_that_gains_half_a_metre_every_two_and_a_half_seconds_is_never_flagged() -> void:
	var x: float = FAR.x
	for step: int in range(1000):
		if step > 0 and step % HALF_METRE_PERIOD == 0:
			x += 0.5
		_enemies.put(1, Vector2(x, 0.0))
		_tracker.update(step, _enemies, _pathing)
		assert_false(_tracker.is_stuck(1), "step %d: it is creeping forward" % step)
	assert_lt(_tracker.longest_streak_ticks(), STUCK_TICKS, "its streak never reached 90")


func test_an_enemy_that_gains_less_than_half_a_metre_in_three_seconds_is_flagged() -> void:
	_enemies.put(1, FAR)
	_update(60)
	_enemies.put(1, FAR + Vector2(0.4, 0.0))
	_update(STUCK_TICKS - 60, 60)
	assert_true(_tracker.is_stuck(1), "0.4 m is not enough")


func test_an_enemy_with_a_target_is_never_flagged_and_its_streak_starts_over() -> void:
	_enemies.put(1, FAR)
	_update(60)
	assert_eq(_tracker.streak_of(1), 60, "60 ticks without progress")
	_enemies.targets[1] = {"kind": PendingHits.KIND_CASTLE, "id": 0}
	_update(500, 60)
	assert_false(_tracker.is_stuck(1), "attacking something")
	assert_eq(_tracker.streak_of(1), 0, "the streak was reset")
	_enemies.targets.erase(1)
	_update(STUCK_TICKS - 1, 560)
	assert_false(_tracker.is_stuck(1), "it has to wait out the seconds again")
	_update(1, 560 + STUCK_TICKS - 1)
	assert_true(_tracker.is_stuck(1), "and then it is flagged")


func test_an_enemy_that_died_or_left_drops_out() -> void:
	_enemies.put(1, FAR)
	_enemies.put(2, FAR + Vector2(0.0, 10.0))
	_update(STUCK_TICKS)
	assert_eq(_tracker.stuck_ids(), PackedInt64Array([1, 2]), "both flagged, ascending")
	_enemies.dead[1] = true
	_update(1, STUCK_TICKS)
	assert_eq(_tracker.stuck_ids(), PackedInt64Array([2]), "the dead one is dropped")
	assert_false(_tracker.is_stuck(1), "no longer flagged")
	assert_eq(_tracker.streak_of(1), 0, "and forgotten")
	_enemies.spots.erase(2)
	_update(1, STUCK_TICKS + 1)
	assert_eq(_tracker.stuck_count(), 0, "one that left is gone too")
	assert_eq(_tracker.streak_of(2), 0, "and forgotten")


func test_longest_streak_keeps_the_longest_seen_and_clear_empties_everything() -> void:
	_enemies.put(1, FAR)
	_update(120)
	assert_eq(_tracker.longest_streak_ticks(), 120, "the streak so far")
	_enemies.put(1, FAR + Vector2(5.0, 0.0))
	_update(1, 120)
	assert_eq(_tracker.streak_of(1), 0, "five metres of progress starts it over")
	assert_eq(_tracker.longest_streak_ticks(), 120, "the longest is kept")
	_tracker.clear()
	assert_eq(_tracker.longest_streak_ticks(), 0, "clear forgets it")
	assert_eq(_tracker.stuck_count(), 0, "and the flags")
	assert_eq(_tracker.stuck_ids(), PackedInt64Array(), "and the list")
	assert_eq(_tracker.streak_of(1), 0, "and every streak")


func test_the_unknown_id_is_not_stuck() -> void:
	assert_false(_tracker.is_stuck(99), "nobody by that id")
	assert_eq(_tracker.streak_of(99), 0, "no streak")
	assert_eq(_tracker.stuck_count(), 0, "and nobody flagged")


func test_ids_are_listed_in_ascending_order() -> void:
	for id: int in [7, 3, 5]:
		_enemies.put(id, FAR + Vector2(0.0, float(id) * 3.0))
	_update(STUCK_TICKS)
	assert_eq(_tracker.stuck_ids(), PackedInt64Array([3, 5, 7]), "ascending")


func test_with_a_field_progress_is_the_route_cost_so_a_cell_of_progress_counts() -> void:
	var ctx: RunContext = RunContext.new(load(GAP_FIXTURE), load(LOOP_TUNING), 1)
	ctx.commands.submit(BuildIntent.new(RUN))
	ctx.step()
	var pathing: Pathing = ctx.night.get_pathing()
	assert_lt(
		pathing.route().castle_cost_at(FIELD_SPOT), FlowField.INF_COST, "the field reaches the spot"
	)
	var tracker: StuckTracker = StuckTracker.new(load(TUNING), 2.0)
	_enemies.put(1, FIELD_SPOT)
	_enemies.put(2, FIELD_SPOT + Vector2(0.0, -6.0))
	for step: int in range(STUCK_TICKS):
		tracker.update(step, _enemies, pathing)
	assert_eq(tracker.stuck_ids(), PackedInt64Array([1, 2]), "held in place, both are flagged")
	var before: int = pathing.route().castle_cost_at(FIELD_SPOT)
	var nearer: Vector2 = FIELD_SPOT + Vector2(4.0, 0.0)
	_enemies.put(1, nearer)
	tracker.update(STUCK_TICKS, _enemies, pathing)
	assert_lt(pathing.route().castle_cost_at(nearer), before, "nearer the castle by route")
	assert_false(tracker.is_stuck(1), "two cells of progress reset the streak")
	assert_true(tracker.is_stuck(2), "the other is still held")


func test_a_real_night_is_read_and_nothing_about_it_changes() -> void:
	var ctx: RunContext = RunContext.new(load(GAP_FIXTURE), load(LOOP_TUNING), 1)
	for _tier: int in range(3):
		ctx.commands.submit(BuildIntent.new(RUN))
	ctx.commands.submit(BuildIntent.new(TOWER))
	ctx.commands.submit(StartNightIntent.new())
	for _step: int in range(100):
		ctx.step()
	var enemies: EnemySystem = ctx.night.get_enemies()
	assert_gt(enemies.count(), 0, "enemies are on the field")
	var before: Dictionary = _snapshot(enemies)
	watch_signals(ctx.events)
	var tracker: StuckTracker = ctx.night.get_pathing().stuck()
	for repeat: int in range(5):
		tracker.update(1000 + repeat, enemies, ctx.night.get_pathing())
	assert_eq(_snapshot(enemies), before, "positions, health and targets are untouched")
	for signal_name: String in SimSignals.ALL:
		assert_signal_not_emitted(ctx.events, signal_name)


func test_a_new_night_starts_with_a_clean_tracker() -> void:
	var ctx: RunContext = RunContext.new(load(GAP_FIXTURE), load(LOOP_TUNING), 1)
	ctx.commands.submit(BuildIntent.new(TOWER))
	ctx.commands.submit(StartNightIntent.new())
	for _step: int in range(100):
		ctx.step()
	var tracker: StuckTracker = ctx.night.get_pathing().stuck()
	assert_gt(tracker.longest_streak_ticks(), 0, "the night was watched")
	ctx.night.begin_night(2)
	assert_eq(tracker.longest_streak_ticks(), 0, "the next night starts clean")
	assert_eq(tracker.stuck_count(), 0, "with nobody flagged")


func _snapshot(enemies: EnemySystem) -> Dictionary:
	var out: Dictionary = {}
	for id: int in enemies.ids():
		out[id] = [
			enemies.position_of(id),
			enemies.previous_position_of(id),
			enemies.health_of(id),
			enemies.target_of(id)
		]
	return out
