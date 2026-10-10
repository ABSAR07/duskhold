extends GutTest
## UNIT-10, D-10, D-16, D-25: the plan of each selected squad drawn on the ground, and the hover
## preview. Real scene on the squad fixture, both squads built, laid out in a 1280x720 SubViewport
## (see test_squad_selection for why). Orders are submitted straight through the command processor
## so each test names exactly the plan it expects to see. A patrol is a dashed #FFE073 line with
## 0.4 m end discs that flashes for 1.5 s when set; queued orders are numbered 0.4 m discs joined
## by a thin line in the verb colour (cyan move, #FF7A59 attack-move, #FFE073 patrol), the running
## order skipped and at most 6 shown; nothing is drawn for an unselected squad. Hovering within
## 32 px of an unselected squad's unit shows that squad's rings at alpha 0.4.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const BARRACKS: StringName = &"barracks_1"
const ARCHERY: StringName = &"archery_1"
const BOTH: Array[StringName] = [&"barracks_1", &"archery_1"]
const SETTLE_FRAMES: int = 3
const RAISE_TIMEOUT_S: float = 2.0
const KING_SPOT := Vector3(-8.0, 0.0, 0.0)
const CAMERA_SETTLE_FRAMES: int = 30
const VIEW_SIZE := Vector2i(1280, 720)
const MOVE_COLOR := Color("#8CEBFF")
const ATTACK_COLOR := Color("#FF7A59")
const PATROL_COLOR := Color("#FFE073")
const HOVER_ALPHA: float = 0.4
const SELECTED_ALPHA: float = 0.95
## Whole-centimetre points well clear of the units, inside the 90 m ground of the fixture.
const FAR_A := Vector2i(-3000, 3000)
const FAR_B := Vector2i(-3000, -3000)
const FAR_C := Vector2i(3000, -3000)
const FAR_D := Vector2i(3000, 3000)
const PATROL_A := Vector2i(-2000, 1500)
const PATROL_B := Vector2i(-2500, 2500)
const POINT_TOLERANCE_M: float = 0.2
const FLASH_SECONDS: float = 1.5
const FLASH_TIMEOUT_S: float = 4.0
const OFF_SCREEN_CM := Vector2i(6000, 0)
const MAX_ARRIVAL_STEPS: int = 3000
const KILL_DAMAGE: int = 999
const EMPTY_SPOT := Vector3(-1.0, 0.0, 0.0)

var _view: SubViewport
var _map: MapRoot
var _ctx: RunContext
var _views: UnitViews
var _camera: Camera3D
var _selection: SelectionModel
var _markers: OrderMarkers
var _rings: SelectionRings
var _pointer: SelectionController
var _strip: SquadStrip


func after_each() -> void:
	E2eSupport.release_all_actions()


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
	_markers = _map.get_node_or_null("OrderMarkers") as OrderMarkers
	_rings = _map.get_node_or_null("SelectionRings") as SelectionRings
	_pointer = _map.get_node_or_null("SelectionController") as SelectionController
	_strip = _map.find_child("SquadStrip", true, false) as SquadStrip
	assert_not_null(_markers, "the scene has OrderMarkers")
	assert_not_null(_rings, "the scene has SelectionRings")
	assert_not_null(_pointer, "the scene has the SelectionController")


func _order(squad: StringName, verb: StringName, cm: Array[Vector2i], queued: bool = false) -> void:
	var ids: Array[StringName] = [squad]
	assert_eq(
		_ctx.commands.submit(SquadOrderIntent.new(ids, verb, cm, queued)),
		CommandProcessor.OK,
		"the %s order is accepted" % verb
	)


func _motion(position: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	_view.push_input(event)
	await wait_process_frames(2)


func _unit_point(squad: StringName, index: int = 0) -> Vector2:
	var unit_id: int = _ctx.squads.unit_ids_of(squad)[index]
	return _camera.unproject_position(_views.puppet_position(unit_id))


func test_a_patrolling_selected_squad_shows_a_dashed_line_through_its_path() -> void:
	await _setup()
	_selection.select_only([BARRACKS] as Array[StringName], _ctx.squads.squad_ids())
	_order(BARRACKS, SquadOrder.VERB_PATROL, [PATROL_A, PATROL_B] as Array[Vector2i])
	await wait_process_frames(3)
	assert_eq(_markers.patrol_line_count(), 1, "one patrol line")
	assert_eq(_markers.patrol_disc_count(), 2, "a disc at each end")
	var path: Array[Vector2] = _ctx.squads.patrol_path_of(BARRACKS)
	assert_eq(path.size(), 3, "the centroid and the two points")
	var corners: PackedVector3Array = _markers.patrol_line_points(BARRACKS)
	assert_gt(corners.size(), 0, "the line has geometry")
	for waypoint: Vector2 in path:
		var near: bool = false
		for corner: Vector3 in corners:
			if Vector2(corner.x, corner.z).distance_to(waypoint) < POINT_TOLERANCE_M:
				near = true
				break
		assert_true(near, "the line passes through %s" % waypoint)
	_selection.clear()
	await wait_process_frames(2)
	assert_eq(_markers.patrol_line_count(), 0, "deselected, the line is gone")
	assert_eq(_markers.patrol_disc_count(), 0, "and its discs")
	assert_eq(_markers.patrol_line_points(BARRACKS).size(), 0, "with no geometry")


func test_a_new_patrol_flashes_the_line_for_one_and_a_half_seconds() -> void:
	await _setup()
	_selection.select_only([BARRACKS] as Array[StringName], _ctx.squads.squad_ids())
	assert_false(_markers.patrol_flashing(), "nothing flashes before an order")
	_order(BARRACKS, SquadOrder.VERB_PATROL, [PATROL_A, PATROL_B] as Array[Vector2i])
	await wait_process_frames(3)
	assert_true(_markers.patrol_flashing(), "the new patrol flashes")
	var started: int = Time.get_ticks_msec()
	var ended: Callable = func() -> bool: return not _markers.patrol_flashing()
	assert_true(await E2eSupport.wait_until(self, ended, FLASH_TIMEOUT_S), "and stops")
	var elapsed: float = float(Time.get_ticks_msec() - started) / 1000.0
	assert_gt(elapsed, FLASH_SECONDS - 0.5, "after about 1.5 s")
	assert_eq(_markers.patrol_line_count(), 1, "the line itself stays")


func test_three_queued_moves_are_three_numbered_cyan_discs() -> void:
	await _setup()
	_selection.select_only([BARRACKS] as Array[StringName], _ctx.squads.squad_ids())
	_order(BARRACKS, SquadOrder.VERB_MOVE, [FAR_A] as Array[Vector2i])
	assert_eq(_markers.disc_count(), 0, "a lone running order draws no disc")
	_order(BARRACKS, SquadOrder.VERB_MOVE, [FAR_B] as Array[Vector2i], true)
	_order(BARRACKS, SquadOrder.VERB_MOVE, [FAR_C] as Array[Vector2i], true)
	_order(BARRACKS, SquadOrder.VERB_MOVE, [FAR_D] as Array[Vector2i], true)
	await wait_process_frames(3)
	assert_eq(_markers.disc_count(), 3, "the running order is skipped, three wait")
	assert_eq(_markers.disc_labels(), PackedStringArray(["1", "2", "3"]), "numbered 1, 2, 3")
	for color: Color in _markers.disc_colors():
		assert_eq(color.to_html(false), MOVE_COLOR.to_html(false), "moves are cyan")


func test_ten_queued_orders_keep_nine_and_show_six_discs() -> void:
	await _setup()
	_selection.select_only([BARRACKS] as Array[StringName], _ctx.squads.squad_ids())
	_order(BARRACKS, SquadOrder.VERB_MOVE, [FAR_A] as Array[Vector2i])
	for index: int in range(9):
		_order(BARRACKS, SquadOrder.VERB_MOVE, [FAR_B] as Array[Vector2i], true)
	await wait_process_frames(3)
	assert_eq(
		_ctx.squads.orders_of(BARRACKS).size(), SquadOrder.MAX_QUEUE, "the simulation keeps 9"
	)
	assert_eq(OrderMarkers.MAX_DISCS_SHOWN, 6, "the cap is six")
	assert_eq(_markers.disc_count(), OrderMarkers.MAX_DISCS_SHOWN, "at most six are drawn")
	assert_eq(
		_markers.disc_labels(),
		PackedStringArray(["1", "2", "3", "4", "5", "6"]),
		"one-digit numbers"
	)


func test_each_verb_has_its_own_colour() -> void:
	await _setup()
	_selection.select_only([BARRACKS] as Array[StringName], _ctx.squads.squad_ids())
	_order(BARRACKS, SquadOrder.VERB_MOVE, [FAR_A] as Array[Vector2i])
	_order(BARRACKS, SquadOrder.VERB_MOVE, [FAR_B] as Array[Vector2i], true)
	_order(BARRACKS, SquadOrder.VERB_ATTACK_MOVE, [FAR_C] as Array[Vector2i], true)
	_order(BARRACKS, SquadOrder.VERB_PATROL, [FAR_D] as Array[Vector2i], true)
	await wait_process_frames(3)
	var colors: Array[Color] = _markers.disc_colors()
	assert_eq(colors.size(), 3, "three discs wait")
	assert_eq(colors[0].to_html(false), MOVE_COLOR.to_html(false), "move is cyan")
	assert_eq(colors[1].to_html(false), ATTACK_COLOR.to_html(false), "attack-move is #FF7A59")
	assert_eq(colors[2].to_html(false), PATROL_COLOR.to_html(false), "patrol is #FFE073")


func test_nothing_is_drawn_for_an_unselected_squad_or_with_nothing_selected() -> void:
	await _setup()
	_order(BARRACKS, SquadOrder.VERB_MOVE, [FAR_A] as Array[Vector2i])
	_order(BARRACKS, SquadOrder.VERB_MOVE, [FAR_B] as Array[Vector2i], true)
	_order(ARCHERY, SquadOrder.VERB_PATROL, [PATROL_A] as Array[Vector2i])
	await wait_process_frames(3)
	assert_eq(_markers.disc_count(), 0, "nothing selected, no disc")
	assert_eq(_markers.patrol_line_count(), 0, "no line")
	assert_eq(_markers.patrol_disc_count(), 0, "no end disc")
	_selection.select_only([ARCHERY] as Array[StringName], _ctx.squads.squad_ids())
	await wait_process_frames(2)
	assert_eq(
		_markers.disc_count(), 0, "the barracks queue is not drawn while only archers are selected"
	)
	assert_eq(_markers.patrol_line_count(), 1, "the archers' own patrol is")
	_selection.select_only([BARRACKS] as Array[StringName], _ctx.squads.squad_ids())
	await wait_process_frames(2)
	assert_eq(_markers.disc_count(), 1, "the barracks queue shows once it is selected")
	assert_eq(_markers.patrol_line_count(), 0, "and the archers' line is gone")
	_selection.clear()
	await wait_process_frames(2)
	assert_eq(_markers.disc_count(), 0, "cleared again, nothing")
	assert_eq(_markers.patrol_line_count(), 0, "nothing")


func test_hovering_a_squad_previews_its_rings_at_alpha_point_four() -> void:
	await _setup()
	assert_eq(_pointer.hovered_squad(), &"", "nobody hovered at first")
	await _motion(_unit_point(ARCHERY) + Vector2(10.0, 10.0))
	assert_eq(_pointer.hovered_squad(), ARCHERY, "the archers are hovered")
	assert_eq(_rings.hover_ring_count(), 4, "their four rings preview")
	assert_eq(_rings.ring_count(), 0, "nothing is selected")
	assert_almost_eq(_rings.ring_alpha(0), HOVER_ALPHA, 0.001, "at alpha 0.4")
	await _motion(_camera.unproject_position(EMPTY_SPOT))
	assert_eq(_pointer.hovered_squad(), &"", "moving away clears it")
	assert_eq(_rings.hover_ring_count(), 0, "and the rings go")


func test_a_hovered_squad_never_changes_the_selected_squads_colour() -> void:
	await _setup()
	_selection.select_only([BARRACKS] as Array[StringName], _ctx.squads.squad_ids())
	await _motion(_unit_point(ARCHERY))
	assert_eq(_rings.ring_count(), 4, "the selected footmen keep their rings")
	assert_eq(_rings.hover_ring_count(), 4, "the archers add theirs")
	for index: int in range(4):
		assert_almost_eq(_rings.ring_alpha(index), SELECTED_ALPHA, 0.001, "selected stays full")
	for index: int in range(4, 8):
		assert_almost_eq(_rings.ring_alpha(index), HOVER_ALPHA, 0.001, "hover stays faint")
	await _motion(_unit_point(BARRACKS))
	assert_eq(_pointer.hovered_squad(), &"", "a selected squad is not previewed")
	assert_eq(_rings.hover_ring_count(), 0, "no second ring set on a selected squad")
	assert_eq(_rings.ring_count(), 4, "only its own")


func test_a_selected_squad_that_walked_off_screen_keeps_its_slot_and_its_rings() -> void:
	await _setup()
	_selection.select_only([BARRACKS] as Array[StringName], _ctx.squads.squad_ids())
	_order(BARRACKS, SquadOrder.VERB_MOVE, [OFF_SCREEN_CM] as Array[Vector2i])
	var steps: int = 0
	while not _ctx.squads.orders_of(BARRACKS).is_empty() and steps < MAX_ARRIVAL_STEPS:
		_ctx.step()
		steps += 1
	assert_true(_ctx.squads.orders_of(BARRACKS).is_empty(), "the squad arrived")
	await wait_process_frames(10)
	assert_true(_selection.is_selected(BARRACKS), "still selected")
	assert_true(_strip.slot_for(BARRACKS).is_selected(), "its slot stays highlighted")
	assert_eq(_rings.ring_count(), _ctx.squads.unit_ids_of(BARRACKS).size(), "one ring per unit")
	for index: int in range(_rings.ring_count()):
		assert_false(
			_camera.is_position_in_frustum(_rings.ring_position(index)),
			"ring %d is off the screen" % index
		)


func test_a_selected_squad_down_to_one_unit_has_one_ring() -> void:
	await _setup()
	_selection.select_only([BARRACKS] as Array[StringName], _ctx.squads.squad_ids())
	var ids: Array[int] = _ctx.squads.unit_ids_of(BARRACKS)
	assert_eq(ids.size(), 4, "four footmen to begin with")
	for index: int in range(1, ids.size()):
		_ctx.squads.damage_unit(ids[index], KILL_DAMAGE, &"test")
	_ctx.squads.remove_dead()
	await wait_process_frames(5)
	assert_eq(_rings.ring_count(), 1, "one living unit, one ring")
	await wait_process_frames(1)
	_selection.clear()
	await wait_process_frames(2)
	assert_eq(_rings.ring_count(), 0, "zero selected, none")
