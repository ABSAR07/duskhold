class_name PadCursorView
extends Node3D
## The pad's ground cursor on the map (UI-SPEC "Gamepad cursor"): a flat ring 1.2 m wide in #8CEBFF
## at alpha 0.9 with a dark under-ring, and a 0.12 m line from the king to it. Shown only while the
## PadCursorController has the cursor up. Display only: it is told where to draw and reads nothing.
## The headless dummy renderer cannot be read back, so the view keeps its own copy of what it draws
## for the tests.

const RING_DIAMETER: float = 1.2
const COLOR := Color(0.549, 0.9216, 1.0, 0.9)
## The dark ring under the accent one, so it reads on light ground; a little wider on each side.
const UNDER_COLOR := Color(0.0784, 0.0784, 0.1019, 0.7)
const UNDER_MARGIN: float = 0.08
## Width of the ring band as a share of its radius.
const BAND_SHARE: float = 0.2
const LINE_WIDTH: float = 0.12
const LINE_HEIGHT: float = 0.02
const RING_SEGMENTS: int = 32
## Heights above the ground, so the layers are not z-fought by the terrain or each other.
const UNDER_Y: float = 0.05
const RING_Y: float = 0.07
const LINE_Y: float = 0.06

var _ring: MeshInstance3D
var _under: MeshInstance3D
var _line: MeshInstance3D
var _shown: bool = false
var _cursor_ground: Vector3 = Vector3.ZERO
var _line_length: float = 0.0


func _ready() -> void:
	visible = false
	_under = _make_ring(UNDER_COLOR, RING_DIAMETER * 0.5 + UNDER_MARGIN, UNDER_Y, "UnderRing")
	_ring = _make_ring(COLOR, RING_DIAMETER * 0.5, RING_Y, "Ring")
	_line = MeshInstance3D.new()
	_line.name = "Line"
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(1.0, LINE_HEIGHT, LINE_WIDTH)
	box.material = _material(COLOR)
	_line.mesh = box
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_line)


func bind_run(_ctx: RunContext, _map_root: MapRoot) -> void:
	hide_cursor()


## Draws the ring at `cursor_ground` and the line from `king_ground` to it.
func show_cursor(king_ground: Vector3, cursor_ground: Vector3) -> void:
	_shown = true
	visible = true
	_cursor_ground = cursor_ground
	var from: Vector3 = Vector3(king_ground.x, 0.0, king_ground.z)
	var to: Vector3 = Vector3(cursor_ground.x, 0.0, cursor_ground.z)
	_under.global_position = Vector3(to.x, UNDER_Y, to.z)
	_ring.global_position = Vector3(to.x, RING_Y, to.z)
	var span: Vector3 = to - from
	_line_length = span.length()
	_line.visible = _line_length > 0.01
	if _line.visible:
		_line.global_position = Vector3((from.x + to.x) * 0.5, LINE_Y, (from.z + to.z) * 0.5)
		_line.rotation = Vector3(0.0, atan2(-span.z, span.x), 0.0)
		_line.scale = Vector3(_line_length, 1.0, 1.0)


func hide_cursor() -> void:
	_shown = false
	visible = false


## True while the cursor is drawn. Test hook.
func is_visible_cursor() -> bool:
	return _shown


## The ground point the ring was last drawn at. Test hook.
func cursor_ground() -> Vector3:
	return _cursor_ground


## The length of the line from the king to the ring, in metres. Test hook.
func line_length() -> float:
	return _line_length


func _make_ring(color: Color, radius: float, height: float, node_name: String) -> MeshInstance3D:
	var mesh: TorusMesh = TorusMesh.new()
	mesh.outer_radius = radius
	mesh.inner_radius = radius * (1.0 - BAND_SHARE)
	mesh.rings = RING_SEGMENTS
	mesh.ring_segments = 4
	mesh.material = _material(color)
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.position = Vector3(0.0, height, 0.0)
	add_child(instance)
	return instance


func _material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	return material
