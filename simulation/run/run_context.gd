class_name RunContext
extends RefCounted
## Composition root of the headless simulation. Constructible and testable with no scene tree.

var map: MapConfig
var tuning: LoopTuning
var events: SimEvents
var economy: Economy
var buildings: BuildingSystem
var run_manager: RunManager
var commands: CommandProcessor


func _init(map_config: MapConfig, loop_tuning: LoopTuning) -> void:
	map = map_config
	for error: String in map_config.validate():
		push_error("MapConfig '%s': %s" % [map_config.id, error])
	tuning = loop_tuning
	events = SimEvents.new()
	economy = Economy.new(events, map_config.starting_gold)
	buildings = BuildingSystem.new(map_config, events)
	run_manager = RunManager.new(events)
	commands = CommandProcessor.new(economy, buildings, run_manager, events)
