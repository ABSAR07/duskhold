#pragma once

#include <cstdint>
#include <vector>

#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>

#include "gd_math.h"
#include "native_walls.h"

namespace godot {

// The wall decision's per-tick state in C++ (PLAT-01, plan 04-23): the published time to
// destruction of every wall segment, worked out on a coarse staggered cadence from the damage of the
// enemies aggroed near it (simulation/nav/wall_decision.gd: begin_tick, add_attacker, end_tick,
// ttd_of, evaluated_count), reading segment health from the wall mirror of plan 04-17. A
// line-by-line port under exact_port_rules 1 to 6 and 10: every GDScript int is an int64, the
// arithmetic wraps like GDScript's (unsigned operations, so a pathological value is not undefined
// behaviour), division truncates toward zero as GDScript's does, and posmod is the engine's. The
// pins of tests/unit/test_structure_decision_pins.gd were computed on the GDScript before this file
// existed and this port reproduces them unchanged.
//
// WallDecision keeps its static integer rules in GDScript (EnemySystem.spawn and the debug overlay
// call them); the same five rules are static members here with the same arithmetic, for the native
// enemy step of plan 04-19 and proven equal to the GDScript on an exhaustive grid of inputs by
// tests/unit/test_native_structures.gd through the NativeSim.probe_rules probe.
//
// The bound methods check segment indices and sizes and answer what the GDScript answered for bad
// input: SimClock.MAX_TICKS for an unknown segment, nothing counted for an attacker on one
// (exact_port_rules 10). One thread only.
class NativeWallDecision : public RefCounted {
	GDCLASS(NativeWallDecision, RefCounted)

protected:
	static void _bind_methods();

public:
	// SimClock.MAX_TICKS (1 << 30): the time that stands for never.
	static constexpr int64_t MAX_TICKS = gd::SIM_MAX_TICKS;

	// WallDecision._init's hand-over: the wall mirror (null: every health reads 0), the cadence in
	// ticks (at least 1), the neighbour span (at least 0), the hysteresis in ticks, the notice
	// range in metres and the first and last segment of the run each segment belongs to (arrays of
	// different sizes leave the decision with no segments). Every time to destruction starts never.
	void setup(
			const Ref<NativeWalls> &walls,
			int64_t cadence,
			int64_t span,
			int64_t hysteresis,
			double notice,
			const PackedInt32Array &run_first,
			const PackedInt32Array &run_last);

	// WallDecision.begin_tick, add_attacker, end_tick, ttd_of, evaluated_count.
	void begin_tick(int64_t tick);
	void add_attacker(int64_t segment, int64_t per_300);
	void end_tick();
	int64_t ttd_of(int64_t segment) const;
	int64_t evaluated_count() const;
	// WallDecision.hysteresis_ticks and notice_range.
	int64_t hysteresis_ticks() const;
	double notice_range() const;

	// WallDecision.damage_per_300, ttd_ticks, walk_ticks, should_break and keep_breaking.
	static int64_t damage_per_300(int64_t attack_damage, int64_t interval_ticks);
	static int64_t ttd_ticks(int64_t health, int64_t sum_per_300);
	static int64_t walk_ticks(int64_t distance_cm, int64_t speed_cm_per_s);
	static bool should_break(int64_t ttd, int64_t straight_ticks, int64_t detour_ticks);
	static bool keep_breaking(
			int64_t ttd, int64_t straight_ticks, int64_t detour_ticks, int64_t hysteresis);

private:
	// WallDecision._first_due: the smallest s with (tick + s) % cadence == 0.
	int64_t first_due() const;

	Ref<NativeWalls> walls_;
	int64_t cadence_ = 1;
	int64_t span_ = 0;
	int64_t hysteresis_ = 0;
	double notice_ = 0.0;
	int64_t tick_ = 0;
	int64_t evaluated_ = 0;
	// Published time to destruction per segment; MAX_TICKS until a crowd was seen at it.
	std::vector<int32_t> ttd_;
	// Summed damage per 10 s of the attackers counted for each due segment this tick.
	std::vector<int64_t> sums_;
	std::vector<int32_t> run_first_;
	std::vector<int32_t> run_last_;
};

} // namespace godot
