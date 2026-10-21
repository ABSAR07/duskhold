class_name ShotEconomyScenarios
extends RefCounted
## The Phase 5 scenes of `tools/screenshot.sh` (plan 05-04): the four ability cards above the castle
## with card 2 raised, and the tier IV keep with its three picks on the label. They follow the
## rules of ShotScenarios: every scene reaches its state through the command intents and the
## Input Map, never by writing simulation state. Later Phase 5 plans append their shots here.

const CASTLE: StringName = &"castle_plot"
const ECONOMY_SHOTS: Array[StringName] = [
	ShotScenarios.CASTLE_CARDS,
	ShotScenarios.CASTLE_TIER_FOUR,
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
static func map_for(_shot_name: StringName) -> MapConfig:
	var shipped: MapConfig = load(ShotScenarios.MAP_DATA_PATH)
	var config: MapConfig = shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	config.starting_gold = SHOT_GOLD
	return config


static func run(shot_name: StringName, runner: Node, map_root: MapRoot) -> bool:
	match shot_name:
		ShotScenarios.CASTLE_CARDS:
			return await _castle_cards(runner, map_root)
		ShotScenarios.CASTLE_TIER_FOUR:
			return await _castle_tier_four(runner, map_root)
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
