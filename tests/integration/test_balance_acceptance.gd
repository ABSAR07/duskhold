extends GutTest
## G-02-1 point 4, G-02-15 and D-10: the seeded balance shape. Owner decision 2026-10-07 (round 2,
## G-02-15): the balanced bot should lose 2 or 3 of 10 runs, so the shipped nights carry the full
## wall (night 2 opens the east road, nights 3 to 5 grow). Measured: balanced 8 of 10 on seeds 1
## to 10, seeds 3 and 9 lost on night 3 (a night-3 wall for House openings). The other strategies
## keep the D-10 shape on seeds 1 to 3: greedy economy play never wins and falls on the middle
## nights, doing nothing falls at once, and the owner's tower opening (towers_first) earns gold and
## can win. The grunt keeps 600 hp against the king's 500 blow (owner decision of 2026-10-06).
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
##
## Round 2 (G-03-11, plan 03-17, owner decision 2026-10-13, D-26 and D-27) retuned two numbers: the
## first tower tier fires every 0.9 s (was 0.8 s) and the north road of night 8 carries 11 grunts
## (was 10). Measured on seeds 1 to 10, old value to new value:
##   - balanced: 9 of 10 won (seed 9 lost) became 8 of 10 (seeds 3 and 9 lost); BALANCED_LOST_SEEDS
##     [9] became [3, 9]; seed 3 now falls on night 8, seed 9 still on night 3, so
##     BALANCED_FIRST_LOSS_NIGHT stays 3. The two new goal tests (BALANCED_MIN_WINS 7, MAX 8) hold.
##   - army_balanced: 8 of 10 won before and after (seeds 1 and 9 lost); squad_value_ratio 0.68
##     became 0.92 (SQUAD_VALUE_BAR 0.8, D-26).
##   - greedy economy: loss nights 3 to 5 and no_build: one night survived are unchanged.
##   - towers_first: won 2 of 3 on seeds 1 to 3 (seeds 1 and 2) and now wins none; it falls on night
##     7 on all three (6 nights survived). TOWERS_FIRST_MIN_WINS 2 became
##     TOWERS_FIRST_MIN_NIGHTS_SURVIVED 6, a finding for the owner: no tower nerf that moved the
##     balanced bot to 7 or 8 wins (and the squads to the bar) left the pure tower opening a win.

##
## Plan 04-10 (D-14, D-15, Phase 4) added the wall runs. The Phase 3 pins above now live on the two
## no-walls twins, balanced_no_walls and army_balanced_no_walls, whose orders are the Phase 3
## orders: measured on the Phase 4 code they give the Phase 3 results seed for seed
## (balanced_no_walls 8 of 10, seeds 3 and 9 lost, first loss night 3; army_balanced_no_walls 8 of
## 10, seeds 1 and 9 lost, squad_value_ratio 0.915). `balanced` and `army_balanced` now buy the
## four wall runs. Their first order (each road run right after its tower) won 4 and 2 of 10, so
## the D-15 ladder moved the wall entries later (04-BALANCE-REPORT.md has the search log); the
## shipped orders win 8 of 10 each and lose exactly the twins seeds (3 and 9; 1 and 9), with a
## squad_value_ratio of 0.888 for the army bot. No night count, wall cost or other data moved.
## greedy economy, no_build and towers_first are unchanged.
##
## Plan 05-11 (D-03, D-08, BLDG-09, Phase 5) put the castle gate in the shipped data (the last tier
## of House, Tower, Barracks, Archery Range and Wall needs castle II; Mill III and Harbor II already
## did) and made the bots play the new day. The names moved: the Phase 4 orders are now
## balanced_no_castle and army_balanced_no_castle (unchanged orders, they never buy the castle and
## so measure what the gate costs), and balanced and army_balanced are the castle-aware orders,
## which buy the Fishing Harbor, the castle with one card pick per tier, the Gold Mine, the Mill and
## its Fields and the Shrines (05-BALANCE-REPORT.md has the search log). Measured on seeds 1 to 10,
## old value to new value:
##   - balanced (now castle-aware): 8 of 10 won (seeds 3 and 9 lost) before and after; seed 3 is
##     now lost on night 7 (night 8 before), seed 9 still on night 3, so BALANCED_FIRST_LOSS_NIGHT
##     stays 3. The first castle upgrade is bought on day 6 at the earliest (D-01: never before
##     day 2).
##   - army_balanced: 8 of 10 won (seeds 1 and 9 lost) before and after, squad_value_ratio 0.888
##     before and after: the squad build cannot afford the castle in an eight-night run (it earns
##     about 15 gold), so only its new Harbor and Mine entries differ from the Phase 4 order.
##   - balanced_no_castle: 8 of 10 won became 3 of 10 (seeds 2, 4, 5, 6, 8, 9 and 10 lost): without
##     castle II the Phase 4 order can no longer upgrade a tower, which is what the gate costs a bot
##     that ignores the castle. army_balanced_no_castle is unchanged (8 of 10, seeds 1 and 9)
##     because its order reaches Tower II only after the gold has run out.
##   - balanced_no_walls: 8 of 10 won became 4 of 10 (seeds 1, 3, 4, 6, 9 and 10 lost), the same
##     gate cost on the Phase 3 order; army_balanced_no_walls is unchanged (8 of 10, ratio 0.915).
##   - greedy economy (loss nights 3 to 5), no_build (one night survived) and towers_first (loses
##     on nights 7 and 8, 6 or 7 nights survived) keep their pins.
## No night count, castle number, card or economy number moved: the order lever of the D-15 ladder
## was enough, so BALANCED_MIN_WINS 7 and BALANCED_MAX_WINS 8 stand.
##
## Gap round G-05-2 (plans 05-13 to 05-24, owner UAT decision 2026-10-25): every health and
## damage number is 100 times larger, the owner's hard requirement, so percentages and rounding
## to the nearest unit work as written. GRUNT_MAX_HEALTH 6 became 600; every other pin is
## unchanged because every hits-to-kill count is (the bots measured the scaled game in plan
## 05-14).

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
## Round 2 (plan 03-17, G-03-11) re-measured it: [9] became [3, 9] (8 of 10 won); seed 3 is lost on
## night 8, seed 9 on night 3.
const BALANCED_LOST_SEEDS: Array[int] = [3, 9]
const BALANCED_FIRST_LOSS_NIGHT: int = 3
## Plan 04-10: the balanced bot with the wall runs loses the same two seeds, and the army bot with
## them the same two as without (the army twin's lost seeds are pinned beside its win count). Plan
## 05-11: the castle-aware balanced bot still loses exactly seeds 3 and 9.
const BALANCED_WALLS_LOST_SEEDS: Array[int] = [3, 9]
const ARMY_BALANCED_LOST_SEEDS: Array[int] = [1, 9]
const ARMY_BALANCED_WALLS_LOST_SEEDS: Array[int] = [1, 9]
## Plan 05-11: what the castle gate costs the bots that never buy the castle, as measured on seeds
## 1 to 10. The Phase 4 balanced order (balanced_no_castle) wins 3 and loses these seven seeds; the
## Phase 3 order (balanced_no_walls) wins 4 and loses these six.
const BALANCED_NO_CASTLE_LOST_SEEDS: Array[int] = [2, 4, 5, 6, 8, 9, 10]
const BALANCED_NO_WALLS_LOST_SEEDS: Array[int] = [1, 3, 4, 6, 9, 10]
## D-01: the castle-aware balanced bot never upgrades the castle before this day (the first day is
## day 1); measured, its earliest first upgrade is day 6.
const CASTLE_EARLIEST_DAY: int = 2
const SHIPPED_EARLIEST_CASTLE_DAY: int = 6
## Review WR-06: seeds of ten in which each bot with walls bought at least one wall tier, as
## measured; the orders put the walls late, so most seeds never reach them. Plan 05-11: under the
## gate the Phase 4 balanced order spends less on the economy than the Phase 3 order in nine seeds
## of ten (it cannot upgrade its towers and loses earlier), so the economy-gold comparison only
## still separates the army pair; the balanced pair floor is the one seed measured.
const BALANCED_WALL_SEEDS_MIN: int = 1
const ARMY_BALANCED_WALL_SEEDS_MIN: int = 3
const GRUNT_PATH := "res://data/enemies/grunt.tres"
const GRUNT_MAX_HEALTH: int = 600
## Greedy economy must lose on a night from 3 to 5 (D-10: around the middle nights; the last was
## night 6 before plan 03-11 raised night 5).
const GREEDY_FIRST_LOSS_NIGHT: int = 3
const GREEDY_LAST_LOSS_NIGHT: int = 5
## Doing nothing loses by night 3: at most two nights survived.
const NO_BUILD_MAX_NIGHTS_SURVIVED: int = 2
## The tower opening survives at least six nights on every one of its three seeds. It won two of the
## three (all three before plan 03-11's retune) until Round 2 (plan 03-17) slowed the first tower
## tier; it now falls on night 7 on each (6 nights survived), so the old "wins at least two of
## three" pin (TOWERS_FIRST_MIN_WINS 2) became this nights-survived pin.
const TOWERS_FIRST_MIN_NIGHTS_SURVIVED: int = 6

var _report: Dictionary = {}
var _balanced_report: Dictionary = {}
var _army_report: Dictionary = {}
var _twin_report: Dictionary = {}
var _no_castle_report: Dictionary = {}


func before_all() -> void:
	var strategies: Array[StringName] = [&"greedy_economy", &"no_build", &"towers_first"]
	_report = BalanceReport.run(strategies, SEEDS)
	_balanced_report = BalanceReport.run([&"balanced"] as Array[StringName], BALANCED_SEEDS)
	_army_report = BalanceReport.run([&"army_balanced"] as Array[StringName], ARMY_BALANCED_SEEDS)
	var twins: Array[StringName] = [&"balanced_no_walls", &"army_balanced_no_walls"]
	_twin_report = BalanceReport.run(twins, BALANCED_SEEDS)
	var no_castle: Array[StringName] = [&"balanced_no_castle", &"army_balanced_no_castle"]
	_no_castle_report = BalanceReport.run(no_castle, BALANCED_SEEDS)


func _runs_of(strategy: StringName) -> Array:
	var matching: Array = []
	var source: Dictionary = _report
	if strategy == &"balanced":
		source = _balanced_report
	elif strategy == &"army_balanced":
		source = _army_report
	elif strategy == &"balanced_no_walls" or strategy == &"army_balanced_no_walls":
		source = _twin_report
	elif strategy == &"balanced_no_castle" or strategy == &"army_balanced_no_castle":
		source = _no_castle_report
	for entry: Dictionary in source.get("runs", []):
		if entry["strategy"] == str(strategy):
			matching.append(entry)
	return matching


func _lost_runs(strategy: StringName) -> Array:
	var lost: Array = []
	for entry: Dictionary in _runs_of(strategy):
		if entry["outcome"] == BalanceReport.OUTCOME_LOST:
			lost.append(entry)
	return lost


func _lost_seeds(strategy: StringName) -> Array[int]:
	var seeds: Array[int] = []
	for entry: Dictionary in _lost_runs(strategy):
		seeds.append(int(entry["seed"]))
	seeds.sort()
	return seeds


func test_the_matrix_ran_every_strategy_on_every_seed() -> void:
	assert_eq(_runs_of(&"balanced").size(), BALANCED_SEEDS.size(), "balanced ran all ten seeds")
	for twin: StringName in [
		&"balanced_no_walls",
		&"army_balanced_no_walls",
		&"balanced_no_castle",
		&"army_balanced_no_castle"
	]:
		assert_eq(_runs_of(twin).size(), BALANCED_SEEDS.size(), "%s ran all ten seeds" % twin)
	for strategy: StringName in [&"greedy_economy", &"no_build", &"towers_first"]:
		assert_eq(_runs_of(strategy).size(), SEEDS.size(), "%s ran every seed" % strategy)


func test_the_gate_costs_the_phase_three_balanced_order_six_seeds() -> void:
	## Plan 05-11: the Phase 3 order (balanced_no_walls) won 8 of 10 before the gate and wins 4 now;
	## it keeps its Phase 3 loss night floor (night 3 or later) and loses exactly these seeds.
	assert_eq(
		_lost_seeds(&"balanced_no_walls"),
		BALANCED_NO_WALLS_LOST_SEEDS,
		"the gate turns the Phase 3 order's seeds 1, 4, 6 and 10 into losses (3 and 9 stay lost)"
	)
	for entry: Dictionary in _lost_runs(&"balanced_no_walls"):
		assert_gte(
			int(entry["nights_survived"]) + 1,
			BALANCED_FIRST_LOSS_NIGHT,
			"balanced_no_walls seed %d is lost on night 3 or later" % entry["seed"]
		)


func test_the_gate_costs_the_phase_four_balanced_order_seven_seeds() -> void:
	## Plan 05-11: balanced_no_castle is the Phase 4 order. Without castle II it cannot upgrade a
	## tower and wins 3 of 10; this is what the gate costs a bot that ignores the castle, and the
	## reason the castle-aware order exists.
	assert_eq(
		_lost_seeds(&"balanced_no_castle"),
		BALANCED_NO_CASTLE_LOST_SEEDS,
		"the Phase 4 order loses seven seeds with the gate on"
	)
	for entry: Dictionary in _lost_runs(&"balanced_no_castle"):
		assert_gte(
			int(entry["nights_survived"]) + 1,
			BALANCED_FIRST_LOSS_NIGHT,
			"balanced_no_castle seed %d is lost on night 3 or later" % entry["seed"]
		)


func test_the_castle_aware_balanced_bot_never_buys_the_castle_before_day_two() -> void:
	## D-01: the first upgrade is a real trade-off. Every run that upgraded the castle did it on day
	## 2 or later, and the earliest measured first upgrade is day 6 (the castle costs 6 gold, and
	## the bot holds 4 at the start and 1 more at the first dawn).
	var earliest: int = 0
	for entry: Dictionary in _runs_of(&"balanced"):
		var days: Array = entry["castle_days"]
		if days.is_empty():
			continue
		var first: int = int(days[0])
		assert_gte(first, CASTLE_EARLIEST_DAY, "seed %d: day of the first upgrade" % entry["seed"])
		earliest = first if earliest == 0 else mini(earliest, first)
	assert_eq(earliest, SHIPPED_EARLIEST_CASTLE_DAY, "the earliest first upgrade measured")
	var summary: Dictionary = BalanceReport.summary(_balanced_report, &"balanced")
	assert_gt(float(summary["mean_castle_tier_reached"]), 1.0, "the bot does buy the castle")


func test_balanced_with_walls_loses_the_same_two_seeds() -> void:
	assert_eq(
		_lost_seeds(&"balanced"),
		BALANCED_WALLS_LOST_SEEDS,
		"D-08 same outcomes: the castle-aware order loses the seeds the Phase 4 order lost"
	)
	for entry: Dictionary in _lost_runs(&"balanced"):
		assert_gte(
			int(entry["nights_survived"]) + 1,
			BALANCED_FIRST_LOSS_NIGHT,
			"balanced seed %d is lost on night 3 or later" % entry["seed"]
		)


func test_the_army_bot_ran_every_seed() -> void:
	assert_eq(_runs_of(&"army_balanced").size(), ARMY_BALANCED_SEEDS.size(), "ten seeds")


func test_the_army_building_bot_wins_seven_or_eight_of_ten_seeds() -> void:
	## D-15 / Phase 2 bar with the wall runs bought: 7 or 8 of seeds 1 to 10.
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
	assert_eq(
		lost_seeds, ARMY_BALANCED_WALLS_LOST_SEEDS, "and loses seeds 1 and 9 as without walls"
	)


func test_the_army_no_walls_twin_keeps_the_phase_three_result() -> void:
	var wins: int = 0
	for entry: Dictionary in _runs_of(&"army_balanced_no_walls"):
		wins += 1 if entry["outcome"] == BalanceReport.OUTCOME_WON else 0
	assert_between(wins, ARMY_BALANCED_MIN_WINS, ARMY_BALANCED_MAX_WINS, "7 or 8 of 10")
	assert_eq(wins, 8, "exactly the Phase 3 eight")
	assert_eq(_lost_seeds(&"army_balanced_no_walls"), ARMY_BALANCED_LOST_SEEDS, "seeds 1 and 9")


func test_the_army_no_castle_twin_keeps_the_phase_four_result() -> void:
	## Plan 05-11: the gate costs the army order nothing, since it reaches Tower II only after its
	## gold has run out: 8 of 10 won, seeds 1 and 9 lost, as in Phase 4.
	var wins: int = 0
	for entry: Dictionary in _runs_of(&"army_balanced_no_castle"):
		wins += 1 if entry["outcome"] == BalanceReport.OUTCOME_WON else 0
	assert_eq(wins, 8, "exactly the Phase 4 eight")
	assert_eq(_lost_seeds(&"army_balanced_no_castle"), ARMY_BALANCED_LOST_SEEDS, "seeds 1 and 9")


func test_the_bots_with_walls_pay_for_walls_in_enough_seeds() -> void:
	## The wall entries are in the orders but sit late (the economy leaves little room), so some
	## seeds never reach them. A wall counts as economy in the gold ledger, so a seed in which the
	## bot bought a wall tier spends more on the economy role than the same seed of its twin.
	## Measured on seeds 1 to 10 (plan 05-11, the Phase 4 orders against the Phase 3 orders, both
	## under the castle gate): balanced_no_castle buys walls in 1 seed, army_balanced_no_castle in 3.
	## The floors are those counts, so a change that makes the orders skip the walls fails here
	## (review WR-06).
	## No wall segment falls in any of these runs (the per-night walls_broken column is all zero),
	## so wall damage is pinned by the walls scenarios, not here.
	for pair: Array in [
		[&"balanced_no_castle", &"balanced_no_walls", BALANCED_WALL_SEEDS_MIN],
		[&"army_balanced_no_castle", &"army_balanced_no_walls", ARMY_BALANCED_WALL_SEEDS_MIN]
	]:
		var with_walls: Array = _runs_of(pair[0])
		var without: Array = _runs_of(pair[1])
		var seeds_with_walls: int = 0
		for index: int in range(with_walls.size()):
			assert_eq(with_walls[index]["seed"], without[index]["seed"], "same seed order")
			var extra: int = (
				int(with_walls[index]["economy_gold_spent"])
				- int(without[index]["economy_gold_spent"])
			)
			seeds_with_walls += 1 if extra > 0 else 0
		assert_gte(
			seeds_with_walls,
			int(pair[2]),
			"%s paid for a wall tier in at least %d of ten seeds" % [pair[0], int(pair[2])]
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


func test_towers_first_survives_at_least_six_nights_on_every_pinned_seed() -> void:
	for entry: Dictionary in _runs_of(&"towers_first"):
		assert_gte(
			int(entry["nights_survived"]),
			TOWERS_FIRST_MIN_NIGHTS_SURVIVED,
			"the owner's tower opening survives 6 nights on seed %d" % entry["seed"]
		)


func test_the_grunt_still_has_six_hundred_hp() -> void:
	var grunt: EnemyDef = load(GRUNT_PATH)
	assert_eq(
		grunt.max_health,
		GRUNT_MAX_HEALTH,
		"the owner ruled out 500 hp (one-shot by the king's 500)"
	)


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
		(
			"G-03-11 / D-15: the balanced bot with walls wins 7 or 8 of 10 (lost seeds %s)"
			% [lost_seeds]
		)
	)


func test_squads_are_worth_their_gold_against_towers() -> void:
	## D-26 stays pinned where Phase 3 measured it, on the army twin without walls. The ratio with
	## the wall runs bought (0.888) is reported in 04-BALANCE-REPORT.md; a value under the bar there
	## would be a finding for the owner, not a retune (plan 04-10).
	var castle_aware: Dictionary = BalanceReport.summary(_army_report, &"army_balanced")
	assert_gte(
		float(castle_aware["squad_value_ratio"]),
		SQUAD_VALUE_BAR,
		(
			"plan 05-11: the castle-aware army bot's squad value ratio %.3f is at least %.2f"
			% [float(castle_aware["squad_value_ratio"]), SQUAD_VALUE_BAR]
		)
	)
	var summary: Dictionary = BalanceReport.summary(_twin_report, &"army_balanced_no_walls")
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
