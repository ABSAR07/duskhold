extends GutTest
## DEV-05: the same map, seed and scripted bot replay to the same integer-only event digest. The
## same-process double run is the primary proof; the recorder's drift guard keeps a new SimEvents
## signal from going unrecorded.

const FIXTURE := "res://tests/fixtures/fixture_map_one_night.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const HOLD_POINT := Vector2(-4.5, 0.0)
const MAX_TICKS: int = 2500
const LINE_FORMAT := "^-?[0-9]+ [a-z_]+( [^ ]+)*$"

var _map: MapConfig
var _tuning: LoopTuning


func before_each() -> void:
	_map = load(FIXTURE)
	_tuning = load(TUNING)


func _bot(start_nights: bool = true) -> PlaytestBot:
	var bot: PlaytestBot = PlaytestBot.new()
	bot.king_mode = PlaytestBot.KING_HOLD_POINT
	bot.hold_point = HOLD_POINT
	bot.start_nights = start_nights
	return bot


func _run(run_seed: int) -> Dictionary:
	return ReplayDriver.run(_map, _tuning, run_seed, _bot(), MAX_TICKS, 1)


func _signal_names(source: Array) -> Array[String]:
	var names: Array[String] = []
	for entry: String in source:
		names.append(entry)
	names.sort()
	return names


func test_two_runs_of_the_same_seed_and_script_give_identical_digests() -> void:
	var first: Dictionary = _run(1)
	var second: Dictionary = _run(1)
	assert_eq(first["outcome"], &"stopped", "the run stops after the first dawn")
	assert_eq(second["outcome"], &"stopped", "and so does the twin")
	assert_eq(first["digest"], second["digest"], "same seed, same digest")
	assert_eq(first["line_count"], second["line_count"], "same number of lines")
	assert_eq(first["ticks"], second["ticks"], "same final tick")
	assert_gt(first["line_count"], 10, "the log really recorded the night")


func test_adjacent_seeds_give_different_digests() -> void:
	var one: Dictionary = _run(1)
	var two: Dictionary = _run(2)
	assert_ne(one["digest"], two["digest"], "seed 1 and seed 2 scatter the spawns differently")


func test_the_digest_is_a_sha256_even_when_the_run_times_out() -> void:
	var result: Dictionary = ReplayDriver.run(_map, _tuning, 1, _bot(false), 10)
	assert_eq(result["outcome"], &"timeout", "a bot that never starts the night times out")
	assert_eq(String(result["digest"]).length(), 64, "a 64 character digest")
	assert_true(String(result["digest"]).is_valid_hex_number(), "in hex")
	assert_eq(result["ticks"], 10, "after exactly max_ticks")


func test_the_recorder_handles_every_signal_the_simulation_declares() -> void:
	var declared: Array[String] = []
	for info: Dictionary in SimEvents.new().get_script().get_script_signal_list():
		declared.append(info["name"])
	declared.sort()
	assert_eq(_signal_names(SimRecorder.HANDLED), declared, "a SimEvents signal has no handler")
	assert_eq(_signal_names(SimRecorder.HANDLED), _signal_names(SimSignals.ALL), "same list")


func test_every_line_is_integers_ids_and_names_only() -> void:
	var lines: PackedStringArray = _run(1)["lines"]
	var format: RegEx = RegEx.create_from_string(LINE_FORMAT)
	assert_gt(lines.size(), 0, "there are lines to check")
	for line: String in lines:
		assert_not_null(format.search(line), "line shape: %s" % line)
		for token: String in line.split(" "):
			assert_false(
				token.is_valid_float() and not token.is_valid_int(), "raw float in: %s" % line
			)


func test_lines_follow_emission_order_exactly() -> void:
	var ctx: RunContext = RunContext.new(_map, _tuning, 1)
	var recorder: SimRecorder = SimRecorder.attach(ctx)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night starts")
	var names: Array[String] = []
	for line: String in recorder.lines():
		names.append(line.split(" ")[1])
	assert_eq(
		names,
		["phase_changed", "phase_changed", "night_started"] as Array[String],
		"transition, night, then the announcement"
	)


func test_the_fixture_night_logs_three_deaths_and_the_kings_attacks() -> void:
	var lines: PackedStringArray = _run(1)["lines"]
	var deaths: int = 0
	var attacks: int = 0
	for line: String in lines:
		var event_name: String = line.split(" ")[1]
		if event_name == "enemy_died":
			deaths += 1
		if event_name == "attack_fired":
			attacks += 1
	assert_eq(deaths, _map.night_def(1).groups[0].count, "every grunt's death is logged")
	assert_gt(attacks, 0, "the king's attacks are logged")


func test_the_final_state_line_is_part_of_the_digested_log() -> void:
	var lines: PackedStringArray = _run(1)["lines"]
	assert_gt(lines.size(), 0, "there are lines")
	if lines.size() > 0:
		assert_true(lines[lines.size() - 1].contains(" final "), "the last line is the final state")
