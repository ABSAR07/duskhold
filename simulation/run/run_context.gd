class_name RunContext
extends RefCounted
## Composition root of the headless simulation. Constructible and testable with no scene tree.
## The simulation advances only through `step()`, exactly SimClock.STEP seconds per call (DR-2).
## The game reaches it through `advance(real_delta)`; headless tools call `step()` directly.

const DEFAULT_KING_PATH := "res://data/king/king.tres"

var map: MapConfig
var tuning: LoopTuning
var events: SimEvents
var economy: Economy
var buildings: BuildingSystem
var walls: WallSystem
var squads: SquadSystem
var castle: CastleState
var king: KingState
var night: NightSim
var run_manager: RunManager
var commands: CommandProcessor
var stats: RunStats
## The one stat-modifier stack (META-08, D-15): every bonus goes through it and every modifiable
## stat is read through it.
var stat_stack: StatStack
var run_seed: int = 1
## Simulation steps run so far.
var tick_count: int = 0

var _accumulator: float = 0.0


func _init(
	map_config: MapConfig, loop_tuning: LoopTuning, seed_value: int = 1, king_def: KingDef = null
) -> void:
	map = map_config
	for error: String in map_config.validate():
		push_error("MapConfig '%s': %s" % [map_config.id, error])
	tuning = loop_tuning
	run_seed = seed_value
	var def: KingDef = king_def if king_def != null else load(DEFAULT_KING_PATH) as KingDef
	events = SimEvents.new()
	stat_stack = StatStack.new()
	stats = RunStats.new(events)
	economy = Economy.new(events, map_config.starting_gold)
	buildings = BuildingSystem.new(map_config, events)
	walls = WallSystem.new(map_config, buildings, events)
	castle = CastleState.new(map_config, events)
	king = KingState.new(
		def, Vector2(map_config.king_spawn.x, map_config.king_spawn.z), events, tuning
	)
	squads = SquadSystem.new(map_config, buildings, events)
	night = NightSim.new(
		map_config, events, king, run_seed, castle, buildings, squads, walls, stat_stack
	)
	run_manager = RunManager.new(
		events, economy, buildings, tuning, night, king, castle, map_config.base_dawn_income, squads
	)
	commands = CommandProcessor.new(
		economy, buildings, run_manager, events, king, squads, map_config
	)


## Runs one fixed simulation step: the king's timers, then the night while it is NIGHT or the army
## and the king's slam alone in every other phase, then the loop clock. A castle that fell during
## the night step ends the run before the clock ticks, so the loss beats a win the same step would
## have made (LOOP-06, DR-8). Once the run is over a step does nothing at all.
func step() -> void:
	if run_manager.is_run_over():
		return
	king.tick_timers()
	if run_manager.get_phase() == RunManager.RunPhase.NIGHT:
		night.step(tick_count)
		if castle.is_destroyed():
			run_manager.end_run_in_defeat()
	else:
		night.step_day(tick_count)
	run_manager.tick(SimClock.STEP)
	tick_count += 1


## Feeds real elapsed seconds (clamped to SimClock.MAX_ADVANCE_SECONDS) into the accumulator and
## runs as many whole steps as fit, so any split of a second into frames runs the same steps.
## Returns the number of steps run.
func advance(real_delta: float) -> int:
	_accumulator += clampf(real_delta, 0.0, SimClock.MAX_ADVANCE_SECONDS)
	var steps: int = 0
	while _accumulator >= SimClock.STEP - SimClock.ACCUMULATOR_EPSILON:
		_accumulator -= SimClock.STEP
		step()
		steps += 1
	return steps


## How far between the last step and the next one the clock is, in [0, 1). Puppets interpolate
## from their previous to their current simulation position by this much.
func alpha() -> float:
	return clampf(_accumulator / SimClock.STEP, 0.0, 0.999999)


## Number of friendly units alive.
func get_unit_count() -> int:
	return squads.get_units().count()


## Number of enemies alive.
func get_enemy_count() -> int:
	return night.enemy_count()
