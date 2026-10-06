class_name FastForwardController
extends Node
## Toggle-to-fast-forward during a night (owner decision 2026-10-07, UAT G-02-14, replacing the
## 2026-10-06 hold of G-02-1, "the speed up should be at least 1.5x faster"). Press the
## fast_forward action once in NIGHT and the whole game runs at LoopTuning.fast_forward_scale
## through Engine.time_scale; press it again and it is back to real time. The engine then hands
## MapRoot a larger process delta and the King a larger physics delta, so the simulation runs more
## fixed steps per real second and the king, camera, projectiles and enemy puppets keep pace. A
## step itself is unchanged, so results are identical (DEV-05); RunContext.advance still clamps
## each frame to SimClock.MAX_ADVANCE_SECONDS.
##
## The switch is a latch (_switched_on), flipped on a press edge read in _process, never on the
## key level and never per input event: a trigger axis reports "pressed" on every motion event
## above its deadzone, so a per-event check would flip it several times in one pull. Godot also
## applies no hysteresis to an action deadzone, so a trigger hovering around halfway would cross
## it upward again and again; after a counted press the next one counts only once the action's raw
## strength has fallen below REARM_STRENGTH, a quarter of the trigger's travel (diagnosis probe A).
##
## Fast-forward acts only in NIGHT. By day there is nothing to wait for (no day timer, and the
## sprint is for riding), dawn is two seconds of payout coins, and the loss beat and the results
## screen must run in real seconds so the 1.2 s beat and the 0.6 s input grace mean what they say.
## A press outside NIGHT does nothing and arms nothing, and a key held from day into the night does
## not switch it on (only a fresh press does). The switch resets inside the simulation step that
## leaves NIGHT (dawn, victory or defeat), through phase_changed, so every night starts at real
## time. Because the switch is a latch it stays on when the window loses focus (Godot releases
## held actions on focus-out, which used to cancel the hold); the next press switches it off.
##
## This node is the only writer of Engine.time_scale (test_fast_forward_rules.gd scans for it), and
## it restores 1.0 whenever it leaves the tree: Play again reload, scene change, test teardown.

## Emitted when the applied scale changes: `active` is true while the game runs faster than real
## time. The HUD shows its Fast-forward label from this.
signal changed(active: bool, scale: float)

const ACTION: StringName = &"fast_forward"
const REAL_TIME: float = 1.0
## Input-device guard, not gameplay tuning (like the action deadzone in project.godot): after an
## accepted press, another press counts only once the action's raw strength has fallen below this.
const REARM_STRENGTH: float = 0.25

var _ctx: RunContext
var _scale: float = REAL_TIME
var _switched_on: bool = false
var _was_pressed: bool = false
var _rearmed: bool = true


## 1.0 unless the switch is on during NIGHT; then the tuning scale clamped to
## [1.0, LoopTuning.FAST_FORWARD_MAX_SCALE]. A tuning value that is not finite counts as 1.0, so
## bad data can never stall or race the game (T-02-29).
static func scale_for(phase: int, on: bool, tuning: LoopTuning) -> float:
	if phase != RunManager.RunPhase.NIGHT or not on:
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
	if _ctx == null:
		return
	var pressed: bool = Input.is_action_pressed(ACTION)
	var edge: bool = Input.is_action_just_pressed(ACTION) or (pressed and not _was_pressed)
	_was_pressed = pressed
	var counted: bool = _press_counts(edge, pressed)
	var phase: int = _ctx.run_manager.get_phase()
	if counted and phase == RunManager.RunPhase.NIGHT:
		_switched_on = not _switched_on
	_apply(phase)


func _exit_tree() -> void:
	if _ctx != null and _ctx.events.phase_changed.is_connected(_on_phase_changed):
		_ctx.events.phase_changed.disconnect(_on_phase_changed)
	_ctx = null
	_switched_on = false
	if _scale != REAL_TIME:
		_scale = REAL_TIME
		Engine.time_scale = REAL_TIME


## True for a press edge that counts: the guard must be armed, and it re-arms once the action is up
## and its raw strength (before the deadzone) has fallen below REARM_STRENGTH. A released key reads
## 0, so a key press, even a sub-frame tap, always counts and re-arms in the same frame.
func _press_counts(edge: bool, pressed: bool) -> bool:
	var counted: bool = edge and _rearmed
	if counted:
		_rearmed = false
	if not pressed and Input.get_action_raw_strength(ACTION) < REARM_STRENGTH:
		_rearmed = true
	return counted


## Runs inside the simulation step that changes the phase, so leaving the night clears the switch
## and drops the scale before the loss beat or the results grace starts counting real seconds, and
## the next night starts at real time.
func _on_phase_changed(_old_phase: int, new_phase: int) -> void:
	if new_phase != RunManager.RunPhase.NIGHT:
		_switched_on = false
	_apply(new_phase)


func _apply(phase: int) -> void:
	var wanted: float = scale_for(phase, _switched_on, _ctx.tuning)
	if wanted == _scale:
		return
	_scale = wanted
	Engine.time_scale = wanted
	changed.emit(wanted > REAL_TIME, wanted)
