class_name MapRoot
extends Node3D
## Scene composition root. Builds the RunContext from the exported .tres data, binds every node
## in group "run_bound" that lives under this map, and drives the simulation clock from _process.

@export var map_config: MapConfig
@export var loop_tuning: LoopTuning

var _ctx: RunContext

@onready var _king: King = $King
@onready var _build_hold: BuildHoldController = $BuildHold


func _ready() -> void:
	_ctx = RunContext.new(map_config, loop_tuning)
	_king.global_position = map_config.king_spawn
	# Bind only this map's own subtree: a second MapRoot in the tree must not re-bind our nodes.
	for node: Node in get_tree().get_nodes_in_group(&"run_bound"):
		if node != self and is_ancestor_of(node):
			node.call(&"bind_run", _ctx, self)


func _process(delta: float) -> void:
	_ctx.run_manager.tick(delta)


func get_context() -> RunContext:
	return _ctx


func get_king() -> King:
	return _king


func get_build_hold() -> BuildHoldController:
	return _build_hold
