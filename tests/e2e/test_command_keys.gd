extends GutTest
## INPT-01, D-15, UNIT-05, UNIT-06, UNIT-10: the squad verb keys in the real scene on the squad
## fixture, both squads built. F follow, H hold and R rally order the selection; Tab cycles the
## squads and F2 selects them all; a verb with nothing selected issues no order and the toast says
## "Select a squad first". The keys are polled, so scripted Input.action_press drives them. The
## toast is one line in the hint-strip slot; the longest line it will ever show is measured in a
## 1280x720 viewport (UI-SPEC E6). The UI-SPEC estimated that line at about 460 px; Godot's default
## font measures it at 526 px at size 22, so the check is on what the estimate was for: one line,
## centred on x 640, wholly below the protected centre (its bottom edge is y 500) and within half
## the screen width.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const HUD_SCENE := "res://ui/hud/hud.tscn"
const BARRACKS: StringName = &"barracks_1"
const ARCHERY: StringName = &"archery_1"
const QUEUE_ACTION: StringName = &"command_queue"
const MAX_ARRIVAL_STEPS: int = 3000
const ARRIVE_TOLERANCE_M: float = 0.01
const LONGEST_TOAST := "Can't go there. Click a point on the visible ground."
const BASE_SIZE := Vector2i(1280, 720)
const SETTLE_FRAMES: int = 3
const RAISE_TIMEOUT_S: float = 2.0
const TOAST_FONT_SIZE: int = 22
const TOAST_MAX_WIDTH: float = 640.0
const TOAST_SLOT_TOP: float = 504.0
const TOAST_SLOT_BOTTOM: float = 536.0
const CENTRE_X: float = 640.0
const CENTRE_TOLERANCE_PX: float = 1.0
const PROTECTED_RECT := Rect2(384.0, 96.0, 512.0, 404.0)

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


## The verbs of the squad's queue, the running order first.
func _verbs_of(squad_id: StringName) -> Array[StringName]:
	var verbs: Array[StringName] = []
	for order: Dictionary in _ctx.squads.orders_of(squad_id):
		verbs.append(order["verb"])
	return verbs


## Queues three walks of 4 m each from the squad's anchor, the first replacing the queue and the
## next two queued (as Shift right-clicks do), and returns the third point in metres. The event
## recorder is cleared afterwards so the test reads only the order it gives next.
func _queue_three_moves(squad_id: StringName) -> Vector2:
	var anchor: Vector2 = _ctx.squads.anchor_of(squad_id)
	var base: Vector2i = Vector2i(roundi(anchor.x * 100.0), roundi(anchor.y * 100.0))
	var legs: Array[Vector2i] = [
		base + Vector2i(400, 0), base + Vector2i(400, 400), base + Vector2i(0, 400)
	]
	for index: int in range(legs.size()):
		var points: Array[Vector2i] = [legs[index]]
		var intent: SquadOrderIntent = SquadOrderIntent.new(
			[squad_id] as Array[StringName], SquadOrder.VERB_MOVE, points, index > 0
		)
		assert_eq(_ctx.commands.submit(intent), CommandProcessor.OK, "leg %d" % index)
	_ordered = []
	return Vector2(legs[2]) / 100.0


## One press of an action with the queue key (Shift) held down for it.
func _tap_queued(action: StringName) -> void:
	Input.action_press(QUEUE_ACTION)
	await _tap(action)
	Input.action_release(QUEUE_ACTION)


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


func test_shift_hold_after_three_queued_moves_waits_behind_the_walks() -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	var last_point: Vector2 = _queue_three_moves(BARRACKS)
	await _tap_queued(&"squad_hold")
	assert_eq(_ordered.size(), 1, "one order")
	assert_eq(_ordered[0][1], SquadOrder.VERB_HOLD, "a hold")
	assert_true(_ordered[0][2], "marked queued")
	var expected: Array[StringName] = [
		SquadOrder.VERB_MOVE, SquadOrder.VERB_MOVE, SquadOrder.VERB_MOVE, SquadOrder.VERB_HOLD
	]
	assert_eq(_verbs_of(BARRACKS), expected, "the hold waits behind the three walks")
	assert_eq(_ctx.squads.resting_stance(BARRACKS), SquadOrder.STANCE_HOLD, "and it will hold")
	var steps: int = 0
	while not _ctx.squads.orders_of(BARRACKS).is_empty() and steps < MAX_ARRIVAL_STEPS:
		_ctx.step()
		steps += 1
	assert_true(_ctx.squads.orders_of(BARRACKS).is_empty(), "the walks ended")
	assert_eq(_ctx.squads.resting_stance(BARRACKS), SquadOrder.STANCE_HOLD, "and the squad holds")
	var held: Vector2 = _ctx.squads.anchor_of(BARRACKS)
	assert_almost_eq(held.x, last_point.x, ARRIVE_TOLERANCE_M, "at the last point, x")
	assert_almost_eq(held.y, last_point.y, ARRIVE_TOLERANCE_M, "at the last point, z")


func test_hold_without_shift_still_clears_the_queue_and_holds_at_the_centroid() -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	_queue_three_moves(BARRACKS)
	await _tap(&"squad_hold")
	assert_eq(_ordered.size(), 1, "one order")
	assert_eq(_ordered[0][1], SquadOrder.VERB_HOLD, "a hold")
	assert_false(_ordered[0][2], "not queued")
	assert_true(_ctx.squads.orders_of(BARRACKS).is_empty(), "the walks are gone")
	assert_eq(_ctx.squads.resting_stance(BARRACKS), SquadOrder.STANCE_HOLD, "and it holds at once")
	await _tap_queued(&"squad_hold")
	assert_eq(_ordered.size(), 2, "Shift+H on an empty queue is an order too")
	assert_true(_ordered[1][2], "marked queued")
	assert_true(_ctx.squads.orders_of(BARRACKS).is_empty(), "nothing waits, the hold ran at once")
	assert_eq(_ctx.squads.resting_stance(BARRACKS), SquadOrder.STANCE_HOLD, "and it holds")


func test_shift_follow_and_shift_rally_queue_behind_the_walks() -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	_queue_three_moves(BARRACKS)
	await _tap_queued(&"squad_follow")
	assert_eq(_ordered.size(), 1, "one order")
	assert_eq(_ordered[0][1], SquadOrder.VERB_FOLLOW, "a follow")
	assert_true(_ordered[0][2], "marked queued")
	var follow_queue: Array[StringName] = [
		SquadOrder.VERB_MOVE, SquadOrder.VERB_MOVE, SquadOrder.VERB_MOVE, SquadOrder.VERB_FOLLOW
	]
	assert_eq(_verbs_of(BARRACKS), follow_queue, "the follow waits behind the walks")
	assert_eq(_ctx.squads.resting_stance(BARRACKS), SquadOrder.STANCE_FOLLOW, "and it will follow")
	_select([ARCHERY] as Array[StringName])
	_queue_three_moves(ARCHERY)
	await _tap_queued(&"squad_rally")
	assert_eq(_ordered.size(), 1, "one order")
	assert_eq(_ordered[0][0], ARCHERY, "for the range")
	assert_eq(_ordered[0][1], SquadOrder.VERB_RALLY, "a rally")
	assert_true(_ordered[0][2], "marked queued")
	var rally_queue: Array[StringName] = [
		SquadOrder.VERB_MOVE,
		SquadOrder.VERB_MOVE,
		SquadOrder.VERB_MOVE,
		SquadOrder.VERB_MOVE,
		SquadOrder.VERB_HOLD,
	]
	assert_eq(_verbs_of(ARCHERY), rally_queue, "the rally is a move to the king then a hold")
	var orders: Array[Dictionary] = _ctx.squads.orders_of(ARCHERY)
	assert_eq(orders.size(), rally_queue.size(), "five entries")
	if orders.size() > 3:
		assert_eq(orders[3]["points"], [_ctx.king.get_position()], "the fourth walk is to the king")
	assert_eq(_ctx.squads.resting_stance(ARCHERY), SquadOrder.STANCE_HOLD, "and it ends holding")


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
	assert_lte(text_width, TOAST_MAX_WIDTH, "the longest line fits within half the screen")
	var rect: Rect2 = toast.get_global_rect()
	assert_almost_eq(rect.get_center().x, CENTRE_X, CENTRE_TOLERANCE_PX, "centred on x 640")
	assert_false(rect.intersects(PROTECTED_RECT), "clear of the protected centre")
	assert_almost_eq(rect.position.y, TOAST_SLOT_TOP, CENTRE_TOLERANCE_PX, "slot top y 504")
	assert_almost_eq(rect.end.y, TOAST_SLOT_BOTTOM, CENTRE_TOLERANCE_PX, "slot bottom y 536")
