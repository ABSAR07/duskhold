class_name ShotCrowdScenarios
extends RefCounted
## The Phase 4 scenes of `tools/screenshot.sh` (plans 04-05 and 04-08): the four wall runs by day, a
## breach at night, and the flow field with the queue at the stress map's gate. They follow the
## rules of ShotScenarios: every scene reaches its state through intents
## and the bot-then-step replay loop. The one exception is the breach itself, which uses
## `ctx.walls.damage_segment` the way the shots teleport the king: a tools-only shortcut, so the
## scene does not depend on which way the enemies choose to go once the flow field and the
## break-or-detour rule land (plans 04-06 and 04-07).

const WEST: StringName = &"wall_west"
const EAST: StringName = &"wall_east"
const NORTH: StringName = &"wall_north"
const RING: StringName = &"wall_ring"
## The tier each run is bought up to in walls_day, in the order the plots appear on the map.
const DAY_RUNS: Array[StringName] = [WEST, EAST, NORTH, RING]
const DAY_TIERS: Array[int] = [1, 2, 3, 2]
const CROWD_SHOTS: Array[StringName] = [
	ShotScenarios.WALLS_DAY, ShotScenarios.WALLS_NIGHT_BREACH, ShotScenarios.OVERLAY_FIELD_GATE
]
const DRAW_TIMEOUT_S: float = 3.0
## The label fades in over this long once the king stands at the plot.
const LABEL_SETTLE_S: float = 0.8
## A grunt this close to the run (metres, to the nearest standing segment) starts the breach.
const BREACH_REACH_M: float = 6.0
## The simulation runs this many ticks after the break (2 s) before the capture.
const AFTER_BREAK_TICKS: int = 60
const COLLAPSE_WAIT_S: float = 0.8
const BREACH_TIMEOUT_TICKS: int = 900
## overlay_field_gate: the king stands on the castle side of the stress map's wall, east of the gate
## and clear of every aggro range (the gate is at x -2 to 2 on z 30), the night runs this many ticks
## (8 s) and the drawing gets this long to appear.
const FIELD_GATE_STAND := Vector3(7.0, 0.0, 24.0)
const FIELD_GATE_NIGHT_TICKS: int = 240
const FIELD_GATE_DRAW_TIMEOUT_S: float = 4.0


## True for the Phase 4 shots.
static func handles(shot_name: StringName) -> bool:
	return CROWD_SHOTS.has(shot_name)


## The map copy a Phase 4 shot runs on: a deep copy (DR-12) with the shot gold. The wall shots get
## the shipped map with its four wall runs and its eight nights kept; overlay_field_gate gets the
## tools-only stress map.
static func map_for(shot_name: StringName) -> MapConfig:
	var path: String = ShotScenarios.MAP_DATA_PATH
	if shot_name == ShotScenarios.OVERLAY_FIELD_GATE:
		path = GateStress.STRESS_MAP
	var shipped: MapConfig = load(path)
	var config: MapConfig = shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	config.starting_gold = ShotScenarios.SHOT_STARTING_GOLD
	return config


static func run(shot_name: StringName, runner: Node, map_root: MapRoot) -> bool:
	match shot_name:
		ShotScenarios.WALLS_DAY:
			return await _walls_day(runner, map_root)
		ShotScenarios.WALLS_NIGHT_BREACH:
			return await _walls_night_breach(runner, map_root)
		ShotScenarios.OVERLAY_FIELD_GATE:
			return await _overlay_field_gate(runner, map_root)
	printerr("unknown crowd shot %s" % shot_name)
	return false


## By day with all four runs bought (west a barricade, east stone, north reinforced, the ring
## stone) and the king just inside the west gap, so its label offers Wall II.
static func _walls_day(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	for index: int in range(DAY_RUNS.size()):
		for _step: int in range(DAY_TIERS[index]):
			if not ShotScenarios._submit_ok(ctx, BuildIntent.new(DAY_RUNS[index])):
				return false
	var views: WallViews = map_root.get_node("WallViews") as WallViews
	var expected: int = 0
	for run_id: StringName in DAY_RUNS:
		expected += ctx.walls.segments_of(run_id).size()
	var drawn: Callable = func() -> bool: return views.piece_count() == expected
	if not await ShotScenarios._wait_until(runner, drawn, DRAW_TIMEOUT_S):
		printerr("the runs were not drawn (%d of %d pieces)" % [views.piece_count(), expected])
		return false
	await _stand_at(runner, map_root, WEST)
	await ShotScenarios._wait(runner, LABEL_SETTLE_S)
	var looks_ok: bool = (
		views.tier_look_of(WEST) == WallViews.LOOK_BARRICADE
		and views.tier_look_of(EAST) == WallViews.LOOK_STONE
		and views.tier_look_of(NORTH) == WallViews.LOOK_REINFORCED
		and views.tier_look_of(RING) == WallViews.LOOK_STONE
	)
	if not looks_ok:
		printerr("the runs do not wear their tier looks")
	return looks_ok


## Night 1 with the west run a barricade: the sim runs until the first grunt is within reach of the
## run, the segment next to the road gap is broken, and two more seconds later the camera, on the
## gate, shows the sunk piece, its rubble and the grunts coming through.
static func _walls_night_breach(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	if not ShotScenarios._submit_ok(ctx, BuildIntent.new(WEST)):
		return false
	await _stand_at(runner, map_root, WEST)
	var stand: Vector3 = ctx.buildings.get_spot(WEST).position + ShotScenarios.NEAR_OFFSET
	var bot: PlaytestBot = PlaytestBot.new()
	bot.start_nights = false
	bot.king_mode = PlaytestBot.KING_HOLD_POINT
	bot.hold_point = Vector2(stand.x, stand.z)
	if not ShotScenarios._submit_ok(ctx, StartNightIntent.new()):
		return false
	var near: Callable = func() -> bool: return _nearest_grunt(ctx, WEST) >= 0
	if not ShotScenarios._fast_forward(map_root, bot, near, BREACH_TIMEOUT_TICKS):
		printerr("no grunt came within %s m of the run (%s)" % [BREACH_REACH_M, _state(ctx)])
		return false
	var segment: int = _segment_beside_the_gap(ctx, WEST, _nearest_grunt(ctx, WEST))
	var broken: Array[int] = []
	ctx.events.wall_segment_broken.connect(
		func(_spot_id: StringName, index: int) -> void: broken.append(index)
	)
	ctx.walls.damage_segment(segment, ctx.walls.max_health_of(segment))
	if broken != [segment]:
		printerr("segment %d did not break (%s)" % [segment, broken])
		return false
	var until: int = ctx.tick_count + AFTER_BREAK_TICKS
	var later: Callable = func() -> bool: return ctx.tick_count >= until
	ShotScenarios._fast_forward(map_root, bot, later)
	await ShotScenarios._wait(runner, COLLAPSE_WAIT_S)
	var views: WallViews = map_root.get_node("WallViews") as WallViews
	if views.rubble_count() < 1 or views.is_piece_drawn(segment):
		printerr("the broken segment is not rubble (%d rubble)" % views.rubble_count())
		return false
	return true


## The stress map's gate wall raised to its tier, night 1 started and run for 8 s with the overlay
## open and the king beside the gate: the field arrows funnel into the gate, the crosses mark the
## wall, the queue builds up in front of it and the Walls, Field and Crowd sections read.
static func _overlay_field_gate(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	if not ShotScenarios._submit_ok(ctx, BuildIntent.new(GateStress.GATE_SPOT)):
		return false
	map_root.get_king().global_position = FIELD_GATE_STAND
	await ShotScenarios._wait(runner, ShotScenarios.CAMERA_SETTLE_S)
	await ShotScenarios._wait_frames(runner, 1)
	Input.action_press(&"toggle_debug_overlay")
	await ShotScenarios._wait_frames(runner, ShotScenarios.PRESS_FRAMES)
	Input.action_release(&"toggle_debug_overlay")
	await ShotScenarios._wait_frames(runner, ShotScenarios.PRESS_FRAMES)
	if not ShotScenarios._submit_ok(ctx, StartNightIntent.new()):
		return false
	var bot: PlaytestBot = PlaytestBot.new()
	bot.start_nights = false
	bot.king_mode = PlaytestBot.KING_HOLD_POINT
	bot.hold_point = Vector2(FIELD_GATE_STAND.x, FIELD_GATE_STAND.z)
	var until: int = ctx.tick_count + FIELD_GATE_NIGHT_TICKS
	var later: Callable = func() -> bool: return ctx.tick_count >= until
	ShotScenarios._fast_forward(map_root, bot, later)
	var gizmo: FlowFieldGizmo = map_root.find_child("FlowFieldGizmo", true, false) as FlowFieldGizmo
	var overlay: DebugOverlay = map_root.get_node_or_null("HUD/DebugOverlay") as DebugOverlay
	if gizmo == null or overlay == null or not overlay.is_overlay_visible():
		printerr("the overlay or its field gizmo is missing")
		return false
	var drawn: Callable = func() -> bool: return gizmo.arrow_count() > 0
	var shown: bool = await ShotScenarios._wait_until(runner, drawn, FIELD_GATE_DRAW_TIMEOUT_S)
	if not shown:
		printerr("no field arrows were drawn (%s)" % _state(ctx))
	return shown


## Puts the king beside the plot, where its label shows, and waits for the camera to catch up.
static func _stand_at(runner: Node, map_root: MapRoot, spot_id: StringName) -> void:
	var plot: Vector3 = map_root.get_context().buildings.get_spot(spot_id).position
	map_root.get_king().global_position = plot + ShotScenarios.NEAR_OFFSET
	await ShotScenarios._wait(runner, ShotScenarios.CAMERA_SETTLE_S)


## The id of a living enemy within BREACH_REACH_M of a standing segment of the run, or -1.
static func _nearest_grunt(ctx: RunContext, spot_id: StringName) -> int:
	var enemies: EnemySystem = ctx.night.get_enemies()
	var best: int = -1
	var best_distance: float = BREACH_REACH_M
	for id: int in enemies.ids():
		if not enemies.is_alive(id):
			continue
		for segment: int in ctx.walls.segments_of(spot_id):
			if not ctx.walls.is_intact(segment):
				continue
			var at: Vector2 = WallSolids.closest_point(ctx.walls, segment, enemies.position_of(id))
			var apart: float = at.distance_to(enemies.position_of(id))
			if apart <= best_distance:
				best = id
				best_distance = apart
	return best


## Of the two segments on either side of the road gap (the gap is authored in the middle of the
## run), the one nearer to the enemy.
static func _segment_beside_the_gap(ctx: RunContext, spot_id: StringName, enemy: int) -> int:
	var segments: PackedInt32Array = ctx.walls.segments_of(spot_id)
	var half: int = segments.size() >> 1
	var before: int = segments[half - 1]
	var after: int = segments[half]
	var at: Vector2 = ctx.night.get_enemies().position_of(enemy)
	var to_before: float = _middle(ctx, before).distance_to(at)
	var to_after: float = _middle(ctx, after).distance_to(at)
	return before if to_before <= to_after else after


static func _middle(ctx: RunContext, segment: int) -> Vector2:
	return (ctx.walls.segment_start(segment) + ctx.walls.segment_end(segment)) * 0.5


static func _state(ctx: RunContext) -> String:
	return ShotScenarios._state_line(ctx)
