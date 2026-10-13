class_name BalanceReport
extends RefCounted
## The strategy by seed matrix of the playtest gate (D-18): one full scripted run of the shipped
## prototype map per named strategy and seed, the per-run and per-night numbers of each, and the
## markdown tables Claude copies into the phase directory as gate evidence. Pure data in, plain
## dictionaries out (every value is an int, float, bool, String, Array or Dictionary), so the report
## serialises as JSON as it is. tools/ is excluded from the export.
##
## Squad value (G-03-11): each run also totals the gold it spent by building role (military: a
## building with a unit_id; towers: any other building with a tier that attacks; economy: the rest)
## and the kills squads and towers made. A strategy's `squad_value_ratio` is the unit kills per
## military gold divided by the tower kills per tower gold, both summed over its runs; 1.0 means a
## gold in a squad building killed as much as a gold in a tower, and it is 0.0 when either role has
## no gold or no kills to divide.
##
## What it cannot show: the bots build instantly without riding to the plots, react perfectly and
## cannot judge tension, readability or fun. Footmen that shield a tower get no kill credit, so the
## ratio understates squads that hold a line for towers behind them. The gate decision stays with
## the owner.

const MAP_PATH := "res://data/maps/prototype_map.tres"
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
const KING_PATH := "res://data/king/king.tres"
## The tick bound of one run (T-02-21): far above the longest run, so only a hang reaches it.
const MAX_TICKS: int = 40000
const OUTCOME_WON := "won"
const OUTCOME_LOST := "lost"
const NO_VALUE := "-"
const NIGHT_COLUMNS: Array[String] = [
	"Runs",
	"Enemies",
	"Kills king",
	"Kills towers",
	"Kills castle",
	"Kills units",
	"Buildings lost",
	"Units lost",
	"Knockouts",
	"Castle hp at end",
	"Night seconds",
	"Gold at dawn",
]


## Runs every strategy over every seed on the shipped data and returns
## {seeds, runs, summaries}. A name that is not a known strategy is skipped. A run is
## {strategy, seed, outcome, nights_survived, gold_earned, buildings_lost, king_knockouts,
## per_night, military_gold_spent, tower_gold_spent, economy_gold_spent, unit_kills, tower_kills};
## summaries maps strategy to what `summary` returns.
static func run(strategies: Array[StringName], seeds: Array[int]) -> Dictionary:
	return run_on(load(MAP_PATH), load(TUNING_PATH), load(KING_PATH), strategies, seeds)


## `run` on the given data instead of the shipped files. The data is only read (DR-12).
static func run_on(
	map: MapConfig,
	tuning: LoopTuning,
	king: KingDef,
	strategies: Array[StringName],
	seeds: Array[int]
) -> Dictionary:
	var runs: Array = []
	var summaries: Dictionary = {}
	var listed_seeds: Array = []
	listed_seeds.append_array(seeds)
	var report: Dictionary = {"seeds": listed_seeds, "runs": runs, "summaries": summaries}
	for strategy: StringName in strategies:
		for run_seed: int in seeds:
			var bot: PlaytestBot = PlaytestStrategies.make(strategy)
			if bot == null:
				continue
			var result: Dictionary = ReplayDriver.run(
				map, tuning, run_seed, bot, MAX_TICKS, 0, king
			)
			runs.append(_run_entry(strategy, run_seed, result))
		summaries[str(strategy)] = summary(report, strategy)
	return report


## What one strategy did across the report's seeds: {win_rate, mean_nights_survived,
## min_nights_survived, max_nights_survived, median_loss_night, mean_gold_earned,
## mean_buildings_lost, mean_knockouts, unit_kills_per_military_gold, tower_kills_per_tower_gold,
## squad_value_ratio}. `median_loss_night` is the night number lost runs ended on (the lower middle
## one of the sorted list, ties ordered by seed) and 0 when none was lost. The three squad value
## keys divide sums over the runs, not a mean of per-run ratios, and are 0.0 when a divisor is 0.
static func summary(report: Dictionary, strategy: StringName) -> Dictionary:
	var runs: Array = _runs_of(report, strategy)
	var wins: int = 0
	var survived: Array[int] = []
	var gold: float = 0.0
	var lost_buildings: float = 0.0
	var knockouts: float = 0.0
	var losses: Array = []
	var military_gold: int = 0
	var tower_gold: int = 0
	var unit_kills: int = 0
	var tower_kills: int = 0
	for entry: Dictionary in runs:
		var nights: int = int(entry["nights_survived"])
		survived.append(nights)
		gold += float(entry["gold_earned"])
		lost_buildings += float(entry["buildings_lost"])
		knockouts += float(entry["king_knockouts"])
		military_gold += int(entry.get("military_gold_spent", 0))
		tower_gold += int(entry.get("tower_gold_spent", 0))
		unit_kills += int(entry.get("unit_kills", 0))
		tower_kills += int(entry.get("tower_kills", 0))
		if entry["outcome"] == OUTCOME_WON:
			wins += 1
		elif entry["outcome"] == OUTCOME_LOST:
			losses.append([nights + 1, int(entry["seed"])])
	var count: float = maxf(float(runs.size()), 1.0)
	var sum_nights: float = 0.0
	for nights: int in survived:
		sum_nights += float(nights)
	var unit_value: float = _per_gold(unit_kills, military_gold)
	var tower_value: float = _per_gold(tower_kills, tower_gold)
	return {
		"win_rate": float(wins) / count,
		"mean_nights_survived": sum_nights / count,
		"min_nights_survived": survived.min() if not survived.is_empty() else 0,
		"max_nights_survived": survived.max() if not survived.is_empty() else 0,
		"median_loss_night": _median_loss_night(losses),
		"mean_gold_earned": gold / count,
		"mean_buildings_lost": lost_buildings / count,
		"mean_knockouts": knockouts / count,
		"unit_kills_per_military_gold": unit_value,
		"tower_kills_per_tower_gold": tower_value,
		"squad_value_ratio": unit_value / tower_value if tower_value > 0.0 else 0.0,
	}


## The markdown of the report: a summary table with one row per strategy, then a per-night table
## per strategy averaged over the runs that started each night.
static func to_markdown(report: Dictionary) -> String:
	var seeds: Array = report.get("seeds", [])
	var summaries: Dictionary = report.get("summaries", {})
	var lines: PackedStringArray = PackedStringArray()
	lines.append("# Balance report")
	lines.append("")
	lines.append(
		"%d runs per strategy over seeds %s on the shipped prototype map." % [seeds.size(), seeds]
	)
	lines.append("")
	lines.append("## Summary")
	lines.append("")
	lines.append(
		(
			"| Strategy | Win rate | Nights survived (mean / min / max) | Median loss night"
			+ " | Gold earned (mean) | Buildings lost (mean) | Knockouts (mean) |"
		)
	)
	lines.append("|---|---:|---:|---:|---:|---:|---:|")
	for strategy: String in summaries.keys():
		lines.append(_summary_row(strategy, summaries[strategy]))
	lines.append("")
	lines.append("## Squad value per gold")
	lines.append("")
	lines.append(
		(
			"| Strategy | Military gold (mean) | Unit kills (mean) | Unit kills per military gold"
			+ " | Tower gold (mean) | Tower kills (mean) | Tower kills per tower gold"
			+ " | Squad value ratio |"
		)
	)
	lines.append("|---|---:|---:|---:|---:|---:|---:|---:|")
	for strategy: String in summaries.keys():
		lines.append(
			_value_row(strategy, _runs_of(report, StringName(strategy)), summaries[strategy])
		)
	for strategy: String in summaries.keys():
		lines.append("")
		lines.append("## Per night: %s" % strategy)
		lines.append("")
		lines.append("| Night | %s |" % " | ".join(NIGHT_COLUMNS))
		lines.append("|---|%s" % "---:|".repeat(NIGHT_COLUMNS.size()))
		for row: String in _night_rows(_runs_of(report, StringName(strategy))):
			lines.append(row)
	lines.append("")
	return "\n".join(lines)


static func _run_entry(strategy: StringName, run_seed: int, result: Dictionary) -> Dictionary:
	var stats: Dictionary = result["stats"]
	var spent: Dictionary = result["spent"]
	var unit_kills: int = 0
	var tower_kills: int = 0
	for night: Dictionary in result["per_night"]:
		unit_kills += int(night["kills_units"])
		tower_kills += int(night["kills_towers"])
	return {
		"strategy": str(strategy),
		"seed": run_seed,
		"outcome": str(result["outcome"]),
		"nights_survived": stats["nights_survived"],
		"gold_earned": stats["gold_earned"],
		"buildings_lost": stats["buildings_lost"],
		"king_knockouts": stats["king_knockouts"],
		"per_night": result["per_night"],
		"military_gold_spent": spent["military"],
		"tower_gold_spent": spent["towers"],
		"economy_gold_spent": spent["economy"],
		"unit_kills": unit_kills,
		"tower_kills": tower_kills,
	}


## `kills` over `gold`, 0.0 when there was no gold.
static func _per_gold(kills: int, gold: int) -> float:
	return float(kills) / float(gold) if gold > 0 else 0.0


static func _runs_of(report: Dictionary, strategy: StringName) -> Array:
	var matching: Array = []
	for entry: Dictionary in report.get("runs", []):
		if entry["strategy"] == str(strategy):
			matching.append(entry)
	return matching


## The night number in the middle of `losses` (each [night, seed]), 0 for an empty list. The sort
## ends in the seed, so it is a total order and the pick never depends on an unstable sort.
@warning_ignore("integer_division")
static func _median_loss_night(losses: Array) -> int:
	if losses.is_empty():
		return 0
	losses.sort_custom(_loss_before)
	return int((losses[(losses.size() - 1) / 2] as Array)[0])


static func _loss_before(a: Array, b: Array) -> bool:
	if a[0] != b[0]:
		return a[0] < b[0]
	return a[1] < b[1]


static func _summary_row(strategy: String, values: Dictionary) -> String:
	var median: int = int(values["median_loss_night"])
	return (
		"| %s | %d%% | %.1f / %d / %d | %s | %.1f | %.1f | %.1f |"
		% [
			strategy,
			roundi(float(values["win_rate"]) * 100.0),
			values["mean_nights_survived"],
			values["min_nights_survived"],
			values["max_nights_survived"],
			str(median) if median > 0 else NO_VALUE,
			values["mean_gold_earned"],
			values["mean_buildings_lost"],
			values["mean_knockouts"],
		]
	)


## One squad value row: the means over `runs` and the per-gold values of the strategy's summary.
static func _value_row(strategy: String, runs: Array, values: Dictionary) -> String:
	return (
		"| %s | %.2f | %.2f | %.2f | %.2f | %.2f | %.2f | %.2f |"
		% [
			strategy,
			_mean(runs, "military_gold_spent"),
			_mean(runs, "unit_kills"),
			values["unit_kills_per_military_gold"],
			_mean(runs, "tower_gold_spent"),
			_mean(runs, "tower_kills"),
			values["tower_kills_per_tower_gold"],
			values["squad_value_ratio"],
		]
	)


## One markdown row per night number any of `runs` started, averaged over the runs that started it.
static func _night_rows(runs: Array) -> Array[String]:
	var rows: Array[String] = []
	var last_night: int = 0
	for entry: Dictionary in runs:
		last_night = maxi(last_night, (entry["per_night"] as Array).size())
	for night_number: int in range(1, last_night + 1):
		var started: Array = []
		for entry: Dictionary in runs:
			var per_night: Array = entry["per_night"]
			if per_night.size() >= night_number:
				started.append(per_night[night_number - 1])
		(
			rows
			. append(
				(
					"| %d | %d | %.1f | %.1f | %.1f | %.1f | %.1f | %.1f | %.1f | %.1f | %.1f | %.1f | %.1f |"
					% [
						night_number,
						started.size(),
						_mean(started, "enemies"),
						_mean(started, "kills_king"),
						_mean(started, "kills_towers"),
						_mean(started, "kills_castle"),
						_mean(started, "kills_units"),
						_mean(started, "buildings_lost"),
						_mean(started, "units_lost"),
						_mean(started, "knockouts"),
						_mean(started, "castle_hp_end"),
						_mean(started, "duration_s"),
						_mean(started, "gold_at_dawn"),
					]
				)
			)
		)
	return rows


static func _mean(entries: Array, key: String) -> float:
	if entries.is_empty():
		return 0.0
	var total: float = 0.0
	for entry: Dictionary in entries:
		total += float(entry[key])
	return total / float(entries.size())
