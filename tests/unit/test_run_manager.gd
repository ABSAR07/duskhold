extends GutTest
## The Day -> Night -> Dawn -> Day state machine (D-11, D-12) on a RunContext with no scene tree.
## Every duration is read from loop_tuning.tres so Phase 2 tuning cannot break these tests.

const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const SOURCE_ROOTS: Array[String] = [
	"res://simulation", "res://input", "res://ui", "res://presentation"
]

var _tuning: LoopTuning


func before_each() -> void:
	_tuning = load(TUNING)


func _context() -> RunContext:
	return RunContext.new(load(PROTOTYPE_MAP), _tuning)


func _into_night(ctx: RunContext) -> void:
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "the night starts")


func _into_dawn(ctx: RunContext) -> void:
	_into_night(ctx)
	ctx.run_manager.tick(_tuning.placeholder_night_seconds + 0.1)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "night ended into dawn")


func _gd_files(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return found
	for sub: String in dir.get_directories():
		found.append_array(_gd_files(dir_path.path_join(sub)))
	for file_name: String in dir.get_files():
		if file_name.ends_with(".gd"):
			found.append(dir_path.path_join(file_name))
	return found


func test_a_new_run_starts_on_day_one_with_no_nights_behind_it() -> void:
	var ctx: RunContext = _context()
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAY, "the run starts by day")
	assert_eq(ctx.run_manager.get_day_number(), 1, "day one")
	assert_eq(ctx.run_manager.get_night_number(), 0, "no night has started")


func test_start_night_intent_by_day_enters_the_night_through_the_transition() -> void:
	var ctx: RunContext = _context()
	watch_signals(ctx.events)

	var result: StringName = ctx.commands.submit(StartNightIntent.new())

	assert_eq(result, CommandProcessor.OK, "the intent is accepted by day")
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.NIGHT, "the night is under way")
	assert_eq(ctx.run_manager.get_night_number(), 1, "night one started")
	assert_signal_emit_count(ctx.events, "phase_changed", 2, "two steps: transition, then night")
	assert_eq(
		get_signal_parameters(ctx.events, "phase_changed", 0),
		[RunManager.RunPhase.DAY, RunManager.RunPhase.NIGHT_TRANSITION],
		"DAY to NIGHT_TRANSITION first"
	)
	assert_eq(
		get_signal_parameters(ctx.events, "phase_changed", 1),
		[RunManager.RunPhase.NIGHT_TRANSITION, RunManager.RunPhase.NIGHT],
		"then NIGHT_TRANSITION to NIGHT"
	)
	assert_signal_emitted_with_parameters(ctx.events, "night_started", [1])


func test_start_night_is_refused_with_no_events_during_night_and_dawn() -> void:
	var ctx: RunContext = _context()
	_into_night(ctx)
	watch_signals(ctx.events)
	assert_false(ctx.run_manager.start_night(), "refused in NIGHT")
	assert_signal_not_emitted(ctx.events, "phase_changed")
	assert_signal_not_emitted(ctx.events, "night_started")
	ctx.run_manager.tick(_tuning.placeholder_night_seconds + 0.1)
	clear_signal_watcher()
	watch_signals(ctx.events)
	assert_false(ctx.run_manager.start_night(), "refused in DAWN")
	assert_signal_not_emitted(ctx.events, "phase_changed")
	assert_signal_not_emitted(ctx.events, "night_started")
	assert_eq(ctx.run_manager.get_night_number(), 1, "still only one night started")


func test_start_night_intent_outside_the_day_is_rejected_with_not_day() -> void:
	var ctx: RunContext = _context()
	_into_night(ctx)
	watch_signals(ctx.events)

	var result: StringName = ctx.commands.submit(StartNightIntent.new())

	assert_eq(result, CommandProcessor.NOT_DAY, "not_day in NIGHT")
	assert_signal_emitted_with_parameters(
		ctx.events, "command_rejected", [&"start_night", &"", CommandProcessor.NOT_DAY]
	)
	assert_signal_not_emitted(ctx.events, "night_started")
	ctx.run_manager.tick(_tuning.placeholder_night_seconds + 0.1)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.NOT_DAY, "and in DAWN")


func test_the_placeholder_night_lasts_exactly_its_tuned_duration() -> void:
	var ctx: RunContext = _context()
	_into_night(ctx)

	ctx.run_manager.tick(_tuning.placeholder_night_seconds - 0.1)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.NIGHT, "still night just before")
	ctx.run_manager.tick(0.2)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "dawn just after")


func test_dawn_lasts_its_tuned_duration_then_the_next_day_begins() -> void:
	var ctx: RunContext = _context()
	_into_dawn(ctx)
	watch_signals(ctx.events)

	ctx.run_manager.tick(_tuning.dawn_seconds)

	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAY, "back to day")
	assert_eq(ctx.run_manager.get_day_number(), 2, "day two")
	assert_signal_emitted_with_parameters(ctx.events, "day_started", [2])
	assert_signal_emitted_with_parameters(
		ctx.events, "phase_changed", [RunManager.RunPhase.DAWN, RunManager.RunPhase.DAY]
	)


func test_one_huge_tick_moves_night_to_dawn_and_stops_there() -> void:
	var ctx: RunContext = _context()
	_into_night(ctx)
	watch_signals(ctx.events)

	ctx.run_manager.tick(1000.0)

	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "only as far as dawn")
	assert_signal_emit_count(ctx.events, "phase_changed", 1, "exactly one transition")
	assert_signal_not_emitted(ctx.events, "day_started")


func test_one_huge_tick_moves_dawn_to_day_and_stops_there() -> void:
	var ctx: RunContext = _context()
	_into_dawn(ctx)
	watch_signals(ctx.events)

	ctx.run_manager.tick(1000.0)

	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAY, "day again")
	assert_signal_emit_count(ctx.events, "phase_changed", 1, "exactly one transition")
	assert_signal_emit_count(ctx.events, "day_started", 1, "one new day")


func test_the_time_remaining_counts_down_through_the_night_and_dawn() -> void:
	var ctx: RunContext = _context()
	assert_almost_eq(ctx.run_manager.get_phase_time_remaining(), 0.0, 0.0001, "no timer by day")
	_into_night(ctx)
	assert_almost_eq(
		ctx.run_manager.get_phase_time_remaining(), _tuning.placeholder_night_seconds, 0.0001
	)
	ctx.run_manager.tick(1.0)
	assert_almost_eq(
		ctx.run_manager.get_phase_time_remaining(),
		_tuning.placeholder_night_seconds - 1.0,
		0.0001,
		"one second less"
	)
	ctx.run_manager.tick(_tuning.placeholder_night_seconds)
	assert_almost_eq(
		ctx.run_manager.get_phase_time_remaining(), _tuning.dawn_seconds, 0.0001, "dawn timer"
	)


func test_three_full_cycles_number_the_days_and_nights() -> void:
	var ctx: RunContext = _context()
	for cycle: int in range(1, 4):
		_into_night(ctx)
		assert_eq(ctx.run_manager.get_night_number(), cycle, "night %d" % cycle)
		ctx.run_manager.tick(_tuning.placeholder_night_seconds)
		ctx.run_manager.tick(_tuning.dawn_seconds)
		assert_eq(
			ctx.run_manager.get_phase(), RunManager.RunPhase.DAY, "day after night %d" % cycle
		)
		assert_eq(ctx.run_manager.get_day_number(), cycle + 1, "day %d" % (cycle + 1))


func test_only_the_run_manager_assigns_the_loop_phase() -> void:
	var pattern: RegEx = RegEx.create_from_string("(^|[^A-Za-z0-9_])_phase\\s*=[^=]")
	var offenders: Array[String] = []
	var scanned: int = 0
	for root: String in SOURCE_ROOTS:
		for path: String in _gd_files(root):
			if path.ends_with("simulation/run/run_manager.gd"):
				continue
			scanned += 1
			for line: String in FileAccess.get_file_as_string(path).split("\n"):
				if pattern.search(line) != null:
					offenders.append(path)
					break
	assert_gt(scanned, 20, "the scan really read the first-party sources")
	assert_eq(offenders, [], "no file but run_manager.gd assigns the phase")
	var owner_text: String = FileAccess.get_file_as_string("res://simulation/run/run_manager.gd")
	assert_not_null(pattern.search(owner_text), "the pattern does match the real owner")
