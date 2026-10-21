#pragma once

#include <cstdint>
#include <vector>

#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/vector2.hpp>

#include "gd_math.h"
#include "native_walls.h"

namespace godot {

// The flow-field reads in C++ (PLAT-01, plan 04-18): a mirror of the nav grid that NavGrid
// (simulation/nav/nav_grid.gd) refreshes at the end of every rebuild, and the reads of a cost field
// over it (simulation/nav/flow_field.gd: cost_at, is_reached and the lazily cached, bilinearly
// blended direction_at). FlowField.build (Dial's algorithm, the wall-break rebuild hitch the owner
// accepted) stays GDScript and hands its finished costs over. A line-by-line port under
// exact_port_rules 1 to 6 and 10: Vector2 values are real_t (single precision), every GDScript float
// is a double, a scalar meets a Vector2 only through a cast to real_t at the operator, directions
// are stored as float exactly as the PackedFloat32Array they replace stored them, and nothing is
// reassociated. tests/unit/test_field_route_pins.gd was computed on the GDScript before this file
// existed and this port reproduces it unchanged.
//
// THE LAZY DIRECTION CACHE IS PART OF THE CONTRACT. A cell's direction is computed from the LIVE
// grid's blocked mask the first time the cell is asked and is then kept until the field's
// generation changes (set_costs, i.e. a rebuild of the field). It is not recomputed on every read
// and not precomputed at build time: after a wall breaks and the grid is rebuilt but the field is
// not, a cell asked for the first time reads the new mask while a cell asked before keeps its old
// direction, and the pins' stale state holds the port to exactly that.
//
// The bound methods check indices, sizes and finiteness and answer what the GDScript answered for
// bad input: -1 for no cell, INF_COST, the zero vector, false (exact_port_rules 10). They are also
// the plain C++ members the native enemy step of plan 04-19 calls (no Godot arrays in them except
// the two setters). One thread only: the direction cache is filled by the const readers.

// The nav grid's layout and masks, as NavGrid holds them.
class NativeGrid : public RefCounted {
	GDCLASS(NativeGrid, RefCounted)

protected:
	static void _bind_methods();

public:
	// NavGrid._armed, _origin, _cell, _width and _height. A layout that cannot size a grid (a
	// non-positive width or height, an armed flag with no cells, a cell that is not a positive
	// finite number, or more cells than a 32-bit count holds) leaves the grid unarmed.
	void set_layout(bool armed, const Vector2 &origin, double cell, int64_t width, int64_t height);
	// NavGrid._blocked and _owner after a rebuild; marks the grid ready (NavGrid.is_ready is
	// armed and rebuilt at least once). Arrays whose size is not width * height are refused: the
	// grid stays as it was (not ready the first time).
	void set_masks(const PackedByteArray &blocked, const PackedInt32Array &owner);

	bool is_armed() const;
	bool is_ready() const;
	int64_t width() const;
	int64_t height() const;
	double cell_size() const;
	Vector2 origin() const;
	// NavGrid.cell_of: the cell holding `pos`, -1 outside the grid or when unarmed.
	int64_t cell_of(const Vector2 &pos) const;
	// NavGrid.is_blocked: true for a blocked cell, a border cell and an index outside the masks.
	bool is_blocked(int64_t cell) const;
	// NavGrid.is_border: the always-blocked outer ring.
	bool is_border(int64_t cell) const;
	// NavGrid.owner_of: the wall segment that blocked the cell; -1 for an open cell, the border and
	// an index outside the masks.
	int64_t owner_of(int64_t cell) const;

private:
	bool armed_ = false;
	bool ready_ = false;
	Vector2 origin_ = Vector2(0.0f, 0.0f);
	double cell_ = 2.0;
	int64_t width_ = 0;
	int64_t height_ = 0;
	std::vector<uint8_t> blocked_;
	std::vector<int32_t> owner_;
};

// One cost field's reads (FlowField._cost and the direction cache).
class NativeField : public RefCounted {
	GDCLASS(NativeField, RefCounted)

protected:
	static void _bind_methods();

public:
	// flow_field.gd INF_COST, STEP_ORTHOGONAL, STEP_DIAGONAL, WALL_PENALTY and
	// MIN_DIRECTION_LENGTH: the algorithm constants live here now, not in the GDScript.
	static constexpr int64_t INF_COST = gd::FIELD_INF_COST;

	// FlowField.build's hand-over: the finished costs and the live grid they were built over.
	// Starts a new generation, so every cell's direction is computed again on its next read.
	void set_costs(const PackedInt32Array &costs, const Ref<NativeGrid> &grid);

	// FlowField.cost_at.
	int64_t cost_at(const Vector2 &pos) const;
	// FlowField.is_reached.
	bool is_reached(const Vector2 &pos) const;
	// FlowField.direction_at.
	Vector2 direction_at(const Vector2 &pos) const;

private:
	int64_t cost_of(int64_t cell) const;
	Vector2 cell_direction(int64_t cell_x, int64_t cell_y) const;
	void compute_direction(int64_t cell) const;
	void point_at_cheapest(int64_t cell) const;

	Ref<NativeGrid> grid_;
	std::vector<int32_t> cost_;
	int64_t offsets_[8] = { 0, 0, 0, 0, 0, 0, 0, 0 };
	mutable std::vector<float> dir_x_;
	mutable std::vector<float> dir_y_;
	mutable std::vector<int32_t> stamp_;
	int64_t generation_ = 0;
};

// The castle routing of Pathing (simulation/nav/pathing.gd): is_sealed with its probe off a blocking
// wall, castle_cost_at, castle_distance_cm, detour_ticks, straight_ticks and march_step, answered
// from the grid mirror, the castle field and the wall mirror. Pathing keeps one of these updated in
// refresh() and its routing methods delegate, so the 20 public methods of Pathing stay what they
// were. A line-by-line port under the same rules; WR-03 (an enemy outside the grid counts as sealed)
// lives in is_sealed and is ported unchanged on purpose, fixing it would move a digest.
class NativeRoute : public RefCounted {
	GDCLASS(NativeRoute, RefCounted)

protected:
	static void _bind_methods();

public:
	// pathing.gd _init: the grid mirror, the wall mirror (null when the facade has no walls), the
	// castle's ground position and NavTuning.cell_size.
	void set_world(
			const Ref<NativeGrid> &grid,
			const Ref<NativeWalls> &walls,
			const Vector2 &castle,
			double tuning_cell_size);
	// pathing.gd refresh(): the castle field once it exists (null while it does not).
	void set_castle_field(const Ref<NativeField> &field);

	// Pathing.is_sealed.
	bool is_sealed(const Vector2 &pos) const;
	// Pathing.castle_cost_at.
	int64_t castle_cost_at(const Vector2 &pos) const;
	// Pathing.castle_distance_cm.
	int64_t castle_distance_cm(const Vector2 &pos) const;
	// Pathing.detour_ticks.
	int64_t detour_ticks(const Vector2 &pos, int64_t speed_cm_per_s) const;
	// Pathing.straight_ticks.
	int64_t straight_ticks(const Vector2 &pos, int64_t speed_cm_per_s) const;
	// Pathing.march_step.
	Vector2 march_step(const Vector2 &pos, double max_distance) const;
	// Pathing._probe_of.
	Vector2 probe_of(const Vector2 &pos) const;
	// Pathing.has_intact_walls.
	bool has_intact_walls() const;

private:
	Ref<NativeGrid> grid_;
	Ref<NativeWalls> walls_;
	Ref<NativeField> field_;
	Vector2 castle_ = Vector2(0.0f, 0.0f);
	double tuning_cell_size_ = 2.0;
};

} // namespace godot
