class_name ShotArmyScenarios
extends RefCounted
## The eighteen Phase 3 scenes of `tools/screenshot.sh` (plan 03-12): the army HUD at night and by
## day, the drag box, the pad's ground cursor, the knocked-out king, the ability's ready flash, the
## longest toast, three window shapes, the backstop rows of the UI-SPEC and four scripted command
## runs. They follow the rules of ShotScenarios: every scene reaches its state through intents,
## Input Map actions, input events and the bot-then-step replay loop, never by writing simulation
## state. The selection is presentation state, so a scene that only needs a squad selected writes
## the SelectionModel directly; the scenes about the pointer and the pad drive real events instead.
## The input scenes run at 1280x720, where a screen pixel and a HUD pixel are the same.

const BARRACKS: StringName = &"barracks_1"
const ARCHERY: StringName = &"archery_1"
const BOTH: Array[StringName] = [&"barracks_1", &"archery_1"]
## Where the king waits by day: between the two squads, in front of the keep.
const KING_STAND := Vector3(0.0, 0.0, 4.0)
## Far east on the ground plane, so a click off the map's edge lands on no ground.
const KING_EDGE := Vector3(84.0, 0.0, 0.0)
const OFF_MAP_POINT := Vector3(100.0, 0.0, 0.0)
const RAISE_TIMEOUT_S: float = 3.0
const SETTLE_S: float = 1.2
const TOAST_FADE_IN_S: float = 0.25
const FLASH_TIMEOUT_S: float = 2.0
const SLAM_RING_WAIT_S: float = 0.1
const RING_TIMEOUT_S: float = 2.0
## Longer than the slam ring lives (0.25 s), so the ready-flash shot has no ring left in it.
const FILL_WATCH_S: float = 0.5
const HINT_FADE_WAIT_S: float = 0.35
const RING_GONE_WAIT_S: float = 0.5
## Night scenes that hurt the king keep him from healing, so the number the shot shows is the one
## the scene reached (a shot-only copy of the king, like king_down_countdown's).
const FROZEN_KING_SHOTS: Array[StringName] = [
	ShotScenarios.HUD_NIGHT_SQUAD_DOWN,
	ShotScenarios.HUD_NIGHT_SQUAD_DOWN_16X10,
	ShotScenarios.HUD_KING_DOWN,
	ShotScenarios.HUD_KING_120,
]
const LONG_RUN_NIGHTS: int = 12
const KING_120_HEALTH: int = 120
## The night the king starts defending in the squad-down scenes: before it the squads hold alone.
const DEFEND_FROM_NIGHT: int = 4
const HURT_MIN: int = 34
const HURT_MAX: int = 42
const HURT_120_MIN: int = 84
const HURT_120_MAX: int = 90
const POINT_MARGIN_PX: float = 60.0
## The ten queued moves, relative to the king: five on each side of the keep, in two rows, clear of
## the squad slots (which swallow a click) at the foot of the screen.
const QUEUE_POINTS: Array[Vector3] = [
	Vector3(-14.0, 0.0, 0.0),
	Vector3(-11.0, 0.0, 2.0),
	Vector3(-8.0, 0.0, 0.0),
	Vector3(-5.0, 0.0, 2.0),
	Vector3(-6.0, 0.0, -3.0),
	Vector3(6.0, 0.0, -3.0),
	Vector3(5.0, 0.0, 2.0),
	Vector3(8.0, 0.0, 0.0),
	Vector3(11.0, 0.0, 2.0),
	Vector3(14.0, 0.0, 0.0),
]
const SLAM_MIN_ENEMIES: int = 2
const DRAG_FROM := Vector2(240.0, 150.0)
const DRAG_MID := Vector2(520.0, 330.0)
const DRAG_TO := Vector2(900.0, 470.0)
const PAD_STICK := Vector2(0.8, -0.5)
const PAD_STICK_SECONDS: float = 0.35
const PAD_DEBOUNCE_S: float = 0.35
const PATROL_POINTS: Array[Vector3] = [Vector3(-12.0, 0.0, 0.0), Vector3(-6.0, 0.0, 2.0)]
const PING_POINT := Vector3(-8.0, 0.0, 2.0)


## True for the eighteen Phase 3 shots.
static func handles(shot_name: StringName) -> bool:
	return ShotScenarios.ARMY_SHOTS.has(shot_name)


## Edits the map copy of the long-counter shot: twelve nights of one grunt each, so the day before
## the last one reads "Night 12 of 12" after a short run.
static func use_twelve_short_nights(config: MapConfig) -> void:
	var template: NightDef = config.nights[0]
	var nights: Array[NightDef] = []
	for _index: int in range(LONG_RUN_NIGHTS):
		var night: NightDef = template.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
		var first: SpawnGroupDef = night.groups[0]
		first.count = 1
		var groups: Array[SpawnGroupDef] = [first]
		night.groups = groups
		nights.append(night)
	config.nights = nights


## Edits the king copy of a shot: the shots that hurt him hold his health still, and the long-health
## shot gets 120 points.
static func tune_king(shot_name: StringName, def: KingDef) -> void:
	if FROZEN_KING_SHOTS.has(shot_name):
		def.regen_fraction_per_second = 0.0
	if shot_name == ShotScenarios.HUD_KING_120:
		def.max_health = KING_120_HEALTH


static func run(shot_name: StringName, runner: Node, map_root: MapRoot) -> bool:
	match shot_name:
		ShotScenarios.HUD_DAY_SQUADS, ShotScenarios.HUD_DAY_SQUADS_1080P:
			return await _day_squads(runner, map_root)
		ShotScenarios.HUD_NIGHT_SQUAD_DOWN:
			return await _night_squad_down(runner, map_root, BARRACKS)
		ShotScenarios.HUD_NIGHT_SQUAD_DOWN_16X10:
			return await _night_squad_down(runner, map_root, ARCHERY)
		ShotScenarios.HUD_DRAG_BOX:
			return await _drag_box(runner, map_root)
		ShotScenarios.HUD_PAD_CURSOR:
			return await _pad_cursor(runner, map_root)
		ShotScenarios.HUD_KING_DOWN:
			return await _king_down(runner, map_root)
		ShotScenarios.HUD_ABILITY_READY:
			return await _ability_ready(runner, map_root)
		ShotScenarios.HUD_LONG_TOAST:
			return await _long_toast(runner, map_root)
		ShotScenarios.HUD_DAY_COUNTER_LONG:
			return await _day_counter_long(runner, map_root)
		ShotScenarios.HUD_KING_120:
			return await _king_120(runner, map_root)
		ShotScenarios.HUD_KEYCAP_BACKSPACE:
			return await _keycap_backspace(runner, map_root)
		ShotScenarios.CMD_QUEUE_TEN:
			return await _queue_ten(runner, map_root)
		ShotScenarios.HUD_RUBBLE_SQUAD:
			return await _rubble_squad(runner, map_root)
		ShotScenarios.CMD_BOX_SELECT:
			return await _box_select(runner, map_root)
		ShotScenarios.CMD_MOVE_PING:
			return await _move_ping(runner, map_root)
		ShotScenarios.CMD_PATROL:
			return await _patrol(runner, map_root)
		ShotScenarios.CMD_SLAM:
			return await _slam(runner, map_root)
	printerr("unknown army shot %s" % shot_name)
	return false


## By day with both squads raised and the Barracks squad selected: the strip, the hint row, the
## rings and the king widget together. The 1080p variant is the same scene in a larger window.
static func _day_squads(runner: Node, map_root: MapRoot) -> bool:
	if not await _raise_squads(runner, map_root):
		return false
	_select(map_root, [BARRACKS] as Array[StringName])
	await _stand(runner, map_root, KING_STAND)
	return _strip_has_slots(map_root, 2)


## Night 7 of an army with no towers: one squad has fallen to 0 alive and the king is hurt to about
## 38 / 50. `selected` is the squad left selected, so the hint row shows.
static func _night_squad_down(runner: Node, map_root: MapRoot, selected: StringName) -> bool:
	var ctx: RunContext = map_root.get_context()
	var bot: PlaytestBot = _hold_bot()
	var hurt: Callable = func() -> bool:
		if ctx.run_manager.get_night_number() >= DEFEND_FROM_NIGHT:
			bot.king_mode = PlaytestBot.KING_DEFEND_NEAREST_THREAT
		return _squad_down_and_king_hurt(ctx, HURT_MIN, HURT_MAX)
	if not ShotScenarios._fast_forward(map_root, bot, hurt):
		printerr("no squad fell with the king hurt (%s)" % ShotScenarios._state_line(ctx))
		return false
	_select(map_root, [selected] as Array[StringName])
	await ShotScenarios._wait(runner, SETTLE_S)
	var fallen: bool = _any_squad_down(ctx)
	if not fallen:
		printerr(
			"the fallen squad was replaced during the settle (%s)" % ShotScenarios._state_line(ctx)
		)
	return fallen and not ctx.king.is_down()


## A press on the ground and motion past the drag threshold, held: the drag box is up.
static func _drag_box(runner: Node, map_root: MapRoot) -> bool:
	if not await _raise_squads(runner, map_root):
		return false
	await _stand(runner, map_root, KING_STAND)
	_mouse_motion(DRAG_FROM)
	await ShotScenarios._wait_frames(runner, 2)
	_mouse_button(MOUSE_BUTTON_LEFT, true, DRAG_FROM)
	await ShotScenarios._wait_frames(runner, 2)
	_mouse_motion(DRAG_MID)
	await ShotScenarios._wait_frames(runner, 2)
	_mouse_motion(DRAG_TO)
	await ShotScenarios._wait_frames(runner, 3)
	var box: DragBox = ShotScenarios._hud(map_root).find_child("DragBox", true, false) as DragBox
	var dragging: bool = box != null and box.is_dragging()
	if not dragging:
		printerr("the drag box is not showing")
	return dragging


## A pad button first (the prompts stay on the keyboard: gamepad prompts are unsupported since
## 2026-10-16), then LB with the D-pad up held and the right stick moved: the ground cursor is out.
static func _pad_cursor(runner: Node, map_root: MapRoot) -> bool:
	if not await _raise_squads(runner, map_root):
		return false
	_select(map_root, [BARRACKS] as Array[StringName])
	await _stand(runner, map_root, KING_STAND)
	_pad_button(JOY_BUTTON_A, true)
	await ShotScenarios._wait_frames(runner, 2)
	_pad_button(JOY_BUTTON_A, false)
	await ShotScenarios._wait(runner, PAD_DEBOUNCE_S)
	_pad_button(JOY_BUTTON_LEFT_SHOULDER, true)
	await ShotScenarios._wait_frames(runner, 2)
	_pad_button(JOY_BUTTON_DPAD_UP, true)
	await ShotScenarios._wait_frames(runner, 3)
	_pad_axis(JOY_AXIS_RIGHT_X, PAD_STICK.x)
	_pad_axis(JOY_AXIS_RIGHT_Y, PAD_STICK.y)
	await ShotScenarios._wait(runner, PAD_STICK_SECONDS)
	_pad_axis(JOY_AXIS_RIGHT_X, 0.0)
	_pad_axis(JOY_AXIS_RIGHT_Y, 0.0)
	await ShotScenarios._wait_frames(runner, 3)
	var cursor: PadCursorController = (
		map_root.get_node("PadCursorController") as PadCursorController
	)
	if not cursor.is_active():
		printerr("the pad cursor is not out")
		return false
	var tracker: LastDeviceTracker = map_root.get_device_tracker()
	if tracker == null or tracker.device() != GlyphResolver.DEVICE_KEYBOARD:
		printerr("the prompts left the keyboard")
		return false
	return true


## The balanced build with both squads first and holding their posts, the king held at the busiest
## spawn until he is knocked out: the widget dims and the countdown shows.
static func _king_down(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	var bot: PlaytestBot = PlaytestStrategies.make(&"balanced")
	var order: Array[StringName] = [BARRACKS, ARCHERY]
	order.append_array(bot.build_order)
	bot.build_order = order
	bot.night_orders = [{"squads": BOTH, "verb": SquadOrder.VERB_HOLD}]
	bot.king_mode = PlaytestBot.KING_HOLD_POINT
	bot.hold_point = ShotScenarios._busiest_spawn_point(ctx.map)
	var king: King = map_root.get_king()
	king.global_position = Vector3(bot.hold_point.x, king.global_position.y, bot.hold_point.y)
	await ShotScenarios._wait(runner, SETTLE_S)
	var down: Callable = func() -> bool: return ctx.king.is_down()
	if not ShotScenarios._fast_forward(map_root, bot, down):
		printerr("the king was never knocked out (%s)" % ShotScenarios._state_line(ctx))
		return false
	await ShotScenarios._wait(runner, ShotScenarios.RESPAWN_WAIT_S)
	var label: Label = ShotScenarios._hud(map_root).find_child("RespawnLabel", true, false) as Label
	var shown: bool = label != null and label.visible
	if not shown:
		printerr("the countdown label is not showing (%s)" % ShotScenarios._state_line(ctx))
	return shown


## The slam is used, the sim runs until it recharges and the shot is taken on the frames of the
## ready flash.
static func _ability_ready(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	if not await _raise_squads(runner, map_root):
		return false
	await _stand(runner, map_root, KING_STAND)
	Input.action_press(&"ability")
	await ShotScenarios._wait_frames(runner, 3)
	Input.action_release(&"ability")
	await ShotScenarios._wait(runner, RING_GONE_WAIT_S)
	if ctx.king.ability_ticks_left() <= 0:
		printerr("the slam was not used")
		return false
	var bot: PlaytestBot = PlaytestBot.new()
	bot.start_nights = false
	bot.king_mode = PlaytestBot.KING_HOLD_POINT
	bot.hold_point = Vector2(KING_STAND.x, KING_STAND.z)
	var nearly: Callable = func() -> bool: return ctx.king.ability_ticks_left() <= 2
	if not ShotScenarios._fast_forward(map_root, bot, nearly):
		printerr("the slam never came close to ready (%s)" % ShotScenarios._state_line(ctx))
		return false
	var widget: KingWidget = (
		ShotScenarios._hud(map_root).find_child("KingWidget", true, false) as KingWidget
	)
	var flashed: Callable = func() -> bool: return widget.ready_flash_count() > 0
	var seen: bool = await ShotScenarios._wait_until(runner, flashed, FLASH_TIMEOUT_S)
	await ShotScenarios._wait_frames(runner, 2)
	if not seen:
		printerr("the ready flash never played")
	return seen


## With a squad selected and the king at the east edge of the ground, a right click past the edge
## orders nothing and shows the longest toast.
static func _long_toast(runner: Node, map_root: MapRoot) -> bool:
	if not await _raise_squads(runner, map_root):
		return false
	_select(map_root, [BARRACKS] as Array[StringName])
	await _stand(runner, map_root, KING_EDGE)
	var at: Vector2 = _screen_of(map_root, OFF_MAP_POINT)
	_mouse_motion(at)
	await ShotScenarios._wait_frames(runner, 2)
	_mouse_button(MOUSE_BUTTON_RIGHT, true, at)
	await ShotScenarios._wait_frames(runner, 2)
	_mouse_button(MOUSE_BUTTON_RIGHT, false, at)
	await ShotScenarios._wait(runner, TOAST_FADE_IN_S)
	var toast: Toast = ShotScenarios._hud(map_root).find_child("Toast", true, false) as Toast
	var shown: bool = toast != null and toast.current_text() == Toast.CANT_GO_THERE
	if not shown:
		printerr("the toast is not showing the longest line")
		return false
	print("toast rect %s" % toast.get_global_rect())
	return true


## Twelve one-grunt nights, run to the day before the last: the counter reads "Night 12 of 12".
static func _day_counter_long(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	var bot: PlaytestBot = PlaytestStrategies.make(&"no_build")
	var eve: Callable = func() -> bool:
		return (
			ctx.run_manager.get_phase() == RunManager.RunPhase.DAY
			and ctx.run_manager.get_night_number() == LONG_RUN_NIGHTS - 1
		)
	if not ShotScenarios._fast_forward(map_root, bot, eve):
		printerr(
			"the run never reached the day before night 12 (%s)" % ShotScenarios._state_line(ctx)
		)
		return false
	await ShotScenarios._wait(runner, ShotScenarios.OVERVIEW_WAIT_S)
	var counter: DayCounter = (
		ShotScenarios._hud(map_root).find_child("DayCounter", true, false) as DayCounter
	)
	var label: Label = counter.find_child("DayCounterLabel", true, false) as Label
	var shown: bool = (
		label != null and label.is_visible_in_tree() and label.text == "Night 12 of 12"
	)
	if not shown:
		printerr("the counter does not read Night 12 of 12")
	return shown


## A king of 120 health, hurt to the high eighties at a spawn point: three digits on both sides of
## the slash.
static func _king_120(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	var bot: PlaytestBot = PlaytestStrategies.make(&"balanced")
	bot.king_mode = PlaytestBot.KING_HOLD_POINT
	bot.hold_point = ShotScenarios._busiest_spawn_point(ctx.map)
	var king: King = map_root.get_king()
	king.global_position = Vector3(bot.hold_point.x, king.global_position.y, bot.hold_point.y)
	await ShotScenarios._wait(runner, SETTLE_S)
	var hurt: Callable = func() -> bool:
		var health: int = ctx.king.get_health()
		return (
			ctx.run_manager.get_phase() == RunManager.RunPhase.NIGHT
			and health >= HURT_120_MIN
			and health <= HURT_120_MAX
		)
	if not ShotScenarios._fast_forward(map_root, bot, hurt):
		printerr("the king was never hurt into the eighties (%s)" % ShotScenarios._state_line(ctx))
		return false
	await ShotScenarios._wait(runner, ShotScenarios.RESPAWN_WAIT_S)
	return ctx.king.get_max_health() == KING_120_HEALTH


## Follow rebound to Backspace: the hint row shows a keycap that has to widen for a long key name.
static func _keycap_backspace(runner: Node, map_root: MapRoot) -> bool:
	if not await _raise_squads(runner, map_root):
		return false
	InputMap.action_erase_events(&"squad_follow")
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_BACKSPACE
	InputMap.action_add_event(&"squad_follow", key)
	_select(map_root, [BARRACKS] as Array[StringName])
	await _stand(runner, map_root, KING_STAND)
	var hints: CommandHints = (
		ShotScenarios._hud(map_root).find_child("CommandHints", true, false) as CommandHints
	)
	var shown: bool = hints != null and hints.visible_item_count() > 0
	if not shown:
		printerr("the hint row is not showing")
	return shown


## Ten moves queued with Shift on one selected squad: nine are kept, six discs are drawn and the
## tenth replaced the ninth.
static func _queue_ten(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	if not await _raise_squads(runner, map_root):
		return false
	_select(map_root, [BARRACKS] as Array[StringName])
	await _stand(runner, map_root, KING_STAND)
	Input.action_press(&"command_queue")
	await ShotScenarios._wait_frames(runner, 2)
	# The simulation is held still while the ten clicks go in: it runs in real time, and on a slow
	# renderer (CI) the frames between two clicks add up to enough walking for the first leg to end
	# and shorten the queue. The orders still go through the real click path and the command gate.
	map_root.set_process(false)
	for point: Vector3 in QUEUE_POINTS:
		var at: Vector2 = _screen_of(map_root, KING_STAND + point)
		_mouse_button(MOUSE_BUTTON_RIGHT, true, at)
		await ShotScenarios._wait_frames(runner, 1)
		_mouse_button(MOUSE_BUTTON_RIGHT, false, at)
		await ShotScenarios._wait_frames(runner, 1)
	Input.action_release(&"command_queue")
	await ShotScenarios._wait_frames(runner, 2)
	map_root.set_process(true)
	var markers: OrderMarkers = map_root.get_node("OrderMarkers") as OrderMarkers
	var kept: int = ctx.squads.orders_of(BARRACKS).size()
	if kept != SquadOrder.MAX_QUEUE or markers.disc_count() != OrderMarkers.MAX_DISCS_SHOWN:
		printerr("queue %d kept and %d discs drawn" % [kept, markers.disc_count()])
		return false
	return true


## A night with no towers: the Barracks falls with its squad, and its slot keeps its place dimmed.
static func _rubble_squad(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	var fallen: Array[StringName] = []
	ctx.events.building_destroyed.connect(
		func(spot_id: StringName, _building_id: StringName, _tier: int) -> void:
			fallen.append(spot_id)
	)
	var gone: Callable = func() -> bool:
		return fallen.has(BARRACKS) and ctx.squads.alive_count(BARRACKS) == 0
	if not ShotScenarios._fast_forward(map_root, _hold_bot(), gone):
		printerr("the Barracks never fell (%s)" % ShotScenarios._state_line(ctx))
		return false
	_select(map_root, [BARRACKS] as Array[StringName])
	var plot: Vector3 = ctx.buildings.get_spot(BARRACKS).position
	map_root.get_king().global_position = plot + ShotScenarios.BESIDE_PLOT_OFFSET
	await ShotScenarios._wait(runner, SETTLE_S)
	var views: BuildingViews = map_root.get_node("BuildingViews") as BuildingViews
	var view: Node3D = views.get_view(BARRACKS)
	var rubble: bool = view != null and view.get_meta(&"rubble", false)
	if not rubble:
		printerr("the Barracks is not rubble (%s)" % ShotScenarios._state_line(ctx))
		return false
	var before: float = ctx.squads.replacement_progress(BARRACKS)
	await ShotScenarios._wait(runner, FILL_WATCH_S)
	var after: float = ctx.squads.replacement_progress(BARRACKS)
	print("rubble fill progress %.3f then %.3f" % [before, after])
	if not is_equal_approx(before, after):
		printerr("the replacement fill of the fallen Barracks is still running")
		return false
	return ctx.squads.alive_count(BARRACKS) == 0


## A real drag over both squads: the box is gone after the release and both are selected.
static func _box_select(runner: Node, map_root: MapRoot) -> bool:
	if not await _raise_squads(runner, map_root):
		return false
	await _stand(runner, map_root, KING_STAND)
	var rect: Rect2 = _squads_rect(map_root)
	_mouse_motion(rect.position)
	await ShotScenarios._wait_frames(runner, 2)
	_mouse_button(MOUSE_BUTTON_LEFT, true, rect.position)
	await ShotScenarios._wait_frames(runner, 2)
	_mouse_motion(rect.position + rect.size * 0.5)
	await ShotScenarios._wait_frames(runner, 2)
	_mouse_motion(rect.end)
	await ShotScenarios._wait_frames(runner, 2)
	_mouse_button(MOUSE_BUTTON_LEFT, false, rect.end)
	await ShotScenarios._wait(runner, HINT_FADE_WAIT_S)
	var chosen: Array[StringName] = map_root.get_selection().selected()
	if chosen != BOTH:
		printerr("the drag selected %s" % [chosen])
		return false
	return true


## A right click on the ground with a squad selected: it moves there and a ping marks the point.
static func _move_ping(runner: Node, map_root: MapRoot) -> bool:
	if not await _raise_squads(runner, map_root):
		return false
	_select(map_root, [BARRACKS] as Array[StringName])
	await _stand(runner, map_root, KING_STAND)
	var at: Vector2 = _screen_of(map_root, PING_POINT)
	_mouse_motion(at)
	await ShotScenarios._wait_frames(runner, 2)
	_mouse_button(MOUSE_BUTTON_RIGHT, true, at)
	await ShotScenarios._wait_frames(runner, 1)
	_mouse_button(MOUSE_BUTTON_RIGHT, false, at)
	# A ping lives only half a second and a frame on a slow renderer (CI) is long, so the scene
	# reads it as soon as the click has been handled and the shot follows one frame later.
	await ShotScenarios._wait_frames(runner, 1)
	var markers: OrderMarkers = map_root.get_node("OrderMarkers") as OrderMarkers
	var pinged: bool = markers.active_ping_count() > 0
	if not pinged:
		printerr("no ping is showing")
	return pinged


## The patrol key held and two right clicks, then the key let go: the dashed line is drawn.
static func _patrol(runner: Node, map_root: MapRoot) -> bool:
	if not await _raise_squads(runner, map_root):
		return false
	_select(map_root, [BARRACKS] as Array[StringName])
	await _stand(runner, map_root, KING_STAND)
	Input.action_press(&"squad_patrol")
	await ShotScenarios._wait_frames(runner, 3)
	for point: Vector3 in PATROL_POINTS:
		var at: Vector2 = _screen_of(map_root, KING_STAND + point)
		_mouse_motion(at)
		await ShotScenarios._wait_frames(runner, 2)
		_mouse_button(MOUSE_BUTTON_RIGHT, true, at)
		await ShotScenarios._wait_frames(runner, 2)
		_mouse_button(MOUSE_BUTTON_RIGHT, false, at)
		await ShotScenarios._wait_frames(runner, 2)
	Input.action_release(&"squad_patrol")
	await ShotScenarios._wait(runner, SETTLE_S / 3.0)
	var markers: OrderMarkers = map_root.get_node("OrderMarkers") as OrderMarkers
	var drawn: bool = markers.patrol_line_count() > 0
	if not drawn:
		printerr("no patrol line is showing")
	return drawn


## The king at the first tower with enemies in reach and the slam ready: the key is pressed and the
## ring is caught on its way out among them.
static func _slam(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	var tower: Vector3 = ctx.buildings.get_spot(ShotScenarios.TOWER_SPOT).position
	var stand: Vector3 = tower + ShotScenarios.COMBAT_KING_OFFSET
	map_root.get_king().global_position = stand
	await ShotScenarios._wait(runner, SETTLE_S)
	var bot: PlaytestBot = PlaytestStrategies.make(&"army_balanced")
	bot.king_mode = PlaytestBot.KING_HOLD_POINT
	bot.hold_point = Vector2(stand.x, stand.z)
	bot.slam_min_enemies = 0
	var among: Callable = func() -> bool:
		var here: Vector3 = Vector3(ctx.king.get_position().x, 0.0, ctx.king.get_position().y)
		return (
			ctx.run_manager.get_phase() == RunManager.RunPhase.NIGHT
			and ctx.king.ability_ticks_left() == 0
			and not ctx.king.is_down()
			and (
				ShotScenarios._enemies_near(ctx, here, ctx.king.get_weapon().slam_radius)
				>= SLAM_MIN_ENEMIES
			)
		)
	if not ShotScenarios._fast_forward(map_root, bot, among):
		printerr(
			(
				"no slam had %d enemies in reach (%s)"
				% [SLAM_MIN_ENEMIES, ShotScenarios._state_line(ctx)]
			)
		)
		return false
	# The ring lives a quarter of a second and a frame on a slow renderer (CI) is long, so the key
	# is held only until the ring exists and the shot follows a short timer (one frame on CI).
	var vfx: SlamVfx = map_root.get_node("SlamVfx") as SlamVfx
	var made: Callable = func() -> bool: return vfx.active_ring_count() > 0
	Input.action_press(&"ability")
	var ringed: bool = await ShotScenarios._wait_until(runner, made, RING_TIMEOUT_S)
	Input.action_release(&"ability")
	await ShotScenarios._wait(runner, SLAM_RING_WAIT_S)
	if not ringed:
		printerr("no slam ring is showing")
	return ringed


## Builds both squads and waits until all eight puppets stand.
static func _raise_squads(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	var built: bool = (
		ShotScenarios._submit_ok(ctx, BuildIntent.new(BARRACKS))
		and ShotScenarios._submit_ok(ctx, BuildIntent.new(ARCHERY))
	)
	if not built:
		return false
	var views: UnitViews = map_root.get_node("UnitViews") as UnitViews
	var raised: Callable = func() -> bool: return views.view_count() >= 8
	var up: bool = await ShotScenarios._wait_until(runner, raised, RAISE_TIMEOUT_S)
	if not up:
		printerr("the squads did not stand (%d puppets)" % views.view_count())
	return up


## The bot of the night scenes with no towers: the two military buildings, two Houses, and both
## squads told to hold at the start of every night while the king idles at the keep.
static func _hold_bot() -> PlaytestBot:
	var bot: PlaytestBot = PlaytestBot.new()
	var order: Array[StringName] = [BARRACKS, ARCHERY, &"house_1", &"house_2"]
	bot.build_order = order
	bot.king_mode = PlaytestBot.KING_IDLE_AT_CASTLE
	bot.night_orders = [{"squads": BOTH, "verb": SquadOrder.VERB_HOLD}]
	return bot


static func _squad_down_and_king_hurt(ctx: RunContext, lowest: int, highest: int) -> bool:
	var health: int = ctx.king.get_health()
	return (
		ctx.run_manager.get_phase() == RunManager.RunPhase.NIGHT
		and _any_squad_down(ctx)
		and health >= lowest
		and health <= highest
		and not ctx.king.is_down()
	)


static func _any_squad_down(ctx: RunContext) -> bool:
	for squad_id: StringName in BOTH:
		if ctx.squads.alive_count(squad_id) == 0:
			return true
	return false


static func _select(map_root: MapRoot, ids: Array[StringName]) -> void:
	var all_ids: Array[StringName] = map_root.get_context().squads.squad_ids()
	map_root.get_selection().select_only(ids, all_ids)


static func _strip_has_slots(map_root: MapRoot, count: int) -> bool:
	var strip: SquadStrip = (
		ShotScenarios._hud(map_root).find_child("SquadStrip", true, false) as SquadStrip
	)
	var ok: bool = strip != null and strip.slot_count() == count
	if not ok:
		printerr("the strip does not hold %d slots" % count)
	return ok


## Puts the king at `point` and waits for the smoothed camera to catch up.
static func _stand(runner: Node, map_root: MapRoot, point: Vector3) -> void:
	map_root.get_king().global_position = point
	await ShotScenarios._wait(runner, SETTLE_S)


## The viewport pixel of a ground point, through the camera the player sees.
static func _screen_of(map_root: MapRoot, ground: Vector3) -> Vector2:
	var camera: Camera3D = map_root.get_viewport().get_camera_3d()
	return camera.unproject_position(ground)


## The screen rectangle around every unit of both squads, kept inside the window.
static func _squads_rect(map_root: MapRoot) -> Rect2:
	var ctx: RunContext = map_root.get_context()
	var views: UnitViews = map_root.get_node("UnitViews") as UnitViews
	var low: Vector2 = Vector2(INF, INF)
	var high: Vector2 = Vector2(-INF, -INF)
	for squad_id: StringName in BOTH:
		for unit_id: int in ctx.squads.unit_ids_of(squad_id):
			var at: Vector2 = _screen_of(map_root, views.puppet_position(unit_id))
			low = low.min(at)
			high = high.max(at)
	var margin: Vector2 = Vector2(POINT_MARGIN_PX, POINT_MARGIN_PX)
	var bounds: Rect2 = map_root.get_viewport().get_visible_rect().grow(-POINT_MARGIN_PX / 2.0)
	var start: Vector2 = (low - margin).max(bounds.position)
	var finish: Vector2 = (high + margin).min(bounds.end)
	return Rect2(start, finish - start)


static func _mouse_motion(at: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	Input.parse_input_event(event)


static func _mouse_button(index: MouseButton, pressed: bool, at: Vector2) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = index
	event.pressed = pressed
	event.position = at
	event.global_position = at
	if pressed:
		event.button_mask = (
			MOUSE_BUTTON_MASK_LEFT if index == MOUSE_BUTTON_LEFT else MOUSE_BUTTON_MASK_RIGHT
		)
	Input.parse_input_event(event)


static func _pad_button(button: JoyButton, pressed: bool) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)


static func _pad_axis(axis: JoyAxis, value: float) -> void:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)
