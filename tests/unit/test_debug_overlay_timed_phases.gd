extends GutTest
## DEV-03: the debug overlay model in the timed phases. The read-only suite only ever collects by
## day; this one drives the run to NIGHT and DAWN, where the Loop section gains a Timer row, and
## checks the Day and Night counters and that collecting there stays read-only too.

const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const COLLECT_REPEATS: int = 200
const SIM_SIGNALS: Array[String] = [
	"gold_changed",
	"building_built",
	"command_rejected",
	"phase_changed",
	"night_started",
	"dawn_payout",
	"day_started",
]

var _tuning: LoopTuning


func before_each() -> void:
	_tuning = (load(TUNING) as LoopTuning).duplicate(true)


func _context_with_one_house() -> RunContext:
	var map: MapConfig = (load(PROTOTYPE_MAP) as MapConfig).duplicate(true)
	var ctx: RunContext = RunContext.new(map, _tuning)
	var first_spot: StringName = ctx.buildings.spot_ids()[0]
	var result: StringName = ctx.commands.submit(BuildIntent.new(first_spot))
	assert_eq(result, CommandProcessor.OK, "the setup House is built through the command gate")
	return ctx


func _into_night(ctx: RunContext) -> void:
	var result: StringName = ctx.commands.submit(StartNightIntent.new())
	assert_eq(result, CommandProcessor.OK, "the night starts")


func _into_dawn(ctx: RunContext) -> void:
	_into_night(ctx)
	ctx.run_manager.tick(_tuning.placeholder_night_seconds + 0.1)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "night ended into dawn")


func _loop(model: DebugOverlayModel) -> Dictionary:
	for section: Dictionary in model.collect(60.0):
		if section["title"] == "Loop":
			return section
	return {}


func _row(section: Dictionary, label: String) -> Variant:
	for row: Array in section.get("rows", []):
		if row[0] == label:
			return row[1]
	return null


func _assert_collecting_is_read_only(ctx: RunContext, model: DebugOverlayModel) -> void:
	var gold_before: int = ctx.economy.get_gold()
	var phase_before: RunManager.RunPhase = ctx.run_manager.get_phase()
	var timer_before: float = ctx.run_manager.get_phase_time_remaining()
	var elapsed_before: float = ctx.run_manager.get_elapsed()
	watch_signals(ctx.events)
	for i: int in COLLECT_REPEATS:
		model.collect(float(i))
	assert_eq(ctx.economy.get_gold(), gold_before, "gold unchanged")
	assert_eq(ctx.run_manager.get_phase(), phase_before, "phase unchanged")
	assert_eq(ctx.run_manager.get_phase_time_remaining(), timer_before, "the phase timer unchanged")
	assert_eq(ctx.run_manager.get_elapsed(), elapsed_before, "simulation time unchanged")
	for signal_name: String in SIM_SIGNALS:
		assert_signal_not_emitted(ctx.events, signal_name)


func test_by_day_the_loop_section_has_no_timer_row_and_counts_day_one_night_zero() -> void:
	var loop: Dictionary = _loop(DebugOverlayModel.new(_context_with_one_house()))

	assert_eq(_row(loop, "Phase"), "DAY", "phase row")
	assert_eq(_row(loop, "Day"), "1", "day one")
	assert_eq(_row(loop, "Night"), "0", "no night yet")
	assert_null(_row(loop, "Timer"), "the day has no clock, so no Timer row")


func test_by_night_the_loop_section_shows_the_night_timer_and_counts() -> void:
	var ctx: RunContext = _context_with_one_house()
	var model: DebugOverlayModel = DebugOverlayModel.new(ctx)
	_into_night(ctx)

	var loop: Dictionary = _loop(model)

	assert_eq(_row(loop, "Phase"), "NIGHT", "phase row")
	assert_eq(_row(loop, "Day"), "1", "still the first day's number")
	assert_eq(_row(loop, "Night"), "1", "night one started")
	assert_eq(_row(loop, "Timer"), "%.1f" % _tuning.placeholder_night_seconds, "a full night left")


func test_the_night_timer_row_follows_the_clock_down() -> void:
	var ctx: RunContext = _context_with_one_house()
	var model: DebugOverlayModel = DebugOverlayModel.new(ctx)
	_into_night(ctx)

	ctx.run_manager.tick(1.5)

	var expected: float = _tuning.placeholder_night_seconds - 1.5
	assert_eq(_row(_loop(model), "Timer"), "%.1f" % expected, "the row reads the live time left")


func test_by_dawn_the_loop_section_shows_the_dawn_timer_and_counts() -> void:
	var ctx: RunContext = _context_with_one_house()
	var model: DebugOverlayModel = DebugOverlayModel.new(ctx)
	_into_dawn(ctx)

	var loop: Dictionary = _loop(model)

	assert_eq(_row(loop, "Phase"), "DAWN", "phase row")
	assert_eq(_row(loop, "Day"), "1", "the day number only grows when dawn hands over to day")
	assert_eq(_row(loop, "Night"), "1", "night one is behind us")
	assert_eq(_row(loop, "Timer"), "%.1f" % _tuning.dawn_seconds, "a full dawn left")
	assert_eq(_row(loop, "Gold"), str(ctx.economy.get_gold()), "the paid-out gold is shown")


func test_the_timer_row_goes_away_and_the_day_counter_grows_when_dawn_hands_over_to_day() -> void:
	var ctx: RunContext = _context_with_one_house()
	var model: DebugOverlayModel = DebugOverlayModel.new(ctx)
	_into_dawn(ctx)
	assert_not_null(_row(_loop(model), "Timer"), "dawn has a Timer row")

	ctx.run_manager.tick(_tuning.dawn_seconds + 0.1)

	var loop: Dictionary = _loop(model)
	assert_eq(_row(loop, "Phase"), "DAY", "back to day")
	assert_eq(_row(loop, "Day"), "2", "day two")
	assert_eq(_row(loop, "Night"), "1", "one night behind us")
	assert_null(_row(loop, "Timer"), "and the Timer row is gone again")


func test_collecting_200_times_by_night_changes_no_state_and_emits_no_events() -> void:
	var ctx: RunContext = _context_with_one_house()
	var model: DebugOverlayModel = DebugOverlayModel.new(ctx)
	_into_night(ctx)
	ctx.run_manager.tick(1.0)
	assert_not_null(_row(_loop(model), "Timer"), "the timer getter is really being read")

	_assert_collecting_is_read_only(ctx, model)


func test_collecting_200_times_by_dawn_changes_no_state_and_emits_no_events() -> void:
	var ctx: RunContext = _context_with_one_house()
	var model: DebugOverlayModel = DebugOverlayModel.new(ctx)
	_into_dawn(ctx)
	ctx.run_manager.tick(0.5)
	assert_not_null(_row(_loop(model), "Timer"), "the timer getter is really being read")

	_assert_collecting_is_read_only(ctx, model)
