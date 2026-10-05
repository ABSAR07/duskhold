extends GutTest
## RunStats (D-15): the five numbers of the results screen, counted from the run's own events. The
## listener never emits or changes anything. Counts are checked first against hand-emitted events,
## then against a scripted two-night run on a deep-copied fixture.

const FIXTURE := "res://tests/fixtures/fixture_map_one_night.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const KING_AT := Vector2(-4.5, 0.0)
const MAX_NIGHT_STEPS: int = 1500
const RICH_GOLD: int = 500

var _events: SimEvents
var _stats: RunStats
var _tuning: LoopTuning


func before_each() -> void:
	_events = SimEvents.new()
	_stats = RunStats.new(_events)
	_tuning = load(TUNING)


func _phase(old_phase: int, new_phase: int) -> void:
	_events.phase_changed.emit(old_phase, new_phase)


func _context() -> RunContext:
	var shipped: MapConfig = load(FIXTURE)
	var map: MapConfig = shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	map.starting_gold = RICH_GOLD
	var ctx: RunContext = RunContext.new(map, _tuning, 1)
	ctx.king.report_position(KING_AT)
	return ctx


func _step_until_phase(ctx: RunContext, phase: int, max_steps: int = MAX_NIGHT_STEPS) -> bool:
	for _i: int in range(max_steps):
		if ctx.run_manager.get_phase() == phase:
			return true
		ctx.step()
	return ctx.run_manager.get_phase() == phase


func test_a_fresh_run_has_counted_nothing() -> void:
	assert_eq(_stats.nights_survived(), 0, "no nights")
	assert_eq(_stats.gold_earned(), 0, "no gold")
	assert_eq(_stats.buildings_lost(), 0, "no buildings lost")
	assert_eq(_stats.king_knockouts(), 0, "no knockouts")
	assert_eq(_stats.outcome(), &"", "no outcome until the run ends")


func test_only_the_ways_out_of_a_survived_night_count_as_a_night_survived() -> void:
	_phase(RunManager.RunPhase.DAY, RunManager.RunPhase.NIGHT_TRANSITION)
	_phase(RunManager.RunPhase.NIGHT_TRANSITION, RunManager.RunPhase.NIGHT)
	assert_eq(_stats.nights_survived(), 0, "starting a night survives nothing")
	_phase(RunManager.RunPhase.NIGHT, RunManager.RunPhase.DAWN)
	assert_eq(_stats.nights_survived(), 1, "night to dawn")
	_phase(RunManager.RunPhase.DAWN, RunManager.RunPhase.DAY)
	assert_eq(_stats.nights_survived(), 1, "dawn to day survives nothing new")
	_phase(RunManager.RunPhase.NIGHT, RunManager.RunPhase.WON)
	assert_eq(_stats.nights_survived(), 2, "the last night, to victory")


func test_a_night_that_ends_the_run_in_defeat_is_not_survived() -> void:
	_phase(RunManager.RunPhase.NIGHT, RunManager.RunPhase.DAWN)
	_phase(RunManager.RunPhase.NIGHT, RunManager.RunPhase.LOST)
	assert_eq(_stats.nights_survived(), 1, "n - 1 for a loss during night n")


func test_gold_earned_is_the_integer_sum_of_every_dawn_total() -> void:
	_events.dawn_payout.emit(7, {&"house_1": 7})
	_events.dawn_payout.emit(0, {})
	_events.dawn_payout.emit(12, {&"house_1": 5, &"house_2": 7})
	assert_eq(_stats.gold_earned(), 19, "7 + 0 + 12")


func test_buildings_lost_and_king_knockouts_count_their_events() -> void:
	_events.building_destroyed.emit(&"house_1", &"house", 1)
	_events.building_destroyed.emit(&"tower_1", &"tower", 2)
	_events.building_destroyed.emit(&"house_1", &"house", 1)
	_events.king_downed.emit(180, 1)
	_events.king_downed.emit(180, 2)
	assert_eq(_stats.buildings_lost(), 3, "every destruction counts, a rebuilt one again")
	assert_eq(_stats.king_knockouts(), 2, "every knockout counts across nights")


func test_the_outcome_is_what_run_ended_reported() -> void:
	_events.run_ended.emit(&"victory")
	assert_eq(_stats.outcome(), &"victory", "victory")
	var lost: RunStats = RunStats.new(_events)
	_events.run_ended.emit(&"defeat")
	assert_eq(lost.outcome(), &"defeat", "a defeat on a fresh listener")


func test_counting_emits_nothing_of_its_own() -> void:
	watch_signals(_events)
	_phase(RunManager.RunPhase.NIGHT, RunManager.RunPhase.DAWN)
	_events.dawn_payout.emit(3, {&"house_1": 3})
	assert_signal_emit_count(_events, "phase_changed", 1, "only the emission the test made")
	assert_signal_emit_count(_events, "dawn_payout", 1, "only the emission the test made")
	for signal_name: String in SimSignals.ALL:
		if signal_name != "phase_changed" and signal_name != "dawn_payout":
			assert_signal_not_emitted(_events, signal_name, "%s was not emitted" % signal_name)


func test_a_won_two_night_run_counts_two_nights_and_every_payout() -> void:
	var ctx: RunContext = _context()
	assert_eq(ctx.commands.submit(BuildIntent.new(&"house_1")), CommandProcessor.OK, "a House")
	var paid: Array[int] = []
	ctx.events.dawn_payout.connect(
		func(total: int, _per_spot: Dictionary) -> void: paid.append(total)
	)
	for night: int in range(2):
		assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night starts")
		var target: int = RunManager.RunPhase.DAWN if night == 0 else RunManager.RunPhase.WON
		assert_true(_step_until_phase(ctx, target), "night %d ends" % (night + 1))
		if night == 0:
			assert_true(_step_until_phase(ctx, RunManager.RunPhase.DAY, 400), "then day")
	assert_eq(ctx.stats.nights_survived(), 2, "two nights on a two-night win")
	assert_eq(paid.size(), 1, "only the first night paid a dawn")
	assert_gt(paid[0], 0, "the House paid")
	assert_eq(ctx.stats.gold_earned(), paid[0], "gold earned is the sum of the dawn totals")
	assert_eq(ctx.stats.outcome(), &"victory", "the outcome")
	assert_eq(ctx.run_manager.get_total_nights(), 2, "two authored nights")


func test_a_loss_during_night_two_has_survived_one_night() -> void:
	var ctx: RunContext = _context()
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night 1 starts")
	assert_true(_step_until_phase(ctx, RunManager.RunPhase.DAWN), "night 1 ends")
	assert_true(_step_until_phase(ctx, RunManager.RunPhase.DAY, 400), "then day")
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night 2 starts")
	ctx.castle.damage(ctx.castle.get_max_health())
	ctx.step()
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.LOST, "lost in night 2")
	assert_eq(ctx.stats.nights_survived(), 1, "n - 1")
	assert_eq(ctx.stats.outcome(), &"defeat", "the outcome")


func test_buildings_lost_and_knockouts_follow_a_real_night() -> void:
	var ctx: RunContext = _context()
	assert_eq(ctx.commands.submit(BuildIntent.new(&"tower_1")), CommandProcessor.OK, "a Tower")
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "the night starts")
	ctx.buildings.damage_building(&"tower_1", 1000)
	ctx.king.take_damage(ctx.king.get_max_health())
	assert_eq(ctx.stats.buildings_lost(), 1, "the Tower fell")
	assert_eq(ctx.stats.king_knockouts(), 1, "the king was knocked out once")
