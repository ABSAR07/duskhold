class_name FastForwardController
extends Node
## Hold-to-fast-forward during a night (owner decision 2026-10-06, UAT G-02-1: "the speed up should
## be at least 1.5x faster"). While the fast_forward action is held in NIGHT, the whole game runs
## at LoopTuning.fast_forward_scale through Engine.time_scale. The engine then hands MapRoot a
## larger process delta and the King a larger physics delta, so the simulation runs more fixed
## steps per real second and the king, camera, projectiles and enemy puppets keep pace. A step
## itself is unchanged, so results are identical (DEV-05); RunContext.advance still clamps each
## frame to SimClock.MAX_ADVANCE_SECONDS.
##
## Fast-forward acts only in NIGHT. By day there is nothing to wait for (no day timer, and the
## sprint is for riding), dawn is two seconds of payout coins, and the loss beat and the results
## screen must run in real seconds so the 1.2 s beat and the 0.6 s input grace mean what they say.
## Leaving the night (dawn, victory or defeat) drops the scale to 1.0 inside the same simulation
## step, through phase_changed. A key held across dawn into the next night resumes fast-forward
## when that night starts (it is a hold, not a toggle), and it also works while the king is down.
##
## This node is the only writer of Engine.time_scale (test_fast_forward_rules.gd scans for it), and
## it restores 1.0 whenever it leaves the tree: Play again reload, scene change, test teardown.

## Emitted when the applied scale changes: `active` is true while the game runs faster than real
## time. The HUD shows its Fast-forward label from this.
signal changed(active: bool, scale: float)

const ACTION: StringName = &"fast_forward"
const REAL_TIME: float = 1.0

var _ctx: RunContext
var _scale: float = REAL_TIME


## 1.0 unless the action is held during NIGHT; then the tuning scale clamped to
## [1.0, LoopTuning.FAST_FORWARD_MAX_SCALE]. A tuning value that is not finite counts as 1.0, so
## bad data can never stall or race the game (T-02-29).
static func scale_for(phase: int, held: bool, tuning: LoopTuning) -> float:
	if phase != RunManager.RunPhase.NIGHT or not held:
		return REAL_TIME
	var wanted: float = tuning.fast_forward_scale
	if is_nan(wanted) or is_inf(wanted):
		return REAL_TIME
	return clampf(wanted, REAL_TIME, LoopTuning.FAST_FORWARD_MAX_SCALE)


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	_ctx.events.phase_changed.connect(_on_phase_changed)


## True while the game runs faster than real time.
func is_active() -> bool:
	return _scale > REAL_TIME


## The scale this node last applied; 1.0 when not fast-forwarding.
func get_scale() -> float:
	return _scale


func _process(_delta: float) -> void:
	if _ctx != null:
		_apply(_ctx.run_manager.get_phase())


func _exit_tree() -> void:
	if _ctx != null and _ctx.events.phase_changed.is_connected(_on_phase_changed):
		_ctx.events.phase_changed.disconnect(_on_phase_changed)
	_ctx = null
	if _scale != REAL_TIME:
		_scale = REAL_TIME
		Engine.time_scale = REAL_TIME


## Runs inside the simulation step that changes the phase, so leaving the night drops the scale
## before the loss beat or the results grace starts counting real seconds.
func _on_phase_changed(_old_phase: int, new_phase: int) -> void:
	_apply(new_phase)


func _apply(phase: int) -> void:
	var wanted: float = scale_for(phase, Input.is_action_pressed(ACTION), _ctx.tuning)
	if wanted == _scale:
		return
	_scale = wanted
	Engine.time_scale = wanted
	changed.emit(wanted > REAL_TIME, wanted)
