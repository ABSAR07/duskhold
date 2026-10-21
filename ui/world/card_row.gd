class_name CardRow
extends Node3D
## The world-space row of choice cards above the castle (UI-02, D-06, D-07): each card is an
## unshaded quad with an icon slot, a name and a wrapped flavour line, drawn over everything like
## the spot label. The row hangs ROW_HEIGHT above the shown spot, turns to face the camera each
## frame so the cards stay side by side on screen, and scales with the camera distance by
## SpotLabel's LEGIBLE_CAMERA_DISTANCE rule. The highlighted card is raised and brighter and is the
## only one that prints its numbers line (ChoiceDef.effect_line(), D-07), whether it was highlighted
## by key or by mouse. The row is hidden whenever CardPicker is not showing; it reads CardPicker and
## CardRowModel and writes nothing. card_rects() gives the cards' screen rectangles for the mouse
## hit test (Camera3D.unproject_position per corner: no colliders, no physics, no SubViewport).

## Height of the row's centre above the shown spot, clear of the spot label.
const ROW_HEIGHT: float = 7.6
const CARD_SIZE := Vector2(3.4, 3.2)
const CARD_GAP: float = 0.3
## How far the highlighted card rises.
const RAISE: float = 0.35
const ICON_SLOT_SIZE: float = 0.9
const ICON_HEIGHT: float = 1.05
const ICON_PIXELS: float = 0.8
const NAME_HEIGHT: float = 0.5
const FLAVOUR_HEIGHT: float = 0.05
const NUMBERS_HEIGHT: float = -0.85
## The key tile of card n (the Kenney tile of the digit key that picks it) and where it sits.
const KEY_TILE_PATH := GlyphResolver.KEYBOARD_DIR + "keyboard_%d.png"
const KEY_TILE_SIZE: float = 0.5
const KEY_TILE_POSITION := Vector3(-1.45, 1.35, 0.03)
## Where the rectangle of a card behind the camera is parked: far outside any viewport.
const OFFSCREEN: float = 1.0e9
const TEXT_WIDTH_PIXELS: float = 320.0
const TEXT_PIXEL_SIZE: float = 0.01
const CARD_COLOR := Color(0.14, 0.16, 0.22, 0.94)
const CARD_HIGHLIGHT_COLOR := Color(0.36, 0.4, 0.56, 1.0)
const SLOT_COLOR := Color(0.07, 0.08, 0.11, 0.9)
const TEXT_COLOR := Color(0.88, 0.88, 0.9)
const TEXT_HIGHLIGHT_COLOR := Color(1.0, 1.0, 1.0)
const FLAVOUR_COLOR := Color(0.72, 0.74, 0.8)
const NUMBERS_COLOR := Color(1.0, 0.86, 0.4)
const OUTLINE_COLOR := Color(0.0, 0.0, 0.0)

var _ctx: RunContext
var _picker: CardPicker
var _cards: Array[Node3D] = []
var _faces: Array[MeshInstance3D] = []
var _names: Array[Label3D] = []
var _flavours: Array[Label3D] = []
var _numbers: Array[Label3D] = []
var _icons: Array[Texture2D] = []
var _effect_lines: Array[String] = []
var _signature: String = ""


func bind_run(ctx: RunContext, map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	_picker = map_root.get_cards()
	visible = false
	if _picker != null:
		_picker.highlight_changed.connect(_on_highlight_changed)


func _process(_delta: float) -> void:
	if _ctx == null:
		return
	_refresh()
	if not visible:
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var distance: float = camera.global_position.distance_to(global_position)
	var factor: float = maxf(1.0, distance / SpotLabel.LEGIBLE_CAMERA_DISTANCE)
	global_transform = Transform3D(
		camera.global_transform.basis.orthonormalized().scaled(Vector3.ONE * factor),
		global_position
	)


## How many cards are drawn; 0 while the row is hidden.
func card_count() -> int:
	return _cards.size() if visible else 0


## True when the card at `index` is drawn raised (the highlighted one); false for an index that
## addresses no drawn card.
func is_card_raised(index: int) -> bool:
	if not visible or index < 0 or index >= _cards.size():
		return false
	return _cards[index].position.y > 0.0


## The name printed on the card at `index`; empty for an index that addresses no drawn card.
func card_name(index: int) -> String:
	if not visible or index < 0 or index >= _names.size():
		return ""
	return _names[index].text


## The numbers line printed on the card at `index`: its effect text while the card is highlighted,
## empty for every other card and for an index that addresses no drawn card.
func numbers_text(index: int) -> String:
	if not visible or index < 0 or index >= _numbers.size():
		return ""
	return _numbers[index].text


## The icon texture drawn on the card at `index`; null for a card with no icon and for an index that
## addresses no drawn card.
func icon_of(index: int) -> Texture2D:
	if not visible or index < 0 or index >= _icons.size():
		return null
	return _icons[index]


## The screen rectangle of each drawn card, in card order, as the camera sees the row now: the
## bounding box of the card's four corners projected with Camera3D.unproject_position (a raised card
## is projected where it is drawn). Empty while the row is hidden. A corner behind the camera sends
## its card's rectangle off screen, so it can never be hit.
func card_rects(camera: Camera3D) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if not visible or camera == null:
		return rects
	var half: Vector2 = CARD_SIZE * 0.5
	var corners: Array[Vector3] = [
		Vector3(-half.x, -half.y, 0.0),
		Vector3(half.x, -half.y, 0.0),
		Vector3(half.x, half.y, 0.0),
		Vector3(-half.x, half.y, 0.0),
	]
	for card: Node3D in _cards:
		rects.append(_screen_rect(camera, card, corners))
	return rects


func _screen_rect(camera: Camera3D, card: Node3D, corners: Array[Vector3]) -> Rect2:
	var rect: Rect2 = Rect2()
	var first: bool = true
	for corner: Vector3 in corners:
		var world: Vector3 = card.global_transform * corner
		if camera.is_position_behind(world):
			return Rect2(Vector2(-OFFSCREEN, -OFFSCREEN), Vector2.ZERO)
		var point: Vector2 = camera.unproject_position(world)
		rect = Rect2(point, Vector2.ZERO) if first else rect.expand(point)
		first = false
	return rect


func _on_highlight_changed(_index: int) -> void:
	_refresh()


## Shows or hides the row and keeps its cards in step with the picker: rebuilt when the spot or the
## card list changes, restyled when the highlight moves.
func _refresh() -> void:
	var showing: bool = _picker != null and _picker.is_showing()
	if not showing:
		visible = false
		if not _cards.is_empty():
			_clear_cards()
		_signature = ""
		return
	var spot_id: StringName = _picker.shown_spot()
	var signature: String = "%s|%s" % [spot_id, ",".join(PackedStringArray(_picker.card_ids()))]
	if signature != _signature:
		_signature = signature
		_build_cards(CardRowModel.cards(_ctx, spot_id, _picker.highlighted_index()))
		global_position = _ctx.buildings.get_spot(spot_id).position + Vector3(0.0, ROW_HEIGHT, 0.0)
	_restyle(_picker.highlighted_index())
	visible = true


func _clear_cards() -> void:
	for card: Node3D in _cards:
		remove_child(card)
		card.queue_free()
	_cards.clear()
	_faces.clear()
	_names.clear()
	_flavours.clear()
	_numbers.clear()
	_icons.clear()
	_effect_lines.clear()


func _build_cards(content: Array[Dictionary]) -> void:
	_clear_cards()
	var count: int = content.size()
	for index: int in range(count):
		var card: Node3D = Node3D.new()
		card.name = "Card%d" % (index + 1)
		card.position = Vector3((float(index) - float(count - 1) * 0.5) * _pitch(), 0.0, 0.0)
		add_child(card)
		_cards.append(card)
		_faces.append(_add_face(card))
		var icon: Texture2D = content[index]["icon"] as Texture2D
		_icons.append(icon)
		_add_icon(card, icon)
		_add_key_tile(card, content[index]["key_hint"] as int)
		_names.append(_add_name(card, content[index]["name"] as String))
		_flavours.append(_add_flavour(card, content[index]["flavour"] as String))
		_numbers.append(_add_numbers(card))
		_effect_lines.append(content[index]["effect_line"] as String)


func _pitch() -> float:
	return CARD_SIZE.x + CARD_GAP


func _add_face(card: Node3D) -> MeshInstance3D:
	var face: MeshInstance3D = MeshInstance3D.new()
	face.name = "Face"
	var quad: QuadMesh = QuadMesh.new()
	quad.size = CARD_SIZE
	quad.material = _make_material(CARD_COLOR)
	face.mesh = quad
	card.add_child(face)
	return face


## The icon: a dark slot always, with the card's texture over it when it has one.
func _add_icon(card: Node3D, icon: Texture2D) -> void:
	var slot: MeshInstance3D = MeshInstance3D.new()
	slot.name = "IconSlot"
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(ICON_SLOT_SIZE, ICON_SLOT_SIZE)
	quad.material = _make_material(SLOT_COLOR)
	slot.mesh = quad
	slot.position = Vector3(0.0, ICON_HEIGHT, 0.01)
	card.add_child(slot)
	if icon == null:
		return
	var sprite: Sprite3D = Sprite3D.new()
	sprite.name = "Icon"
	sprite.texture = icon
	sprite.shaded = false
	sprite.no_depth_test = true
	sprite.render_priority = 2
	sprite.pixel_size = ICON_PIXELS / float(maxi(icon.get_width(), 1))
	sprite.position = Vector3(0.0, ICON_HEIGHT, 0.02)
	card.add_child(sprite)


## The key that picks the card, as the Kenney Input Prompts tile of that digit, in the card's top
## left corner (D-05). A digit with no tile file draws nothing.
func _add_key_tile(card: Node3D, key: int) -> void:
	var path: String = KEY_TILE_PATH % key
	if not ResourceLoader.exists(path):
		return
	var texture: Texture2D = load(path) as Texture2D
	if texture == null:
		return
	var tile: Sprite3D = Sprite3D.new()
	tile.name = "KeyTile"
	tile.texture = texture
	tile.shaded = false
	tile.no_depth_test = true
	tile.render_priority = 2
	tile.pixel_size = KEY_TILE_SIZE / float(maxi(texture.get_width(), 1))
	tile.position = KEY_TILE_POSITION
	card.add_child(tile)


func _add_name(card: Node3D, text: String) -> Label3D:
	var label: Label3D = _make_label(text, 32, TEXT_COLOR, Vector3(0.0, NAME_HEIGHT, 0.03))
	label.name = "Name"
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	card.add_child(label)
	return label


func _add_flavour(card: Node3D, text: String) -> Label3D:
	var label: Label3D = _make_label(text, 22, FLAVOUR_COLOR, Vector3(0.0, FLAVOUR_HEIGHT, 0.03))
	label.name = "Flavour"
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	card.add_child(label)
	return label


## The numbers line: empty until the card is highlighted (see _restyle).
func _add_numbers(card: Node3D) -> Label3D:
	var label: Label3D = _make_label("", 24, NUMBERS_COLOR, Vector3(0.0, NUMBERS_HEIGHT, 0.03))
	label.name = "Numbers"
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	card.add_child(label)
	return label


func _make_label(text: String, size: int, color: Color, at: Vector3) -> Label3D:
	var label: Label3D = Label3D.new()
	label.text = text
	label.font_size = size
	label.outline_size = 8
	label.modulate = color
	label.outline_modulate = OUTLINE_COLOR
	label.pixel_size = TEXT_PIXEL_SIZE
	label.width = TEXT_WIDTH_PIXELS
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.no_depth_test = true
	label.shaded = false
	label.render_priority = 1
	label.outline_render_priority = 0
	label.position = at
	return label


## Raises and brightens the card at `highlighted_index`; every other card rests.
func _restyle(highlighted_index: int) -> void:
	for index: int in range(_cards.size()):
		var lit: bool = index == highlighted_index
		_cards[index].position.y = RAISE if lit else 0.0
		var material: StandardMaterial3D = (
			(_faces[index].mesh as QuadMesh).material as StandardMaterial3D
		)
		material.albedo_color = CARD_HIGHLIGHT_COLOR if lit else CARD_COLOR
		_names[index].modulate = TEXT_HIGHLIGHT_COLOR if lit else TEXT_COLOR
		_numbers[index].text = _effect_lines[index] if lit else ""


func _make_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
