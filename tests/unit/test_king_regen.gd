extends GutTest
## KING-05, D-20: the king heals himself. SimClock.ticks(regen_delay_seconds) steps after the last
## hit taken he regains regen_fraction_per_second of his maximum health per second, as whole points
## through a float accumulator, until full, by day and by night and never while knocked out. Every
## hit restarts the delay and discards the partial point. KingState is exercised directly with a
## KingDef copy (max_health 50, delay 1 s, 10 % per second = 5 points per second); the RunContext
## cases use the shipped map and the shipped king, whose data is pinned in the first tests.

const KING_PATH := "res://data/king/king.tres"
const MAP_PATH := "res://data/maps/prototype_map.tres"
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
const MAX_HEALTH: int = 50
const DELAY_S: float = 1.0
const FRACTION: float = 0.1
## 10 % of 50 per second.
const POINTS_PER_SECOND: int = 5

var _def: KingDef
var _events: SimEvents
var _king: KingState
var _healed: Array[int] = []


func before_each() -> void:
	_def = (load(KING_PATH) as KingDef).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	_def.max_health = MAX_HEALTH
	_def.regen_delay_seconds = DELAY_S
	_def.regen_fraction_per_second = FRACTION
	_healed = []
	_build(_def)


func _build(def: KingDef) -> void:
	_events = SimEvents.new()
	_king = KingState.new(def, Vector2.ZERO, _events)
	_king.begin_night()
	_events.king_healed.connect(
		func(amount: int, _hp: int, _max: int) -> void: _healed.append(amount)
	)


func _timers(count: int) -> void:
	for _i: int in range(count):
		_king.tick_timers()


func _delay_ticks() -> int:
	return SimClock.ticks(DELAY_S)


func _sum(values: Array[int]) -> int:
	var total: int = 0
	for value: int in values:
		total += value
	return total


func test_the_shipped_king_heals_a_second_after_the_last_hit_at_ten_percent_a_second() -> void:
	var king: KingDef = load(KING_PATH)
	assert_eq(king.regen_delay_seconds, 1.0, "the delay is 1 s (D-20)")
	assert_eq(king.regen_fraction_per_second, 0.1, "10 percent of max health per second (D-20)")


func test_a_fresh_king_def_has_regeneration_off() -> void:
	var def: KingDef = KingDef.new()
	assert_eq(def.regen_delay_seconds, 0.0, "off by data default")
	assert_eq(def.regen_fraction_per_second, 0.0, "so fixtures and the smoke golden stay put")


func test_nothing_heals_during_the_delay_after_a_hit() -> void:
	_king.take_damage(12)
	_timers(_delay_ticks())
	assert_eq(_king.get_health(), MAX_HEALTH - 12, "no heal for SimClock.ticks(1.0) steps")
	assert_eq(_healed.size(), 0, "and no king_healed")


func test_after_the_delay_he_regains_five_points_in_the_next_thirty_steps() -> void:
	_king.take_damage(12)
	_timers(_delay_ticks())
	_timers(30)
	assert_eq(_king.get_health(), MAX_HEALTH - 12 + POINTS_PER_SECOND, "exactly 5 points")
	assert_eq(_sum(_healed), POINTS_PER_SECOND, "king_healed reports each gained point")


func test_king_healed_reports_the_amount_and_the_new_health() -> void:
	_king.take_damage(12)
	_timers(_delay_ticks())
	watch_signals(_events)
	_timers(6)
	assert_signal_emitted_with_parameters(_events, "king_healed", [1, MAX_HEALTH - 11, MAX_HEALTH])
	assert_signal_emit_count(_events, "king_healed", 1, "one point is one event")


func test_a_step_that_changes_no_whole_point_emits_nothing() -> void:
	_king.take_damage(12)
	_timers(_delay_ticks())
	watch_signals(_events)
	_timers(3)
	assert_signal_not_emitted(_events, "king_healed")
	assert_eq(_king.get_health(), MAX_HEALTH - 12, "half a point is not a point")


func test_healing_stops_at_full_health_and_the_next_step_emits_nothing() -> void:
	_king.take_damage(2)
	_timers(_delay_ticks() + 60)
	assert_eq(_king.get_health(), MAX_HEALTH, "full")
	assert_eq(_sum(_healed), 2, "only the missing points were reported")
	watch_signals(_events)
	_timers(60)
	assert_signal_not_emitted(_events, "king_healed")
	assert_eq(_king.get_health(), MAX_HEALTH, "and never above full")


func test_a_hit_during_regeneration_restarts_the_delay_and_drops_the_partial_point() -> void:
	_king.take_damage(12)
	_timers(_delay_ticks())
	_timers(5)
	assert_eq(_king.get_health(), MAX_HEALTH - 12, "five steps are not yet a point")
	_king.take_damage(1)
	_timers(_delay_ticks())
	assert_eq(_king.get_health(), MAX_HEALTH - 13, "the delay starts over")
	_timers(5)
	assert_eq(_king.get_health(), MAX_HEALTH - 13, "and the earlier partial point is gone")
	_timers(1)
	assert_eq(_king.get_health(), MAX_HEALTH - 12, "a point takes six steps from a clean start")


func test_every_hit_restarts_the_delay() -> void:
	_king.take_damage(10)
	for _i: int in range(5):
		_timers(_delay_ticks() - 1)
		_king.take_damage(1)
	assert_eq(
		_king.get_health(), MAX_HEALTH - 15, "hits just inside the delay keep him from healing"
	)
	assert_eq(_healed.size(), 0, "no king_healed")


func test_a_knocked_out_king_does_not_heal() -> void:
	_king.take_damage(MAX_HEALTH)
	assert_true(_king.is_down(), "down")
	_timers(_delay_ticks() + 300)
	assert_eq(_king.get_health(), 0, "still 0")
	assert_eq(_healed.size(), 0, "nothing healed")


func test_a_respawn_gives_full_health_and_the_dawn_still_does() -> void:
	var enemies: EnemySystem = EnemySystem.new(_events)
	var hits: PendingHits = PendingHits.new()
	_king.take_damage(MAX_HEALTH)
	var guard: int = 0
	while _king.is_down() and guard < 10000:
		_king.step(guard, enemies, hits)
		guard += 1
	assert_false(_king.is_down(), "he is back")
	assert_eq(_king.get_health(), MAX_HEALTH, "with full health")
	_king.take_damage(20)
	_king.restore_for_dawn()
	assert_eq(_king.get_health(), MAX_HEALTH, "and dawn heals him fully in one go")


func test_regeneration_off_by_data_never_heals() -> void:
	var cases: Array[float] = [0.0, -0.5, NAN, -INF]
	for bad: float in cases:
		var def: KingDef = _def.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
		def.regen_fraction_per_second = bad
		_build(def)
		_king.take_damage(10)
		_timers(_delay_ticks() + 600)
		assert_eq(_king.get_health(), MAX_HEALTH - 10, "fraction %s never heals" % bad)
	assert_eq(_healed.size(), 0, "and nothing is reported")


func test_an_infinite_fraction_cannot_heal_more_than_the_missing_health() -> void:
	var def: KingDef = _def.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	def.regen_fraction_per_second = INF
	_build(def)
	_king.take_damage(10)
	_timers(_delay_ticks() + 10)
	assert_eq(_king.get_health(), MAX_HEALTH - 10, "an infinite number counts as off")


func test_a_delay_that_is_not_finite_or_negative_counts_as_none() -> void:
	for bad: float in [NAN, -3.0, -INF]:
		var def: KingDef = _def.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
		def.regen_delay_seconds = bad
		_build(def)
		_king.take_damage(10)
		_timers(6)
		assert_eq(
			_king.get_health(), MAX_HEALTH - 9, "delay %s: the first point comes at once" % bad
		)


func _day_context() -> RunContext:
	return RunContext.new(load(MAP_PATH), load(TUNING_PATH), 1)


func test_the_king_heals_by_day_in_a_run() -> void:
	var ctx: RunContext = _day_context()
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAY, "it is day")
	var max_hp: int = ctx.king.get_max_health()
	ctx.king.take_damage(10)
	for _i: int in range(SimClock.ticks(ctx.king.get_def().regen_delay_seconds)):
		ctx.step()
	assert_eq(ctx.king.get_health(), max_hp - 10, "not during the delay")
	for _i: int in range(30):
		ctx.step()
	assert_gt(ctx.king.get_health(), max_hp - 10, "then by day too")


func test_the_king_heals_at_night_in_a_run() -> void:
	var map: MapConfig = (load(MAP_PATH) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	var no_nights: Array[NightDef] = []
	map.nights = no_nights
	var ctx: RunContext = RunContext.new(map, load(TUNING_PATH), 1)
	assert_true(ctx.run_manager.start_night(), "the night starts")
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.NIGHT, "it is night")
	var max_hp: int = ctx.king.get_max_health()
	ctx.king.take_damage(10)
	for _i: int in range(SimClock.ticks(ctx.king.get_def().regen_delay_seconds) + 30):
		ctx.step()
	assert_gt(ctx.king.get_health(), max_hp - 10, "by night too")
