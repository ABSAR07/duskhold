#include "native_sim.h"

#include <godot_cpp/core/class_db.hpp>

#include "gd_math.h"
#include "native_separation.h"
#include "native_wall_decision.h"

#ifndef DUSKHOLD_GODOT_CPP_PIN
#error "DUSKHOLD_GODOT_CPP_PIN must be defined by native/CMakeLists.txt"
#endif
#ifndef DUSKHOLD_API_VERSION
#error "DUSKHOLD_API_VERSION must be defined by native/CMakeLists.txt"
#endif

using namespace godot;

void NativeSim::_bind_methods() {
	ClassDB::bind_static_method("NativeSim", D_METHOD("version"), &NativeSim::version);
	ClassDB::bind_static_method("NativeSim", D_METHOD("godot_cpp_pin"), &NativeSim::godot_cpp_pin);
	ClassDB::bind_static_method("NativeSim", D_METHOD("api_version"), &NativeSim::api_version);
	ClassDB::bind_static_method("NativeSim", D_METHOD("real_t_bytes"), &NativeSim::real_t_bytes);
	ClassDB::bind_static_method(
			"NativeSim",
			D_METHOD("separation_displacements", "positions", "radii", "ids"),
			&NativeSim::separation_displacements);
	ClassDB::bind_static_method(
			"NativeSim",
			D_METHOD("separation_displacements_bucketed", "positions", "radii", "ids", "cell"),
			&NativeSim::separation_displacements_bucketed);

	ClassDB::bind_static_method(
			"NativeSim",
			D_METHOD("probe_vector", "op", "a", "b", "s"),
			&NativeSim::probe_vector);
	ClassDB::bind_static_method(
			"NativeSim",
			D_METHOD("probe_double", "op", "a", "b", "x", "y"),
			&NativeSim::probe_double);
	ClassDB::bind_static_method(
			"NativeSim",
			D_METHOD("probe_int", "op", "x", "y", "m", "n", "k"),
			&NativeSim::probe_int);
	ClassDB::bind_static_method(
			"NativeSim",
			D_METHOD("probe_rules", "op", "a", "b", "c", "d"),
			&NativeSim::probe_rules);

	BIND_CONSTANT(OP_VEC_ADD);
	BIND_CONSTANT(OP_VEC_SUB);
	BIND_CONSTANT(OP_VEC_MUL_SCALAR);
	BIND_CONSTANT(OP_VEC_SCALAR_MUL);
	BIND_CONSTANT(OP_VEC_DIV_SCALAR);
	BIND_CONSTANT(OP_VEC_FROM_DOUBLES);
	BIND_CONSTANT(OP_VEC_NORMALIZED);
	BIND_CONSTANT(OP_VEC_MOVE_TOWARD);
	BIND_CONSTANT(OP_VEC_LERP);
	BIND_CONSTANT(OP_VEC_NORMALIZED_CPP);
	BIND_CONSTANT(OP_VEC_MOVE_TOWARD_CPP);
	BIND_CONSTANT(OP_VEC_LERP_CPP);

	BIND_CONSTANT(OP_DBL_LENGTH);
	BIND_CONSTANT(OP_DBL_LENGTH_SQUARED);
	BIND_CONSTANT(OP_DBL_DISTANCE_TO);
	BIND_CONSTANT(OP_DBL_DISTANCE_SQUARED_TO);
	BIND_CONSTANT(OP_DBL_DOT);
	BIND_CONSTANT(OP_DBL_CROSS);
	BIND_CONSTANT(OP_DBL_MAXF);
	BIND_CONSTANT(OP_DBL_MINF);
	BIND_CONSTANT(OP_DBL_CLAMPF);
	BIND_CONSTANT(OP_DBL_ABSF);
	BIND_CONSTANT(OP_DBL_SQRT);
	BIND_CONSTANT(OP_DBL_LENGTH_CPP);
	BIND_CONSTANT(OP_DBL_LENGTH_SQUARED_CPP);
	BIND_CONSTANT(OP_DBL_DISTANCE_TO_CPP);
	BIND_CONSTANT(OP_DBL_DISTANCE_SQUARED_TO_CPP);
	BIND_CONSTANT(OP_DBL_DOT_CPP);
	BIND_CONSTANT(OP_DBL_CROSS_CPP);

	BIND_CONSTANT(OP_INT_FLOORI);
	BIND_CONSTANT(OP_INT_CEILI);
	BIND_CONSTANT(OP_INT_ROUNDI);
	BIND_CONSTANT(OP_INT_POSMOD);
	BIND_CONSTANT(OP_INT_MINI);
	BIND_CONSTANT(OP_INT_MAXI);
	BIND_CONSTANT(OP_INT_CLAMPI);
	BIND_CONSTANT(OP_INT_TICKS);
	BIND_CONSTANT(OP_INT_FLIGHT_TICKS);

	BIND_CONSTANT(OP_RULE_DAMAGE_PER_300);
	BIND_CONSTANT(OP_RULE_TTD_TICKS);
	BIND_CONSTANT(OP_RULE_WALK_TICKS);
	BIND_CONSTANT(OP_RULE_SHOULD_BREAK);
	BIND_CONSTANT(OP_RULE_KEEP_BREAKING);
}

String NativeSim::version() {
	return String("duskhold-native-0.1");
}

String NativeSim::godot_cpp_pin() {
	return String(DUSKHOLD_GODOT_CPP_PIN);
}

String NativeSim::api_version() {
	return String(DUSKHOLD_API_VERSION);
}

int64_t NativeSim::real_t_bytes() {
	return static_cast<int64_t>(sizeof(real_t));
}

PackedVector2Array NativeSim::separation_displacements(
		const PackedVector2Array &positions,
		const PackedFloat64Array &radii,
		const PackedInt64Array &ids) {
	return duskhold::separation_displacements(positions, radii, ids);
}

PackedVector2Array NativeSim::separation_displacements_bucketed(
		const PackedVector2Array &positions,
		const PackedFloat64Array &radii,
		const PackedInt64Array &ids,
		double cell) {
	return duskhold::separation_displacements_bucketed(positions, radii, ids, cell);
}

// --- math probes (see the table in native_sim.h) ------------------------------------------------

PackedVector2Array NativeSim::probe_vector(
		int64_t op,
		const PackedVector2Array &a,
		const PackedVector2Array &b,
		const PackedFloat64Array &s) {
	PackedVector2Array result;
	const int64_t count = a.size();
	const int64_t scalars_needed = (op == OP_VEC_FROM_DOUBLES) ? 2 * count : count;
	if (b.size() != count || s.size() != scalars_needed) {
		return result;
	}
	result.resize(count);
	Vector2 *out = result.ptrw();
	const Vector2 *pa = a.ptr();
	const Vector2 *pb = b.ptr();
	const double *ps = s.ptr();
	for (int64_t i = 0; i < count; i++) {
		switch (op) {
			case OP_VEC_ADD:
				out[i] = pa[i] + pb[i];
				break;
			case OP_VEC_SUB:
				out[i] = pa[i] - pb[i];
				break;
			case OP_VEC_MUL_SCALAR:
				out[i] = pa[i] * static_cast<real_t>(ps[i]);
				break;
			case OP_VEC_SCALAR_MUL:
				out[i] = static_cast<real_t>(ps[i]) * pa[i];
				break;
			case OP_VEC_DIV_SCALAR:
				out[i] = pa[i] / static_cast<real_t>(ps[i]);
				break;
			case OP_VEC_FROM_DOUBLES:
				out[i] = Vector2(static_cast<real_t>(ps[2 * i]), static_cast<real_t>(ps[2 * i + 1]));
				break;
			case OP_VEC_NORMALIZED:
				out[i] = gd::normalized(pa[i]);
				break;
			case OP_VEC_MOVE_TOWARD:
				out[i] = gd::move_toward(pa[i], pb[i], static_cast<real_t>(ps[i]));
				break;
			case OP_VEC_LERP:
				out[i] = gd::lerp(pa[i], pb[i], static_cast<real_t>(ps[i]));
				break;
			case OP_VEC_NORMALIZED_CPP:
				out[i] = pa[i].normalized();
				break;
			case OP_VEC_MOVE_TOWARD_CPP:
				out[i] = pa[i].move_toward(pb[i], static_cast<real_t>(ps[i]));
				break;
			case OP_VEC_LERP_CPP:
				out[i] = pa[i].lerp(pb[i], static_cast<real_t>(ps[i]));
				break;
			default:
				return PackedVector2Array();
		}
	}
	return result;
}

PackedFloat64Array NativeSim::probe_double(
		int64_t op,
		const PackedVector2Array &a,
		const PackedVector2Array &b,
		const PackedFloat64Array &x,
		const PackedFloat64Array &y) {
	PackedFloat64Array result;
	const int64_t count = x.size();
	if (a.size() != count || b.size() != count || y.size() != count) {
		return result;
	}
	result.resize(count);
	double *out = result.ptrw();
	const Vector2 *pa = a.ptr();
	const Vector2 *pb = b.ptr();
	const double *px = x.ptr();
	const double *py = y.ptr();
	for (int64_t i = 0; i < count; i++) {
		switch (op) {
			case OP_DBL_LENGTH:
				out[i] = static_cast<double>(gd::length(pa[i]));
				break;
			case OP_DBL_LENGTH_SQUARED:
				out[i] = static_cast<double>(gd::length_squared(pa[i]));
				break;
			case OP_DBL_DISTANCE_TO:
				out[i] = static_cast<double>(gd::distance_to(pa[i], pb[i]));
				break;
			case OP_DBL_DISTANCE_SQUARED_TO:
				out[i] = static_cast<double>(gd::distance_squared_to(pa[i], pb[i]));
				break;
			case OP_DBL_DOT:
				out[i] = static_cast<double>(gd::dot(pa[i], pb[i]));
				break;
			case OP_DBL_CROSS:
				out[i] = static_cast<double>(gd::cross(pa[i], pb[i]));
				break;
			case OP_DBL_MAXF:
				out[i] = gd::maxf(px[i], py[i]);
				break;
			case OP_DBL_MINF:
				out[i] = gd::minf(px[i], py[i]);
				break;
			case OP_DBL_CLAMPF:
				out[i] = gd::clampf(px[i], py[i], static_cast<double>(pb[i].x));
				break;
			case OP_DBL_ABSF:
				out[i] = gd::absf(px[i]);
				break;
			case OP_DBL_SQRT:
				out[i] = gd::sqrt(px[i]);
				break;
			case OP_DBL_LENGTH_CPP:
				out[i] = static_cast<double>(pa[i].length());
				break;
			case OP_DBL_LENGTH_SQUARED_CPP:
				out[i] = static_cast<double>(pa[i].length_squared());
				break;
			case OP_DBL_DISTANCE_TO_CPP:
				out[i] = static_cast<double>(pa[i].distance_to(pb[i]));
				break;
			case OP_DBL_DISTANCE_SQUARED_TO_CPP:
				out[i] = static_cast<double>(pa[i].distance_squared_to(pb[i]));
				break;
			case OP_DBL_DOT_CPP:
				out[i] = static_cast<double>(pa[i].dot(pb[i]));
				break;
			case OP_DBL_CROSS_CPP:
				out[i] = static_cast<double>(pa[i].cross(pb[i]));
				break;
			default:
				return PackedFloat64Array();
		}
	}
	return result;
}

PackedInt64Array NativeSim::probe_int(
		int64_t op,
		const PackedFloat64Array &x,
		const PackedFloat64Array &y,
		const PackedInt64Array &m,
		const PackedInt64Array &n,
		const PackedInt64Array &k) {
	PackedInt64Array result;
	const int64_t count = x.size();
	if (y.size() != count || m.size() != count || n.size() != count || k.size() != count) {
		return result;
	}
	result.resize(count);
	int64_t *out = result.ptrw();
	const double *px = x.ptr();
	const double *py = y.ptr();
	const int64_t *pm = m.ptr();
	const int64_t *pn = n.ptr();
	const int64_t *pk = k.ptr();
	for (int64_t i = 0; i < count; i++) {
		switch (op) {
			case OP_INT_FLOORI:
				out[i] = gd::floori(px[i]);
				break;
			case OP_INT_CEILI:
				out[i] = gd::ceili(px[i]);
				break;
			case OP_INT_ROUNDI:
				out[i] = gd::roundi(px[i]);
				break;
			case OP_INT_POSMOD:
				out[i] = gd::posmod(pm[i], pn[i]);
				break;
			case OP_INT_MINI:
				out[i] = gd::mini(pm[i], pn[i]);
				break;
			case OP_INT_MAXI:
				out[i] = gd::maxi(pm[i], pn[i]);
				break;
			case OP_INT_CLAMPI:
				out[i] = gd::clampi(pm[i], pn[i], pk[i]);
				break;
			case OP_INT_TICKS:
				out[i] = gd::sim_ticks(px[i]);
				break;
			case OP_INT_FLIGHT_TICKS:
				out[i] = gd::sim_flight_ticks(px[i], py[i]);
				break;
			default:
				return PackedInt64Array();
		}
	}
	return result;
}

PackedInt64Array NativeSim::probe_rules(
		int64_t op,
		const PackedInt64Array &a,
		const PackedInt64Array &b,
		const PackedInt64Array &c,
		const PackedInt64Array &d) {
	PackedInt64Array result;
	const int64_t count = a.size();
	if (b.size() != count || c.size() != count || d.size() != count) {
		return result;
	}
	result.resize(count);
	int64_t *out = result.ptrw();
	const int64_t *pa = a.ptr();
	const int64_t *pb = b.ptr();
	const int64_t *pc = c.ptr();
	const int64_t *pd = d.ptr();
	for (int64_t i = 0; i < count; i++) {
		switch (op) {
			case OP_RULE_DAMAGE_PER_300:
				out[i] = NativeWallDecision::damage_per_300(pa[i], pb[i]);
				break;
			case OP_RULE_TTD_TICKS:
				out[i] = NativeWallDecision::ttd_ticks(pa[i], pb[i]);
				break;
			case OP_RULE_WALK_TICKS:
				out[i] = NativeWallDecision::walk_ticks(pa[i], pb[i]);
				break;
			case OP_RULE_SHOULD_BREAK:
				out[i] = NativeWallDecision::should_break(pa[i], pb[i], pc[i]) ? 1 : 0;
				break;
			case OP_RULE_KEEP_BREAKING:
				out[i] = NativeWallDecision::keep_breaking(pa[i], pb[i], pc[i], pd[i]) ? 1 : 0;
				break;
			default:
				return PackedInt64Array();
		}
	}
	return result;
}
