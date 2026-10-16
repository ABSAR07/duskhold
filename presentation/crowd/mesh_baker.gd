class_name MeshBaker
extends RefCounted
## Turns a model scene into one ArrayMesh a MultiMesh can draw (PLAT-01): every mesh of the tree,
## skinned or static, is moved to its place under the model root, scaled, and appended as surfaces
## that keep their materials. A skinned part is baked from the skeleton's current pose with
## MeshInstance3D.bake_mesh_from_current_skeleton_pose(), which needs a real renderer and a node in
## the tree: where it returns nothing (headless) the whole bake is null and the caller falls back
## to a primitive (RESEARCH F7, Pitfall 4). Display only: it builds meshes and touches no state.

## The display server name with no renderer behind it: a skinned mesh has no pose to read there.
const HEADLESS_DISPLAY: String = "headless"


## Bakes every mesh under `model_root` (its own and its descendants', in child order) into one
## ArrayMesh scaled by `uniform_scale`; each mesh sits where its node chain puts it relative to the
## root, the root's own transform ignored. Null when a skinned part cannot be baked or the tree
## holds no mesh at all.
static func bake(model_root: Node3D, uniform_scale: float) -> ArrayMesh:
	var target: ArrayMesh = ArrayMesh.new()
	var scaled: Transform3D = Transform3D(Basis.from_scale(Vector3.ONE * uniform_scale), Vector3())
	if not _collect(model_root, scaled, target):
		return null
	return target if target.get_surface_count() > 0 else null


## Adds every surface of `mesh` to `target`, each moved by `xform` and keeping its material.
static func append_primitive(target: ArrayMesh, mesh: Mesh, xform: Transform3D) -> void:
	_append_surfaces(target, mesh, xform, null)


## Appends the meshes of `node` and its children; `node_xform` is the node's transform relative to
## the model root with the scale applied. False as soon as a skinned part cannot be baked.
static func _collect(node: Node3D, node_xform: Transform3D, target: ArrayMesh) -> bool:
	var instance: MeshInstance3D = node as MeshInstance3D
	if instance != null and instance.mesh != null:
		var geometry: Mesh = instance.mesh
		if instance.skin != null:
			if DisplayServer.get_name() == HEADLESS_DISPLAY:
				return false
			geometry = instance.bake_mesh_from_current_skeleton_pose()
			if geometry == null or geometry.get_surface_count() == 0:
				return false
		_append_surfaces(target, geometry, node_xform, instance)
	for child: Node in node.get_children():
		var part: Node3D = child as Node3D
		if part == null:
			continue
		if not _collect(part, node_xform * part.transform, target):
			return false
	return true


## Appends the surfaces of `geometry` to `target`, moved by `xform`. Materials come from
## `material_owner` when there is one (an override on the node wins over its mesh's own), else
## from `geometry`.
static func _append_surfaces(
	target: ArrayMesh, geometry: Mesh, xform: Transform3D, material_owner: MeshInstance3D
) -> void:
	if target == null or geometry == null:
		return
	for surface: int in range(geometry.get_surface_count()):
		var arrays: Array = geometry.surface_get_arrays(surface)
		if arrays.is_empty() or arrays[Mesh.ARRAY_VERTEX] == null:
			continue
		_transform_arrays(arrays, xform)
		target.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var material: Material = null
		if material_owner != null:
			material = material_owner.get_surface_override_material(surface)
			if material == null:
				material = material_owner.mesh.surface_get_material(surface)
		else:
			material = geometry.surface_get_material(surface)
		target.surface_set_material(target.get_surface_count() - 1, material)


## Moves a surface's vertices, normals and tangents by `xform`, in place.
static func _transform_arrays(arrays: Array, xform: Transform3D) -> void:
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for index: int in range(vertices.size()):
		vertices[index] = xform * vertices[index]
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var normal_basis: Basis = xform.basis.inverse().transposed()
	if arrays[Mesh.ARRAY_NORMAL] != null:
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for index: int in range(normals.size()):
			normals[index] = (normal_basis * normals[index]).normalized()
		arrays[Mesh.ARRAY_NORMAL] = normals
	if arrays[Mesh.ARRAY_TANGENT] != null:
		var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
		for base: int in range(0, tangents.size() - 3, 4):
			var moved: Vector3 = (
				(xform.basis * Vector3(tangents[base], tangents[base + 1], tangents[base + 2]))
				. normalized()
			)
			tangents[base] = moved.x
			tangents[base + 1] = moved.y
			tangents[base + 2] = moved.z
		arrays[Mesh.ARRAY_TANGENT] = tangents
