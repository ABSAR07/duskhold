class_name ShotScenarios
extends RefCounted
## The scripted scenes behind `tools/screenshot.sh` (DEV-04). Every scenario drives the game the
## way a player does: through the Input Map actions or the command intents in `ctx.commands`,
## never by writing simulation state directly. The night scenes reach their state by running the
## same bot-then-step loop a headless replay runs (`_fast_forward`), which is also only intents and
## the king's position report.

const MAP_DATA_PATH := "res://data/maps/prototype_map.tres"
## The shots start with enough gold to show several buildings in one scene.
const SHOT_STARTING_GOLD: int = 30
const NEAR_OFFSET := Vector3(0.5, 0.0, 0.0)
## A few metres off a plot, so the king does not stand on the marks hanging over it.
const BESIDE_PLOT_OFFSET := Vector3(4.0, 0.0, 2.0)
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
## The longest a scripted fast-forward may run (about 33 minutes of game time, far more than a run).
const FAST_FORWARD_MAX_TICKS: int = 60000
## How far into the first night the path-overlay shot is taken, in simulation ticks (5 s).
const PATHS_NIGHT_TICKS: int = 150
const PATHS_POLL_TIMEOUT_S: float = 1.0
## A night-combat scene needs this many enemies within NEAR_TOWER_RADIUS_M of the first tower.
const COMBAT_ENEMIES: int = 3
const NEAR_TOWER_RADIUS_M: float = 12.0
## Where the king stands relative to the tower in the combat shot: on its road side, so the tower
## and the enemies arriving at it share the frame.
const COMBAT_KING_OFFSET := Vector3(-3.0, 0.0, 0.0)
const TOWER_SPOT: StringName = &"tower_1"
const COMBAT_POLL_TIMEOUT_S: float = 4.0
const COLLAPSE_WAIT_S: float = 1.5
const DAWN_REBUILT_WAIT_S: float = 0.3
const RESPAWN_WAIT_S: float = 0.3
const RESULTS_VICTORY_WAIT_S: float = 0.5
const RESULTS_DEFEAT_EXTRA_WAIT_S: float = 0.5
## The defeat shot needs a castle that falls to the first blow.
const DEFEAT_CASTLE_HEALTH: int = 1

const DAY_OVERVIEW := &"day_overview"
const SPOT_LABEL := &"spot_label"
const BUILD_IN_PROGRESS := &"build_in_progress"
const NIGHT_BANNER := &"night_banner"
const DAWN_PAYOUT := &"dawn_payout"
const OVERLAY_ON := &"overlay_on"
const KING_BEHIND_KEEP := &"king_behind_keep"
const SPAWN_TELEGRAPH := &"spawn_telegraph"
const NIGHT_COMBAT := &"night_combat"
const BUILDING_DESTROYED := &"building_destroyed"
const DAWN_REBUILT := &"dawn_rebuilt"
const KING_DOWN_COUNTDOWN := &"king_down_countdown"
const RESULTS_VICTORY := &"results_victory"
const RESULTS_DEFEAT := &"results_defeat"
const OVERLAY_PATHS := &"overlay_paths"
const ALL_SHOTS: Array[StringName] = [
	DAY_OVERVIEW,
	SPOT_LABEL,
	BUILD_IN_PROGRESS,
	NIGHT_BANNER,
	DAWN_PAYOUT,
	OVERLAY_ON,
	KING_BEHIND_KEEP,
	SPAWN_TELEGRAPH,
	NIGHT_COMBAT,
	BUILDING_DESTROYED,
	DAWN_REBUILT,
	KING_DOWN_COUNTDOWN,
	RESULTS_VICTORY,
	RESULTS_DEFEAT,
	OVERLAY_PATHS
]


## True for the shots that wait out the Phase 1 timed night (night_banner and dawn_payout): their
## map copy drops its authored nights, so the night ends on its timer instead of on dead enemies.
## The other shots keep the shipped nights.
static func needs_timed_night(shot_name: StringName) -> bool:
	return shot_name == NIGHT_BANNER or shot_name == DAWN_PAYOUT


## The map copy a shot runs on (deep copies, so no edit reaches the shared resource, DR-12). Every
## copy starts with SHOT_STARTING_GOLD. The two Phase 1 timed-night shots drop their nights;
## results_victory keeps only the first night so the run is won after it; results_defeat gets a
## castle that falls to the first blow; every other shot keeps the shipped nights.
static func map_for(shot_name: StringName) -> MapConfig:
	var shipped: MapConfig = load(MAP_DATA_PATH)
	var config: MapConfig = shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	config.starting_gold = SHOT_STARTING_GOLD
	if needs_timed_night(shot_name):
		var no_nights: Array[NightDef] = []
		config.nights = no_nights
	elif shot_name == RESULTS_VICTORY:
		config.nights.resize(1)
	elif shot_name == RESULTS_DEFEAT:
		config.castle_max_health = DEFEAT_CASTLE_HEALTH
	return config


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
		SPAWN_TELEGRAPH:
			return await _spawn_telegraph(runner, map_root)
		NIGHT_COMBAT:
			return await _night_combat(runner, map_root)
		BUILDING_DESTROYED:
			return await _building_destroyed(runner, map_root)
		DAWN_REBUILT:
			return await _dawn_rebuilt(runner, map_root)
		KING_DOWN_COUNTDOWN:
			return await _king_down_countdown(runner, map_root)
		RESULTS_VICTORY:
			return await _results_victory(runner, map_root)
		RESULTS_DEFEAT:
			return await _results_defeat(runner, map_root)
		OVERLAY_PATHS:
			return await _overlay_paths(runner, map_root)
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


## By day, with a tower standing, the spawn points of the coming night wear their count markers.
## The king stands beside the tower, so the west road's marker sits over its spawn point and the
## others are clamped to the screen edge.
static func _spawn_telegraph(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	if not _submit_ok(ctx, BuildIntent.new(TOWER_SPOT)):
		return false
	await _stand_beside(runner, map_root, TOWER_SPOT)
	var telegraph: SpawnTelegraph = (
		_hud(map_root).find_child("SpawnTelegraph", true, false) as SpawnTelegraph
	)
	return telegraph != null and telegraph.marker_count() > 0


## The king stands on the first tower's road side from the start, so the camera is already there.
## The balanced bot plays into the first night until grunts crowd the tower, and the scene then runs
## in real time until an arrow is in the air.
static func _night_combat(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	var tower: Vector3 = ctx.buildings.get_spot(TOWER_SPOT).position
	var stand: Vector3 = tower + COMBAT_KING_OFFSET
	map_root.get_king().global_position = stand
	await _wait(runner, CAMERA_SETTLE_S)
	var bot: PlaytestBot = PlaytestStrategies.make(&"balanced")
	bot.king_mode = PlaytestBot.KING_HOLD_POINT
	bot.hold_point = Vector2(stand.x, stand.z)
	var crowded: Callable = func() -> bool:
		return (
			ctx.run_manager.get_phase() == RunManager.RunPhase.NIGHT
			and _enemies_near(ctx, tower, NEAR_TOWER_RADIUS_M) >= COMBAT_ENEMIES
		)
	if not _fast_forward(map_root, bot, crowded):
		printerr("no night put %d enemies near %s" % [COMBAT_ENEMIES, TOWER_SPOT])
		return false
	var vfx: ProjectileVfx = map_root.get_node("ProjectileVfx") as ProjectileVfx
	var shooting: Callable = func() -> bool:
		return (
			vfx.live_count() > 0
			and _enemies_near(ctx, tower, NEAR_TOWER_RADIUS_M) >= COMBAT_ENEMIES
		)
	var seen: bool = await _wait_until(runner, shooting, COMBAT_POLL_TIMEOUT_S)
	if not seen:
		printerr(
			(
				"no arrow in the air with %d enemies near the tower (arrows %d, enemies near %d)"
				% [COMBAT_ENEMIES, vfx.live_count(), _enemies_near(ctx, tower, NEAR_TOWER_RADIUS_M)]
			)
		)
	return seen


## A House the night kills lies in rubble: the greedy bot builds nothing but Houses, so the first
## night that reaches them costs it one. The king stands beside the plot and the collapse plays.
static func _building_destroyed(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	var watch: Watch = Watch.new(ctx)
	var fallen: Callable = func() -> bool: return watch.destroyed > 0
	if not _fast_forward(map_root, PlaytestStrategies.make(&"greedy_economy"), fallen):
		printerr("no building fell")
		return false
	var spot: StringName = watch.last_destroyed_spot
	map_root.get_king().global_position = ctx.buildings.get_spot(spot).position + NEAR_OFFSET
	await _wait(runner, COLLAPSE_WAIT_S)
	var views: BuildingViews = map_root.get_node("BuildingViews") as BuildingViews
	var view: Node3D = views.get_view(spot)
	return view != null and view.get_meta(&"rubble", false)


## The dawn after a night that cost a House: it stands again and wears the crossed-out coin that
## says it pays nothing this morning.
static func _dawn_rebuilt(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	var watch: Watch = Watch.new(ctx)
	var rebuilt_dawn: Callable = func() -> bool:
		return ctx.run_manager.get_phase() == RunManager.RunPhase.DAWN and watch.rebuilt > 0
	if not _fast_forward(map_root, PlaytestStrategies.make(&"greedy_economy"), rebuilt_dawn):
		printerr("no dawn rebuilt a building")
		return false
	var spot: StringName = watch.last_rebuilt_spot
	map_root.get_king().global_position = ctx.buildings.get_spot(spot).position + BESIDE_PLOT_OFFSET
	await _wait(runner, DAWN_REBUILT_WAIT_S)
	var marker: DawnNoIncomeMarker = (
		_hud(map_root).find_child("DawnNoIncomeMarker", true, false) as DawnNoIncomeMarker
	)
	return marker != null and marker.marker_count() > 0


## The king holds the spawn point that sends the most enemies, with the camera already there, until
## he is knocked out; the HUD then counts him back in. The wait after the knockout is short, because
## the towers may clear the night and dawn calls him back.
static func _king_down_countdown(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	var bot: PlaytestBot = PlaytestStrategies.make(&"balanced")
	bot.king_mode = PlaytestBot.KING_HOLD_POINT
	bot.hold_point = _busiest_spawn_point(ctx.map)
	var king: King = map_root.get_king()
	king.global_position = Vector3(bot.hold_point.x, king.global_position.y, bot.hold_point.y)
	await _wait(runner, CAMERA_SETTLE_S)
	var down: Callable = func() -> bool: return ctx.king.is_down()
	if not _fast_forward(map_root, bot, down):
		printerr("the king was never knocked out (%s)" % _state_line(ctx))
		return false
	await _wait(runner, RESPAWN_WAIT_S)
	var label: Label = _hud(map_root).find_child("RespawnLabel", true, false) as Label
	var shown: bool = label != null and label.visible
	if not shown:
		printerr("the countdown label is not showing (%s)" % _state_line(ctx))
	return shown


## The balanced bot wins the one-night copy and the Victory screen is up half a second later.
static func _results_victory(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	var won: Callable = func() -> bool:
		return ctx.run_manager.get_phase() == RunManager.RunPhase.WON
	if not _fast_forward(map_root, PlaytestStrategies.make(&"balanced"), won):
		printerr("the one-night run was not won")
		return false
	await _wait(runner, RESULTS_VICTORY_WAIT_S)
	return _results_showing(map_root)


## A castle of one hit point and a king who builds nothing: the run is lost, the collapse plays for
## the loss beat and the Defeat screen follows.
static func _results_defeat(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	var lost: Callable = func() -> bool:
		return ctx.run_manager.get_phase() == RunManager.RunPhase.LOST
	if not _fast_forward(map_root, PlaytestStrategies.make(&"no_build"), lost):
		printerr("the run was not lost")
		return false
	await _wait(runner, ctx.tuning.loss_beat_seconds + RESULTS_DEFEAT_EXTRA_WAIT_S)
	return _results_showing(map_root)


## Five seconds into the first night, with the overlay open and the king beside the first tower
## where the enemies arrive, the path lines run from each enemy to its target. The overlay is
## toggled on by its input action while it is still day, with the camera already in place.
static func _overlay_paths(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	var stand: Vector3 = ctx.buildings.get_spot(TOWER_SPOT).position + COMBAT_KING_OFFSET
	map_root.get_king().global_position = stand
	await _wait(runner, CAMERA_SETTLE_S)
	# A timer ends after the frame's _process calls, where a press would be missed by the overlay's
	# is_action_just_pressed check; one more frame puts the press before the next _process.
	await _wait_frames(runner, 1)
	Input.action_press(&"toggle_debug_overlay")
	await _wait_frames(runner, PRESS_FRAMES)
	Input.action_release(&"toggle_debug_overlay")
	await _wait_frames(runner, PRESS_FRAMES)
	var watch: Watch = Watch.new(ctx)
	var bot: PlaytestBot = PlaytestStrategies.make(&"balanced")
	bot.king_mode = PlaytestBot.KING_HOLD_POINT
	bot.hold_point = Vector2(stand.x, stand.z)
	var deep_enough: Callable = func() -> bool:
		return (
			watch.night_start_tick >= 0
			and ctx.tick_count - watch.night_start_tick >= PATHS_NIGHT_TICKS
		)
	if not _fast_forward(map_root, bot, deep_enough):
		printerr(
			"the first night did not reach %d ticks (%s)" % [PATHS_NIGHT_TICKS, _state_line(ctx)]
		)
		return false
	var overlay: DebugOverlay = map_root.get_node_or_null("HUD/DebugOverlay") as DebugOverlay
	var gizmo: EnemyPathGizmo = map_root.find_child("EnemyPathGizmo", true, false) as EnemyPathGizmo
	if overlay == null or gizmo == null:
		printerr("the overlay or its path gizmo is missing")
		return false
	var drawn: Callable = func() -> bool: return gizmo.line_count() > 0
	var shown: bool = await _wait_until(runner, drawn, PATHS_POLL_TIMEOUT_S)
	if not shown or not overlay.is_overlay_visible():
		printerr(
			(
				"path lines %d, overlay %s (%s)"
				% [gizmo.line_count(), overlay.is_overlay_visible(), _state_line(ctx)]
			)
		)
	return shown and overlay.is_overlay_visible()


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


static func _hud(map_root: MapRoot) -> Node:
	return map_root.get_node("HUD")


static func _results_showing(map_root: MapRoot) -> bool:
	var results: ResultsScreen = map_root.get_node("ResultsScreen") as ResultsScreen
	return results != null and results.is_showing()


## Runs the loop a headless replay runs (the bot thinks, then the simulation steps) until `done` is
## true, the run ends or `max_ticks` steps have run, then puts the king node where the simulation
## has him so the next frame's position report agrees. It is the only way these scenes move the
## clock faster than real time, and they still never write simulation state themselves.
static func _fast_forward(
	map_root: MapRoot, bot: PlaytestBot, done: Callable, max_ticks: int = FAST_FORWARD_MAX_TICKS
) -> bool:
	var ctx: RunContext = map_root.get_context()
	var reached: bool = done.call()
	var ticks: int = 0
	while not reached and ticks < max_ticks and not ctx.run_manager.is_run_over():
		bot.think(ctx)
		ctx.step()
		ticks += 1
		reached = done.call()
	var king: King = map_root.get_king()
	var here: Vector2 = ctx.king.get_position()
	king.global_position = Vector3(here.x, king.global_position.y, here.y)
	return reached


## One line of run state for a failed scenario's message.
static func _state_line(ctx: RunContext) -> String:
	return (
		"tick %d, phase %d, night %d, enemies %d, king hp %d, castle hp %d"
		% [
			ctx.tick_count,
			ctx.run_manager.get_phase(),
			ctx.run_manager.get_night_number(),
			ctx.get_enemy_count(),
			ctx.king.get_health(),
			ctx.castle.get_health()
		]
	)


## The number of living enemies within `radius` metres of `point` (XZ distance).
static func _enemies_near(ctx: RunContext, point: Vector3, radius: float) -> int:
	var enemies: EnemySystem = ctx.night.get_enemies()
	var centre: Vector2 = Vector2(point.x, point.z)
	var count: int = 0
	for id: int in enemies.ids():
		if enemies.is_alive(id) and enemies.position_of(id).distance_to(centre) <= radius:
			count += 1
	return count


## The spawn point that sends the most enemies over all nights, as an XZ point.
static func _busiest_spawn_point(map: MapConfig) -> Vector2:
	var totals: Dictionary = {}
	for night: NightDef in map.nights:
		for group: SpawnGroupDef in night.groups:
			totals[group.spawn_point_id] = int(totals.get(group.spawn_point_id, 0)) + group.count
	var best_total: int = -1
	var best: Vector2 = Vector2(map.king_spawn.x, map.king_spawn.z)
	for spawn_point: SpawnPointDef in map.spawn_points:
		var total: int = int(totals.get(spawn_point.id, 0))
		if total > best_total:
			best_total = total
			best = Vector2(spawn_point.position.x, spawn_point.position.z)
	return best


## Puts the king next to a spot and waits for the smoothed camera to catch up.
static func _stand_beside(runner: Node, map_root: MapRoot, spot_id: StringName) -> void:
	var ctx: RunContext = map_root.get_context()
	map_root.get_king().global_position = ctx.buildings.get_spot(spot_id).position + NEAR_OFFSET
	await _wait(runner, CAMERA_SETTLE_S)


## Polls once per frame until `predicate` holds or `timeout_s` of real time has passed.
static func _wait_until(runner: Node, predicate: Callable, timeout_s: float) -> bool:
	var deadline: int = Time.get_ticks_msec() + roundi(timeout_s * 1000.0)
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		await runner.get_tree().process_frame
	return predicate.call()


static func _wait(runner: Node, seconds: float) -> void:
	await runner.get_tree().create_timer(seconds).timeout


static func _wait_frames(runner: Node, frames: int) -> void:
	for _frame: int in range(frames):
		await runner.get_tree().process_frame


## Records the simulation events a fast-forward needs to recognise its scene.
class Watch:
	extends RefCounted
	var destroyed: int = 0
	var last_destroyed_spot: StringName = &""
	var rebuilt: int = 0
	var last_rebuilt_spot: StringName = &""
	## The simulation tick the first night began on; -1 before it does.
	var night_start_tick: int = -1

	var _ctx: RunContext

	func _init(ctx: RunContext) -> void:
		_ctx = ctx
		ctx.events.building_destroyed.connect(_on_building_destroyed)
		ctx.events.buildings_rebuilt.connect(_on_buildings_rebuilt)
		ctx.events.night_started.connect(_on_night_started)

	func _on_building_destroyed(spot_id: StringName, _building_id: StringName, _tier: int) -> void:
		destroyed += 1
		last_destroyed_spot = spot_id

	func _on_buildings_rebuilt(spot_ids: Array) -> void:
		rebuilt += spot_ids.size()
		if not spot_ids.is_empty():
			last_rebuilt_spot = spot_ids[0]

	func _on_night_started(_night_number: int) -> void:
		if night_start_tick < 0:
			night_start_tick = _ctx.tick_count
