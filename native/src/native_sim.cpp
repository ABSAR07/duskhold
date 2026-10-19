#include "native_sim.h"

#include <godot_cpp/core/class_db.hpp>

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
