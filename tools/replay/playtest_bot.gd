class_name PlaytestBot
extends RefCounted
## A scripted player for headless runs (D-18). It touches the simulation only through intents and
## the king-position input (DR-10) and uses no random function, so a run with a given bot, map and
## seed is reproducible. Bots build without riding to plots: the balance report says so, because
## the real player pays for the ride in time. Squad orders (`scripted_orders`, `night_orders`) and
## the slam (`slam_min_enemies`) go through the same intents a player's keys and clicks produce.
## tools/ is excluded from the export.

const KING_IDLE_AT_CASTLE := &"idle_at_castle"
const KING_HOLD_POINT := &"hold_point"
## Sprint toward the enemy nearest the castle; wait at the castle front when none is up.
const KING_DEFEND_NEAREST_THREAT := &"defend_nearest_threat"
## A defending king stops this share of his attack range away from his target, so he does not
## stand on top of it.
const STOP_SHARE_OF_ATTACK_RANGE: float = 0.5

## Spots to build in order. A repeated spot id means an upgrade.
var build_order: Array[StringName] = []
## Where the bot keeps the king: KING_IDLE_AT_CASTLE (the map's king spawn), KING_HOLD_POINT or
## KING_DEFEND_NEAREST_THREAT.
var king_mode: StringName = KING_IDLE_AT_CASTLE
## The XZ point the king walks to in KING_HOLD_POINT mode.
var hold_point: Vector2 = Vector2.ZERO
## Whether the bot starts every night as soon as the day allows.
var start_nights: bool = true
## Whether, each day, the bot moves the tower plots on the roads the coming night uses to the front
## of its remaining tower entries (the telegraph icons tell a player the same thing).
var prefer_telegraphed_towers: bool = false
## Squad orders given on fixed ticks: {"tick": int, "squads": Array[StringName], "verb": StringName,
## "points": Array[Vector2i] (centimetres), "queued": bool}. "points" and "queued" may be left out.
## An order for a squad that does not exist yet is simply refused by the command gate.
var scripted_orders: Array[Dictionary] = []
## Squad orders given once at the start of every night: {"squads": Array[StringName], "verb":
## StringName}, plus the optional "points" and "queued" of scripted_orders.
var night_orders: Array[Dictionary] = []
## The king slams when the slam is ready and at least this many living enemies are within its
## radius. 0 never slams.
var slam_min_enemies: int = 0

var _cursor: int = 0
## Entries deferred because a requirement locked them (castle_tier, needs_spot), in the order they
## were deferred; retried at the start of every build think.
var _pending: Array[StringName] = []
## The goal fields the king walks round walls on, a cache of the bot's own so it never spends the
## squads' build budget (ENMY-04).
var _king_goals: GoalFieldCache
var _ordered_for_night: int = -1
var _night_orders_given_for: int = -1


## One decision per simulation tick, before `ctx.step()`.
func think(ctx: RunContext) -> void:
	if ctx.run_manager.get_phase() == RunManager.RunPhase.DAY:
		if prefer_telegraphed_towers:
			_prioritise_telegraphed_towers(ctx)
		_build(ctx)
		if start_nights:
			ctx.commands.submit(StartNightIntent.new())
	_give_orders(ctx)
	_slam(ctx)
	_move_king(ctx)


## Submits the scripted orders whose tick is this one and, on the first think of each night, the
## night orders. Rejections are returned values and are ignored: an order for a squad that has not
## been raised yet is simply refused.
func _give_orders(ctx: RunContext) -> void:
	for order: Dictionary in scripted_orders:
		if int(order.get("tick", -1)) == ctx.tick_count:
			_submit_order(ctx, order)
	if ctx.run_manager.get_phase() != RunManager.RunPhase.NIGHT:
		return
	var night_number: int = ctx.run_manager.get_night_number()
	if _night_orders_given_for == night_number:
		return
	_night_orders_given_for = night_number
	for order: Dictionary in night_orders:
		_submit_order(ctx, order)


func _submit_order(ctx: RunContext, order: Dictionary) -> void:
	var squads: Array[StringName] = []
	squads.assign(order.get("squads", []))
	var points: Array[Vector2i] = []
	points.assign(order.get("points", []))
	var verb: StringName = order.get("verb", &"")
	ctx.commands.submit(
		SquadOrderIntent.new(squads, verb, points, bool(order.get("queued", false)))
	)


## Uses the king's slam when it is ready and enough enemies stand inside its radius.
func _slam(ctx: RunContext) -> void:
	if slam_min_enemies <= 0 or not ctx.king.has_ability() or ctx.king.is_down():
		return
	if ctx.king.ability_ticks_left() > 0:
		return
	var enemies: EnemySystem = ctx.night.get_enemies()
	var reach: float = ctx.king.get_weapon().slam_radius
	var here: Vector2 = ctx.king.get_position()
	var in_reach: int = 0
	for id: int in enemies.ids():
		if (
			enemies.is_alive(id)
			and here.distance_squared_to(enemies.position_of(id)) <= reach * reach
		):
			in_reach += 1
	if in_reach >= slam_min_enemies:
		ctx.commands.submit(ActivateAbilityIntent.new())


## Builds the next entries of build_order while they are accepted. An entry that can never be
## built (max tier, unknown spot) is skipped; an unaffordable one waits for a later think. An entry
## locked behind the castle or another plot (castle_tier, needs_spot) is deferred, not waited for:
## it moves to the pending list and the later entries are still bought, so a gate never stalls the
## whole order (Pitfall 1). Every think retries the pending entries first, in their original order.
func _build(ctx: RunContext) -> void:
	_retry_pending(ctx)
	while _cursor < build_order.size():
		var spot_id: StringName = build_order[_cursor]
		var reason: StringName = ctx.commands.validate_build(spot_id)
		if reason == CommandProcessor.OK:
			ctx.commands.submit(BuildIntent.new(spot_id))
			_cursor += 1
		elif reason == CommandProcessor.MAX_TIER or reason == CommandProcessor.UNKNOWN_SPOT:
			_cursor += 1
		elif reason == CommandProcessor.CASTLE_TIER or reason == CommandProcessor.NEEDS_SPOT:
			_pending.append(spot_id)
			_cursor += 1
		else:
			return


## Retries the deferred entries in the order they were deferred: one that is accepted now is
## submitted and dropped, one that can never be built (max tier, unknown spot) is dropped, and one
## that is still locked or unaffordable stays for the next think.
func _retry_pending(ctx: RunContext) -> void:
	var still_pending: Array[StringName] = []
	for spot_id: StringName in _pending:
		var reason: StringName = ctx.commands.validate_build(spot_id)
		if reason == CommandProcessor.OK:
			ctx.commands.submit(BuildIntent.new(spot_id))
		elif reason != CommandProcessor.MAX_TIER and reason != CommandProcessor.UNKNOWN_SPOT:
			still_pending.append(spot_id)
	_pending = still_pending


## Once per day: among the not yet built entries, the first entry of each unbuilt tower plot keeps
## its place in the order but the plots are refilled so those on a road the coming night uses come
## first. The relative order inside each of the two groups is kept. Upgrade entries stay where they
## are: moving them would only delay the first towers on the roads the telegraph has not shown yet.
func _prioritise_telegraphed_towers(ctx: RunContext) -> void:
	var coming_night: int = ctx.run_manager.get_night_number() + 1
	if _ordered_for_night == coming_night:
		return
	_ordered_for_night = coming_night
	var roads: Dictionary = WaveSchedule.preview_counts(ctx.map, coming_night)
	var slots: Array[int] = []
	var on_road: Array[StringName] = []
	var elsewhere: Array[StringName] = []
	var seen: Dictionary = {}
	for index: int in range(_cursor, build_order.size()):
		var spot_id: StringName = build_order[index]
		if seen.has(spot_id):
			continue
		seen[spot_id] = true
		if not _is_tower_plot(ctx, spot_id) or ctx.buildings.current_tier(spot_id) > 0:
			continue
		slots.append(index)
		if roads.has(_road_of(ctx, spot_id)):
			on_road.append(spot_id)
		else:
			elsewhere.append(spot_id)
	var ordered: Array[StringName] = on_road + elsewhere
	for slot: int in range(slots.size()):
		build_order[slots[slot]] = ordered[slot]


## True when the spot takes a building whose first tier shoots.
func _is_tower_plot(ctx: RunContext, spot_id: StringName) -> bool:
	var def: BuildingDef = ctx.buildings.get_building_def_for_spot(spot_id)
	if def == null or def.tier_def(1) == null:
		return false
	return def.tier_def(1).attack_damage > 0


## The spawn point whose direction from the castle is closest to the plot's: the road the plot
## guards. &"" when the map has no spawn points.
func _road_of(ctx: RunContext, spot_id: StringName) -> StringName:
	var castle: Vector2 = ctx.castle.get_position()
	var plot_position: Vector3 = ctx.buildings.get_spot(spot_id).position
	var plot_direction: Vector2 = (Vector2(plot_position.x, plot_position.z) - castle).normalized()
	var best: StringName = &""
	var best_alignment: float = -INF
	for spawn_point: SpawnPointDef in ctx.map.spawn_points:
		var spawn_at: Vector2 = Vector2(spawn_point.position.x, spawn_point.position.z)
		var alignment: float = plot_direction.dot((spawn_at - castle).normalized())
		if alignment > best_alignment:
			best_alignment = alignment
			best = spawn_point.id
	return best


## Walks the bot-owned king position toward the mode's goal. The idle and hold modes walk at the
## king's walking speed; the defending king sprints and stops once his target is in reach.
func _move_king(ctx: RunContext) -> void:
	var def: KingDef = ctx.king.get_def()
	var here: Vector2 = ctx.king.get_position()
	var goal: Vector2 = Vector2(ctx.map.king_spawn.x, ctx.map.king_spawn.z)
	var pace: float = def.walk_speed * SimClock.STEP
	if king_mode == KING_HOLD_POINT:
		goal = hold_point
	elif king_mode == KING_DEFEND_NEAREST_THREAT:
		pace = def.walk_speed * def.sprint_multiplier * SimClock.STEP
		var threat: int = _nearest_threat(ctx)
		if threat >= 0:
			goal = ctx.night.get_enemies().position_of(threat)
			if (
				here.distance_to(goal)
				<= ctx.king.get_weapon().attack_range * STOP_SHARE_OF_ATTACK_RANGE
			):
				return
	var pathing: Pathing = ctx.night.get_pathing()
	var stepped: Vector2 = here.move_toward(goal, pace)
	if pathing.has_intact_walls() and pathing.first_blocking(here, goal, def.body_radius) >= 0:
		if _king_goals == null:
			_king_goals = pathing.new_goal_cache()
		stepped = (
			here
			+ pathing.walk_step(
				here, goal, pace, def.body_radius, 0.0, ctx.tick_count, _king_goals, 1
			)
		)
	ctx.king.report_position(pathing.push_out(stepped, def.body_radius))


## The id of the living enemy nearest the castle (the lowest id wins a tie); -1 while none is up.
func _nearest_threat(ctx: RunContext) -> int:
	var enemies: EnemySystem = ctx.night.get_enemies()
	var castle: Vector2 = ctx.castle.get_position()
	var best: float = INF
	var best_id: int = -1
	for id: int in enemies.ids():
		if not enemies.is_alive(id):
			continue
		var distance: float = enemies.position_of(id).distance_squared_to(castle)
		if distance < best:
			best = distance
			best_id = id
	return best_id
