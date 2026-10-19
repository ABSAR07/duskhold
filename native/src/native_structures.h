#pragma once

#include <cstdint>
#include <map>
#include <vector>

#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_int64_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3i.hpp>

#include "native_walls.h"

namespace godot {

// The structure index in C++ (PLAT-01, plan 04-23): the nearest-structure question of a target-less
// enemy, answered from a uniform grid over a snapshot that StructureIndex
// (simulation/night/structure_index.gd) gathers once per enemy step and hands over. A line-by-line
// port of that GDScript under exact_port_rules 1 to 6 and 10: every GDScript float is a double, a
// distance is the real_t distance_to widened to double and then reduced by the double radius, and
// the candidates are visited in ascending index with the same strict test. The pins of
// tests/unit/test_structure_decision_pins.gd were computed on the GDScript before this file existed
// and this port reproduces them unchanged.
//
// CANDIDATE ORDER IS THE CONTRACT (exact_port_rules 5). rebuild takes the snapshot in the order
// StructureIndex.rebuild gathers it: living units by ascending id, then standing buildings in
// standing_spot_ids order, then the castle, which is always the last candidate. The scan takes
// `edge <= aggro_range and edge < best_edge`, so a tie goes to the earlier candidate, and the wall
// line test is paid only by a candidate that would improve the best (nearest_visible), while
// nearest_through_walls skips the castle (plan 04-12). The 12 m grid only decides which candidates
// are worth testing; a query whose block of cells would be larger than the grid itself tests every
// candidate instead, which is the unfiltered scan the grid replaces (a superset over an exact test).
//
// The bound methods check sizes and answer what the GDScript answered for bad input: no candidate
// (the zero vector) and the zero vector or 0.0 for an unknown id or index (exact_port_rules 10). The
// plain C++ members below take no Godot arrays, so the native enemy step of plan 04-19 reads the
// snapshot (unit positions and radii by id, building centres and radii by spot index, the standing
// membership) without crossing the GDScript boundary. One thread only: queries share a scratch
// buffer.
class NativeStructures : public RefCounted {
	GDCLASS(NativeStructures, RefCounted)

protected:
	static void _bind_methods();

public:
	// structure_index.gd KIND_UNIT, KIND_BUILDING and KIND_CASTLE.
	static constexpr int32_t KIND_UNIT = 0;
	static constexpr int32_t KIND_BUILDING = 1;
	static constexpr int32_t KIND_CASTLE = 2;

	// StructureIndex.rebuild's hand-over. A group whose arrays differ in size holds no candidates.
	void rebuild(
			const PackedInt64Array &unit_ids,
			const PackedVector2Array &unit_positions,
			const PackedFloat64Array &unit_radii,
			const PackedInt32Array &building_indices,
			const PackedVector2Array &building_centres,
			const PackedFloat64Array &building_radii,
			const Vector2 &castle_position,
			double castle_radius);

	// StructureIndex.nearest, nearest_visible (the wall mirror may be null: nothing is in the way)
	// and nearest_through_walls; Vector3i(kind, id, 1), the zero vector when nothing is in range.
	Vector3i nearest(const Vector2 &pos, double aggro_range) const;
	Vector3i nearest_visible(
			const Vector2 &pos,
			double aggro_range,
			const Ref<NativeWalls> &walls,
			double radius,
			double ranged_reach) const;
	Vector3i nearest_through_walls(const Vector2 &pos, double aggro_range) const;

	// The snapshot, by id or index; the zero vector and 0.0 for an unknown one.
	Vector2 unit_position(int64_t id) const;
	double unit_radius(int64_t id) const;
	bool has_unit(int64_t id) const;
	Vector2 building_centre(int64_t spot_index) const;
	double building_radius(int64_t spot_index) const;
	// True when the spot index is in the standing snapshot of the last rebuild.
	bool is_standing(int64_t spot_index) const;
	// How many candidates the snapshot holds (units, standing buildings and the castle).
	int64_t candidate_count() const;

	// --- plain C++ for native callers ---------------------------------------------------------
	// The same three queries with a raw wall mirror (null: no wall in the way).
	Vector3i scan_nearest(const Vector2 &pos, double aggro_range) const;
	Vector3i scan_visible(
			const Vector2 &pos,
			double aggro_range,
			const NativeWalls *walls,
			double radius,
			double ranged_reach) const;
	Vector3i scan_through_walls(const Vector2 &pos, double aggro_range) const;

private:
	// structure_index.gd CELL, REACH_MARGIN, KEY_OFFSET and KEY_STRIDE.
	static constexpr double CELL = 12.0;
	static constexpr double REACH_MARGIN = 0.01;
	static constexpr int64_t KEY_OFFSET = static_cast<int64_t>(1) << 19;
	static constexpr int64_t KEY_STRIDE = static_cast<int64_t>(1) << 20;

	void insert(const Vector2 &centre, double radius, int32_t kind, int32_t id);
	Vector3i scan(
			const Vector2 &pos,
			double aggro_range,
			const NativeWalls *walls,
			bool filter,
			double radius,
			double ranged_reach,
			bool skip_castle) const;
	void gather(const Vector2 &pos, double aggro_range) const;
	// structure_index.gd _seen.
	bool seen(
			const Vector2 &pos,
			size_t index,
			double edge,
			const NativeWalls *walls,
			double radius,
			double ranged_reach) const;
	int64_t find_unit(int64_t id) const;
	int64_t find_building(int64_t spot_index) const;

	std::vector<Vector2> centres_;
	std::vector<double> radii_;
	std::vector<int32_t> kinds_;
	std::vector<int32_t> ids_;
	double largest_radius_ = 0.0;
	// Cell key -> candidate indices, ascending (insertion order is the shipped order).
	std::map<int64_t, std::vector<int32_t>> cells_;
	// Units are candidates [0, unit_count_), the standing buildings follow, the castle is last.
	size_t unit_count_ = 0;
	std::vector<int64_t> unit_ids_;
	std::vector<int32_t> building_indices_;
	bool units_sorted_ = true;
	bool buildings_sorted_ = true;
	mutable std::vector<int32_t> scratch_;
};

} // namespace godot
