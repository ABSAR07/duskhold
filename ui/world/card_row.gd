class_name CardRow
extends Node3D
## The world-space row of choice cards above the castle (UI-02, D-06, D-07): each card is an
## unshaded quad with an icon slot, a name and a wrapped flavour line, drawn over everything like
## the spot label. The row hangs ROW_HEIGHT above the shown spot, turns to face the camera each
## frame so the cards stay side by side on screen, and scales with the camera distance by
## SpotLabel's LEGIBLE_CAMERA_DISTANCE rule. The highlighted card is raised and brighter. The row is
## hidden whenever CardPicker is not showing; it reads CardPicker and CardRowModel and writes
## nothing. The numbers on highlight and the key hints arrive with plan 05-04.

## Height of the row's centre above the shown spot, clear of the spot label.
const ROW_HEIGHT: float = 7.6
const CARD_SIZE := Vector2(2.4, 3.2)
const CARD_GAP: float = 0.3
## How far the highlighted card rises.
const RAISE: float = 0.35
const ICON_SLOT_SIZE: float = 0.9
const ICON_HEIGHT: float = 1.0
const ICON_PIXELS: float = 0.9
const TEXT_WIDTH_PIXELS: float = 220.0
const TEXT_PIXEL_SIZE: float = 0.01
const CARD_COLOR := Color(0.14, 0.16, 0.22, 0.94)
const CARD_HIGHLIGHT_COLOR := Color(0.36, 0.4, 0.56, 1.0)
const SLOT_COLOR := Color(0.07, 0.08, 0.11, 0.9)
const TEXT_COLOR := Color(0.88, 0.88, 0.9)
const TEXT_HIGHLIGHT_COLOR := Color(1.0, 1.0, 1.0)
const FLAVOUR_COLOR := Color(0.72, 0.74, 0.8)
const OUTLINE_COLOR := Color(0.0, 0.0, 0.0)

var _ctx: RunContext
var _picker: CardPicker
var _cards: Array[Node3D] = []
var _faces: Array[MeshInstance3D] = []
var _names: Array[Label3D] = []
var _flavours: Array[Label3D] = []
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
		_add_icon(card, content[index]["icon"] as Texture2D)
		_names.append(_add_name(card, content[index]["name"] as String, index + 1))
		_flavours.append(_add_flavour(card, content[index]["flavour"] as String))


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
	sprite.pixel_size = ICON_PIXELS / float(maxi(icon.get_width(), 1))
	sprite.position = Vector3(0.0, ICON_HEIGHT, 0.02)
	card.add_child(sprite)


func _add_name(card: Node3D, text: String, key: int) -> Label3D:
	var label: Label3D = _make_label(text, 34, TEXT_COLOR, Vector3(0.0, 0.45, 0.03))
	label.name = "Name"
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	card.add_child(label)
	var hint: Label3D = _make_label(str(key), 30, FLAVOUR_COLOR, Vector3(-1.0, 1.38, 0.03))
	hint.name = "Key"
	hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	card.add_child(hint)
	return label


func _add_flavour(card: Node3D, text: String) -> Label3D:
	var label: Label3D = _make_label(text, 24, FLAVOUR_COLOR, Vector3(0.0, -0.6, 0.03))
	label.name = "Flavour"
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


func _make_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
