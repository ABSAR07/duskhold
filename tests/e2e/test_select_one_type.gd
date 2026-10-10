extends GutTest
## INPT-01, INPT-02, UNIT-09, D-10, D-12: select one type, by the mouse double-click and by the pad
## (LB + R3). Phase 3's map has one footman squad, so a double-click on a footman could not be told
## from a single click there. This test runs on a test-local copy of the squad fixture with a second
## barracks (barracks_2, 6 m from barracks_1) so the clicked squad's type has two squads: a single
## click selects one, and the double-click flag on the press selects both, a result a single click
## cannot produce. The shipped map and the fixture are unchanged (D-03). Pointer events are pushed
## into a 1280x720 SubViewport at the screen point a unit projects to (see test_squad_selection).

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const BARRACKS: StringName = &"barracks_1"
const BARRACKS_TWO: StringName = &"barracks_2"
const ARCHERY: StringName = &"archery_1"
const SETTLE_FRAMES: int = 3
const RAISE_TIMEOUT_S: float = 2.0
const CAMERA_SETTLE_FRAMES: int = 30
const KING_SPOT := Vector3(-8.0, 0.0, 0.0)
const VIEW_SIZE := Vector2i(1280, 720)
## Free ground 6 m from barracks_1 at (-10, 0, -4), clear of every other spot.
const SECOND_OFFSET := Vector3(0.0, 0.0, -6.0)

var _view: SubViewport
var _map: MapRoot
var _ctx: RunContext
var _views: UnitViews
var _camera: Camera3D
var _selection: SelectionModel


func after_each() -> void:
	E2eSupport.release_all_actions()


## The squad fixture with barracks_1's spot duplicated as barracks_2 and appended last.
func _two_barracks_map() -> MapConfig:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	var first: BuildSpotDef = null
	for spot: BuildSpotDef in map.spots:
		if spot.id == BARRACKS:
			first = spot
	var second: BuildSpotDef = first.duplicate(true) as BuildSpotDef
	second.id = BARRACKS_TWO
	second.position = first.position + SECOND_OFFSET
	map.spots.append(second)
	return map


func _setup() -> void:
	var map: MapConfig = _two_barracks_map()
	assert_eq(map.validate(), PackedStringArray(), "the copy passes MapConfig.validate()")
	_view = SubViewport.new()
	_view.size = VIEW_SIZE
	add_child_autofree(_view)
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	_map = scene.instantiate()
	_map.map_config = map
	_map.fixed_run_seed = 1
	_map.handle_results_actions = false
	_view.add_child(_map)
	await wait_process_frames(SETTLE_FRAMES)
	_ctx = _map.get_context()
	_views = _map.get_node("UnitViews")
	for spot_id: StringName in [BARRACKS, BARRACKS_TWO, ARCHERY]:
		assert_eq(_ctx.commands.submit(BuildIntent.new(spot_id)), CommandProcessor.OK, "build")
	var raised: Callable = func() -> bool: return _views.view_count() == 12
	assert_true(await E2eSupport.wait_until(self, raised, RAISE_TIMEOUT_S), "twelve puppets")
	E2eSupport.teleport_king(_map, KING_SPOT)
	await wait_process_frames(CAMERA_SETTLE_FRAMES)
	_camera = _view.get_camera_3d()
	_selection = _map.get_selection()


func _unit_point(squad: StringName) -> Vector2:
	var unit_id: int = _ctx.squads.unit_ids_of(squad)[0]
	return _camera.unproject_position(_views.puppet_position(unit_id))


func _mouse(position: Vector2, pressed: bool, double: bool = false) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	event.global_position = position
	event.double_click = double
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	_view.push_input(event)


func _pad(button: JoyButton, pressed: bool) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)


func _tap_pad(button: JoyButton) -> void:
	_pad(button, true)
	await wait_process_frames(2)
	_pad(button, false)
	await wait_process_frames(2)


func test_a_double_click_on_a_footman_selects_both_footman_squads_and_not_the_archers() -> void:
	await _setup()
	_selection.select_only([ARCHERY] as Array[StringName], _ctx.squads.squad_ids())
	var footman: Vector2 = _unit_point(BARRACKS)
	_mouse(footman, true)
	await wait_process_frames(1)
	_mouse(footman, false)
	await wait_process_frames(2)
	assert_eq(_selection.selected(), [BARRACKS] as Array[StringName], "a single click: one squad")
	_mouse(footman, true, true)
	await wait_process_frames(1)
	_mouse(footman, false)
	await wait_process_frames(2)
	assert_eq(
		_selection.selected(),
		[BARRACKS, BARRACKS_TWO] as Array[StringName],
		"the double-click: both footman squads, a result a single click cannot produce"
	)


func test_lb_and_r3_select_every_squad_of_the_cycled_squads_type_and_r3_alone_selects_all() -> void:
	await _setup()
	var all_ids: Array[StringName] = _ctx.squads.squad_ids()
	_selection.select_only([BARRACKS] as Array[StringName], all_ids)
	await _tap_pad(JOY_BUTTON_RIGHT_STICK)
	assert_eq(_selection.selected(), all_ids, "R3 alone selects all three")
	_selection.select_only([BARRACKS] as Array[StringName], all_ids)
	_pad(JOY_BUTTON_LEFT_SHOULDER, true)
	await wait_process_frames(2)
	await _tap_pad(JOY_BUTTON_RIGHT_STICK)
	_pad(JOY_BUTTON_LEFT_SHOULDER, false)
	await wait_process_frames(2)
	assert_eq(
		_selection.selected(),
		[BARRACKS, BARRACKS_TWO] as Array[StringName],
		"LB + R3 selects both footman squads"
	)
