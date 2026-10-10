class_name PromptGlyph
extends Control
## D-24 / INPT-02: one on-screen key or button prompt. It shows the Kenney tile of the first binding
## of `action` on the device in use, drawn at a fixed `glyph_size` (24 or 32 px, never scaled with
## text) on a #14141A plate at alpha 0.78 with radius 4, because the tiles are white on
## transparent. When the pack has no tile for the binding it shows a text keycap instead (radius 4,
## #3A3F4B plate, 2 px #C8CCD4 border, Label 18), which widens to fit a long name like "Backspace".
## An action with no binding on the device shows the "(unbound)" keycap, so a verb is never hidden
## silently.
##
## A runtime rebind is noticed once a frame while the glyph is on screen. Display only.

const PLATE_COLOR := Color(0.0784, 0.0784, 0.1019, 0.78)
const PLATE_RADIUS: int = 4
const KEYCAP_COLOR := Color("#3A3F4B")
const KEYCAP_BORDER_COLOR := Color("#C8CCD4")
const KEYCAP_BORDER_WIDTH: int = 2
const KEYCAP_FONT_SIZE: int = 18
const KEYCAP_PADDING: int = 4
const OUTLINE_SIZE: int = 6

@export var action: StringName = &""
## 24 for hints and badges, 32 for the start-night prompt.
@export_range(24, 32, 8) var glyph_size: int = 24

## Maps a physical keycode to the keycode the layout prints on that key (see GlyphResolver).
var label_resolver: Callable = GlyphResolver.layout_label

var _device: int = GlyphResolver.DEVICE_KEYBOARD
var _tile: Texture2D
var _shown: String = ""
var _is_keycap: bool = false
var _signature: String = ""
var _plate_style: StyleBoxFlat
var _keycap: PanelContainer
var _keycap_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_plate_style = StyleBoxFlat.new()
	_plate_style.bg_color = PLATE_COLOR
	_plate_style.set_corner_radius_all(PLATE_RADIUS)
	_build_keycap()
	render(_device)


## Shows the tile or keycap of `action` on `device` (GlyphResolver.DEVICE_KEYBOARD or DEVICE_PAD).
func render(device: int) -> void:
	_device = device
	if _keycap == null:
		return
	var event: InputEvent = GlyphResolver.first_event(action, device)
	_signature = _signature_of(event)
	var path: String = GlyphResolver.tile_path(event, label_resolver)
	_tile = null
	if not path.is_empty():
		_tile = load(path) as Texture2D
	if _tile != null:
		_is_keycap = false
		_shown = path.get_file().get_basename()
		_keycap.visible = false
		custom_minimum_size = Vector2(glyph_size, glyph_size)
	else:
		_is_keycap = true
		_shown = GlyphResolver.keycap_text(event, label_resolver)
		_keycap_label.text = _shown
		_keycap.visible = true
		var wanted: Vector2 = _keycap.get_combined_minimum_size()
		custom_minimum_size = Vector2(maxf(wanted.x, glyph_size), maxf(wanted.y, glyph_size))
	size = custom_minimum_size
	queue_redraw()


## True while the glyph shows a text keycap instead of a tile.
func is_keycap() -> bool:
	return _is_keycap


## What the glyph shows: the keycap's text, or the tile's file name without extension
## ("keyboard_q", "xbox_button_x") for a tile.
func shown_text() -> String:
	return _shown


## The device this glyph was last rendered for.
func device() -> int:
	return _device


func _process(_delta: float) -> void:
	if action.is_empty() or not is_visible_in_tree():
		return
	if _signature_of(GlyphResolver.first_event(action, _device)) != _signature:
		render(_device)


func _draw() -> void:
	if _tile == null:
		return
	var rect: Rect2 = Rect2(Vector2.ZERO, Vector2(glyph_size, glyph_size))
	draw_style_box(_plate_style, rect)
	draw_texture_rect(_tile, rect, false)


func _build_keycap() -> void:
	_keycap = PanelContainer.new()
	_keycap.name = "Keycap"
	_keycap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_keycap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = KEYCAP_COLOR
	style.set_corner_radius_all(PLATE_RADIUS)
	style.set_border_width_all(KEYCAP_BORDER_WIDTH)
	style.border_color = KEYCAP_BORDER_COLOR
	style.content_margin_left = KEYCAP_PADDING + KEYCAP_BORDER_WIDTH
	style.content_margin_right = KEYCAP_PADDING + KEYCAP_BORDER_WIDTH
	style.content_margin_top = 0.0
	style.content_margin_bottom = 0.0
	_keycap.add_theme_stylebox_override("panel", style)
	_keycap_label = Label.new()
	_keycap_label.name = "Text"
	_keycap_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_keycap_label.add_theme_font_size_override("font_size", KEYCAP_FONT_SIZE)
	_keycap_label.add_theme_color_override("font_color", Color.WHITE)
	_keycap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_keycap_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_keycap.add_child(_keycap_label)
	add_child(_keycap)
	_keycap.visible = false


## What identifies the binding being shown: its text and its tile, so an edit made in place to the
## same event object (a runtime rebind) is noticed.
func _signature_of(event: InputEvent) -> String:
	return (
		"%s|%s"
		% [
			GlyphResolver.keycap_text(event, label_resolver),
			GlyphResolver.tile_path(event, label_resolver)
		]
	)
