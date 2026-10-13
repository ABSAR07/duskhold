extends GutTest
## INPT-02, UNIT-10, D-12, T-03-15: the pad's right-stick ground cursor in the real scene on the
## squad fixture, laid out in a 1280x720 SubViewport (see test_mouse_commands). Holding LB and a
## D-pad button that needs a ground point (up move, right attack-move, down patrol) shows the cursor
## on the king; the right stick moves it, zoom is suppressed while it is up, and letting go of the
## D-pad button confirms: one order at the ground point in whole centimetres, queued when the right
## trigger is held. B cancels with no order and keeps the selection. Over ground the map does not
## have the release gives no order and the "Can't go there" toast. Pad events go through
## Input.parse_input_event as joypad buttons and motions.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const BARRACKS: StringName = &"barracks_1"
const ARCHERY: StringName = &"archery_1"
const SETTLE_FRAMES: int = 3
const RAISE_TIMEOUT_S: float = 2.0
const KING_SPOT := Vector3(-8.0, 0.0, 0.0)
const CAMERA_SETTLE_S: float = 1.5
const VIEW_SIZE := Vector2i(1280, 720)
const START_TOLERANCE_PX: float = 3.0
const POINT_TOLERANCE_M: float = 0.011
const MARGIN: float = SpawnTelegraph.EDGE_MARGIN_PX
const AIM_SECONDS: float = 0.3
const CLAMP_SECONDS: float = 1.5
const ZOOM_SECONDS: float = 0.5
const SMALL_EXTENT_M: float = 5.0

var _view: SubViewport
var _map: MapRoot
var _ctx: RunContext
var _camera: Camera3D
var _selection: SelectionModel
var _toast: Toast
var _rig: CameraRig
var _cursor: PadCursorController
var _cursor_view: PadCursorView
var _ordered: Array[Array] = []


func after_each() -> void:
	Engine.time_scale = 1.0
	E2eSupport.release_all_actions()
	for button: JoyButton in [
		JOY_BUTTON_LEFT_SHOULDER,
		JOY_BUTTON_DPAD_UP,
		JOY_BUTTON_DPAD_DOWN,
		JOY_BUTTON_DPAD_RIGHT,
		JOY_BUTTON_B,
	]:
		_pad(button, false)
	for axis: JoyAxis in [JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y, JOY_AXIS_TRIGGER_RIGHT]:
		_stick(axis, 0.0)


func _setup(map: MapConfig = null, select: bool = true) -> void:
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
	await wait_seconds(CAMERA_SETTLE_S)
	_camera = _view.get_camera_3d()
	_selection = _map.get_selection()
	_toast = _map.find_child("Toast", true, false) as Toast
	_rig = _map.get_node("CameraRig") as CameraRig
	_cursor = _map.get_node_or_null("PadCursorController") as PadCursorController
	_cursor_view = _map.get_node_or_null("PadCursorView") as PadCursorView
	assert_not_null(_cursor, "the scene has a PadCursorController")
	assert_not_null(_cursor_view, "the scene has a PadCursorView")
	if select:
		_selection.select_only([BARRACKS] as Array[StringName], _ctx.squads.squad_ids())
	_ordered = []
	_ctx.events.squad_ordered.connect(
		func(squad_id: StringName, verb: StringName, queued: bool, points: Array) -> void:
			_ordered.append([squad_id, verb, queued, points])
	)


func _pad(button: JoyButton, pressed: bool) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)


func _stick(axis: JoyAxis, value: float) -> void:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)


## LB held, then the D-pad button down: the cursor appears (the LB layer turns the D-pad into the
## point verbs). The buttons stay down until the test lets go.
func _hold_point_verb(button: JoyButton) -> void:
	_pad(JOY_BUTTON_LEFT_SHOULDER, true)
	await wait_process_frames(2)
	_pad(button, true)
	await wait_process_frames(3)


func _let_go(button: JoyButton) -> void:
	_pad(button, false)
	await wait_process_frames(3)
	_pad(JOY_BUTTON_LEFT_SHOULDER, false)
	await wait_process_frames(2)


func _king_screen() -> Vector2:
	var king: Vector3 = _map.get_king().global_position
	return _camera.unproject_position(Vector3(king.x, 0.0, king.z))


func _point_of(order: Array) -> Vector2:
	return (order[3] as Array)[0] as Vector2


func test_holding_lb_and_d_pad_up_shows_the_cursor_on_the_king_and_the_line() -> void:
	await _setup()
	assert_false(_cursor_view.is_visible_cursor(), "no cursor before the button")
	await _hold_point_verb(JOY_BUTTON_DPAD_UP)
	assert_true(_cursor.is_active(), "the cursor is up")
	assert_true(_cursor_view.is_visible_cursor(), "and drawn")
	var start: Vector2 = _king_screen()
	assert_almost_eq(
		_cursor.cursor_position().x, start.x, START_TOLERANCE_PX, "starts on the king x"
	)
	assert_almost_eq(
		_cursor.cursor_position().y, start.y, START_TOLERANCE_PX, "starts on the king y"
	)
	assert_eq(_toast.current_text(), Toast.ARMED_PAD, "the line says how to aim")
	assert_eq(_ordered.size(), 0, "holding orders nothing")
	await _let_go(JOY_BUTTON_DPAD_UP)


func test_the_right_stick_moves_the_cursor_and_zoom_is_suppressed_until_release() -> void:
	await _setup()
	await _hold_point_verb(JOY_BUTTON_DPAD_UP)
	var start: Vector2 = _cursor.cursor_position()
	var start_ground: Vector3 = _cursor_view.cursor_ground()
	_stick(JOY_AXIS_RIGHT_X, 1.0)
	await wait_seconds(AIM_SECONDS)
	_stick(JOY_AXIS_RIGHT_X, 0.0)
	await wait_process_frames(2)
	assert_gt(_cursor.cursor_position().x, start.x + 100.0, "the stick moved it right")
	assert_almost_eq(_cursor.cursor_position().y, start.y, 1.0, "and not up or down")
	assert_ne(_cursor_view.cursor_ground(), start_ground, "the drawn ring followed it")
	assert_gt(_cursor_view.line_length(), 0.5, "the line runs from the king to the ring")
	var zoom: float = _rig.get_zoom()
	_stick(JOY_AXIS_RIGHT_Y, 1.0)
	await wait_seconds(ZOOM_SECONDS)
	_stick(JOY_AXIS_RIGHT_Y, 0.0)
	assert_almost_eq(_rig.get_zoom(), zoom, 0.0001, "zoom is suppressed while the cursor is up")
	await _let_go(JOY_BUTTON_DPAD_UP)
	_stick(JOY_AXIS_RIGHT_Y, 1.0)
	await wait_seconds(ZOOM_SECONDS)
	_stick(JOY_AXIS_RIGHT_Y, 0.0)
	assert_gt(_rig.get_zoom(), zoom + 0.01, "zoom works again after the release")


func test_releasing_d_pad_up_orders_a_move_at_the_cursor_ground_point_in_centimetres() -> void:
	await _setup()
	await _hold_point_verb(JOY_BUTTON_DPAD_UP)
	_stick(JOY_AXIS_RIGHT_X, 1.0)
	_stick(JOY_AXIS_RIGHT_Y, -1.0)
	await wait_seconds(AIM_SECONDS)
	_stick(JOY_AXIS_RIGHT_X, 0.0)
	_stick(JOY_AXIS_RIGHT_Y, 0.0)
	await wait_process_frames(3)
	var ground: Vector3 = _cursor_view.cursor_ground()
	var cm: Vector2i = GroundPick.to_centimetres(ground)
	assert_eq(_ordered.size(), 0, "nothing is ordered while it is held")
	await _let_go(JOY_BUTTON_DPAD_UP)
	assert_eq(_ordered.size(), 1, "one order for the selected squad")
	assert_eq(_ordered[0][0], BARRACKS, "for the barracks squad")
	assert_eq(_ordered[0][1], SquadOrder.VERB_MOVE, "a move")
	assert_false(_ordered[0][2], "not queued")
	var point: Vector2 = _point_of(_ordered[0])
	assert_almost_eq(point.x, float(cm.x) / 100.0, POINT_TOLERANCE_M, "x in whole centimetres")
	assert_almost_eq(point.y, float(cm.y) / 100.0, POINT_TOLERANCE_M, "z in whole centimetres")
	assert_false(_cursor.is_active(), "the cursor is gone")
	assert_false(_cursor_view.is_visible_cursor(), "and hidden")
	assert_eq(_toast.current_text(), "", "and the aiming line cleared")
	assert_eq(_selection.selected(), [BARRACKS] as Array[StringName], "the selection is kept")


func test_d_pad_right_orders_attack_move_and_d_pad_down_a_patrol_with_one_point() -> void:
	await _setup()
	await _hold_point_verb(JOY_BUTTON_DPAD_RIGHT)
	_stick(JOY_AXIS_RIGHT_X, 1.0)
	await wait_seconds(AIM_SECONDS)
	_stick(JOY_AXIS_RIGHT_X, 0.0)
	await _let_go(JOY_BUTTON_DPAD_RIGHT)
	assert_eq(_ordered.size(), 1, "one order")
	assert_eq(_ordered[0][1], SquadOrder.VERB_ATTACK_MOVE, "attack-move")
	assert_eq((_ordered[0][3] as Array).size(), 1, "one point")
	await _hold_point_verb(JOY_BUTTON_DPAD_DOWN)
	_stick(JOY_AXIS_RIGHT_X, -1.0)
	await wait_seconds(AIM_SECONDS)
	_stick(JOY_AXIS_RIGHT_X, 0.0)
	await _let_go(JOY_BUTTON_DPAD_DOWN)
	assert_eq(_ordered.size(), 2, "a second order")
	assert_eq(_ordered[1][1], SquadOrder.VERB_PATROL, "patrol")
	assert_eq((_ordered[1][3] as Array).size(), 1, "with one point")


func test_the_right_trigger_held_at_release_queues_the_order() -> void:
	await _setup()
	await _hold_point_verb(JOY_BUTTON_DPAD_UP)
	_stick(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await wait_process_frames(2)
	await _let_go(JOY_BUTTON_DPAD_UP)
	_stick(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	assert_eq(_ordered.size(), 1, "one order")
	assert_true(_ordered[0][2], "queued")
	await _hold_point_verb(JOY_BUTTON_DPAD_UP)
	await _let_go(JOY_BUTTON_DPAD_UP)
	assert_eq(_ordered.size(), 2, "a second order")
	assert_false(_ordered[1][2], "not queued without the trigger")


func test_the_right_trigger_behind_a_queued_hold_is_refused_and_the_toast_says_so() -> void:
	await _setup()
	await _hold_point_verb(JOY_BUTTON_DPAD_UP)
	await _let_go(JOY_BUTTON_DPAD_UP)
	var none: Array[Vector2i] = []
	var hold: SquadOrderIntent = SquadOrderIntent.new(
		[BARRACKS] as Array[StringName], SquadOrder.VERB_HOLD, none, true
	)
	assert_eq(_ctx.commands.submit(hold), CommandProcessor.OK, "a hold waits behind the walk")
	_ordered = []
	await _hold_point_verb(JOY_BUTTON_DPAD_UP)
	_stick(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await wait_process_frames(2)
	await _let_go(JOY_BUTTON_DPAD_UP)
	_stick(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	assert_eq(_ordered.size(), 0, "nothing was queued")
	assert_eq(_toast.current_text(), Toast.QUEUE_CLOSED, "the toast says why")


func test_b_while_held_hides_the_cursor_orders_nothing_and_keeps_the_selection() -> void:
	await _setup()
	await _hold_point_verb(JOY_BUTTON_DPAD_UP)
	assert_true(_cursor.is_active(), "the cursor is up")
	_pad(JOY_BUTTON_B, true)
	await wait_process_frames(3)
	_pad(JOY_BUTTON_B, false)
	assert_false(_cursor.is_active(), "B put the cursor away")
	assert_false(_cursor_view.is_visible_cursor(), "and hid it")
	assert_eq(_toast.current_text(), "", "and the aiming line cleared")
	await _let_go(JOY_BUTTON_DPAD_UP)
	assert_eq(_ordered.size(), 0, "letting go afterwards orders nothing")
	assert_eq(
		_selection.selected(), [BARRACKS] as Array[StringName], "B did not clear the selection"
	)
	var zoom: float = _rig.get_zoom()
	_stick(JOY_AXIS_RIGHT_Y, 1.0)
	await wait_seconds(ZOOM_SECONDS)
	_stick(JOY_AXIS_RIGHT_Y, 0.0)
	assert_gt(_rig.get_zoom(), zoom + 0.01, "zoom is back")


func test_the_cursor_stays_inside_the_screen_edge() -> void:
	await _setup()
	await _hold_point_verb(JOY_BUTTON_DPAD_UP)
	_stick(JOY_AXIS_RIGHT_X, 1.0)
	_stick(JOY_AXIS_RIGHT_Y, 1.0)
	await wait_seconds(CLAMP_SECONDS)
	assert_almost_eq(
		_cursor.cursor_position().x, VIEW_SIZE.x - MARGIN, 0.01, "48 px from the right"
	)
	assert_almost_eq(
		_cursor.cursor_position().y, VIEW_SIZE.y - MARGIN, 0.01, "48 px from the bottom"
	)
	_stick(JOY_AXIS_RIGHT_X, -1.0)
	_stick(JOY_AXIS_RIGHT_Y, -1.0)
	await wait_seconds(CLAMP_SECONDS * 2.0)
	assert_almost_eq(_cursor.cursor_position().x, MARGIN, 0.01, "48 px from the left")
	assert_almost_eq(_cursor.cursor_position().y, MARGIN, 0.01, "48 px from the top")
	_stick(JOY_AXIS_RIGHT_X, 0.0)
	_stick(JOY_AXIS_RIGHT_Y, 0.0)
	await _let_go(JOY_BUTTON_DPAD_UP)
	assert_eq(_ordered.size(), 1, "a clamped cursor still lands on the ground")


func test_releasing_over_ground_the_map_does_not_have_gives_no_order_and_says_so() -> void:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	map.ground_half_extent = SMALL_EXTENT_M
	await _setup(map)
	await _hold_point_verb(JOY_BUTTON_DPAD_UP)
	assert_true(_cursor.is_active(), "the cursor starts on the king, 8 m out")
	await _let_go(JOY_BUTTON_DPAD_UP)
	assert_eq(_ordered.size(), 0, "no order")
	assert_false(_cursor.is_active(), "the cursor is gone")
	assert_false(_cursor_view.is_visible_cursor(), "and hidden")
	assert_eq(_toast.current_text(), Toast.CANT_GO_THERE, "the toast says why")


func test_with_nothing_selected_the_cursor_never_starts() -> void:
	await _setup(null, false)
	await _hold_point_verb(JOY_BUTTON_DPAD_UP)
	assert_false(_cursor.is_active(), "no cursor")
	assert_false(_cursor_view.is_visible_cursor(), "nothing drawn")
	assert_eq(_toast.current_text(), Toast.SELECT_FIRST, "the toast says what to do")
	await _let_go(JOY_BUTTON_DPAD_UP)
	assert_eq(_ordered.size(), 0, "and no order")
