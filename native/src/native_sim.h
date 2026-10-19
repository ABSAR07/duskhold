#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

// The native side of the simulation. This plan only proves the library loads and reports what it
// was built from; the enemy and wall step arrives in later plans of phase 04.
class NativeSim : public RefCounted {
	GDCLASS(NativeSim, RefCounted)

protected:
	static void _bind_methods();

public:
	static String version();
	static String godot_cpp_pin();
	static String api_version();
	static int64_t real_t_bytes();
};

} // namespace godot
