extends GutTest
## UI-01 / D-21 / G-03-14b (plan 03-15): the start-night prompt and its fill bar sit on their own
## plate so the prompt stays the day focal point beside a cyan selected squad slot. The real HUD is
## laid out in a 1280x720 SubViewport with the night preview showing on a long line, and the rects
## are measured, never estimated: the plate runs from 8 px below the SquadStrip to at most y 700,
## the preview line sits unplated under it, and neither the plate nor its rows swallow a click.

const HUD_SCENE := "res://ui/hud/hud.tscn"
const BASE_SIZE := Vector2i(1280, 720)
const PROTECTED_RECT := Rect2(384.0, 96.0, 512.0, 404.0)
const STRIP_BOTTOM: float = 616.0
const PLATE_TOP: float = 624.0
const PLATE_BOTTOM_MAX: float = 700.0
const PREVIEW_BOTTOM_MAX: float = 716.0
const PREVIEW_FONT_SIZE: int = 18
const INSET: float = 8.0
const RADIUS: int = 8
const LONG_PREVIEW := "Night 8: 99 enemies from 3 directions"
const HINT_ROW_TOP: float = 504.0
const HINT_ROW_BOTTOM: float = 536.0
const PLATE_COLOR := Color(0.0784, 0.0784, 0.1019, 0.78)
const COLOR_TOLERANCE: float = 0.002
const TOLERANCE_PX: float = 0.5
const SETTLE_FRAMES: int = 3

var _hud: Hud


func after_each() -> void:
	E2eSupport.release_all_actions()


## The HUD laid out at the base size with the preview made visible, as it is by day.
func _setup() -> void:
	var viewport := SubViewport.new()
	viewport.size = BASE_SIZE
	add_child_autofree(viewport)
	var scene: PackedScene = load(HUD_SCENE)
	_hud = scene.instantiate()
	viewport.add_child(_hud)
	var preview: Label = _hud.find_child("NightPreview", true, false) as Label
	preview.text = LONG_PREVIEW
	preview.visible = true
	await wait_process_frames(SETTLE_FRAMES)


func _plate() -> PanelContainer:
	return _hud.find_child("StartNightPlate", true, false) as PanelContainer


func _rect_of(node_name: String) -> Rect2:
	var control: Control = _hud.find_child(node_name, true, false) as Control
	assert_not_null(control, "the HUD has a %s" % node_name)
	if control == null:
		return Rect2()
	return control.get_global_rect()


func test_the_plate_sits_between_the_strip_and_the_screen_bottom() -> void:
	await _setup()
	var plate: PanelContainer = _plate()
	assert_not_null(plate, "the HUD has a StartNightPlate")
	if plate == null:
		return
	var rect: Rect2 = plate.get_global_rect()
	assert_almost_eq(rect.position.y, PLATE_TOP, TOLERANCE_PX, "8 px below the strip's y 616")
	assert_almost_eq(rect.position.y - STRIP_BOTTOM, INSET, TOLERANCE_PX, "the strip gap is 8")
	assert_lte(rect.end.y, PLATE_BOTTOM_MAX, "the plate ends at or above y 700")
	var box_rect: Rect2 = _rect_of("StartNightBox")
	assert_almost_eq(box_rect.position.y, PLATE_TOP, TOLERANCE_PX, "the box keeps y 624")


func test_the_prompt_and_the_fill_sit_8_px_inside_the_plate() -> void:
	await _setup()
	var plate: Rect2 = _rect_of("StartNightPlate")
	var prompt: Rect2 = _rect_of("StartNightPrompt")
	var fill: Rect2 = _rect_of("StartNightFill")
	assert_almost_eq(prompt.position.y - plate.position.y, INSET, TOLERANCE_PX, "prompt 8 px down")
	assert_almost_eq(fill.position.x - plate.position.x, INSET, TOLERANCE_PX, "fill 8 px in left")
	assert_almost_eq(plate.end.x - fill.end.x, INSET, TOLERANCE_PX, "fill 8 px in right")
	assert_almost_eq(plate.end.y - fill.end.y, INSET, TOLERANCE_PX, "fill 8 px above the bottom")


func test_the_preview_stays_below_the_plate_unplated_and_on_screen() -> void:
	await _setup()
	var plate: Rect2 = _rect_of("StartNightPlate")
	var preview_node: Label = _hud.find_child("NightPreview", true, false) as Label
	var preview: Rect2 = preview_node.get_global_rect()
	assert_gte(preview.position.y, plate.end.y, "the preview starts at or below the plate")
	assert_lte(preview.end.y, PREVIEW_BOTTOM_MAX, "and ends at or above y 716")
	assert_eq(preview_node.get_theme_font_size(&"font_size"), PREVIEW_FONT_SIZE, "still 18 px")
	var plate_node: Control = _plate()
	assert_not_null(plate_node, "the HUD has a StartNightPlate")
	if plate_node != null:
		assert_false(plate_node.is_ancestor_of(preview_node), "it is not on the plate")


func test_the_plate_stays_clear_of_the_centre_the_king_widget_and_the_hint_row() -> void:
	await _setup()
	var plate: Rect2 = _rect_of("StartNightPlate")
	assert_false(plate.intersects(PROTECTED_RECT), "outside the protected centre")
	var king: Control = _hud.find_child("KingWidget", true, false) as Control
	var king_rect: Rect2 = king.get_global_rect()
	for node: Node in king.find_children("*", "Control", true, false):
		king_rect = king_rect.merge((node as Control).get_global_rect())
	assert_false(plate.intersects(king_rect), "clear of the king widget")
	var hint_row := Rect2(0.0, HINT_ROW_TOP, float(BASE_SIZE.x), HINT_ROW_BOTTOM - HINT_ROW_TOP)
	assert_false(plate.intersects(hint_row), "clear of the hint and toast row")


func test_the_plate_is_the_dominant_panel_colour_and_ignores_the_mouse() -> void:
	await _setup()
	var plate: PanelContainer = _plate()
	assert_not_null(plate, "the HUD has a StartNightPlate")
	if plate == null:
		return
	var style: StyleBoxFlat = plate.get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_not_null(style, "the panel is a StyleBoxFlat")
	if style == null:
		return
	assert_almost_eq(style.bg_color.r, PLATE_COLOR.r, COLOR_TOLERANCE, "red")
	assert_almost_eq(style.bg_color.g, PLATE_COLOR.g, COLOR_TOLERANCE, "green")
	assert_almost_eq(style.bg_color.b, PLATE_COLOR.b, COLOR_TOLERANCE, "blue")
	assert_almost_eq(style.bg_color.a, PLATE_COLOR.a, COLOR_TOLERANCE, "alpha 0.78")
	assert_eq(style.corner_radius_top_left, RADIUS, "radius top left")
	assert_eq(style.corner_radius_top_right, RADIUS, "radius top right")
	assert_eq(style.corner_radius_bottom_left, RADIUS, "radius bottom left")
	assert_eq(style.corner_radius_bottom_right, RADIUS, "radius bottom right")
	assert_eq(style.get_content_margin(SIDE_LEFT), float(INSET), "margin left")
	assert_eq(style.get_content_margin(SIDE_TOP), float(INSET), "margin top")
	assert_eq(style.get_content_margin(SIDE_RIGHT), float(INSET), "margin right")
	assert_eq(style.get_content_margin(SIDE_BOTTOM), float(INSET), "margin bottom")
	assert_eq(plate.mouse_filter, Control.MOUSE_FILTER_IGNORE, "the plate ignores the mouse")
	var rows: Control = _hud.find_child("StartNightRows", true, false) as Control
	assert_not_null(rows, "the plate holds a StartNightRows")
	if rows != null:
		assert_eq(rows.mouse_filter, Control.MOUSE_FILTER_IGNORE, "so do its rows")


func test_the_plate_shows_by_day_and_hides_at_night() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, E2eSupport.waveless_prototype_map())
	var plate: Control = (
		map_root.get_node("HUD").find_child("StartNightPlate", true, false) as Control
	)
	assert_not_null(plate, "the map's HUD has a StartNightPlate")
	if plate == null:
		return
	assert_true(plate.visible, "shown by day")
	var ctx: RunContext = map_root.get_context()
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	await wait_process_frames(SETTLE_FRAMES)
	assert_false(plate.visible, "hidden once the night has started")
