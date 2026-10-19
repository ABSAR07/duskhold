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
// GDScript API of Separation (simulation/squads/separation.gd); the rest of the enemy and wall step
// follows in later plans of phase 04.
class NativeSim : public RefCounted {
	GDCLASS(NativeSim, RefCounted)

protected:
	static void _bind_methods();

public:
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
};

} // namespace godot
