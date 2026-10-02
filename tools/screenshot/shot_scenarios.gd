class_name ShotScenarios
extends RefCounted
## The scripted scenes behind `tools/screenshot.sh` (DEV-04). Every scenario drives the game the
## way a player does: through the Input Map actions or the command intents in `ctx.commands`,
## never by writing simulation state directly.

const NEAR_OFFSET := Vector3(0.5, 0.0, 0.0)
## The camera looks toward -Z, so this puts the king 1.4 m past the keep's far wall, where UAT
## found him hidden.
const BEHIND_KEEP_OFFSET := Vector3(0.0, 0.0, -5.0)
const CAMERA_SETTLE_S: float = 1.2
const OVERVIEW_WAIT_S: float = 0.8
const LABEL_WAIT_S: float = 0.6
const BANNER_WAIT_S: float = 1.3
const OVERLAY_WAIT_S: float = 0.6
const DAWN_COIN_WAIT_S: float = 0.45
const DAWN_TIMEOUT_S: float = 10.0
## build_in_progress catches the hold with this many coins paid and the next one still flying.
const SHOT_COINS_PAID: int = 2
## How far into the gap to the next coin the shot is taken (0.5 is mid-flight).
const MID_GAP_FRACTION: float = 0.5
const PRESS_FRAMES: int = 2

const DAY_OVERVIEW := &"day_overview"
const SPOT_LABEL := &"spot_label"
const BUILD_IN_PROGRESS := &"build_in_progress"
const NIGHT_BANNER := &"night_banner"
const DAWN_PAYOUT := &"dawn_payout"
const OVERLAY_ON := &"overlay_on"
const KING_BEHIND_KEEP := &"king_behind_keep"
const ALL_SHOTS: Array[StringName] = [
	DAY_OVERVIEW,
	SPOT_LABEL,
	BUILD_IN_PROGRESS,
	NIGHT_BANNER,
	DAWN_PAYOUT,
	OVERLAY_ON,
	KING_BEHIND_KEEP
]


## Runs the scenario and returns true when the scene is ready to be captured.
static func run(shot_name: StringName, runner: Node, map_root: MapRoot) -> bool:
	match shot_name:
		DAY_OVERVIEW:
			return await _day_overview(runner, map_root)
		SPOT_LABEL:
			return await _spot_label(runner, map_root)
		BUILD_IN_PROGRESS:
			return await _build_in_progress(runner, map_root)
		NIGHT_BANNER:
			return await _night_banner(runner, map_root)
		DAWN_PAYOUT:
			return await _dawn_payout(runner, map_root)
		OVERLAY_ON:
			return await _overlay_on(runner, map_root)
		KING_BEHIND_KEEP:
			return await _king_behind_keep(runner, map_root)
	printerr("unknown shot %s (known: %s)" % [shot_name, ALL_SHOTS])
	return false


## Lets go of every action, so a scenario that leaves a key held cannot leak into the capture.
static func cleanup() -> void:
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)


static func _day_overview(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	var built: bool = (
		_submit_ok(ctx, BuildIntent.new(&"house_1"))
		and _submit_ok(ctx, BuildIntent.new(&"house_2"))
		and _submit_ok(ctx, BuildIntent.new(&"house_1"))
	)
	await _wait(runner, OVERVIEW_WAIT_S)
	return built


static func _spot_label(runner: Node, map_root: MapRoot) -> bool:
	await _stand_beside(runner, map_root, &"house_3")
	await _wait(runner, LABEL_WAIT_S)
	return true


static func _build_in_progress(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	await _stand_beside(runner, map_root, &"tower_1")
	Input.action_press(&"action_build")
	await _wait(
		runner,
		(
			ctx.tuning.coin_due_seconds(SHOT_COINS_PAID)
			+ MID_GAP_FRACTION * ctx.tuning.coin_interval(SHOT_COINS_PAID + 1)
		)
	)
	var hold: BuildHoldController = map_root.get_build_hold()
	return hold.get_coins_paid() > 0 and hold.is_holding()


static func _night_banner(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	var started: bool = _build_two_houses(ctx) and _submit_ok(ctx, StartNightIntent.new())
	await _wait(runner, BANNER_WAIT_S)
	return started


static func _dawn_payout(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	# house_2 is upgraded once, so it pays two coins and the flight shows three in total.
	var started: bool = (
		_build_two_houses(ctx)
		and _submit_ok(ctx, BuildIntent.new(&"house_2"))
		and _submit_ok(ctx, StartNightIntent.new())
	)
	if not started:
		return false
	var deadline: int = Time.get_ticks_msec() + roundi(DAWN_TIMEOUT_S * 1000.0)
	while (
		ctx.run_manager.get_phase() != RunManager.RunPhase.DAWN and Time.get_ticks_msec() < deadline
	):
		await runner.get_tree().process_frame
	await _wait(runner, DAWN_COIN_WAIT_S)
	return ctx.run_manager.get_phase() == RunManager.RunPhase.DAWN


static func _overlay_on(runner: Node, map_root: MapRoot) -> bool:
	Input.action_press(&"toggle_debug_overlay")
	await _wait_frames(runner, PRESS_FRAMES)
	Input.action_release(&"toggle_debug_overlay")
	await _wait(runner, OVERLAY_WAIT_S)
	var overlay: DebugOverlay = map_root.get_node_or_null("HUD/DebugOverlay") as DebugOverlay
	return overlay != null and overlay.is_overlay_visible()


## The king stands where the castle keep hides him. The shot is only worth taking if his X-Ray
## silhouette is set up, so the scenario fails (exit 1) when it is not.
static func _king_behind_keep(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	map_root.get_king().global_position = ctx.map.castle_position + BEHIND_KEEP_OFFSET
	await _wait(runner, CAMERA_SETTLE_S)
	var xray: XRaySilhouette = map_root.get_king().find_child("XRay", true, false) as XRaySilhouette
	if xray == null or xray.get_applied_count() <= 0:
		printerr("the king has no X-Ray silhouette set up")
		return false
	return true


static func _build_two_houses(ctx: RunContext) -> bool:
	return (
		_submit_ok(ctx, BuildIntent.new(&"house_1"))
		and _submit_ok(ctx, BuildIntent.new(&"house_2"))
	)


static func _submit_ok(ctx: RunContext, intent: RefCounted) -> bool:
	var result: StringName = ctx.commands.submit(intent)
	if result != CommandProcessor.OK:
		printerr("intent rejected: %s" % result)
	return result == CommandProcessor.OK


## Puts the king next to a spot and waits for the smoothed camera to catch up.
static func _stand_beside(runner: Node, map_root: MapRoot, spot_id: StringName) -> void:
	var ctx: RunContext = map_root.get_context()
	map_root.get_king().global_position = ctx.buildings.get_spot(spot_id).position + NEAR_OFFSET
	await _wait(runner, CAMERA_SETTLE_S)


static func _wait(runner: Node, seconds: float) -> void:
	await runner.get_tree().create_timer(seconds).timeout


static func _wait_frames(runner: Node, frames: int) -> void:
	for _frame: int in range(frames):
		await runner.get_tree().process_frame
