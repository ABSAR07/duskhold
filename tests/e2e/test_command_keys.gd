extends GutTest
## INPT-01, D-15, UNIT-05, UNIT-06, UNIT-10: the squad verb keys in the real scene on the squad
## fixture, both squads built. F follow, H hold and R rally order the selection; Tab cycles the
## squads and F2 selects them all; a verb with nothing selected issues no order and the toast says
## "Select a squad first". The keys are polled, so scripted Input.action_press drives them. The
## toast is one line in the hint-strip slot; the longest line it will ever show is measured in a
## 1280x720 viewport (UI-SPEC E6).

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const HUD_SCENE := "res://ui/hud/hud.tscn"
const BARRACKS: StringName = &"barracks_1"
const ARCHERY: StringName = &"archery_1"
const LONGEST_TOAST := "Can't go there. Click a point on the visible ground."
const BASE_SIZE := Vector2i(1280, 720)
const SETTLE_FRAMES: int = 3
const RAISE_TIMEOUT_S: float = 2.0
const TOAST_FONT_SIZE: int = 22
const TOAST_MAX_WIDTH: float = 512.0
const TOAST_SLOT_TOP: float = 504.0
const TOAST_SLOT_BOTTOM: float = 536.0
const CENTRE_X: float = 640.0
const CENTRE_TOLERANCE_PX: float = 1.0
const SAFE_LEFT: float = 384.0
const SAFE_RIGHT: float = 896.0

var _map: MapRoot
var _ctx: RunContext
var _selection: SelectionModel
var _toast: Toast
var _ordered: Array[Array] = []


func after_each() -> void:
	Engine.time_scale = 1.0
	E2eSupport.release_all_actions()


func _setup() -> void:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	_map = scene.instantiate()
	_map.map_config = load(FIXTURE)
	_map.fixed_run_seed = 1
	_map.handle_results_actions = false
	add_child_autofree(_map)
	await wait_process_frames(SETTLE_FRAMES)
	_ctx = _map.get_context()
	var views: UnitViews = _map.get_node("UnitViews")
	assert_eq(_ctx.commands.submit(BuildIntent.new(BARRACKS)), CommandProcessor.OK, "barracks")
	assert_eq(_ctx.commands.submit(BuildIntent.new(ARCHERY)), CommandProcessor.OK, "range")
	var raised: Callable = func() -> bool: return views.view_count() == 8
	assert_true(await E2eSupport.wait_until(self, raised, RAISE_TIMEOUT_S), "eight puppets")
	_selection = _map.get_selection()
	_toast = _map.find_child("Toast", true, false) as Toast
	assert_not_null(_toast, "the HUD has a Toast")
	_ordered = []
	_ctx.events.squad_ordered.connect(
		func(squad_id: StringName, verb: StringName, queued: bool, points: Array) -> void:
			_ordered.append([squad_id, verb, queued, points])
	)


## One press of an action: down for two frames, released, two more frames.
func _tap(action: StringName) -> void:
	Input.action_press(action)
	await wait_process_frames(2)
	Input.action_release(action)
	await wait_process_frames(2)


func _select(ids: Array[StringName]) -> void:
	_selection.select_only(ids, _ctx.squads.squad_ids())


func test_hold_orders_the_selected_squad_to_hold() -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	await _tap(&"squad_hold")
	assert_eq(_ordered.size(), 1, "one order")
	assert_eq(_ordered[0][0], BARRACKS, "for the barracks")
	assert_eq(_ordered[0][1], SquadOrder.VERB_HOLD, "to hold")
	assert_eq(_ctx.squads.resting_stance(BARRACKS), SquadOrder.STANCE_HOLD, "and it holds")
	assert_eq(_ctx.squads.resting_stance(ARCHERY), SquadOrder.STANCE_POST, "the other did not")


func test_follow_orders_the_selected_squad_to_follow_the_king() -> void:
	await _setup()
	_select([ARCHERY] as Array[StringName])
	await _tap(&"squad_follow")
	assert_eq(_ordered.size(), 1, "one order")
	assert_eq(_ordered[0][1], SquadOrder.VERB_FOLLOW, "follow")
	assert_eq(_ctx.squads.resting_stance(ARCHERY), SquadOrder.STANCE_FOLLOW, "and it follows")
	assert_eq(_ctx.squads.anchor_of(ARCHERY), _ctx.king.get_position(), "round the king")


func test_rally_walks_the_selected_squad_to_the_king() -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	await _tap(&"squad_rally")
	assert_eq(_ordered.size(), 1, "one order")
	assert_eq(_ordered[0][1], SquadOrder.VERB_RALLY, "rally")
	assert_eq(_ctx.squads.anchor_of(BARRACKS), _ctx.king.get_position(), "the anchor is the king")
	assert_eq(_ordered[0][3], [_ctx.king.get_position()], "and the order carries that point")


func test_a_verb_orders_every_selected_squad_in_creation_order() -> void:
	await _setup()
	_select([ARCHERY, BARRACKS] as Array[StringName])
	await _tap(&"squad_hold")
	assert_eq(_ordered.size(), 2, "two orders")
	assert_eq(_ordered[0][0], BARRACKS, "the barracks first")
	assert_eq(_ordered[1][0], ARCHERY, "then the range")


func test_a_verb_with_nothing_selected_issues_no_order_and_says_so() -> void:
	await _setup()
	for action: StringName in [&"squad_follow", &"squad_hold", &"squad_rally"]:
		_toast.clear_line()
		await _tap(action)
		assert_eq(_ordered.size(), 0, "%s with nothing selected orders nothing" % action)
		assert_eq(_toast.current_text(), Toast.SELECT_FIRST, "%s shows the toast" % action)
	assert_eq(Toast.SELECT_FIRST, "Select a squad first", "the UI-SPEC copy")


func test_cycle_selects_one_squad_at_a_time_in_creation_order_and_wraps() -> void:
	await _setup()
	await _tap(&"squad_cycle")
	assert_eq(_selection.selected(), [BARRACKS] as Array[StringName], "the barracks first")
	await _tap(&"squad_cycle")
	assert_eq(_selection.selected(), [ARCHERY] as Array[StringName], "then the range")
	await _tap(&"squad_cycle")
	assert_eq(_selection.selected(), [BARRACKS] as Array[StringName], "and round again")


func test_select_all_selects_every_squad_in_creation_order() -> void:
	await _setup()
	await _tap(&"select_all")
	assert_eq(_selection.selected(), [BARRACKS, ARCHERY] as Array[StringName], "both squads")


func test_fast_forward_still_toggles_at_night_on_its_action() -> void:
	await _setup()
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	await wait_process_frames(2)
	await _tap(&"fast_forward")
	assert_gt(Engine.time_scale, 1.0, "the first press switches fast-forward on")
	await _tap(&"fast_forward")
	assert_eq(Engine.time_scale, 1.0, "the second switches it off")


func test_a_second_toast_replaces_the_first_and_only_one_line_shows() -> void:
	await _setup()
	_toast.show_toast("First")
	_toast.show_toast("Second")
	assert_eq(_toast.current_text(), "Second", "the newer toast replaced the older")
	assert_eq(_toast.get_line_count(), 1, "one line")


func test_a_toast_ends_and_the_armed_line_returns() -> void:
	await _setup()
	_toast.set_line("Click a point")
	assert_eq(_toast.current_text(), "Click a point", "the line shows")
	_toast.show_toast("Heads up", 0.05)
	assert_eq(_toast.current_text(), "Heads up", "a toast replaces the line while it lasts")
	await wait_seconds(0.8)
	assert_eq(_toast.current_text(), "Click a point", "and the line comes back")
	_toast.clear_line()
	assert_eq(_toast.current_text(), "", "clearing it hides it")


func test_the_longest_toast_is_one_centred_line_in_the_hint_slot() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = BASE_SIZE
	add_child_autofree(viewport)
	var hud: Node = load(HUD_SCENE).instantiate()
	viewport.add_child(hud)
	await wait_process_frames(SETTLE_FRAMES)
	var toast: Toast = hud.find_child("Toast", true, false) as Toast
	assert_not_null(toast, "the HUD has a Toast")
	if toast == null:
		return
	toast.show_error(LONGEST_TOAST)
	await wait_process_frames(SETTLE_FRAMES)
	assert_eq(toast.current_text(), LONGEST_TOAST, "the line shows")
	assert_eq(toast.get_line_count(), 1, "on one line")
	var font: Font = toast.get_theme_font(&"font")
	assert_eq(toast.get_theme_font_size(&"font_size"), TOAST_FONT_SIZE, "Body 22")
	var text_width: float = (
		font.get_string_size(LONGEST_TOAST, HORIZONTAL_ALIGNMENT_LEFT, -1.0, TOAST_FONT_SIZE).x
	)
	assert_lte(text_width, TOAST_MAX_WIDTH, "about 460 px, never past 512")
	var rect: Rect2 = toast.get_global_rect()
	assert_almost_eq(rect.get_center().x, CENTRE_X, CENTRE_TOLERANCE_PX, "centred on x 640")
	assert_gte(rect.position.x, SAFE_LEFT, "inside x 384")
	assert_lte(rect.end.x, SAFE_RIGHT, "inside x 896")
	assert_almost_eq(rect.position.y, TOAST_SLOT_TOP, CENTRE_TOLERANCE_PX, "slot top y 504")
	assert_almost_eq(rect.end.y, TOAST_SLOT_BOTTOM, CENTRE_TOLERANCE_PX, "slot bottom y 536")
