extends GutTest
## G-03-11: what each building role bought. The driver's tally adds the gold of every build and
## upgrade to its role, the report totals the kills squads and towers made, and the summary divides
## kills by gold per role and compares the two. Every expected number is read from the shipped defs.

const MAP_PATH := "res://data/maps/prototype_map.tres"
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
const KING_PATH := "res://data/king/king.tres"
const RICH_GOLD: int = 10000
const NEW_RUN_KEYS: Array[String] = [
	"military_gold_spent",
	"tower_gold_spent",
	"economy_gold_spent",
	"unit_kills",
	"tower_kills",
]
const ROLES: Array[String] = ["military", "towers", "economy"]


func _context_with_gold(gold: int) -> RunContext:
	var map: MapConfig = (load(MAP_PATH) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	map.starting_gold = gold
	return RunContext.new(map, load(TUNING_PATH), 1)


func _tier_cost(ctx: RunContext, spot_id: StringName, tier: int) -> int:
	return ctx.buildings.get_building_def_for_spot(spot_id).tier_def(tier).cost


## A run entry with only the keys `summary` reads, so the maths is checked on exact numbers.
func _entry(strategy: String, values: Dictionary) -> Dictionary:
	var entry: Dictionary = {
		"strategy": strategy,
		"seed": 1,
		"outcome": "won",
		"nights_survived": 8,
		"gold_earned": 10,
		"buildings_lost": 0,
		"king_knockouts": 0,
		"per_night": [],
	}
	entry.merge(values, true)
	return entry


func _report_of(runs: Array, strategies: Array[String]) -> Dictionary:
	var report: Dictionary = {"seeds": [1], "runs": runs, "summaries": {}}
	for strategy: String in strategies:
		report["summaries"][strategy] = BalanceReport.summary(report, StringName(strategy))
	return report


func test_the_tally_adds_each_build_and_upgrade_cost_to_its_role() -> void:
	var ctx: RunContext = _context_with_gold(RICH_GOLD)
	var tally: ReplayDriver.Tally = ReplayDriver.Tally.new(ctx)
	var military: int = _tier_cost(ctx, &"barracks_1", 1) + _tier_cost(ctx, &"barracks_1", 2)
	military += _tier_cost(ctx, &"archery_1", 1)
	var towers: int = _tier_cost(ctx, &"tower_1", 1)
	var economy: int = _tier_cost(ctx, &"house_1", 1)
	for spot_id: StringName in [&"barracks_1", &"barracks_1", &"archery_1", &"tower_1", &"house_1"]:
		assert_eq(ctx.commands.submit(BuildIntent.new(spot_id)), CommandProcessor.OK, str(spot_id))
	assert_eq(tally.spent["military"], military, "a build and an upgrade of squad buildings")
	assert_eq(tally.spent["towers"], towers, "the tower")
	assert_eq(tally.spent["economy"], economy, "the house")


func test_a_refused_build_spends_nothing() -> void:
	var ctx: RunContext = _context_with_gold(0)
	var tally: ReplayDriver.Tally = ReplayDriver.Tally.new(ctx)
	for spot_id: StringName in [&"barracks_1", &"tower_1", &"house_1"]:
		var result: StringName = ctx.commands.submit(BuildIntent.new(spot_id))
		assert_eq(result, CommandProcessor.CANNOT_AFFORD, "%s is refused" % spot_id)
	for role: String in ROLES:
		assert_eq(tally.spent[role], 0, "nothing spent on %s" % role)


func test_run_entries_carry_the_gold_and_kill_totals() -> void:
	var report: Dictionary = BalanceReport.run([&"army_balanced"] as Array[StringName], [1])
	var entry: Dictionary = (report["runs"] as Array)[0]
	for key: String in NEW_RUN_KEYS:
		assert_true(entry.has(key), "the entry has %s" % key)
	var unit_kills: int = 0
	var tower_kills: int = 0
	for night: Dictionary in entry["per_night"]:
		unit_kills += int(night["kills_units"])
		tower_kills += int(night["kills_towers"])
	assert_eq(entry["unit_kills"], unit_kills, "the sum of the nights' kills_units")
	assert_eq(entry["tower_kills"], tower_kills, "the sum of the nights' kills_towers")
	assert_gt(int(entry["military_gold_spent"]), 0, "the army bot spent on squads")


func test_the_summary_divides_kills_by_gold_and_guards_zero() -> void:
	var runs: Array = [
		_entry(
			"mix",
			{
				"military_gold_spent": 10,
				"unit_kills": 30,
				"tower_gold_spent": 10,
				"tower_kills": 10,
			}
		),
		_entry(
			"mix",
			{
				"military_gold_spent": 30,
				"unit_kills": 30,
				"tower_gold_spent": 10,
				"tower_kills": 30,
			}
		),
		_entry(
			"no_squads",
			{
				"military_gold_spent": 0,
				"unit_kills": 0,
				"tower_gold_spent": 8,
				"tower_kills": 16,
			}
		),
		_entry(
			"no_towers",
			{
				"military_gold_spent": 8,
				"unit_kills": 16,
				"tower_gold_spent": 0,
				"tower_kills": 0,
			}
		),
	]
	var report: Dictionary = _report_of(runs, ["mix", "no_squads", "no_towers"])
	var mix: Dictionary = report["summaries"]["mix"]
	assert_almost_eq(
		float(mix["unit_kills_per_military_gold"]), 1.5, 0.0001, "60 kills over 40 gold"
	)
	assert_almost_eq(float(mix["tower_kills_per_tower_gold"]), 2.0, 0.0001, "40 kills over 20 gold")
	assert_almost_eq(float(mix["squad_value_ratio"]), 0.75, 0.0001, "sums, not a mean of ratios")
	var no_squads: Dictionary = report["summaries"]["no_squads"]
	assert_eq(no_squads["unit_kills_per_military_gold"], 0.0, "no military gold")
	assert_eq(no_squads["squad_value_ratio"], 0.0, "no squads, no ratio")
	assert_almost_eq(
		float(no_squads["tower_kills_per_tower_gold"]), 2.0, 0.0001, "towers still count"
	)
	var no_towers: Dictionary = report["summaries"]["no_towers"]
	assert_eq(no_towers["tower_kills_per_tower_gold"], 0.0, "no tower gold")
	assert_eq(no_towers["squad_value_ratio"], 0.0, "no towers, no ratio")
	assert_almost_eq(
		float(no_towers["unit_kills_per_military_gold"]), 2.0, 0.0001, "squads still count"
	)


func test_the_markdown_lists_the_squad_value_table_with_one_row_per_strategy() -> void:
	var runs: Array = [
		_entry(
			"alpha",
			{"military_gold_spent": 10, "unit_kills": 30, "tower_gold_spent": 10, "tower_kills": 10}
		),
		_entry(
			"beta",
			{"military_gold_spent": 5, "unit_kills": 5, "tower_gold_spent": 5, "tower_kills": 10}
		),
	]
	var text: String = BalanceReport.to_markdown(_report_of(runs, ["alpha", "beta"]))
	assert_true(text.contains("## Squad value per gold"), "the section heading")
	var lines: PackedStringArray = text.split("\n")
	var start: int = lines.find("## Squad value per gold")
	assert_gt(start, -1, "the heading is a line of its own")
	if start < 0 or start + 4 >= lines.size():
		return
	var header: String = lines[start + 2]
	for column: String in [
		"Strategy",
		"Military gold (mean)",
		"Unit kills (mean)",
		"Unit kills per military gold",
		"Tower gold (mean)",
		"Tower kills (mean)",
		"Tower kills per tower gold",
		"Squad value ratio",
	]:
		assert_true(header.contains(column), "the header names %s" % column)
	var rows: Array[String] = []
	for index: int in range(start + 4, lines.size()):
		if not lines[index].begins_with("|"):
			break
		rows.append(lines[index])
	assert_eq(rows.size(), 2, "one row per strategy")
	if rows.size() != 2:
		return
	assert_true(rows[0].begins_with("| alpha |"), "alpha first")
	assert_true(rows[1].begins_with("| beta |"), "beta second")
	assert_eq(rows[0].count("|"), header.count("|"), "a value for every column")
