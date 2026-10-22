class_name ShotEconomyScenarios
extends RefCounted
## The Phase 5 scenes of `tools/screenshot.sh` (plans 05-04, 05-07, 05-08 and 05-09): the four
## ability cards above the castle with card 2 raised, the tier IV keep with its three picks on the
## label, a Field beside the unbuilt Mill reading "Needs a Mill", the Fishing Harbor on its pond
## with three boats, and an awake Shrine glowing at night with a violet bolt in flight. They follow
## the rules of ShotScenarios: every scene reaches its state through the command intents and the
## Input Map, never by writing simulation state. Later Phase 5 plans append their shots here.

const CASTLE: StringName = &"castle_plot"
## shrine_awake_night runs on the Shrine fixture (two towers and a Shrine beside the west road).
const SHRINE_FIXTURE := "res://tests/fixtures/fixture_map_shrine.tres"
## field_locked: the Field the king stands beside; the Mill plot (mill_1) lies 5 m north of it.
const LOCKED_FIELD: StringName = &"field_2"
const LOCKED_LINE := "Needs a Mill"
## harbor_pond: the Harbor, the dawns that give it boats and where the king stands on its shore.
const POND_HARBOR: StringName = &"harbor_1"
const POND_DAWNS: int = 3
## A timed night and its dawn take a few hundred steps; this bounds the loop if one never ends.
const POND_NIGHT_TICKS: int = 4000
const POND_STAND_OFFSET := Vector3(-2.5, 0.0, 6.5)
## shrine_awake_night: the plots the bot buys on the Shrine fixture, the Shrine, where the king
## stands beside it and how long the real-time capture waits for a bolt in flight.
const SHRINE_SPOT: StringName = &"shrine_1"
const SHRINE_BUILD_ORDER: Array[StringName] = [&"tower_1", &"tower_2", &"shrine_1"]
const SHRINE_STAND_OFFSET := Vector3(3.0, 0.0, 3.0)
const SHRINE_BOLT_TIMEOUT_S: float = 25.0
const ECONOMY_SHOTS: Array[StringName] = [
	ShotScenarios.CASTLE_CARDS,
	ShotScenarios.CASTLE_TIER_FOUR,
	ShotScenarios.FIELD_LOCKED,
	ShotScenarios.HARBOR_POND,
	ShotScenarios.SHRINE_AWAKE_NIGHT,
]
## The gold the Phase 5 shots start with: enough for all three castle upgrades (6 + 10 + 16).
const SHOT_GOLD: int = 60
## The card the castle_cards shot raises: card 2, the second of the tier II row.
const RAISED_CARD_INDEX: int = 1
## The castle_tier_four shot buys the three upgrades with one pick each, in this order.
const TIER_FOUR_PICKS: Array[StringName] = [&"royal_training", &"engineers", &"golden_age"]
const TIER_FOUR_KEEP := "res://presentation/buildings/models/castle_center_t4.tscn"
## The cards show once the king stands at the plot; this long for the row to draw.
const CARDS_TIMEOUT_S: float = 3.0
const SETTLE_S: float = 0.8
## castle_tier_four: the king stands to the side and a little behind the plot (still within the
## 2.5 m reach), so he is clear of the label and the camera, which follows him, shows more of the
## keep.
const KEEP_STAND_OFFSET := Vector3(2.3, 0.0, -0.9)
## castle_tier_four zooms the camera out this long so the whole tall keep is in the frame.
const ZOOM_OUT_S: float = 1.0


## True for the Phase 5 shots.
static func handles(shot_name: StringName) -> bool:
	return ECONOMY_SHOTS.has(shot_name)


## The map copy a Phase 5 shot runs on: a deep copy of the shipped map (DR-12, never the shared
## resource) with the shot gold. Every other field, the nights included, stays as shipped.
static func map_for(shot_name: StringName) -> MapConfig:
	if shot_name == ShotScenarios.SHRINE_AWAKE_NIGHT:
		var fixture: MapConfig = load(SHRINE_FIXTURE)
		var copy: MapConfig = fixture.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
		copy.starting_gold = SHOT_GOLD
		return copy
	var shipped: MapConfig = load(ShotScenarios.MAP_DATA_PATH)
	var config: MapConfig = shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	config.starting_gold = SHOT_GOLD
	if shot_name == ShotScenarios.HARBOR_POND:
		var no_nights: Array[NightDef] = []
		config.nights = no_nights
	return config


static func run(shot_name: StringName, runner: Node, map_root: MapRoot) -> bool:
	match shot_name:
		ShotScenarios.CASTLE_CARDS:
			return await _castle_cards(runner, map_root)
		ShotScenarios.CASTLE_TIER_FOUR:
			return await _castle_tier_four(runner, map_root)
		ShotScenarios.FIELD_LOCKED:
			return await _field_locked(runner, map_root)
		ShotScenarios.HARBOR_POND:
			return await _harbor_pond(runner, map_root)
		ShotScenarios.SHRINE_AWAKE_NIGHT:
			return await _shrine_awake_night(runner, map_root)
	printerr("unknown economy shot %s" % shot_name)
	return false


## By day with the king beside the castle plot and the gold for tier II: four cards float over the
## castle and card 2 is highlighted (raised, brighter, with its numbers line and its key tile).
static func _castle_cards(runner: Node, map_root: MapRoot) -> bool:
	await ShotScenarios._stand_beside(runner, map_root, CASTLE)
	var picker: CardPicker = map_root.get_cards()
	var row: CardRow = map_root.get_node("CardRow") as CardRow
	var shown: Callable = func() -> bool: return picker.is_showing() and row.card_count() == 4
	if not await ShotScenarios._wait_until(runner, shown, CARDS_TIMEOUT_S):
		printerr(
			"the four cards did not show (%s)" % ShotScenarios._state_line(map_root.get_context())
		)
		return false
	picker.set_highlight(RAISED_CARD_INDEX)
	await ShotScenarios._wait(runner, SETTLE_S)
	var ready: bool = (
		picker.highlighted_index() == RAISED_CARD_INDEX
		and row.is_card_raised(RAISED_CARD_INDEX)
		and not row.numbers_text(RAISED_CARD_INDEX).is_empty()
	)
	if not ready:
		printerr("card %d is not raised with its numbers" % (RAISED_CARD_INDEX + 1))
	return ready


## All three castle upgrades bought with one pick each, the keep at its tier IV look, and the king
## beside the plot so the label reads Max tier and lists the three picks.
static func _castle_tier_four(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	for pick: StringName in TIER_FOUR_PICKS:
		if not ShotScenarios._submit_ok(ctx, BuildIntent.new(CASTLE, pick)):
			return false
	var plot: Vector3 = ctx.buildings.get_spot(CASTLE).position
	map_root.get_king().global_position = plot + KEEP_STAND_OFFSET
	Input.action_press(&"zoom_out")
	await ShotScenarios._wait(runner, ZOOM_OUT_S)
	Input.action_release(&"zoom_out")
	await ShotScenarios._wait(runner, ShotScenarios.CAMERA_SETTLE_S)
	var keep: Node3D = map_root.get_node("BuildingViews/CastleCenter") as Node3D
	var picks: Label3D = map_root.find_child("Picks", true, false) as Label3D
	var ready: bool = (
		keep != null
		and keep.get_meta(&"view_source") == TIER_FOUR_KEEP
		and picks != null
		and picks.visible
		and not picks.text.is_empty()
	)
	if not ready:
		printerr("the tier IV keep or its picks line is not showing")
	return ready


## By day with the Mill unbuilt and the king beside the second Field: its label reads "Needs a Mill"
## with no price, and the empty Mill plot and the neighbouring Field plots are in the frame.
static func _field_locked(runner: Node, map_root: MapRoot) -> bool:
	await ShotScenarios._stand_beside(runner, map_root, LOCKED_FIELD)
	await ShotScenarios._wait(runner, SETTLE_S)
	var status: Label3D = map_root.find_child("Status", true, false) as Label3D
	var ready: bool = status != null and status.visible and status.text == LOCKED_LINE
	if not ready:
		printerr("the Field label does not read '%s'" % LOCKED_LINE)
	return ready


## By day with a Fishing Harbor built and three boats on the pond: the Harbor is bought through its
## command, then three timed nights are run the way a replay runs them (the loop steps the
## simulation, nothing writes its state), each dawn giving the Harbor one boat. The king stands on
## the shore and the camera is zoomed out so the whole pond and its dock are in the frame.
static func _harbor_pond(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	if not ShotScenarios._submit_ok(ctx, BuildIntent.new(POND_HARBOR)):
		return false
	for _dawn: int in range(POND_DAWNS):
		if not ShotScenarios._submit_ok(ctx, StartNightIntent.new()):
			return false
		var ticks: int = 0
		while ctx.run_manager.get_phase() != RunManager.RunPhase.DAY and ticks < POND_NIGHT_TICKS:
			ctx.step()
			ticks += 1
	var plot: Vector3 = ctx.buildings.get_spot(POND_HARBOR).position
	map_root.get_king().global_position = plot + POND_STAND_OFFSET
	Input.action_press(&"zoom_out")
	await ShotScenarios._wait(runner, ZOOM_OUT_S)
	Input.action_release(&"zoom_out")
	await ShotScenarios._wait(runner, ShotScenarios.CAMERA_SETTLE_S)
	var pond: PondView = map_root.get_node("PondView") as PondView
	var ready: bool = (
		ctx.run_manager.get_phase() == RunManager.RunPhase.DAY
		and pond != null
		and pond.has_pond()
		and pond.boat_count(POND_HARBOR) == POND_DAWNS
	)
	if not ready:
		printerr(
			"the pond does not show %d boats (%s)" % [POND_DAWNS, ShotScenarios._state_line(ctx)]
		)
	return ready


## The Shrine fixture at night: the bot buys two towers and the Shrine, the loop fast-forwards (the
## way a replay runs it) until the grunts that died beside the Shrine have woken it, and the scene
## then runs in real time until a Shrine bolt is in the air. The king stands beside the Shrine so
## the camera shows its glowing orb, the violet bolt and the road. Nothing writes simulation state.
static func _shrine_awake_night(runner: Node, map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	var plot: Vector3 = ctx.buildings.get_spot(SHRINE_SPOT).position
	var stand: Vector3 = plot + SHRINE_STAND_OFFSET
	map_root.get_king().global_position = stand
	await ShotScenarios._wait(runner, ShotScenarios.CAMERA_SETTLE_S)
	var bot: PlaytestBot = PlaytestBot.new()
	bot.build_order = SHRINE_BUILD_ORDER
	bot.king_mode = PlaytestBot.KING_HOLD_POINT
	bot.hold_point = Vector2(stand.x, stand.z)
	var woke: Callable = func() -> bool:
		return (
			ctx.run_manager.get_phase() == RunManager.RunPhase.NIGHT
			and ctx.income.is_awake(SHRINE_SPOT)
		)
	if not ShotScenarios._fast_forward(map_root, bot, woke):
		printerr("no night woke the Shrine (%s)" % ShotScenarios._state_line(ctx))
		return false
	var vfx: ProjectileVfx = map_root.get_node("ProjectileVfx") as ProjectileVfx
	var firing: Callable = func() -> bool: return _shrine_bolt_drawn(vfx, plot)
	var seen: bool = await ShotScenarios._wait_until(runner, firing, SHRINE_BOLT_TIMEOUT_S)
	if not seen:
		printerr("no Shrine bolt was drawn (%s)" % ShotScenarios._state_line(ctx))
		return false
	var views: BuildingViews = map_root.get_node("BuildingViews") as BuildingViews
	if not views.is_shrine_glowing(SHRINE_SPOT):
		printerr("the awake Shrine does not glow")
		return false
	return true


## True while a drawn bolt leaves from above the Shrine's plot (its launch point is on the plot).
static func _shrine_bolt_drawn(vfx: ProjectileVfx, plot: Vector3) -> bool:
	for index: int in range(vfx.arrow_count()):
		var launch: Vector3 = vfx.arrow_launch_at(index)
		if absf(launch.x - plot.x) < 0.01 and absf(launch.z - plot.z) < 0.01:
			return true
	return false
