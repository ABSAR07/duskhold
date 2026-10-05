extends GutTest
## RESEARCH Pitfall 7: a night must never hang. Under the balanced strategy, for seeds 1 to 10 on
## the shipped data, every night that starts ends in dawn, victory or defeat inside the per-night
## tick budget, and no run ends in timeout. The budget is 300 simulated seconds per night, far
## above the longest shipped night, so only a stuck enemy or a schedule that never finishes can
## reach it.

const MAP_PATH := "res://data/maps/prototype_map.tres"
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
const KING_PATH := "res://data/king/king.tres"
const SEED_COUNT: int = 10
const NIGHT_BUDGET_S: float = 300.0
const ENDINGS: Array[String] = ["dawn", "won", "lost"]


func _run(run_seed: int) -> Dictionary:
	var map: MapConfig = load(MAP_PATH)
	var nights: int = map.nights.size()
	var run_budget: int = nights * (SimClock.ticks(NIGHT_BUDGET_S) + SimClock.ticks(60.0))
	return ReplayDriver.run(
		map,
		load(TUNING_PATH),
		run_seed,
		PlaytestStrategies.make(&"balanced"),
		run_budget,
		0,
		load(KING_PATH)
	)


func test_every_started_night_ends_inside_its_budget_on_all_ten_seeds() -> void:
	for run_seed: int in range(1, SEED_COUNT + 1):
		var result: Dictionary = _run(run_seed)
		assert_ne(
			result["outcome"], ReplayDriver.OUTCOME_TIMEOUT, "seed %d did not time out" % run_seed
		)
		var per_night: Array = result["per_night"]
		assert_gt(per_night.size(), 0, "seed %d started a night" % run_seed)
		for night: Dictionary in per_night:
			var label: String = "seed %d night %d" % [run_seed, night["night"]]
			assert_true(ENDINGS.has(night["end"]), "%s ended (%s)" % [label, night["end"]])
			assert_lte(float(night["duration_s"]), NIGHT_BUDGET_S, "%s inside the budget" % label)
			assert_gt(float(night["duration_s"]), 0.0, "%s took at least one step" % label)
		for index: int in range(per_night.size() - 1):
			assert_eq(
				per_night[index]["end"],
				"dawn",
				"seed %d: only the last night ends the run" % run_seed
			)
