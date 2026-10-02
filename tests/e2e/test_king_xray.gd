extends GutTest
## G-01-3 part 1 on the real scene: every visible part of the king carries the stencil X-Ray pass,
## so a building that hides him never hides where he is. The imported (shared) materials must stay
## untouched, and buildings must not show through each other.

const EXTRA_GOLD: int = 500
const HOUSE_SPOTS: Array[StringName] = [&"house_1", &"house_2", &"house_3"]
const MIN_KING_SURFACES: int = 4
const SILHOUETTE := Color(0.4, 0.9, 1.0, 1.0)


func _spawn() -> MapRoot:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	map_root.get_context().economy.grant(EXTRA_GOLD)
	return map_root


## Every (mesh instance, surface index) pair under `root`, including meshes inside instanced GLBs.
func _surfaces(root: Node) -> Array[Array]:
	var found: Array[Array] = []
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		for surface: int in range(mesh_instance.get_surface_override_material_count()):
			found.append([mesh_instance, surface])
	return found


func _xray_node(map_root: MapRoot) -> XRaySilhouette:
	var model: Node = map_root.get_king().get_node("Model")
	return model.find_child("XRay", true, false) as XRaySilhouette


func test_every_king_surface_has_the_xray_pass_in_the_silhouette_colour() -> void:
	var map_root: MapRoot = await _spawn()
	var xray: XRaySilhouette = _xray_node(map_root)
	assert_not_null(xray, "the king model has an XRay node")
	if xray == null:
		return
	var surfaces: Array[Array] = _surfaces(map_root.get_king().get_node("Model"))
	assert_gt(surfaces.size(), MIN_KING_SURFACES - 1, "horse, body, head and crown at least")
	for entry: Array in surfaces:
		var mesh_instance: MeshInstance3D = entry[0]
		var surface: int = entry[1]
		var material: Material = mesh_instance.get_active_material(surface)
		var label: String = "%s surface %d" % [mesh_instance.name, surface]
		assert_true(material is BaseMaterial3D, "%s is a BaseMaterial3D" % label)
		if material is BaseMaterial3D:
			var base: BaseMaterial3D = material as BaseMaterial3D
			assert_eq(
				base.stencil_mode,
				BaseMaterial3D.STENCIL_MODE_XRAY,
				"%s uses the X-Ray stencil" % label
			)
			assert_eq(
				base.stencil_color, xray.stencil_color, "%s has the silhouette colour" % label
			)


func test_the_xray_node_counts_every_surface_it_covered() -> void:
	var map_root: MapRoot = await _spawn()
	var xray: XRaySilhouette = _xray_node(map_root)
	assert_not_null(xray, "the king model has an XRay node")
	if xray == null:
		return
	var surfaces: Array[Array] = _surfaces(map_root.get_king().get_node("Model"))
	assert_gt(xray.get_applied_count(), 3, "more than horse, body and head")
	assert_eq(xray.get_applied_count(), surfaces.size(), "one count per king surface")
	assert_eq(xray.stencil_color, SILHOUETTE, "the shipped colour is light cyan")


func test_imported_materials_shared_with_other_instances_are_not_mutated() -> void:
	var map_root: MapRoot = await _spawn()
	var checked: int = 0
	for entry: Array in _surfaces(map_root.get_king().get_node("Model")):
		var mesh_instance: MeshInstance3D = entry[0]
		var surface: int = entry[1]
		var source: Material = mesh_instance.mesh.surface_get_material(surface)
		if source is BaseMaterial3D:
			checked += 1
			assert_eq(
				(source as BaseMaterial3D).stencil_mode,
				BaseMaterial3D.STENCIL_MODE_DISABLED,
				"%s surface %d source material is untouched" % [mesh_instance.name, surface]
			)
	assert_gt(checked, 0, "at least one king surface has a mesh-owned material to protect")


func test_buildings_never_get_the_xray_pass() -> void:
	var map_root: MapRoot = await _spawn()
	var ctx: RunContext = map_root.get_context()
	for spot_id: StringName in HOUSE_SPOTS:
		ctx.commands.submit(BuildIntent.new(spot_id))
	await wait_process_frames(1)
	var views: Node = map_root.get_node("BuildingViews")
	assert_not_null(views.get_node_or_null("CastleCenter"), "the keep is among the views")
	var checked: int = 0
	for entry: Array in _surfaces(views):
		var mesh_instance: MeshInstance3D = entry[0]
		var material: Material = mesh_instance.get_active_material(entry[1])
		checked += 1
		if material is BaseMaterial3D:
			assert_ne(
				(material as BaseMaterial3D).stencil_mode,
				BaseMaterial3D.STENCIL_MODE_XRAY,
				"%s is not a see-through building" % mesh_instance.name
			)
	assert_gt(checked, 0, "the buildings have surfaces to check")


func test_apply_xray_covers_standard_materials_only_and_copies_them() -> void:
	var fixture: Node3D = Node3D.new()
	add_child_autofree(fixture)
	var plain: StandardMaterial3D = StandardMaterial3D.new()
	plain.albedo_color = Color(0.2, 0.3, 0.4)
	var plain_mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.material = plain
	plain_mesh.mesh = box
	fixture.add_child(plain_mesh)
	var shader_material: ShaderMaterial = ShaderMaterial.new()
	var shader_mesh: MeshInstance3D = MeshInstance3D.new()
	var other_box: BoxMesh = BoxMesh.new()
	other_box.material = shader_material
	shader_mesh.mesh = other_box
	fixture.add_child(shader_mesh)

	var count: int = XRaySilhouette.apply_xray(fixture, SILHOUETTE)

	assert_eq(count, 1, "only the StandardMaterial3D surface was covered")
	var copy: BaseMaterial3D = plain_mesh.get_active_material(0) as BaseMaterial3D
	assert_not_null(copy, "the plain surface now has an override")
	assert_ne(copy, plain, "the override is a copy, not the original")
	assert_eq(copy.stencil_mode, BaseMaterial3D.STENCIL_MODE_XRAY, "the copy has the X-Ray pass")
	assert_eq(copy.stencil_color, SILHOUETTE, "the copy has the requested colour")
	assert_eq(copy.albedo_color, plain.albedo_color, "the copy keeps the original look")
	assert_eq(plain.stencil_mode, BaseMaterial3D.STENCIL_MODE_DISABLED, "the original is untouched")
	assert_eq(
		shader_mesh.get_active_material(0), shader_material, "the ShaderMaterial is left alone"
	)
