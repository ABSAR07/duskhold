extends GutTest
## UI-01 / D-21 HUD ground rules (plan 03-03): one themed HudRoot, the four-size font scale, the
## black outline of 6, the protected clear centre and the top-centre "Night N of T" counter. Layout
## is measured with the HUD laid out in a 1280x720 SubViewport so the rects are in the base space
## whatever the headless window is. Later HUD plans extend this file or add sibling contract files
## (20-test cap per script).

const HUD_SCENE := "res://ui/hud/hud.tscn"
const THEME_PATH := "res://ui/theme/hud_theme.tres"
const BASE_SIZE := Vector2i(1280, 720)
const FONT_SIZES: Array[int] = [36, 28, 22, 18]
const OUTLINE_SIZE: int = 6
const PROTECTED_RECT := Rect2(384.0, 96.0, 512.0, 404.0)
const COUNTER_BAND_TOP: float = 16.0
const COUNTER_BAND_BOTTOM: float = 56.0
const CENTRE_X: float = 640.0
const CENTRE_TOLERANCE_PX: float = 1.0
const SETTLE_FRAMES: int = 3
const LONG_NIGHT: int = 12
const RUN_SEED: int = 11
const MAX_NIGHT_STEPS: int = 20000
const KILL_DAMAGE: int = 100000
## The dev-only overlay is not part of the player HUD and keeps its own 16 px text.
const EXEMPT_SUBTREE := "DebugOverlay"

var _viewport: SubViewport
var _hud: Hud


func _hud_in_base_viewport() -> void:
	_viewport = SubViewport.new()
	_viewport.size = BASE_SIZE
	add_child_autofree(_viewport)
	var scene: PackedScene = load(HUD_SCENE)
	_hud = scene.instantiate()
	_viewport.add_child(_hud)
	await wait_process_frames(SETTLE_FRAMES)


func _counter() -> DayCounter:
	return _hud.find_child("DayCounter", true, false) as DayCounter


func _labels_of(root: Node) -> Array[Label]:
	var found: Array[Label] = []
	for child: Node in root.get_children():
		if child.name == EXEMPT_SUBTREE:
			continue
		if child is Label:
			found.append(child as Label)
		found.append_array(_labels_of(child))
	return found


func _spawn(map: MapConfig) -> MapRoot:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	var map_root: MapRoot = scene.instantiate()
	map_root.map_config = map
	map_root.fixed_run_seed = RUN_SEED
	map_root.handle_results_actions = false
	add_child_autofree(map_root)
	await wait_process_frames(SETTLE_FRAMES)
	return map_root


func _day_counter_of(map_root: MapRoot) -> DayCounter:
	return map_root.get_node("HUD").find_child("DayCounter", true, false) as DayCounter


## Steps the sim, killing every enemy as it appears, until the night is cleared into dawn.
func _clear_the_night(ctx: RunContext) -> void:
	var steps: int = 0
	while ctx.run_manager.get_phase() == RunManager.RunPhase.NIGHT and steps < MAX_NIGHT_STEPS:
		for enemy_id: int in ctx.night.get_enemies().ids():
			ctx.night.get_enemies().damage(enemy_id, KILL_DAMAGE, &"test")
		ctx.step()
		steps += 1


func test_hud_root_is_a_full_rect_ignore_control_with_the_hud_theme() -> void:
	await _hud_in_base_viewport()
	var root: HudRoot = _hud.get_node("HudRoot") as HudRoot
	assert_not_null(root, "the HUD has a HudRoot")
	assert_eq(root.mouse_filter, Control.MOUSE_FILTER_IGNORE, "HudRoot never swallows a click")
	assert_eq(root.anchor_left, 0.0, "anchor left")
	assert_eq(root.anchor_top, 0.0, "anchor top")
	assert_eq(root.anchor_right, 1.0, "anchor right")
	assert_eq(root.anchor_bottom, 1.0, "anchor bottom")
	assert_eq(root.size, Vector2(BASE_SIZE), "it spans the whole base screen")
	assert_eq(root.theme.resource_path, THEME_PATH, "it carries the HUD theme")


func test_the_day_counter_is_ignore_and_a_child_of_the_hud_root() -> void:
	await _hud_in_base_viewport()
	var counter: DayCounter = _counter()
	assert_not_null(counter, "the HUD has a DayCounter")
	assert_eq(counter.get_parent().name, &"HudRoot", "it lives under HudRoot")
	assert_eq(counter.mouse_filter, Control.MOUSE_FILTER_IGNORE, "it never swallows a click")
	assert_true(counter.is_in_group(&"run_bound"), "the map binds it to the run")


func test_the_theme_outlines_labels_in_black_at_size_6() -> void:
	var hud_theme: Theme = load(THEME_PATH)
	assert_eq(hud_theme.get_color(&"font_outline_color", &"Label"), Color.BLACK, "outline colour")
	assert_eq(hud_theme.get_constant(&"outline_size", &"Label"), OUTLINE_SIZE, "outline size")
	assert_eq(hud_theme.get_color(&"font_color", &"Label"), Color.WHITE, "label colour")
	var bold: Font = hud_theme.get_font(&"font", &"HudBoldLabel")
	assert_true(bold is FontVariation, "a bold FontVariation is stored for numerals")
	assert_almost_eq((bold as FontVariation).variation_embolden, 0.5, 0.0001, "embolden 0.5")


func test_every_hud_label_uses_one_of_the_four_font_sizes() -> void:
	await _hud_in_base_viewport()
	var labels: Array[Label] = _labels_of(_hud)
	assert_gt(labels.size(), 7, "the HUD has its labels")
	for label: Label in labels:
		assert_has(
			FONT_SIZES, label.get_theme_font_size(&"font_size"), "font size of %s" % label.name
		)


func test_the_three_remapped_labels_use_their_new_sizes() -> void:
	await _hud_in_base_viewport()
	assert_eq((_hud.get_node("%RespawnLabel") as Label).get_theme_font_size(&"font_size"), 28)
	assert_eq((_hud.get_node("%FastForwardLabel") as Label).get_theme_font_size(&"font_size"), 22)
	assert_eq((_hud.get_node("%PayoutTotal") as Label).get_theme_font_size(&"font_size"), 22)


func test_the_remapped_labels_keep_their_positions() -> void:
	await _hud_in_base_viewport()
	var payout: Label = _hud.get_node("%PayoutTotal") as Label
	assert_eq(payout.position, Vector2(16.0, 52.0), "PayoutTotal stays at (16, 52)")
	var fast_forward: Label = _hud.get_node("%FastForwardLabel") as Label
	assert_eq(fast_forward.position.y, 60.0, "FastForwardLabel keeps its row")
	var respawn_box: Control = (_hud.get_node("%RespawnLabel") as Label).get_parent() as Control
	assert_eq(respawn_box.position.y, 100.0, "RespawnLabel keeps its row")


func test_gold_and_day_counter_labels_carry_a_black_outline_of_6() -> void:
	await _hud_in_base_viewport()
	var labels: Array[Label] = [_hud.get_node("%GoldLabel") as Label, _counter().get_label()]
	for label: Label in labels:
		assert_eq(
			label.get_theme_color(&"font_outline_color"), Color.BLACK, "%s colour" % label.name
		)
		assert_eq(label.get_theme_constant(&"outline_size"), OUTLINE_SIZE, "%s size" % label.name)


func test_the_day_counter_sits_in_the_top_band_clear_of_the_protected_rectangle() -> void:
	await _hud_in_base_viewport()
	var counter: DayCounter = _counter()
	var rect: Rect2 = counter.get_global_rect()
	assert_gte(rect.position.y, COUNTER_BAND_TOP, "starts at or below y 16")
	assert_lte(rect.end.y, COUNTER_BAND_BOTTOM, "ends at or above y 56")
	assert_false(rect.intersects(PROTECTED_RECT), "outside the protected rectangle")
	var label_rect: Rect2 = counter.get_label().get_global_rect()
	assert_false(label_rect.intersects(PROTECTED_RECT), "its text is outside it too")


func test_no_hud_node_beyond_the_named_exemptions_enters_the_protected_rectangle() -> void:
	await _hud_in_base_viewport()
	var allowed: Array[StringName] = [&"PhaseBanner", &"RespawnLabel"]
	for label: Label in _labels_of(_hud):
		if not label.is_visible_in_tree() or label.name in allowed:
			continue
		assert_false(
			label.get_global_rect().intersects(PROTECTED_RECT), "%s stays clear" % label.name
		)


func test_two_digit_night_numbers_stay_on_one_centred_line() -> void:
	await _hud_in_base_viewport()
	var counter: DayCounter = _counter()
	counter.show()
	var label: Label = counter.get_label()
	label.text = DayCounter.DAY_COUNTER_TEXT % [LONG_NIGHT, LONG_NIGHT]
	await wait_process_frames(SETTLE_FRAMES)
	assert_eq(label.get_line_count(), 1, "one line")
	var rect: Rect2 = label.get_global_rect()
	assert_almost_eq(rect.get_center().x, CENTRE_X, CENTRE_TOLERANCE_PX, "centred on x 640")
	assert_gte(rect.position.x, 0.0, "inside the left edge")
	assert_lte(rect.end.x, float(BASE_SIZE.x), "inside the right edge")


func test_the_text_is_clamped_to_the_total() -> void:
	assert_eq(DayCounter.text_for(1, 8), "Night 1 of 8", "the first night")
	assert_eq(DayCounter.text_for(9, 8), "Night 8 of 8", "never above the total")


func test_by_day_one_the_counter_reads_night_1_of_8() -> void:
	var map_root: MapRoot = await _spawn(E2eSupport.shipped_prototype_map())
	var counter: DayCounter = _day_counter_of(map_root)
	assert_true(counter.visible, "shown by day")
	assert_eq(counter.get_label().text, "Night 1 of 8", "the next night out of the total")


func test_the_counter_hides_while_the_night_banner_shows() -> void:
	var map_root: MapRoot = await _spawn(E2eSupport.shipped_prototype_map())
	var ctx: RunContext = map_root.get_context()
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	await wait_process_frames(SETTLE_FRAMES)
	assert_false(_day_counter_of(map_root).visible, "hidden at night")
	assert_true((map_root.get_node("HUD").get_node("%PhaseBanner") as Label).visible, "banner up")


func test_after_a_cleared_night_the_counter_reads_the_next_night_at_dawn_and_by_day() -> void:
	var map_root: MapRoot = await _spawn(E2eSupport.shipped_prototype_map())
	var ctx: RunContext = map_root.get_context()
	var counter: DayCounter = _day_counter_of(map_root)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	_clear_the_night(ctx)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "dawn began")
	assert_true(counter.visible, "shown at dawn")
	assert_eq(counter.get_label().text, "Night 2 of 8", "the next night at dawn")
	ctx.run_manager.tick(ctx.run_manager.get_phase_time_remaining() + 0.1)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAY, "day began")
	assert_true(counter.visible, "shown by day")
	assert_eq(counter.get_label().text, "Night 2 of 8", "the next night by day")


func test_the_counter_is_hidden_on_a_map_without_authored_nights() -> void:
	var map_root: MapRoot = await _spawn(E2eSupport.waveless_prototype_map())
	assert_false(_day_counter_of(map_root).visible, "no total, no counter")
