#pragma once

#include <cstdint>
#include <utility>
#include <vector>

#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/packed_int64_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/vector2.hpp>

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

// The raw-pointer cores the two entry points above wrap (IN-01), for callers that already hold the
// circles in plain C++ arrays (the native enemy step): `count` circles at `positions`, `radii` and
// `ids` (parallel, ascending id order), one displacement per circle written to `out` (all `count`
// entries are set). The caller owns the sizes; the packed-array entry points check them first.
void separation_displacements_raw(
		const godot::Vector2 *positions,
		const double *radii,
		const int64_t *ids,
		int64_t count,
		godot::Vector2 *out);

// The scratch the bucketed pass fills: kept by the caller so a pass allocates once, not per circle.
struct SeparationScratch {
	std::vector<int64_t> cell_x;
	std::vector<int64_t> cell_y;
	std::vector<std::pair<int64_t, int64_t>> cells;
	std::vector<int64_t> partners;
};

void separation_displacements_bucketed_raw(
		const godot::Vector2 *positions,
		const double *radii,
		const int64_t *ids,
		int64_t count,
		double cell,
		godot::Vector2 *out,
		SeparationScratch &scratch);

} // namespace duskhold
