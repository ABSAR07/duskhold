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
const RUN_OVER := &"run_over"
const NO_ABILITY := &"no_ability"
const KING_DOWN := &"king_down"
const ABILITY_COOLING := &"ability_cooling"
const NO_SQUADS := &"no_squads"
const UNKNOWN_SQUAD := &"unknown_squad"
const UNKNOWN_VERB := &"unknown_verb"
const BAD_POINT := &"bad_point"
const TOO_MANY_POINTS := &"too_many_points"
const QUEUE_CLOSED := &"queue_closed"

var _economy: Economy
var _buildings: BuildingSystem
var _run_manager: RunManager
var _events: SimEvents
var _king: KingState
var _squads: SquadSystem
## Intent script -> handler Callable; one return path for every intent.
var _handlers: Dictionary = {}


func _init(
	economy: Economy,
	buildings: BuildingSystem,
	run_manager: RunManager,
	events: SimEvents,
	king: KingState = null,
	squads: SquadSystem = null
) -> void:
	_economy = economy
	_buildings = buildings
	_run_manager = run_manager
	_events = events
	_king = king
	_squads = squads
	_handlers = {
		BuildIntent: _submit_build,
		StartNightIntent: _submit_start_night,
		ActivateAbilityIntent: _submit_ability,
		SquadOrderIntent: _submit_squad_order,
	}


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


## Applies an intent. Returns OK or the rejection reason; nothing changes on a rejection. The
## handler is looked up by the intent's script, so an unknown or null intent is UNKNOWN_INTENT.
func submit(intent: RefCounted) -> StringName:
	var result: StringName = UNKNOWN_INTENT
	if intent != null:
		var handler: Callable = _handlers.get(intent.get_script(), Callable())
		if handler.is_valid():
			result = handler.call(intent)
	return result


## Check order: RUN_OVER, NO_ABILITY, KING_DOWN, ABILITY_COOLING. A rejection returns the reason,
## announces command_rejected and changes nothing (T-03-07).
func _submit_ability(_intent: RefCounted) -> StringName:
	var reason: StringName = _ability_rejection()
	if reason != OK:
		_events.command_rejected.emit(&"ability", &"", reason)
		return reason
	_king.activate_ability()
	return OK


func _ability_rejection() -> StringName:
	if _run_manager.is_run_over():
		return RUN_OVER
	if _king == null or not _king.has_ability():
		return NO_ABILITY
	if _king.is_down():
		return KING_DOWN
	if _king.ability_ticks_left() > 0:
		return ABILITY_COOLING
	return OK


## Check order: RUN_OVER, NO_SQUADS, UNKNOWN_SQUAD, UNKNOWN_VERB. A rejection returns the reason,
## announces command_rejected and changes nothing (T-03-10). CommandProcessor is the only place
## centimetres become metres: one IEEE division per component. The order is applied at once, between
## two steps, so it reads the state the last completed step left (it carries no tick).
func _submit_squad_order(intent: RefCounted) -> StringName:
	var order: SquadOrderIntent = intent as SquadOrderIntent
	var reason: StringName = _squad_order_rejection(order)
	if reason != OK:
		var first: StringName = order.squad_ids[0] if not order.squad_ids.is_empty() else &""
		_events.command_rejected.emit(&"squad_order", first, reason)
		return reason
	var metres: Array[Vector2] = []
	for point: Vector2i in order.points:
		metres.append(Vector2(point) / 100.0)
	var king_at: Vector2 = _king.get_position() if _king != null else Vector2.ZERO
	_squads.apply_order(order.squad_ids, order.verb, metres, order.queued, king_at)
	return OK


func _squad_order_rejection(order: SquadOrderIntent) -> StringName:
	if _run_manager.is_run_over():
		return RUN_OVER
	if order.squad_ids.is_empty():
		return NO_SQUADS
	var known: Array[StringName] = _squads.squad_ids() if _squads != null else []
	for squad_id: StringName in order.squad_ids:
		if not known.has(squad_id):
			return UNKNOWN_SQUAD
	if not SquadOrders.is_supported(order.verb):
		return UNKNOWN_VERB
	return OK


func _submit_start_night(_intent: RefCounted) -> StringName:
	if not _run_manager.is_build_allowed() or not _run_manager.start_night():
		_events.command_rejected.emit(&"start_night", &"", NOT_DAY)
		return NOT_DAY
	return OK


func _submit_build(intent: RefCounted) -> StringName:
	var spot_id: StringName = (intent as BuildIntent).spot_id
	var reason: StringName = validate_build(spot_id)
	if reason == OK and not _economy.try_spend(_buildings.next_action_cost(spot_id)):
		reason = CANNOT_AFFORD
	if reason != OK:
		_events.command_rejected.emit(&"build", spot_id, reason)
		return reason
	_buildings.apply_next_tier(spot_id)
	return OK
