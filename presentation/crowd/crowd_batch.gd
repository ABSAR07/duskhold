class_name CrowdBatch
extends MultiMeshInstance3D
## One MultiMesh drawn as a single batch, with a CPU mirror of its instance buffer. A frame is
## `begin()`, one `add()` (or `add_transform()`) per instance, then `commit()`, which uploads the
## whole mirror in one call and shows exactly the instances added. The mirror also serves the
## tests: the headless renderer keeps no readback of a MultiMesh (every transform reads back zero),
## so nothing here ever reads the MultiMesh itself.
##
## Buffer layout per instance, in floats (verified on Godot 4.7.2, RESEARCH F6):
## [12 transform: xx xy xz ox, yx yy yz oy, zx zy zz oz][4 colour, only with colours][4 custom].
## Display only: it holds numbers a view hands it and never reads or writes the simulation.

const TRANSFORM_FLOATS: int = 12
const COLOR_FLOATS: int = 4
const CUSTOM_FLOATS: int = 4

var _mirror: PackedFloat32Array = PackedFloat32Array()
var _with_colors: bool = false
var _stride: int = TRANSFORM_FLOATS + CUSTOM_FLOATS
var _custom_offset: int = TRANSFORM_FLOATS
var _capacity: int = 0
var _count: int = 0


## Builds the MultiMesh: `capacity` instances of `mesh` drawn with `material`, every instance
## carrying custom data and, when `with_colors`, a colour. `basis_scale` is the scale written into
## every slot once; a batch that places with `add()` keeps it, one that places with
## `add_transform()` overwrites it. False (and nothing built) for a capacity below 1 or no mesh.
func setup(
	mesh: Mesh,
	material: Material,
	capacity: int,
	with_colors: bool,
	basis_scale: Vector3 = Vector3.ONE
) -> bool:
	if capacity < 1 or mesh == null:
		return false
	_capacity = capacity
	_with_colors = with_colors
	_custom_offset = TRANSFORM_FLOATS + (COLOR_FLOATS if with_colors else 0)
	_stride = _custom_offset + CUSTOM_FLOATS
	_mirror = PackedFloat32Array()
	_mirror.resize(capacity * _stride)
	for index: int in range(capacity):
		var offset: int = index * _stride
		_mirror[offset] = basis_scale.x
		_mirror[offset + 5] = basis_scale.y
		_mirror[offset + 10] = basis_scale.z
		if with_colors:
			_mirror[offset + TRANSFORM_FLOATS + 3] = 1.0
	# The format and both flags go in while instance_count is still 0 (RESEARCH Pitfall 2).
	var batch: MultiMesh = MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = with_colors
	batch.use_custom_data = true
	batch.mesh = mesh
	batch.instance_count = capacity
	batch.visible_instance_count = 0
	multimesh = batch
	material_override = material
	_count = 0
	return true


## Fixes the culling box once, so the engine never recomputes it from the instances.
func set_bounds(aabb: AABB) -> void:
	if multimesh != null:
		multimesh.custom_aabb = aabb


## Starts a frame: no instance is held until `add()` puts one back.
func begin() -> void:
	_count = 0


## Appends an instance at `origin`, keeping the setup basis. False when the batch is full (the
## instance is simply not drawn) or not set up.
func add(origin: Vector3, custom: Color, color: Color = Color.WHITE) -> bool:
	if _count >= _capacity:
		return false
	var offset: int = _count * _stride
	_mirror[offset + 3] = origin.x
	_mirror[offset + 7] = origin.y
	_mirror[offset + 11] = origin.z
	_write_data(offset, custom, color)
	_count += 1
	return true


## Appends an instance with its own basis as well as its origin. False when full.
func add_transform(xform: Transform3D, custom: Color, color: Color = Color.WHITE) -> bool:
	if _count >= _capacity:
		return false
	var offset: int = _count * _stride
	var basis: Basis = xform.basis
	for row: int in range(3):
		var base: int = offset + row * 4
		_mirror[base] = basis.x[row]
		_mirror[base + 1] = basis.y[row]
		_mirror[base + 2] = basis.z[row]
	_mirror[offset + 3] = xform.origin.x
	_mirror[offset + 7] = xform.origin.y
	_mirror[offset + 11] = xform.origin.z
	_write_data(offset, custom, color)
	_count += 1
	return true


## Uploads the mirror in one call and shows the instances added since `begin()`; an empty frame
## shows none.
func commit() -> void:
	if multimesh == null:
		return
	multimesh.buffer = _mirror
	multimesh.visible_instance_count = _count


## The CPU mirror itself (a copy-on-write share, so reading it costs nothing until someone writes).
## The native fills (PLAT-01, plan 04-25) start from the batch's own setup mirror.
func mirror() -> PackedFloat32Array:
	return _mirror


## The shape of the mirror for a native writer: [capacity, stride, colour offset or -1 without
## colours, custom data offset], offsets in floats from the start of an instance.
func layout() -> PackedInt64Array:
	var color_offset: int = TRANSFORM_FLOATS if _with_colors else -1
	return PackedInt64Array([_capacity, _stride, color_offset, _custom_offset])


## Takes a mirror a native fill has written (`instances` of them, the rest as earlier frames left
## it) and uploads it exactly as `commit()` does. False, and nothing changes, when the batch is not
## set up, the buffer is not capacity * stride floats or `instances` is outside 0 to the capacity.
func commit_buffer(buffer: PackedFloat32Array, instances: int) -> bool:
	if multimesh == null or _capacity < 1:
		return false
	if buffer.size() != _capacity * _stride or instances < 0 or instances > _capacity:
		return false
	_mirror = buffer
	_count = instances
	commit()
	return true


## Instances added since `begin()`.
func count() -> int:
	return _count


## Instances the batch can hold.
func capacity() -> int:
	return _capacity


## Where instance `index` stands, from the mirror; the zero vector past the live count.
func origin_of(index: int) -> Vector3:
	if index < 0 or index >= _count:
		return Vector3.ZERO
	var offset: int = index * _stride
	return Vector3(_mirror[offset + 3], _mirror[offset + 7], _mirror[offset + 11])


## The basis of instance `index`, from the mirror; the identity past the live count.
func basis_of(index: int) -> Basis:
	if index < 0 or index >= _count:
		return Basis.IDENTITY
	var offset: int = index * _stride
	var column_x: Vector3 = Vector3(_mirror[offset], _mirror[offset + 4], _mirror[offset + 8])
	var column_y: Vector3 = Vector3(_mirror[offset + 1], _mirror[offset + 5], _mirror[offset + 9])
	var column_z: Vector3 = Vector3(_mirror[offset + 2], _mirror[offset + 6], _mirror[offset + 10])
	return Basis(column_x, column_y, column_z)


## The custom data of instance `index`, from the mirror; all zero past the live count.
func custom_of(index: int) -> Color:
	if index < 0 or index >= _count:
		return Color(0.0, 0.0, 0.0, 0.0)
	var offset: int = index * _stride + _custom_offset
	return Color(_mirror[offset], _mirror[offset + 1], _mirror[offset + 2], _mirror[offset + 3])


## The colour of instance `index`, from the mirror; white when the batch has no colours or the
## index is past the live count.
func color_of(index: int) -> Color:
	if not _with_colors or index < 0 or index >= _count:
		return Color.WHITE
	var offset: int = index * _stride + TRANSFORM_FLOATS
	return Color(_mirror[offset], _mirror[offset + 1], _mirror[offset + 2], _mirror[offset + 3])


func _write_data(offset: int, custom: Color, color: Color) -> void:
	if _with_colors:
		var color_offset: int = offset + TRANSFORM_FLOATS
		_mirror[color_offset] = color.r
		_mirror[color_offset + 1] = color.g
		_mirror[color_offset + 2] = color.b
		_mirror[color_offset + 3] = color.a
	var custom_offset: int = offset + _custom_offset
	_mirror[custom_offset] = custom.r
	_mirror[custom_offset + 1] = custom.g
	_mirror[custom_offset + 2] = custom.b
	_mirror[custom_offset + 3] = custom.a
