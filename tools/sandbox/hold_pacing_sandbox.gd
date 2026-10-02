class_name HoldPacingSandbox
extends Node
## A real-window sandbox for judging the hold-to-build pace (UAT G-01-58). It starts the prototype
## map with House tiers that cost 15, 30 and 50 coins, so the accelerating stream, the 3 s cap and
## the cap's coin rush can be felt (no shipped building costs more than 6 coins yet). The shipped
## map and building data are never changed: the repricing happens on a deep copy.
##
## Launch from Git Bash in the repo root:
##   bash tools/godot.sh --path . res://tools/sandbox/hold_pacing_sandbox.tscn
## tools/ is excluded from the export (export_presets.cfg exclude_filter), so this never ships.

const MAP_SCENE_PATH := "res://presentation/map/prototype_map.tscn"
const MAP_DATA_PATH := "res://data/maps/prototype_map.tres"
const HOUSE_ID: StringName = &"house"
const SANDBOX_HOUSE_COSTS: Array[int] = [15, 30, 50]
## Gold kept on top of every tier's cost, so the last build still leaves a few coins.
const GOLD_MARGIN: int = 5

var _map_root: MapRoot


func _ready() -> void:
	var config: MapConfig = _sandbox_map()
	if config == null:
		return
	var scene: PackedScene = load(MAP_SCENE_PATH)
	_map_root = scene.instantiate()
	_map_root.map_config = config
	add_child(_map_root)
	print(
		(
			(
				"hold pacing sandbox: House plots cost %s coins per tier; holds accelerate and stop at "
				+ "%s s, and the coins still unpaid then are rushed in at once"
			)
			% [SANDBOX_HOUSE_COSTS, _map_root.get_context().tuning.max_build_hold_seconds]
		)
	)


func get_map_root() -> MapRoot:
	return _map_root


## A deep copy of the shipped map (so the cached house.tres is never touched) with the House
## repriced and enough starting gold for every tier. Null, after a push_error, when the House does
## not have one tier per sandbox cost.
func _sandbox_map() -> MapConfig:
	var shipped: MapConfig = load(MAP_DATA_PATH)
	var config: MapConfig = shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	for building_def: BuildingDef in config.buildings:
		if building_def.id != HOUSE_ID:
			continue
		if building_def.tiers.size() != SANDBOX_HOUSE_COSTS.size():
			push_error(
				(
					"sandbox expects %d House tiers, the map has %d"
					% [SANDBOX_HOUSE_COSTS.size(), building_def.tiers.size()]
				)
			)
			return null
		var total: int = 0
		for index: int in range(SANDBOX_HOUSE_COSTS.size()):
			building_def.tiers[index].cost = SANDBOX_HOUSE_COSTS[index]
			total += SANDBOX_HOUSE_COSTS[index]
		config.starting_gold = total + GOLD_MARGIN
		return config
	push_error("sandbox: the map has no House building")
	return null
