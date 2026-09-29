class_name BuildHoldController
extends Node
## Hold-to-build input (D-05/D-06). Coins drip in while the action key is held near a spot.
## Hold state is ephemeral and lives only here: no gold moves and nothing is stored on a spot
## until the last coin lands, when one BuildIntent goes to the command gate.

signal focus_changed(spot_id: StringName)
signal hold_started(spot_id: StringName, cost: int)
signal hold_progress(spot_id: StringName, coins_paid: int, cost: int)
signal hold_cancelled(spot_id: StringName, coins_refunded: int)
signal hold_completed(spot_id: StringName)
## D-08 hook; also the future SFX hook.
signal hold_denied(spot_id: StringName, reason: StringName)

const ACTION: StringName = &"action_build"
const MIN_DRIP_INTERVAL: float = 0.001

var _ctx: RunContext
var _king: King
var _focused: StringName = &""
var _active: StringName = &""
var _cost: int = 0
var _coins_paid: int = 0
var _drip_timer: float = 0.0
var _was_pressed: bool = false


func bind_run(ctx: RunContext, map_root: MapRoot) -> void:
	_ctx = ctx
	_king = map_root.get_king()


func get_focused_spot() -> StringName:
	return _focused


func get_active_spot() -> StringName:
	return _active


func get_coins_paid() -> int:
	return _coins_paid


func is_holding() -> bool:
	return _active != &""


func _process(delta: float) -> void:
	if _ctx == null or _king == null:
		return
	var pressed: bool = Input.is_action_pressed(ACTION)
	if is_holding():
		_advance_hold(delta, pressed)
	else:
		_update_focus()
		var just_pressed: bool = (
			Input.is_action_just_pressed(ACTION) or (pressed and not _was_pressed)
		)
		if just_pressed and _focused != &"":
			_try_start_hold()
	_was_pressed = pressed


func _update_focus() -> void:
	var spot_id: StringName = _ctx.buildings.nearest_spot_in_range(
		_king.global_position, _ctx.tuning.interaction_radius
	)
	if spot_id != _focused:
		_focused = spot_id
		focus_changed.emit(spot_id)


## Focus is locked to the active spot for the whole hold; only release, leaving the interaction
## range or the day ending cancels it. A hold that finishes or cancels needs a fresh key press to
## start again, because starting is edge-triggered (the key must be released in between).
func _try_start_hold() -> void:
	var reason: StringName = _ctx.commands.validate_build(_focused)
	if reason != CommandProcessor.OK:
		hold_denied.emit(_focused, reason)
		return
	_active = _focused
	_cost = _ctx.buildings.next_action_cost(_active)
	_coins_paid = 0
	_drip_timer = 0.0
	hold_started.emit(_active, _cost)


## The day check runs every frame, ahead of any drip, so a coin never lands after building
## stops being allowed (plan 01-08's night transition relies on this).
func _advance_hold(delta: float, pressed: bool) -> void:
	if not pressed or not _active_spot_in_range() or not _ctx.run_manager.is_build_allowed():
		_cancel_hold()
		return
	var interval: float = maxf(_ctx.tuning.coin_drip_interval, MIN_DRIP_INTERVAL)
	_drip_timer += delta
	while _drip_timer >= interval and _coins_paid < _cost:
		_drip_timer -= interval
		_coins_paid += 1
		hold_progress.emit(_active, _coins_paid, _cost)
	if _coins_paid >= _cost:
		_finish_hold()


func _active_spot_in_range() -> bool:
	var spot: BuildSpotDef = _ctx.buildings.get_spot(_active)
	if spot == null:
		return false
	var flat_king: Vector2 = Vector2(_king.global_position.x, _king.global_position.z)
	var flat_spot: Vector2 = Vector2(spot.position.x, spot.position.z)
	return flat_king.distance_to(flat_spot) <= _ctx.tuning.interaction_radius


func _finish_hold() -> void:
	var spot_id: StringName = _active
	var coins: int = _coins_paid
	var result: StringName = _ctx.commands.submit(BuildIntent.new(spot_id))
	_reset_hold()
	if result == CommandProcessor.OK:
		hold_completed.emit(spot_id)
	else:
		hold_cancelled.emit(spot_id, coins)


## Nothing was deducted while dripping, so the refund is purely a reset (D-06).
func _cancel_hold() -> void:
	var spot_id: StringName = _active
	var coins: int = _coins_paid
	_reset_hold()
	hold_cancelled.emit(spot_id, coins)


func _reset_hold() -> void:
	_active = &""
	_cost = 0
	_coins_paid = 0
	_drip_timer = 0.0
