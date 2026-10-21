#pragma once

#include <cstdint>
#include <map>
#include <vector>

#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_int64_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/vector2.hpp>

#include "gd_math.h"
#include "native_field.h"

namespace godot {

// The stuck tracker in C++ (PLAT-01, plan 04-20): which enemies have stopped getting anywhere
// (ENMY-04, D-09). A line-by-line port of StuckTracker (simulation/nav/stuck_tracker.gd) under
// exact_port_rules 1 to 6 and 10: an enemy with no target whose progress toward the castle has not
// improved by stuck_progress_m for stuck_seconds is flagged; one with a target resets; progress is
// the castle field's cost at the enemy's cell where the field reaches it, else the straight
// distance in whole centimetres, and a change of unit restarts the enemy's watermark. The entries
// live in an ordered map by enemy id and the enemies are visited in ascending id (the order of
// the read view), as the GDScript visited enemies.ids().
//
// STRICTLY READ-ONLY (RESEARCH Pitfall 10, T-04-54): update reads the arrays it is handed (the
// enemy read view's ids, targeted and living flags and current positions, and the castle field)
// and keeps its own state. It holds no pointer to the enemy store, emits nothing and writes
// nothing into any enemy, so the replay digests cannot depend on it. tests/unit/test_stuck_pins.gd
// was computed on the GDScript tracker before this file existed and this port reproduces it.
//
// The bound methods check sizes and answer what the GDScript answered for bad input: arrays of
// different sizes are an update with no enemies, an unknown id is not stuck and has streak 0
// (exact_port_rules 10). One thread only.
class NativeStuck : public RefCounted {
	GDCLASS(NativeStuck, RefCounted)

protected:
	static void _bind_methods();

public:
	// stuck_tracker.gd UNIT_CENTIMETRES and UNIT_FIELD_COST: the two units progress is measured in.
	static constexpr int32_t UNIT_CENTIMETRES = 0;
	static constexpr int32_t UNIT_FIELD_COST = 1;
	// flow_field.gd STEP_ORTHOGONAL, the field's cost of a step to a neighbour cell.
	static constexpr int64_t STEP_ORTHOGONAL = gd::FIELD_STEP_ORTHOGONAL;

	// stuck_tracker.gd _init: the three thresholds from NavTuning (stuck_seconds, stuck_progress_m)
	// and NavTuning.cell_size, and the castle's ground position. Forgets everything.
	void configure(
			double stuck_seconds,
			double stuck_progress_m,
			double cell_size,
			const Vector2 &castle);
	// stuck_tracker.gd update: looks at every living enemy of the view in ascending id order and
	// refreshes the flags; enemies that are gone are forgotten. `field` is the castle field, null
	// until it exists.
	void update(
			int64_t tick,
			const PackedInt64Array &ids,
			const PackedByteArray &targeted,
			const PackedByteArray &living,
			const PackedVector2Array &current,
			const Ref<NativeField> &field);
	// stuck_tracker.gd clear.
	void clear();
	bool is_stuck(int64_t id) const;
	int64_t stuck_count() const;
	// The flagged enemies of the last update, ascending.
	PackedInt64Array stuck_ids() const;
	// Ticks the enemy has made no progress for as of the last update; 0 for an unknown id.
	int64_t streak_of(int64_t id) const;
	int64_t longest_streak_ticks() const;
	int64_t threshold_ticks() const;

private:
	// One enemy's watermark: the best progress so far, the streak without improvement, the unit the
	// progress is in and the update it was last seen on.
	struct Entry {
		int64_t best = 0;
		int64_t streak = 0;
		int32_t unit = -1;
		int64_t stamp = -1;
	};

	void observe(Entry &entry, bool has_target, const Vector2 &position, const Ref<NativeField> &field);
	void forget_unseen(int64_t tick);

	int64_t threshold_ticks_ = 0;
	int64_t needed_cost_ = 0;
	int64_t needed_cm_ = 0;
	Vector2 castle_ = Vector2(0.0f, 0.0f);
	std::map<int64_t, Entry> entries_;
	std::vector<int64_t> stuck_;
	int64_t longest_ = 0;
};

} // namespace godot
