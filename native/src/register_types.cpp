#include "register_types.h"

#include <gdextension_interface.h>

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

#include "native_field.h"
#include "native_sim.h"
#include "native_structures.h"
#include "native_wall_decision.h"
#include "native_walls.h"

using namespace godot;

void initialize_duskhold_sim_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	GDREGISTER_CLASS(NativeSim);
	GDREGISTER_CLASS(NativeWalls);
	GDREGISTER_CLASS(NativeGrid);
	GDREGISTER_CLASS(NativeField);
	GDREGISTER_CLASS(NativeRoute);
	GDREGISTER_CLASS(NativeStructures);
	GDREGISTER_CLASS(NativeWallDecision);
}

void uninitialize_duskhold_sim_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
}

extern "C" {
GDExtensionBool GDE_EXPORT duskhold_sim_library_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
	::godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

	init_obj.register_initializer(initialize_duskhold_sim_module);
	init_obj.register_terminator(uninitialize_duskhold_sim_module);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

	return init_obj.init();
}
}
