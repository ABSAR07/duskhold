extends GutTest
## CrowdBatch (PLAT-01): the MultiMesh flags go in before the instance count, a frame is begin, add
## and commit, and the CPU mirror answers what the headless renderer cannot (it reads a MultiMesh
## back as zeros, RESEARCH F6). Nothing here reads the MultiMesh buffer.

const CAPACITY: int = 8
const EPSILON: float = 0.00001
const FIRST := Vector3(1.0, 2.0, 3.0)
const SECOND := Vector3(-4.0, 0.8, 5.5)
const THIRD := Vector3(7.0, 0.0, -2.0)
const CUSTOM := Color(0.25, 0.5, 0.75, 1.0)
const TINT := Color(0.9, 0.1, 0.4, 1.0)

var _batch: CrowdBatch


func before_each() -> void:
	_batch = CrowdBatch.new()
	add_child_autofree(_batch)


func _setup(
	capacity: int = CAPACITY, with_colors: bool = true, scale: Vector3 = Vector3.ONE
) -> bool:
	return _batch.setup(BoxMesh.new(), StandardMaterial3D.new(), capacity, with_colors, scale)


func test_setup_sets_the_flags_before_the_instance_count() -> void:
	assert_true(_setup(), "a valid setup succeeds")
	var multimesh: MultiMesh = _batch.multimesh
	assert_not_null(multimesh, "the batch owns a multimesh")
	assert_eq(multimesh.transform_format, MultiMesh.TRANSFORM_3D, "3D transforms")
	assert_true(multimesh.use_colors, "colours on")
	assert_true(multimesh.use_custom_data, "custom data on")
	assert_eq(multimesh.instance_count, CAPACITY, "the capacity is allocated")
	assert_eq(multimesh.visible_instance_count, 0, "nothing shows before the first commit")
	assert_eq(_batch.capacity(), CAPACITY, "the capacity is readable")
	assert_eq(_batch.count(), 0, "and the batch starts empty")


func test_added_instances_commit_and_read_back_from_the_mirror() -> void:
	_setup()
	_batch.begin()
	assert_true(_batch.add(FIRST, Color(1.0, 0.0, 0.0, 0.0)), "first add")
	assert_true(_batch.add(SECOND, CUSTOM, TINT), "second add")
	assert_true(_batch.add(THIRD, Color(0.0, 0.0, 0.0, 0.0)), "third add")
	_batch.commit()
	assert_eq(_batch.count(), 3, "three instances")
	assert_eq(_batch.multimesh.visible_instance_count, 3, "three shown")
	assert_eq(_batch.origin_of(0), FIRST, "first origin")
	assert_eq(_batch.origin_of(1), SECOND, "second origin")
	assert_eq(_batch.origin_of(2), THIRD, "third origin")
	assert_eq(_batch.custom_of(1), CUSTOM, "the custom data comes back")
	assert_eq(_batch.color_of(1), TINT, "and so does the colour")
	assert_eq(_batch.custom_of(0).r, 1.0, "the first instance flashes")


func test_a_full_batch_refuses_one_more_instance() -> void:
	_setup()
	_batch.begin()
	for index: int in range(CAPACITY):
		assert_true(_batch.add(Vector3(float(index), 0.0, 0.0), CUSTOM), "slot %d" % index)
	assert_false(_batch.add(THIRD, CUSTOM), "the ninth does not fit")
	assert_eq(_batch.count(), CAPACITY, "the count stays at the capacity")
	_batch.commit()
	assert_eq(_batch.multimesh.visible_instance_count, CAPACITY, "never above the capacity")


func test_an_empty_frame_commits_nothing_and_a_new_frame_starts_over() -> void:
	_setup()
	_batch.begin()
	_batch.add(FIRST, CUSTOM)
	_batch.commit()
	assert_eq(_batch.multimesh.visible_instance_count, 1, "one shown")
	_batch.begin()
	_batch.commit()
	assert_eq(_batch.multimesh.visible_instance_count, 0, "a frame with no add draws nothing")
	assert_eq(_batch.count(), 0, "and holds nothing")
	assert_eq(_batch.origin_of(0), Vector3.ZERO, "a stale slot reads as zero")


func test_the_setup_scale_fills_every_basis() -> void:
	var scale: Vector3 = Vector3(2.0, 0.5, 3.0)
	_setup(CAPACITY, false, scale)
	_batch.begin()
	_batch.add(FIRST, CUSTOM)
	_batch.add(SECOND, CUSTOM)
	assert_eq(_batch.basis_of(0), Basis.IDENTITY.scaled(scale), "the scaled identity")
	assert_eq(_batch.basis_of(1), Basis.IDENTITY.scaled(scale), "in every slot")
	assert_eq(_batch.color_of(0), Color.WHITE, "a batch without colours reads white")


func test_add_transform_keeps_the_given_basis_and_origin() -> void:
	_setup()
	var basis: Basis = Basis(Vector3.UP, 0.7).scaled(Vector3(1.0, 2.0, 3.0))
	_batch.begin()
	assert_true(_batch.add_transform(Transform3D(basis, SECOND), CUSTOM, TINT), "added")
	var back: Basis = _batch.basis_of(0)
	assert_true(back.x.is_equal_approx(basis.x), "x axis")
	assert_true(back.y.is_equal_approx(basis.y), "y axis")
	assert_true(back.z.is_equal_approx(basis.z), "z axis")
	assert_true(_batch.origin_of(0).is_equal_approx(SECOND), "origin")
	assert_eq(_batch.color_of(0), TINT, "colour")


func test_a_batch_without_colours_is_smaller_and_still_reads_custom_data() -> void:
	_setup(CAPACITY, false)
	assert_false(_batch.multimesh.use_colors, "no colours")
	_batch.begin()
	_batch.add(FIRST, CUSTOM, TINT)
	assert_eq(_batch.custom_of(0), CUSTOM, "custom data lands in its own slot")
	assert_eq(_batch.origin_of(0), FIRST, "and the origin is untouched")


func test_setup_refuses_a_capacity_below_one_or_no_mesh_without_an_error() -> void:
	assert_false(_batch.setup(BoxMesh.new(), StandardMaterial3D.new(), 0, true), "capacity 0")
	assert_false(_batch.setup(BoxMesh.new(), StandardMaterial3D.new(), -3, true), "capacity -3")
	assert_false(_batch.setup(null, StandardMaterial3D.new(), CAPACITY, true), "no mesh")
	assert_null(_batch.multimesh, "nothing was built")
	_batch.begin()
	assert_false(_batch.add(FIRST, CUSTOM), "and nothing can be added")
	_batch.commit()
	assert_eq(_batch.count(), 0, "an unbuilt batch stays empty")


func test_set_bounds_fixes_the_culling_box() -> void:
	_setup()
	var box: AABB = AABB(Vector3(-100.0, 0.0, -100.0), Vector3(200.0, 8.0, 200.0))
	_batch.set_bounds(box)
	assert_eq(_batch.multimesh.custom_aabb, box, "the custom aabb is set")


func test_mirror_of_a_fresh_batch_carries_the_setup_scale_on_its_diagonals() -> void:
	var scale: Vector3 = Vector3(2.0, 0.5, 3.0)
	_setup(CAPACITY, true, scale)
	var mirror: PackedFloat32Array = _batch.mirror()
	var stride: int = (
		CrowdBatch.TRANSFORM_FLOATS + CrowdBatch.COLOR_FLOATS + CrowdBatch.CUSTOM_FLOATS
	)
	assert_eq(mirror.size(), CAPACITY * stride, "capacity times stride floats")
	for index: int in range(CAPACITY):
		var offset: int = index * stride
		assert_eq(mirror[offset], scale.x, "x diagonal of slot %d" % index)
		assert_eq(mirror[offset + 5], scale.y, "y diagonal of slot %d" % index)
		assert_eq(mirror[offset + 10], scale.z, "z diagonal of slot %d" % index)
		assert_eq(mirror[offset + CrowdBatch.TRANSFORM_FLOATS + 3], 1.0, "colour alpha 1.0")


func test_layout_names_the_capacity_the_stride_and_both_offsets() -> void:
	_setup(CAPACITY, true)
	assert_eq(_batch.layout(), PackedInt64Array([CAPACITY, 20, 12, 16]), "coloured batch")
	_setup(5, false)
	assert_eq(_batch.layout(), PackedInt64Array([5, 16, -1, 12]), "uncoloured batch")


func test_commit_buffer_takes_a_right_size_buffer_and_refuses_the_rest() -> void:
	_setup()
	var buffer: PackedFloat32Array = _batch.mirror().duplicate()
	buffer[3] = 9.5
	buffer[7] = 8.5
	buffer[11] = 7.5
	assert_true(_batch.commit_buffer(buffer, 1), "a right-size buffer is taken")
	assert_eq(_batch.count(), 1, "the count follows")
	assert_eq(_batch.origin_of(0), Vector3(9.5, 8.5, 7.5), "the origin reads back")
	assert_eq(_batch.multimesh.visible_instance_count, 1, "and one instance shows")
	var short: PackedFloat32Array = PackedFloat32Array([1.0, 2.0])
	assert_false(_batch.commit_buffer(short, 0), "a wrong size is refused")
	assert_false(
		_batch.commit_buffer(buffer, CAPACITY + 1), "a count above the capacity is refused"
	)
	assert_false(_batch.commit_buffer(buffer, -1), "a negative count is refused")
	assert_eq(_batch.count(), 1, "a refusal keeps the count")
	assert_eq(_batch.origin_of(0), Vector3(9.5, 8.5, 7.5), "and the mirror")
