class_name CommandProcessor
extends RefCounted
## The single validated mutation gate. Input never touches Economy or BuildingSystem directly.
## Rejections are returned as reason values (never push_error) and announced on SimEvents.

const OK := &"ok"
const NOT_DAY := &"not_day"
const UNKNOWN_SPOT := &"unknown_spot"
const MAX_TIER := &"max_tier"
const CANNOT_AFFORD := &"cannot_afford"
const UNKNOWN_INTENT := &"unknown_intent"

var _economy: Economy
var _buildings: BuildingSystem
var _run_manager: RunManager
var _events: SimEvents


func _init(
	economy: Economy, buildings: BuildingSystem, run_manager: RunManager, events: SimEvents
) -> void:
	_economy = economy
	_buildings = buildings
	_run_manager = run_manager
	_events = events


## Read-only check of whether a build or upgrade on `spot_id` would be accepted right now.
## Check order: NOT_DAY, UNKNOWN_SPOT, MAX_TIER, CANNOT_AFFORD.
func validate_build(spot_id: StringName) -> StringName:
	if not _run_manager.is_build_allowed():
		return NOT_DAY
	if _buildings.get_spot(spot_id) == null:
		return UNKNOWN_SPOT
	var cost: int = _buildings.next_action_cost(spot_id)
	if cost < 0:
		return MAX_TIER
	if not _economy.can_afford(cost):
		return CANNOT_AFFORD
	return OK


## Applies an intent. Returns OK or the rejection reason; nothing changes on a rejection.
func submit(intent: RefCounted) -> StringName:
	if intent is BuildIntent:
		return _submit_build(intent as BuildIntent)
	if intent is StartNightIntent:
		return _submit_start_night()
	return UNKNOWN_INTENT


func _submit_start_night() -> StringName:
	if not _run_manager.is_build_allowed() or not _run_manager.start_night():
		_events.command_rejected.emit(&"start_night", &"", NOT_DAY)
		return NOT_DAY
	return OK


func _submit_build(intent: BuildIntent) -> StringName:
	var spot_id: StringName = intent.spot_id
	var reason: StringName = validate_build(spot_id)
	if reason == OK and not _economy.try_spend(_buildings.next_action_cost(spot_id)):
		reason = CANNOT_AFFORD
	if reason != OK:
		_events.command_rejected.emit(&"build", spot_id, reason)
		return reason
	_buildings.apply_next_tier(spot_id)
	return OK
