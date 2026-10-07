extends GutTest
## G-02-1 point 4, G-02-15 and D-10: the seeded balance shape. Owner decision 2026-10-07 (round 2,
## G-02-15): the balanced bot should lose 2 or 3 of 10 runs, so the shipped nights carry the full
## wall (night 2 opens the east road, nights 3 to 5 grow). Measured: balanced 8 of 10 on seeds 1
## to 10, seeds 3 and 9 lost on night 3 (a night-3 wall for House openings). The other strategies
## keep the D-10 shape on seeds 1 to 3: greedy economy play never wins and falls on the middle
## nights, doing nothing falls at once, and the owner's tower opening (towers_first) earns gold and
## can win. The grunt keeps 6 hp: at 5 the king one-shots grunts (owner decision of 2026-10-06).
## The bots' numbers are measurements of the data, not the owner's sign-off (D-18).

const SEEDS: Array[int] = [1, 2, 3]
## The balanced bot is measured on ten seeds (owner decision 2026-10-07: it loses 2 or 3 of 10).
const BALANCED_SEEDS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
const BALANCED_MIN_WINS: int = 7
const BALANCED_MAX_WINS: int = 8
## Measured losses: exactly these seeds, never before night 3 (greedy shares nights 1 and 2).
const BALANCED_LOST_SEEDS: Array[int] = [3, 9]
const BALANCED_FIRST_LOSS_NIGHT: int = 3
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
var _balanced_report: Dictionary = {}


func before_all() -> void:
	var strategies: Array[StringName] = [&"greedy_economy", &"no_build", &"towers_first"]
	_report = BalanceReport.run(strategies, SEEDS)
	_balanced_report = BalanceReport.run([&"balanced"] as Array[StringName], BALANCED_SEEDS)


func _runs_of(strategy: StringName) -> Array:
	var matching: Array = []
	var source: Dictionary = _balanced_report if strategy == &"balanced" else _report
	for entry: Dictionary in source.get("runs", []):
		if entry["strategy"] == str(strategy):
			matching.append(entry)
	return matching


func _lost_balanced_runs() -> Array:
	var lost: Array = []
	for entry: Dictionary in _runs_of(&"balanced"):
		if entry["outcome"] == BalanceReport.OUTCOME_LOST:
			lost.append(entry)
	return lost


func test_the_matrix_ran_every_strategy_on_every_seed() -> void:
	assert_eq(_runs_of(&"balanced").size(), BALANCED_SEEDS.size(), "balanced ran all ten seeds")
	for strategy: StringName in [&"greedy_economy", &"no_build", &"towers_first"]:
		assert_eq(_runs_of(strategy).size(), SEEDS.size(), "%s ran every seed" % strategy)


func test_balanced_wins_seven_or_eight_of_seeds_one_to_ten() -> void:
	var wins: int = _runs_of(&"balanced").size() - _lost_balanced_runs().size()
	assert_between(
		wins, BALANCED_MIN_WINS, BALANCED_MAX_WINS, "G-02-15: the balanced bot wins 7 or 8 of 10"
	)


func test_balanced_loses_only_seeds_three_and_nine_and_never_before_night_three() -> void:
	var lost_seeds: Array[int] = []
	for entry: Dictionary in _lost_balanced_runs():
		lost_seeds.append(int(entry["seed"]))
		var loss_night: int = int(entry["nights_survived"]) + 1
		assert_gte(
			loss_night,
			BALANCED_FIRST_LOSS_NIGHT,
			"balanced seed %d is lost on night 3 or later" % entry["seed"]
		)
	lost_seeds.sort()
	assert_eq(lost_seeds, BALANCED_LOST_SEEDS, "the balanced losses are exactly seeds 3 and 9")


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
