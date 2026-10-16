extends GutTest
## MeshBaker (PLAT-01): a model scene becomes one ArrayMesh with its surfaces, positions and
## materials; a skinned part that cannot be baked (the headless renderer returns nothing for it,
## RESEARCH F7) makes the whole bake null so the caller falls back to a capsule.

const EPSILON: float = 0.0001
const BOX_SIZE := Vector3(1.0, 2.0, 1.0)
const SCALE: float = 2.0
const PART_AT := Vector3(1.0, 0.0, 0.0)
const PRIMITIVE_AT := Vector3(0.0, 3.0, 0.0)
const PRIMITIVE_COLOR := Color(0.2, 0.6, 0.4)


func _box_instance(size: Vector3, material: Material = null) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	return instance


func test_a_plain_mesh_keeps_its_surface_count_and_is_scaled() -> void:
	var root: Node3D = Node3D.new()
	root.add_child(_box_instance(BOX_SIZE))
	var baked: ArrayMesh = MeshBaker.bake(root, SCALE)
	root.free()
	assert_not_null(baked, "a static mesh always bakes")
	if baked == null:
		return
	assert_eq(baked.get_surface_count(), 1, "the box has one surface")
	var size: Vector3 = baked.get_aabb().size
	assert_almost_eq(size.x, BOX_SIZE.x * SCALE, EPSILON, "x is scaled")
	assert_almost_eq(size.y, BOX_SIZE.y * SCALE, EPSILON, "y is scaled")
	assert_almost_eq(size.z, BOX_SIZE.z * SCALE, EPSILON, "z is scaled")


func test_a_part_sits_where_its_node_chain_puts_it() -> void:
	var root: Node3D = Node3D.new()
	var holder: Node3D = Node3D.new()
	holder.position = PART_AT
	root.add_child(holder)
	holder.add_child(_box_instance(BOX_SIZE))
	var baked: ArrayMesh = MeshBaker.bake(root, SCALE)
	root.free()
	assert_not_null(baked, "bakes")
	if baked == null:
		return
	var center: Vector3 = baked.get_aabb().get_center()
	assert_almost_eq(center.x, PART_AT.x * SCALE, EPSILON, "moved by the holder, then scaled")
	assert_almost_eq(center.y, 0.0, EPSILON, "and no higher")


func test_every_mesh_of_the_tree_is_merged_with_its_own_material() -> void:
	var red: StandardMaterial3D = StandardMaterial3D.new()
	red.albedo_color = Color.RED
	var blue: StandardMaterial3D = StandardMaterial3D.new()
	blue.albedo_color = Color.BLUE
	var root: Node3D = Node3D.new()
	root.add_child(_box_instance(BOX_SIZE, red))
	root.add_child(_box_instance(BOX_SIZE, blue))
	var baked: ArrayMesh = MeshBaker.bake(root, 1.0)
	root.free()
	assert_not_null(baked, "bakes")
	if baked == null:
		return
	assert_eq(baked.get_surface_count(), 2, "one surface per mesh")
	assert_eq(baked.surface_get_material(0), red, "the first keeps its material")
	assert_eq(baked.surface_get_material(1), blue, "and so does the second")


func test_a_skinned_part_that_cannot_be_baked_makes_the_bake_null() -> void:
	var root: Node3D = Node3D.new()
	root.add_child(_box_instance(BOX_SIZE))
	var array_mesh: ArrayMesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, BoxMesh.new().get_mesh_arrays())
	var skinned: MeshInstance3D = MeshInstance3D.new()
	skinned.mesh = array_mesh
	skinned.skin = Skin.new()
	root.add_child(skinned)
	var baked: ArrayMesh = MeshBaker.bake(root, SCALE)
	root.free()
	assert_null(baked, "no renderer, no skinned bake, so the caller must fall back")


func test_a_tree_with_no_mesh_bakes_to_nothing() -> void:
	var root: Node3D = Node3D.new()
	root.add_child(Node3D.new())
	var baked: ArrayMesh = MeshBaker.bake(root, SCALE)
	root.free()
	assert_null(baked, "nothing to draw")


func test_append_primitive_adds_one_surface_carrying_the_primitives_material() -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = PRIMITIVE_COLOR
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = BOX_SIZE
	mesh.material = material
	var target: ArrayMesh = ArrayMesh.new()
	MeshBaker.append_primitive(target, mesh, Transform3D(Basis.IDENTITY, PRIMITIVE_AT))
	assert_eq(target.get_surface_count(), 1, "one surface added")
	assert_eq(target.surface_get_material(0), material, "with the primitive's material")
	assert_almost_eq(target.get_aabb().get_center().y, PRIMITIVE_AT.y, EPSILON, "moved up")
	MeshBaker.append_primitive(target, mesh, Transform3D.IDENTITY)
	assert_eq(target.get_surface_count(), 2, "a second call adds a second surface")


func test_append_primitive_ignores_a_missing_mesh_or_target() -> void:
	var target: ArrayMesh = ArrayMesh.new()
	MeshBaker.append_primitive(target, null, Transform3D.IDENTITY)
	assert_eq(target.get_surface_count(), 0, "no mesh, no surface")
	MeshBaker.append_primitive(null, BoxMesh.new(), Transform3D.IDENTITY)
	assert_true(true, "and a null target does not crash")
