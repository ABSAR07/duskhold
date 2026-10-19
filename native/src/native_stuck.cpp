#include "native_stuck.h"

#include <cstdint>
#include <vector>

#include <godot_cpp/core/class_db.hpp>

#include "gd_math.h"

using namespace godot;

void NativeStuck::_bind_methods() {
	ClassDB::bind_method(
			D_METHOD("configure", "stuck_seconds", "stuck_progress_m", "cell_size", "castle"),
			&NativeStuck::configure);
	ClassDB::bind_method(
			D_METHOD("update", "tick", "ids", "targeted", "living", "current", "field"),
			&NativeStuck::update);
	ClassDB::bind_method(D_METHOD("clear"), &NativeStuck::clear);
	ClassDB::bind_method(D_METHOD("is_stuck", "id"), &NativeStuck::is_stuck);
	ClassDB::bind_method(D_METHOD("stuck_count"), &NativeStuck::stuck_count);
	ClassDB::bind_method(D_METHOD("stuck_ids"), &NativeStuck::stuck_ids);
	ClassDB::bind_method(D_METHOD("streak_of", "id"), &NativeStuck::streak_of);
	ClassDB::bind_method(D_METHOD("longest_streak_ticks"), &NativeStuck::longest_streak_ticks);
	ClassDB::bind_method(D_METHOD("threshold_ticks"), &NativeStuck::threshold_ticks);
}

// stuck_tracker.gd _init, with SimClock.ticks as gd::sim_ticks and the two roundi expressions
// written in the GDScript's order: stuck_progress_m * float(STEP_ORTHOGONAL) / cell_size, then
// stuck_progress_m * 100.0.
void NativeStuck::configure(
		double stuck_seconds, double stuck_progress_m, double cell_size, const Vector2 &castle) {
	threshold_ticks_ = gd::maxi(gd::sim_ticks(stuck_seconds), 1);
	needed_cost_ = gd::maxi(
			gd::roundi(stuck_progress_m * static_cast<double>(STEP_ORTHOGONAL) / cell_size), 1);
	needed_cm_ = gd::maxi(gd::roundi(stuck_progress_m * 100.0), 1);
	castle_ = castle;
	clear();
}

void NativeStuck::update(
		int64_t tick,
		const PackedInt64Array &ids,
		const PackedByteArray &targeted,
		const PackedByteArray &living,
		const PackedVector2Array &current,
		const Ref<NativeField> &field) {
	stuck_.clear();
	int64_t count = ids.size();
	if (targeted.size() != count || living.size() != count || current.size() != count) {
		count = 0;
	}
	int64_t seen = 0;
	for (int64_t index = 0; index < count; index++) {
		if (living[index] == 0) {
			continue;
		}
		seen++;
		const int64_t id = ids[index];
		Entry &entry = entries_[id];
		entry.stamp = tick;
		observe(entry, targeted[index] != 0, current[index], field);
		longest_ = gd::maxi(longest_, entry.streak);
		if (entry.streak >= threshold_ticks_) {
			stuck_.push_back(id);
		}
	}
	if (static_cast<int64_t>(entries_.size()) > seen) {
		forget_unseen(tick);
	}
}

void NativeStuck::clear() {
	entries_.clear();
	stuck_.clear();
	longest_ = 0;
}

bool NativeStuck::is_stuck(int64_t id) const {
	const auto found = entries_.find(id);
	return found != entries_.end() && found->second.streak >= threshold_ticks_;
}

int64_t NativeStuck::stuck_count() const {
	return static_cast<int64_t>(stuck_.size());
}

PackedInt64Array NativeStuck::stuck_ids() const {
	PackedInt64Array result;
	result.resize(static_cast<int64_t>(stuck_.size()));
	for (size_t index = 0; index < stuck_.size(); index++) {
		result[static_cast<int64_t>(index)] = stuck_[index];
	}
	return result;
}

int64_t NativeStuck::streak_of(int64_t id) const {
	const auto found = entries_.find(id);
	return found != entries_.end() ? found->second.streak : 0;
}

int64_t NativeStuck::longest_streak_ticks() const {
	return longest_;
}

int64_t NativeStuck::threshold_ticks() const {
	return threshold_ticks_;
}

// stuck_tracker.gd _observe: Pathing.castle_cost_at is the field's cost (INF_COST while no field
// exists) and Pathing.castle_distance_cm the straight distance to the castle in whole centimetres.
void NativeStuck::observe(
		Entry &entry, bool has_target, const Vector2 &position, const Ref<NativeField> &field) {
	if (has_target) {
		entry.streak = 0;
		entry.unit = -1;
		return;
	}
	int64_t progress = field.is_valid() ? field->cost_at(position) : NativeField::INF_COST;
	int32_t unit = UNIT_FIELD_COST;
	int64_t needed = needed_cost_;
	if (progress >= NativeField::INF_COST) {
		progress = gd::roundi(static_cast<double>(gd::distance_to(position, castle_)) * 100.0);
		unit = UNIT_CENTIMETRES;
		needed = needed_cm_;
	}
	if (entry.unit != unit) {
		entry.unit = unit;
		entry.best = progress;
		entry.streak = 1;
	} else if (progress <= entry.best - needed) {
		entry.best = progress;
		entry.streak = 0;
	} else {
		entry.streak += 1;
	}
}

// stuck_tracker.gd _forget_unseen: every entry not stamped by this update goes.
void NativeStuck::forget_unseen(int64_t tick) {
	for (auto entry = entries_.begin(); entry != entries_.end();) {
		if (entry->second.stamp != tick) {
			entry = entries_.erase(entry);
		} else {
			++entry;
		}
	}
}
