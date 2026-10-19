#pragma once

#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/packed_int64_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>

namespace duskhold {

// The push-apart pass shared by EnemySystem._separate and UnitSystem.separate (PLAT-01, plan
// 04-15): the C++ counterpart of Separation.displacements and Separation.displacements_bucketed
// (simulation/squads/separation.gd). `positions`, `radii` and `ids` are parallel arrays in ascending
// id order. Both return one displacement per circle, bit for bit what the GDScript routines
// returned. Arrays of different sizes give an all-zero result of positions.size() (exact_port_rules
// 10), never a read past an array.
godot::PackedVector2Array separation_displacements(
		const godot::PackedVector2Array &positions,
		const godot::PackedFloat64Array &radii,
		const godot::PackedInt64Array &ids);

// The same displacements from a grid of `cell` metres instead of every pair: for each circle only
// the circles in the cells around it are visited, in ascending partner order, so every addition
// happens in the order the pairwise pass produces. `cell` decides how many cells are visited, never
// an answer.
godot::PackedVector2Array separation_displacements_bucketed(
		const godot::PackedVector2Array &positions,
		const godot::PackedFloat64Array &radii,
		const godot::PackedInt64Array &ids,
		double cell);

} // namespace duskhold
