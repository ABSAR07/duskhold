#pragma once

#include <cstdint>
#include <map>
#include <vector>

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

// The wall solid test in C++ (PLAT-01, plan 04-17): the segment mirror that WallSystem
// (simulation/walls/wall_system.gd) keeps in step with every health change, and the four queries
// that WallSolids (simulation/walls/wall_solids.gd) and WallSystem.segments_near answer from it
// for every caller (enemies, squads, both kings, the nav grid). A line-by-line port of those
// GDScript routines under exact_port_rules 1 to 6 and 10: Vector2 values are real_t (single
// precision), every GDScript float is a double, a scalar meets a Vector2 only through a cast to
// real_t at the operator, candidates are visited in ascending segment index, and nothing is
// reassociated. The tests/unit/test_wall_geometry_pins.gd digests were computed on the GDScript
// before this file existed and this port reproduces them unchanged.
//
// CANDIDATE SETS ARE THE CONTRACT (exact_port_rules 5): push_out's answer depends on exactly which
// segments segments_near visits and in which order, so the 4 m bucket grid is built with the
// inflated-box rule, the floori-in-double cell range, KEY_OFFSET and KEY_STRIDE of the GDScript
// WallSystem._bucket it replaces, and a query walks the same cells and returns the same ascending,
// de-duplicated list. Two things are ported unchanged on purpose because fixing either moves a
// digest: the strict line test without a tangency epsilon (open review item WR-02) and the
// bucket walk that grows with the square of the reach (IN-02).
//
// The bound methods check indices, sizes and finiteness and answer what the GDScript answered for
// bad input: -1, the zero vector, an empty array (exact_port_rules 10). The plain C++ members
// below them take no Godot arrays, so the native enemy step of plan 04-19 can call the mirror
// without crossing the GDScript boundary. One thread only: the queries share a scratch buffer.
class NativeWalls : public RefCounted {
	GDCLASS(NativeWalls, RefCounted)

protected:
	static void _bind_methods();

public:
	// WallSystem._starts, _ends and _half in segment order; the mirror starts with every segment
	// at health 0 (unbuilt), like WallSystem. Arrays of different sizes give an empty mirror.
	void setup(
			const PackedVector2Array &starts,
			const PackedVector2Array &ends,
			const PackedFloat64Array &half);
	// One health write of WallSystem. An index out of range is ignored.
	void set_health(int64_t segment, int64_t health);
	int64_t intact_count() const;
	bool is_intact(int64_t segment) const;
	// WallSystem.segments_near: the segments whose inflated box touches a cell the circle's square
	// touches, ascending, standing or not.
	PackedInt32Array segments_near(const Vector2 &pos, double reach) const;
	// WallSolids.first_blocking.
	int64_t first_blocking(const Vector2 &from, const Vector2 &to, double radius) const;
	// WallSolids.push_out.
	Vector2 push_out(const Vector2 &pos, double radius) const;
	// WallSolids.closest_point.
	Vector2 closest_point(int64_t segment, const Vector2 &pos) const;

	// --- plain C++ for native callers (no Godot arrays) ------------------------------------------
	// The same four answers; near_segments fills `out` (cleared first) instead of allocating.
	void near_segments(const Vector2 &pos, double reach, std::vector<int32_t> &out) const;
	int64_t blocking_segment(const Vector2 &from, const Vector2 &to, double radius) const;
	Vector2 pushed_position(const Vector2 &pos, double radius) const;
	Vector2 closest_on_segment(int64_t segment, const Vector2 &pos) const;
	int64_t segment_count() const;

private:
	bool valid(int64_t segment) const;
	Vector2 pushed_from(int64_t segment, const Vector2 &pos, double radius) const;

	std::vector<Vector2> starts_;
	std::vector<Vector2> ends_;
	std::vector<double> half_;
	std::vector<int64_t> health_;
	int64_t intact_ = 0;
	// Bucket key (WallSystem._key) -> the segments whose inflated box touches the cell, ascending.
	std::map<int64_t, std::vector<int32_t>> buckets_;
	// The occupied cell range, used only to bound a query whose cell range is absurd.
	int64_t min_cell_x_ = 0;
	int64_t max_cell_x_ = 0;
	int64_t min_cell_y_ = 0;
	int64_t max_cell_y_ = 0;
	mutable std::vector<int32_t> scratch_;
};

} // namespace godot
