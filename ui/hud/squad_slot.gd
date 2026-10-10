class_name SquadSlot
extends PanelContainer
## UI-01 / D-23: one squad's slot in the bottom-centre strip, 136x72. The unit icon (a sword for a
## melee squad, a bow for a ranged one, both drawn in code), "alive / max" in Body 22 bold, the
## stance glyph, a hidden group badge and a 4 px fill along the bottom edge that runs 0 to 1 over
## the tier respawn interval while the squad is short. A squad with nobody left turns its count
## red and dims the icon and glyph, and keeps its slot (also when its building is rubble, where the
## fill simply stops because the simulation countdown does). At dawn the border flashes once.
## Display only: it polls the simulation read getters through `refresh` and never writes it.
##
## Selection (D-10, D-16): a left click selects only this squad, Ctrl + click toggles it in the
## selection, and a selected slot draws a 4 px #8CEBFF border over a bluer plate, inside the 8 px
## padding so nothing moves. Hover draws a 2 px #C8CCD4 border. The group badge shows the lowest
## control group the squad is in (`set_group`). While the pad group mode edits the badge
## (`set_group_edit`, D-12) it shows the digit being chosen with a pulsing #8CEBFF border instead.

const ALIVE_TEXT := "%d / %d"
const SLOT_SIZE := Vector2(136.0, 72.0)
const ICON_PIXELS: int = 32
const PLATE_RADIUS: int = 6
const BORDER_WIDTH: int = 2
const SELECTED_BORDER_WIDTH: int = 4
const OUTLINE_SIZE: int = 6
## #14141A at alpha 0.78.
const PLATE_COLOR := Color(0.0784, 0.0784, 0.1019, 0.78)
const IDLE_BORDER_COLOR := Color("#3A3F4B")
const FLASH_COLOR := Color("#8CEBFF")
const SELECTED_BORDER_COLOR := Color("#8CEBFF")
const HOVER_BORDER_COLOR := Color("#C8CCD4")
## #1B2830 at alpha 0.85, the selected plate: the idle plate lightened and bluer.
const SELECTED_PLATE_COLOR := Color(0.1059, 0.1569, 0.1882, 0.85)
const DANGER_COLOR := Color("#FF4040")
const DIMMED_COLOR := Color("#7A808C")
## #2A2D36 at alpha 0.9.
const TRACK_COLOR := Color(0.1647, 0.1765, 0.2118, 0.9)
## #8CEBFF at alpha 0.6.
const FILL_COLOR := Color(0.549, 0.9216, 1.0, 0.6)
const FILL_RADIUS: int = 2
const BADGE_COLOR := Color(0.0, 0.0, 0.0, 0.5)
const BADGE_RADIUS: int = 4
const BADGE_SIZE: float = 20.0
const FLASH_SECONDS: float = 0.3
## The edit pulse: a 2 px #8CEBFF border whose alpha swings between EDIT_PULSE_LOW and 1.0, taking
## PULSE_SECONDS each way.
const EDIT_BORDER_WIDTH: int = 2
const EDIT_PULSE_LOW: float = 0.35
const PULSE_SECONDS: float = 0.4

## The squad this slot shows (a military spot id). Set before the slot enters the tree.
var squad_id: StringName = &""

var _ctx: RunContext
var _plate: StyleBoxFlat
var _shown_alive: int = -1
var _shown_max: int = -1
var _flashes: int = 0
var _flash_tween: Tween
var _selected: bool = false
var _hovered: bool = false
var _flashing: bool = false
var _selection: SelectionModel
var _group_digit: int = -1
var _edit_digit: int = -1
var _badge_style: StyleBoxFlat
var _pulse_tween: Tween

@onready var _icon: TextureRect = %UnitIcon
@onready var _alive_label: Label = %AliveLabel
@onready var _glyph: StanceGlyph = %StanceGlyph
@onready var _badge: PanelContainer = %GroupBadge
@onready var _badge_label: Label = %GroupBadgeLabel
@onready var _fill: ProgressBar = %ReplacementFill


func _ready() -> void:
	custom_minimum_size = SLOT_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	_plate = _make_plate()
	add_theme_stylebox_override("panel", _plate)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_alive_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_alive_label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	_fill.add_theme_stylebox_override("background", _make_bar(TRACK_COLOR))
	_fill.add_theme_stylebox_override("fill", _make_bar(FILL_COLOR))
	_badge_style = StyleBoxFlat.new()
	_badge_style.bg_color = BADGE_COLOR
	_badge_style.set_corner_radius_all(BADGE_RADIUS)
	_badge_style.border_color = FLASH_COLOR
	# Fixed margins, so the border of the edit pulse never grows the badge or the slot.
	_badge_style.content_margin_left = 0.0
	_badge_style.content_margin_top = 0.0
	_badge_style.content_margin_right = 0.0
	_badge_style.content_margin_bottom = 0.0
	_badge.add_theme_stylebox_override("panel", _badge_style)
	_centre_badge_label()


## Reads the squad from `ctx` and shows it. The first call also binds the slot to the run (the
## dawn flash listens for squad_restored) and picks the unit icon; a repeat only refreshes.
func refresh(ctx: RunContext) -> void:
	if ctx == null:
		return
	if _ctx == null:
		_ctx = ctx
		ctx.events.squad_restored.connect(_on_squad_restored)
		_icon.texture = _icon_for(ctx.squads.unit_def_of(squad_id))
	var squads: SquadSystem = ctx.squads
	var alive: int = squads.alive_count(squad_id)
	var max_alive: int = squads.max_count(squad_id)
	if alive != _shown_alive or max_alive != _shown_max:
		_shown_alive = alive
		_shown_max = max_alive
		_alive_label.text = ALIVE_TEXT % [alive, max_alive]
		_apply_gone(alive == 0)
	_fill.visible = alive < max_alive
	_fill.value = squads.replacement_progress(squad_id)
	var verb: StringName = squads.executing_verb(squad_id)
	_glyph.stance = verb if verb != &"" else squads.resting_stance(squad_id)


## Lights or clears the selection border and plate; the strip calls it on SelectionModel.changed.
func set_selected(selected: bool) -> void:
	_selected = selected
	_apply_look()


## Lets a click on the slot change the selection.
func bind_selection(model: SelectionModel) -> void:
	_selection = model


## Shows the control-group digit in the badge (the lowest group the squad is in, 0 meaning group
## 10), or hides the badge for -1 when the squad is in no group (D-16, D-23).
func set_group(digit: int) -> void:
	_group_digit = digit
	_apply_badge()


## Shows `digit` (0..9) on the badge with the pulsing #8CEBFF border while the pad group mode edits
## it, even when the squad is in no group; -1 stops the pulse and restores the squad's own group
## digit (D-12, UI-SPEC Color item 9).
func set_group_edit(digit: int) -> void:
	_edit_digit = digit
	_apply_badge()
	if digit >= 0:
		_start_pulse()
	else:
		_stop_pulse()


## True while the pad group mode is editing this badge (the border pulses).
func is_group_editing() -> bool:
	return _edit_digit >= 0


## The border colour of the badge right now (alpha swings while it pulses). Test hook, read-only.
func badge_border_color() -> Color:
	return _badge_style.border_color


func is_selected() -> bool:
	return _selected


func get_alive_label() -> Label:
	return _alive_label


func get_icon() -> TextureRect:
	return _icon


func get_glyph() -> StanceGlyph:
	return _glyph


func get_fill() -> ProgressBar:
	return _fill


func get_badge() -> PanelContainer:
	return _badge


func get_badge_label() -> Label:
	return _badge_label


## The edit digit while one is being chosen, else the squad's lowest group digit.
func _apply_badge() -> void:
	var shown: int = _edit_digit if _edit_digit >= 0 else _group_digit
	_badge.visible = shown >= 0
	_badge_label.text = str(shown) if shown >= 0 else ""


func _start_pulse() -> void:
	_stop_pulse()
	_badge_style.set_border_width_all(EDIT_BORDER_WIDTH)
	_badge_style.border_color = FLASH_COLOR
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_badge_style, "border_color:a", EDIT_PULSE_LOW, PULSE_SECONDS)
	_pulse_tween.tween_property(_badge_style, "border_color:a", 1.0, PULSE_SECONDS)


func _stop_pulse() -> void:
	if _pulse_tween != null:
		_pulse_tween.kill()
		_pulse_tween = null
	_badge_style.set_border_width_all(0)


## The digit label sits in a plain 20x20 box so its line height (taller than 20 px at size 18) never
## grows the badge or the slot; the label is centred on the box and the box clips the overhang.
func _centre_badge_label() -> void:
	var overhang: float = maxf(_badge_label.get_combined_minimum_size().y - BADGE_SIZE, 0.0) * 0.5
	_badge_label.offset_top = -overhang
	_badge_label.offset_bottom = overhang


## Dawn flashes so far. Test hook, read-only.
func flash_count() -> int:
	return _flashes


## The colour of the border right now. Test hook, read-only.
func border_color() -> Color:
	return _plate.border_color


## The sword for a melee unit, the bow for a unit that shoots.
static func _icon_for(unit_def: UnitDef) -> ImageTexture:
	if unit_def != null and unit_def.projectile_speed > 0.0:
		return BowIcon.make_texture(ICON_PIXELS)
	return SwordIcon.make_texture(ICON_PIXELS)


func _make_plate() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PLATE_COLOR
	style.set_corner_radius_all(PLATE_RADIUS)
	style.set_border_width_all(BORDER_WIDTH)
	style.border_color = IDLE_BORDER_COLOR
	# The border is drawn inside the 8 px padding, so the layout takes no margin from the style.
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	return style


func _make_bar(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(FILL_RADIUS)
	return style


## A squad with nobody left: red count, dimmed icon and glyph.
func _apply_gone(gone: bool) -> void:
	var tint: Color = DIMMED_COLOR if gone else Color.WHITE
	_icon.modulate = tint
	_glyph.modulate = tint
	if gone:
		_alive_label.add_theme_color_override("font_color", DANGER_COLOR)
	else:
		_alive_label.remove_theme_color_override("font_color")


## The dawn restore of this squad: the count is read again at once and the border flashes.
func _on_squad_restored(restored_id: StringName, _alive: int) -> void:
	if restored_id != squad_id or _ctx == null:
		return
	refresh(_ctx)
	_flashes += 1
	if _flash_tween != null:
		_flash_tween.kill()
	_flashing = true
	_apply_look()
	_flash_tween = create_tween()
	_flash_tween.tween_interval(FLASH_SECONDS)
	_flash_tween.tween_callback(_end_flash)


func _end_flash() -> void:
	_flashing = false
	_apply_look()


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT or not button.pressed:
		return
	accept_event()
	if _selection == null or _ctx == null:
		return
	var all_ids: Array[StringName] = _ctx.squads.squad_ids()
	if button.ctrl_pressed:
		_selection.toggle(squad_id, all_ids)
	else:
		_selection.select_only([squad_id] as Array[StringName], all_ids)


func _on_mouse_entered() -> void:
	_hovered = true
	_apply_look()


func _on_mouse_exited() -> void:
	_hovered = false
	_apply_look()


## Border and plate for the state right now: the dawn flash beats selected, selected beats hover,
## hover beats idle. Widths and colours only; the layout never changes (content margins are 0).
func _apply_look() -> void:
	if _plate == null:
		return
	var width: int = BORDER_WIDTH
	var border: Color = IDLE_BORDER_COLOR
	if _selected:
		width = SELECTED_BORDER_WIDTH
		border = SELECTED_BORDER_COLOR
	elif _hovered:
		border = HOVER_BORDER_COLOR
	if _flashing:
		border = FLASH_COLOR
	_plate.set_border_width_all(width)
	_plate.border_color = border
	_plate.bg_color = SELECTED_PLATE_COLOR if _selected else PLATE_COLOR
