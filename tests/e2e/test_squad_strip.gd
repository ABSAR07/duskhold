extends GutTest
## UI-01 / D-23 (plan 03-05): the bottom-centre SquadStrip. The real HUD is laid out in a 1280x720
## SubViewport and bound to a RunContext on the squad fixture (its grunts crawl, so no enemy ever
## reaches a squad), and the test steps the simulation by hand. One slot per squad in creation
## order, "alive / max" in the slot, a dim red 0 / N when the squad is gone (also when its building
## is rubble), a replacement fill that rises over the tier interval, a border flash at dawn, a
## one-line "14 / 14", and the layout rows of the UI-SPEC (clear of the king widget, 8 px above the
## start-night box, outside the protected centre).

const HUD_SCENE := "res://ui/hud/hud.tscn"
const SLOT_SCENE := "res://ui/hud/squad_slot.tscn"
const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
const BASE_SIZE := Vector2i(1280, 720)
const BARRACKS: StringName = &"barracks_1"
const ARCHERY: StringName = &"archery_1"
const PROTECTED_RECT := Rect2(384.0, 96.0, 512.0, 404.0)
const SLOT_SIZE := Vector2(136.0, 72.0)
const STRIP_TOP: float = 544.0
const STRIP_BOTTOM: float = 616.0
const START_BOX_TOP: float = 624.0
const DANGER := Color("#FF4040")
const DIMMED := Color("#7A808C")
const FLASH := Color("#8CEBFF")
const IDLE_BORDER := Color("#3A3F4B")
const SETTLE_FRAMES: int = 3
const KILL_DAMAGE: int = 1000
const CRAWL_SPEED: float = 0.001
const MAX_NIGHT_STEPS: int = 20000
const STEPS_PER_SECOND: int = 30
const OVERFLOW_MAX_WIDTH: float = 720.0
const SIX_SLOTS_WIDTH: float = 856.0
const FLASH_SETTLE_S: float = 0.6
const SCENE_TIMEOUT_S: float = 2.0

var _viewport: SubViewport
var _hud: Hud
var _strip: SquadStrip
var _ctx: RunContext


func after_each() -> void:
	E2eSupport.release_all_actions()


## Lays the real HUD out in a 1280x720 viewport and binds the strip to a fresh run on the squad
## fixture. The grunts crawl so no enemy reaches a squad and the test decides every death.
func _setup() -> void:
	_viewport = SubViewport.new()
	_viewport.size = BASE_SIZE
	add_child_autofree(_viewport)
	var scene: PackedScene = load(HUD_SCENE)
	_hud = scene.instantiate()
	_viewport.add_child(_hud)
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	for enemy: EnemyDef in map.enemies:
		enemy.move_speed = CRAWL_SPEED
	_ctx = RunContext.new(map, load(TUNING_PATH), 1)
	_strip = _hud.find_child("SquadStrip", true, false) as SquadStrip
	assert_not_null(_strip, "the HUD has a SquadStrip")
	if _strip != null:
		_strip.bind_run(_ctx, null)
	await wait_process_frames(SETTLE_FRAMES)


func _build(spot: StringName) -> void:
	assert_eq(_ctx.commands.submit(BuildIntent.new(spot)), CommandProcessor.OK, "built %s" % spot)


func _step(count: int) -> void:
	for _i: int in range(count):
		_ctx.step()


func _settle() -> void:
	await wait_process_frames(SETTLE_FRAMES)


func _start_night() -> void:
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night starts")


func _kill_units(spot: StringName, count: int) -> void:
	var ids: Array[int] = _ctx.squads.unit_ids_of(spot)
	for index: int in range(mini(count, ids.size())):
		_ctx.squads.damage_unit(ids[index], KILL_DAMAGE, &"test")
	_ctx.squads.remove_dead()


## Steps the sim, killing every enemy as it appears, until the night is cleared into dawn.
func _clear_the_night() -> void:
	var steps: int = 0
	while _ctx.run_manager.get_phase() == RunManager.RunPhase.NIGHT and steps < MAX_NIGHT_STEPS:
		for enemy_id: int in _ctx.night.get_enemies().ids():
			_ctx.night.get_enemies().damage(enemy_id, KILL_DAMAGE, &"test")
		_ctx.step()
		steps += 1


func _slots() -> Array[SquadSlot]:
	var found: Array[SquadSlot] = []
	for child: Node in _strip.get_children():
		if child is SquadSlot:
			found.append(child as SquadSlot)
	return found


func _slot_ids() -> Array:
	var ids: Array = []
	for slot: SquadSlot in _slots():
		ids.append(slot.squad_id)
	return ids


func _icon_bytes(texture: Texture2D) -> PackedByteArray:
	return texture.get_image().get_data()


func _font_color_of(label: Label) -> Color:
	return label.get_theme_color(&"font_color")


func test_the_strip_lives_under_the_hud_root_and_only_slots_take_the_mouse() -> void:
	await _setup()
	if _strip == null:
		return
	assert_eq(_strip.get_parent().name, &"HudRoot", "under HudRoot")
	assert_true(_strip.is_in_group(&"run_bound"), "the map binds it to the run")
	assert_eq(_strip.mouse_filter, Control.MOUSE_FILTER_IGNORE, "the strip itself is transparent")
	assert_eq(_strip.anchor_left, 0.5, "anchored on the centre")
	assert_eq(_strip.anchor_right, 0.5, "anchored on the centre")
	assert_eq(_strip.anchor_top, 1.0, "anchored to the bottom")
	assert_eq(_strip.anchor_bottom, 1.0, "anchored to the bottom")
	assert_eq(_strip.offset_top, -176.0, "top offset")
	assert_eq(_strip.offset_bottom, -104.0, "bottom offset")
	assert_eq(_strip.get_theme_constant(&"separation"), 8, "8 px between slots")


func test_with_nothing_built_the_strip_is_hidden_and_shows_no_placeholder() -> void:
	await _setup()
	if _strip == null:
		return
	assert_false(_strip.visible, "hidden with no squad")
	assert_eq(_strip.slot_count(), 0, "no slot")
	assert_eq(_strip.find_children("*", "Label", true, false).size(), 0, "no placeholder text")


func test_building_the_barracks_adds_one_slot_reading_4_of_4() -> void:
	await _setup()
	if _strip == null:
		return
	_build(BARRACKS)
	_step(1)
	await _settle()
	assert_eq(_strip.slot_count(), 1, "one slot")
	assert_true(_strip.visible, "the strip shows")
	var slot: SquadSlot = _strip.slot_for(BARRACKS)
	assert_not_null(slot, "the Barracks has its slot")
	if slot == null:
		return
	assert_eq(slot.get_alive_label().text, "4 / 4", "alive / max")
	assert_eq(
		_icon_bytes(slot.get_icon().texture),
		_icon_bytes(SwordIcon.make_texture(32)),
		"melee squads wear the sword"
	)
	assert_eq(slot.get_glyph().current_shape(), StanceGlyph.shape_for(SquadOrder.STANCE_POST))
	assert_false(slot.get_fill().visible, "a full squad shows no replacement fill")
	assert_eq(slot.mouse_filter, Control.MOUSE_FILTER_STOP, "a slot takes the mouse")
	assert_eq(slot.focus_mode, Control.FOCUS_NONE, "and never takes keyboard focus")


func test_one_slot_sits_centred_at_the_bottom() -> void:
	await _setup()
	if _strip == null:
		return
	_build(BARRACKS)
	_step(1)
	await _settle()
	var slot: SquadSlot = _strip.slot_for(BARRACKS)
	if slot == null:
		fail_test("no slot")
		return
	var rect: Rect2 = slot.get_global_rect()
	assert_almost_eq(rect.size.x, SLOT_SIZE.x, 0.5, "136 wide")
	assert_almost_eq(rect.size.y, SLOT_SIZE.y, 0.5, "72 tall")
	assert_almost_eq(rect.get_center().x, 640.0, 1.0, "centred")
	assert_almost_eq(rect.end.y, STRIP_BOTTOM, 0.5, "bottom edge at y 616")


func test_building_the_range_adds_a_second_slot_after_the_first_with_the_bow() -> void:
	await _setup()
	if _strip == null:
		return
	_build(BARRACKS)
	_step(1)
	_build(ARCHERY)
	_step(1)
	await _settle()
	assert_eq(_strip.slot_count(), 2, "two slots")
	assert_eq(_slot_ids(), [BARRACKS, ARCHERY], "in creation order")
	var bow: SquadSlot = _strip.slot_for(ARCHERY)
	if bow == null:
		fail_test("no archery slot")
		return
	assert_eq(
		_icon_bytes(bow.get_icon().texture),
		_icon_bytes(BowIcon.make_texture(32)),
		"ranged squads wear the bow"
	)
	assert_eq(bow.get_alive_label().text, "4 / 4", "the archers are all up")


func test_slots_follow_the_order_the_buildings_were_first_built() -> void:
	await _setup()
	if _strip == null:
		return
	_build(ARCHERY)
	_step(1)
	await _settle()
	_build(BARRACKS)
	_step(1)
	await _settle()
	assert_eq(_slot_ids(), [ARCHERY, BARRACKS], "the Range was built first")


func test_two_slots_lay_out_clear_of_the_king_widget_and_the_start_night_box() -> void:
	await _setup()
	if _strip == null:
		return
	_build(BARRACKS)
	_build(ARCHERY)
	_step(1)
	await _settle()
	var first: Rect2 = _strip.slot_for(BARRACKS).get_global_rect()
	var second: Rect2 = _strip.slot_for(ARCHERY).get_global_rect()
	assert_almost_eq(first.position.x, 500.0, 0.5, "the first slot starts at x 500")
	assert_almost_eq(first.position.y, STRIP_TOP, 0.5, "and at y 544")
	assert_almost_eq(second.end.x, 780.0, 0.5, "the second ends at x 780")
	assert_almost_eq(second.end.y, STRIP_BOTTOM, 0.5, "at y 616")
	assert_almost_eq(second.position.x - first.end.x, 8.0, 0.5, "8 px between the slots")
	var footprint: Rect2 = first.merge(second)
	var king: Control = _hud.find_child("KingWidget", true, false) as Control
	var king_rect: Rect2 = king.get_global_rect()
	for node: Node in king.find_children("*", "Control", true, false):
		king_rect = king_rect.merge((node as Control).get_global_rect())
	assert_false(footprint.intersects(king_rect), "clear of the king widget")
	var start_box: Control = _hud.find_child("StartNightBox", true, false) as Control
	var start_rect: Rect2 = start_box.get_global_rect()
	assert_false(footprint.intersects(start_rect), "clear of the start-night box")
	assert_almost_eq(start_rect.position.y, START_BOX_TOP, 0.5, "the box keeps y 624")
	assert_almost_eq(start_rect.position.y - footprint.end.y, 8.0, 0.5, "8 px above it")
	assert_false(footprint.intersects(PROTECTED_RECT), "outside the protected centre")


func test_after_two_footmen_die_the_slot_reads_2_of_4_and_its_fill_rises() -> void:
	await _setup()
	if _strip == null:
		return
	_build(BARRACKS)
	_build(ARCHERY)
	_step(1)
	_start_night()
	_step(1)
	await _settle()
	var slot: SquadSlot = _strip.slot_for(BARRACKS)
	if slot == null:
		fail_test("no slot")
		return
	_kill_units(BARRACKS, 2)
	_step(STEPS_PER_SECOND)
	await _settle()
	assert_eq(slot.get_alive_label().text, "2 / 4", "two are left")
	var fill: ProgressBar = slot.get_fill()
	assert_true(fill.visible, "a replacement is coming")
	var early: float = fill.value
	assert_gt(early, 0.0, "the fill has started")
	assert_lt(early, 1.0, "and has not finished")
	assert_almost_eq(early, _ctx.squads.replacement_progress(BARRACKS), 0.001, "it mirrors the sim")
	_step(STEPS_PER_SECOND * 2)
	await _settle()
	assert_gt(fill.value, early, "and it keeps rising")
	assert_eq(_slot_ids(), [BARRACKS, ARCHERY], "the slots did not move")
	assert_eq(slot.get_alive_label().text, "2 / 4", "still two")


func test_with_every_footman_dead_the_slot_reads_0_of_4_in_red_and_dimmed() -> void:
	await _setup()
	if _strip == null:
		return
	_build(BARRACKS)
	_step(1)
	_start_night()
	_step(1)
	_kill_units(BARRACKS, 4)
	_step(STEPS_PER_SECOND)
	await _settle()
	var slot: SquadSlot = _strip.slot_for(BARRACKS)
	if slot == null:
		fail_test("no slot")
		return
	assert_eq(slot.get_alive_label().text, "0 / 4", "nobody is up")
	assert_eq(_font_color_of(slot.get_alive_label()), DANGER, "the count turns red")
	assert_eq(slot.get_icon().modulate, DIMMED, "the icon is dimmed")
	assert_eq(slot.get_glyph().modulate, DIMMED, "so is the stance glyph")
	assert_true(slot.get_fill().visible, "the replacement is on its way")
	assert_gt(slot.get_fill().value, 0.0, "and already filling")


func test_a_squad_whose_barracks_is_rubble_keeps_its_place_dimmed_with_a_stopped_fill() -> void:
	await _setup()
	if _strip == null:
		return
	_build(BARRACKS)
	_build(ARCHERY)
	_step(1)
	_start_night()
	_step(1)
	_kill_units(BARRACKS, 4)
	_step(STEPS_PER_SECOND)
	await _settle()
	var slot: SquadSlot = _strip.slot_for(BARRACKS)
	if slot == null:
		fail_test("no slot")
		return
	var before: float = slot.get_fill().value
	assert_gt(before, 0.0, "the fill was running before the building fell")
	_ctx.buildings.damage_building(BARRACKS, KILL_DAMAGE)
	assert_true(_ctx.buildings.is_destroyed(BARRACKS), "the Barracks is rubble")
	_step(STEPS_PER_SECOND * 2)
	await _settle()
	assert_eq(_strip.slot_count(), 2, "both slots are still there")
	assert_eq(_slot_ids(), [BARRACKS, ARCHERY], "in the same order")
	assert_eq(_strip.slot_for(BARRACKS), slot, "the same slot")
	assert_eq(slot.get_alive_label().text, "0 / 4", "nobody is up")
	assert_eq(_font_color_of(slot.get_alive_label()), DANGER, "in red")
	assert_eq(slot.get_icon().modulate, DIMMED, "the icon is dimmed")
	assert_eq(slot.get_glyph().modulate, DIMMED, "so is the glyph")
	assert_true(slot.get_fill().visible, "the fill stays on the slot")
	assert_eq(slot.get_fill().value, before, "but it does not advance while the building is rubble")


func test_at_dawn_the_count_jumps_to_full_and_the_border_flashes_once() -> void:
	await _setup()
	if _strip == null:
		return
	_build(BARRACKS)
	_step(1)
	_start_night()
	_step(1)
	await _settle()
	var slot: SquadSlot = _strip.slot_for(BARRACKS)
	if slot == null:
		fail_test("no slot")
		return
	_kill_units(BARRACKS, 2)
	_step(STEPS_PER_SECOND)
	await _settle()
	assert_eq(slot.get_alive_label().text, "2 / 4", "two fell")
	assert_eq(slot.flash_count(), 0, "no flash yet")
	assert_eq(slot.border_color(), IDLE_BORDER, "an idle border")
	_clear_the_night()
	assert_eq(_ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "dawn began")
	assert_eq(slot.flash_count(), 1, "the restore flashed the border once")
	assert_eq(slot.border_color(), FLASH, "in the accent colour")
	await _settle()
	assert_eq(slot.get_alive_label().text, "4 / 4", "the count is straight back to full")
	assert_false(slot.get_fill().visible, "no replacement is coming")
	await wait_seconds(FLASH_SETTLE_S)
	assert_eq(slot.border_color(), IDLE_BORDER, "the border returns to idle")
	assert_eq(slot.flash_count(), 1, "and it flashed only once")


func test_upgraded_twice_by_day_the_slot_reads_14_of_14_on_one_line_and_keeps_its_width() -> void:
	await _setup()
	if _strip == null:
		return
	_build(BARRACKS)
	_build(BARRACKS)
	_build(BARRACKS)
	assert_eq(_ctx.buildings.current_tier(BARRACKS), 3, "tier three")
	_step(1)
	await _settle()
	var slot: SquadSlot = _strip.slot_for(BARRACKS)
	if slot == null:
		fail_test("no slot")
		return
	var label: Label = slot.get_alive_label()
	assert_eq(label.text, "14 / 14", "the new cap shows at once and the seats fill by day")
	assert_eq(label.get_line_count(), 1, "one line")
	assert_almost_eq(slot.size.x, SLOT_SIZE.x, 0.5, "the slot is still 136 wide")
	assert_almost_eq(slot.size.y, SLOT_SIZE.y, 0.5, "and 72 tall")
	var padded: Rect2 = Rect2(Vector2(8.0, 8.0), SLOT_SIZE - Vector2(16.0, 16.0))
	var local: Rect2 = Rect2(label.global_position - slot.global_position, label.size)
	assert_true(padded.encloses(local), "the text sits inside the 8 px padding")


func test_the_group_badge_is_a_twenty_by_twenty_box_hidden_until_a_group_digit_is_set() -> void:
	await _setup()
	if _strip == null:
		return
	_build(BARRACKS)
	_step(1)
	await _settle()
	var slot: SquadSlot = _strip.slot_for(BARRACKS)
	if slot == null:
		fail_test("no slot")
		return
	var badge: PanelContainer = slot.get_badge()
	assert_false(badge.visible, "hidden until a control group exists")
	assert_eq(badge.custom_minimum_size, Vector2(20.0, 20.0), "a fixed 20x20 box")
	slot.set_selected(true)
	slot.set_group(3)
	await _settle()
	assert_true(badge.visible, "a group digit shows the badge")
	assert_eq((badge.get_child(0) as Label).text, "3", "with that digit")
	assert_eq(badge.size, Vector2(20.0, 20.0), "still 20x20")
	slot.set_group(0)
	await _settle()
	assert_eq((badge.get_child(0) as Label).text, "0", "0 is group 10")
	slot.set_group(-1)
	await _settle()
	assert_false(badge.visible, "-1 hides it again")
	assert_eq(slot.get_alive_label().text, "4 / 4", "and none of it changed anything else")


func test_six_slots_fit_in_856_px_without_scaling() -> void:
	await _setup()
	if _strip == null:
		return
	_add_fake_slots(6)
	await _settle()
	assert_eq(_strip.slot_count(), 6, "six slots")
	assert_almost_eq(_strip.size.x, SIX_SLOTS_WIDTH, 0.5, "6 x 136 + 5 x 8")
	assert_eq(_strip.scale, Vector2.ONE, "no scaling up to six")


func test_seven_slots_scale_the_strip_to_at_most_720_px_from_the_bottom_centre() -> void:
	await _setup()
	if _strip == null:
		return
	_add_fake_slots(7)
	await _settle()
	assert_eq(_strip.slot_count(), 7, "seven slots")
	assert_eq(_strip.scale.x, _strip.scale.y, "scaled uniformly")
	assert_lt(_strip.scale.x, 1.0, "scaled down")
	assert_lte(_strip.size.x * _strip.scale.x, OVERFLOW_MAX_WIDTH + 0.5, "at most 720 px wide")
	var transform: Transform2D = _strip.get_global_transform()
	var bottom_centre: Vector2 = transform * Vector2(_strip.size.x * 0.5, _strip.size.y)
	assert_almost_eq(bottom_centre.x, 640.0, 1.0, "still centred")
	assert_almost_eq(bottom_centre.y, STRIP_BOTTOM, 1.0, "the bottom edge stays put")
	var top_left: Vector2 = transform * Vector2.ZERO
	var top_right: Vector2 = transform * Vector2(_strip.size.x, 0.0)
	assert_gte(top_left.y, STRIP_TOP, "it never rises toward the clear centre")
	assert_gte(top_left.x, 0.0, "inside the left edge")
	assert_lte(top_right.x, float(BASE_SIZE.x), "inside the right edge")


func test_in_the_real_scene_the_map_binds_the_strip() -> void:
	var map: MapConfig = load(FIXTURE)
	var map_root: MapRoot = await E2eSupport.spawn_map(self, map)
	map_root.handle_results_actions = false
	var strip: SquadStrip = map_root.get_node("HUD").find_child("SquadStrip", true, false)
	assert_not_null(strip, "the scene has a strip")
	if strip == null:
		return
	var ctx: RunContext = map_root.get_context()
	assert_false(strip.visible, "hidden at the start")
	assert_eq(ctx.commands.submit(BuildIntent.new(BARRACKS)), CommandProcessor.OK, "built")
	var shown: Callable = func() -> bool: return strip.slot_count() == 1
	assert_true(await E2eSupport.wait_until(self, shown, SCENE_TIMEOUT_S), "the slot appears")
	assert_true(strip.visible, "and the strip shows")
	assert_eq(strip.slot_for(BARRACKS).get_alive_label().text, "4 / 4", "it reads the run")


func _add_fake_slots(count: int) -> void:
	var scene: PackedScene = load(SLOT_SCENE)
	for index: int in range(count):
		var slot: SquadSlot = scene.instantiate() as SquadSlot
		slot.squad_id = StringName("fake_%d" % index)
		_strip.add_child(slot)
