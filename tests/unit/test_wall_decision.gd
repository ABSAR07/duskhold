extends GutTest
## ENMY-04, D-07 and D-08: the integer break-or-detour arithmetic (damage per 10 s, time to
## destruction, walking ticks, the strict rule and its hysteresis) and the per-segment published
## time to destruction: summed over the crowd aggroed within the neighbour span of the same run,
## evaluated only on the segment's own staggered tick, held in between.
## Gap round G-05-2 (owner decision 2026-10-25): health and damage are 100 times larger, so
## the shipped grunt deals 2000 per 10 s and a shipped segment holds 3000; every expected tick
## count is unchanged.

const RING_FIXTURE := "res://tests/fixtures/fixture_map_walls.tres"
const GAP_FIXTURE := "res://tests/fixtures/fixture_map_walls_gap.tres"
const TUNING := "res://data/tuning/nav_tuning.tres"
const RING: StringName = &"wall_ring"
const RUN: StringName = &"wall_west"
const SECOND_RUN: StringName = &"wall_east"
const GRUNT_PER_300: int = 2000
const CADENCE: int = 15
const MIDDLE: int = 5
const FIRST_RUN_LAST: int = 5

var _walls: WallSystem
var _buildings: BuildingSystem
var _decision: WallDecision


func _ring_decision() -> void:
	var map: MapConfig = load(RING_FIXTURE)
	var events: SimEvents = SimEvents.new()
	_buildings = BuildingSystem.new(map, events)
	_walls = WallSystem.new(map, _buildings, events)
	_buildings.apply_next_tier(RING)
	_decision = WallDecision.new(_walls, load(TUNING))


## A gap-fixture copy with a second run (east) and both bought at tier I.
func _two_runs_decision() -> void:
	var map: MapConfig = (load(GAP_FIXTURE) as MapConfig).duplicate_deep(
		Resource.DEEP_DUPLICATE_ALL
	)
	var run: WallRunDef = WallRunDef.new()
	run.points = PackedVector2Array([Vector2(20.0, -10.0), Vector2(20.0, 10.0)])
	run.segment_length = 3.0
	run.gaps = PackedVector2Array([Vector2(12.0, 16.0)])
	run.half_thickness = 0.4
	var spot: BuildSpotDef = BuildSpotDef.new()
	spot.id = SECOND_RUN
	spot.position = Vector3(17.5, 0.0, 0.0)
	spot.building_id = &"wall"
	spot.wall_run = run
	var spots: Array[BuildSpotDef] = []
	spots.append_array(map.spots)
	spots.append(spot)
	map.spots = spots
	var events: SimEvents = SimEvents.new()
	_buildings = BuildingSystem.new(map, events)
	_walls = WallSystem.new(map, _buildings, events)
	_buildings.apply_next_tier(RUN)
	_buildings.apply_next_tier(SECOND_RUN)
	_decision = WallDecision.new(_walls, load(TUNING))


## One decision pass at `tick` with `count` grunts aggroed onto `segment`.
func _decide(tick: int, segment: int, count: int) -> void:
	_decision.begin_tick(tick)
	for _grunt: int in range(count):
		_decision.add_attacker(segment, GRUNT_PER_300)
	_decision.end_tick()


## The first tick at or after `from` on which `segment` is due.
func _due_tick(segment: int, from: int) -> int:
	var tick: int = from
	while (tick + segment) % CADENCE != 0:
		tick += 1
	return tick


func test_damage_per_300_is_damage_per_ten_seconds_in_integers() -> void:
	assert_eq(WallDecision.damage_per_300(200, 30), GRUNT_PER_300, "the grunt: 200 per second")
	assert_eq(WallDecision.damage_per_300(3, 48), 18, "integer division rounds down")
	assert_eq(WallDecision.damage_per_300(5, 0), 1500, "an interval under a tick counts as one")


func test_time_to_destruction_rounds_up_and_a_zero_sum_is_never() -> void:
	assert_eq(WallDecision.ttd_ticks(30, 0), SimClock.MAX_TICKS, "nobody hits it")
	assert_eq(WallDecision.ttd_ticks(30, -5), SimClock.MAX_TICKS, "a negative sum is nobody")
	assert_eq(WallDecision.ttd_ticks(3000, GRUNT_PER_300), 450, "3000 hp at 2000 per 10 s")
	assert_eq(WallDecision.ttd_ticks(3100, GRUNT_PER_300), 465, "rounded up, not down")
	assert_eq(WallDecision.ttd_ticks(0, GRUNT_PER_300), 0, "a broken segment is gone at once")


func test_walk_ticks_rounds_up_and_a_missing_speed_is_never() -> void:
	assert_eq(WallDecision.walk_ticks(2000, 320), 188, "20 m at 3.2 m/s is 187.5 ticks")
	assert_eq(WallDecision.walk_ticks(0, 320), 0, "already there")
	assert_eq(WallDecision.walk_ticks(2000, 0), SimClock.MAX_TICKS, "standing still never arrives")
	assert_eq(WallDecision.walk_ticks(2000, -3), SimClock.MAX_TICKS, "nor going backwards")


func test_should_break_is_strict_and_a_missing_detour_always_breaks() -> void:
	assert_true(WallDecision.should_break(100, 50, SimClock.MAX_TICKS), "sealed: always break")
	assert_true(
		WallDecision.should_break(SimClock.MAX_TICKS, 50, SimClock.MAX_TICKS), "even if never"
	)
	assert_true(WallDecision.should_break(100, 50, 151), "150 against 151 breaks")
	assert_false(WallDecision.should_break(100, 50, 150), "150 against 150 goes round")
	assert_false(WallDecision.should_break(100, 50, 149), "and so does 150 against 149")
	assert_false(WallDecision.should_break(SimClock.MAX_TICKS, 50, 5000), "never destroyed: round")


func test_keep_breaking_lets_go_only_when_the_detour_wins_by_more_than_the_hysteresis() -> void:
	assert_true(WallDecision.keep_breaking(100, 50, 150, 15), "a tie is kept")
	assert_true(WallDecision.keep_breaking(100, 50, 135, 15), "detour + 15 equals 150: kept")
	assert_false(WallDecision.keep_breaking(100, 50, 134, 15), "detour + 15 is below 150: let go")
	assert_true(WallDecision.keep_breaking(100, 50, SimClock.MAX_TICKS, 15), "sealed: kept")
	assert_true(WallDecision.keep_breaking(100, 50, 400, 15), "breaking is the faster way")


func test_the_two_rules_leave_a_dead_band_so_nobody_flips() -> void:
	for detour: int in range(100, 200):
		var takes: bool = WallDecision.should_break(60, 40, detour)
		var keeps: bool = WallDecision.keep_breaking(60, 40, detour, 15)
		assert_true(keeps or not takes, "a detour of %d takes but does not keep" % detour)
	assert_true(WallDecision.should_break(60, 40, 101), "takes at 101")
	assert_true(WallDecision.keep_breaking(60, 40, 101, 15), "and keeps it")
	assert_false(WallDecision.should_break(60, 40, 100), "does not take at 100")
	assert_true(WallDecision.keep_breaking(60, 40, 100, 15), "but one already at it keeps it")


func test_five_grunts_on_a_segment_publish_its_time_to_destruction_across_the_span() -> void:
	_ring_decision()
	assert_eq(_decision.ttd_of(MIDDLE), SimClock.MAX_TICKS, "nothing is known at the start")
	for segment: int in range(MIDDLE - 2, MIDDLE + 3):
		_decide(_due_tick(segment, 30 * (segment + 1)), MIDDLE, 5)
		assert_eq(_decision.ttd_of(segment), 90, "segment %d: 3000 hp at 10000 per 10 s" % segment)
		assert_eq(_decision.evaluated_count(), 1, "one segment was due and aggroed near")
	_decide(_due_tick(MIDDLE - 3, 200), MIDDLE, 5)
	assert_eq(_decision.ttd_of(MIDDLE - 3), SimClock.MAX_TICKS, "three away is not counted")
	_decide(_due_tick(MIDDLE + 3, 300), MIDDLE, 5)
	assert_eq(_decision.ttd_of(MIDDLE + 3), SimClock.MAX_TICKS, "three away is not counted")


func test_a_crowd_on_the_last_segment_of_a_run_does_not_reach_the_next_run() -> void:
	_two_runs_decision()
	var next: int = FIRST_RUN_LAST + 1
	assert_eq(_walls.spot_of(next), SECOND_RUN, "the next index belongs to the second run")
	_decide(_due_tick(next, 60), FIRST_RUN_LAST, 5)
	assert_eq(_decision.ttd_of(next), SimClock.MAX_TICKS, "the other run is not near")
	_decide(_due_tick(FIRST_RUN_LAST - 1, 120), FIRST_RUN_LAST, 5)
	assert_eq(_decision.ttd_of(FIRST_RUN_LAST - 1), 90, "its own run is")


func test_a_segment_is_evaluated_only_on_its_own_tick_and_keeps_its_value_between() -> void:
	_ring_decision()
	var first: int = _due_tick(MIDDLE, 30)
	_decide(first, MIDDLE, 1)
	assert_eq(_decision.ttd_of(MIDDLE), 450, "3000 hp at 2000 per 10 s")
	_walls.damage_segment(MIDDLE, 1000)
	for offset: int in range(1, CADENCE):
		_decide(first + offset, MIDDLE, 1)
		assert_eq(_decision.ttd_of(MIDDLE), 450, "not due at +%d: the old value stands" % offset)
	_decide(first + CADENCE, MIDDLE, 1)
	assert_eq(_decision.ttd_of(MIDDLE), 300, "due again: 2000 hp now")


func test_a_due_segment_with_nobody_near_goes_back_to_never() -> void:
	_ring_decision()
	var first: int = _due_tick(MIDDLE, 30)
	_decide(first, MIDDLE, 2)
	assert_eq(_decision.ttd_of(MIDDLE), 225, "two grunts: 3000 hp at 4000 per 10 s")
	_decide(first + CADENCE, MIDDLE, 0)
	assert_eq(_decision.ttd_of(MIDDLE), SimClock.MAX_TICKS, "the crowd left")
	assert_eq(_decision.evaluated_count(), 0, "nothing was evaluated")


func test_a_million_health_against_a_thousand_attackers_stays_exact() -> void:
	var sum: int = 1000 * GRUNT_PER_300
	assert_eq(WallDecision.ttd_ticks(100000000, sum), 15000, "exact in 64-bit integers")
	assert_eq(WallDecision.ttd_ticks(1000000, 1), 300000000, "300 million ticks, no overflow")
	assert_eq(WallDecision.ttd_ticks(1 << 40, 1), SimClock.MAX_TICKS, "saturates at never")
	_ring_decision()
	_decision.begin_tick(_due_tick(MIDDLE, 30))
	for _attacker: int in range(1000):
		_decision.add_attacker(MIDDLE, GRUNT_PER_300)
	_decision.end_tick()
	assert_eq(_decision.ttd_of(MIDDLE), 1, "3000 hp at 2000000 per 10 s is under a tick: 1")


func test_the_numbers_come_from_the_shipped_tuning() -> void:
	_ring_decision()
	assert_eq(_decision.hysteresis_ticks(), 15, "0.5 s is 15 ticks")
	assert_almost_eq(_decision.notice_range(), 12.0, 0.0001, "12 m")
	assert_eq(_decision.ttd_of(-1), SimClock.MAX_TICKS, "an unknown segment is never")
	assert_eq(_decision.ttd_of(999), SimClock.MAX_TICKS, "an unknown segment is never")
	_decision.begin_tick(0)
	_decision.add_attacker(-1, GRUNT_PER_300)
	_decision.add_attacker(999, GRUNT_PER_300)
	_decision.end_tick()
	assert_eq(_decision.evaluated_count(), 0, "unknown segments are ignored")
