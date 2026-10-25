extends GutTest
## UI-01 / D-22 (plan 03-04): the bottom-left KingWidget on the real scene and laid out in a
## 1280x720 SubViewport. Health text and bar follow the simulation, the sword icon fills clockwise
## as the slam recharges and flashes once when it is ready, a refused press shakes the icon, a
## knocked-out king dims the bar and the icon but keeps the count and the caption opaque, and the
## row never leaves x 16..408 / y 624..704 or enters the clear centre.
## Gap round G-05-2 (the x100 rescale): the health reads as it is, '5000 / 5000', and the label
## holds 128 px, enough for Royal Training's '6250 / 6250'.
## The map's own process is switched off in the timing tests so the test steps the simulation by
## hand and nothing regenerates behind its back.

const HUD_SCENE := "res://ui/hud/hud.tscn"
const KING_PATH := "res://data/king/king.tres"
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
const BASE_SIZE := Vector2i(1280, 720)
const PROTECTED_RECT := Rect2(384.0, 96.0, 512.0, 404.0)
const WIDGET_LEFT: float = 16.0
const WIDGET_RIGHT: float = 408.0
const WIDGET_TOP: float = 624.0
const WIDGET_BOTTOM: float = 704.0
## 16 margin + 56 icon + 8 separation.
const BAR_LEFT: float = 80.0
const BAR_WIDTH: float = 192.0
const SETTLE_FRAMES: int = 3
const BAR_SETTLE_S: float = 0.4
const SHAKE_SETTLE_S: float = 0.4
const KO_ALPHA: float = 0.4
## WCAG AA for normal text.
const MIN_CONTRAST: float = 4.5
const MAX_STEPS: int = 4000
const LONG_MAX_HEALTH: int = 12000
const LONG_HURT_TO: int = 8700

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


## Asserts the knocked-out dimming rule at `expected` alpha: the bar, the plate panel (its own
## self_modulate), the sword icon and the slam glyph dim, the caption and the count never do.
func _assert_dimmed(widget: KingWidget, expected: float, when: String) -> void:
	assert_almost_eq(widget.get_health_bar().modulate.a, expected, 0.001, "%s: bar" % when)
	assert_almost_eq(widget.get_plate().self_modulate.a, expected, 0.001, "%s: plate" % when)
	assert_almost_eq(widget.get_ability_bar().modulate.a, expected, 0.001, "%s: sword" % when)
	assert_almost_eq(widget.get_ability_glyph().modulate.a, expected, 0.001, "%s: glyph" % when)
	assert_almost_eq(_effective_alpha(widget.get_health_label()), 1.0, 0.001, "%s: count" % when)
	assert_almost_eq(_effective_alpha(widget.get_caption()), 1.0, 0.001, "%s: caption" % when)


## The node's own modulate.a and self_modulate.a times the modulate.a of every CanvasItem ancestor.
## An ancestor's self_modulate tints only that ancestor's own drawing, so it is not multiplied in.
func _effective_alpha(item: CanvasItem) -> float:
	var alpha: float = item.modulate.a * item.self_modulate.a
	var node: Node = item.get_parent()
	while node != null:
		if node is CanvasItem:
			alpha *= (node as CanvasItem).modulate.a
		node = node.get_parent()
	return alpha


## `top` drawn over `below` at `alpha` times top.a (a straight sRGB "over" blend).
func _over(top: Color, alpha: float, below: Color) -> Color:
	var weight: float = clampf(alpha * top.a, 0.0, 1.0)
	return Color(
		lerpf(below.r, top.r, weight),
		lerpf(below.g, top.g, weight),
		lerpf(below.b, top.b, weight),
		1.0
	)


func _linear(channel: float) -> float:
	if channel <= 0.04045:
		return channel / 12.92
	return pow((channel + 0.055) / 1.055, 2.4)


## WCAG relative luminance of an sRGB colour.
func _luminance(color: Color) -> float:
	return 0.2126 * _linear(color.r) + 0.7152 * _linear(color.g) + 0.0722 * _linear(color.b)


## WCAG contrast ratio of two colours, (lighter + 0.05) / (darker + 0.05).
func _contrast(first: Color, second: Color) -> float:
	var lighter: float = maxf(_luminance(first), _luminance(second))
	var darker: float = minf(_luminance(first), _luminance(second))
	return (lighter + 0.05) / (darker + 0.05)


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
	assert_eq(widget.get_health_label().text, "5000 / 5000", "hp / max")
	assert_eq(widget.get_health_bar().value, 1.0, "the bar is full")
	assert_eq(widget.get_caption().text, KingWidget.ABILITY_CAPTION, "the icon is captioned")
	assert_eq(widget.modulate.a, 1.0, "at full strength")


func test_after_a_hit_the_label_reads_3800_of_5000_and_the_bar_settles_on_it() -> void:
	var map_root: MapRoot = await _spawn()
	var widget: KingWidget = _widget_of(map_root)
	map_root.get_context().king.take_damage(1200)
	await wait_process_frames(SETTLE_FRAMES)
	assert_eq(widget.get_health_label().text, "3800 / 5000", "the text follows at once")
	var settled: bool = await E2eSupport.wait_until(
		self,
		func() -> bool: return absf(widget.get_health_bar().value - 3800.0 / 5000.0) < 0.001,
		BAR_SETTLE_S
	)
	assert_true(settled, "the bar settles on 3800 / 5000 within the tween")


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


func test_a_knocked_out_king_keeps_the_count_and_caption_opaque_and_dims_the_rest() -> void:
	var map_root: MapRoot = await _spawn()
	var ctx: RunContext = map_root.get_context()
	var widget: KingWidget = _widget_of(map_root)
	assert_true(ctx.run_manager.start_night(), "the timed night starts")
	ctx.king.take_damage(ctx.king.get_max_health())
	await wait_process_frames(SETTLE_FRAMES)
	var label: Label = widget.get_health_label()
	var caption: Label = widget.get_caption()
	assert_eq(label.text, "0 / 5000", "0 / 5000")
	assert_eq(label.get_theme_color(&"font_color"), Color("#FF4040"), "in red")
	assert_eq(widget.modulate.a, 1.0, "the widget as a whole is not dimmed")
	assert_almost_eq(_effective_alpha(label), 1.0, 0.001, "the count stays opaque")
	assert_almost_eq(_effective_alpha(caption), 1.0, 0.001, "and so does the caption")
	assert_eq(label.get_theme_constant(&"outline_size"), KingWidget.OUTLINE_SIZE, "count outline")
	assert_eq(caption.get_theme_constant(&"outline_size"), KingWidget.OUTLINE_SIZE, "caption")
	_assert_dimmed(widget, KO_ALPHA, "knocked out")
	assert_eq(widget.get_health_bar().value, 0.0, "the bar is empty")
	var steps: int = 0
	while ctx.king.is_down() and steps < MAX_STEPS:
		ctx.step()
		steps += 1
	assert_false(ctx.king.is_down(), "he is back")
	await wait_process_frames(SETTLE_FRAMES)
	_assert_dimmed(widget, 1.0, "after the respawn")
	assert_eq(label.text, "5000 / 5000", "full health")
	assert_eq(label.get_theme_color(&"font_color"), Color.WHITE, "in white")
	assert_false(label.has_theme_color_override(&"font_color"), "the red override is gone")
	assert_eq(widget.get_health_bar().value, 1.0, "the bar jumps to full at once")


## G-03-13 (UAT test 13): the knocked-out "0 / 5000" and the "Slam" caption read against their own
## outline. Neither sits on a panel (the label is beside the bar, the caption above the plate), and
## Godot draws the outline opaque and contiguous around every glyph, so the outline is the glyphs'
## immediate surround and the 3D ground behind it does not enter the fill-over-outline ratio.
## The one composite over black is kept only so that a regressed alpha shows up as a number. The
## real-window check of the same ratio is tools/contrast_probe.sh on screenshots/hud_king_down.png.
func test_the_knocked_out_count_reads_at_least_4_5_to_1_on_its_opaque_outline() -> void:
	var map_root: MapRoot = await _spawn()
	var ctx: RunContext = map_root.get_context()
	var widget: KingWidget = _widget_of(map_root)
	assert_true(ctx.run_manager.start_night(), "the timed night starts")
	ctx.king.take_damage(ctx.king.get_max_health())
	await wait_process_frames(SETTLE_FRAMES)
	for label: Label in [widget.get_health_label(), widget.get_caption()]:
		var outline: Color = label.get_theme_color(&"font_outline_color")
		var alpha: float = _effective_alpha(label)
		assert_eq(outline.a, 1.0, "%s outline is opaque" % label.name)
		assert_gte(
			label.get_theme_constant(&"outline_size"),
			KingWidget.OUTLINE_SIZE,
			"%s outline is at least 6" % label.name
		)
		assert_almost_eq(alpha, 1.0, 0.001, "%s has an effective alpha of 1.0" % label.name)
		var backdrop: Color = _over(outline, alpha * outline.a, Color.BLACK)
		var text: Color = _over(label.get_theme_color(&"font_color"), alpha, backdrop)
		assert_gte(
			_contrast(text, backdrop), MIN_CONTRAST, "%s over its outline is 4.5:1" % label.name
		)


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
	assert_eq(widget.get_health_label().custom_minimum_size.x, 128.0, "the label holds 128 px")
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


func test_a_nearly_empty_and_a_full_label_do_not_shift_the_row() -> void:
	var widget: KingWidget = await _hud_in_base_viewport()
	var label: Label = widget.get_health_label()
	assert_eq(label.text, "5000 / 5000", "full")
	var full_bar: Rect2 = widget.get_health_bar().get_global_rect()
	var full_label_x: float = label.get_global_rect().position.x
	_run.king.take_damage(4500)
	await wait_process_frames(SETTLE_FRAMES)
	assert_eq(label.text, "500 / 5000", "nearly empty")
	assert_eq(widget.get_health_bar().get_global_rect().position.x, full_bar.position.x, "bar x")
	assert_eq(widget.get_health_bar().get_global_rect().size.x, full_bar.size.x, "bar width")
	assert_eq(label.get_global_rect().position.x, full_label_x, "label x")
	assert_eq(full_bar.position.x, BAR_LEFT, "the bar sits at x 80")


func test_a_king_of_12000_health_grows_the_label_right_without_reflowing_the_row() -> void:
	var widget: KingWidget = await _hud_in_base_viewport(_king_def_with_health(LONG_MAX_HEALTH))
	_run.king.take_damage(LONG_MAX_HEALTH - LONG_HURT_TO)
	await wait_process_frames(SETTLE_FRAMES)
	var label: Label = widget.get_health_label()
	assert_eq(label.text, "8700 / 12000", "hp / max")
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


func test_royal_trainings_king_fits_the_label_without_moving_the_right_edge() -> void:
	var widget: KingWidget = await _hud_in_base_viewport()
	var card: ChoiceDef = load("res://data/abilities/royal_training.tres") as ChoiceDef
	assert_true(_run.stat_stack.add_source(&"royal_training", card.modifiers), "the card arms")
	await wait_process_frames(SETTLE_FRAMES)
	var label: Label = widget.get_health_label()
	assert_eq(label.text, "6250 / 6250", "Royal Training's king at full health")
	assert_lte(label.size.x, KingWidget.LABEL_MIN_WIDTH, "the widest shipped label fits")
	assert_lte(_footprint(widget).end.x, WIDGET_RIGHT, "and the row keeps its right edge")
