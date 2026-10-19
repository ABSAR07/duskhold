#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/packed_int64_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

// The native side of the simulation (PLAT-01). Plan 04-14 proved the library loads and reports what
// it was built from; plan 04-15 adds the push-apart pass as static methods behind the unchanged
// GDScript API of Separation (simulation/squads/separation.gd) and the math probes below; the rest
// of the enemy and wall step follows in later plans of phase 04.
//
// MATH PROBES. tests/unit/test_native_math_contract.gd calls the three probes with seeded inputs
// and compares the bytes with the same GDScript expressions. The op codes are the constants bound
// on the class (NativeSim.OP_VEC_ADD ...): this enum is the one table, and the test reads the
// codes from the class by name. Every probe returns an empty array for an unknown op code or for
// input arrays whose sizes the op does not accept (exact_port_rules 10); a code with the suffix
// _CPP calls godot-cpp's own method instead of the gd_math.h mirror, so the contract test shows
// which of the two is bit-equal to the engine (the operation table at the top of gd_math.h).
//
//   probe_vector(op, a, b, s) -> PackedVector2Array, one result per element of `a`:
//     `b` must have the size of `a`; `s` too, except OP_VEC_FROM_DOUBLES, which needs 2 * size.
//     OP_VEC_ADD              a + b                         OP_VEC_SUB          a - b
//     OP_VEC_MUL_SCALAR       a * s (s narrowed)            OP_VEC_SCALAR_MUL   s * a (s narrowed)
//     OP_VEC_DIV_SCALAR       a / s (s narrowed)            OP_VEC_FROM_DOUBLES Vector2(s[2i], s[2i + 1])
//     OP_VEC_NORMALIZED       a.normalized()
//     OP_VEC_MOVE_TOWARD      a.move_toward(b, s)           OP_VEC_LERP         a.lerp(b, s)
//     OP_VEC_NORMALIZED_CPP, OP_VEC_MOVE_TOWARD_CPP, OP_VEC_LERP_CPP: the godot-cpp methods
//   probe_double(op, a, b, x, y) -> PackedFloat64Array, one result per element of `x`; a, b and y
//     must have the size of `x`:
//     OP_DBL_LENGTH a.length()          OP_DBL_LENGTH_SQUARED a.length_squared()
//     OP_DBL_DISTANCE_TO a.distance_to(b)   OP_DBL_DISTANCE_SQUARED_TO a.distance_squared_to(b)
//     OP_DBL_DOT a.dot(b)               OP_DBL_CROSS a.cross(b)
//     OP_DBL_MAXF maxf(x, y)            OP_DBL_MINF minf(x, y)
//     OP_DBL_CLAMPF clampf(x, y, b.x)   OP_DBL_ABSF absf(x)        OP_DBL_SQRT sqrt(x)
//     OP_DBL_*_CPP for LENGTH, LENGTH_SQUARED, DISTANCE_TO, DISTANCE_SQUARED_TO, DOT, CROSS: the
//     godot-cpp methods (a Vector2 method result leaves as a double)
//   probe_int(op, x, y, m, n, k) -> PackedInt64Array, one result per element of `x`; y, m, n and k
//     must have the size of `x`:
//     OP_INT_FLOORI floori(x)   OP_INT_CEILI ceili(x)   OP_INT_ROUNDI roundi(x)
//     OP_INT_POSMOD posmod(m, n)   OP_INT_MINI mini(m, n)   OP_INT_MAXI maxi(m, n)
//     OP_INT_CLAMPI clampi(m, n, k)   OP_INT_TICKS SimClock.ticks(x)
//     OP_INT_FLIGHT_TICKS SimClock.flight_ticks(x, y)
class NativeSim : public RefCounted {
	GDCLASS(NativeSim, RefCounted)

protected:
	static void _bind_methods();

public:
	enum {
		OP_VEC_ADD = 0,
		OP_VEC_SUB = 1,
		OP_VEC_MUL_SCALAR = 2,
		OP_VEC_SCALAR_MUL = 3,
		OP_VEC_DIV_SCALAR = 4,
		OP_VEC_FROM_DOUBLES = 5,
		OP_VEC_NORMALIZED = 6,
		OP_VEC_MOVE_TOWARD = 7,
		OP_VEC_LERP = 8,
		OP_VEC_NORMALIZED_CPP = 16,
		OP_VEC_MOVE_TOWARD_CPP = 17,
		OP_VEC_LERP_CPP = 18,

		OP_DBL_LENGTH = 0,
		OP_DBL_LENGTH_SQUARED = 1,
		OP_DBL_DISTANCE_TO = 2,
		OP_DBL_DISTANCE_SQUARED_TO = 3,
		OP_DBL_DOT = 4,
		OP_DBL_CROSS = 5,
		OP_DBL_MAXF = 6,
		OP_DBL_MINF = 7,
		OP_DBL_CLAMPF = 8,
		OP_DBL_ABSF = 9,
		OP_DBL_SQRT = 10,
		OP_DBL_LENGTH_CPP = 16,
		OP_DBL_LENGTH_SQUARED_CPP = 17,
		OP_DBL_DISTANCE_TO_CPP = 18,
		OP_DBL_DISTANCE_SQUARED_TO_CPP = 19,
		OP_DBL_DOT_CPP = 20,
		OP_DBL_CROSS_CPP = 21,

		OP_INT_FLOORI = 0,
		OP_INT_CEILI = 1,
		OP_INT_ROUNDI = 2,
		OP_INT_POSMOD = 3,
		OP_INT_MINI = 4,
		OP_INT_MAXI = 5,
		OP_INT_CLAMPI = 6,
		OP_INT_TICKS = 7,
		OP_INT_FLIGHT_TICKS = 8,
	};

	static String version();
	static String godot_cpp_pin();
	static String api_version();
	static int64_t real_t_bytes();

	// Separation.displacements and Separation.displacements_bucketed (native_separation.cpp).
	static PackedVector2Array separation_displacements(
			const PackedVector2Array &positions,
			const PackedFloat64Array &radii,
			const PackedInt64Array &ids);
	static PackedVector2Array separation_displacements_bucketed(
			const PackedVector2Array &positions,
			const PackedFloat64Array &radii,
			const PackedInt64Array &ids,
			double cell);

	// The math probes of the contract test (see the table above).
	static PackedVector2Array probe_vector(
			int64_t op,
			const PackedVector2Array &a,
			const PackedVector2Array &b,
			const PackedFloat64Array &s);
	static PackedFloat64Array probe_double(
			int64_t op,
			const PackedVector2Array &a,
			const PackedVector2Array &b,
			const PackedFloat64Array &x,
			const PackedFloat64Array &y);
	static PackedInt64Array probe_int(
			int64_t op,
			const PackedFloat64Array &x,
			const PackedFloat64Array &y,
			const PackedInt64Array &m,
			const PackedInt64Array &n,
			const PackedInt64Array &k);
};

} // namespace godot
