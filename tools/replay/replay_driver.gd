class_name ReplayDriver
extends RefCounted
## Runs one scripted, seeded playthrough headlessly and returns its outcome and event digest
## (DEV-05). Every run is bounded by `max_ticks` (threat T-02-02) and never edits the map or tuning
## it is given (DR-12). A run that ends stops at its terminal step with the outcome `won` or `lost`
## and the run's stats, plus one metrics entry per started night.
## tools/ is excluded from the export.

## Outcome when the run reached `stop_after_dawns` dawns.
const OUTCOME_STOPPED := &"stopped"
## Outcome when `max_ticks` ran out first.
const OUTCOME_TIMEOUT := &"timeout"
## Outcome when the last night was cleared (RunManager reached WON).
const OUTCOME_WON := &"won"
## Outcome when the castle fell (RunManager reached LOST).
const OUTCOME_LOST := &"lost"


## Result: {outcome, ticks, digest, line_count, nights_started, lines, stats, per_night}. `stats`
## holds the RunStats values {nights_survived, gold_earned, buildings_lost, king_knockouts, outcome}
## and per_night has one Dictionary per started night: {night, enemies, kills_king, kills_towers,
## buildings_lost, knockouts, castle_hp_end, duration_s, gold_at_dawn, end}. `end` is "dawn", "won"
## or "lost" for a night that finished and "" for one the tick bound cut short; `gold_at_dawn` is
## the gold after the dawn payout, or the gold when the night ended without one.
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
	var tally: Tally = Tally.new(ctx)
	var outcome: StringName = OUTCOME_TIMEOUT
	for _tick: int in range(maxi(max_ticks, 0)):
		bot.think(ctx)
		if ctx.run_manager.get_phase() == RunManager.RunPhase.NIGHT:
			tally.night_steps += 1
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
		"per_night": tally.per_night,
	}


## Counts dawns and started nights and keeps the per-night metrics, all from the run's events. A
## read-only listener: it never changes the simulation, so the digest does not depend on it.
class Tally:
	extends RefCounted
	var dawns: int = 0
	var nights: int = 0
	## Steps run in the current night, counted by the driver before each step.
	var night_steps: int = 0
	var per_night: Array = []

	var _ctx: RunContext
	var _open: Dictionary = {}

	func _init(ctx: RunContext) -> void:
		_ctx = ctx
		var events: SimEvents = ctx.events
		events.phase_changed.connect(on_phase_changed)
		events.night_started.connect(on_night_started)
		events.enemy_spawned.connect(_on_enemy_spawned)
		events.enemy_died.connect(_on_enemy_died)
		events.building_destroyed.connect(_on_building_destroyed)
		events.king_downed.connect(_on_king_downed)
		events.dawn_payout.connect(_on_dawn_payout)

	func on_phase_changed(old_phase: int, new_phase: int) -> void:
		if new_phase == RunManager.RunPhase.DAWN:
			dawns += 1
		if old_phase == RunManager.RunPhase.NIGHT and not _open.is_empty():
			_close_night(new_phase)

	func on_night_started(night_number: int) -> void:
		nights += 1
		night_steps = 0
		_open = {
			"night": night_number,
			"enemies": 0,
			"kills_king": 0,
			"kills_towers": 0,
			"buildings_lost": 0,
			"knockouts": 0,
			"castle_hp_end": 0,
			"duration_s": 0.0,
			"gold_at_dawn": 0,
			"end": "",
		}
		per_night.append(_open)

	func _close_night(new_phase: int) -> void:
		_open["castle_hp_end"] = _ctx.castle.get_health()
		_open["duration_s"] = float(night_steps) * SimClock.STEP
		_open["gold_at_dawn"] = _ctx.economy.get_gold()
		if new_phase == RunManager.RunPhase.DAWN:
			_open["end"] = "dawn"
		elif new_phase == RunManager.RunPhase.WON:
			_open["end"] = "won"
		else:
			_open["end"] = "lost"
		_open = {}

	func _on_enemy_spawned(_enemy_id: int, _def_id: StringName, _pos: Vector2) -> void:
		_bump("enemies")

	func _on_enemy_died(
		_enemy_id: int, _def_id: StringName, _pos: Vector2, killer_kind: StringName
	) -> void:
		if killer_kind == PendingHits.KIND_KING:
			_bump("kills_king")
		elif killer_kind == PendingHits.KIND_BUILDING:
			_bump("kills_towers")

	func _on_building_destroyed(_spot_id: StringName, _building_id: StringName, _tier: int) -> void:
		_bump("buildings_lost")

	func _on_king_downed(_respawn_ticks: int, _knockout_number: int) -> void:
		_bump("knockouts")

	## The dawn payout arrives after the night closed, so it updates the night that just ended.
	func _on_dawn_payout(_total: int, _per_spot: Dictionary) -> void:
		if not per_night.is_empty():
			(per_night[per_night.size() - 1] as Dictionary)["gold_at_dawn"] = (
				_ctx.economy.get_gold()
			)

	func _bump(key: String) -> void:
		if not _open.is_empty():
			_open[key] = int(_open[key]) + 1
