#include "native_enemies.h"

#include <algorithm>
#include <cstdint>
#include <limits>
#include <vector>

#include <godot_cpp/core/class_db.hpp>

#include "gd_math.h"

using namespace godot;

namespace {

// GDScript int arithmetic wraps on overflow; the port does the same in unsigned arithmetic so a
// pathological coordinate cannot be undefined behaviour and aliases to the same key as before.
int64_t wrap_add(int64_t a, int64_t b) {
	return static_cast<int64_t>(static_cast<uint64_t>(a) + static_cast<uint64_t>(b));
}

int64_t wrap_mul(int64_t a, int64_t b) {
	return static_cast<int64_t>(static_cast<uint64_t>(a) * static_cast<uint64_t>(b));
}

// enemy_index.gd _key.
int64_t grid_key(int64_t cell_x, int64_t cell_y) {
	return wrap_add(
			wrap_mul(wrap_add(cell_x, NativeEnemies::GRID_KEY_OFFSET), NativeEnemies::GRID_KEY_STRIDE),
			wrap_add(cell_y, NativeEnemies::GRID_KEY_OFFSET));
}

// A block of cells wider than this many cells per side is never walked: every living enemy is
// listed instead, a superset the caller narrows with its own exact test.
constexpr int64_t MAX_REACH_CELLS = 1000000;

} // namespace

void NativeEnemies::_bind_methods() {
	ClassDB::bind_method(
			D_METHOD("set_def", "index", "numbers", "attack_damage", "flags"),
			&NativeEnemies::set_def);
	ClassDB::bind_method(
			D_METHOD("spawn", "def_index", "position", "health", "rescan_ticks", "per_300", "speed_cm"),
			&NativeEnemies::spawn);
	ClassDB::bind_method(D_METHOD("ids"), &NativeEnemies::ids);
	ClassDB::bind_method(D_METHOD("count"), &NativeEnemies::count);
	ClassDB::bind_method(D_METHOD("is_alive", "id"), &NativeEnemies::is_alive);
	ClassDB::bind_method(D_METHOD("position_of", "id"), &NativeEnemies::position_of);
	ClassDB::bind_method(D_METHOD("previous_of", "id"), &NativeEnemies::previous_of);
	ClassDB::bind_method(D_METHOD("def_index_of", "id"), &NativeEnemies::def_index_of);
	ClassDB::bind_method(D_METHOD("health_of", "id"), &NativeEnemies::health_of);
	ClassDB::bind_method(D_METHOD("behind_kind_of", "id"), &NativeEnemies::behind_kind_of);
	ClassDB::bind_method(D_METHOD("target_of", "id"), &NativeEnemies::target_of);
	ClassDB::bind_method(D_METHOD("damage", "id", "amount"), &NativeEnemies::damage);
	ClassDB::bind_method(D_METHOD("dead_ids"), &NativeEnemies::dead_ids);
	ClassDB::bind_method(D_METHOD("remove", "id"), &NativeEnemies::remove);
	ClassDB::bind_method(D_METHOD("clear"), &NativeEnemies::clear);
	ClassDB::bind_method(D_METHOD("living_within", "pos", "reach"), &NativeEnemies::living_within);
	ClassDB::bind_method(
			D_METHOD("nearest_living", "pos", "reach", "radius", "walls"),
			&NativeEnemies::nearest_living);
	ClassDB::bind_method(D_METHOD("view_ids"), &NativeEnemies::view_ids);
	ClassDB::bind_method(D_METHOD("view_previous"), &NativeEnemies::view_previous);
	ClassDB::bind_method(D_METHOD("view_current"), &NativeEnemies::view_current);
	ClassDB::bind_method(
			D_METHOD("set_world", "walls", "route", "decision", "structures"),
			&NativeEnemies::set_world);
	ClassDB::bind_method(D_METHOD("begin_step"), &NativeEnemies::begin_step);
	ClassDB::bind_method(
			D_METHOD(
					"walk_pass",
					"tick",
					"castle_position",
					"castle_radius",
					"king_up",
					"king_position",
					"king_radius",
					"walls_solid"),
			&NativeEnemies::walk_pass);
	ClassDB::bind_method(D_METHOD("separate_pass", "walls_solid"), &NativeEnemies::separate_pass);
}

void NativeEnemies::set_def(
		int64_t index, const PackedFloat64Array &numbers, int64_t attack_damage, int64_t flags) {
	if (index < 0 || index >= MAX_DEFS || numbers.size() < 7) {
		return;
	}
	const size_t slot = static_cast<size_t>(index);
	if (defs_.size() <= slot) {
		defs_.resize(slot + 1);
	}
	EnemyDefRow &row = defs_[slot];
	row.move_speed = numbers[0];
	row.radius = numbers[1];
	row.attack_range = numbers[2];
	row.aggro_range = numbers[3];
	row.leash_range = numbers[4];
	row.projectile_speed = numbers[5];
	row.attack_interval = numbers[6];
	row.attack_damage = attack_damage;
	row.ignores_walls = (flags & 1) != 0;
	row.drops_blocked_targets = (flags & 2) != 0;
}

int64_t NativeEnemies::spawn(
		int64_t def_index,
		const Vector2 &position,
		int64_t health,
		int64_t rescan_ticks,
		int64_t per_300,
		int64_t speed_cm) {
	if (def_index < 0 || static_cast<size_t>(def_index) >= defs_.size()) {
		return 0;
	}
	EnemyRec rec;
	rec.id = next_id_;
	rec.def = static_cast<int32_t>(def_index);
	rec.position = position;
	rec.previous = position;
	rec.health = health;
	rec.rescan_ticks = rescan_ticks;
	rec.per_300 = per_300;
	rec.speed_cm = speed_cm;
	next_id_++;
	recs_.push_back(rec);
	grid_dirty_ = true;
	return rec.id;
}

// Ids are appended in ascending order and removal keeps the order, so the store is sorted by id.
int64_t NativeEnemies::slot_of(int64_t id) const {
	const auto found = std::lower_bound(
			recs_.begin(), recs_.end(), id, [](const EnemyRec &rec, int64_t wanted) {
				return rec.id < wanted;
			});
	if (found == recs_.end() || found->id != id) {
		return -1;
	}
	return static_cast<int64_t>(found - recs_.begin());
}

PackedInt64Array NativeEnemies::ids() const {
	PackedInt64Array result;
	result.resize(static_cast<int64_t>(recs_.size()));
	for (size_t slot = 0; slot < recs_.size(); slot++) {
		result[static_cast<int64_t>(slot)] = recs_[slot].id;
	}
	return result;
}

int64_t NativeEnemies::count() const {
	return static_cast<int64_t>(recs_.size());
}

bool NativeEnemies::is_alive(int64_t id) const {
	const int64_t slot = slot_of(id);
	return slot >= 0 && recs_[static_cast<size_t>(slot)].health > 0;
}

Vector2 NativeEnemies::position_of(int64_t id) const {
	const int64_t slot = slot_of(id);
	return slot >= 0 ? recs_[static_cast<size_t>(slot)].position : Vector2(0.0f, 0.0f);
}

Vector2 NativeEnemies::previous_of(int64_t id) const {
	const int64_t slot = slot_of(id);
	return slot >= 0 ? recs_[static_cast<size_t>(slot)].previous : Vector2(0.0f, 0.0f);
}

int64_t NativeEnemies::def_index_of(int64_t id) const {
	const int64_t slot = slot_of(id);
	return slot >= 0 ? recs_[static_cast<size_t>(slot)].def : -1;
}

int64_t NativeEnemies::health_of(int64_t id) const {
	const int64_t slot = slot_of(id);
	return slot >= 0 ? recs_[static_cast<size_t>(slot)].health : 0;
}

int64_t NativeEnemies::behind_kind_of(int64_t id) const {
	const int64_t slot = slot_of(id);
	return slot >= 0 ? recs_[static_cast<size_t>(slot)].behind_kind : TARGET_NONE;
}

PackedInt64Array NativeEnemies::target_of(int64_t id) const {
	PackedInt64Array result;
	const int64_t slot = slot_of(id);
	if (slot < 0 || recs_[static_cast<size_t>(slot)].target_kind == TARGET_NONE) {
		return result;
	}
	result.push_back(recs_[static_cast<size_t>(slot)].target_kind);
	result.push_back(recs_[static_cast<size_t>(slot)].target_id);
	return result;
}

int64_t NativeEnemies::damage(int64_t id, int64_t amount) {
	const int64_t slot = slot_of(id);
	if (slot < 0 || recs_[static_cast<size_t>(slot)].health <= 0 || amount <= 0) {
		return -1;
	}
	EnemyRec &rec = recs_[static_cast<size_t>(slot)];
	rec.health = gd::maxi(rec.health - amount, 0);
	return rec.health;
}

PackedInt64Array NativeEnemies::dead_ids() const {
	PackedInt64Array result;
	for (const EnemyRec &rec : recs_) {
		if (rec.health <= 0) {
			result.push_back(rec.id);
		}
	}
	return result;
}

void NativeEnemies::remove(int64_t id) {
	const int64_t slot = slot_of(id);
	if (slot < 0) {
		return;
	}
	recs_.erase(recs_.begin() + slot);
	grid_dirty_ = true;
}

void NativeEnemies::clear() {
	recs_.clear();
	grid_dirty_ = true;
}

// enemy_index.gd rebuild over the living enemies in ascending id: each is filed under its cell.
void NativeEnemies::rebuild_grid() {
	grid_.clear();
	for (const EnemyRec &rec : recs_) {
		if (rec.health > 0) {
			const int64_t cell_x = gd::floori(static_cast<double>(rec.position.x) / GRID_CELL);
			const int64_t cell_y = gd::floori(static_cast<double>(rec.position.y) / GRID_CELL);
			grid_.emplace_back(grid_key(cell_x, cell_y), rec.id);
		}
	}
	std::sort(grid_.begin(), grid_.end());
	grid_cells_ = 0;
	for (size_t index = 0; index < grid_.size(); index++) {
		if (index == 0 || grid_[index].first != grid_[index - 1].first) {
			grid_cells_++;
		}
	}
	grid_dirty_ = false;
}

// enemy_index.gd within.
void NativeEnemies::collect_within(const Vector2 &pos, double reach, std::vector<int64_t> &found) {
	if (grid_dirty_) {
		rebuild_grid();
	}
	const int64_t span = gd::ceili((gd::maxf(reach, 0.0) + GRID_REACH_MARGIN) / GRID_CELL);
	const int64_t cell_x = gd::floori(static_cast<double>(pos.x) / GRID_CELL);
	const int64_t cell_y = gd::floori(static_cast<double>(pos.y) / GRID_CELL);
	found.clear();
	const int64_t block = wrap_add(wrap_mul(2, span), 1);
	if (span < 0 || span > MAX_REACH_CELLS || wrap_mul(block, block) > grid_cells_) {
		// A reach wider than the field: every occupied cell, an exact superset of the block.
		for (const auto &entry : grid_) {
			found.push_back(entry.second);
		}
	} else {
		for (int64_t offset_x = -span; offset_x <= span; offset_x++) {
			for (int64_t offset_y = -span; offset_y <= span; offset_y++) {
				const int64_t key = grid_key(
						wrap_add(cell_x, offset_x), wrap_add(cell_y, offset_y));
				auto entry = std::lower_bound(
						grid_.begin(), grid_.end(), std::make_pair(key, static_cast<int64_t>(INT64_MIN)));
				for (; entry != grid_.end() && entry->first == key; ++entry) {
					found.push_back(entry->second);
				}
			}
		}
	}
	std::sort(found.begin(), found.end());
}

PackedInt64Array NativeEnemies::living_within(const Vector2 &pos, double reach) {
	std::vector<int64_t> found;
	collect_within(pos, reach, found);
	PackedInt64Array result;
	result.resize(static_cast<int64_t>(found.size()));
	for (size_t index = 0; index < found.size(); index++) {
		result[static_cast<int64_t>(index)] = found[index];
	}
	return result;
}

// target_query.gd nearest_enemy and nearest_enemy_clear: the candidates are living_within's, in
// ascending id; a candidate counts when it is alive, `d2 <= reach * reach` and `d2 < best_d2` (a
// strictly nearer one replaces the best, so the lower id wins a tie), and, with walls standing,
// only when Pathing.first_blocking(pos, there, radius) < 0, tested last so only an improving
// candidate pays for it. The squared distance is real_t as Vector2.distance_squared_to computes it,
// widened to double at the compare.
int64_t NativeEnemies::nearest_living(
		const Vector2 &pos, double reach, double radius, const Ref<NativeWalls> &walls) {
	const bool test_walls = walls.is_valid() && walls->intact_count() > 0;
	std::vector<int64_t> &candidates = candidates_;
	collect_within(pos, reach, candidates);
	int64_t best_id = -1;
	double best_d2 = std::numeric_limits<double>::infinity();
	const double limit = reach * reach;
	for (const int64_t id : candidates) {
		const int64_t slot = slot_of(id);
		if (slot < 0) {
			continue;
		}
		const EnemyRec &rec = recs_[static_cast<size_t>(slot)];
		if (rec.health <= 0) {
			continue;
		}
		const double d2 = static_cast<double>(gd::distance_squared_to(pos, rec.position));
		if (d2 <= limit && d2 < best_d2) {
			if (test_walls && walls->blocking_segment(pos, rec.position, radius) >= 0) {
				continue;
			}
			best_d2 = d2;
			best_id = id;
		}
	}
	return best_id;
}

PackedInt64Array NativeEnemies::view_ids() const {
	return ids();
}

PackedVector2Array NativeEnemies::view_previous() const {
	PackedVector2Array result;
	result.resize(static_cast<int64_t>(recs_.size()));
	for (size_t slot = 0; slot < recs_.size(); slot++) {
		result[static_cast<int64_t>(slot)] = recs_[slot].previous;
	}
	return result;
}

PackedVector2Array NativeEnemies::view_current() const {
	PackedVector2Array result;
	result.resize(static_cast<int64_t>(recs_.size()));
	for (size_t slot = 0; slot < recs_.size(); slot++) {
		result[static_cast<int64_t>(slot)] = recs_[slot].position;
	}
	return result;
}

void NativeEnemies::set_world(
		const Ref<NativeWalls> &walls,
		const Ref<NativeRoute> &route,
		const Ref<NativeWallDecision> &decision,
		const Ref<NativeStructures> &structures) {
	walls_ = walls;
	route_ = route;
	decision_ = decision;
	structures_ = structures;
}

void NativeEnemies::begin_step() {
	for (EnemyRec &rec : recs_) {
		rec.previous = rec.position;
	}
	grid_dirty_ = true;
}
