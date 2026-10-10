extends GutTest
## UI-01 / D-22 (plan 03-04): the bottom-left KingWidget on the real scene and laid out in a
## 1280x720 SubViewport. Health text and bar follow the simulation, the sword icon fills clockwise
## as the slam recharges and flashes once when it is ready, a refused press shakes the icon, a
## knocked-out king dims the widget, and the row never leaves x 16..376 / y 624..704 or enters the
## clear centre.
## The map's own process is switched off in the timing tests so the test steps the simulation by
## hand and nothing regenerates behind its back.

const HUD_SCENE := "res://ui/hud/hud.tscn"
const KING_PATH := "res://data/king/king.tres"
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
const BASE_SIZE := Vector2i(1280, 720)
const PROTECTED_RECT := Rect2(384.0, 96.0, 512.0, 404.0)
const WIDGET_LEFT: float = 16.0
const WIDGET_RIGHT: float = 376.0
const WIDGET_TOP: float = 624.0
const WIDGET_BOTTOM: float = 704.0
## 16 margin + 56 icon + 8 separation.
const BAR_LEFT: float = 80.0
const BAR_WIDTH: float = 192.0
const SETTLE_FRAMES: int = 3
const BAR_SETTLE_S: float = 0.4
const SHAKE_SETTLE_S: float = 0.4
const KO_ALPHA: float = 0.4
const MAX_STEPS: int = 4000
const LONG_MAX_HEALTH: int = 120
const LONG_HURT_TO: int = 87

var _viewport: SubViewport
var _hud: Hud
var _run: RunContext


func after_each() -> void:
	E2eSupport.release_all_actions()


func _spawn() -> MapRoot:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	map_root.handle_results_actions = false
	map_root.set_process(false)
	return map_root


func _widget_of(map_root: MapRoot) -> KingWidget:
	return map_root.get_node("HUD").find_child("KingWidget", true, false) as KingWidget


## Lays the real HUD out in a 1280x720 viewport and binds the king widget to a run made with `def`.
func _hud_in_base_viewport(def: KingDef = null) -> KingWidget:
	_viewport = SubViewport.new()
	_viewport.size = BASE_SIZE
	add_child_autofree(_viewport)
	var scene: PackedScene = load(HUD_SCENE)
	_hud = scene.instantiate()
	_viewport.add_child(_hud)
	var widget: KingWidget = _hud.find_child("KingWidget", true, false) as KingWidget
	_run = RunContext.new(E2eSupport.waveless_prototype_map(), load(TUNING_PATH), 1, def)
	widget.bind_run(_run, null)
	await wait_process_frames(SETTLE_FRAMES)
	return widget


func _king_def_with_health(max_health: int) -> KingDef:
	var def: KingDef = (load(KING_PATH) as KingDef).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	def.max_health = max_health
	return def


## The union of the global rects of the widget and every Control inside it (the caption included).
func _footprint(widget: KingWidget) -> Rect2:
	var rect: Rect2 = widget.get_global_rect()
	for node: Node in widget.find_children("*", "Control", true, false):
		rect = rect.merge((node as Control).get_global_rect())
	return rect


func _labels_in(widget: KingWidget) -> Array[Label]:
	var labels: Array[Label] = []
	for node: Node in widget.find_children("*", "Label", true, false):
		labels.append(node as Label)
	return labels


func _press_ability(frames: int) -> void:
	Input.action_press(&"ability")
	await wait_process_frames(frames)
	Input.action_release(&"ability")
	await wait_process_frames(frames)


func test_the_widget_lives_under_the_hud_root_and_ignores_the_mouse() -> void:
	var map_root: MapRoot = await _spawn()
	var widget: KingWidget = _widget_of(map_root)
	assert_not_null(widget, "the HUD has a KingWidget")
	if widget == null:
		return
	assert_eq(widget.get_parent().name, &"HudRoot", "under HudRoot")
	assert_true(widget.is_in_group(&"run_bound"), "bound to the run by the map")
	assert_eq(widget.mouse_filter, Control.MOUSE_FILTER_IGNORE, "the row ignores the mouse")
	for node: Node in widget.find_children("*", "Control", true, false):
		assert_eq(
			(node as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s ignores it" % node.name
		)


func test_by_day_the_label_reads_full_health_and_the_bar_is_full() -> void:
	var map_root: MapRoot = await _spawn()
	var widget: KingWidget = _widget_of(map_root)
	await wait_process_frames(SETTLE_FRAMES)
	assert_eq(widget.get_health_label().text, "50 / 50", "hp / max")
	assert_eq(widget.get_health_bar().value, 1.0, "the bar is full")
	assert_eq(widget.get_caption().text, KingWidget.ABILITY_CAPTION, "the icon is captioned")
	assert_eq(widget.modulate.a, 1.0, "at full strength")


func test_after_a_hit_the_label_reads_38_of_50_and_the_bar_settles_on_it() -> void:
	var map_root: MapRoot = await _spawn()
	var widget: KingWidget = _widget_of(map_root)
	map_root.get_context().king.take_damage(12)
	await wait_process_frames(SETTLE_FRAMES)
	assert_eq(widget.get_health_label().text, "38 / 50", "the text follows at once")
	var settled: bool = await E2eSupport.wait_until(
		self,
		func() -> bool: return absf(widget.get_health_bar().value - 38.0 / 50.0) < 0.001,
		BAR_SETTLE_S
	)
	assert_true(settled, "the bar settles on 38 / 50 within the tween")


func test_the_icon_empties_on_a_slam_and_fills_and_flashes_once_per_cooldown() -> void:
	var map_root: MapRoot = await _spawn()
	var ctx: RunContext = map_root.get_context()
	var widget: KingWidget = _widget_of(map_root)
	await wait_process_frames(SETTLE_FRAMES)
	var icon: TextureProgressBar = widget.get_ability_bar()
	assert_eq(icon.fill_mode, TextureProgressBar.FILL_CLOCKWISE, "it fills clockwise")
	assert_eq(icon.value, icon.max_value, "ready at the start")
	assert_eq(widget.ready_flash_count(), 0, "and no flash for starting ready")
	var cooldown: int = SimClock.ticks(ctx.king.get_weapon().slam_cooldown_seconds)
	for round_number: int in range(1, 3):
		assert_eq(ctx.commands.submit(ActivateAbilityIntent.new()), CommandProcessor.OK, "slam")
		await wait_process_frames(SETTLE_FRAMES)
		assert_eq(icon.value, 0.0, "the fill snaps to 0 right after the slam")
		for _i: int in range(cooldown):
			ctx.step()
		await wait_process_frames(SETTLE_FRAMES)
		assert_eq(icon.value, icon.max_value, "full again after the cooldown")
		assert_eq(widget.ready_flash_count(), round_number, "one flash per cooldown")


func test_the_plate_border_is_the_ready_colour_only_while_it_is_ready() -> void:
	var map_root: MapRoot = await _spawn()
	var ctx: RunContext = map_root.get_context()
	var widget: KingWidget = _widget_of(map_root)
	await wait_process_frames(SETTLE_FRAMES)
	var style: StyleBoxFlat = widget.get_plate().get_theme_stylebox("panel") as StyleBoxFlat
	assert_eq(style.border_color, KingWidget.READY_COLOR, "ready")
	ctx.commands.submit(ActivateAbilityIntent.new())
	await wait_process_frames(SETTLE_FRAMES)
	assert_eq(style.border_color, KingWidget.IDLE_BORDER_COLOR, "cooling")


func test_a_press_while_cooling_shakes_the_icon_and_shows_no_text() -> void:
	var map_root: MapRoot = await _spawn()
	var ctx: RunContext = map_root.get_context()
	var widget: KingWidget = _widget_of(map_root)
	ctx.commands.submit(ActivateAbilityIntent.new())
	await wait_process_frames(SETTLE_FRAMES)
	var health_text: String = widget.get_health_label().text
	await _press_ability(SETTLE_FRAMES)
	assert_eq(widget.shake_count(), 1, "one denied press, one shake")
	assert_eq(widget.get_caption().text, KingWidget.ABILITY_CAPTION, "the caption is unchanged")
	assert_eq(widget.get_health_label().text, health_text, "and no error text appears")
	var settled: bool = await E2eSupport.wait_until(
		self, func() -> bool: return absf(widget.get_plate().position.x) < 0.01, SHAKE_SETTLE_S
	)
	assert_true(settled, "the plate is back in place")


func test_a_press_while_knocked_out_shakes_the_icon_too() -> void:
	var map_root: MapRoot = await _spawn()
	var ctx: RunContext = map_root.get_context()
	var widget: KingWidget = _widget_of(map_root)
	ctx.king.take_damage(ctx.king.get_max_health())
	await wait_process_frames(SETTLE_FRAMES)
	await _press_ability(SETTLE_FRAMES)
	assert_eq(widget.shake_count(), 1, "a refused press shakes")
	assert_eq(ctx.king.ability_ticks_left(), 0, "and starts no cooldown")


func test_a_knocked_out_king_shows_zero_in_red_and_dims_the_widget_until_the_respawn() -> void:
	var map_root: MapRoot = await _spawn()
	var ctx: RunContext = map_root.get_context()
	var widget: KingWidget = _widget_of(map_root)
	assert_true(ctx.run_manager.start_night(), "the timed night starts")
	ctx.king.take_damage(ctx.king.get_max_health())
	await wait_process_frames(SETTLE_FRAMES)
	var label: Label = widget.get_health_label()
	assert_eq(label.text, "0 / 50", "0 / 50")
	assert_eq(label.get_theme_color(&"font_color"), Color("#FF4040"), "in red")
	assert_almost_eq(widget.modulate.a, KO_ALPHA, 0.001, "the widget is dimmed to 0.4")
	assert_eq(widget.get_health_bar().value, 0.0, "the bar is empty")
	var steps: int = 0
	while ctx.king.is_down() and steps < MAX_STEPS:
		ctx.step()
		steps += 1
	assert_false(ctx.king.is_down(), "he is back")
	await wait_process_frames(SETTLE_FRAMES)
	assert_eq(widget.modulate.a, 1.0, "full strength again")
	assert_eq(label.text, "50 / 50", "full health")
	assert_eq(label.get_theme_color(&"font_color"), Color.WHITE, "in white")
	assert_eq(widget.get_health_bar().value, 1.0, "the bar jumps to full at once")


func test_the_widget_stays_in_its_corner_and_clear_of_the_centre() -> void:
	var widget: KingWidget = await _hud_in_base_viewport()
	var footprint: Rect2 = _footprint(widget)
	assert_gte(footprint.position.x, WIDGET_LEFT, "left edge")
	assert_lte(footprint.end.x, WIDGET_RIGHT, "right edge")
	assert_gte(footprint.position.y, WIDGET_TOP, "top, caption included")
	assert_lte(footprint.end.y, WIDGET_BOTTOM, "bottom")
	assert_false(footprint.intersects(PROTECTED_RECT), "outside the protected rectangle")


func test_the_icon_bar_and_label_have_the_specified_sizes() -> void:
	var widget: KingWidget = await _hud_in_base_viewport()
	assert_eq(widget.get_plate().get_global_rect().size, Vector2(56.0, 56.0), "the icon is 56x56")
	assert_eq(widget.get_health_bar().size, Vector2(BAR_WIDTH, 24.0), "the bar is 192x24")
	assert_eq(widget.get_health_bar().get_global_rect().position.x, BAR_LEFT, "8 px after the icon")
	assert_eq(widget.get_health_label().custom_minimum_size.x, 96.0, "the label holds 96 px")
	assert_eq(widget.get_ability_bar().size, Vector2(48.0, 48.0), "the fill is 48x48")


func test_every_label_uses_size_22_or_18_with_the_outline() -> void:
	var widget: KingWidget = await _hud_in_base_viewport()
	assert_eq(_labels_in(widget).size(), 2, "the caption and the health text")
	assert_eq(widget.get_health_label().get_theme_font_size(&"font_size"), 22, "health text")
	assert_eq(widget.get_caption().get_theme_font_size(&"font_size"), 18, "caption")
	for label: Label in _labels_in(widget):
		assert_eq(label.get_theme_constant(&"outline_size"), 6, "%s outline" % label.name)
		assert_eq(
			label.get_theme_color(&"font_outline_color"), Color.BLACK, "%s colour" % label.name
		)


func test_five_of_fifty_and_fifty_of_fifty_do_not_shift_the_row() -> void:
	var widget: KingWidget = await _hud_in_base_viewport()
	var label: Label = widget.get_health_label()
	assert_eq(label.text, "50 / 50", "full")
	var full_bar: Rect2 = widget.get_health_bar().get_global_rect()
	var full_label_x: float = label.get_global_rect().position.x
	_run.king.take_damage(45)
	await wait_process_frames(SETTLE_FRAMES)
	assert_eq(label.text, "5 / 50", "nearly empty")
	assert_eq(widget.get_health_bar().get_global_rect().position.x, full_bar.position.x, "bar x")
	assert_eq(widget.get_health_bar().get_global_rect().size.x, full_bar.size.x, "bar width")
	assert_eq(label.get_global_rect().position.x, full_label_x, "label x")
	assert_eq(full_bar.position.x, BAR_LEFT, "the bar sits at x 80")


func test_a_king_of_120_health_grows_the_label_right_without_reflowing_the_row() -> void:
	var widget: KingWidget = await _hud_in_base_viewport(_king_def_with_health(LONG_MAX_HEALTH))
	_run.king.take_damage(LONG_MAX_HEALTH - LONG_HURT_TO)
	await wait_process_frames(SETTLE_FRAMES)
	var label: Label = widget.get_health_label()
	assert_eq(label.text, "87 / 120", "hp / max")
	assert_eq(label.get_line_count(), 1, "on one line")
	var bar_rect: Rect2 = widget.get_health_bar().get_global_rect()
	assert_eq(bar_rect.position.x, BAR_LEFT, "the bar keeps its x")
	assert_eq(bar_rect.size.x, BAR_WIDTH, "and its width")
	assert_eq(widget.get_global_rect().position.x, WIDGET_LEFT, "the left edge stays at 16")
	assert_gte(
		label.get_global_rect().position.x, bar_rect.end.x, "the label sits right of the bar"
	)


func test_the_sword_icon_is_a_white_sword_on_a_transparent_square() -> void:
	var texture: ImageTexture = SwordIcon.make_texture(48)
	assert_eq(texture.get_size(), Vector2(48.0, 48.0), "48 square")
	var image: Image = texture.get_image()
	assert_eq(image.get_pixel(0, 0).a, 0.0, "the corner is clear")
	assert_eq(image.get_pixel(24, 20), Color.WHITE, "the blade is white")
	assert_eq(image.get_pixel(24, 32), Color.WHITE, "so is the guard")
	var small: ImageTexture = SwordIcon.make_texture(24)
	assert_eq(small.get_size(), Vector2(24.0, 24.0), "it scales")
	assert_eq(small.get_image().get_pixel(12, 10), Color.WHITE, "and keeps the blade")
