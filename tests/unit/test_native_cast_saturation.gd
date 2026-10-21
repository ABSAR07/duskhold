extends GutTest
## IN-15: the float-to-integer mirrors floori, ceili and roundi in native/src/gd_math.h are defined
## for every double. An argument outside the int64 range (and a NaN) answers INT64_MIN, which is
## what this engine's hardware conversion answers on x86-64, so the bytes stay equal to the
## GDScript functions while the C++ no longer depends on undefined behaviour. The seeded contract
## test (test_native_math_contract.gd) covers the bulk of the inputs; this one names the boundary.

const INT_MIN: int = -9223372036854775808
## The largest double below 2^63; its negative is the smallest double above -2^63.
const LARGEST_IN_RANGE: float = 9223372036854774784.0
const TWO_POW_63: float = 9223372036854775808.0
const EDGES: Array[float] = [
	NAN,
	INF,
	-INF,
	1.0e19,
	-1.0e19,
	1.0e300,
	-1.0e300,
	TWO_POW_63,
	-TWO_POW_63,
	LARGEST_IN_RANGE,
	-LARGEST_IN_RANGE,
	0.5,
	-0.5,
	2.5,
	-2.5,
	4.0e18,
	-4.0e18,
]

var _x: PackedFloat64Array = PackedFloat64Array()
var _zero_floats: PackedFloat64Array = PackedFloat64Array()
var _zero_ints: PackedInt64Array = PackedInt64Array()


func before_all() -> void:
	_x = PackedFloat64Array(EDGES)
	_zero_floats.resize(_x.size())
	_zero_ints.resize(_x.size())


func _probe(op_name: String) -> PackedInt64Array:
	if not ClassDB.class_exists(&"NativeSim"):
		fail_test("NativeSim is missing; run: bash tools/native_build.sh")
		return PackedInt64Array()
	var result: Variant = ClassDB.class_call_static(
		&"NativeSim",
		&"probe_int",
		ClassDB.class_get_integer_constant(&"NativeSim", StringName(op_name)),
		_x,
		_zero_floats,
		_zero_ints,
		_zero_ints,
		_zero_ints
	)
	return result if typeof(result) == TYPE_PACKED_INT64_ARRAY else PackedInt64Array()


func test_every_edge_value_matches_the_engine() -> void:
	var floors: PackedInt64Array = _probe("OP_INT_FLOORI")
	var ceilings: PackedInt64Array = _probe("OP_INT_CEILI")
	var rounded: PackedInt64Array = _probe("OP_INT_ROUNDI")
	assert_eq(floors.size(), _x.size(), "one floori result per edge value")
	assert_eq(ceilings.size(), _x.size(), "one ceili result per edge value")
	assert_eq(rounded.size(), _x.size(), "one roundi result per edge value")
	for index: int in range(mini(floors.size(), _x.size())):
		assert_eq(floors[index], floori(_x[index]), "floori(%s)" % _x[index])
		assert_eq(ceilings[index], ceili(_x[index]), "ceili(%s)" % _x[index])
		assert_eq(rounded[index], roundi(_x[index]), "roundi(%s)" % _x[index])


func test_a_value_outside_the_int64_range_answers_the_minimum() -> void:
	var floors: PackedInt64Array = _probe("OP_INT_FLOORI")
	var ceilings: PackedInt64Array = _probe("OP_INT_CEILI")
	var rounded: PackedInt64Array = _probe("OP_INT_ROUNDI")
	for index: int in range(7):
		assert_eq(floors[index], INT_MIN, "floori(%s) is the minimum" % _x[index])
		assert_eq(ceilings[index], INT_MIN, "ceili(%s) is the minimum" % _x[index])
		assert_eq(rounded[index], INT_MIN, "roundi(%s) is the minimum" % _x[index])
	assert_eq(floors[7], INT_MIN, "2^63 is out of range")
	assert_eq(floors[8], INT_MIN, "-2^63 converts to the minimum, in range or not")


func test_values_inside_the_range_keep_their_exact_conversion() -> void:
	var floors: PackedInt64Array = _probe("OP_INT_FLOORI")
	var ceilings: PackedInt64Array = _probe("OP_INT_CEILI")
	var rounded: PackedInt64Array = _probe("OP_INT_ROUNDI")
	assert_eq(floors[9], 9223372036854774784, "the largest double below 2^63")
	assert_eq(ceilings[10], -9223372036854774784, "the smallest double above -2^63")
	assert_eq([floors[13], ceilings[13], rounded[13]], [2, 3, 3], "2.5 floors, ceils, rounds up")
	assert_eq([floors[14], ceilings[14], rounded[14]], [-3, -2, -3], "-2.5 rounds away from zero")
