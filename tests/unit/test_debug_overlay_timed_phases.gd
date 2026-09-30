extends GutTest
## DEV-03: the debug overlay model in the timed phases. The read-only suite only ever collects by
## day; this one drives the run to NIGHT and DAWN, where the Loop section gains a Timer row, and
## checks the Day and Night counters and that collecting there stays read-only too.

var _tuning: LoopTuning


func before_each() -> void:
	_tuning = OverlayTestSupport.new_tuning()


func _context_with_one_house() -> RunContext:
	return OverlayTestSupport.context_with_one_house(self, _tuning)


func _into_night(ctx: RunContext) -> void:
	var result: StringName = ctx.commands.submit(StartNightIntent.new())
	assert_eq(result, CommandProcessor.OK, "the night starts")


func _into_dawn(ctx: RunContext) -> void:
	_into_night(ctx)
	ctx.run_manager.tick(_tuning.placeholder_night_seconds + 0.1)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "night ended into dawn")


func _loop(model: DebugOverlayModel) -> Dictionary:
	return OverlayTestSupport.section(model.collect(60.0), "Loop")


func test_by_day_the_loop_section_has_no_timer_row_and_counts_day_one_night_zero() -> void:
	var loop: Dictionary = _loop(DebugOverlayModel.new(_context_with_one_house()))

	assert_eq(OverlayTestSupport.row_value(loop, "Phase"), "DAY", "phase row")
	assert_eq(OverlayTestSupport.row_value(loop, "Day"), "1", "day one")
	assert_eq(OverlayTestSupport.row_value(loop, "Night"), "0", "no night yet")
	assert_null(
		OverlayTestSupport.row_value(loop, "Timer"), "the day has no clock, so no Timer row"
	)


func test_by_night_the_loop_section_shows_the_night_timer_and_counts() -> void:
	var ctx: RunContext = _context_with_one_house()
	var model: DebugOverlayModel = DebugOverlayModel.new(ctx)
	_into_night(ctx)

	var loop: Dictionary = _loop(model)

	assert_eq(OverlayTestSupport.row_value(loop, "Phase"), "NIGHT", "phase row")
	assert_eq(OverlayTestSupport.row_value(loop, "Day"), "1", "still the first day's number")
	assert_eq(OverlayTestSupport.row_value(loop, "Night"), "1", "night one started")
	assert_eq(
		OverlayTestSupport.row_value(loop, "Timer"),
		"%.1f" % _tuning.placeholder_night_seconds,
		"a full night left"
	)


func test_the_night_timer_row_follows_the_clock_down() -> void:
	var ctx: RunContext = _context_with_one_house()
	var model: DebugOverlayModel = DebugOverlayModel.new(ctx)
	_into_night(ctx)

	ctx.run_manager.tick(1.5)

	var expected: float = _tuning.placeholder_night_seconds - 1.5
	assert_eq(
		OverlayTestSupport.row_value(_loop(model), "Timer"),
		"%.1f" % expected,
		"the row reads the live time left"
	)


func test_by_dawn_the_loop_section_shows_the_dawn_timer_and_counts() -> void:
	var ctx: RunContext = _context_with_one_house()
	var model: DebugOverlayModel = DebugOverlayModel.new(ctx)
	_into_dawn(ctx)

	var loop: Dictionary = _loop(model)

	assert_eq(OverlayTestSupport.row_value(loop, "Phase"), "DAWN", "phase row")
	assert_eq(
		OverlayTestSupport.row_value(loop, "Day"),
		"1",
		"the day number only grows when dawn hands over to day"
	)
	assert_eq(OverlayTestSupport.row_value(loop, "Night"), "1", "night one is behind us")
	assert_eq(
		OverlayTestSupport.row_value(loop, "Timer"),
		"%.1f" % _tuning.dawn_seconds,
		"a full dawn left"
	)
	assert_eq(
		OverlayTestSupport.row_value(loop, "Gold"),
		str(ctx.economy.get_gold()),
		"the paid-out gold is shown"
	)


func test_the_timer_row_goes_away_and_the_day_counter_grows_when_dawn_hands_over_to_day() -> void:
	var ctx: RunContext = _context_with_one_house()
	var model: DebugOverlayModel = DebugOverlayModel.new(ctx)
	_into_dawn(ctx)
	assert_not_null(OverlayTestSupport.row_value(_loop(model), "Timer"), "dawn has a Timer row")

	ctx.run_manager.tick(_tuning.dawn_seconds + 0.1)

	var loop: Dictionary = _loop(model)
	assert_eq(OverlayTestSupport.row_value(loop, "Phase"), "DAY", "back to day")
	assert_eq(OverlayTestSupport.row_value(loop, "Day"), "2", "day two")
	assert_eq(OverlayTestSupport.row_value(loop, "Night"), "1", "one night behind us")
	assert_null(OverlayTestSupport.row_value(loop, "Timer"), "and the Timer row is gone again")


func test_collecting_200_times_by_night_changes_no_state_and_emits_no_events() -> void:
	var ctx: RunContext = _context_with_one_house()
	var model: DebugOverlayModel = DebugOverlayModel.new(ctx)
	_into_night(ctx)
	ctx.run_manager.tick(1.0)
	assert_not_null(
		OverlayTestSupport.row_value(_loop(model), "Timer"), "the timer getter is really being read"
	)

	OverlayTestSupport.assert_collecting_is_read_only(self, ctx, model)


func test_collecting_200_times_by_dawn_changes_no_state_and_emits_no_events() -> void:
	var ctx: RunContext = _context_with_one_house()
	var model: DebugOverlayModel = DebugOverlayModel.new(ctx)
	_into_dawn(ctx)
	ctx.run_manager.tick(0.5)
	assert_not_null(
		OverlayTestSupport.row_value(_loop(model), "Timer"), "the timer getter is really being read"
	)

	OverlayTestSupport.assert_collecting_is_read_only(self, ctx, model)
