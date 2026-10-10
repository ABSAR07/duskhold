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

var _ctx: RunContext
var _selection: SelectionModel
var _views: UnitViews
var _ring: MultiMeshInstance3D
var _under: MultiMeshInstance3D
var _shown: int = 0


func _ready() -> void:
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


## Rings drawn right now: one per shown unit of every selected squad. Test hook, read-only.
func ring_count() -> int:
	return _shown


func _process(_delta: float) -> void:
	if _ctx == null or _selection == null or _views == null:
		return
	var count: int = 0
	for squad_id: StringName in _selection.selected():
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
			count += 1
	_shown = count
	_ring.multimesh.visible_instance_count = count
	_under.multimesh.visible_instance_count = count


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
