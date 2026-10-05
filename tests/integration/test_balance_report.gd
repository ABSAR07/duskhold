extends GutTest
## D-18: the balance report. A small strategy-by-seed matrix is run once on the shipped data and
## read through the report's accessors. The per-night metrics of ReplayDriver are checked against
## the canonical event log, and the playtest CLI's argument allowlist is exercised without
## spawning a process (T-02-21, T-02-22). The matrix stays at four runs so the suite stays fast.

const Cli := preload("res://tools/playtest/playtest_cli.gd")
const MAP_PATH := "res://data/maps/prototype_map.tres"
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
const KING_PATH := "res://data/king/king.tres"
const RUN_KEYS: Array[String] = [
	"strategy",
	"seed",
	"outcome",
	"nights_survived",
	"gold_earned",
	"buildings_lost",
	"king_knockouts",
	"per_night",
]
const NIGHT_KEYS: Array[String] = [
	"night",
	"enemies",
	"kills_king",
	"kills_towers",
	"buildings_lost",
	"knockouts",
	"castle_hp_end",
	"duration_s",
	"gold_at_dawn",
]
const SUMMARY_KEYS: Array[String] = [
	"win_rate",
	"mean_nights_survived",
	"min_nights_survived",
	"max_nights_survived",
	"median_loss_night",
	"mean_gold_earned",
	"mean_buildings_lost",
	"mean_knockouts",
]
## Phase numbers of RunManager.RunPhase that end a night.
const PHASE_NIGHT: int = 2

var _report: Dictionary = {}
var _driver_result: Dictionary = {}


func before_all() -> void:
	var strategies: Array[StringName] = [&"balanced", &"no_build"]
	var seeds: Array[int] = [1, 2]
	_report = BalanceReport.run(strategies, seeds)
	_driver_result = ReplayDriver.run(
		load(MAP_PATH),
		load(TUNING_PATH),
		1,
		PlaytestStrategies.make(&"balanced"),
		40000,
		0,
		load(KING_PATH)
	)


func _runs() -> Array:
	return _report.get("runs", [])


func _parse(args: Array[String]) -> Dictionary:
	return Cli.parse_args(PackedStringArray(args))


func test_the_matrix_has_one_run_per_strategy_and_seed() -> void:
	assert_eq(_runs().size(), 4, "two strategies times two seeds")
	assert_eq(_report.get("seeds"), [1, 2], "the seeds are listed")
	var pairs: Dictionary = {}
	for run: Dictionary in _runs():
		pairs["%s/%d" % [run["strategy"], run["seed"]]] = true
	assert_eq(pairs.size(), 4, "every pair once")


func test_every_run_carries_the_keys_the_playtest_gate_reads() -> void:
	for run: Dictionary in _runs():
		for key: String in RUN_KEYS:
			assert_true(run.has(key), "run has %s" % key)
		assert_ne(run.get("outcome"), "timeout", "no run ends in timeout")
		for night: Dictionary in run.get("per_night", []):
			for key: String in NIGHT_KEYS:
				assert_true(night.has(key), "night has %s" % key)


func test_the_report_is_plain_json_data() -> void:
	var text: String = JSON.stringify(_report)
	var parsed: Variant = JSON.parse_string(text)
	assert_true(parsed is Dictionary, "it round-trips through JSON")
	assert_eq((parsed as Dictionary).get("runs", []).size(), 4, "with its runs")


func test_a_summary_reports_every_key_and_a_win_rate_between_zero_and_one() -> void:
	for strategy: StringName in [&"balanced", &"no_build"]:
		var summary: Dictionary = BalanceReport.summary(_report, strategy)
		for key: String in SUMMARY_KEYS:
			assert_true(summary.has(key), "%s has %s" % [strategy, key])
		assert_between(float(summary.get("win_rate", -1.0)), 0.0, 1.0, "win rate of %s" % strategy)
		assert_eq(_report["summaries"][str(strategy)], summary, "the report stores the same")


func test_no_build_never_wins_and_a_loss_reports_its_night() -> void:
	var summary: Dictionary = BalanceReport.summary(_report, &"no_build")
	assert_eq(summary["win_rate"], 0.0, "doing nothing does not win")
	assert_gt(int(summary["median_loss_night"]), 0, "it lost on a numbered night")
	assert_lte(int(summary["median_loss_night"]), 8, "inside the run")


func test_median_loss_night_is_zero_when_a_strategy_never_lost() -> void:
	var report: Dictionary = {
		"seeds": [1],
		"runs":
		[
			{
				"strategy": "x",
				"seed": 1,
				"outcome": "won",
				"nights_survived": 8,
				"gold_earned": 10,
				"buildings_lost": 0,
				"king_knockouts": 0,
				"per_night": [],
			}
		],
		"summaries": {},
	}
	var summary: Dictionary = BalanceReport.summary(report, &"x")
	assert_eq(summary["median_loss_night"], 0, "no loss, no loss night")
	assert_eq(summary["win_rate"], 1.0, "the only run won")


func test_markdown_has_a_header_row_and_one_summary_row_per_strategy() -> void:
	var text: String = BalanceReport.to_markdown(_report)
	var lines: PackedStringArray = text.split("\n")
	var header: int = 0
	var balanced_rows: int = 0
	var no_build_rows: int = 0
	for line: String in lines:
		if line.begins_with("| Strategy |"):
			header += 1
		if line.begins_with("| balanced |"):
			balanced_rows += 1
		if line.begins_with("| no_build |"):
			no_build_rows += 1
	assert_eq(header, 1, "one summary header row")
	assert_eq(balanced_rows, 1, "one balanced summary row")
	assert_eq(no_build_rows, 1, "one no_build summary row")
	assert_true(text.contains("balanced"), "the per-night section names the strategy")
	assert_true(text.contains("| Night |"), "the per-night tables have a header")


func test_per_night_has_one_entry_per_started_night() -> void:
	var per_night: Array = _driver_result.get("per_night", [])
	assert_gt(per_night.size(), 0, "at least one night was played")
	assert_eq(per_night.size(), _driver_result.get("nights_started"), "one entry per started night")
	for index: int in range(per_night.size()):
		assert_eq(per_night[index]["night"], index + 1, "numbered from 1")


## Splits the event lines into the lines of each night: from its night_started line to the
## phase_changed line that leaves NIGHT (inclusive).
func _night_lines(lines: PackedStringArray) -> Array:
	var nights: Array = []
	var current: Array = []
	var inside: bool = false
	for line: String in lines:
		var parts: PackedStringArray = line.split(" ")
		if parts[1] == "night_started":
			inside = true
			current = []
		if inside:
			current.append(line)
		if inside and parts[1] == "phase_changed" and int(parts[2]) == PHASE_NIGHT:
			nights.append(current)
			inside = false
	if inside:
		nights.append(current)
	return nights


func test_kills_by_king_and_towers_add_up_to_the_nights_deaths() -> void:
	var nights: Array = _night_lines(_driver_result["lines"])
	var per_night: Array = _driver_result["per_night"]
	assert_eq(nights.size(), per_night.size(), "the log has the same nights")
	for index: int in range(per_night.size()):
		var deaths: int = 0
		var spawns: int = 0
		for line: String in nights[index]:
			var parts: PackedStringArray = line.split(" ")
			deaths += 1 if parts[1] == "enemy_died" else 0
			spawns += 1 if parts[1] == "enemy_spawned" else 0
		var night: Dictionary = per_night[index]
		assert_eq(
			night["kills_king"] + night["kills_towers"], deaths, "night %d deaths" % (index + 1)
		)
		assert_eq(night["enemies"], spawns, "night %d enemies" % (index + 1))


func test_a_nights_duration_is_its_steps_times_the_step() -> void:
	var nights: Array = _night_lines(_driver_result["lines"])
	var per_night: Array = _driver_result["per_night"]
	for index: int in range(per_night.size()):
		var first: PackedStringArray = (nights[index][0] as String).split(" ")
		var last: PackedStringArray = (nights[index][nights[index].size() - 1] as String).split(" ")
		var steps: int = int(last[0]) - int(first[0]) + 1
		assert_almost_eq(
			float(per_night[index]["duration_s"]),
			float(steps) * SimClock.STEP,
			0.0001,
			"night %d lasted %d steps" % [index + 1, steps]
		)


func test_buildings_lost_and_knockouts_per_night_add_up_to_the_run_totals() -> void:
	var lost: int = 0
	var knockouts: int = 0
	for night: Dictionary in _driver_result["per_night"]:
		lost += int(night["buildings_lost"])
		knockouts += int(night["knockouts"])
	assert_eq(lost, _driver_result["stats"]["buildings_lost"], "buildings lost")
	assert_eq(knockouts, _driver_result["stats"]["king_knockouts"], "king knockouts")


func test_the_per_night_bookkeeping_does_not_change_the_digest() -> void:
	var again: Dictionary = ReplayDriver.run(
		load(MAP_PATH),
		load(TUNING_PATH),
		1,
		PlaytestStrategies.make(&"balanced"),
		40000,
		0,
		load(KING_PATH)
	)
	assert_eq(again["digest"], _driver_result["digest"], "the same run, the same digest")


func test_the_cli_defaults_run_every_strategy_over_ten_seeds() -> void:
	var parsed: Dictionary = _parse([])
	assert_eq(parsed.get("error"), "", "no arguments is valid")
	assert_eq(parsed.get("strategies"), PlaytestStrategies.NAMES, "every strategy")
	assert_eq(parsed.get("seeds"), 10, "seeds 1 to 10")
	assert_eq(parsed.get("out"), "res://build/playtest", "the default output directory")


func test_the_cli_accepts_a_strategy_list_and_a_seed_count() -> void:
	var parsed: Dictionary = _parse(["--strategies=no_build,balanced", "--seeds=2"])
	assert_eq(parsed.get("error"), "", "valid")
	var expected: Array[StringName] = [&"no_build", &"balanced"]
	assert_eq(parsed.get("strategies"), expected, "listed")
	assert_eq(parsed.get("seeds"), 2, "two seeds")


func test_the_cli_rejects_unknown_strategies_and_bad_seed_counts() -> void:
	assert_ne(_parse(["--strategies=nope"]).get("error"), "", "unknown strategy")
	assert_ne(_parse(["--strategies="]).get("error"), "", "empty strategy list")
	assert_ne(_parse(["--strategies=balanced,"]).get("error"), "", "empty entry")
	assert_ne(_parse(["--seeds=51"]).get("error"), "", "above the cap of 50")
	assert_ne(_parse(["--seeds=0"]).get("error"), "", "below 1")
	assert_ne(_parse(["--seeds=-3"]).get("error"), "", "negative")
	assert_ne(_parse(["--seeds=abc"]).get("error"), "", "not an integer")
	assert_ne(_parse(["--bogus"]).get("error"), "", "unknown argument")
	assert_eq(_parse(["--seeds=50"]).get("error"), "", "50 is the largest accepted count")
	assert_eq(_parse(["--seeds=1"]).get("error"), "", "1 is the smallest accepted count")


func test_the_cli_confines_the_output_directory_to_build() -> void:
	assert_eq(_parse(["--out=build/x"]).get("error"), "", "under build/")
	assert_eq(_parse(["--out=build/x"]).get("out"), "res://build/x", "normalised")
	assert_ne(_parse(["--out=../x"]).get("error"), "", "parent segments are rejected")
	assert_ne(_parse(["--out=build/../x"]).get("error"), "", "even inside a path")
	assert_ne(_parse(["--out=tests/golden"]).get("error"), "", "not outside build/")
	assert_ne(_parse(["--out=buildx"]).get("error"), "", "not a prefix sibling")
	assert_ne(_parse(["--out=/etc"]).get("error"), "", "not an absolute path elsewhere")
