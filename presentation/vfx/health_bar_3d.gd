class_name HealthBar3D
extends Node3D
## A billboard health bar that shows only once its owner is hurt (D-12's rule, reused for the king
## and the castle here, for buildings in plan 02-04 and for enemies in 02-05). Two unshaded quads, a
## dark background and a coloured fill, drawn without a depth test so the bar reads through geometry
## at night. Presentation only: it is told the numbers and never reads or writes the simulation.

const BAR_HEIGHT: float = 0.16
const BACKGROUND_COLOR := Color(0.08, 0.08, 0.1, 0.8)
const FILL_COLOR := Color(0.85, 0.2, 0.18, 1.0)
## The fill draws above the background.
const FILL_RENDER_PRIORITY: int = 2
const BACKGROUND_RENDER_PRIORITY: int = 1

## Full bar width in metres.
@export var bar_width: float = 1.4
## Height above the node's own origin; set before the node enters the tree, or call `set_health`
## again afterwards.
@export var height_offset: float = 2.6

var _background: MeshInstance3D
var _fill: MeshInstance3D
var _ratio: float = 1.0


## True while 0 < hp < max_hp: hurt and still alive. A full bar and a dead owner show nothing.
static func should_show(hp: int, max_hp: int) -> bool:
	return max_hp > 0 and hp > 0 and hp < max_hp


func _init() -> void:
	visible = false


func _ready() -> void:
	_background = _make_quad(BACKGROUND_COLOR, BACKGROUND_RENDER_PRIORITY)
	_fill = _make_quad(FILL_COLOR, FILL_RENDER_PRIORITY)
	_background.name = "Background"
	_fill.name = "Fill"
	add_child(_background)
	add_child(_fill)
	position.y = height_offset
	_apply_ratio()


## Fill ratio shown, 0.0 to 1.0.
func get_fill_ratio() -> float:
	return _ratio


## Updates the fill to hp / max_hp and shows or hides the bar by `should_show`.
func set_health(hp: int, max_hp: int) -> void:
	_ratio = clampf(float(hp) / float(max_hp), 0.0, 1.0) if max_hp > 0 else 0.0
	visible = should_show(hp, max_hp)
	if _fill != null:
		_apply_ratio()


## Resizes the fill quad and slides it so its left edge stays on the bar's left edge.
func _apply_ratio() -> void:
	var background_mesh: QuadMesh = _background.mesh as QuadMesh
	background_mesh.size = Vector2(bar_width, BAR_HEIGHT)
	var fill_mesh: QuadMesh = _fill.mesh as QuadMesh
	var fill_width: float = bar_width * _ratio
	fill_mesh.size = Vector2(maxf(fill_width, 0.001), BAR_HEIGHT * 0.7)
	fill_mesh.center_offset = Vector3((fill_width - bar_width) * 0.5, 0.0, 0.0)


func _make_quad(color: Color, priority: int) -> MeshInstance3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.no_depth_test = true
	material.render_priority = priority
	var mesh: QuadMesh = QuadMesh.new()
	mesh.material = material
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance
