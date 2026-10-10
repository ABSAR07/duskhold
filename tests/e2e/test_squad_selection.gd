extends GutTest
## UNIT-09, D-10, D-11, D-16: mouse selection in the real scene on the squad fixture, both squads
## built, laid out in a 1280x720 SubViewport. Events are pushed into that viewport with push_input
## at the screen point a unit projects to: the GUT output panel covers the root window and would
## take a click aimed at the HUD, and the root window is stretched from 64 px in the headless
## runner, so a SubViewport is the one place pointer coordinates are exact. A left click within
## 32 px of a unit selects its squad, Ctrl + click toggles, a double-click selects every squad of
## the same unit type, a click on empty ground clears, a click on a squad slot selects that squad,
## and a HUD control set to STOP swallows the click. Selected units wear a ring and the squad slot
## shows the selected border.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const BARRACKS: StringName = &"barracks_1"
const ARCHERY: StringName = &"archery_1"
const SELECTED_BORDER := Color("#8CEBFF")
const HOVER_BORDER := Color("#C8CCD4")
const IDLE_BORDER := Color("#3A3F4B")
const SETTLE_FRAMES: int = 3
const RAISE_TIMEOUT_S: float = 2.0
const KING_SPOT := Vector3(-8.0, 0.0, 0.0)
## Ground well clear of every unit, between the squads and the castle.
const EMPTY_SPOT := Vector3(-1.0, 0.0, 0.0)
const CAMERA_SETTLE_FRAMES: int = 30
const SAFE_MARGIN_PX: float = 60.0
const BLOCKER_SIZE := Vector2(140.0, 140.0)
const VIEW_SIZE := Vector2i(1280, 720)

var _view: SubViewport
var _map: MapRoot
var _ctx: RunContext
var _views: UnitViews
var _camera: Camera3D
var _selection: SelectionModel
var _rings: SelectionRings
var _strip: SquadStrip


func after_each() -> void:
	E2eSupport.release_all_actions()


## The real scene with both squads built, their puppets up and the camera settled on the king, who
## stands between the two squads.
func _setup() -> void:
	_view = SubViewport.new()
	_view.size = VIEW_SIZE
	add_child_autofree(_view)
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	_map = scene.instantiate()
	_map.map_config = load(FIXTURE)
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
	_strip = _map.find_child("SquadStrip", true, false) as SquadStrip
	assert_not_null(_selection, "the map owns a SelectionModel")
	assert_not_null(_rings, "the scene has SelectionRings")
	assert_not_null(_strip, "the HUD has the squad strip")


func _unit_point(squad: StringName, index: int = 0) -> Vector2:
	var unit_id: int = _ctx.squads.unit_ids_of(squad)[index]
	return _camera.unproject_position(_views.puppet_position(unit_id))


func _empty_point() -> Vector2:
	return _camera.unproject_position(EMPTY_SPOT)


func _mouse(position: Vector2, pressed: bool, ctrl: bool = false, double: bool = false) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	event.global_position = position
	event.ctrl_pressed = ctrl
	event.double_click = double
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	_view.push_input(event)


func _click(position: Vector2, ctrl: bool = false, double: bool = false) -> void:
	_mouse(position, true, ctrl, double)
	await wait_process_frames(1)
	_mouse(position, false, ctrl)
	await wait_process_frames(2)


func _selected() -> Array[StringName]:
	return _selection.selected()


func test_a_click_on_a_footman_selects_its_squad_and_rings_its_units() -> void:
	await _setup()
	assert_eq(_rings.ring_count(), 0, "no ring before a selection")
	await _click(_unit_point(BARRACKS))
	assert_eq(_selected(), [BARRACKS] as Array[StringName], "the barracks squad")
	assert_eq(_rings.ring_count(), 4, "one ring per footman")
	var slot: SquadSlot = _strip.slot_for(BARRACKS)
	assert_true(slot.is_selected(), "its slot is selected")
	assert_eq(slot.border_color(), SELECTED_BORDER, "with the selected border")
	assert_false(_strip.slot_for(ARCHERY).is_selected(), "the other slot is not")


func test_ctrl_click_adds_a_squad_and_ctrl_click_again_removes_it() -> void:
	await _setup()
	await _click(_unit_point(BARRACKS))
	await _click(_unit_point(ARCHERY), true)
	assert_eq(_selected(), [BARRACKS, ARCHERY] as Array[StringName], "both, in creation order")
	assert_eq(_rings.ring_count(), 8, "four footmen and four archers")
	await _click(_unit_point(ARCHERY), true)
	assert_eq(_selected(), [BARRACKS] as Array[StringName], "the archers are removed")
	assert_eq(_rings.ring_count(), 4, "back to four rings")
	assert_false(_strip.slot_for(ARCHERY).is_selected(), "and the slot lets go")


func test_a_double_click_selects_every_squad_of_that_unit_type() -> void:
	await _setup()
	await _click(_unit_point(ARCHERY))
	assert_eq(_selected(), [ARCHERY] as Array[StringName], "the archers first")
	var footman: Vector2 = _unit_point(BARRACKS)
	_mouse(footman, true)
	await wait_process_frames(1)
	_mouse(footman, false)
	await wait_process_frames(1)
	_mouse(footman, true, false, true)
	await wait_process_frames(1)
	_mouse(footman, false)
	await wait_process_frames(2)
	assert_eq(_selected(), [BARRACKS] as Array[StringName], "every footman squad, and no archers")
	assert_eq(_rings.ring_count(), 4, "four rings")


func test_a_click_on_empty_ground_clears_the_selection() -> void:
	await _setup()
	await _click(_unit_point(BARRACKS))
	var empty: Vector2 = _empty_point()
	for squad: StringName in [BARRACKS, ARCHERY]:
		for index: int in range(4):
			assert_gt(empty.distance_to(_unit_point(squad, index)), 32.0 + SAFE_MARGIN_PX, "empty")
	await _click(empty)
	assert_eq(_selected(), [] as Array[StringName], "nothing selected")
	assert_eq(_rings.ring_count(), 0, "no rings")
	assert_false(_strip.slot_for(BARRACKS).is_selected(), "no slot selected")


func test_ctrl_click_on_empty_ground_keeps_the_selection() -> void:
	await _setup()
	await _click(_unit_point(BARRACKS))
	await _click(_empty_point(), true)
	assert_eq(_selected(), [BARRACKS] as Array[StringName], "still selected")


func test_a_click_on_a_squad_slot_selects_that_squad() -> void:
	await _setup()
	var archery_slot: SquadSlot = _strip.slot_for(ARCHERY)
	await _click(archery_slot.get_global_rect().get_center())
	assert_eq(_selected(), [ARCHERY] as Array[StringName], "the archery squad")
	assert_eq(_rings.ring_count(), 4, "its four archers are ringed")
	await _click(_strip.slot_for(BARRACKS).get_global_rect().get_center(), true)
	assert_eq(_selected(), [BARRACKS, ARCHERY] as Array[StringName], "ctrl adds the other")
	await _click(archery_slot.get_global_rect().get_center())
	assert_eq(_selected(), [ARCHERY] as Array[StringName], "a plain click selects only it")


func test_a_click_on_a_stop_control_never_reaches_the_selection() -> void:
	await _setup()
	var footman: Vector2 = _unit_point(BARRACKS)
	var layer: CanvasLayer = CanvasLayer.new()
	var blocker: Panel = Panel.new()
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.position = footman - BLOCKER_SIZE * 0.5
	blocker.size = BLOCKER_SIZE
	layer.add_child(blocker)
	_map.add_child(layer)
	await wait_process_frames(2)
	await _click(footman)
	assert_eq(_selected(), [] as Array[StringName], "the STOP control took the click")
	await _click(_unit_point(ARCHERY))
	assert_eq(_selected(), [ARCHERY] as Array[StringName], "a click beside it still selects")


func test_hovering_a_slot_draws_the_grey_border_and_selected_keeps_the_cyan_one() -> void:
	await _setup()
	var slot: SquadSlot = _strip.slot_for(BARRACKS)
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = slot.get_global_rect().get_center()
	motion.global_position = motion.position
	_view.push_input(motion)
	await wait_process_frames(2)
	assert_eq(slot.border_color(), HOVER_BORDER, "hover draws the secondary-text border")
	await _click(slot.get_global_rect().get_center())
	assert_eq(slot.border_color(), SELECTED_BORDER, "selected wins over hover")
	motion.position = _empty_point()
	motion.global_position = motion.position
	_view.push_input(motion)
	await wait_process_frames(2)
	assert_eq(slot.border_color(), SELECTED_BORDER, "and stays after the pointer leaves")
	await _click(_empty_point())
	assert_eq(slot.border_color(), IDLE_BORDER, "cleared, the slot is idle again")
