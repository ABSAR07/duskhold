class_name PlaytestBot
extends RefCounted
## A scripted player for headless runs (D-18). It touches the simulation only through intents and
## the king-position input (DR-10) and uses no random function, so a run with a given bot, map and
## seed is reproducible. Bots build without riding to plots: the balance report says so, because
## the real player pays for the ride in time. tools/ is excluded from the export.

const KING_IDLE_AT_CASTLE := &"idle_at_castle"
const KING_HOLD_POINT := &"hold_point"
const KING_DEFEND_NEAREST_THREAT := &"defend_nearest_threat"

## Spots to build in order. A repeated spot id means an upgrade.
var build_order: Array[StringName] = []
## Where the bot keeps the king: KING_IDLE_AT_CASTLE (the map's king spawn) or KING_HOLD_POINT.
var king_mode: StringName = KING_IDLE_AT_CASTLE
## The XZ point the king walks to in KING_HOLD_POINT mode.
var hold_point: Vector2 = Vector2.ZERO
## Whether the bot starts every night as soon as the day allows.
var start_nights: bool = true
## Whether the bot builds tower plots on the roads the coming night uses first.
var prefer_telegraphed_towers: bool = false

var _cursor: int = 0


## One decision per simulation tick, before `ctx.step()`.
func think(ctx: RunContext) -> void:
	if ctx.run_manager.get_phase() == RunManager.RunPhase.DAY:
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


## Walks the bot-owned king position toward the mode's goal at the king's walking speed.
func _move_king(ctx: RunContext) -> void:
	var goal: Vector2 = Vector2(ctx.map.king_spawn.x, ctx.map.king_spawn.z)
	if king_mode == KING_HOLD_POINT:
		goal = hold_point
	var pace: float = ctx.king.get_def().walk_speed * SimClock.STEP
	ctx.king.report_position(ctx.king.get_position().move_toward(goal, pace))
