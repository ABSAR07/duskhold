class_name CommandHints
extends HBoxContainer
## UI-01 / KING-04: the command hint strip. While at least one squad is selected it lists the orders
## with the input that gives each one, left to right: Follow, Hold, Rally, Move, Attack, Patrol,
## Queue. Each item is a 24 px glyph of the action on the device in use and its fixed single-word
## label (Label 18). On the pad the three point orders are chords, so they show the command layer
## glyph, a "+" and the D-pad glyph. The row sits in the toast slot, y 504..536 at 1280x720, 8 px
## above the squad strip and below the protected centre. A toast or an armed line owns that slot
## (Toast.is_occupied), so the row yields at once and returns, fading in over 0.15 s, when the slot
## is free. With nothing selected (which includes no squad at all) it is hidden and shows no
## placeholder. Display only: it never writes the simulation.

const FADE_SECONDS: float = 0.15
const ITEM_SEPARATION: int = 4
const ROW_SEPARATION: int = 16
const GLYPH_SIZE: int = 24
const LABEL_FONT_SIZE: int = 18
const PLUS_TEXT := "+"
const LAYER_ACTION: StringName = &"command_layer"
## The verbs in reading order. `layer` marks the point orders that are chords on the pad.
const VERBS: Array[Dictionary] = [
	{"label": "Follow", "action": &"squad_follow", "layer": false},
	{"label": "Hold", "action": &"squad_hold", "layer": false},
	{"label": "Rally", "action": &"squad_rally", "layer": false},
	{"label": "Move", "action": &"squad_move", "layer": true},
	{"label": "Attack", "action": &"squad_attack_move", "layer": true},
	{"label": "Patrol", "action": &"squad_patrol", "layer": true},
	{"label": "Queue", "action": &"command_queue", "layer": false},
]

var _selection: SelectionModel
var _toast: Toast
var _has_selection: bool = false
var _shown: bool = false
var _fade: Tween
var _items: Array[HBoxContainer] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", ROW_SEPARATION)
	alignment = BoxContainer.ALIGNMENT_CENTER
	for verb: Dictionary in VERBS:
		_items.append(_build_item(verb))
	if _toast == null:
		_toast = get_parent().get_node_or_null("Toast") as Toast
	visible = false


## Binds the strip to one run: the selection decides whether it shows and every glyph follows the
## device tracker. A repeat call is ignored.
func bind_run(_ctx: RunContext, map_root: MapRoot) -> void:
	if _selection != null or map_root == null:
		return
	set_selection(map_root.get_selection())
	var tracker: LastDeviceTracker = map_root.get_device_tracker()
	if tracker != null:
		follow_device(tracker)


## The selection that decides whether the hints show. Also the way a test lays the strip out
## without a map.
func set_selection(selection: SelectionModel) -> void:
	if selection == null or selection == _selection:
		return
	_selection = selection
	selection.changed.connect(_on_selection_changed)
	_on_selection_changed()


## Subscribes every glyph of the strip to `tracker`, so a device change re-renders them all in the
## same frame, and shows the chord parts the pad needs.
func follow_device(tracker: LastDeviceTracker) -> void:
	for glyph: PromptGlyph in _glyphs():
		glyph.bind_device(tracker)
	tracker.device_changed.connect(_apply_device)
	_apply_device(tracker.device())


## How many items are showing: 7 while the strip shows, 0 while it is hidden.
func visible_item_count() -> int:
	return _items.size() if visible else 0


## The words of the items, left to right.
func item_words() -> Array[String]:
	var words: Array[String] = []
	for item: HBoxContainer in _items:
		words.append((item.get_node("Word") as Label).text)
	return words


## The item of a verb word ("Move"); null for an unknown one. Test hook.
func get_item(word: String) -> HBoxContainer:
	for item: HBoxContainer in _items:
		if (item.get_node("Word") as Label).text == word:
			return item
	return null


func _process(_delta: float) -> void:
	var yields: bool = _toast != null and _toast.is_occupied()
	var wanted: bool = _has_selection and not yields
	if wanted == _shown:
		return
	_shown = wanted
	_stop_fade()
	if not wanted:
		visible = false
		return
	modulate.a = 0.0
	visible = true
	_fade = create_tween()
	_fade.tween_property(self, "modulate:a", 1.0, FADE_SECONDS)


func _on_selection_changed() -> void:
	_has_selection = _selection != null and not _selection.selected().is_empty()


## Shows the command-layer glyph and the "+" before the point verbs on the pad only.
func _apply_device(device: int) -> void:
	var on_pad: bool = device == GlyphResolver.DEVICE_PAD
	for index: int in range(VERBS.size()):
		if VERBS[index]["layer"]:
			_items[index].get_node("Layer").visible = on_pad
			_items[index].get_node("Plus").visible = on_pad


func _build_item(verb: Dictionary) -> HBoxContainer:
	var item: HBoxContainer = HBoxContainer.new()
	item.name = "Item%s" % verb["label"]
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	item.add_theme_constant_override("separation", ITEM_SEPARATION)
	if verb["layer"]:
		var layer: PromptGlyph = _make_glyph("Layer", LAYER_ACTION)
		layer.visible = false
		item.add_child(layer)
		var plus: Label = _make_label("Plus", PLUS_TEXT)
		plus.visible = false
		item.add_child(plus)
	item.add_child(_make_glyph("Key", verb["action"]))
	item.add_child(_make_label("Word", verb["label"]))
	add_child(item)
	return item


func _make_glyph(glyph_name: String, action: StringName) -> PromptGlyph:
	var glyph: PromptGlyph = PromptGlyph.new()
	glyph.name = glyph_name
	glyph.action = action
	glyph.glyph_size = GLYPH_SIZE
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return glyph


func _make_label(label_name: String, text_value: String) -> Label:
	var label: Label = Label.new()
	label.name = label_name
	label.text = text_value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	return label


func _glyphs() -> Array[PromptGlyph]:
	var found: Array[PromptGlyph] = []
	for item: HBoxContainer in _items:
		for child: Node in item.get_children():
			if child is PromptGlyph:
				found.append(child as PromptGlyph)
	return found


func _stop_fade() -> void:
	if _fade != null:
		_fade.kill()
		_fade = null
	modulate.a = 1.0
