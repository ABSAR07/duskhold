extends GutTest
## UI-02, BLDG-05, D-05, D-07, Pitfall 7 on the real scene (fixed run seed 1, laid out in a 1280x720
## SubViewport so pointer coordinates are exact, see test_squad_selection): pointing the mouse at a
## world-space card highlights it and prints its numbers line; a left click on a card highlights it
## too, is consumed (no drag box, the selected squad stays selected) and never buys or spends; a
## click anywhere else still reaches the selection layer (it clears the selection); the digit keys
## move the highlight after a click; the hold then buys the clicked card. Events are pushed into the
## SubViewport with push_input.

const CASTLE: StringName = &"castle_plot"
const BARRACKS: StringName = &"barracks_1"
const SETTLE_FRAMES: int = 3
const CAMERA_SETTLE_FRAMES: int = 30
const GRANTED_GOLD: int = 60
const HOLD_SLACK_S: float = 1.5
const RAISE_TIMEOUT_S: float = 2.0
const VIEW_SIZE := Vector2i(1280, 720)
const FAR_AWAY := Vector3(40.0, 0.0, 40.0)
## A screen point clear of every card and of the HUD: the lower left of the view.
const AWAY_POINT := Vector2(160.0, 520.0)
const DRAG_PX: float = 30.0

var _view: SubViewport
var _map: MapRoot
var _ctx: RunContext
var _picker: CardPicker
var _row: CardRow
var _selection: SelectionModel
var _box: DragBox
var _camera: Camera3D


func after_each() -> void:
	E2eSupport.release_all_actions()


## The real scene with a squad selected and the king beside the castle plot with gold, so the four
## cards show and the camera has settled on them.
func _setup() -> void:
	_view = SubViewport.new()
	_view.size = VIEW_SIZE
	add_child_autofree(_view)
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	_map = scene.instantiate()
	_map.map_config = E2eSupport.waveless_prototype_map()
	_map.fixed_run_seed = 1
	_map.handle_results_actions = false
	_view.add_child(_map)
	await wait_process_frames(SETTLE_FRAMES)
	_ctx = _map.get_context()
	_ctx.economy.grant(GRANTED_GOLD)
	assert_eq(_ctx.commands.submit(BuildIntent.new(BARRACKS)), CommandProcessor.OK, "a squad")
	_picker = _map.get_cards()
	_row = _map.get_node("CardRow")
	_selection = _map.get_selection()
	_box = _map.find_child("DragBox", true, false) as DragBox
	var raised: Callable = func() -> bool: return not _ctx.squads.squad_ids().is_empty()
	assert_true(await E2eSupport.wait_until(self, raised, RAISE_TIMEOUT_S), "the squad is raised")
	_selection.select_only(_ctx.squads.squad_ids(), _ctx.squads.squad_ids())
	assert_false(_selection.selected().is_empty(), "a squad is selected")
	var focused: bool = await E2eSupport.stand_at_spot(self, _map, CASTLE)
	assert_true(focused, "the king reached the castle plot")
	await wait_process_frames(CAMERA_SETTLE_FRAMES)
	_camera = _view.get_camera_3d()
	assert_true(_picker.is_showing(), "the cards show")
	assert_eq(_row.card_count(), 4, "four cards")


func _centre(index: int) -> Vector2:
	var rects: Array[Rect2] = _row.card_rects(_camera)
	return rects[index].get_center()


func _motion(to: Vector2, mask: int = 0) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = to
	event.global_position = to
	event.button_mask = mask
	_view.push_input(event)
	await wait_process_frames(2)


func _button(at: Vector2, index: MouseButton, pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = index
	event.pressed = pressed
	event.position = at
	event.global_position = at
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	_view.push_input(event)
	await wait_process_frames(2)


func _click(at: Vector2) -> void:
	await _button(at, MOUSE_BUTTON_LEFT, true)
	await _button(at, MOUSE_BUTTON_LEFT, false)


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await wait_process_frames(2)
	Input.action_release(action)
	await wait_process_frames(2)


func _tier_two_cost() -> int:
	return _ctx.buildings.get_building_def_for_spot(CASTLE).tier_def(2).cost


func test_the_four_card_rectangles_lie_on_screen_side_by_side() -> void:
	await _setup()
	var rects: Array[Rect2] = _row.card_rects(_camera)
	assert_eq(rects.size(), 4, "one rectangle per card")
	var view: Rect2 = Rect2(Vector2.ZERO, Vector2(VIEW_SIZE))
	for index: int in range(rects.size()):
		assert_true(view.encloses(rects[index]), "card %d is inside the view" % (index + 1))
		assert_gt(rects[index].size.x, 20.0, "card %d is wide enough to hit" % (index + 1))
	for index: int in range(1, rects.size()):
		assert_gt(rects[index].position.x, rects[index - 1].position.x, "left to right")


func test_hidden_cards_have_no_rectangles() -> void:
	await _setup()
	E2eSupport.teleport_king(_map, FAR_AWAY)
	await wait_process_frames(3)
	assert_true(_row.card_rects(_camera).is_empty(), "nothing to point at while hidden")


func test_pointing_at_a_card_highlights_it_and_prints_its_numbers() -> void:
	await _setup()
	await _motion(_centre(2))
	assert_eq(_picker.highlighted_index(), 2, "the mouse is over card 3")
	assert_true(_row.is_card_raised(2), "it is raised")
	var third: ChoiceDef = _ctx.buildings.get_building_def_for_spot(CASTLE).tier_def(2).choices[2]
	assert_eq(_row.numbers_text(2), third.effect_line(), "the numbers line is the generated one")
	assert_false(_row.numbers_text(2).is_empty(), "and it says something")
	assert_eq(_row.numbers_text(0), "", "an unhighlighted card prints no numbers")
	assert_eq(_row.numbers_text(3), "", "none of them does")


func test_pointing_at_another_card_moves_the_highlight() -> void:
	await _setup()
	await _motion(_centre(0))
	assert_eq(_picker.highlighted_index(), 0, "card 1")
	await _motion(_centre(3))
	assert_eq(_picker.highlighted_index(), 3, "then card 4")
	assert_eq(_row.numbers_text(0), "", "card 1 lost its numbers")
	assert_ne(_row.numbers_text(3), "", "card 4 shows them")


func test_moving_the_mouse_off_the_cards_keeps_the_highlight() -> void:
	await _setup()
	await _motion(_centre(1))
	await _motion(AWAY_POINT)
	assert_eq(_picker.highlighted_index(), 1, "the choice stays for the hold")
	assert_true(_row.is_card_raised(1), "still raised")


func test_a_key_highlight_shows_the_same_numbers_line() -> void:
	await _setup()
	await _tap(&"group_2")
	assert_eq(_picker.highlighted_index(), 1, "key 2")
	var second: ChoiceDef = _ctx.buildings.get_building_def_for_spot(CASTLE).tier_def(2).choices[1]
	assert_eq(_row.numbers_text(1), second.effect_line(), "the keyboard shows the numbers too")


func test_a_click_on_a_card_highlights_it_and_leaves_everything_else_alone() -> void:
	await _setup()
	var gold: int = _ctx.economy.get_gold()
	var selected: Array[StringName] = _selection.selected()
	watch_signals(_ctx.events)
	await _click(_centre(0))
	assert_eq(_picker.highlighted_index(), 0, "card 1 is highlighted")
	assert_eq(_selection.selected(), selected, "the squad is still selected")
	assert_false(_box.visible, "no drag box")
	assert_false(_box.is_dragging(), "and no drag")
	assert_eq(_ctx.economy.get_gold(), gold, "nothing was spent")
	assert_eq(_ctx.buildings.current_tier(CASTLE), 1, "the castle did not change tier")
	assert_signal_not_emitted(_ctx.events, "command_rejected", "no command was even tried")
	assert_signal_not_emitted(_ctx.events, "building_built", "nothing was built")


func test_a_press_and_drag_that_starts_on_a_card_draws_no_box() -> void:
	await _setup()
	var selected: Array[StringName] = _selection.selected()
	var start: Vector2 = _centre(1)
	await _button(start, MOUSE_BUTTON_LEFT, true)
	await _motion(start + Vector2(DRAG_PX, DRAG_PX), MOUSE_BUTTON_MASK_LEFT)
	assert_false(_box.visible, "no box while the press was taken by the card")
	await _button(start + Vector2(DRAG_PX, DRAG_PX), MOUSE_BUTTON_LEFT, false)
	assert_eq(_selection.selected(), selected, "the squad is still selected")
	assert_eq(_picker.highlighted_index(), 1, "the press highlighted the card")


func test_a_click_away_from_the_cards_still_reaches_the_selection() -> void:
	await _setup()
	assert_false(_selection.selected().is_empty(), "a squad is selected first")
	await _click(AWAY_POINT)
	assert_true(_selection.selected().is_empty(), "the click on empty ground cleared it")
	assert_eq(_picker.highlighted_index(), -1, "and no card was highlighted")


func test_a_right_click_on_a_card_is_not_taken() -> void:
	await _setup()
	var at: Vector2 = _centre(0)
	watch_signals(_ctx.events)
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	event.position = at
	event.global_position = at
	event.button_mask = MOUSE_BUTTON_MASK_RIGHT
	_view.push_input(event)
	await wait_process_frames(2)
	assert_eq(_picker.highlighted_index(), -1, "a right click highlights nothing")


func test_a_digit_key_after_a_click_moves_the_highlight() -> void:
	await _setup()
	await _click(_centre(0))
	assert_eq(_picker.highlighted_index(), 0, "clicked card 1")
	await _tap(&"group_4")
	assert_eq(_picker.highlighted_index(), 3, "key 4 moves it to card 4")
	assert_ne(_row.numbers_text(3), "", "card 4 shows its numbers")
	assert_eq(_row.numbers_text(0), "", "card 1 does not")


func test_a_click_after_the_cards_hid_reaches_the_selection() -> void:
	await _setup()
	var at: Vector2 = _centre(0)
	E2eSupport.teleport_king(_map, FAR_AWAY)
	await wait_process_frames(3)
	assert_false(_picker.is_showing(), "the cards hid")
	await _click(at)
	assert_true(_selection.selected().is_empty(), "so the click went to the selection")
	assert_eq(_picker.highlighted_index(), -1, "and highlighted nothing")


func test_holding_the_action_key_buys_the_clicked_card() -> void:
	await _setup()
	await _click(_centre(0))
	assert_eq(_picker.highlighted(), &"royal_training", "card 1 is Royal Training")
	var gold: int = _ctx.economy.get_gold()
	watch_signals(_ctx.events)
	var seconds: float = _ctx.tuning.build_hold_seconds(_tier_two_cost()) + HOLD_SLACK_S
	Input.action_press(&"action_build")
	var bought: Callable = func() -> bool: return _ctx.buildings.current_tier(CASTLE) == 2
	assert_true(await E2eSupport.wait_until(self, bought, seconds), "the castle reached tier II")
	Input.action_release(&"action_build")
	assert_signal_emitted_with_parameters(
		_ctx.events, "choice_picked", [CASTLE, 2, &"royal_training"]
	)
	assert_eq(_ctx.economy.get_gold(), gold - _tier_two_cost(), "only the hold spent the cost")
	assert_true(_ctx.stat_stack.has_source(&"royal_training"), "the clicked card is armed")
