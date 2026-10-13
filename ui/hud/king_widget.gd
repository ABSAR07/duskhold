class_name KingWidget
extends HBoxContainer
## UI-01 / D-22: the king's lifeline, bottom-left. A 56x56 ability icon (a sword that fills
## clockwise as the slam recharges, a one-shot flash when it is ready, a caption "Slam" above it),
## then a 192x24 health bar with "hp / max" beside it. It never hides. Display only: it polls the
## simulation each frame (health, knockout, cooldown ratio) and never writes it. Every part
## ignores the mouse. The widget row spans x 16..376 and y 648..704 at 1280x720, the caption
## reaches up to y 624, and nothing of it enters the protected clear centre.
##
## Knocked out (KING-06): the bar is empty and the label reads "0 / 50" in red. The bar, the plate
## panel (its own self_modulate), the sword icon and the slam glyph dim to alpha 0.4; the count and
## the "Slam" caption stay at full alpha (G-03-13). Neither sits on a panel (the label is beside the
## bar, the caption above the plate), and the opaque black outline Godot draws around every glyph is
## their immediate surround, which is why they read at 4.5:1 or better whatever the ground is. The
## RespawnLabel carries the countdown. A respawn restores everything without a flash. A press that
## the command gate refused (AbilityController.denied) shakes the icon; there is no error text.

const HEALTH_TEXT := "%d / %d"
const ABILITY_CAPTION := "Slam"
const ICON_SIZE: float = 56.0
const ICON_INNER: int = 48
const ICON_INSET: float = 4.0
## D-24: the slam key or button, a 24 px glyph in the bottom-right corner of the plate.
const GLYPH_SIZE: int = 24
## A long key name widens the glyph to the left; it stops this far left of the plate, on screen.
const GLYPH_MIN_X: float = -12.0
const ABILITY_ACTION: StringName = &"ability"
const BAR_SIZE := Vector2(192.0, 24.0)
const LABEL_MIN_WIDTH: float = 96.0
const ROW_SEPARATION: int = 8
const CAPTION_SIZE := Vector2(56.0, 24.0)
const CAPTION_OFFSET := Vector2(0.0, -24.0)
const HEALTH_FONT_SIZE: int = 22
const CAPTION_FONT_SIZE: int = 18
const OUTLINE_SIZE: int = 6
const KNOCKED_OUT_COLOR := Color("#FF4040")
const KNOCKED_OUT_ALPHA: float = 0.4
const READY_COLOR := Color("#8CEBFF")
const IDLE_BORDER_COLOR := Color("#3A3F4B")
const UNDER_TINT := Color("#5A5F6B")
const BAR_FILL_COLOR := Color("#D9332E")
## #14141A at alpha 0.78.
const PLATE_COLOR := Color(0.0784, 0.0784, 0.1019, 0.78)
const BAR_TWEEN_SECONDS: float = 0.15
const DAMAGE_FLASH_SECONDS: float = 0.1
const READY_SCALE: float = 1.2
const READY_SCALE_SECONDS: float = 0.25
const READY_TINT_SECONDS: float = 0.2
const USE_SCALE: float = 0.9
const USE_SCALE_SECONDS: float = 0.12
const SHAKE_PIXELS: float = 3.0
const SHAKE_STEP_SECONDS: float = 0.025
const SHAKE_OSCILLATIONS: int = 3

var _ctx: RunContext
var _plate: Panel
var _plate_style: StyleBoxFlat
var _icon_bar: TextureProgressBar
var _caption: Label
var _ability_glyph: PromptGlyph
var _health_bar: ProgressBar
var _bar_background: StyleBoxFlat
var _health_label: Label
var _shown_health: int = -1
var _shown_max: int = -1
var _shown_down: bool = false
var _was_ready: bool = true
var _ready_flashes: int = 0
var _shakes: int = 0
var _bar_tween: Tween
var _plate_tween: Tween
var _tint_tween: Tween
var _shake_tween: Tween
var _border_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", ROW_SEPARATION)
	_build_ability_icon()
	_build_health()


## Binds the widget to one run: it reads the king from `ctx`, flashes on a hit, pulses on a slam
## and shakes when the AbilityController (found under the map root) refuses a press. A repeat call
## is ignored so no signal is connected twice.
func bind_run(ctx: RunContext, map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	ctx.events.king_damaged.connect(_on_king_damaged)
	ctx.events.king_ability_used.connect(_on_king_ability_used)
	if map_root != null:
		var controller: AbilityController = (
			map_root.find_child("AbilityController", true, false) as AbilityController
		)
		if controller != null:
			controller.denied.connect(_on_denied)
	if map_root != null:
		_ability_glyph.bind_device(map_root.get_device_tracker())
	_was_ready = ctx.king.ability_cooldown_ratio() >= 1.0
	_sync_health(true)
	_sync_ability()


## Times the ready flash has played. Test hook, read-only.
func ready_flash_count() -> int:
	return _ready_flashes


## Times the denied shake has played. Test hook, read-only.
func shake_count() -> int:
	return _shakes


func get_health_bar() -> ProgressBar:
	return _health_bar


func get_health_label() -> Label:
	return _health_label


func get_ability_bar() -> TextureProgressBar:
	return _icon_bar


func get_plate() -> Panel:
	return _plate


func get_caption() -> Label:
	return _caption


## The glyph of the slam key or button on the ability badge. Test hook.
func get_ability_glyph() -> PromptGlyph:
	return _ability_glyph


func _process(_delta: float) -> void:
	if _ctx == null:
		return
	_sync_health(false)
	_sync_ability()
	_place_glyph()


func _build_ability_icon() -> void:
	var icon: Control = Control.new()
	icon.name = "AbilityIcon"
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	_plate_style = _make_style(PLATE_COLOR, 8, IDLE_BORDER_COLOR, 2)
	_plate = Panel.new()
	_plate.name = "Plate"
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.add_theme_stylebox_override("panel", _plate_style)
	_plate.position = Vector2.ZERO
	_plate.size = Vector2(ICON_SIZE, ICON_SIZE)
	_plate.pivot_offset = Vector2(ICON_SIZE, ICON_SIZE) * 0.5
	icon.add_child(_plate)
	var texture: ImageTexture = SwordIcon.make_texture(ICON_INNER)
	_icon_bar = TextureProgressBar.new()
	_icon_bar.name = "IconBar"
	_icon_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_bar.texture_under = texture
	_icon_bar.texture_progress = texture
	_icon_bar.tint_under = UNDER_TINT
	_icon_bar.tint_progress = Color.WHITE
	_icon_bar.fill_mode = TextureProgressBar.FILL_CLOCKWISE
	_icon_bar.radial_initial_angle = 0.0
	_icon_bar.min_value = 0.0
	_icon_bar.max_value = 1.0
	_icon_bar.step = 0.001
	_icon_bar.value = 1.0
	_icon_bar.position = Vector2(ICON_INSET, ICON_INSET)
	_plate.add_child(_icon_bar)
	_caption = _make_label("Caption", CAPTION_FONT_SIZE)
	_caption.text = ABILITY_CAPTION
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.position = CAPTION_OFFSET
	_caption.custom_minimum_size = CAPTION_SIZE
	_caption.size = CAPTION_SIZE
	_plate.add_child(_caption)
	_ability_glyph = PromptGlyph.new()
	_ability_glyph.name = "AbilityGlyph"
	_ability_glyph.action = ABILITY_ACTION
	_ability_glyph.glyph_size = GLYPH_SIZE
	_plate.add_child(_ability_glyph)
	_place_glyph()


## Keeps the glyph in the bottom-right corner of the plate: (32, 32) for a 24 px tile, and the
## corner stays put when a long keycap text widens it (limited by GLYPH_MIN_X).
func _place_glyph() -> void:
	var corner: Vector2 = Vector2(ICON_SIZE, ICON_SIZE) - _ability_glyph.size
	_ability_glyph.position = Vector2(maxf(corner.x, GLYPH_MIN_X), corner.y)


func _build_health() -> void:
	_bar_background = _make_style(PLATE_COLOR, 4, Color.BLACK, 2)
	_health_bar = ProgressBar.new()
	_health_bar.name = "HealthBar"
	_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_health_bar.custom_minimum_size = BAR_SIZE
	_health_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_health_bar.show_percentage = false
	_health_bar.min_value = 0.0
	_health_bar.max_value = 1.0
	_health_bar.step = 0.001
	_health_bar.value = 1.0
	_health_bar.add_theme_stylebox_override("background", _bar_background)
	_health_bar.add_theme_stylebox_override("fill", _make_style(BAR_FILL_COLOR, 4, Color.BLACK, 0))
	add_child(_health_bar)
	_health_label = _make_label("HealthLabel", HEALTH_FONT_SIZE)
	_health_label.theme_type_variation = &"HudBoldLabel"
	_health_label.custom_minimum_size = Vector2(LABEL_MIN_WIDTH, 0.0)
	_health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_health_label)


func _make_label(label_name: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.name = label_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	return label


func _make_style(fill: Color, radius: int, border: Color, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border_width)
	style.border_color = border
	return style


## Mirrors the king's health and knockout state. `snap` jumps the bar instead of tweening it (the
## first look after binding, and a respawn).
func _sync_health(snap: bool) -> void:
	var king: KingState = _ctx.king
	var health: int = king.get_health()
	var max_health: int = king.get_max_health()
	var down: bool = king.is_down()
	if health != _shown_health or max_health != _shown_max:
		_health_label.text = HEALTH_TEXT % [health, max_health]
		var target: float = clampf(float(health) / float(max_health), 0.0, 1.0)
		_move_bar(target, snap or down or _shown_down)
		_shown_health = health
		_shown_max = max_health
	if down != _shown_down:
		_shown_down = down
		_apply_knocked_out(down)


## G-03-13: dims the parts that are not text (the bar, the plate's own panel, the sword and the
## glyph) and leaves the widget, the count and the caption at full alpha.
func _apply_knocked_out(down: bool) -> void:
	var alpha: float = KNOCKED_OUT_ALPHA if down else 1.0
	_health_bar.modulate.a = alpha
	_plate.self_modulate.a = alpha
	_icon_bar.modulate.a = alpha
	_ability_glyph.modulate.a = alpha
	if down:
		_health_label.add_theme_color_override("font_color", KNOCKED_OUT_COLOR)
	else:
		_health_label.remove_theme_color_override("font_color")


func _move_bar(target: float, snap: bool) -> void:
	if _bar_tween != null:
		_bar_tween.kill()
	if snap:
		_health_bar.value = target
		return
	_bar_tween = create_tween()
	_bar_tween.tween_property(_health_bar, "value", target, BAR_TWEEN_SECONDS)


## Mirrors the slam cooldown: the icon fills clockwise as it recharges, the border is the ready
## colour while it is ready, and reaching ready plays the flash once.
func _sync_ability() -> void:
	var ratio: float = _ctx.king.ability_cooldown_ratio()
	_icon_bar.value = ratio
	var is_ready: bool = ratio >= 1.0
	_plate_style.border_color = READY_COLOR if is_ready else IDLE_BORDER_COLOR
	if is_ready and not _was_ready:
		_ready_flashes += 1
		_play_ready_flash()
	_was_ready = is_ready


## Plate scale 1.0 to 1.2 to 1.0 over 0.25 s and its tint to the ready colour and back over 0.2 s.
func _play_ready_flash() -> void:
	_stop_plate_tweens()
	_plate.scale = Vector2.ONE
	_plate.modulate = Color.WHITE
	var half: float = READY_SCALE_SECONDS * 0.5
	_plate_tween = create_tween()
	_plate_tween.tween_property(_plate, "scale", Vector2.ONE * READY_SCALE, half)
	_plate_tween.tween_property(_plate, "scale", Vector2.ONE, half)
	var tint_half: float = READY_TINT_SECONDS * 0.5
	_tint_tween = create_tween()
	_tint_tween.tween_property(_plate, "modulate", READY_COLOR, tint_half)
	_tint_tween.tween_property(_plate, "modulate", Color.WHITE, tint_half)


func _stop_plate_tweens() -> void:
	if _plate_tween != null:
		_plate_tween.kill()
	if _tint_tween != null:
		_tint_tween.kill()


func _on_king_ability_used(_hit_count: int) -> void:
	_was_ready = false
	_stop_plate_tweens()
	_plate.modulate = Color.WHITE
	_plate_tween = create_tween()
	var half: float = USE_SCALE_SECONDS * 0.5
	_plate_tween.tween_property(_plate, "scale", Vector2.ONE * USE_SCALE, half)
	_plate_tween.tween_property(_plate, "scale", Vector2.ONE, half)


func _on_king_damaged(_amount: int, _hp: int, _max_hp: int) -> void:
	if _border_tween != null:
		_border_tween.kill()
	_bar_background.border_color = Color.WHITE
	_border_tween = create_tween()
	_border_tween.tween_property(_bar_background, "border_color", Color.BLACK, DAMAGE_FLASH_SECONDS)


## A refused press: the plate shakes SHAKE_PIXELS either way for SHAKE_OSCILLATIONS swings. No text.
func _on_denied(_reason: StringName) -> void:
	_shakes += 1
	if _shake_tween != null:
		_shake_tween.kill()
	_plate.position.x = 0.0
	_shake_tween = create_tween()
	for swing: int in range(SHAKE_OSCILLATIONS):
		_shake_tween.tween_property(_plate, "position:x", SHAKE_PIXELS, SHAKE_STEP_SECONDS)
		var back: float = 0.0 if swing == SHAKE_OSCILLATIONS - 1 else -SHAKE_PIXELS
		_shake_tween.tween_property(_plate, "position:x", back, SHAKE_STEP_SECONDS)
