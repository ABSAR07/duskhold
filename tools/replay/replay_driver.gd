class_name ReplayDriver
extends RefCounted
## Runs one scripted, seeded playthrough headlessly and returns its outcome and event digest
## (DEV-05). Every run is bounded by `max_ticks` (threat T-02-02) and never edits the map or tuning
## it is given (DR-12). A run that ends stops at its terminal step with the outcome `won` or `lost`
## and the run's stats; later plans add per-night metrics.
## tools/ is excluded from the export.

## Outcome when the run reached `stop_after_dawns` dawns.
const OUTCOME_STOPPED := &"stopped"
## Outcome when `max_ticks` ran out first.
const OUTCOME_TIMEOUT := &"timeout"
## Outcome when the last night was cleared (RunManager reached WON).
const OUTCOME_WON := &"won"
## Outcome when the castle fell (RunManager reached LOST).
const OUTCOME_LOST := &"lost"


## Result: {outcome, ticks, digest, line_count, nights_started, lines, stats}, where stats holds the
## RunStats values {nights_survived, gold_earned, buildings_lost, king_knockouts, outcome}.
## `stop_after_dawns` of 0 means run until the run ends or `max_ticks` runs out.
static func run(
	map: MapConfig,
	tuning: LoopTuning,
	run_seed: int,
	bot: PlaytestBot,
	max_ticks: int,
	stop_after_dawns: int = 0,
	king_def: KingDef = null
) -> Dictionary:
	var ctx: RunContext = RunContext.new(map, tuning, run_seed, king_def)
	var recorder: SimRecorder = SimRecorder.attach(ctx)
	var tally: Tally = Tally.new()
	ctx.events.phase_changed.connect(tally.on_phase_changed)
	ctx.events.night_started.connect(tally.on_night_started)
	var outcome: StringName = OUTCOME_TIMEOUT
	for _tick: int in range(maxi(max_ticks, 0)):
		bot.think(ctx)
		ctx.step()
		if ctx.run_manager.is_run_over():
			outcome = OUTCOME_WON if ctx.stats.outcome() == &"victory" else OUTCOME_LOST
			break
		if stop_after_dawns > 0 and tally.dawns >= stop_after_dawns:
			outcome = OUTCOME_STOPPED
			break
	recorder.append_final_state(ctx)
	var lines: PackedStringArray = recorder.lines()
	return {
		"outcome": outcome,
		"ticks": ctx.tick_count,
		"digest": recorder.digest(),
		"line_count": lines.size(),
		"nights_started": tally.nights,
		"lines": lines,
		"stats":
		{
			"nights_survived": ctx.stats.nights_survived(),
			"gold_earned": ctx.stats.gold_earned(),
			"buildings_lost": ctx.stats.buildings_lost(),
			"king_knockouts": ctx.stats.king_knockouts(),
			"outcome": ctx.stats.outcome(),
		},
	}


## Counts dawns and started nights from the run's events.
class Tally:
	extends RefCounted
	var dawns: int = 0
	var nights: int = 0

	func on_phase_changed(_old_phase: int, new_phase: int) -> void:
		if new_phase == RunManager.RunPhase.DAWN:
			dawns += 1

	func on_night_started(_night_number: int) -> void:
		nights += 1
