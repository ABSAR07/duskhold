#include <algorithm>
#include <cstdint>
#include <vector>

#include <godot_cpp/variant/vector3i.hpp>

#include "gd_math.h"
#include "native_enemies.h"
#include "native_separation.h"

using namespace godot;

// THE NATIVE ENEMY STEP (PLAT-01, plan 04-19, diagnosis boundary A). Step order, as
// EnemySystem.step ran it and the facade still drives it:
//   1. begin_step: previous := position for every enemy;
//   2. (facade) the castle is destroyed: stop; else StructureIndex.rebuild;
//   3. walk_pass: when walls are solid, publish the D-08 wall times (begin_tick, add_attacker per
//      living enemy aggroed onto an intact segment, else wall_seg := -1, end_tick); then, for each
//      living enemy in ascending id, _choose_target and _advance_and_strike, collecting the
//      strikes in that order;
//   4. (facade) enqueue every strike into PendingHits and emit attack_fired for it;
//   5. separate_pass: the push-apart of the living enemies (native Separation, cell
//      2 * largest radius + 0.001), then, when walls are solid, the push out of every intact
//      segment of each living enemy whose def does not ignore walls.
//
// A LINE-BY-LINE PORT of simulation/night/enemy_system.gd as plan 04-12 left it (the rule of the
// owner decision of 2026-10-19, UAT test 13, gap G-04-7: _breaks_to_targets, _release_held_wall
// and the three sub-rules of _target_walls_in_the_way, ported as committed and never changed
// here). The GDScript at the start of plan 04-19 is commit 2483384:
//   git show 2483384:simulation/night/enemy_system.gd
// Each function below names the GDScript function it is. exact_port_rules 1 to 6: a GDScript float
// is a double, a Vector2 holds real_t, a Vector2 method result leaves as a double (the real_t
// distance widened) and a scalar meets a Vector2 only through a cast at the operator; no
// expression is reassociated or hoisted.
//
// Inputs fixed for the whole enemy phase (nothing moves or falls before hits resolve, DR-8): the
// castle, the king, the structure snapshot, the walls, the castle route and the decision. The
// snapshot answers every lookup the GDScript made on the unit and building systems: a unit target
// is valid while it is in the snapshot of living units, a building target while its spot index is
// in the standing snapshot.

namespace {

constexpr int64_t MAX_TICKS = gd::SIM_MAX_TICKS;

// enemy_system.gd is_rescan_tick.
bool is_rescan_tick(int64_t tick, int64_t id, int64_t rescan_ticks) {
	return rescan_ticks > 0 && (tick + id) % rescan_ticks == 0;
}

// enemy_system.gd desired_step: the straight-line step toward `goal`, at most `max_distance`.
Vector2 desired_step(const Vector2 &pos, const Vector2 &goal, double max_distance) {
	return gd::move_toward(pos, goal, static_cast<real_t>(gd::maxf(max_distance, 0.0))) - pos;
}

// The step of one pass: the world it reads and the strikes it collects.
class Stepper {
public:
	Stepper(
			std::vector<EnemyRec> &recs,
			const std::vector<EnemyDefRow> &defs,
			const NativeWalls *walls,
			const NativeRoute *route,
			NativeWallDecision *decision,
			const NativeStructures *structures,
			bool solid) :
			recs_(recs),
			defs_(defs),
			walls_(walls),
			route_(route),
			decision_(decision),
			structures_(structures),
			solid_(solid) {}

	int64_t tick = 0;
	Vector2 castle_position = Vector2(0.0f, 0.0f);
	double castle_radius = 0.0;
	bool king_up = false;
	Vector2 king_position = Vector2(0.0f, 0.0f);
	double king_radius = 0.0;
	std::vector<int64_t> *strikes = nullptr;

	// enemy_system.gd _publish_wall_times.
	void publish_wall_times() {
		decision_->begin_tick(tick);
		for (EnemyRec &rec : recs_) {
			if (rec.health > 0 && rec.wall_seg >= 0) {
				if (segment_intact(rec.wall_seg)) {
					decision_->add_attacker(rec.wall_seg, rec.per_300);
				} else {
					rec.wall_seg = -1;
				}
			}
		}
		decision_->end_tick();
	}

	// The per-enemy loop of enemy_system.gd step.
	void walk_all() {
		for (EnemyRec &rec : recs_) {
			if (rec.health <= 0) {
				continue;
			}
			choose_target(rec);
			advance_and_strike(rec);
		}
	}

	// enemy_system.gd _separate.
	void separate() {
		std::vector<EnemyRec *> alive;
		for (EnemyRec &rec : recs_) {
			if (rec.health > 0) {
				alive.push_back(&rec);
			}
		}
		if (alive.size() < 2) {
			return;
		}
		// Plain std::vectors, handed to the raw-pointer core: no Godot packed array is built only to
		// be read back (IN-01).
		separation_positions_.clear();
		separation_radii_.clear();
		separation_ids_.clear();
		double largest = 0.0;
		for (const EnemyRec *rec : alive) {
			separation_positions_.push_back(rec->position);
			separation_radii_.push_back(def_of(*rec).radius);
			separation_ids_.push_back(rec->id);
			largest = gd::maxf(largest, def_of(*rec).radius);
		}
		const double cell = 2.0 * largest + NativeEnemies::SEPARATION_CELL_SLACK;
		const int64_t count = static_cast<int64_t>(alive.size());
		separation_pushes_.resize(alive.size());
		duskhold::separation_displacements_bucketed_raw(
				separation_positions_.data(),
				separation_radii_.data(),
				separation_ids_.data(),
				count,
				cell,
				separation_pushes_.data(),
				separation_scratch_);
		for (size_t index = 0; index < alive.size(); index++) {
			alive[index]->position += separation_pushes_[index];
		}
	}

	// enemy_system.gd _push_out_of_walls.
	void push_out_of_walls() {
		if (walls_ == nullptr) {
			return;
		}
		for (EnemyRec &rec : recs_) {
			if (rec.health > 0 && !def_of(rec).ignores_walls) {
				rec.position = walls_->pushed_position(rec.position, def_of(rec).radius);
			}
		}
	}

private:
	const EnemyDefRow &def_of(const EnemyRec &rec) const {
		return defs_[static_cast<size_t>(rec.def)];
	}

	// Pathing.walls().is_intact: a missing wall mirror has no intact segment.
	bool segment_intact(int64_t segment) const {
		return walls_ != nullptr && walls_->is_intact(segment);
	}

	// Pathing.first_blocking.
	int64_t first_blocking(const Vector2 &from, const Vector2 &to, double radius) const {
		if (walls_ == nullptr) {
			return -1;
		}
		return walls_->blocking_segment(from, to, radius);
	}

	// enemy_system.gd _wall_edge: the distance from `pos` to the face of the segment.
	double wall_edge(const Vector2 &pos, int64_t segment) const {
		const Vector2 nearest = walls_ != nullptr ? walls_->closest_on_segment(segment, pos)
												   : Vector2(0.0f, 0.0f);
		const double half = walls_ != nullptr ? walls_->half_thickness_of(segment) : 0.0;
		return static_cast<double>(gd::distance_to(pos, nearest)) - half;
	}

	bool king_valid_for(const EnemyRec &rec) const {
		return king_up && static_cast<double>(gd::distance_to(rec.position, king_position)) <=
								  def_of(rec).leash_range;
	}

	// enemy_system.gd _target_valid with the five _*_target_valid functions.
	bool target_valid(const EnemyRec &rec) const {
		const EnemyDefRow &def = def_of(rec);
		switch (rec.target_kind) {
			case TARGET_KING:
				return king_valid_for(rec);
			case TARGET_CASTLE: {
				const double to_castle = static_cast<double>(gd::distance_to(rec.position, castle_position));
				return to_castle <= def.leash_range + castle_radius;
			}
			case TARGET_BUILDING: {
				if (structures_ == nullptr || !structures_->is_standing(rec.target_id)) {
					return false;
				}
				const double edge =
						static_cast<double>(gd::distance_to(rec.position, structures_->building_centre(rec.target_id))) -
						structures_->building_radius(rec.target_id);
				return edge <= def.leash_range;
			}
			case TARGET_UNIT: {
				if (structures_ == nullptr || !structures_->has_unit(rec.target_id)) {
					return false;
				}
				const double edge =
						static_cast<double>(gd::distance_to(rec.position, structures_->unit_position(rec.target_id))) -
						structures_->unit_radius(rec.target_id);
				return edge <= def.leash_range;
			}
			case TARGET_WALL:
				if (!segment_intact(rec.target_id)) {
					return false;
				}
				return wall_edge(rec.position, rec.target_id) <= def.leash_range;
			default:
				return false;
		}
	}

	// enemy_system.gd _goal_of: where the record's target stands.
	Vector2 goal_of(const EnemyRec &rec) const {
		if (rec.target_kind == TARGET_KING) {
			return king_position;
		}
		if (rec.target_kind == TARGET_BUILDING && structures_ != nullptr) {
			return structures_->building_centre(rec.target_id);
		}
		if (rec.target_kind == TARGET_UNIT && structures_ != nullptr) {
			return structures_->unit_position(rec.target_id);
		}
		return castle_position;
	}

	// enemy_system.gd _goal_radius_of.
	double goal_radius_of(const EnemyRec &rec) const {
		if (rec.target_kind == TARGET_KING) {
			return king_radius;
		}
		if (rec.target_kind == TARGET_BUILDING && structures_ != nullptr) {
			return structures_->building_radius(rec.target_id);
		}
		if (rec.target_kind == TARGET_UNIT && structures_ != nullptr) {
			return structures_->unit_radius(rec.target_id);
		}
		return castle_radius;
	}

	// enemy_system.gd _breaks_to_targets.
	bool breaks_to_targets(const EnemyRec &rec) const {
		const EnemyDefRow &def = def_of(rec);
		return solid_ && !def.ignores_walls && !def.drops_blocked_targets && def.projectile_speed <= 0.0;
	}

	// enemy_system.gd _shoots_over.
	bool shoots_over(const EnemyRec &rec, const Vector2 &centre, double target_radius) const {
		const EnemyDefRow &def = def_of(rec);
		if (def.projectile_speed <= 0.0) {
			return false;
		}
		return static_cast<double>(gd::distance_to(rec.position, centre)) - target_radius <= def.attack_range;
	}

	// enemy_system.gd _can_see.
	bool can_see(const EnemyRec &rec, const Vector2 &centre, double target_radius) const {
		if (!solid_ || def_of(rec).ignores_walls) {
			return true;
		}
		if (first_blocking(rec.position, centre, def_of(rec).radius) < 0) {
			return true;
		}
		return shoots_over(rec, centre, target_radius);
	}

	// enemy_system.gd _target_in_sight.
	bool target_in_sight(const EnemyRec &rec) const {
		if (rec.target_kind == TARGET_WALL) {
			return true;
		}
		if (breaks_to_targets(rec)) {
			if (rec.target_kind != TARGET_CASTLE) {
				return true;
			}
			return first_blocking(rec.position, castle_position, 0.0) < 0;
		}
		return can_see(rec, goal_of(rec), goal_radius_of(rec));
	}

	// enemy_system.gd _wall_ticks: the time to destruction of `segment`, the straight walk to the
	// castle and the detour, in ticks, as (x, y, z).
	void wall_ticks(const EnemyRec &rec, int64_t segment, int64_t &ttd, int64_t &straight, int64_t &detour) const {
		ttd = decision_->ttd_of(segment);
		straight = route_->straight_ticks(rec.position, rec.speed_cm);
		detour = route_->detour_ticks(rec.position, rec.speed_cm);
	}

	// enemy_system.gd _breaking_is_faster.
	bool breaking_is_faster(const EnemyRec &rec, int64_t segment) const {
		int64_t ttd = 0;
		int64_t straight = 0;
		int64_t detour = 0;
		wall_ticks(rec, segment, ttd, straight, detour);
		if (segment == rec.wall_given_up && detour < MAX_TICKS) {
			return false;
		}
		return NativeWallDecision::should_break(ttd, straight, detour);
	}

	// enemy_system.gd _keeps_breaking.
	bool keeps_breaking(const EnemyRec &rec) const {
		int64_t ttd = 0;
		int64_t straight = 0;
		int64_t detour = 0;
		wall_ticks(rec, rec.target_id, ttd, straight, detour);
		return NativeWallDecision::keep_breaking(ttd, straight, detour, decision_->hysteresis_ticks());
	}

	// enemy_system.gd _take_wall.
	void take_wall(EnemyRec &rec, int64_t segment, double reach) const {
		if (segment < 0 || !segment_intact(segment)) {
			return;
		}
		if (wall_edge(rec.position, segment) > reach) {
			return;
		}
		rec.target_kind = TARGET_WALL;
		rec.target_id = segment;
		rec.wall_seg = segment;
	}

	// enemy_system.gd _pick_nearest_structure.
	void pick_nearest_structure(EnemyRec &rec) const {
		if (structures_ == nullptr) {
			return;
		}
		const EnemyDefRow &def = def_of(rec);
		Vector3i found;
		if (breaks_to_targets(rec)) {
			found = structures_->scan_visible(rec.position, def.aggro_range, walls_, 0.0, -1.0);
			if (found.z == 0) {
				found = structures_->scan_through_walls(rec.position, def.aggro_range);
			}
		} else if (solid_ && !def.ignores_walls) {
			double ranged_reach = -1.0;
			if (def.projectile_speed > 0.0) {
				ranged_reach = def.attack_range;
			}
			found = structures_->scan_visible(rec.position, def.aggro_range, walls_, def.radius, ranged_reach);
		} else {
			found = structures_->scan_nearest(rec.position, def.aggro_range);
		}
		if (found.z == 0) {
			return;
		}
		if (found.x == NativeStructures::KIND_UNIT) {
			rec.target_kind = TARGET_UNIT;
		} else if (found.x == NativeStructures::KIND_BUILDING) {
			rec.target_kind = TARGET_BUILDING;
		} else {
			rec.target_kind = TARGET_CASTLE;
		}
		rec.target_id = found.y;
	}

	// enemy_system.gd _release_held_wall.
	void release_held_wall(EnemyRec &rec) const {
		const int64_t segment = rec.target_id;
		rec.target_kind = rec.behind_kind;
		rec.target_id = rec.behind_id;
		bool release = false;
		if (!target_valid(rec)) {
			rec.target_kind = TARGET_NONE;
			rec.target_id = 0;
			release = true;
		} else if (!segment_intact(segment)) {
			release = true;
		} else if (is_rescan_tick(tick, rec.id, rec.rescan_ticks)) {
			const Vector2 goal = goal_of(rec);
			release = first_blocking(rec.position, goal, 0.0) != segment;
		}
		if (release) {
			rec.behind_kind = TARGET_NONE;
			rec.behind_id = 0;
			rec.wall_seg = -1;
		} else {
			rec.target_kind = TARGET_WALL;
			rec.target_id = segment;
		}
	}

	// enemy_system.gd _choose_base_target.
	bool choose_base_target(EnemyRec &rec) const {
		const EnemyDefRow &def = def_of(rec);
		bool valid = rec.target_kind != TARGET_NONE && target_valid(rec);
		const bool rescan = is_rescan_tick(tick, rec.id, rec.rescan_ticks);
		if (valid && rescan && !target_in_sight(rec)) {
			valid = false;
		}
		if (valid && !rescan) {
			return false;
		}
		if (valid && rec.target_kind == TARGET_KING) {
			return false;
		}
		if (king_up &&
				static_cast<double>(gd::distance_to(rec.position, king_position)) <= def.aggro_range &&
				(breaks_to_targets(rec) || can_see(rec, king_position, king_radius))) {
			rec.target_kind = TARGET_KING;
			rec.target_id = 0;
			rec.behind_kind = TARGET_NONE;
			return true;
		}
		if (valid) {
			return false;
		}
		rec.target_kind = TARGET_NONE;
		rec.target_id = 0;
		rec.behind_kind = TARGET_NONE;
		pick_nearest_structure(rec);
		return rec.target_kind != TARGET_NONE;
	}

	// enemy_system.gd _aim_at_walls.
	void aim_at_walls(EnemyRec &rec, bool rescan) const {
		const EnemyDefRow &def = def_of(rec);
		if (rescan) {
			rec.castle_blocker = first_blocking(rec.position, castle_position, def.radius);
			rec.castle_blocked = rec.castle_blocker >= 0 && !route_->is_sealed(rec.position);
			rec.wall_seg = -1;
			if (rec.castle_blocker >= 0 &&
					wall_edge(rec.position, rec.castle_blocker) <= decision_->notice_range()) {
				rec.wall_seg = rec.castle_blocker;
			}
		}
		if (rec.wall_seg < 0 || !segment_intact(rec.wall_seg)) {
			return;
		}
		if (!breaking_is_faster(rec, rec.wall_seg)) {
			return;
		}
		take_wall(rec, rec.wall_seg, gd::minf(decision_->notice_range(), def.leash_range));
	}

	// enemy_system.gd _target_walls_in_the_way.
	void target_walls_in_the_way(EnemyRec &rec, bool chosen) const {
		const EnemyDefRow &def = def_of(rec);
		const bool rescan = is_rescan_tick(tick, rec.id, rec.rescan_ticks);
		if (rec.target_kind == TARGET_WALL) {
			if (rec.behind_kind != TARGET_NONE || !rescan || keeps_breaking(rec)) {
				return;
			}
			rec.wall_given_up = rec.target_id;
			rec.target_kind = TARGET_NONE;
			rec.target_id = 0;
		}
		if (rec.target_kind == TARGET_NONE) {
			aim_at_walls(rec, rescan);
			return;
		}
		rec.wall_seg = -1;
		if (!chosen && !rescan) {
			return;
		}
		const bool breaks = breaks_to_targets(rec);
		if (breaks && rec.target_kind == TARGET_CASTLE) {
			return;
		}
		const Vector2 goal = goal_of(rec);
		if (shoots_over(rec, goal, goal_radius_of(rec))) {
			return;
		}
		const int32_t held_kind = rec.target_kind;
		const int64_t held_id = rec.target_id;
		const double line_radius = breaks ? 0.0 : def.radius;
		take_wall(rec, first_blocking(rec.position, goal, line_radius), def.leash_range);
		if (breaks && rec.target_kind == TARGET_WALL) {
			rec.behind_kind = held_kind;
			rec.behind_id = held_id;
		}
	}

	// enemy_system.gd _choose_target.
	void choose_target(EnemyRec &rec) const {
		if (rec.behind_kind != TARGET_NONE) {
			release_held_wall(rec);
		}
		const bool chosen = choose_base_target(rec);
		if (solid_ && !def_of(rec).ignores_walls) {
			target_walls_in_the_way(rec, chosen);
		}
	}

	// enemy_system.gd _advance_and_strike: walks toward the target (or the castle while there is
	// none) and, once at its stop distance and off cooldown, collects one strike.
	void advance_and_strike(EnemyRec &rec) const {
		const EnemyDefRow &def = def_of(rec);
		Vector2 goal = castle_position;
		double goal_radius = castle_radius;
		if (rec.target_kind == TARGET_KING) {
			goal = king_position;
			goal_radius = king_radius;
		} else if (rec.target_kind == TARGET_BUILDING) {
			goal = structures_->building_centre(rec.target_id);
			goal_radius = structures_->building_radius(rec.target_id);
		} else if (rec.target_kind == TARGET_UNIT) {
			goal = structures_->unit_position(rec.target_id);
			goal_radius = structures_->unit_radius(rec.target_id);
		} else if (rec.target_kind == TARGET_WALL) {
			if (walls_ != nullptr) {
				goal = walls_->closest_on_segment(rec.target_id, rec.position);
				goal_radius = walls_->half_thickness_of(rec.target_id);
			}
		}
		const bool attacking = rec.target_kind != TARGET_NONE;
		const double stop_distance = goal_radius + def.attack_range;
		double remaining = static_cast<double>(gd::distance_to(rec.position, goal)) - stop_distance;
		if (remaining > 0.0) {
			const double reach = gd::minf(def.move_speed * gd::SIM_STEP, remaining);
			if (rec.castle_blocked && !attacking && solid_) {
				rec.position += route_->march_step(rec.position, reach);
			} else {
				rec.position += desired_step(rec.position, goal, reach);
			}
			remaining = static_cast<double>(gd::distance_to(rec.position, goal)) - stop_distance;
		}
		if (!attacking || remaining > NativeEnemies::ARRIVE_EPSILON || tick < rec.cooldown_ready_tick) {
			return;
		}
		const int64_t flight = gd::sim_flight_ticks(
				static_cast<double>(gd::distance_to(rec.position, goal)), def.projectile_speed);
		strikes->push_back(tick + flight);
		strikes->push_back(rec.id);
		strikes->push_back(rec.target_kind);
		strikes->push_back(rec.target_id);
		strikes->push_back(def.attack_damage);
		strikes->push_back(flight);
		rec.cooldown_ready_tick = tick + gd::sim_ticks(def.attack_interval);
	}

	std::vector<EnemyRec> &recs_;
	const std::vector<EnemyDefRow> &defs_;
	const NativeWalls *walls_;
	const NativeRoute *route_;
	NativeWallDecision *decision_;
	const NativeStructures *structures_;
	bool solid_;
	// separate()'s plain arrays and scratch, kept for the pass.
	std::vector<Vector2> separation_positions_;
	std::vector<double> separation_radii_;
	std::vector<int64_t> separation_ids_;
	std::vector<Vector2> separation_pushes_;
	duskhold::SeparationScratch separation_scratch_;
};

} // namespace

PackedInt64Array NativeEnemies::walk_pass(
		int64_t tick,
		const Vector2 &castle_position,
		double castle_radius,
		bool king_up,
		const Vector2 &king_position,
		double king_radius,
		bool walls_solid) {
	strikes_.clear();
	grid_dirty_ = true;
	// A solid world needs the route and the decision; without them nothing can be decided.
	const bool solid = walls_solid && route_.is_valid() && decision_.is_valid();
	// A target of a kind the step cannot resolve (no snapshot) stays harmless: the facade always
	// hands every object over, and a missing one is the unit-less, building-less case.
	if (!structures_.is_valid()) {
		return PackedInt64Array();
	}
	Stepper stepper(recs_, defs_, walls_.ptr(), route_.ptr(), decision_.ptr(), structures_.ptr(), solid);
	stepper.tick = tick;
	stepper.castle_position = castle_position;
	stepper.castle_radius = castle_radius;
	stepper.king_up = king_up;
	stepper.king_position = king_position;
	stepper.king_radius = king_radius;
	stepper.strikes = &strikes_;
	if (solid) {
		stepper.publish_wall_times();
	}
	stepper.walk_all();
	PackedInt64Array result;
	result.resize(static_cast<int64_t>(strikes_.size()));
	for (size_t index = 0; index < strikes_.size(); index++) {
		result[static_cast<int64_t>(index)] = strikes_[index];
	}
	grid_dirty_ = true;
	return result;
}

void NativeEnemies::separate_pass(bool walls_solid) {
	const bool solid = walls_solid && route_.is_valid() && decision_.is_valid();
	Stepper stepper(recs_, defs_, walls_.ptr(), route_.ptr(), decision_.ptr(), structures_.ptr(), solid);
	stepper.separate();
	if (solid) {
		stepper.push_out_of_walls();
	}
	grid_dirty_ = true;
}
