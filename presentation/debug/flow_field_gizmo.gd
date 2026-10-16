class_name FlowFieldGizmo
extends Node3D
## 3D debug drawing of the castle flow field (ENMY-04, D-04, D-09): one short arrow on every reached
## open cell pointing the way enemies are steered (a pin on a goal cell, where there is no
## direction), and a small cross on every blocked cell. It shows only while the debug overlay is
## open and the phase is NIGHT, like EnemyPathGizmo, and the mesh is rebuilt only when the field
## version changes (RESEARCH F6: a few milliseconds for 6,400 cells, once per change).
##
## Presentation only: it reads the castle field and the grid through getters and never asks a
## GoalFieldCache for a field, so it cannot spend a squad's build budget or change an outcome. The
## field's lazy direction cache returns the same values whenever it is filled (DR-11; T-01-15
## carried: the overlay ships in all builds and is read-only).

const FIELD_COLOR := Color(0.55, 0.9, 1.0, 0.5)
const BLOCKED_COLOR := Color(1.0, 0.55, 0.2, 0.7)
## The arrows lie this far above the ground, in metres.
const FIELD_HEIGHT: float = 0.25
## An arrow is this long, the head's two barbs this long, and a blocked cross reaches this far from
## the cell centre, in metres.
const ARROW_LENGTH: float = 0.8
const BARB_LENGTH: float = 0.25
const CROSS_REACH: float = 0.35
## A goal cell has no direction; it gets a pin this tall.
const PIN_HEIGHT: float = 0.6
## How far the barbs swing back from the shaft, in radians.
const BARB_ANGLE: float = 0.5

var _ctx: RunContext
var _overlay: DebugOverlay
var _view: MeshInstance3D = MeshInstance3D.new()
var _mesh: ImmediateMesh = ImmediateMesh.new()
var _material: StandardMaterial3D = StandardMaterial3D.new()
var _arrows: int = 0
var _crosses: int = 0
var _built_version: int = -1


func _init() -> void:
	visible = false
	_view.mesh = _mesh
	_view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_view)
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.no_depth_test = true
	_material.vertex_color_use_as_albedo = true
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


## Binds the gizmo to one run and the overlay whose visibility it follows.
func bind(ctx: RunContext, overlay: DebugOverlay) -> void:
	_ctx = ctx
	_overlay = overlay


func _ready() -> void:
	# Vertices are written in world coordinates, so the gizmo ignores its parent's transform.
	top_level = true
	global_transform = Transform3D.IDENTITY


func _process(_delta: float) -> void:
	refresh()


## Arrows (and goal pins) in the drawing; 0 while hidden.
func arrow_count() -> int:
	return _arrows


## Crosses on blocked cells in the drawing; 0 while hidden.
func blocked_mark_count() -> int:
	return _crosses


## The field version the drawing was built for; -1 while nothing is drawn.
func built_for_version() -> int:
	return _built_version


## Draws the castle field as it is now, rebuilding only when its version changed, or hides and
## clears the drawing when the overlay is closed, it is not night, or no field stands yet. Called
## every frame; tests call it to sync on demand.
func refresh() -> void:
	var show_field: bool = (
		_ctx != null
		and _overlay != null
		and _overlay.is_overlay_visible()
		and _ctx.run_manager.get_phase() == RunManager.RunPhase.NIGHT
	)
	var pathing: Pathing = _ctx.night.get_pathing() if show_field else null
	var field: FlowField = pathing.castle_field() if pathing != null else null
	if field == null:
		visible = false
		_clear()
		return
	visible = true
	if pathing.field_version() == _built_version:
		return
	_rebuild(pathing.grid(), field)
	_built_version = pathing.field_version()


func _clear() -> void:
	if _built_version == -1 and _arrows == 0 and _crosses == 0:
		return
	_mesh.clear_surfaces()
	_arrows = 0
	_crosses = 0
	_built_version = -1


## One surface of lines: an arrow or pin per reached open cell, a cross per blocked cell. The
## border ring of the grid is not part of the world and is skipped.
func _rebuild(grid: NavGrid, field: FlowField) -> void:
	_mesh.clear_surfaces()
	_arrows = 0
	_crosses = 0
	if not grid.is_ready():
		return
	var costs: PackedInt32Array = field.costs()
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _material)
	for cell: int in range(grid.width() * grid.height()):
		if grid.is_border(cell):
			continue
		if grid.is_blocked(cell):
			_add_cross(grid.centre_of(cell))
		elif costs[cell] < FlowField.INF_COST:
			var centre: Vector2 = grid.centre_of(cell)
			_add_arrow(centre, field.direction_at(centre))
	_mesh.surface_end()


func _add_arrow(centre: Vector2, direction: Vector2) -> void:
	_arrows += 1
	if direction == Vector2.ZERO:
		_add_line(_lifted(centre), _lifted(centre) + Vector3(0.0, PIN_HEIGHT, 0.0), FIELD_COLOR)
		return
	var tail: Vector2 = centre - direction * (ARROW_LENGTH * 0.5)
	var tip: Vector2 = centre + direction * (ARROW_LENGTH * 0.5)
	var back: Vector2 = -direction * BARB_LENGTH
	_add_line(_lifted(tail), _lifted(tip), FIELD_COLOR)
	_add_line(_lifted(tip), _lifted(tip + back.rotated(BARB_ANGLE)), FIELD_COLOR)
	_add_line(_lifted(tip), _lifted(tip + back.rotated(-BARB_ANGLE)), FIELD_COLOR)


func _add_cross(centre: Vector2) -> void:
	_crosses += 1
	var low: Vector2 = centre - Vector2(CROSS_REACH, CROSS_REACH)
	var high: Vector2 = centre + Vector2(CROSS_REACH, CROSS_REACH)
	_add_line(_lifted(low), _lifted(high), BLOCKED_COLOR)
	_add_line(_lifted(Vector2(low.x, high.y)), _lifted(Vector2(high.x, low.y)), BLOCKED_COLOR)


func _add_line(from: Vector3, to: Vector3, color: Color) -> void:
	_mesh.surface_set_color(color)
	_mesh.surface_add_vertex(from)
	_mesh.surface_set_color(color)
	_mesh.surface_add_vertex(to)


func _lifted(ground: Vector2) -> Vector3:
	return Vector3(ground.x, FIELD_HEIGHT, ground.y)
