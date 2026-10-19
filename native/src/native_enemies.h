#pragma once

#include <cstdint>
#include <utility>
#include <vector>

#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/packed_int64_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/vector2.hpp>

#include "native_field.h"
#include "native_structures.h"
#include "native_wall_decision.h"
#include "native_walls.h"

namespace godot {

// The kinds a target (or the held target of a wall) can have, as the small integers that cross to
// GDScript. EnemySystem (simulation/night/enemy_system.gd) maps them to PendingHits.KIND_*.
enum EnemyTargetKind : int32_t {
	TARGET_NONE = 0,
	TARGET_KING = 1,
	TARGET_UNIT = 2,
	TARGET_BUILDING = 3,
	TARGET_CASTLE = 4,
	TARGET_WALL = 5,
};

// The numbers of one EnemyDef the step reads. EnemySystem refreshes the whole table from the
// registered defs at the start of every step, because GDScript read them live from the resource.
struct EnemyDefRow {
	double move_speed = 0.0;
	double radius = 0.0;
	double attack_range = 0.0;
	double aggro_range = 0.0;
	double leash_range = 0.0;
	double projectile_speed = 0.0;
	double attack_interval = 0.0;
	int64_t attack_damage = 0;
	bool ignores_walls = false;
	bool drops_blocked_targets = false;
};

// One enemy: every field of the EnemySystem.Record it replaces (plan 04-19).
struct EnemyRec {
	int64_t id = 0;
	int32_t def = 0;
	Vector2 position = Vector2(0.0f, 0.0f);
	Vector2 previous = Vector2(0.0f, 0.0f);
	int64_t health = 0;
	int32_t target_kind = TARGET_NONE;
	int64_t target_id = 0;
	int64_t cooldown_ready_tick = 0;
	int64_t rescan_ticks = 1;
	int64_t castle_blocker = -1;
	bool castle_blocked = false;
	int64_t per_300 = 0;
	int64_t speed_cm = 0;
	int64_t wall_seg = -1;
	int64_t wall_given_up = -1;
	int32_t behind_kind = TARGET_NONE;
	int64_t behind_id = 0;
};

// The enemy store and the whole enemy step in C++ (PLAT-01, plan 04-19, diagnosis boundary A):
// what EnemySystem (simulation/night/enemy_system.gd) kept in a Dictionary of Record objects and
// walked in GDScript. EnemySystem stays the facade (events, the hit queue, the defs and the
// killer kinds are GDScript) and every rule lives here, a line-by-line port of the GDScript step
// as plan 04-12 left it, under exact_port_rules 1 to 6 and 10: Vector2 values are real_t, every
// GDScript float a double, a scalar meets a Vector2 only through a cast to real_t at the operator,
// enemies are visited in ascending id, and nothing is reassociated. tools/stress/enemy_trace.gd
// traces of the GDScript step, committed as tests/fixtures/trace/enemy_step_refs.txt before this
// file existed, are the proof that the port is the same simulation tick by tick.
//
// THE STEP IS THREE CALLS so the facade can keep the event order of the GDScript: begin_step
// copies position to previous; walk_pass publishes the D-08 wall times, lets every living enemy
// choose its target, walk and strike, and returns the strikes in ascending attacker id (the facade
// enqueues each into PendingHits and emits attack_fired for it); separate_pass pushes overlapping
// enemies apart and then out of the walls. Within the per-enemy loop no enemy reads another
// enemy's state and nothing reads the hit queue, so collecting the strikes does not change an
// answer.
//
// The world the step reads (the wall mirror, the castle route, the wall decision and the
// structure snapshot) is handed over by set_world each step; the pass reads it through the plain
// C++ members of the classes of plans 04-17, 04-18 and 04-23. The bound methods check ids,
// indices and sizes and answer what the GDScript answered for an unknown id: false, the zero
// vector, 0, an empty array, a negative def index (exact_port_rules 10). One thread only.
class NativeEnemies : public RefCounted {
	GDCLASS(NativeEnemies, RefCounted)

protected:
	static void _bind_methods();

public:
	// enemy_index.gd CELL, REACH_MARGIN, KEY_OFFSET and KEY_STRIDE.
	static constexpr double GRID_CELL = 8.0;
	static constexpr double GRID_REACH_MARGIN = 0.01;
	static constexpr int64_t GRID_KEY_OFFSET = static_cast<int64_t>(1) << 19;
	static constexpr int64_t GRID_KEY_STRIDE = static_cast<int64_t>(1) << 20;
	// enemy_system.gd ARRIVE_EPSILON and SEPARATION_CELL_SLACK.
	static constexpr double ARRIVE_EPSILON = 0.001;
	static constexpr double SEPARATION_CELL_SLACK = 0.001;
	// The most defs the table holds; set_def refuses an index beyond it.
	static constexpr int64_t MAX_DEFS = 4096;
	// Values per strike in walk_pass's answer: arrival tick, attacker id, target kind, target id,
	// damage, flight ticks.
	static constexpr int64_t STRIKE_STRIDE = 6;

	// --- the def table ----------------------------------------------------------------------
	// `numbers` is move_speed, radius, attack_range, aggro_range, leash_range, projectile_speed,
	// attack_interval; `flags` bit 0 is ignores_walls and bit 1 drops_blocked_targets. A bad index
	// or a short array is ignored.
	void set_def(int64_t index, const PackedFloat64Array &numbers, int64_t attack_damage, int64_t flags);

	// --- the store ---------------------------------------------------------------------------
	// Adds an enemy and returns its id (they start at 1 and only grow, across clear too); 0 and no
	// enemy for a def index that is not in the table.
	int64_t spawn(
			int64_t def_index,
			const Vector2 &position,
			int64_t health,
			int64_t rescan_ticks,
			int64_t per_300,
			int64_t speed_cm);
	PackedInt64Array ids() const;
	int64_t count() const;
	bool is_alive(int64_t id) const;
	Vector2 position_of(int64_t id) const;
	Vector2 previous_of(int64_t id) const;
	// The table index of the enemy's def; -1 for an unknown id.
	int64_t def_index_of(int64_t id) const;
	int64_t health_of(int64_t id) const;
	// The kind of the target a held wall stands in front of (TARGET_NONE when none, and for an
	// unknown id); read by tests/unit/test_melee_breaks_to_target.gd.
	int64_t behind_kind_of(int64_t id) const;
	// [kind, id] of the target, or an empty array while there is none and for an unknown id.
	PackedInt64Array target_of(int64_t id) const;
	// Removes `amount` hit points (never below 0) and answers the health left; -1 and no change for
	// an unknown or dead id and a non-positive amount.
	int64_t damage(int64_t id, int64_t amount);
	// The ids whose health is 0, ascending (not removed), and the removal of one id.
	PackedInt64Array dead_ids() const;
	void remove(int64_t id);
	// Empties the field; the id counter keeps growing.
	void clear();
	// EnemyIndex.within over the living enemies: ids whose cell lies within `reach` of `pos`'s cell,
	// ascending, rebuilt lazily after the field changed.
	PackedInt64Array living_within(const Vector2 &pos, double reach);
	// TargetQuery.nearest_enemy and nearest_enemy_clear over the same candidates (plan 04-20): the
	// id of the living enemy nearest `pos` whose centre is within `reach` (inclusive, squared
	// distances compared, the lower id on a tie), or -1. With `walls` given and at least one
	// intact segment, only an enemy whose straight line from `pos` is clear of every intact
	// segment for a walker of `radius` counts, and only a candidate that would improve the best
	// pays for the line test. A null `walls` is the plain query.
	int64_t nearest_living(
			const Vector2 &pos, double reach, double radius, const Ref<NativeWalls> &walls);
	// The read view's arrays: ids ascending with the previous and the current positions.
	PackedInt64Array view_ids() const;
	PackedVector2Array view_previous() const;
	PackedVector2Array view_current() const;

	// --- the step ----------------------------------------------------------------------------
	// The structures, walls, castle route and decision of the step in progress (null: none).
	void set_world(
			const Ref<NativeWalls> &walls,
			const Ref<NativeRoute> &route,
			const Ref<NativeWallDecision> &decision,
			const Ref<NativeStructures> &structures);
	// previous := position for every enemy; marks the field changed.
	void begin_step();
	// The D-08 wall times (when walls are solid) and every living enemy's target choice, walk and
	// strike, in ascending id. Answers the strikes, STRIKE_STRIDE values each.
	PackedInt64Array walk_pass(
			int64_t tick,
			const Vector2 &castle_position,
			double castle_radius,
			bool king_up,
			const Vector2 &king_position,
			double king_radius,
			bool walls_solid);
	// The push-apart of the living enemies, then (when walls are solid) the push out of the walls
	// of every living enemy whose def does not ignore them. Marks the field changed.
	void separate_pass(bool walls_solid);

private:
	int64_t slot_of(int64_t id) const;
	void rebuild_grid();
	// The ids living_within lists, ascending, appended to `found` (cleared first).
	void collect_within(const Vector2 &pos, double reach, std::vector<int64_t> &found);

	std::vector<EnemyRec> recs_;
	std::vector<EnemyDefRow> defs_;
	int64_t next_id_ = 1;

	Ref<NativeWalls> walls_;
	Ref<NativeRoute> route_;
	Ref<NativeWallDecision> decision_;
	Ref<NativeStructures> structures_;

	// The grid of living enemies: (cell key, id) sorted, and how many distinct cells it holds.
	std::vector<std::pair<int64_t, int64_t>> grid_;
	int64_t grid_cells_ = 0;
	bool grid_dirty_ = true;
	std::vector<int64_t> strikes_;
	// Scratch for nearest_living's candidate ids (one thread only).
	std::vector<int64_t> candidates_;
};

} // namespace godot
