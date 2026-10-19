#pragma once

// Bit-exact mirrors of the GDScript utilities and Vector2 operations the native simulation port
// uses (PLAT-01, exact_port_rules 1 to 3, plan 04-15). Every mirror copies the definition in
// Godot 4.7.2-stable (tag 4.7.2-stable of github.com/godotengine/godot) and names its source in a
// comment, so a port reads like the GDScript it replaces.
//
// OPERATION TABLE. Per operation: how the port gets it and the engine source it was checked
// against. Later plans call only what this table allows. "mirror" = a function below; "godot-cpp"
// = the godot-cpp method or operator, proven equal to the engine on 20,000 seeded inputs per
// operation by tests/unit/test_native_math_contract.gd (the op-codes are the table at the top of
// native/src/native_sim.h). The scalar rows follow GDScript's own widths: a GDScript float is a
// double, a Vector2 holds single-precision floats, and a scalar meets a Vector2 only through a
// cast to real_t at the operator.
//
//   operation                                   how        engine source checked against
//   ------------------------------------------  ---------  -------------------------------------
//   Vector2 + - (Vector2)                       godot-cpp  core/math/vector2.h operator+, operator-
//   Vector2 * s, s * Vector2, Vector2 / s       godot-cpp  core/math/vector2.h operator*, operator/
//                                                          (s is cast to real_t at the operator)
//   Vector2(x, y) from doubles                  cast       core/variant/variant_construct.h (the
//                                                          doubles narrow to real_t)
//   length_squared, length                      mirror     core/math/vector2.cpp length_squared,
//                                                          length
//   distance_to, distance_squared_to            mirror     core/math/vector2.cpp distance_to,
//                                                          distance_squared_to
//   dot, cross                                  mirror     core/math/vector2.h dot, cross
//   normalized                                  mirror     core/math/vector2.cpp normalize
//   move_toward (Vector2)                       mirror     core/math/vector2.cpp move_toward
//   lerp (Vector2)                              mirror     core/math/vector2.h lerp (Math::lerp)
//   sqrt                                        mirror     core/variant/variant_utility.cpp sqrt
//   maxf, minf, clampf                          mirror     core/variant/variant_utility.cpp maxf,
//                                                          minf, clampf (core/typedefs.h MAX, MIN,
//                                                          CLAMP: the comparison picks, never an
//                                                          NaN-propagating or sign-aware std call)
//   absf                                        mirror     core/variant/variant_utility.cpp absf
//   floori, ceili, roundi                       mirror     core/variant/variant_utility.cpp floori,
//                                                          ceili, roundi (Math::floor/ceil/round)
//   maxi, mini, clampi                          mirror     core/variant/variant_utility.cpp
//   posmod (int)                                mirror     core/math/math_funcs.h posmod
//   SimClock.ticks, SimClock.flight_ticks       mirror     simulation/clock/sim_clock.gd
//
// Rules: no std::max, std::min or std::clamp on floats (signed zero and NaN differ from the
// engine's comparison), no transcendental call, no fused multiply-add, no fast math; only + - * /
// and sqrt (tests/unit/test_native_rules_guard.gd scans this file).

#include <cmath>
#include <cstdint>

#include <godot_cpp/variant/vector2.hpp>

namespace gd {

using godot::real_t;
using godot::Vector2;

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

// core/variant/variant_utility.cpp VariantUtilityFunctions::floori: int64_t(Math::floor(x)).
// Like the engine, an argument outside the int64 range (or a NaN) is converted by the hardware.
inline int64_t floori(double x) {
	return static_cast<int64_t>(std::floor(x));
}

// core/variant/variant_utility.cpp VariantUtilityFunctions::ceili: int64_t(Math::ceil(x)).
inline int64_t ceili(double x) {
	return static_cast<int64_t>(std::ceil(x));
}

// core/variant/variant_utility.cpp VariantUtilityFunctions::roundi: int64_t(Math::round(x)),
// Math::round being std::round (halves round away from zero).
inline int64_t roundi(double x) {
	return static_cast<int64_t>(std::round(x));
}

// core/math/math_funcs.h Math::posmod: the remainder takes the sign of the divisor. A zero divisor
// answers 0 (the engine reports an error and returns 0).
inline int64_t posmod(int64_t x, int64_t y) {
	if (y == 0) {
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

} // namespace gd
