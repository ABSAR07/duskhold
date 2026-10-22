extends GutTest
## Plan 05-11: the balance report's castle and Shrine columns. A two-seed report for the
## castle-aware bot carries the castle tier it reached, the card ids it picked in pick order and
## the gold it put into the castle and into Shrines; a bot that never buys the castle reports tier
## 1 and no picks. The tally classes a castle-plot purchase as "castle" and a Shrine as "shrine"
## before the attack test (both shoot, neither is a road tower), a Gold Mine as economy and a Tower
## as towers. The columns are read-only bookkeeping: they never move a run's digest.

const MAP_PATH := "res://data/maps/prototype_map.tres"
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
const KING_PATH := "res://data/king/king.tres"
const RICH_GOLD: int = 10000
const CASTLE: StringName = &"castle_plot"
const CARD: StringName = &"royal_training"

var _report: Dictionary = {}


func before_all() -> void:
	var strategies: Array[StringName] = [&"balanced", &"balanced_no_castle"]
	var seeds: Array[int] = [1, 2]
	_report = BalanceReport.run(strategies, seeds)


func _runs_of(strategy: StringName) -> Array:
	var matching: Array = []
	for entry: Dictionary in _report.get("runs", []):
		if entry["strategy"] == str(strategy):
			matching.append(entry)
	return matching


func _rich_context() -> RunContext:
	var map: MapConfig = (load(MAP_PATH) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	map.starting_gold = RICH_GOLD
	return RunContext.new(map, load(TUNING_PATH), 1)


func _tier_cost(ctx: RunContext, spot_id: StringName, tier: int) -> int:
	return ctx.buildings.get_building_def_for_spot(spot_id).tier_def(tier).cost


func test_a_castle_aware_run_reports_a_castle_tier_between_one_and_four() -> void:
	var runs: Array = _runs_of(&"balanced")
	assert_eq(runs.size(), 2, "two seeds")
	for entry: Dictionary in runs:
		assert_between(int(entry["castle_tier_reached"]), 1, 4, "seed %d" % entry["seed"])
		assert_true(entry.has("castle_gold_spent"), "the castle spend column")
		assert_true(entry.has("shrine_gold_spent"), "the Shrine spend column")


func test_picks_list_the_card_ids_in_pick_order_and_match_the_tier_reached() -> void:
	var pick_order: Array[String] = []
	for card: StringName in PlaytestStrategies.make(&"balanced").card_picks:
		pick_order.append(String(card))
	for entry: Dictionary in _runs_of(&"balanced"):
		var picks: Array = entry["picks"]
		var tier: int = int(entry["castle_tier_reached"])
		assert_eq(picks.size(), tier - 1, "one pick per castle upgrade (seed %d)" % entry["seed"])
		assert_eq(
			picks, pick_order.slice(0, picks.size()), "the bot's cards, in the order it picks them"
		)
		assert_eq((entry["castle_days"] as Array).size(), picks.size(), "one day per upgrade")
		for day: int in entry["castle_days"]:
			assert_gte(day, 2, "D-01: never bought on the first day")


func test_castle_gold_spent_equals_the_cost_of_the_tiers_bought() -> void:
	var ctx: RunContext = _rich_context()
	for entry: Dictionary in _runs_of(&"balanced"):
		var expected: int = 0
		for tier: int in range(2, int(entry["castle_tier_reached"]) + 1):
			expected += _tier_cost(ctx, CASTLE, tier)
		assert_eq(int(entry["castle_gold_spent"]), expected, "seed %d" % entry["seed"])


func test_a_bot_that_never_buys_the_castle_reports_tier_one_and_no_picks() -> void:
	for entry: Dictionary in _runs_of(&"balanced_no_castle"):
		assert_eq(entry["castle_tier_reached"], 1, "seed %d stays at tier I" % entry["seed"])
		assert_eq((entry["picks"] as Array).size(), 0, "no card was picked")
		assert_eq((entry["castle_days"] as Array).size(), 0, "no castle upgrade day")
		assert_eq(entry["castle_gold_spent"], 0, "no castle gold")
		assert_eq(entry["shrine_gold_spent"], 0, "no Shrine gold")


func test_the_summary_carries_the_castle_columns() -> void:
	var castle: Dictionary = BalanceReport.summary(_report, &"balanced")
	assert_between(float(castle["mean_castle_tier_reached"]), 1.0, 4.0, "mean tier")
	assert_gte(int(castle["earliest_castle_day"]), 0, "0 when never upgraded")
	var twin: Dictionary = BalanceReport.summary(_report, &"balanced_no_castle")
	assert_eq(twin["mean_castle_tier_reached"], 1.0, "the twin never upgrades")
	assert_eq(twin["earliest_castle_day"], 0, "so it has no first day")
	assert_eq(twin["mean_castle_gold_spent"], 0.0, "and no castle gold")


func test_the_markdown_has_a_castle_and_shrine_table_with_a_row_per_strategy() -> void:
	var text: String = BalanceReport.to_markdown(_report)
	assert_true(text.contains("## Castle and Shrine"), "the section heading")
	var rows: int = 0
	var inside: bool = false
	for line: String in text.split("\n"):
		if line.begins_with("## "):
			inside = line == "## Castle and Shrine"
		var is_row: bool = line.begins_with("| balanced |")
		is_row = is_row or line.begins_with("| balanced_no_castle |")
		if inside and is_row:
			rows += 1
			assert_eq(line.count("|"), 7, "six cells")
	assert_eq(rows, 2, "one row per strategy")


func test_the_tally_classes_each_building_by_role() -> void:
	var ctx: RunContext = _rich_context()
	var tally: ReplayDriver.Tally = ReplayDriver.Tally.new(ctx)
	var castle_cost: int = _tier_cost(ctx, CASTLE, 2)
	var shrine_cost: int = _tier_cost(ctx, &"shrine_west", 1)
	var mine_cost: int = _tier_cost(ctx, &"gold_mine_1", 1)
	var tower_cost: int = _tier_cost(ctx, &"tower_1", 1)
	assert_eq(ctx.commands.submit(BuildIntent.new(CASTLE, CARD)), CommandProcessor.OK, "castle II")
	for spot_id: StringName in [&"shrine_west", &"gold_mine_1", &"tower_1"]:
		assert_eq(ctx.commands.submit(BuildIntent.new(spot_id)), CommandProcessor.OK, str(spot_id))
	assert_eq(tally.spent["castle"], castle_cost, "a castle plot purchase is castle gold")
	assert_eq(tally.spent["shrine"], shrine_cost, "a Shrine is shrine gold, not tower gold")
	assert_eq(tally.spent["economy"], mine_cost, "a Gold Mine is economy")
	assert_eq(tally.spent["towers"], tower_cost, "a Tower is towers")
	assert_eq(tally.spent["military"], 0, "no squad building")
	assert_eq(tally.picks, [String(CARD)] as Array[String], "the card id was recorded")
	assert_eq(tally.castle_tier(), 2, "the castle stands at tier II")
	assert_eq(tally.castle_days, [1] as Array[int], "bought on day 1 of this hand-driven run")


func test_the_castle_columns_do_not_change_a_runs_digest() -> void:
	var first: Dictionary = _run_once()
	var second: Dictionary = _run_once()
	assert_eq(first["digest"], second["digest"], "the same bot and seed, the same run")
	assert_eq(first["picks"], second["picks"], "and the same picks")


func _run_once() -> Dictionary:
	return ReplayDriver.run(
		load(MAP_PATH),
		load(TUNING_PATH),
		1,
		PlaytestStrategies.make(&"balanced"),
		40000,
		0,
		load(KING_PATH)
	)
