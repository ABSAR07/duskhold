class_name XRaySilhouette
extends Node
## Lets the parent model show through anything that hides it, as a flat unlit silhouette in
## `stencil_color`, using the engine's stencil X-Ray preset (G-01-3: the king is never lost behind
## a building). Presentation only: it applies once in `_ready` and never touches the simulation.
## Reusable for later units. Add it as the last child of the model so the model's subtree (the
## instanced GLB scenes included) already exists.

## Light cyan: no part of the visible king uses it (gold crown, darker blue collar), so a hidden
## king reads differently from a visible one, and it contrasts with the grey keep, the House and
## tower models and the dark-blue night. The X-Ray pass is unshaded, so night lighting cannot dim
## it.
@export var stencil_color: Color = Color(0.4, 0.9, 1.0, 1.0)

var _applied: int = 0


func _ready() -> void:
	_applied = apply_xray(get_parent(), stencil_color)


## How many surfaces received the X-Ray pass.
func get_applied_count() -> int:
	return _applied


## Gives every BaseMaterial3D surface under `root` (meshes inside instanced scenes included) an
## X-Ray copy of its active material and returns how many were covered. The copy is a shallow
## duplicate (textures stay shared) set as a surface override: the mesh's own material is a
## resource shared by every instance of the imported scene and must never be written to.
## Surfaces with any other material type (a ShaderMaterial, say) are left alone.
static func apply_xray(root: Node, color: Color) -> int:
	var covered: int = 0
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		for surface: int in range(mesh_instance.get_surface_override_material_count()):
			var source: BaseMaterial3D = (
				mesh_instance.get_active_material(surface) as BaseMaterial3D
			)
			if source == null:
				continue
			var copy: BaseMaterial3D = source.duplicate() as BaseMaterial3D
			copy.stencil_mode = BaseMaterial3D.STENCIL_MODE_XRAY
			copy.stencil_color = color
			mesh_instance.set_surface_override_material(surface, copy)
			covered += 1
	return covered
