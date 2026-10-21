#pragma once

// Bit-exact mirrors of the GDScript utilities and Vector2 operations the native simulation port
// uses (PLAT-01, exact_port_rules 1 to 3, plan 04-15). Every mirror copies the definition in
// Godot 4.7.2-stable (tag 4.7.2-stable of github.com/godotengine/godot) and names its source in a
// comment, so a port reads like the GDScript it replaces.
//
// OPERATION TABLE. For every operation the port may use: where its C++ comes from, the op codes of
// tests/unit/test_native_math_contract.gd that prove it bit-equal to this engine (20,000 seeded
// inputs each, probes in native/src/native_sim.h), and the engine source it was checked against.
// Later plans call only what this table allows. "operator" = godot-cpp's own inline operator;
// "mirror" = the function of that name below (the port calls the mirror: it is inline, compiled
// with this target's flags and does not depend on how godot-cpp built its own library); "also
// godot-cpp" = godot-cpp's out-of-line method gave the same bytes in the test (op code _CPP), so
// it is allowed too. A scalar meets a Vector2 only through a cast to real_t at the operator (a
// GDScript float is a double, a Vector2 holds single-precision floats).
//
//   operation                         C++ source               proving op codes           engine source
//   -------------------------------   ----------------------   ------------------------   ----------------------------
//   Vector2 + Vector2, - Vector2      operator                 OP_VEC_ADD, OP_VEC_SUB     core/math/vector2.h
//   Vector2 * s, s * Vector2          operator, s cast to      OP_VEC_MUL_SCALAR,         core/math/vector2.h operator*
//                                     real_t                   OP_VEC_SCALAR_MUL          (+ global operator*(double, V))
//   Vector2 / s                       operator, s cast         OP_VEC_DIV_SCALAR          core/math/vector2.h operator/
//   Vector2(x, y) from doubles        each cast to real_t      OP_VEC_FROM_DOUBLES        GDScript Vector2(x, y) construct
//   length_squared, length            mirror (also godot-cpp)  OP_DBL_LENGTH_SQUARED,     core/math/vector2.cpp
//                                                              OP_DBL_LENGTH (+ _CPP)
//   distance_squared_to, distance_to  mirror (also godot-cpp)  OP_DBL_DISTANCE_*          core/math/vector2.cpp
//   dot, cross                        mirror (also godot-cpp)  OP_DBL_DOT, OP_DBL_CROSS   core/math/vector2.cpp
//   normalized                        mirror (also godot-cpp)  OP_VEC_NORMALIZED          core/math/vector2.cpp normalize
//   move_toward (Vector2)             mirror (also godot-cpp)  OP_VEC_MOVE_TOWARD         core/math/vector2.cpp move_toward
//   lerp (Vector2)                    mirror (also godot-cpp)  OP_VEC_LERP                core/math/vector2.h lerp
//   sqrt                              mirror                   OP_DBL_SQRT                core/variant/variant_utility.cpp
//   maxf, minf, clampf                mirror (MAX, MIN,        OP_DBL_MAXF, _MINF,        core/variant/variant_utility.cpp,
//                                     CLAMP comparisons)       OP_DBL_CLAMPF              core/typedefs.h
//   absf                              mirror                   OP_DBL_ABSF                core/variant/variant_utility.cpp
//   floori, ceili, roundi             mirror                   OP_INT_FLOORI, _CEILI,     core/variant/variant_utility.cpp
//                                                              _ROUNDI
//   posmod, mini, maxi, clampi        mirror                   OP_INT_POSMOD, _MINI,      core/math/math_funcs.h,
//                                                              _MAXI, _CLAMPI             core/variant/variant_utility.cpp
//   SimClock.ticks, flight_ticks      mirror (sim_ticks,       OP_INT_TICKS,              simulation/clock/sim_clock.gd
//                                     sim_flight_ticks)        OP_INT_FLIGHT_TICKS
//
// The Vector3 rows below (plan 04-25, the view fills) are proven by
// tests/unit/test_native_view_math_contract.gd through NativeSim.probe_vector3 and probe_double3
// (20,000 seeded inputs each, op codes in native/src/native_sim.h). A scalar meets a Vector3 only
// through a cast to real_t at the operator, exactly as for Vector2.
//
//   operation                         C++ source               proving op codes           engine source
//   -------------------------------   ----------------------   ------------------------   ----------------------------
//   Vector3 + Vector3, - Vector3      operator                 OP_V3_ADD, OP_V3_SUB       core/math/vector3.h
//   Vector3 * s                       operator, s cast to      OP_V3_MUL_SCALAR           core/math/vector3.h operator*
//                                     real_t
//   Vector3(x, y, z) from doubles     each cast to real_t      OP_V3_FROM_DOUBLES         GDScript Vector3 construct
//   length_squared, length            mirror                   OP_DBL3_LENGTH_SQUARED,    core/math/vector3.h
//                                                              OP_DBL3_LENGTH
//   distance_to                       mirror                   OP_DBL3_DISTANCE_TO        core/math/vector3.h distance_to
//   normalized                        mirror                   OP_V3_NORMALIZED           core/math/vector3.h normalize
//   cross                             mirror                   OP_V3_CROSS                core/math/vector3.h cross
//   lerp (Vector3)                    mirror                   OP_V3_LERP                 core/math/vector3.h lerp
//
// Scope of the proof: finite inputs, plus infinities and NaN among the double scalars (they stay
// out of the Vector2 and Vector3 inputs, because the engine warns on normalizing a non-finite
// vector and the payload that survives two NaN operands is the compiler's choice, not the
// simulation's). The tests are mutation-checked: a reciprocal multiply in normalized (Vector2 and
// Vector3) and a rounding slack of 0.0002 or 0.00005 in sim_whole_ticks each fail them.
//
// Rules: no std::max, std::min or std::clamp on floats (signed zero and NaN differ from the
// engine's comparison), no transcendental call, no fused multiply-add, no fast math; only + - * /
// and sqrt (tests/unit/test_native_rules_guard.gd scans this file).

#include <cmath>
#include <cstdint>

#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace gd {

using godot::real_t;
using godot::Vector2;
using godot::Vector3;

// core/variant/variant_utility.cpp VariantUtilityFunctions::sqrt -> Math::sqrt (core/math/
// math_funcs.h): the correctly rounded IEEE square root of a double.
inline double sqrt(double x) {
	return std::sqrt(x);
}

// core/variant/variant_utility.cpp VariantUtilityFunctions::absf -> Math::abs (std::abs on double).
inline double absf(double x) {
	return std::abs(x);
}

// core/variant/variant_utility.cpp VariantUtilityFunctions::maxf -> MAX (core/typedefs.h):
// "x > y ? x : y". Equal values, a signed-zero pair and a NaN in either place all answer y.
inline double maxf(double x, double y) {
	return x > y ? x : y;
}

// core/variant/variant_utility.cpp VariantUtilityFunctions::minf -> MIN (core/typedefs.h):
// "x < y ? x : y"; equal values, signed zeros and NaN answer y.
inline double minf(double x, double y) {
	return x < y ? x : y;
}

// core/variant/variant_utility.cpp VariantUtilityFunctions::clampf -> CLAMP (core/typedefs.h):
// "x < min ? min : (x > max ? max : x)".
inline double clampf(double x, double min, double max) {
	return x < min ? min : (x > max ? max : x);
}

// core/variant/variant_utility.cpp VariantUtilityFunctions::maxi -> MAX on int64.
inline int64_t maxi(int64_t x, int64_t y) {
	return x > y ? x : y;
}

// core/variant/variant_utility.cpp VariantUtilityFunctions::mini -> MIN on int64.
inline int64_t mini(int64_t x, int64_t y) {
	return x < y ? x : y;
}

// core/variant/variant_utility.cpp VariantUtilityFunctions::clampi -> CLAMP on int64.
inline int64_t clampi(int64_t x, int64_t min, int64_t max) {
	return x < min ? min : (x > max ? max : x);
}

// Whether `x` converts to int64 without undefined behaviour: [-2^63, 2^63) (a NaN is not).
inline bool fits_int64(double x) {
	return x >= -9223372036854775808.0 && x < 9223372036854775808.0;
}

// The engine converts with a plain C++ cast, which on x86-64 answers INT64_MIN (the "integer
// indefinite" value) for a NaN and for every value outside the int64 range. The cast is undefined
// behaviour in C++ there, so the mirrors answer that value explicitly: the same bytes as the
// engine on this platform, defined everywhere (IN-15).
constexpr int64_t INT64_OUT_OF_RANGE = INT64_MIN;

// core/variant/variant_utility.cpp VariantUtilityFunctions::floori: int64_t(Math::floor(x)).
inline int64_t floori(double x) {
	if (!fits_int64(x)) {
		return INT64_OUT_OF_RANGE;
	}
	return static_cast<int64_t>(std::floor(x));
}

// core/variant/variant_utility.cpp VariantUtilityFunctions::ceili: int64_t(Math::ceil(x)).
inline int64_t ceili(double x) {
	if (!fits_int64(x)) {
		return INT64_OUT_OF_RANGE;
	}
	return static_cast<int64_t>(std::ceil(x));
}

// core/variant/variant_utility.cpp VariantUtilityFunctions::roundi: int64_t(Math::round(x)),
// Math::round being std::round (halves round away from zero).
inline int64_t roundi(double x) {
	if (!fits_int64(x)) {
		return INT64_OUT_OF_RANGE;
	}
	return static_cast<int64_t>(std::round(x));
}

// GDScript int arithmetic wraps on overflow; the port does the same in unsigned arithmetic so a
// pathological coordinate cannot be undefined behaviour and aliases to the same key as before.
inline int64_t wrap_add(int64_t a, int64_t b) {
	return static_cast<int64_t>(static_cast<uint64_t>(a) + static_cast<uint64_t>(b));
}

inline int64_t wrap_mul(int64_t a, int64_t b) {
	return static_cast<int64_t>(static_cast<uint64_t>(a) * static_cast<uint64_t>(b));
}

inline int64_t wrap_neg(int64_t a) {
	return static_cast<int64_t>(static_cast<uint64_t>(0) - static_cast<uint64_t>(a));
}

// core/math/math_funcs.h Math::posmod: the remainder takes the sign of the divisor. A zero divisor
// answers 0 (the engine reports an error and returns 0).
inline int64_t posmod(int64_t x, int64_t y) {
	// A divisor of -1 always leaves 0; answering it here avoids the INT64_MIN % -1 trap.
	if (y == 0 || y == -1) {
		return 0;
	}
	int64_t value = x % y;
	if (((value < 0) && (y > 0)) || ((value > 0) && (y < 0))) {
		value += y;
	}
	return value;
}

// core/math/vector2.cpp Vector2::length_squared: x * x + y * y in real_t.
inline real_t length_squared(const Vector2 &v) {
	return v.x * v.x + v.y * v.y;
}

// core/math/vector2.cpp Vector2::length: Math::sqrt(x * x + y * y) in real_t (the float overload).
inline real_t length(const Vector2 &v) {
	return std::sqrt(v.x * v.x + v.y * v.y);
}

// core/math/vector2.cpp Vector2::distance_squared_to: both differences are formed twice, as there.
inline real_t distance_squared_to(const Vector2 &from, const Vector2 &to) {
	return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y);
}

// core/math/vector2.cpp Vector2::distance_to: Math::sqrt of the expression above, in real_t.
inline real_t distance_to(const Vector2 &from, const Vector2 &to) {
	return std::sqrt((from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y));
}

// core/math/vector2.cpp Vector2::dot.
inline real_t dot(const Vector2 &a, const Vector2 &b) {
	return a.x * b.x + a.y * b.y;
}

// core/math/vector2.cpp Vector2::cross.
inline real_t cross(const Vector2 &a, const Vector2 &b) {
	return a.x * b.y - a.y * b.x;
}

// core/math/vector2.cpp Vector2::is_finite: Math::is_finite on both components.
inline bool is_finite(const Vector2 &v) {
	return std::isfinite(v.x) && std::isfinite(v.y);
}

// core/math/vector2.cpp Vector2::normalize, as normalized() (core/math/vector2.cpp
// Vector2::normalized copies and normalizes): a non-finite vector and a zero vector give (0, 0);
// else both components are divided by the real_t square root of length_squared.
inline Vector2 normalized(const Vector2 &v) {
	Vector2 result = v;
	if (!is_finite(result)) {
		return Vector2(0.0f, 0.0f);
	}
	real_t l = length_squared(result);
	if (l == 0) {
		return Vector2(0.0f, 0.0f);
	}
	l = std::sqrt(l);
	result.x /= l;
	result.y /= l;
	return result;
}

// core/math/math_defs.h CMP_EPSILON.
constexpr double CMP_EPSILON_VALUE = 0.00001;

// core/math/vector2.cpp Vector2::move_toward: the target itself when it is within `delta` or
// within CMP_EPSILON (as real_t); else the step along the unit difference. `delta` is already a
// real_t (GDScript narrows the double at the call).
inline Vector2 move_toward(const Vector2 &from, const Vector2 &to, real_t delta) {
	const Vector2 vd = to - from;
	const real_t len = length(vd);
	if (len <= delta || len < static_cast<real_t>(CMP_EPSILON_VALUE)) {
		return to;
	}
	return from + vd / len * delta;
}

// core/math/vector2.h Vector2::lerp: each component through Math::lerp (core/math/math_funcs.h,
// the float overload): from + (to - from) * weight. `weight` is already a real_t.
inline Vector2 lerp(const Vector2 &from, const Vector2 &to, real_t weight) {
	Vector2 result = from;
	result.x = result.x + (to.x - result.x) * weight;
	result.y = result.y + (to.y - result.y) * weight;
	return result;
}

// --- Vector3 (plan 04-25: the view fills) ---------------------------------------------------------

// core/math/vector3.h Vector3::length_squared: the three squares first, then summed left to right,
// all in real_t.
inline real_t length_squared(const Vector3 &v) {
	real_t x2 = v.x * v.x;
	real_t y2 = v.y * v.y;
	real_t z2 = v.z * v.z;
	return x2 + y2 + z2;
}

// core/math/vector3.h Vector3::length: Math::sqrt (the float overload) of the same sum.
inline real_t length(const Vector3 &v) {
	real_t x2 = v.x * v.x;
	real_t y2 = v.y * v.y;
	real_t z2 = v.z * v.z;
	return std::sqrt(x2 + y2 + z2);
}

// core/math/vector3.h Vector3::distance_to: the length of (to - from).
inline real_t distance_to(const Vector3 &from, const Vector3 &to) {
	return length(to - from);
}

// core/math/vector3.h Vector3::is_finite: Math::is_finite on the three components.
inline bool is_finite(const Vector3 &v) {
	return std::isfinite(v.x) && std::isfinite(v.y) && std::isfinite(v.z);
}

// core/math/vector3.h Vector3::normalize, as normalized() (Vector3::normalized copies and
// normalizes): a non-finite vector and a zero vector give (0, 0, 0); else the three components are
// divided by the real_t square root of length_squared.
inline Vector3 normalized(const Vector3 &v) {
	Vector3 result = v;
	if (!is_finite(result)) {
		return Vector3(0.0f, 0.0f, 0.0f);
	}
	real_t l = length_squared(result);
	if (l == 0) {
		return Vector3(0.0f, 0.0f, 0.0f);
	}
	l = std::sqrt(l);
	result.x /= l;
	result.y /= l;
	result.z /= l;
	return result;
}

// core/math/vector3.h Vector3::cross.
inline Vector3 cross(const Vector3 &a, const Vector3 &b) {
	return Vector3(
			(a.y * b.z) - (a.z * b.y),
			(a.z * b.x) - (a.x * b.z),
			(a.x * b.y) - (a.y * b.x));
}

// core/math/vector3.h Vector3::lerp: each component through Math::lerp (core/math/math_funcs.h,
// the float overload): from + (to - from) * weight. `weight` is already a real_t.
inline Vector3 lerp(const Vector3 &from, const Vector3 &to, real_t weight) {
	Vector3 result = from;
	result.x = result.x + (to.x - result.x) * weight;
	result.y = result.y + (to.y - result.y) * weight;
	result.z = result.z + (to.z - result.z) * weight;
	return result;
}

// --- SimClock (simulation/clock/sim_clock.gd), the double constants as GDScript holds them ------

// SimClock.STEP: the GDScript constant 1.0 / 30.0, a double.
constexpr double SIM_STEP = 1.0 / 30.0;
// SimClock.TICK_ROUNDING_SLACK.
constexpr double SIM_TICK_ROUNDING_SLACK = 0.0001;
// SimClock.MAX_TICKS (1 << 30).
constexpr int64_t SIM_MAX_TICKS = static_cast<int64_t>(1) << 30;

// flow_field.gd INF_COST (the cost of a cell the field never reached; the same 1 << 30 as
// SIM_MAX_TICKS) and STEP_ORTHOGONAL (the field's cost of a step to an orthogonal neighbour, the
// divisor of detour_ticks and of the stuck tracker's progress threshold). Defined once here; the
// classes that name them (NativeField, NativeStuck) alias these.
constexpr int64_t FIELD_INF_COST = static_cast<int64_t>(1) << 30;
constexpr int64_t FIELD_STEP_ORTHOGONAL = 10;

// SimClock._whole_ticks: 0 for NaN, else clampi(ceili(minf(steps, float(MAX_TICKS)) - slack), 1,
// MAX_TICKS).
inline int64_t sim_whole_ticks(double steps) {
	if (std::isnan(steps)) {
		return 0;
	}
	return clampi(
			ceili(minf(steps, static_cast<double>(SIM_MAX_TICKS)) - SIM_TICK_ROUNDING_SLACK),
			1,
			SIM_MAX_TICKS);
}

// SimClock.ticks: 0 unless the duration is above zero (so for zero, negative and NaN), else the
// whole ticks of duration / STEP.
inline int64_t sim_ticks(double duration) {
	if (!(duration > 0.0)) {
		return 0;
	}
	return sim_whole_ticks(duration / SIM_STEP);
}

// SimClock.flight_ticks: 0 unless the speed is above zero, else the whole ticks of
// distance / speed / STEP (left to right, two divisions).
inline int64_t sim_flight_ticks(double distance, double speed) {
	if (!(speed > 0.0)) {
		return 0;
	}
	return sim_whole_ticks(distance / speed / SIM_STEP);
}

} // namespace gd
