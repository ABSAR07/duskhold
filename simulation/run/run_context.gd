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
var castle: CastleState
var king: KingState
var night: NightSim
var run_manager: RunManager
var commands: CommandProcessor
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
	economy = Economy.new(events, map_config.starting_gold)
	buildings = BuildingSystem.new(map_config, events)
	castle = CastleState.new(map_config, events)
	king = KingState.new(
		def, Vector2(map_config.king_spawn.x, map_config.king_spawn.z), events, tuning
	)
	night = NightSim.new(map_config, events, king, run_seed, castle, buildings)
	run_manager = RunManager.new(events, economy, buildings, tuning, night, king, castle)
	commands = CommandProcessor.new(economy, buildings, run_manager, events)


## Runs one fixed simulation step: the night (only while it is NIGHT), then the loop clock.
func step() -> void:
	if run_manager.get_phase() == RunManager.RunPhase.NIGHT:
		night.step(tick_count)
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


## Number of friendly units alive. Phase 1 spawns none; later phases read their manager here.
func get_unit_count() -> int:
	return 0


## Number of enemies alive.
func get_enemy_count() -> int:
	return night.enemy_count()
