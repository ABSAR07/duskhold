class_name SelectionRings
extends Node3D
## D-16: a flat cyan ground ring (outer diameter 1.1 m, 0.1 m thick) under every unit of every
## selected squad, over a dark under-ring 0.06 m wider so it reads on light ground. Each ring layer
## is one MultiMeshInstance3D (one draw call each) whose instances follow the interpolated puppets
## of UnitViews every frame. With nothing selected no instance is shown. Units off-screen simply
## draw nothing; the squad slot carries the selection there. Display only: it reads the selection
## and the simulation and writes neither.

## Instances allocated per layer; the same cap as the puppets (UnitViews.MAX_VIEWS).
const MAX_RINGS: int = UnitViews.MAX_VIEWS
const OUTER_RADIUS: float = 0.55
const THICKNESS: float = 0.1
## The under-ring is 0.06 m wider in diameter, 0.03 m on each side.
const UNDER_MARGIN: float = 0.03
const RING_HEIGHT: float = 0.03
const UNDER_HEIGHT: float = 0.025
const SEGMENTS: int = 32
## #8CEBFF at alpha 0.95.
const RING_COLOR := Color(0.549, 0.9216, 1.0, 0.95)
## #000000 at alpha 0.5.
const UNDER_COLOR := Color(0.0, 0.0, 0.0, 0.5)
## A hovered, unselected squad previews its rings at this alpha (UI-SPEC "Hover preview").
const HOVER_ALPHA: float = 0.4

var _ctx: RunContext
var _selection: SelectionModel
var _views: UnitViews
var _ring: MultiMeshInstance3D
var _under: MultiMeshInstance3D
var _pointer: SelectionController
var _shown: int = 0
var _hover_shown: int = 0
var _alphas: PackedFloat32Array = PackedFloat32Array()
var _positions: PackedVector3Array = PackedVector3Array()


func _ready() -> void:
	_alphas.resize(MAX_RINGS)
	_positions.resize(MAX_RINGS)
	_under = _make_layer(
		"UnderRing",
		OUTER_RADIUS - THICKNESS - UNDER_MARGIN,
		OUTER_RADIUS + UNDER_MARGIN,
		UNDER_COLOR
	)
	_ring = _make_layer("Ring", OUTER_RADIUS - THICKNESS, OUTER_RADIUS, RING_COLOR)


func bind_run(ctx: RunContext, map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	_selection = map_root.get_selection()
	_views = map_root.get_node_or_null("UnitViews") as UnitViews
	_pointer = map_root.get_node_or_null("SelectionController") as SelectionController


## Rings drawn right now: one per shown unit of every selected squad. Test hook, read-only.
func ring_count() -> int:
	return _shown


## Hover preview rings drawn right now (the hovered unselected squad's units). Test hook.
func hover_ring_count() -> int:
	return _hover_shown


## The alpha of ring `index`, selected rings first and hover rings after. Test hook.
func ring_alpha(index: int) -> float:
	return _alphas[index] if index >= 0 and index < _shown + _hover_shown else 0.0


## The ground position of ring `index`. Test hook.
func ring_position(index: int) -> Vector3:
	return _positions[index] if index >= 0 and index < _shown + _hover_shown else Vector3.ZERO


## Recall flashes started so far. Test hook.
func flash_count() -> int:
	return 0


## The scale of ring `index` (1.0 at rest). Test hook.
func ring_scale(_index: int) -> float:
	return 1.0


func _process(_delta: float) -> void:
	if _ctx == null or _selection == null or _views == null:
		return
	var count: int = 0
	var selected: Array[StringName] = _selection.selected()
	for squad_id: StringName in selected:
		count = _place_squad(squad_id, count, RING_COLOR.a)
	_shown = count
	var hovered: StringName = _pointer.hovered_squad() if _pointer != null else &""
	if hovered != &"" and not selected.has(hovered):
		count = _place_squad(hovered, count, HOVER_ALPHA)
	_hover_shown = count - _shown
	_ring.multimesh.visible_instance_count = count
	_under.multimesh.visible_instance_count = count


## Puts a ring under every shown unit of `squad_id` from instance `count` on, at `alpha`, and
## returns the next free instance.
func _place_squad(squad_id: StringName, first: int, alpha: float) -> int:
	var count: int = first
	var under_alpha: float = UNDER_COLOR.a * alpha / RING_COLOR.a
	for unit_id: int in _ctx.squads.unit_ids_of(squad_id):
		if count >= MAX_RINGS:
			break
		if _views.get_view(unit_id) == null:
			continue
		var ground: Vector3 = _views.puppet_position(unit_id)
		_ring.multimesh.set_instance_transform(
			count, Transform3D(Basis.IDENTITY, _at(ground, RING_HEIGHT))
		)
		_under.multimesh.set_instance_transform(
			count, Transform3D(Basis.IDENTITY, _at(ground, UNDER_HEIGHT))
		)
		_ring.multimesh.set_instance_color(count, Color(RING_COLOR, alpha))
		_under.multimesh.set_instance_color(count, Color(UNDER_COLOR, under_alpha))
		_alphas[count] = alpha
		_positions[count] = Vector3(ground.x, 0.0, ground.z)
		count += 1
	return count


func _at(ground: Vector3, height: float) -> Vector3:
	return Vector3(ground.x, height, ground.z)


## One ring layer: a MultiMesh of flat rings, every instance in `color`. The transform format and
## use_colors are set while instance_count is still 0 (Pitfall 9), then the instances are allocated.
func _make_layer(
	layer_name: String, inner: float, outer: float, color: Color
) -> MultiMeshInstance3D:
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = make_ring_mesh(inner, outer, SEGMENTS, _make_material())
	multimesh.instance_count = MAX_RINGS
	multimesh.visible_instance_count = 0
	for index: int in range(MAX_RINGS):
		multimesh.set_instance_color(index, color)
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = layer_name
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance


func _make_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


## A flat ring in the XZ plane, facing up: `segments` quads between radius `inner` and `outer`.
static func make_ring_mesh(
	inner: float, outer: float, segments: int, material: Material
) -> ArrayMesh:
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()
	for index: int in range(segments):
		var angle: float = TAU * float(index) / float(segments)
		var direction: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		vertices.append(direction * inner)
		vertices.append(direction * outer)
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
	for index: int in range(segments):
		var next: int = (index + 1) % segments
		var inner_a: int = index * 2
		var outer_a: int = index * 2 + 1
		var inner_b: int = next * 2
		var outer_b: int = next * 2 + 1
		indices.append_array([inner_a, outer_a, outer_b, inner_a, outer_b, inner_b])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material)
	return mesh
