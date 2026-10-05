class_name PlaytestBot
extends RefCounted
## A scripted player for headless runs (D-18). It touches the simulation only through intents and
## the king-position input (DR-10) and uses no random function, so a run with a given bot, map and
## seed is reproducible. Bots build without riding to plots: the balance report says so, because
## the real player pays for the ride in time. tools/ is excluded from the export.

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

var _cursor: int = 0
var _ordered_for_night: int = -1


## One decision per simulation tick, before `ctx.step()`.
func think(ctx: RunContext) -> void:
	if ctx.run_manager.get_phase() == RunManager.RunPhase.DAY:
		if prefer_telegraphed_towers:
			_prioritise_telegraphed_towers(ctx)
		_build(ctx)
		if start_nights:
			ctx.commands.submit(StartNightIntent.new())
	_move_king(ctx)


## Builds the next entries of build_order while they are accepted. An entry that can never be
## built (max tier, unknown spot) is skipped; an unaffordable one waits for a later think.
func _build(ctx: RunContext) -> void:
	while _cursor < build_order.size():
		var spot_id: StringName = build_order[_cursor]
		var reason: StringName = ctx.commands.validate_build(spot_id)
		if reason == CommandProcessor.OK:
			ctx.commands.submit(BuildIntent.new(spot_id))
			_cursor += 1
		elif reason == CommandProcessor.MAX_TIER or reason == CommandProcessor.UNKNOWN_SPOT:
			_cursor += 1
		else:
			return


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
			if here.distance_to(goal) <= def.attack_range * STOP_SHARE_OF_ATTACK_RANGE:
				return
	ctx.king.report_position(here.move_toward(goal, pace))


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
