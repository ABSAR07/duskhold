class_name MapRoot
extends Node3D
## Scene composition root. Builds the RunContext from the exported .tres data, binds every node
## in group "run_bound" that lives under this map, and feeds real frame time to the fixed-step
## simulation clock from _process (RunContext.advance clamps a stalled frame, DR-2).

@export var map_config: MapConfig
@export var loop_tuning: LoopTuning
## Non-zero fixes the run seed (tests, screenshots, replays); zero draws a fresh seed per run.
@export var fixed_run_seed: int = 0

var _ctx: RunContext
var _run_seed: int = 0

@onready var _king: King = $King
@onready var _build_hold: BuildHoldController = $BuildHold


func _ready() -> void:
	_run_seed = fixed_run_seed
	if _run_seed == 0:
		# Presentation draws the run seed from its own generator; the simulation never sees it.
		var seed_rng: RandomNumberGenerator = RandomNumberGenerator.new()
		seed_rng.randomize()
		_run_seed = seed_rng.randi()
	_ctx = RunContext.new(map_config, loop_tuning, _run_seed, _king.def)
	_king.global_position = map_config.king_spawn
	# Bind only this map's own subtree: a second MapRoot in the tree must not re-bind our nodes.
	for node: Node in get_tree().get_nodes_in_group(&"run_bound"):
		if node != self and is_ancestor_of(node):
			node.call(&"bind_run", _ctx, self)


func _process(delta: float) -> void:
	var king_position: Vector3 = _king.global_position
	_ctx.king.report_position(Vector2(king_position.x, king_position.z))
	_ctx.advance(delta)


func get_context() -> RunContext:
	return _ctx


func get_run_seed() -> int:
	return _run_seed


func get_king() -> King:
	return _king


func get_build_hold() -> BuildHoldController:
	return _build_hold
