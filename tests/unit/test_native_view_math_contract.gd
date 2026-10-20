extends GutTest
## PLAT-01 (plan 04-25, exact_port_rules 1 to 3, T-04-65): every Vector3 operation the native view
## fills use gives the same bytes in C++ as in this engine. For 20,000 seeded inputs per operation
## (signed zeros, tiny and huge magnitudes, exact halves, values one ulp around integers, unit axes,
## equal, opposite and parallel pairs for cross, zero vectors for normalized; every component
## finite) the GDScript expression and the NativeSim probe are compared with to_byte_array().
## Sibling of test_native_math_contract.gd (the Vector2 and scalar rows, which already holds 19 of
## the 20 tests a script may carry).
##
## The probes are NativeSim.probe_vector3 and probe_double3 and the codes are the OP_V3_* and
## OP_DBL3_* constants bound on the class (the table is in native/src/native_sim.h; this test
## reads the codes from the class by name, so the two cannot disagree). The operation table at the
## top of native/src/gd_math.h names the proving code of each row.

const COUNT: int = 20000
const DATA_SEED: int = 4250425
const BYTES_PER_VECTOR: int = 12
const BYTES_PER_NUMBER: int = 8
const ULP_STEPS: Array[int] = [-2, -1, 1, 2]
const EDGE_FLOATS: Array[float] = [
	0.0,
	-0.0,
	1e-30,
	-1e-30,
	1e30,
	-1e30,
	0.5,
	-0.5,
	1.5,
	-1.5,
	2.5,
	-2.5,
	1.0,
	-1.0,
	3.0,
	100.0,
]
const EDGE_DOUBLES: Array[float] = [
	0.0, -0.0, 1e-30, -1e-30, 1e30, -1e30, 1e300, -1e300, 0.5, -0.5, 1.0, -1.0, 0.1, 100.0
]
## Components stay finite in float32: the engine warns when asked to normalize a non-finite vector.
const MAX_COMPONENT: float = 3.0e38
const VECTOR3_OPS: Array[String] = [
	"OP_V3_ADD",
	"OP_V3_SUB",
	"OP_V3_MUL_SCALAR",
	"OP_V3_FROM_DOUBLES",
	"OP_V3_NORMALIZED",
	"OP_V3_CROSS",
	"OP_V3_LERP",
]
const DOUBLE3_OPS: Array[String] = [
	"OP_DBL3_LENGTH",
	"OP_DBL3_LENGTH_SQUARED",
	"OP_DBL3_DISTANCE_TO",
]

var _a: PackedVector3Array = PackedVector3Array()
var _b: PackedVector3Array = PackedVector3Array()
var _scalars: PackedFloat64Array = PackedFloat64Array()
var _triples: PackedFloat64Array = PackedFloat64Array()


func before_all() -> void:
	_a = _make_vectors(1, 0)
	_b = _make_vectors(2, 5)
	_scalars = _make_doubles(COUNT, 3)
	_triples = _make_doubles(3 * COUNT, 4)


# --- seeded inputs -----------------------------------------------------------------------------


func _rng_for(stream: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = DATA_SEED + stream
	return rng


## `value` moved by `steps` units in the last place of a 32-bit float, widened back to a double.
func _step_single(value: float, steps: int) -> float:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(4)
	bytes.encode_float(0, value)
	bytes.encode_u32(0, bytes.decode_u32(0) + steps)
	return bytes.decode_float(0)


## One input number: the case is chosen by `index`, so every kind of value recurs through the pool.
func _pick(rng: RandomNumberGenerator, index: int, single: bool) -> float:
	var value: float = 0.0
	match index % 10:
		0, 1, 2, 3:
			value = rng.randf_range(-100.0, 100.0)
		4:
			var edges: Array[float] = EDGE_FLOATS if single else EDGE_DOUBLES
			value = edges[rng.randi() % edges.size()]
		5:
			var whole: float = (
				float(rng.randi_range(1, 5)) * (1.0 if rng.randi() % 2 == 0 else -1.0)
			)
			value = _step_single(whole, ULP_STEPS[rng.randi() % ULP_STEPS.size()])
		6:
			value = rng.randf_range(-1.0, 1.0) * pow(10.0, float(rng.randi_range(-30, 30)))
		7:
			value = float(rng.randi_range(-80, 80)) * 0.5
		_:
			value = rng.randf_range(-1.0, 1.0)
	return value


func _make_doubles(count: int, stream: int) -> PackedFloat64Array:
	var rng: RandomNumberGenerator = _rng_for(stream)
	var pool: PackedFloat64Array = PackedFloat64Array()
	pool.resize(count)
	for index: int in range(count):
		pool[index] = _pick(rng, index, false)
	return pool


func _component(rng: RandomNumberGenerator, index: int) -> float:
	return clampf(_pick(rng, index, true), -MAX_COMPONENT, MAX_COMPONENT)


## COUNT vectors; every 16th is a structural case: a pair equal, opposite or parallel to a, a unit
## axis, or a zero vector.
func _make_vectors(stream: int, offset: int) -> PackedVector3Array:
	var rng: RandomNumberGenerator = _rng_for(stream)
	var pool: PackedVector3Array = PackedVector3Array()
	pool.resize(COUNT)
	for index: int in range(COUNT):
		pool[index] = Vector3(
			_component(rng, index + offset),
			_component(rng, index + offset + 3),
			_component(rng, index + offset + 7)
		)
	var axes: Array[Vector3] = [Vector3.RIGHT, Vector3.UP, Vector3.BACK, -Vector3.UP]
	for index: int in range(COUNT):
		match index % 16:
			0:
				if stream == 2:
					pool[index] = _a[index]
			1:
				if stream == 2:
					pool[index] = -_a[index]
			2:
				if stream == 2:
					pool[index] = _a[index] * 2.0
			3:
				pool[index] = Vector3.ZERO
			4:
				pool[index] = axes[(index >> 4) % axes.size()]
			5:
				if stream == 2:
					pool[index] = axes[((index >> 4) + 1) % axes.size()]
	return pool


# --- probe plumbing ----------------------------------------------------------------------------


func _op(op_name: String) -> int:
	var key: StringName = StringName(op_name)
	if not ClassDB.class_has_integer_constant(&"NativeSim", key):
		fail_test("NativeSim has no op constant %s" % op_name)
		return -1
	return ClassDB.class_get_integer_constant(&"NativeSim", key)


func _has_probe(method: StringName) -> bool:
	if ClassDB.class_exists(&"NativeSim") and ClassDB.class_has_method(&"NativeSim", method):
		return true
	fail_test("NativeSim.%s is missing; run: bash tools/native_build.sh" % method)
	return false


func _probe_vector3(
	op: int, a: PackedVector3Array, b: PackedVector3Array, s: PackedFloat64Array
) -> PackedVector3Array:
	if not _has_probe(&"probe_vector3"):
		return PackedVector3Array()
	var result: Variant = ClassDB.class_call_static(&"NativeSim", &"probe_vector3", op, a, b, s)
	return result if typeof(result) == TYPE_PACKED_VECTOR3_ARRAY else PackedVector3Array()


func _probe_double3(op: int, a: PackedVector3Array, b: PackedVector3Array) -> PackedFloat64Array:
	if not _has_probe(&"probe_double3"):
		return PackedFloat64Array()
	var result: Variant = ClassDB.class_call_static(&"NativeSim", &"probe_double3", op, a, b)
	return result if typeof(result) == TYPE_PACKED_FLOAT64_ARRAY else PackedFloat64Array()


## The index of the first element (of `stride` bytes) at which the byte arrays differ, or -1.
func _first_difference(expected: PackedByteArray, actual: PackedByteArray, stride: int) -> int:
	if expected == actual:
		return -1
	var shared: int = mini(expected.size(), actual.size())
	for offset: int in range(shared):
		if expected[offset] != actual[offset]:
			@warning_ignore("integer_division")
			return offset / stride
	@warning_ignore("integer_division")
	return shared / stride


func _check_vectors(
	label: String, expected: PackedVector3Array, actual: PackedVector3Array
) -> void:
	assert_eq(actual.size(), expected.size(), "%s: one result per input" % label)
	var bad: int = _first_difference(
		expected.to_byte_array(), actual.to_byte_array(), BYTES_PER_VECTOR
	)
	assert_eq(bad, -1, "%s: first input index whose result differs in bytes" % label)
	if bad >= 0 and bad < expected.size() and bad < actual.size():
		gut.p("%s differs at %d: engine %s native %s" % [label, bad, expected[bad], actual[bad]])


func _check_doubles(
	label: String, expected: PackedFloat64Array, actual: PackedFloat64Array
) -> void:
	assert_eq(actual.size(), expected.size(), "%s: one result per input" % label)
	var bad: int = _first_difference(
		expected.to_byte_array(), actual.to_byte_array(), BYTES_PER_NUMBER
	)
	assert_eq(bad, -1, "%s: first input index whose result differs in bytes" % label)
	if bad >= 0 and bad < expected.size() and bad < actual.size():
		gut.p("%s differs at %d: engine %s native %s" % [label, bad, expected[bad], actual[bad]])


func _blank_vectors() -> PackedVector3Array:
	var blank: PackedVector3Array = PackedVector3Array()
	blank.resize(COUNT)
	return blank


func _blank_doubles() -> PackedFloat64Array:
	var blank: PackedFloat64Array = PackedFloat64Array()
	blank.resize(COUNT)
	return blank


# --- the contract ------------------------------------------------------------------------------


func test_the_seeded_inputs_cover_the_edge_cases() -> void:
	assert_eq(_a.size(), COUNT, "20,000 vectors")
	assert_eq(_b.size(), COUNT, "20,000 partners")
	assert_eq(_scalars.size(), COUNT, "20,000 scalars")
	assert_eq(_triples.size(), 3 * COUNT, "three doubles per vector")
	var zero_vectors: int = 0
	var negative_zeros: int = 0
	var opposite_pairs: int = 0
	var axis_pairs: int = 0
	for index: int in range(COUNT):
		if _a[index] == Vector3.ZERO:
			zero_vectors += 1
		if _a[index].x == 0.0 and 1.0 / _a[index].x < 0.0:
			negative_zeros += 1
		if _b[index] == -_a[index] and _a[index] != Vector3.ZERO:
			opposite_pairs += 1
		if _b[index] == Vector3.RIGHT or _b[index] == Vector3.UP or _b[index] == Vector3.BACK:
			axis_pairs += 1
		assert_true(_a[index].is_finite() and _b[index].is_finite(), "inputs are finite")
	assert_gt(zero_vectors, 500, "zero vectors for normalized")
	assert_gt(negative_zeros, 10, "negative zero components")
	assert_gt(opposite_pairs, 500, "anti-parallel pairs for cross")
	assert_gt(axis_pairs, 500, "unit axes")


func test_every_op_constant_is_bound_and_unique_within_its_probe() -> void:
	if not ClassDB.class_exists(&"NativeSim"):
		fail_test("NativeSim is missing; run: bash tools/native_build.sh")
		return
	for names: Array[String] in [VECTOR3_OPS, DOUBLE3_OPS]:
		var seen: Dictionary = {}
		for op_name: String in names:
			assert_true(
				ClassDB.class_has_integer_constant(&"NativeSim", StringName(op_name)),
				"%s is bound" % op_name
			)
			var code: int = _op(op_name)
			assert_false(seen.has(code), "%s has its own code" % op_name)
			seen[code] = true


func test_vector_plus_and_minus_vector() -> void:
	var added: PackedVector3Array = _blank_vectors()
	var subtracted: PackedVector3Array = _blank_vectors()
	for index: int in range(COUNT):
		added[index] = _a[index] + _b[index]
		subtracted[index] = _a[index] - _b[index]
	_check_vectors("a + b", added, _probe_vector3(_op("OP_V3_ADD"), _a, _b, _scalars))
	_check_vectors("a - b", subtracted, _probe_vector3(_op("OP_V3_SUB"), _a, _b, _scalars))


func test_vector_times_a_scalar_narrows_the_scalar() -> void:
	var product: PackedVector3Array = _blank_vectors()
	for index: int in range(COUNT):
		product[index] = _a[index] * _scalars[index]
	_check_vectors("a * s", product, _probe_vector3(_op("OP_V3_MUL_SCALAR"), _a, _b, _scalars))


func test_a_vector_built_from_three_doubles_narrows_all_three() -> void:
	var built: PackedVector3Array = _blank_vectors()
	for index: int in range(COUNT):
		built[index] = Vector3(
			_triples[3 * index], _triples[3 * index + 1], _triples[3 * index + 2]
		)
	_check_vectors(
		"Vector3(x, y, z)", built, _probe_vector3(_op("OP_V3_FROM_DOUBLES"), _a, _b, _triples)
	)


func test_normalized() -> void:
	var expected: PackedVector3Array = _blank_vectors()
	for index: int in range(COUNT):
		expected[index] = _a[index].normalized()
	_check_vectors(
		"normalized", expected, _probe_vector3(_op("OP_V3_NORMALIZED"), _a, _b, _scalars)
	)


func test_cross() -> void:
	var expected: PackedVector3Array = _blank_vectors()
	for index: int in range(COUNT):
		expected[index] = _a[index].cross(_b[index])
	_check_vectors("cross", expected, _probe_vector3(_op("OP_V3_CROSS"), _a, _b, _scalars))


func test_lerp_narrows_its_weight() -> void:
	var expected: PackedVector3Array = _blank_vectors()
	for index: int in range(COUNT):
		expected[index] = _a[index].lerp(_b[index], _scalars[index])
	_check_vectors("lerp", expected, _probe_vector3(_op("OP_V3_LERP"), _a, _b, _scalars))


func test_length_and_length_squared_widen_a_float32_result() -> void:
	var lengths: PackedFloat64Array = _blank_doubles()
	var squares: PackedFloat64Array = _blank_doubles()
	for index: int in range(COUNT):
		lengths[index] = _a[index].length()
		squares[index] = _a[index].length_squared()
	_check_doubles("length", lengths, _probe_double3(_op("OP_DBL3_LENGTH"), _a, _b))
	_check_doubles("length_squared", squares, _probe_double3(_op("OP_DBL3_LENGTH_SQUARED"), _a, _b))


func test_distance_to_widens_a_float32_result() -> void:
	var expected: PackedFloat64Array = _blank_doubles()
	for index: int in range(COUNT):
		expected[index] = _a[index].distance_to(_b[index])
	_check_doubles("distance_to", expected, _probe_double3(_op("OP_DBL3_DISTANCE_TO"), _a, _b))


func test_an_unknown_op_or_mismatched_sizes_answer_an_empty_array() -> void:
	var few: PackedVector3Array = PackedVector3Array([Vector3.ONE, Vector3.UP])
	var one: PackedVector3Array = PackedVector3Array([Vector3.ONE])
	var scalars: PackedFloat64Array = PackedFloat64Array([1.0, 2.0])
	assert_eq(_probe_vector3(-1, few, few, scalars).size(), 0, "an unknown vector op")
	assert_eq(_probe_vector3(_op("OP_V3_ADD"), few, one, scalars).size(), 0, "b of another size")
	assert_eq(_probe_vector3(_op("OP_V3_LERP"), few, few, PackedFloat64Array()).size(), 0, "no s")
	assert_eq(
		_probe_vector3(_op("OP_V3_FROM_DOUBLES"), few, few, scalars).size(), 0, "too few doubles"
	)
	assert_eq(_probe_double3(-1, few, few).size(), 0, "an unknown double op")
	assert_eq(_probe_double3(_op("OP_DBL3_LENGTH"), few, one).size(), 0, "b of another size")
