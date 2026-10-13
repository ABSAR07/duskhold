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
## The map whose ground bounds the squad command points; null falls back to the default extent.
var _map: MapConfig
## Intent script -> handler Callable; one return path for every intent.
var _handlers: Dictionary = {}


func _init(
	economy: Economy,
	buildings: BuildingSystem,
	run_manager: RunManager,
	events: SimEvents,
	king: KingState = null,
	squads: SquadSystem = null,
	map: MapConfig = null
) -> void:
	_economy = economy
	_buildings = buildings
	_run_manager = run_manager
	_events = events
	_king = king
	_squads = squads
	_map = map
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


## Check order: RUN_OVER, NO_SQUADS, UNKNOWN_SQUAD, UNKNOWN_VERB, BAD_POINT or TOO_MANY_POINTS,
## QUEUE_CLOSED. A rejection returns the reason, announces command_rejected and changes nothing
## (T-03-10, T-03-12). CommandProcessor is the only place
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
	var reason: StringName = _order_target_rejection(order)
	if reason != OK:
		return reason
	reason = _point_rejection(order)
	if reason != OK:
		return reason
	if order.queued and _every_queue_is_closed(order.squad_ids):
		return QUEUE_CLOSED
	return OK


## RUN_OVER, NO_SQUADS, UNKNOWN_SQUAD, UNKNOWN_VERB: who is ordered and what.
func _order_target_rejection(order: SquadOrderIntent) -> StringName:
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


## A move or attack-move needs exactly one point, a patrol one to MAX_PATROL_POINTS - 1 (the path
## also starts at the squad centroid); every point must lie on the ground, within the map's half
## extent on both axes. Follow, hold and rally carry none, and any given are ignored.
func _point_rejection(order: SquadOrderIntent) -> StringName:
	var count: int = order.points.size()
	if SquadOrders.is_walk(order.verb):
		if count != 1:
			return BAD_POINT
	elif order.verb == SquadOrder.VERB_PATROL:
		if count == 0:
			return BAD_POINT
		if count > SquadOrder.MAX_PATROL_POINTS - 1:
			return TOO_MANY_POINTS
	else:
		return OK
	var limit: int = _ground_limit_cm()
	for point: Vector2i in order.points:
		if point.x < -limit or point.x > limit or point.y < -limit or point.y > limit:
			return BAD_POINT
	return OK


## The half extent of the ground in whole centimetres. A bad extent (validate() reports one) bounds
## nothing: every point is refused.
func _ground_limit_cm() -> int:
	var extent: float = MapConfig.DEFAULT_GROUND_HALF_EXTENT
	if _map != null:
		extent = _map.ground_half_extent
	if not is_finite(extent) or extent <= 0.0:
		return -1
	return roundi(minf(extent, MapConfig.MAX_GROUND_HALF_EXTENT) * 100.0)


## True when every ordered squad's queue still ends in a hold, follow or patrol that has not run
## yet: nothing can be queued behind it (D-09). A mixed selection is not refused whole: the order
## goes to the squads that are open and SquadSystem.apply_order skips the closed ones.
func _every_queue_is_closed(squad_ids: Array[StringName]) -> bool:
	for squad_id: StringName in squad_ids:
		var pending: Array[Dictionary] = _squads.orders_of(squad_id)
		if pending.is_empty() or not SquadOrders.is_terminal(pending.back()["verb"] as StringName):
			return false
	return not squad_ids.is_empty()


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
