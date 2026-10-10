extends GutTest
## UNIT-09, D-10, D-13: box selection in the real scene on the squad fixture, both squads built,
## laid out in a 1280x720 SubViewport (see test_squad_selection for why). A left press on the
## ground followed by motion of more than 8 px draws the drag box; the release selects every squad
## with a unit inside it (Ctrl adds); a drag over empty ground clears the selection (Ctrl keeps it);
## Escape or a right click mid-drag cancels; a press on a HUD slot never starts a drag; a drag
## released where there is no ground under it is dropped like a cancel; no case shows a toast.
## While the box is up the hover preview is suppressed.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const BARRACKS: StringName = &"barracks_1"
const ARCHERY: StringName = &"archery_1"
const BOTH: Array[StringName] = [&"barracks_1", &"archery_1"]
const SETTLE_FRAMES: int = 3
const RAISE_TIMEOUT_S: float = 2.0
const KING_SPOT := Vector3(-8.0, 0.0, 0.0)
const CAMERA_SETTLE_FRAMES: int = 30
const VIEW_SIZE := Vector2i(1280, 720)
const BOX_MARGIN_PX: float = 24.0
## Ground clear of every unit, between the squads and the castle.
const EMPTY_SPOT := Vector3(-1.0, 0.0, 0.0)
const EMPTY_BOX_HALF_PX: float = 30.0
const FILL := Color(0.549, 0.9216, 1.0, 0.16)
const BORDER := Color(0.549, 0.9216, 1.0, 0.9)
## On the ground of the small map (x, z within 5 m of the origin).
const INSIDE_SMALL := Vector3(-3.0, 0.0, 1.0)
## Well beyond 5 m but still on screen.
const BEYOND_SMALL := Vector3(-12.0, 0.0, 7.0)

var _view: SubViewport
var _map: MapRoot
var _ctx: RunContext
var _views: UnitViews
var _camera: Camera3D
var _selection: SelectionModel
var _rings: SelectionRings
var _pointer: SelectionController
var _strip: SquadStrip
var _box: DragBox
var _toast: Toast
var _ordered: int = 0


func after_each() -> void:
	E2eSupport.release_all_actions()


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
	_views = _map.get_node("UnitViews")
	assert_eq(_ctx.commands.submit(BuildIntent.new(BARRACKS)), CommandProcessor.OK, "barracks")
	assert_eq(_ctx.commands.submit(BuildIntent.new(ARCHERY)), CommandProcessor.OK, "range")
	var raised: Callable = func() -> bool: return _views.view_count() == 8
	assert_true(await E2eSupport.wait_until(self, raised, RAISE_TIMEOUT_S), "eight puppets")
	E2eSupport.teleport_king(_map, KING_SPOT)
	await wait_process_frames(CAMERA_SETTLE_FRAMES)
	_camera = _view.get_camera_3d()
	_selection = _map.get_selection()
	_rings = _map.get_node_or_null("SelectionRings") as SelectionRings
	_pointer = _map.get_node_or_null("SelectionController") as SelectionController
	_strip = _map.find_child("SquadStrip", true, false) as SquadStrip
	_box = _map.find_child("DragBox", true, false) as DragBox
	_toast = _map.find_child("Toast", true, false) as Toast
	assert_not_null(_box, "the HUD has a DragBox")
	assert_not_null(_pointer, "the scene has the SelectionController")
	_ordered = 0
	_ctx.events.squad_ordered.connect(
		func(_id: StringName, _verb: StringName, _queued: bool, _points: Array) -> void:
			_ordered += 1
	)


func _unit_point(squad: StringName, index: int = 0) -> Vector2:
	var unit_id: int = _ctx.squads.unit_ids_of(squad)[index]
	return _camera.unproject_position(_views.puppet_position(unit_id))


## The screen rectangle around every unit of `squads`, grown by BOX_MARGIN_PX.
func _bounds_of(squads: Array[StringName]) -> Rect2:
	var rect: Rect2 = Rect2(_unit_point(squads[0]), Vector2.ZERO)
	for squad: StringName in squads:
		for index: int in range(_ctx.squads.unit_ids_of(squad).size()):
			rect = rect.expand(_unit_point(squad, index))
	return rect.grow(BOX_MARGIN_PX)


func _empty_rect() -> Rect2:
	var centre: Vector2 = _camera.unproject_position(EMPTY_SPOT)
	return Rect2(centre, Vector2.ZERO).grow(EMPTY_BOX_HALF_PX)


func _button(position: Vector2, index: MouseButton, pressed: bool, ctrl: bool = false) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = index
	event.pressed = pressed
	event.position = position
	event.global_position = position
	event.ctrl_pressed = ctrl
	event.button_mask = (
		(MOUSE_BUTTON_MASK_LEFT if index == MOUSE_BUTTON_LEFT else MOUSE_BUTTON_MASK_RIGHT)
		if pressed
		else 0
	)
	_view.push_input(event)


func _press(at: Vector2, ctrl: bool = false) -> void:
	_button(at, MOUSE_BUTTON_LEFT, true, ctrl)
	await wait_process_frames(1)


func _move(to: Vector2, ctrl: bool = false) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = to
	event.global_position = to
	event.ctrl_pressed = ctrl
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	_view.push_input(event)
	await wait_process_frames(2)


func _release(at: Vector2, ctrl: bool = false) -> void:
	_button(at, MOUSE_BUTTON_LEFT, false, ctrl)
	await wait_process_frames(2)


## A whole drag: press at one corner, move there in three steps, release at the other.
func _drag(rect: Rect2, ctrl: bool = false) -> void:
	await _press(rect.position, ctrl)
	await _move(rect.position.lerp(rect.end, 0.5), ctrl)
	await _move(rect.end, ctrl)
	await _release(rect.end, ctrl)


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await wait_process_frames(2)
	Input.action_release(action)
	await wait_process_frames(2)


func test_motion_of_seven_pixels_is_a_click_and_nine_pixels_is_a_drag() -> void:
	await _setup()
	_selection.select_only(BOTH, _ctx.squads.squad_ids())
	var start: Vector2 = _camera.unproject_position(EMPTY_SPOT)
	await _press(start)
	await _move(start + Vector2(7.0, 0.0))
	assert_false(_box.visible, "7 px is still a click")
	await _release(start + Vector2(7.0, 0.0))
	assert_false(_box.visible, "no box after the click")
	assert_true(_selection.selected().is_empty(), "a click on empty ground clears")
	await _press(start)
	await _move(start + Vector2(9.0, 0.0))
	assert_true(_box.visible, "9 px starts the box")
	assert_true(_box.is_dragging(), "and it says so")
	await _release(start + Vector2(9.0, 0.0))
	assert_false(_box.visible, "the release hides it")
	assert_false(_box.is_dragging(), "and ends the drag")


func test_the_box_follows_the_cursor_with_its_corners_in_either_order() -> void:
	await _setup()
	var start: Vector2 = _camera.unproject_position(EMPTY_SPOT)
	assert_false(_box.visible, "hidden before a drag")
	await _press(start)
	await _move(start + Vector2(60.0, 40.0))
	assert_eq(_box.get_global_rect().position, start, "anchored at the press")
	assert_eq(_box.get_global_rect().size, Vector2(60.0, 40.0), "to the cursor")
	await _move(start + Vector2(-50.0, -30.0))
	assert_eq(_box.get_global_rect().position, start + Vector2(-50.0, -30.0), "up and left")
	assert_eq(_box.get_global_rect().size, Vector2(50.0, 30.0), "a positive size")
	await _release(start + Vector2(-50.0, -30.0))
	assert_false(_box.visible, "gone after the release")


func test_the_box_is_drawn_in_the_ui_spec_colours_and_ignores_the_mouse() -> void:
	await _setup()
	assert_eq(_box.mouse_filter, Control.MOUSE_FILTER_IGNORE, "it never takes a click")
	var style: StyleBoxFlat = _box.get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_not_null(style, "a flat style")
	assert_eq(style.bg_color, FILL, "fill #8CEBFF at 0.16")
	assert_eq(style.border_color, BORDER, "border #8CEBFF at 0.9")
	assert_eq(style.border_width_left, 2, "2 px border")
	assert_eq(style.corner_radius_top_left, 0, "no radius")


func test_a_drag_over_both_squads_selects_both() -> void:
	await _setup()
	await _drag(_bounds_of(BOTH))
	assert_eq(_selection.selected(), BOTH, "both squads, creation order")
	assert_eq(_rings.ring_count(), 8, "eight rings")
	assert_false(_box.visible, "the box is gone")


func test_a_drag_over_only_the_archers_selects_the_archery_squad() -> void:
	await _setup()
	_selection.select_only([BARRACKS] as Array[StringName], _ctx.squads.squad_ids())
	await _drag(_bounds_of([ARCHERY] as Array[StringName]))
	assert_eq(_selection.selected(), [ARCHERY] as Array[StringName], "replaces the selection")


func test_ctrl_adds_the_dragged_squads_to_the_selection() -> void:
	await _setup()
	_selection.select_only([BARRACKS] as Array[StringName], _ctx.squads.squad_ids())
	await _drag(_bounds_of([ARCHERY] as Array[StringName]), true)
	assert_eq(_selection.selected(), BOTH, "the barracks stays, the archers join")


func test_a_drag_over_empty_ground_clears_and_with_ctrl_leaves_it_alone() -> void:
	await _setup()
	_selection.select_only(BOTH, _ctx.squads.squad_ids())
	await _drag(_empty_rect(), true)
	assert_eq(_selection.selected(), BOTH, "Ctrl leaves the selection unchanged")
	await _drag(_empty_rect())
	assert_true(_selection.selected().is_empty(), "without Ctrl the selection clears")


func test_escape_mid_drag_cancels_it_and_changes_nothing() -> void:
	await _setup()
	_selection.select_only([BARRACKS] as Array[StringName], _ctx.squads.squad_ids())
	var rect: Rect2 = _bounds_of(BOTH)
	await _press(rect.position)
	await _move(rect.end)
	assert_true(_box.visible, "the box is up")
	await _tap(&"command_cancel")
	assert_false(_box.visible, "Escape hides it")
	assert_eq(_selection.selected(), [BARRACKS] as Array[StringName], "the selection is as it was")
	await _release(rect.end)
	assert_eq(_selection.selected(), [BARRACKS] as Array[StringName], "the release selects nothing")
	assert_eq(_toast.current_text(), "", "no toast")


func test_a_right_click_mid_drag_cancels_it_and_orders_nothing() -> void:
	await _setup()
	_selection.select_only([BARRACKS] as Array[StringName], _ctx.squads.squad_ids())
	var rect: Rect2 = _bounds_of(BOTH)
	await _press(rect.position)
	await _move(rect.end)
	_button(rect.end, MOUSE_BUTTON_RIGHT, true)
	await wait_process_frames(2)
	_button(rect.end, MOUSE_BUTTON_RIGHT, false)
	await wait_process_frames(2)
	assert_false(_box.visible, "the right click hides it")
	assert_eq(_ordered, 0, "and is not a move order")
	await _release(rect.end)
	assert_eq(_selection.selected(), [BARRACKS] as Array[StringName], "nothing changed")


func test_a_press_on_a_squad_slot_never_starts_a_drag() -> void:
	await _setup()
	var slot_centre: Vector2 = _strip.slot_for(BARRACKS).get_global_rect().get_center()
	await _press(slot_centre)
	await _move(slot_centre + Vector2(0.0, -120.0))
	assert_false(_box.visible, "the STOP slot took the press")
	await _move(slot_centre + Vector2(200.0, -200.0))
	assert_false(_box.visible, "still no box")
	await _release(slot_centre + Vector2(200.0, -200.0))
	assert_false(_box.visible, "and none after")


func test_a_press_while_attack_move_is_armed_does_not_start_a_drag() -> void:
	await _setup()
	_selection.select_only(BOTH, _ctx.squads.squad_ids())
	await _tap(&"squad_attack_move")
	assert_true(_pointer.is_armed(), "attack-move waits for its click")
	var start: Vector2 = _camera.unproject_position(EMPTY_SPOT)
	await _press(start)
	await _move(start + Vector2(80.0, 60.0))
	assert_false(_box.visible, "the armed click is not a drag")


func test_a_drag_released_beyond_the_ground_selects_nothing_and_shows_no_toast() -> void:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	map.ground_half_extent = 5.0
	await _setup(map)
	_selection.select_only([BARRACKS] as Array[StringName], _ctx.squads.squad_ids())
	var start: Vector2 = _camera.unproject_position(INSIDE_SMALL)
	var beyond: Vector2 = _camera.unproject_position(BEYOND_SMALL)
	assert_true(_view.get_visible_rect().has_point(beyond), "the far point is on screen")
	await _press(start)
	await _move(beyond.lerp(start, 0.5))
	assert_true(_box.visible, "the box is up while dragging")
	await _move(beyond)
	await _release(beyond)
	assert_false(_box.visible, "the box disappears")
	assert_eq(_selection.selected(), [BARRACKS] as Array[StringName], "the selection is as it was")
	assert_eq(_toast.current_text(), "", "no toast")
	assert_eq(_ordered, 0, "no order")


func test_hover_rings_are_suppressed_while_the_box_is_up_and_return_after() -> void:
	await _setup()
	var start: Vector2 = _camera.unproject_position(EMPTY_SPOT)
	await _press(start)
	await _move(start + Vector2(40.0, 40.0))
	assert_true(_box.visible, "dragging")
	await _move(_unit_point(ARCHERY) + Vector2(6.0, 6.0))
	assert_eq(_pointer.hovered_squad(), &"", "no hover during a drag")
	assert_eq(_rings.hover_ring_count(), 0, "no alpha 0.4 rings")
	await _tap(&"command_cancel")
	assert_false(_box.visible, "the drag is cancelled")
	await wait_process_frames(2)
	assert_eq(_pointer.hovered_squad(), ARCHERY, "the hover returns")
	assert_eq(_rings.hover_ring_count(), 4, "with its rings")
