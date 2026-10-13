extends GutTest
## G-02-1 point 4, G-02-15 and D-10: the seeded balance shape. Owner decision 2026-10-07 (round 2,
## G-02-15): the balanced bot should lose 2 or 3 of 10 runs, so the shipped nights carry the full
## wall (night 2 opens the east road, nights 3 to 5 grow). Measured: balanced 8 of 10 on seeds 1
## to 10, seeds 3 and 9 lost on night 3 (a night-3 wall for House openings). The other strategies
## keep the D-10 shape on seeds 1 to 3: greedy economy play never wins and falls on the middle
## nights, doing nothing falls at once, and the owner's tower opening (towers_first) earns gold and
## can win. The grunt keeps 6 hp: at 5 the king one-shots grunts (owner decision of 2026-10-06).
## The bots' numbers are measurements of the data, not the owner's sign-off (D-18).
##
## Plan 03-11 (D-08) retuned nights 5 to 8 for squads (totals 21, 22, 27, 33 became 25, 31, 39,
## 39) until the army-building bot (army_balanced) won 8 of 10 seeds, the bar the owner set in
## Phase 2 (7 or 8). Re-measured on the retuned data, old value to new value:
##   - balanced: lost seeds [9] and first loss night 3 are unchanged (9 of 10 won).
##   - greedy economy: loss nights 3 to 6 became 3 to 5 (night 5 now ends the longest runs).
##   - no_build: unchanged, at most 2 nights survived (it survives 1).
##   - towers_first: won 3 of 3 on seeds 1 to 3 and now wins 2 of 3 (seed 3 falls on night 8);
##     on seeds 1 to 10 it went from 10 wins to 3. Squads are no stronger than towers per gold,
##     so a night that is hard for the army is harder for the tower opening.
##   - army_balanced: 10 of 10 won before the retune, 8 of 10 after (seeds 1 and 9 lost).

const SEEDS: Array[int] = [1, 2, 3]
## The balanced bot is measured on ten seeds (owner decision 2026-10-07: it loses 2 or 3 of 10).
const BALANCED_SEEDS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
## The army-building bot is measured on the same ten seeds (D-08, plan 03-11): it must win 7 or 8
## of them, the bar the owner set in Phase 2.
const ARMY_BALANCED_SEEDS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
const ARMY_BALANCED_MIN_WINS: int = 7
const ARMY_BALANCED_MAX_WINS: int = 8
## G-03-11 (owner decision 2026-10-13, D-27): the balanced bot should lose 2 or 3 of the same ten
## seeds, so it wins 7 or 8 (G-02-15). Today it wins 9.
const BALANCED_MIN_WINS: int = 7
const BALANCED_MAX_WINS: int = 8
## The owner's measurable reading of "squads worth their gold against towers" (G-03-11, D-26): the
## army-building bot's unit kills per military gold divided by its tower kills per tower gold, over
## seeds 1 to 10 (plan 03-16's squad_value_ratio), is at least this.
const SQUAD_VALUE_BAR: float = 0.8  # provisional, owner-set (confirmed 2026-10-13, D-26)
## Measured losses: exactly these seeds, never before night 3 (greedy shares nights 1 and 2).
## Re-measured after D-20 regeneration (plan 03-04): the king now heals a second after a hit, so
## seed 3 (lost on night 3 before) is won and only seed 9 is lost; the balanced bot wins 9 of 10,
## one loss short of the owner's 2 or 3 (G-02-15). Plan 03-11 re-measured it after the army retune
## and it is unchanged: the retuned nights 5 to 8 do not cost the tower-heavy balanced order a run.
const BALANCED_LOST_SEEDS: Array[int] = [9]
const BALANCED_FIRST_LOSS_NIGHT: int = 3
const GRUNT_PATH := "res://data/enemies/grunt.tres"
const GRUNT_MAX_HEALTH: int = 6
## Greedy economy must lose on a night from 3 to 5 (D-10: around the middle nights; the last was
## night 6 before plan 03-11 raised night 5).
const GREEDY_FIRST_LOSS_NIGHT: int = 3
const GREEDY_LAST_LOSS_NIGHT: int = 5
## Doing nothing loses by night 3: at most two nights survived.
const NO_BUILD_MAX_NIGHTS_SURVIVED: int = 2
## The tower opening wins at least two of the three seeds (all three before plan 03-11's retune).
const TOWERS_FIRST_MIN_WINS: int = 2

var _report: Dictionary = {}
var _balanced_report: Dictionary = {}
var _army_report: Dictionary = {}


func before_all() -> void:
	var strategies: Array[StringName] = [&"greedy_economy", &"no_build", &"towers_first"]
	_report = BalanceReport.run(strategies, SEEDS)
	_balanced_report = BalanceReport.run([&"balanced"] as Array[StringName], BALANCED_SEEDS)
	_army_report = BalanceReport.run([&"army_balanced"] as Array[StringName], ARMY_BALANCED_SEEDS)


func _runs_of(strategy: StringName) -> Array:
	var matching: Array = []
	var source: Dictionary = _report
	if strategy == &"balanced":
		source = _balanced_report
	elif strategy == &"army_balanced":
		source = _army_report
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


func test_balanced_wins_every_seed_it_is_not_pinned_to_lose() -> void:
	var wins: int = 0
	for entry: Dictionary in _runs_of(&"balanced"):
		if not BALANCED_LOST_SEEDS.has(int(entry["seed"])):
			assert_eq(
				entry["outcome"],
				BalanceReport.OUTCOME_WON,
				"balanced seed %d is won" % entry["seed"]
			)
			wins += 1
	assert_eq(
		wins,
		BALANCED_SEEDS.size() - BALANCED_LOST_SEEDS.size(),
		"the balanced bot wins 9 of 10 (was 8 before D-20 regeneration; unchanged by the 03-11 retune)"
	)


func test_balanced_loses_only_seed_nine_and_never_before_night_three() -> void:
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
	assert_eq(lost_seeds, BALANCED_LOST_SEEDS, "the balanced losses are exactly seed 9")


func test_the_army_bot_ran_every_seed() -> void:
	assert_eq(_runs_of(&"army_balanced").size(), ARMY_BALANCED_SEEDS.size(), "ten seeds")


func test_the_army_building_bot_wins_seven_or_eight_of_ten_seeds() -> void:
	var wins: int = 0
	var lost_seeds: Array[int] = []
	for entry: Dictionary in _runs_of(&"army_balanced"):
		if entry["outcome"] == BalanceReport.OUTCOME_WON:
			wins += 1
		else:
			lost_seeds.append(int(entry["seed"]))
	assert_between(
		wins,
		ARMY_BALANCED_MIN_WINS,
		ARMY_BALANCED_MAX_WINS,
		"army_balanced wins 7 or 8 of 10 (lost seeds %s)" % [lost_seeds]
	)


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


func test_the_balanced_bot_wins_seven_or_eight_of_ten_seeds() -> void:
	var wins: int = 0
	var lost_seeds: Array[int] = []
	for entry: Dictionary in _runs_of(&"balanced"):
		if entry["outcome"] == BalanceReport.OUTCOME_WON:
			wins += 1
		else:
			lost_seeds.append(int(entry["seed"]))
	assert_between(
		wins,
		BALANCED_MIN_WINS,
		BALANCED_MAX_WINS,
		"G-03-11: the balanced bot wins 7 or 8 of 10 (lost seeds %s)" % [lost_seeds]
	)


func test_squads_are_worth_their_gold_against_towers() -> void:
	var summary: Dictionary = BalanceReport.summary(_army_report, &"army_balanced")
	var ratio: float = float(summary["squad_value_ratio"])
	assert_gte(
		ratio,
		SQUAD_VALUE_BAR,
		(
			(
				"G-03-11: army_balanced squad_value_ratio %.3f is at least %.2f (unit kills per military"
				+ " gold %.2f, tower kills per tower gold %.2f)"
			)
			% [
				ratio,
				SQUAD_VALUE_BAR,
				float(summary["unit_kills_per_military_gold"]),
				float(summary["tower_kills_per_tower_gold"]),
			]
		)
	)
