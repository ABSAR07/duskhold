extends GutTest
## D-15 as amended at the 03-07 checkpoint (owner decision, 2026-10-10), in the real scene on the
## squad fixture. While a squad is selected all movement input goes to the selection: holding A for
## half a second moves the king 0.0 m and arms attack-move (A is both move_left and the
## attack-move key, so pressing it must not drift him). With the selection cleared the same hold
## moves him, and Escape clears the selection and hands control back at once. Sprint, the build
## hold and the ability are not movement and work whatever is selected. The A press is a real key
## event, so move_left and squad_attack_move go down together, as on a keyboard.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const BARRACKS: StringName = &"barracks_1"
const ARCHERY: StringName = &"archery_1"
const BOTH: Array[StringName] = [&"barracks_1", &"archery_1"]
const SETTLE_FRAMES: int = 3
const RAISE_TIMEOUT_S: float = 2.0
const KING_SPOT := Vector3(-8.0, 0.0, 0.0)
const HOLD_SECONDS: float = 0.5
const NO_DRIFT_M: float = 0.0001
const MOVED_AT_LEAST_M: float = 0.5
const HOUSE_SPOT: StringName = &"house_1"
const BUILD_TIMEOUT_S: float = 3.0

var _map: MapRoot
var _ctx: RunContext
var _king: King
var _selection: SelectionModel
var _toast: Toast


func after_each() -> void:
	_key(KEY_A, false)
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
	_king = _map.get_king()
	_selection = _map.get_selection()
	_toast = _map.find_child("Toast", true, false) as Toast
	E2eSupport.teleport_king(_map, KING_SPOT)
	_king.velocity = Vector3.ZERO
	await wait_physics_frames(2)


func _key(keycode: Key, pressed: bool) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)


func _xz() -> Vector2:
	return Vector2(_king.global_position.x, _king.global_position.z)


## Holds the A key for `seconds` and returns how far the king moved.
func _hold_a(seconds: float) -> float:
	var start: Vector2 = _xz()
	_key(KEY_A, true)
	await wait_seconds(seconds)
	_key(KEY_A, false)
	await wait_process_frames(2)
	return _xz().distance_to(start)


func test_with_a_squad_selected_holding_a_moves_the_king_nowhere_and_arms_attack_move() -> void:
	await _setup()
	_selection.select_only([BARRACKS] as Array[StringName], _ctx.squads.squad_ids())
	Input.action_press(&"squad_attack_move")
	Input.action_press(&"move_left")
	await wait_seconds(HOLD_SECONDS)
	assert_eq(_toast.current_text(), Toast.ARMED_ATTACK, "attack-move is armed")
	Input.action_release(&"squad_attack_move")
	Input.action_release(&"move_left")
	assert_almost_eq(_xz().distance_to(Vector2(KING_SPOT.x, KING_SPOT.z)), 0.0, NO_DRIFT_M, "0 m")


func test_a_real_a_key_press_with_a_squad_selected_does_not_drift_the_king() -> void:
	await _setup()
	_selection.select_only(BOTH, _ctx.squads.squad_ids())
	var moved: float = await _hold_a(HOLD_SECONDS)
	assert_almost_eq(moved, 0.0, NO_DRIFT_M, "the king stood still")
	assert_eq(_toast.current_text(), Toast.ARMED_ATTACK, "and attack-move is armed")


func test_with_the_selection_cleared_the_same_hold_moves_the_king() -> void:
	await _setup()
	_selection.clear()
	var moved: float = await _hold_a(HOLD_SECONDS)
	assert_gt(moved, MOVED_AT_LEAST_M, "the king rode left")
	assert_lt(_king.global_position.x, KING_SPOT.x, "to the left")
	assert_ne(_toast.current_text(), Toast.SELECT_FIRST, "steering is not an error")
	assert_ne(_toast.current_text(), Toast.ARMED_ATTACK, "and arms nothing")


func test_escape_hands_the_king_back_at_once() -> void:
	await _setup()
	_selection.select_only([ARCHERY] as Array[StringName], _ctx.squads.squad_ids())
	var stuck: float = await _hold_a(HOLD_SECONDS)
	assert_almost_eq(stuck, 0.0, NO_DRIFT_M, "locked while selected")
	Input.action_press(&"command_cancel")
	await wait_process_frames(2)
	Input.action_release(&"command_cancel")
	await wait_process_frames(2)
	assert_eq(_selection.selected(), [] as Array[StringName], "Escape cleared the selection")
	_king.velocity = Vector3.ZERO
	var free: float = await _hold_a(HOLD_SECONDS)
	assert_gt(free, MOVED_AT_LEAST_M, "and the king rides again")


func test_the_ability_works_with_a_squad_selected() -> void:
	await _setup()
	_selection.select_only(BOTH, _ctx.squads.squad_ids())
	Input.action_press(&"ability")
	await wait_process_frames(3)
	Input.action_release(&"ability")
	await wait_process_frames(2)
	assert_gt(_ctx.king.ability_ticks_left(), 0, "the slam fired and its cooldown runs")


func test_the_build_hold_works_with_a_squad_selected() -> void:
	await _setup()
	_ctx.economy.grant(20)
	_selection.select_only(BOTH, _ctx.squads.squad_ids())
	assert_true(await E2eSupport.stand_at_spot(self, _map, HOUSE_SPOT), "the spot is in range")
	Input.action_press(&"action_build")
	var built: Callable = func() -> bool: return _ctx.buildings.current_tier(HOUSE_SPOT) >= 1
	assert_true(await E2eSupport.wait_until(self, built, BUILD_TIMEOUT_S), "the house was built")
	Input.action_release(&"action_build")


func test_sprint_is_not_movement_it_only_matters_once_the_king_may_move() -> void:
	await _setup()
	_selection.select_only(BOTH, _ctx.squads.squad_ids())
	Input.action_press(&"sprint")
	var locked: float = await _hold_a(HOLD_SECONDS)
	assert_almost_eq(locked, 0.0, NO_DRIFT_M, "sprinting does not unlock the king")
	assert_true(Input.is_action_pressed(&"sprint"), "the sprint key still reads as held")
	_selection.clear()
	_king.velocity = Vector3.ZERO
	var sprinted: float = await _hold_a(HOLD_SECONDS)
	Input.action_release(&"sprint")
	assert_gt(sprinted, MOVED_AT_LEAST_M, "with the selection gone the sprint carries him")
