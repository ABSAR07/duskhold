extends GutTest
## UNIT-09, D-10, D-16, D-23, D-25: control groups on the keyboard in the real scene on the squad
## fixture. Ctrl + a digit stores the selection as a group and says "Group N saved"; the bare digit
## recalls it and flashes the rings once; recalling an empty group says "Group N is empty" and
## keeps the selection; the squad slot shows the lowest group number the squad is in (key 0 is
## group 10). The keys are polled, so scripted Input.action_press drives them: the modifier is held
## while the digit is tapped, as a player's hand would (Pitfall 5: ten digit actions plus one
## modifier action).

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const BARRACKS: StringName = &"barracks_1"
const ARCHERY: StringName = &"archery_1"
const SETTLE_FRAMES: int = 3
const RAISE_TIMEOUT_S: float = 2.0
const SELECTED_ALPHA: float = 0.95
const FLASH_ALPHA: float = 1.0
const FLASH_FRAMES: int = 40
const KILL_DAMAGE: int = 1000

var _map: MapRoot
var _ctx: RunContext
var _views: UnitViews
var _selection: SelectionModel
var _toast: Toast
var _rings: SelectionRings
var _strip: SquadStrip


func after_each() -> void:
	Engine.time_scale = 1.0
	E2eSupport.release_all_actions()


## The real scene; `units` is how many puppets to wait for: 8 with both squads built, 4 with one.
func _setup(build_archery: bool = true) -> void:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	_map = scene.instantiate()
	_map.map_config = load(FIXTURE)
	_map.fixed_run_seed = 1
	_map.handle_results_actions = false
	add_child_autofree(_map)
	await wait_process_frames(SETTLE_FRAMES)
	_ctx = _map.get_context()
	_views = _map.get_node("UnitViews")
	assert_eq(_ctx.commands.submit(BuildIntent.new(BARRACKS)), CommandProcessor.OK, "barracks")
	var wanted: int = 4
	if build_archery:
		assert_eq(_ctx.commands.submit(BuildIntent.new(ARCHERY)), CommandProcessor.OK, "range")
		wanted = 8
	var raised: Callable = func() -> bool: return _views.view_count() == wanted
	assert_true(await E2eSupport.wait_until(self, raised, RAISE_TIMEOUT_S), "puppets are up")
	_selection = _map.get_selection()
	_toast = _map.find_child("Toast", true, false) as Toast
	_rings = _map.get_node_or_null("SelectionRings") as SelectionRings
	_strip = _map.find_child("SquadStrip", true, false) as SquadStrip
	assert_not_null(_toast, "the HUD has a Toast")
	assert_not_null(_rings, "the scene has SelectionRings")


func _select(ids: Array[StringName]) -> void:
	_selection.select_only(ids, _ctx.squads.squad_ids())


## One press of an action: down for two frames, released, two more frames.
func _tap(action: StringName) -> void:
	Input.action_press(action)
	await wait_process_frames(2)
	Input.action_release(action)
	await wait_process_frames(2)


## Ctrl held while the digit action is tapped.
func _ctrl_tap(action: StringName) -> void:
	Input.action_press(&"selection_modifier")
	await wait_process_frames(1)
	await _tap(action)
	Input.action_release(&"selection_modifier")
	await wait_process_frames(1)


func _badge_text(squad_id: StringName) -> String:
	var slot: SquadSlot = _strip.slot_for(squad_id)
	return slot.get_badge_label().text if slot.get_badge().visible else ""


func test_ctrl_and_a_digit_stores_the_selection_says_so_and_badges_the_slot() -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	await _ctrl_tap(&"group_1")
	assert_eq(_selection.group_members(1), [BARRACKS] as Array[StringName], "group 1 holds it")
	assert_eq(_toast.current_text(), "Group 1 saved", "the toast says so")
	assert_eq(_badge_text(BARRACKS), "1", "the barracks slot shows 1")
	assert_eq(_badge_text(ARCHERY), "", "the archery slot shows none")
	assert_eq(_selection.selected(), [BARRACKS] as Array[StringName], "storing keeps the selection")


func test_the_bare_digit_recalls_the_group_and_flashes_the_rings_once() -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	await _ctrl_tap(&"group_1")
	_select([ARCHERY] as Array[StringName])
	await wait_process_frames(2)
	assert_eq(_rings.flash_count(), 0, "no flash yet")
	Input.action_press(&"group_1")
	await wait_process_frames(2)
	Input.action_release(&"group_1")
	assert_eq(_selection.selected(), [BARRACKS] as Array[StringName], "the barracks again")
	assert_eq(_rings.flash_count(), 1, "one flash")
	assert_almost_eq(_rings.ring_alpha(0), FLASH_ALPHA, 0.001, "at alpha 1.0 while it lasts")
	var biggest: float = 0.0
	for frame: int in range(FLASH_FRAMES):
		await wait_process_frames(1)
		biggest = maxf(biggest, _rings.ring_scale(0))
	assert_gt(biggest, 1.1, "the rings grew towards 1.2")
	assert_lte(biggest, 1.2001, "and no further")
	assert_almost_eq(_rings.ring_scale(0), 1.0, 0.001, "back to 1.0")
	assert_almost_eq(_rings.ring_alpha(0), SELECTED_ALPHA, 0.001, "and back to the selected alpha")
	assert_eq(_rings.flash_count(), 1, "still a single flash")


func test_recalling_an_empty_group_says_so_and_keeps_the_selection() -> void:
	await _setup()
	_select([ARCHERY] as Array[StringName])
	await _tap(&"group_2")
	assert_eq(_toast.current_text(), "Group 2 is empty", "the toast says so")
	assert_eq(_selection.selected(), [ARCHERY] as Array[StringName], "the selection is kept")
	assert_eq(_rings.flash_count(), 0, "and nothing flashes")


func test_key_zero_is_group_ten_and_its_badge_reads_zero() -> void:
	await _setup()
	_select([ARCHERY] as Array[StringName])
	await _ctrl_tap(&"group_0")
	assert_eq(_selection.group_members(10), [ARCHERY] as Array[StringName], "group 10")
	assert_eq(_toast.current_text(), "Group 0 saved", "the toast names the key")
	assert_eq(_badge_text(ARCHERY), "0", "the badge reads 0")
	_select([BARRACKS] as Array[StringName])
	await _tap(&"group_0")
	assert_eq(_selection.selected(), [ARCHERY] as Array[StringName], "the 0 key recalls it")


func test_a_bare_digit_never_stores_and_ctrl_and_a_digit_never_recalls() -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	await _tap(&"group_3")
	assert_true(_selection.group_members(3).is_empty(), "a bare digit stores nothing")
	assert_eq(_toast.current_text(), "Group 3 is empty", "it tried to recall")
	await _ctrl_tap(&"group_4")
	_select([ARCHERY] as Array[StringName])
	await _ctrl_tap(&"group_4")
	assert_eq(_selection.selected(), [ARCHERY] as Array[StringName], "Ctrl + digit did not recall")
	assert_eq(_selection.group_members(4), [ARCHERY] as Array[StringName], "it stored over it")


func test_storing_with_nothing_selected_says_select_a_squad_first() -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	await _ctrl_tap(&"group_1")
	_selection.clear()
	await _ctrl_tap(&"group_1")
	assert_eq(_toast.current_text(), Toast.SELECT_FIRST, "the toast says what to do")
	assert_eq(_selection.group_members(1), [BARRACKS] as Array[StringName], "group 1 is unchanged")


func test_the_badge_shows_the_lowest_group_the_squad_is_in() -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	await _ctrl_tap(&"group_5")
	assert_eq(_badge_text(BARRACKS), "5", "group 5")
	await _ctrl_tap(&"group_2")
	assert_eq(_badge_text(BARRACKS), "2", "2 is lower than 5")
	await _ctrl_tap(&"group_0")
	assert_eq(_badge_text(BARRACKS), "2", "group 10 is higher than 2")
	_select([ARCHERY] as Array[StringName])
	await _ctrl_tap(&"group_2")
	assert_eq(_badge_text(BARRACKS), "5", "the barracks left group 2, so 5 is its lowest")
	assert_eq(_badge_text(ARCHERY), "2", "the archers took group 2")


func test_a_squad_built_after_a_group_was_stored_joins_no_group() -> void:
	await _setup(false)
	_select([BARRACKS] as Array[StringName])
	await _ctrl_tap(&"group_1")
	assert_eq(_ctx.commands.submit(BuildIntent.new(ARCHERY)), CommandProcessor.OK, "range")
	var raised: Callable = func() -> bool: return _views.view_count() == 8
	assert_true(await E2eSupport.wait_until(self, raised, RAISE_TIMEOUT_S), "eight puppets")
	assert_eq(_selection.lowest_group_of(ARCHERY), -1, "the new squad is in no group")
	assert_eq(_badge_text(ARCHERY), "", "so its badge is hidden")
	_select([ARCHERY] as Array[StringName])
	await _tap(&"group_1")
	assert_eq(
		_selection.selected(), [BARRACKS] as Array[StringName], "the group holds the barracks"
	)


func test_a_squad_with_nobody_alive_keeps_its_group_and_its_badge() -> void:
	await _setup()
	_select([BARRACKS] as Array[StringName])
	await _ctrl_tap(&"group_1")
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night starts")
	for unit_id: int in _ctx.squads.unit_ids_of(BARRACKS):
		_ctx.squads.damage_unit(unit_id, KILL_DAMAGE, &"test")
	_ctx.squads.remove_dead()
	await wait_process_frames(5)
	assert_eq(_ctx.squads.alive_count(BARRACKS), 0, "nobody is left")
	assert_eq(_selection.lowest_group_of(BARRACKS), 1, "still in group 1")
	assert_eq(_badge_text(BARRACKS), "1", "and the slot still wears the badge")
	_select([ARCHERY] as Array[StringName])
	await _tap(&"group_1")
	assert_eq(_selection.selected(), [BARRACKS] as Array[StringName], "the empty squad is recalled")
