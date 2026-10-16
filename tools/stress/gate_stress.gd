class_name GateStress
extends RefCounted
## The headless gate stress (ENMY-04, ROADMAP success criterion 2, D-09 and D-11). 300 enemies of
## the tools-only stress map march at one 4 m gate in an 80 m wall. The run passes only when every
## one of them crosses the finish line before T_max of simulation time and no living enemy, crossed
## or not, is still flagged stuck at the final tick. The same harness and pass rule serve the GUT
## test (tests/integration/test_gate_stress.gd) and the CLI (tools/stress/gate_stress_cli.gd).
##
## The harness never helps an enemy across. The king is parked far from the gate (a harness choice,
## like the bots' king modes) and arrivals that have already crossed the wall and reached the
## castle are removed (RESEARCH F5's sink) so the castle ring does not hold the queue; an enemy that
## has not crossed is never touched. tools/ is excluded from the export.

const STRESS_MAP := "res://tools/stress/stress_map.tres"
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
## The stress map's wall plot the finish line is read from.
const GATE_SPOT: StringName = &"gate_wall"
## Pass-rule threshold of this tools-only, export-excluded harness: an enemy has crossed when it
## stands this many metres past the wall line. Not a gameplay tunable, so exempt from the
## every-number-in-data rule (04-08 Flagged Assumptions, the precedent is test_balance_acceptance).
## Changing it changes what the gate proves, so it is an owner decision.
const FINISH_MARGIN_M: float = 2.0
## Pass-rule threshold of this tools-only harness: an enemy that has crossed and come within
## castle_radius plus this many metres of the castle leaves the run. Exempt from the
## every-number-in-data rule for the reason above.
const SINK_MARGIN_M: float = 4.0
## T_max of the pass rule in seconds of simulation (RESEARCH Pattern 10): a tools-only threshold,
## exempt from the every-number-in-data rule for the reason above. The CLI may override it inside
## its bounded --max-seconds range.
const DEFAULT_MAX_SECONDS: float = 60.0
## The attacker kind recorded for a sunk arrival.
const SINK_KIND: StringName = &"sink"
## Where the harness parks the king, far behind the castle and clear of every aggro range.
const KING_PARKING := Vector2(0.0, -60.0)
const WALL_DAMAGED_EVENT: String = "wall_damaged"
const TIER_GUARD: int = 16


## True when `map` has a GATE_SPOT plot that carries a wall run of at least two points.
static func has_gate(map: MapConfig) -> bool:
	var run: WallRunDef = _gate_run(map)
	return run != null and run.points.size() >= 2


## The z a crossing enemy must get below: the gate wall run's line z (read from its first point,
## the stress run is straight along one z) minus FINISH_MARGIN_M. NAN when the map has no gate.
static func finish_z(map: MapConfig) -> float:
	var run: WallRunDef = _gate_run(map)
	if run == null or run.points.size() < 2:
		return NAN
	return run.points[0].y - FINISH_MARGIN_M


## How close to the castle a crossed enemy must come to be removed: the map's castle_radius plus
## SINK_MARGIN_M.
static func sink_radius(map: MapConfig) -> float:
	return map.castle_radius + SINK_MARGIN_M


## The pass rule: every enemy crossed, none of the living enemies is flagged stuck at the final
## tick (crossed or not), and the run ended before the time limit.
static func passes(enemies: int, crossed: int, stuck_at_end: int, hit_limit: bool) -> bool:
	return enemies > 0 and crossed == enemies and stuck_at_end == 0 and not hit_limit


## Runs one gate stress on `map` with `run_seed` for at most `max_seconds` of simulation. Returns
## {enemies, crossed, stuck_at_end, max_cross_s, median_cross_s, longest_flag_s, wall_hits, ticks,
## digest, passed, hit_limit, reason}. Crossing times are seconds from the start of the night.
## `reason` is "" for a run that happened and a short word when none could (no gate, no night).
static func run(map: MapConfig, run_seed: int, max_seconds: float) -> Dictionary:
	var result: Dictionary = _blank_result()
	if not has_gate(map):
		result["reason"] = "no_gate_wall"
		return result
	var ctx: RunContext = RunContext.new(map, load(TUNING_PATH) as LoopTuning, run_seed)
	var recorder: SimRecorder = SimRecorder.attach(ctx)
	var guard: int = 0
	while guard < TIER_GUARD and ctx.buildings.apply_next_tier(GATE_SPOT) != null:
		guard += 1
	if ctx.commands.submit(StartNightIntent.new()) != CommandProcessor.OK:
		result["reason"] = "night_did_not_start"
		return result
	var crossed_at: Dictionary = _march(ctx, map, SimClock.ticks(max_seconds), result)
	_report(ctx, recorder, crossed_at, result)
	result["passed"] = passes(
		result["enemies"], result["crossed"], result["stuck_at_end"], result["hit_limit"]
	)
	return result


## Steps the night until every enemy has crossed, the phase ends or the tick limit runs out.
## Returns {enemy id: night tick of its crossing}. Sets result["hit_limit"] and result["enemies"].
static func _march(
	ctx: RunContext, map: MapConfig, max_ticks: int, result: Dictionary
) -> Dictionary:
	var line_z: float = finish_z(map)
	var sink: float = sink_radius(map)
	var castle: Vector2 = ctx.castle.get_position()
	var enemies: EnemySystem = ctx.night.get_enemies()
	var total: int = ctx.night.total_count()
	var crossed_at: Dictionary = {}
	var start_tick: int = ctx.tick_count
	result["enemies"] = total
	result["hit_limit"] = true
	for _step: int in range(max_ticks):
		ctx.king.report_position(KING_PARKING)
		ctx.step()
		var night_tick: int = ctx.tick_count - start_tick
		for id: int in enemies.ids():
			if not enemies.is_alive(id):
				continue
			var position: Vector2 = enemies.position_of(id)
			if not crossed_at.has(id) and position.y < line_z:
				crossed_at[id] = night_tick
			if crossed_at.has(id) and position.distance_to(castle) <= sink:
				enemies.damage(id, enemies.health_of(id), SINK_KIND)
		if crossed_at.size() >= total and ctx.night.spawned_count() >= total:
			result["hit_limit"] = false
			break
		if ctx.run_manager.get_phase() != RunManager.RunPhase.NIGHT:
			result["hit_limit"] = false
			break
	return crossed_at


## Fills the counts, the times and the digest of `result` from the finished run.
static func _report(
	ctx: RunContext, recorder: SimRecorder, crossed_at: Dictionary, result: Dictionary
) -> void:
	var enemies: EnemySystem = ctx.night.get_enemies()
	var pathing: Pathing = ctx.night.get_pathing()
	var stuck: int = 0
	for id: int in enemies.ids():
		if enemies.is_alive(id) and pathing.stuck().is_stuck(id):
			stuck += 1
	var ticks: Array[int] = []
	for id: int in crossed_at:
		ticks.append(crossed_at[id])
	ticks.sort()
	result["crossed"] = crossed_at.size()
	result["stuck_at_end"] = stuck
	result["max_cross_s"] = _seconds(ticks[ticks.size() - 1]) if not ticks.is_empty() else 0.0
	result["median_cross_s"] = _median_seconds(ticks)
	result["longest_flag_s"] = _seconds(pathing.stuck().longest_streak_ticks())
	result["wall_hits"] = _count_events(recorder.lines(), WALL_DAMAGED_EVENT)
	result["ticks"] = ctx.tick_count
	recorder.append_final_state(ctx)
	result["digest"] = recorder.digest()


static func _blank_result() -> Dictionary:
	return {
		"enemies": 0,
		"crossed": 0,
		"stuck_at_end": 0,
		"max_cross_s": 0.0,
		"median_cross_s": 0.0,
		"longest_flag_s": 0.0,
		"wall_hits": 0,
		"ticks": 0,
		"digest": "",
		"passed": false,
		"hit_limit": false,
		"reason": "",
	}


## The run of the GATE_SPOT plot, or null.
static func _gate_run(map: MapConfig) -> WallRunDef:
	for spot: BuildSpotDef in map.spots:
		if spot != null and spot.id == GATE_SPOT:
			return spot.wall_run
	return null


static func _seconds(ticks: int) -> float:
	return float(ticks) * SimClock.STEP


## The median of ascending `ticks` in seconds; 0.0 for none. An even count averages the two
## middle values.
static func _median_seconds(ticks: Array[int]) -> float:
	if ticks.is_empty():
		return 0.0
	@warning_ignore("integer_division")
	var middle: int = ticks.size() / 2
	if ticks.size() % 2 == 1:
		return _seconds(ticks[middle])
	return (_seconds(ticks[middle - 1]) + _seconds(ticks[middle])) / 2.0


static func _count_events(lines: PackedStringArray, event_name: String) -> int:
	var total: int = 0
	for line: String in lines:
		var parts: PackedStringArray = line.split(" ")
		if parts.size() > 1 and parts[1] == event_name:
			total += 1
	return total
