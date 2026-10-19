extends GutTest
## PLAT-01 (plan 04-15, exact_port_rules 1 to 3, T-04-38): every Vector2 operation and GDScript
## utility the native port uses gives the same bytes in C++ as in this engine. For 20,000 seeded
## inputs per operation (signed zeros, exact halves, values one ulp around integers, multiples of
## SimClock.STEP, huge and tiny magnitudes, infinities and NaN among the scalars mixed with uniform
## values) the GDScript expression and the NativeSim probe are compared with to_byte_array().
##
## The probes and their op codes are NativeSim's: probe_vector, probe_double and probe_int, with the
## OP_VEC_*, OP_DBL_* and OP_INT_* constants bound on the class. The one documented table of the op
## codes (which operation, which inputs) is in native/src/native_sim.h; this test reads the codes
## from the class by name, so the two cannot disagree. Every Vector2 method that godot-cpp
## implements out of line has a twin op code (suffix _CPP) that calls godot-cpp's own method, so
## the operation table at the top of native/src/gd_math.h records which of the two is proven equal.

const COUNT: int = 20000
const DATA_SEED: int = 4150415
const BYTES_PER_VECTOR: int = 8
const BYTES_PER_NUMBER: int = 8
const ULP_STEPS: Array[int] = [-2, -1, 1, 2]
const TICK_FRACTIONS: Array[float] = [
	0.00005, 0.0001, 0.00011, 0.00015, 0.0002, 0.001, 0.5, -0.0001, 0.0, 0.99995
]
const SPEEDS: Array[float] = [0.5, 1.0, 2.0, 4.0, 8.0, 30.0]
const SLACKS: Array[float] = [0.0, 0.0001, -0.0001, 0.00005]
const EDGE_DOUBLES: Array[float] = [
	0.0,
	-0.0,
	1e-30,
	-1e-30,
	1e30,
	-1e30,
	1e300,
	-1e300,
	0.5,
	-0.5,
	1.5,
	-1.5,
	2.5,
	-2.5,
	0.1,
	-0.1,
	1.0,
	-1.0,
	3.0,
	0.00001,
	100.0,
	1.0 / 30.0,
	-1.0 / 30.0,
	1073741824.0,
	-1073741824.0,
	4611686018427387904.0,
	-4611686018427387904.0,
	9223372036854774784.0,
	-9223372036854775808.0,
	9223372036854775808.0,
]
## Vector2 inputs stay finite (and NaN free) in float32: the engine warns when asked to normalize a
## non-finite vector, and the payload a NaN keeps when two NaN operands meet is a compiler choice.
const MAX_COMPONENT: float = 3.0e38
const NON_FINITE_EVERY: Array[int] = [997, 1009, 1013]
const INT_MIN: int = -9223372036854775807 - 1
const INT_MAX: int = 9223372036854775807
const EDGE_INTS: Array[int] = [
	0,
	1,
	-1,
	2,
	-2,
	3,
	-3,
	7,
	-7,
	30,
	-30,
	1 << 30,
	-(1 << 30),
	1 << 62,
	-(1 << 62),
	INT_MAX,
	INT_MIN,
	INT_MIN + 1,
]
const VECTOR_OPS: Array[String] = [
	"OP_VEC_ADD",
	"OP_VEC_SUB",
	"OP_VEC_MUL_SCALAR",
	"OP_VEC_SCALAR_MUL",
	"OP_VEC_DIV_SCALAR",
	"OP_VEC_FROM_DOUBLES",
	"OP_VEC_NORMALIZED",
	"OP_VEC_MOVE_TOWARD",
	"OP_VEC_LERP",
	"OP_VEC_NORMALIZED_CPP",
	"OP_VEC_MOVE_TOWARD_CPP",
	"OP_VEC_LERP_CPP",
]
const DOUBLE_OPS: Array[String] = [
	"OP_DBL_LENGTH",
	"OP_DBL_LENGTH_SQUARED",
	"OP_DBL_DISTANCE_TO",
	"OP_DBL_DISTANCE_SQUARED_TO",
	"OP_DBL_DOT",
	"OP_DBL_CROSS",
	"OP_DBL_MAXF",
	"OP_DBL_MINF",
	"OP_DBL_CLAMPF",
	"OP_DBL_ABSF",
	"OP_DBL_SQRT",
	"OP_DBL_LENGTH_CPP",
	"OP_DBL_LENGTH_SQUARED_CPP",
	"OP_DBL_DISTANCE_TO_CPP",
	"OP_DBL_DISTANCE_SQUARED_TO_CPP",
	"OP_DBL_DOT_CPP",
	"OP_DBL_CROSS_CPP",
]
const INT_OPS: Array[String] = [
	"OP_INT_FLOORI",
	"OP_INT_CEILI",
	"OP_INT_ROUNDI",
	"OP_INT_POSMOD",
	"OP_INT_MINI",
	"OP_INT_MAXI",
	"OP_INT_CLAMPI",
	"OP_INT_TICKS",
	"OP_INT_FLIGHT_TICKS",
]

var _vec_a: PackedVector2Array = PackedVector2Array()
var _vec_b: PackedVector2Array = PackedVector2Array()
var _scalars: PackedFloat64Array = PackedFloat64Array()
var _pairs: PackedFloat64Array = PackedFloat64Array()
var _x: PackedFloat64Array = PackedFloat64Array()
var _y: PackedFloat64Array = PackedFloat64Array()
var _m: PackedInt64Array = PackedInt64Array()
var _n: PackedInt64Array = PackedInt64Array()
var _k: PackedInt64Array = PackedInt64Array()
var _divisors: PackedInt64Array = PackedInt64Array()


func before_all() -> void:
	_vec_a = _make_vectors(1, 0)
	_vec_b = _make_vectors(2, 5)
	_scalars = _make_doubles(COUNT, 3)
	_pairs = _make_doubles(2 * COUNT, 4)
	_x = _with_non_finite(_make_doubles(COUNT, 5))
	_y = _with_non_finite(_make_doubles(COUNT, 6))
	_add_tick_boundaries()
	_m = _make_ints(7)
	_n = _make_ints(8)
	_k = _make_ints(9)
	_divisors = _n.duplicate()
	for index: int in range(COUNT):
		if _divisors[index] == 0 or (_divisors[index] == -1 and _m[index] == INT_MIN):
			_divisors[index] = 3


# --- seeded inputs -----------------------------------------------------------------------------


func _rng_for(stream: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = DATA_SEED + stream
	return rng


## `value` moved by `steps` units in the last place of a 64-bit double.
func _step_double(value: float, steps: int) -> float:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	bytes.encode_s64(0, bytes.decode_s64(0) + steps)
	return bytes.decode_double(0)


## `value` moved by `steps` units in the last place of a 32-bit float, widened back to a double.
func _step_single(value: float, steps: int) -> float:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(4)
	bytes.encode_float(0, value)
	bytes.encode_u32(0, bytes.decode_u32(0) + steps)
	return bytes.decode_float(0)


## One input number: the case is chosen by `index`, so every kind of value recurs through the pool.
## `single` moves the integer neighbours by float32 ulps (for the components of a Vector2).
func _pick_double(rng: RandomNumberGenerator, index: int, single: bool) -> float:
	var value: float = 0.0
	match index % 10:
		0, 1, 2, 3:
			value = rng.randf_range(-100.0, 100.0)
		4:
			value = EDGE_DOUBLES[rng.randi() % EDGE_DOUBLES.size()]
		5:
			var whole: float = (
				float(rng.randi_range(1, 5)) * (1.0 if rng.randi() % 2 == 0 else -1.0)
			)
			var steps: int = ULP_STEPS[rng.randi() % ULP_STEPS.size()]
			value = _step_single(whole, steps) if single else _step_double(whole, steps)
		6:
			var multiple: float = float(rng.randi_range(-40, 3000)) * SimClock.STEP
			value = multiple + SLACKS[rng.randi() % SLACKS.size()]
		7:
			value = float(rng.randi_range(-80, 80)) * 0.5
		8:
			value = rng.randf_range(-1.0, 1.0) * pow(10.0, float(rng.randi_range(-30, 30)))
		_:
			value = rng.randf_range(-1.0, 1.0)
	return value


func _make_doubles(count: int, stream: int) -> PackedFloat64Array:
	var rng: RandomNumberGenerator = _rng_for(stream)
	var pool: PackedFloat64Array = PackedFloat64Array()
	pool.resize(count)
	for index: int in range(count):
		pool[index] = _pick_double(rng, index, false)
	return pool


## Every 7th pair becomes a duration or a distance and speed whose tick count sits on the rounding
## slack of SimClock.ticks (the fraction of a step lies within a hair of 0.0001): a power of two as
## the speed keeps distance / speed exact, so a slack of 0.00005 or 0.0002 would round differently.
func _add_tick_boundaries() -> void:
	var rng: RandomNumberGenerator = _rng_for(10)
	for index: int in range(COUNT):
		if index % 7 != 2:
			continue
		var whole: float = float(rng.randi_range(0, 3000))
		var fraction: float = TICK_FRACTIONS[rng.randi() % TICK_FRACTIONS.size()]
		var speed: float = SPEEDS[rng.randi() % SPEEDS.size()]
		_y[index] = speed
		_x[index] = (whole + fraction) * SimClock.STEP * speed


## Infinities and NaN at fixed places, among the scalars only (they stay out of the Vector2 inputs).
func _with_non_finite(pool: PackedFloat64Array) -> PackedFloat64Array:
	for index: int in range(pool.size()):
		if index % NON_FINITE_EVERY[0] == 7:
			pool[index] = NAN
		elif index % NON_FINITE_EVERY[1] == 11:
			pool[index] = INF
		elif index % NON_FINITE_EVERY[2] == 13:
			pool[index] = -INF
	return pool


## COUNT vectors; every 16th is a structural case: equal to b, the negative of b, or zero.
func _make_vectors(stream: int, offset: int) -> PackedVector2Array:
	var rng: RandomNumberGenerator = _rng_for(stream)
	var pool: PackedVector2Array = PackedVector2Array()
	pool.resize(COUNT)
	for index: int in range(COUNT):
		var first: float = clampf(
			_pick_double(rng, index + offset, true), -MAX_COMPONENT, MAX_COMPONENT
		)
		var second: float = clampf(
			_pick_double(rng, index + offset + 3, true), -MAX_COMPONENT, MAX_COMPONENT
		)
		pool[index] = Vector2(first, second)
	if stream == 2:
		for index: int in range(COUNT):
			match index % 16:
				0:
					pool[index] = _vec_a[index]
				1:
					pool[index] = -_vec_a[index]
				2:
					pool[index] = Vector2.ZERO
				3:
					_vec_a[index] = Vector2.ZERO
	return pool


func _make_ints(stream: int) -> PackedInt64Array:
	var rng: RandomNumberGenerator = _rng_for(stream)
	var pool: PackedInt64Array = PackedInt64Array()
	pool.resize(COUNT)
	for index: int in range(COUNT):
		var value: int = 0
		match index % 6:
			0, 1:
				value = rng.randi_range(-1000, 1000)
			2:
				value = EDGE_INTS[rng.randi() % EDGE_INTS.size()]
			3:
				value = (rng.randi() << 31) ^ rng.randi()
			4:
				value = -((rng.randi() << 20) ^ rng.randi())
			_:
				value = rng.randi_range(-100000, 100000) * 30
		pool[index] = value
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


func _probe_vector(
	op_name: String, a: PackedVector2Array, b: PackedVector2Array, s: PackedFloat64Array
) -> PackedVector2Array:
	if not _has_probe(&"probe_vector"):
		return PackedVector2Array()
	var result: Variant = ClassDB.class_call_static(
		&"NativeSim", &"probe_vector", _op(op_name), a, b, s
	)
	return result if typeof(result) == TYPE_PACKED_VECTOR2_ARRAY else PackedVector2Array()


func _probe_double(
	op_name: String,
	a: PackedVector2Array,
	b: PackedVector2Array,
	x: PackedFloat64Array,
	y: PackedFloat64Array
) -> PackedFloat64Array:
	if not _has_probe(&"probe_double"):
		return PackedFloat64Array()
	var result: Variant = ClassDB.class_call_static(
		&"NativeSim", &"probe_double", _op(op_name), a, b, x, y
	)
	return result if typeof(result) == TYPE_PACKED_FLOAT64_ARRAY else PackedFloat64Array()


func _probe_int(
	op_name: String,
	x: PackedFloat64Array,
	y: PackedFloat64Array,
	m: PackedInt64Array,
	n: PackedInt64Array,
	k: PackedInt64Array
) -> PackedInt64Array:
	if not _has_probe(&"probe_int"):
		return PackedInt64Array()
	var result: Variant = ClassDB.class_call_static(
		&"NativeSim", &"probe_int", _op(op_name), x, y, m, n, k
	)
	return result if typeof(result) == TYPE_PACKED_INT64_ARRAY else PackedInt64Array()


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
	label: String, expected: PackedVector2Array, actual: PackedVector2Array
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


func _check_ints(label: String, expected: PackedInt64Array, actual: PackedInt64Array) -> void:
	assert_eq(actual.size(), expected.size(), "%s: one result per input" % label)
	var bad: int = _first_difference(
		expected.to_byte_array(), actual.to_byte_array(), BYTES_PER_NUMBER
	)
	assert_eq(bad, -1, "%s: first input index whose result differs" % label)
	if bad >= 0 and bad < expected.size() and bad < actual.size():
		gut.p("%s differs at %d: engine %s native %s" % [label, bad, expected[bad], actual[bad]])


func _blank_vectors() -> PackedVector2Array:
	var blank: PackedVector2Array = PackedVector2Array()
	blank.resize(COUNT)
	return blank


func _blank_doubles() -> PackedFloat64Array:
	var blank: PackedFloat64Array = PackedFloat64Array()
	blank.resize(COUNT)
	return blank


func _blank_ints() -> PackedInt64Array:
	var blank: PackedInt64Array = PackedInt64Array()
	blank.resize(COUNT)
	return blank


# --- the contract ------------------------------------------------------------------------------


func test_the_seeded_inputs_cover_the_edge_cases() -> void:
	assert_eq(_vec_a.size(), COUNT, "20,000 vectors")
	assert_eq(_x.size(), COUNT, "20,000 scalars")
	var negative_zero: bool = false
	var halves: int = 0
	var step_multiples: int = 0
	for value: float in _x:
		if value == 0.0 and is_zero_approx(value) and 1.0 / value < 0.0:
			negative_zero = true
		if absf(value) == 0.5 or absf(value) == 1.5 or absf(value) == 2.5:
			halves += 1
		if absf(value - roundf(value / SimClock.STEP) * SimClock.STEP) < 1e-12:
			step_multiples += 1
	assert_true(negative_zero, "the scalars hold a negative zero")
	assert_gt(halves, 20, "the scalars hold exact halves")
	assert_gt(step_multiples, 200, "the scalars hold multiples of SimClock.STEP")
	assert_true(_x.has(INF) and _x.has(-INF), "the scalars hold both infinities")
	var any_nan: bool = false
	for value: float in _x:
		any_nan = any_nan or is_nan(value)
	assert_true(any_nan, "the scalars hold NaN")


func test_every_op_constant_is_bound_and_unique_within_its_probe() -> void:
	if not ClassDB.class_exists(&"NativeSim"):
		fail_test("NativeSim is missing; run: bash tools/native_build.sh")
		return
	for names: Array[String] in [VECTOR_OPS, DOUBLE_OPS, INT_OPS]:
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
	var added: PackedVector2Array = _blank_vectors()
	var subtracted: PackedVector2Array = _blank_vectors()
	for index: int in range(COUNT):
		added[index] = _vec_a[index] + _vec_b[index]
		subtracted[index] = _vec_a[index] - _vec_b[index]
	_check_vectors("a + b", added, _probe_vector("OP_VEC_ADD", _vec_a, _vec_b, _scalars))
	_check_vectors("a - b", subtracted, _probe_vector("OP_VEC_SUB", _vec_a, _vec_b, _scalars))


func test_vector_times_and_over_a_scalar_narrows_the_scalar() -> void:
	var product: PackedVector2Array = _blank_vectors()
	var reversed: PackedVector2Array = _blank_vectors()
	var quotient: PackedVector2Array = _blank_vectors()
	for index: int in range(COUNT):
		var scalar: float = _scalars[index]
		product[index] = _vec_a[index] * scalar
		reversed[index] = scalar * _vec_a[index]
		quotient[index] = _vec_a[index] / scalar
	_check_vectors("a * s", product, _probe_vector("OP_VEC_MUL_SCALAR", _vec_a, _vec_b, _scalars))
	_check_vectors("s * a", reversed, _probe_vector("OP_VEC_SCALAR_MUL", _vec_a, _vec_b, _scalars))
	_check_vectors("a / s", quotient, _probe_vector("OP_VEC_DIV_SCALAR", _vec_a, _vec_b, _scalars))


func test_a_vector_built_from_two_doubles_narrows_both() -> void:
	var built: PackedVector2Array = _blank_vectors()
	for index: int in range(COUNT):
		built[index] = Vector2(_pairs[2 * index], _pairs[2 * index + 1])
	_check_vectors(
		"Vector2(x, y)", built, _probe_vector("OP_VEC_FROM_DOUBLES", _vec_a, _vec_b, _pairs)
	)


func test_normalized() -> void:
	var expected: PackedVector2Array = _blank_vectors()
	for index: int in range(COUNT):
		expected[index] = _vec_a[index].normalized()
	_check_vectors(
		"normalized (mirror)",
		expected,
		_probe_vector("OP_VEC_NORMALIZED", _vec_a, _vec_b, _scalars)
	)
	_check_vectors(
		"normalized (godot-cpp)",
		expected,
		_probe_vector("OP_VEC_NORMALIZED_CPP", _vec_a, _vec_b, _scalars)
	)


func test_move_toward_narrows_its_delta() -> void:
	var expected: PackedVector2Array = _blank_vectors()
	for index: int in range(COUNT):
		expected[index] = _vec_a[index].move_toward(_vec_b[index], _scalars[index])
	_check_vectors(
		"move_toward (mirror)",
		expected,
		_probe_vector("OP_VEC_MOVE_TOWARD", _vec_a, _vec_b, _scalars)
	)
	_check_vectors(
		"move_toward (godot-cpp)",
		expected,
		_probe_vector("OP_VEC_MOVE_TOWARD_CPP", _vec_a, _vec_b, _scalars)
	)


func test_lerp_narrows_its_weight() -> void:
	var expected: PackedVector2Array = _blank_vectors()
	for index: int in range(COUNT):
		expected[index] = _vec_a[index].lerp(_vec_b[index], _scalars[index])
	_check_vectors(
		"lerp (mirror)", expected, _probe_vector("OP_VEC_LERP", _vec_a, _vec_b, _scalars)
	)
	_check_vectors(
		"lerp (godot-cpp)", expected, _probe_vector("OP_VEC_LERP_CPP", _vec_a, _vec_b, _scalars)
	)


func test_length_and_length_squared_widen_a_float32_result() -> void:
	var lengths: PackedFloat64Array = _blank_doubles()
	var squares: PackedFloat64Array = _blank_doubles()
	for index: int in range(COUNT):
		lengths[index] = _vec_a[index].length()
		squares[index] = _vec_a[index].length_squared()
	_check_doubles(
		"length (mirror)", lengths, _probe_double("OP_DBL_LENGTH", _vec_a, _vec_b, _x, _y)
	)
	_check_doubles(
		"length (godot-cpp)", lengths, _probe_double("OP_DBL_LENGTH_CPP", _vec_a, _vec_b, _x, _y)
	)
	_check_doubles(
		"length_squared (mirror)",
		squares,
		_probe_double("OP_DBL_LENGTH_SQUARED", _vec_a, _vec_b, _x, _y)
	)
	_check_doubles(
		"length_squared (godot-cpp)",
		squares,
		_probe_double("OP_DBL_LENGTH_SQUARED_CPP", _vec_a, _vec_b, _x, _y)
	)


func test_distance_to_and_distance_squared_to() -> void:
	var distances: PackedFloat64Array = _blank_doubles()
	var squares: PackedFloat64Array = _blank_doubles()
	for index: int in range(COUNT):
		distances[index] = _vec_a[index].distance_to(_vec_b[index])
		squares[index] = _vec_a[index].distance_squared_to(_vec_b[index])
	_check_doubles(
		"distance_to (mirror)",
		distances,
		_probe_double("OP_DBL_DISTANCE_TO", _vec_a, _vec_b, _x, _y)
	)
	_check_doubles(
		"distance_to (godot-cpp)",
		distances,
		_probe_double("OP_DBL_DISTANCE_TO_CPP", _vec_a, _vec_b, _x, _y)
	)
	_check_doubles(
		"distance_squared_to (mirror)",
		squares,
		_probe_double("OP_DBL_DISTANCE_SQUARED_TO", _vec_a, _vec_b, _x, _y)
	)
	_check_doubles(
		"distance_squared_to (godot-cpp)",
		squares,
		_probe_double("OP_DBL_DISTANCE_SQUARED_TO_CPP", _vec_a, _vec_b, _x, _y)
	)


func test_dot_and_cross() -> void:
	var dots: PackedFloat64Array = _blank_doubles()
	var crosses: PackedFloat64Array = _blank_doubles()
	for index: int in range(COUNT):
		dots[index] = _vec_a[index].dot(_vec_b[index])
		crosses[index] = _vec_a[index].cross(_vec_b[index])
	_check_doubles("dot (mirror)", dots, _probe_double("OP_DBL_DOT", _vec_a, _vec_b, _x, _y))
	_check_doubles("dot (godot-cpp)", dots, _probe_double("OP_DBL_DOT_CPP", _vec_a, _vec_b, _x, _y))
	_check_doubles("cross (mirror)", crosses, _probe_double("OP_DBL_CROSS", _vec_a, _vec_b, _x, _y))
	_check_doubles(
		"cross (godot-cpp)", crosses, _probe_double("OP_DBL_CROSS_CPP", _vec_a, _vec_b, _x, _y)
	)


func test_maxf_minf_and_clampf() -> void:
	var largest: PackedFloat64Array = _blank_doubles()
	var smallest: PackedFloat64Array = _blank_doubles()
	var clamped: PackedFloat64Array = _blank_doubles()
	for index: int in range(COUNT):
		largest[index] = maxf(_x[index], _y[index])
		smallest[index] = minf(_x[index], _y[index])
		clamped[index] = clampf(_x[index], _y[index], _vec_b[index].x)
	_check_doubles("maxf", largest, _probe_double("OP_DBL_MAXF", _vec_a, _vec_b, _x, _y))
	_check_doubles("minf", smallest, _probe_double("OP_DBL_MINF", _vec_a, _vec_b, _x, _y))
	_check_doubles("clampf", clamped, _probe_double("OP_DBL_CLAMPF", _vec_a, _vec_b, _x, _y))


func test_absf_and_sqrt() -> void:
	var absolute: PackedFloat64Array = _blank_doubles()
	var roots: PackedFloat64Array = _blank_doubles()
	for index: int in range(COUNT):
		absolute[index] = absf(_x[index])
		roots[index] = sqrt(_x[index])
	_check_doubles("absf", absolute, _probe_double("OP_DBL_ABSF", _vec_a, _vec_b, _x, _y))
	_check_doubles("sqrt", roots, _probe_double("OP_DBL_SQRT", _vec_a, _vec_b, _x, _y))


func test_floori_ceili_and_roundi() -> void:
	var floors: PackedInt64Array = _blank_ints()
	var ceilings: PackedInt64Array = _blank_ints()
	var rounded: PackedInt64Array = _blank_ints()
	for index: int in range(COUNT):
		floors[index] = floori(_x[index])
		ceilings[index] = ceili(_x[index])
		rounded[index] = roundi(_x[index])
	_check_ints("floori", floors, _probe_int("OP_INT_FLOORI", _x, _y, _m, _n, _k))
	_check_ints("ceili", ceilings, _probe_int("OP_INT_CEILI", _x, _y, _m, _n, _k))
	_check_ints("roundi", rounded, _probe_int("OP_INT_ROUNDI", _x, _y, _m, _n, _k))


func test_posmod_takes_the_sign_of_the_divisor() -> void:
	var expected: PackedInt64Array = _blank_ints()
	for index: int in range(COUNT):
		expected[index] = posmod(_m[index], _divisors[index])
	_check_ints("posmod", expected, _probe_int("OP_INT_POSMOD", _x, _y, _m, _divisors, _k))


func test_mini_maxi_and_clampi() -> void:
	var smallest: PackedInt64Array = _blank_ints()
	var largest: PackedInt64Array = _blank_ints()
	var clamped: PackedInt64Array = _blank_ints()
	for index: int in range(COUNT):
		smallest[index] = mini(_m[index], _n[index])
		largest[index] = maxi(_m[index], _n[index])
		clamped[index] = clampi(_m[index], _n[index], _k[index])
	_check_ints("mini", smallest, _probe_int("OP_INT_MINI", _x, _y, _m, _n, _k))
	_check_ints("maxi", largest, _probe_int("OP_INT_MAXI", _x, _y, _m, _n, _k))
	_check_ints("clampi", clamped, _probe_int("OP_INT_CLAMPI", _x, _y, _m, _n, _k))


func test_sim_clock_ticks_saturate_and_never_overflow() -> void:
	var expected: PackedInt64Array = _blank_ints()
	for index: int in range(COUNT):
		expected[index] = SimClock.ticks(_x[index])
	_check_ints("SimClock.ticks", expected, _probe_int("OP_INT_TICKS", _x, _y, _m, _n, _k))
	assert_true(
		expected.has(0), "the inputs reach the zero case (zero, negative and NaN durations)"
	)
	assert_true(expected.has(SimClock.MAX_TICKS), "the inputs reach the saturated case")


func test_sim_clock_flight_ticks_saturate_and_never_overflow() -> void:
	var expected: PackedInt64Array = _blank_ints()
	for index: int in range(COUNT):
		expected[index] = SimClock.flight_ticks(_x[index], _y[index])
	_check_ints(
		"SimClock.flight_ticks", expected, _probe_int("OP_INT_FLIGHT_TICKS", _x, _y, _m, _n, _k)
	)
	assert_true(expected.has(0), "the inputs reach the no-flight case")
	assert_true(expected.has(SimClock.MAX_TICKS), "the inputs reach the saturated case")


func test_an_unknown_op_or_mismatched_sizes_give_empty_results() -> void:
	if (
		not ClassDB.class_exists(&"NativeSim")
		or not ClassDB.class_has_method(&"NativeSim", &"probe_vector")
	):
		fail_test("NativeSim probes are missing; run: bash tools/native_build.sh")
		return
	var short_scalars: PackedFloat64Array = _scalars.slice(0, 10)
	var short_vectors: PackedVector2Array = _vec_b.slice(0, 10)
	var add: int = _op("OP_VEC_ADD")
	var mul: int = _op("OP_VEC_MUL_SCALAR")
	var none: Variant = ClassDB.class_call_static(
		&"NativeSim", &"probe_vector", 9999, _vec_a, _vec_b, _scalars
	)
	assert_eq(none, PackedVector2Array(), "an unknown vector op")
	none = ClassDB.class_call_static(
		&"NativeSim", &"probe_vector", add, _vec_a, short_vectors, _scalars
	)
	assert_eq(none, PackedVector2Array(), "b shorter than a")
	none = ClassDB.class_call_static(
		&"NativeSim", &"probe_vector", mul, _vec_a, _vec_b, short_scalars
	)
	assert_eq(none, PackedVector2Array(), "s shorter than a")
	var doubles: Variant = ClassDB.class_call_static(
		&"NativeSim", &"probe_double", 9999, _vec_a, _vec_b, _x, _y
	)
	assert_eq(doubles, PackedFloat64Array(), "an unknown double op")
	var ints: Variant = ClassDB.class_call_static(
		&"NativeSim", &"probe_int", 9999, _x, _y, _m, _n, _k
	)
	assert_eq(ints, PackedInt64Array(), "an unknown int op")
	ints = ClassDB.class_call_static(
		&"NativeSim", &"probe_int", _op("OP_INT_MINI"), _x, _y, _m, _n.slice(0, 10), _k
	)
	assert_eq(ints, PackedInt64Array(), "n shorter than m")
