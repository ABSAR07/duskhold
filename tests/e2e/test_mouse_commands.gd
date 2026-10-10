extends GutTest
## UNIT-10, INPT-01, D-09, D-11, D-13, D-15, D-25: the point commands in the real scene on the squad
## fixture, both squads built and selected, laid out in a 1280x720 SubViewport (see
## test_squad_selection for why). A right click on the ground orders a move, Shift queues it, the
## attack-move key arms attack-move for the next left click, holding P and right-clicking collects
## patrol points that commit when P is released, and Escape or a right click cancels an armed
## command. Every accepted move, attack-move or rally pings at its point; a point off the ground
## issues nothing, draws no ping and shows "Can't go there. Click a point on the visible ground."
## Keys are polled, so scripted Input.action_press drives them; the mouse is pushed into the
## SubViewport with push_input.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const BARRACKS: StringName = &"barracks_1"
const ARCHERY: StringName = &"archery_1"
const BOTH: Array[StringName] = [&"barracks_1", &"archery_1"]
const SETTLE_FRAMES: int = 3
const RAISE_TIMEOUT_S: float = 2.0
const KING_SPOT := Vector3(-8.0, 0.0, 0.0)
const CAMERA_SETTLE_FRAMES: int = 30
const VIEW_SIZE := Vector2i(1280, 720)
const GROUND_A := Vector3(-4.0, 0.0, 5.0)
const GROUND_B := Vector3(-12.0, 0.0, 6.0)
const GROUND_C := Vector3(-3.0, 0.0, -6.0)
const GROUND_INSIDE_SMALL := Vector3(-3.0, 0.0, 2.0)
const POINT_TOLERANCE_M: float = 0.011
const TOAST_END_TIMEOUT_S: float = 4.0
const CAMERA_CATCH_UP_FRAMES: int = 120
## A command far off the king would pan the camera by metres; this is smoothing noise.
const CAMERA_TOLERANCE_M: float = 0.05
const TOAST_SLOT_TOP: float = 504.0
const TOAST_SLOT_BOTTOM: float = 536.0

var _view: SubViewport
var _map: MapRoot
var _ctx: RunContext
var _camera: Camera3D
var _selection: SelectionModel
var _toast: Toast
var _markers: OrderMarkers
var _pointer: SelectionController
var _ordered: Array[Array] = []


func after_each() -> void:
	E2eSupport.release_all_actions()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


## The real scene with both squads built and their puppets up, the king between them, both squads
## selected. `map` replaces the fixture when a test needs another ground extent.
func _setup(map: MapConfig = null) -> void:
	_view = SubViewport.new()
	_view.size = VIEW_SIZE
	add_child_autofree(_view)
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	_map = scene.instantiate()
	_map.map_config = map if map != null else load(FIXTURE)
	_map.fixed_run_seed = 1
	_map.handle_results_actions = false
	_view.add_child(_map)
	await wait_process_frames(SETTLE_FRAMES)
	_ctx = _map.get_context()
	var views: UnitViews = _map.get_node("UnitViews")
	assert_eq(_ctx.commands.submit(BuildIntent.new(BARRACKS)), CommandProcessor.OK, "barracks")
	assert_eq(_ctx.commands.submit(BuildIntent.new(ARCHERY)), CommandProcessor.OK, "range")
	var raised: Callable = func() -> bool: return views.view_count() == 8
	assert_true(await E2eSupport.wait_until(self, raised, RAISE_TIMEOUT_S), "eight puppets")
	E2eSupport.teleport_king(_map, KING_SPOT)
	await wait_process_frames(CAMERA_SETTLE_FRAMES)
	_camera = _view.get_camera_3d()
	_selection = _map.get_selection()
	_toast = _map.find_child("Toast", true, false) as Toast
	_markers = _map.get_node_or_null("OrderMarkers") as OrderMarkers
	_pointer = _map.get_node_or_null("SelectionController") as SelectionController
	assert_not_null(_toast, "the HUD has a Toast")
	assert_not_null(_markers, "the scene has OrderMarkers")
	_selection.select_only(BOTH, _ctx.squads.squad_ids())
	_ordered = []
	_ctx.events.squad_ordered.connect(
		func(squad_id: StringName, verb: StringName, queued: bool, points: Array) -> void:
			_ordered.append([squad_id, verb, queued, points])
	)


func _screen(ground: Vector3) -> Vector2:
	return _camera.unproject_position(ground)


func _button(
	position: Vector2, index: MouseButton, pressed: bool, mask: MouseButtonMask = 0
) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = index
	event.pressed = pressed
	event.position = position
	event.global_position = position
	event.button_mask = mask if pressed else 0
	_view.push_input(event)


func _right_click(ground: Vector3) -> void:
	var at: Vector2 = _screen(ground)
	_button(at, MOUSE_BUTTON_RIGHT, true, MOUSE_BUTTON_MASK_RIGHT)
	await wait_process_frames(1)
	_button(at, MOUSE_BUTTON_RIGHT, false)
	await wait_process_frames(2)


func _left_click(ground: Vector3) -> void:
	var at: Vector2 = _screen(ground)
	_button(at, MOUSE_BUTTON_LEFT, true, MOUSE_BUTTON_MASK_LEFT)
	await wait_process_frames(1)
	_button(at, MOUSE_BUTTON_LEFT, false)
	await wait_process_frames(2)


## One press of an action: down for two frames, released, two more frames.
func _tap(action: StringName) -> void:
	Input.action_press(action)
	await wait_process_frames(2)
	Input.action_release(action)
	await wait_process_frames(2)


func _point_of(order: Array) -> Vector2:
	return (order[3] as Array)[0] as Vector2


func _assert_point(order: Array, ground: Vector3, label: String) -> void:
	var point: Vector2 = _point_of(order)
	assert_almost_eq(point.x, ground.x, POINT_TOLERANCE_M, "%s x" % label)
	assert_almost_eq(point.y, ground.z, POINT_TOLERANCE_M, "%s z" % label)


func test_a_right_click_on_the_ground_moves_both_selected_squads_there_and_pings() -> void:
	await _setup()
	assert_eq(_markers.active_ping_count(), 0, "no ping before the order")
	await _right_click(GROUND_A)
	assert_eq(_ordered.size(), 2, "one order per squad")
	for order: Array in _ordered:
		assert_eq(order[1], SquadOrder.VERB_MOVE, "a move")
		assert_false(order[2], "not queued")
		_assert_point(order, GROUND_A, "the clicked point")
	assert_eq(_ordered[0][0], BARRACKS, "creation order, barracks first")
	assert_eq(_ordered[1][0], ARCHERY, "then the range")
	assert_gt(_markers.active_ping_count(), 0, "a ping shows where it landed")
	assert_eq(_selection.selected(), BOTH, "the selection is kept")


func test_the_point_is_whole_centimetres_of_the_ground_under_the_cursor() -> void:
	await _setup()
	await _right_click(Vector3(-4.0, 0.0, 5.0))
	var point: Vector2 = _point_of(_ordered[0])
	assert_eq(roundi(point.x * 100.0), -400, "x in centimetres")
	assert_eq(roundi(point.y * 100.0), 500, "z in centimetres")


func test_one_ping_per_point_even_though_two_squads_got_the_order() -> void:
	await _setup()
	await _right_click(GROUND_A)
	assert_eq(_markers.active_ping_count(), 1, "one ping, not two")
	await _right_click(GROUND_B)
	assert_eq(_markers.active_ping_count(), 2, "a second point is a second ping")


func test_shift_with_a_right_click_queues_the_move() -> void:
	await _setup()
	await _right_click(GROUND_A)
	_ordered = []
	Input.action_press(&"command_queue")
	await _right_click(GROUND_B)
	Input.action_release(&"command_queue")
	assert_eq(_ordered.size(), 2, "one order per squad")
	assert_true(_ordered[0][2], "marked queued")
	assert_eq(_ctx.squads.orders_of(BARRACKS).size(), 2, "behind the first move")
	await _right_click(GROUND_C)
	assert_false(_ordered.back()[2], "without Shift the next click is not queued")
	assert_eq(_ctx.squads.orders_of(BARRACKS).size(), 1, "and replaces the queue")


func test_the_attack_move_key_arms_it_and_the_next_left_click_orders_it() -> void:
	await _setup()
	Input.action_press(&"squad_attack_move")
	await wait_process_frames(3)
	Input.action_release(&"squad_attack_move")
	await wait_process_frames(2)
	assert_eq(_toast.current_text(), Toast.ARMED_ATTACK, "the line says what to do")
	assert_eq(_pointer.cursor_shape(), Input.CURSOR_CROSS, "the cursor is a cross")
	assert_eq(_ordered.size(), 0, "arming orders nothing")
	await _left_click(GROUND_A)
	assert_eq(_ordered.size(), 2, "the click orders both squads")
	for order: Array in _ordered:
		assert_eq(order[1], SquadOrder.VERB_ATTACK_MOVE, "attack-move")
		_assert_point(order, GROUND_A, "at the click")
	assert_eq(_selection.selected(), BOTH, "the click did not change the selection")
	assert_eq(_toast.current_text(), "", "the line is gone")
	assert_eq(_pointer.cursor_shape(), Input.CURSOR_ARROW, "the arrow is back")
	assert_gt(_markers.active_ping_count(), 0, "and it pinged")


func test_holding_p_and_right_clicking_collects_a_patrol_that_commits_on_release() -> void:
	await _setup()
	Input.action_press(&"squad_patrol")
	await wait_process_frames(3)
	assert_eq(_toast.current_text(), Toast.ARMED_PATROL, "the line says what to do")
	await _right_click(GROUND_A)
	await _right_click(GROUND_B)
	assert_eq(_ordered.size(), 0, "nothing is ordered while P is held")
	Input.action_release(&"squad_patrol")
	await wait_process_frames(3)
	assert_eq(_ordered.size(), 2, "one patrol per squad")
	for order: Array in _ordered:
		assert_eq(order[1], SquadOrder.VERB_PATROL, "a patrol")
		assert_eq((order[3] as Array).size(), 2, "with the two points")
	_assert_point(_ordered[0], GROUND_A, "the first point")
	assert_almost_eq(
		((_ordered[0][3] as Array)[1] as Vector2).x, GROUND_B.x, POINT_TOLERANCE_M, "x"
	)
	assert_eq(_toast.current_text(), "", "the line is gone")
	assert_eq(_ctx.squads.resting_stance(BARRACKS), SquadOrder.STANCE_PATROL, "they patrol")


func test_releasing_p_with_no_point_orders_nothing() -> void:
	await _setup()
	await _tap(&"squad_patrol")
	assert_eq(_ordered.size(), 0, "no order")
	assert_eq(_toast.current_text(), "", "and no line left behind")


func test_escape_after_arming_issues_nothing_and_clears_the_line() -> void:
	await _setup()
	await _tap(&"squad_attack_move")
	assert_eq(_toast.current_text(), Toast.ARMED_ATTACK, "armed")
	await _tap(&"command_cancel")
	assert_eq(_toast.current_text(), "", "the line is gone")
	assert_eq(_pointer.cursor_shape(), Input.CURSOR_ARROW, "the arrow is back")
	assert_eq(_selection.selected(), BOTH, "the first Escape only cancelled the command")
	await _left_click(GROUND_A)
	assert_eq(_ordered.size(), 0, "a later left click orders nothing")


func test_a_right_click_while_armed_cancels_without_an_order() -> void:
	await _setup()
	await _tap(&"squad_attack_move")
	await _right_click(GROUND_A)
	assert_eq(_ordered.size(), 0, "no move and no attack-move")
	assert_eq(_toast.current_text(), "", "the line is gone")
	assert_eq(_selection.selected(), BOTH, "the selection is kept")


func test_escape_with_nothing_armed_clears_the_selection() -> void:
	await _setup()
	await _tap(&"command_cancel")
	assert_eq(_selection.selected(), [] as Array[StringName], "nothing is selected any more")
	assert_eq(_ordered.size(), 0, "and nothing was ordered")


func test_a_right_click_with_nothing_selected_asks_for_a_selection() -> void:
	await _setup()
	_selection.clear()
	await _right_click(GROUND_A)
	assert_eq(_ordered.size(), 0, "no order")
	assert_eq(_toast.current_text(), Toast.SELECT_FIRST, "the toast says why")
	assert_eq(_markers.active_ping_count(), 0, "and nothing pings")


func test_a_point_outside_the_ground_issues_nothing_pings_nothing_and_says_so() -> void:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	map.ground_half_extent = 5.0
	await _setup(map)
	await _right_click(GROUND_B)
	assert_eq(_ordered.size(), 0, "no order")
	assert_eq(_markers.active_ping_count(), 0, "no ping")
	assert_eq(_toast.current_text(), Toast.CANT_GO_THERE, "the message is the only feedback")
	assert_eq(_toast.current_text(), "Can't go there. Click a point on the visible ground.", "copy")
	await _right_click(GROUND_INSIDE_SMALL)
	assert_eq(_ordered.size(), 2, "a point inside the extent still works")


func test_a_toast_replaces_the_armed_line_and_the_line_returns_after_it() -> void:
	await _setup()
	await _tap(&"squad_attack_move")
	assert_eq(_toast.current_text(), Toast.ARMED_ATTACK, "armed")
	_toast.show_error(Toast.CANT_GO_THERE)
	assert_eq(_toast.current_text(), Toast.CANT_GO_THERE, "the toast alone")
	var rect: Rect2 = _toast.get_global_rect()
	assert_gte(rect.position.y, TOAST_SLOT_TOP, "inside the hint slot, top")
	assert_lte(rect.end.y, TOAST_SLOT_BOTTOM, "inside the hint slot, bottom")
	assert_lte(rect.size.y, TOAST_SLOT_BOTTOM - TOAST_SLOT_TOP, "one line")
	var back: Callable = func() -> bool: return _toast.current_text() == Toast.ARMED_ATTACK
	assert_true(await E2eSupport.wait_until(self, back, TOAST_END_TIMEOUT_S), "the line returns")


func test_the_camera_does_not_move_for_a_command() -> void:
	await _setup()
	await wait_process_frames(CAMERA_CATCH_UP_FRAMES)
	var rig: Node3D = _map.get_node("CameraRig")
	var before: Vector3 = rig.global_position
	await _right_click(GROUND_B)
	await wait_process_frames(10)
	assert_almost_eq(
		rig.global_position.distance_to(before), 0.0, CAMERA_TOLERANCE_M, "the camera stayed put"
	)
