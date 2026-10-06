extends GutTest
## G-02-1 point 4 and D-10: the seeded balance shape after the gap closure (base dawn income,
## castle attack, sprint). Seeds 1 to 3 on the shipped data. The balanced bot wins every run,
## greedy economy play never wins and falls on the middle nights, doing nothing falls at once, and
## the owner's tower opening (towers_first) now earns gold from the base income and can win. The
## grunt keeps 6 hp: at 5 the king one-shots grunts (owner decision of 2026-10-06). The bots'
## numbers are measurements of the data, not the owner's sign-off (D-18).

const SEEDS: Array[int] = [1, 2, 3]
const GRUNT_PATH := "res://data/enemies/grunt.tres"
const GRUNT_MAX_HEALTH: int = 6
## Greedy economy must lose on a night from 3 to 6 (D-10: around the middle nights).
const GREEDY_FIRST_LOSS_NIGHT: int = 3
const GREEDY_LAST_LOSS_NIGHT: int = 6
## Doing nothing loses by night 3: at most two nights survived.
const NO_BUILD_MAX_NIGHTS_SURVIVED: int = 2
## The tower opening wins at least two of the three seeds.
const TOWERS_FIRST_MIN_WINS: int = 2

var _report: Dictionary = {}


func before_all() -> void:
	var strategies: Array[StringName] = [
		&"balanced", &"greedy_economy", &"no_build", &"towers_first"
	]
	_report = BalanceReport.run(strategies, SEEDS)


func _runs_of(strategy: StringName) -> Array:
	var matching: Array = []
	for entry: Dictionary in _report.get("runs", []):
		if entry["strategy"] == str(strategy):
			matching.append(entry)
	return matching


func test_the_matrix_ran_every_strategy_on_every_seed() -> void:
	for strategy: StringName in [&"balanced", &"greedy_economy", &"no_build", &"towers_first"]:
		assert_eq(_runs_of(strategy).size(), SEEDS.size(), "%s ran every seed" % strategy)


func test_balanced_wins_every_run() -> void:
	for entry: Dictionary in _runs_of(&"balanced"):
		assert_eq(
			entry["outcome"], BalanceReport.OUTCOME_WON, "balanced won seed %d" % entry["seed"]
		)
	assert_eq(BalanceReport.summary(_report, &"balanced")["win_rate"], 1.0, "win rate 1.0")


func test_greedy_economy_never_wins_and_loses_on_the_middle_nights() -> void:
	for entry: Dictionary in _runs_of(&"greedy_economy"):
		var label: String = "greedy seed %d" % entry["seed"]
		assert_eq(entry["outcome"], BalanceReport.OUTCOME_LOST, "%s is lost" % label)
		var loss_night: int = int(entry["nights_survived"]) + 1
		assert_between(
			loss_night, GREEDY_FIRST_LOSS_NIGHT, GREEDY_LAST_LOSS_NIGHT, "%s loss night" % label
		)
	assert_eq(BalanceReport.summary(_report, &"greedy_economy")["win_rate"], 0.0, "win rate 0")


func test_no_build_loses_by_night_three() -> void:
	for entry: Dictionary in _runs_of(&"no_build"):
		assert_eq(
			entry["outcome"], BalanceReport.OUTCOME_LOST, "no_build seed %d lost" % entry["seed"]
		)
	var summary: Dictionary = BalanceReport.summary(_report, &"no_build")
	assert_lte(
		int(summary["max_nights_survived"]), NO_BUILD_MAX_NIGHTS_SURVIVED, "at most two nights"
	)


func test_towers_first_earns_gold_in_every_run() -> void:
	for entry: Dictionary in _runs_of(&"towers_first"):
		assert_gt(
			float(entry["gold_earned"]),
			0.0,
			"towers_first earned gold on seed %d (it earned 0.0 in round 1)" % entry["seed"]
		)


func test_towers_first_wins_at_least_two_of_three() -> void:
	var wins: int = 0
	for entry: Dictionary in _runs_of(&"towers_first"):
		wins += 1 if entry["outcome"] == BalanceReport.OUTCOME_WON else 0
	assert_gte(wins, TOWERS_FIRST_MIN_WINS, "the owner's tower opening can win")


func test_the_grunt_still_has_six_hp() -> void:
	var grunt: EnemyDef = load(GRUNT_PATH)
	assert_eq(grunt.max_health, GRUNT_MAX_HEALTH, "the owner ruled out 5 hp (one-shot by the king)")
