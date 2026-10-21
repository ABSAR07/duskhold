#include "native_wall_decision.h"

#include <cstdint>

#include <godot_cpp/core/class_db.hpp>

#include "gd_math.h"

using namespace godot;

void NativeWallDecision::_bind_methods() {
	ClassDB::bind_method(
			D_METHOD(
					"setup",
					"walls",
					"cadence",
					"span",
					"hysteresis",
					"notice",
					"run_first",
					"run_last"),
			&NativeWallDecision::setup);
	ClassDB::bind_method(D_METHOD("begin_tick", "tick"), &NativeWallDecision::begin_tick);
	ClassDB::bind_method(
			D_METHOD("add_attacker", "segment", "per_300"), &NativeWallDecision::add_attacker);
	ClassDB::bind_method(D_METHOD("end_tick"), &NativeWallDecision::end_tick);
	ClassDB::bind_method(D_METHOD("ttd_of", "segment"), &NativeWallDecision::ttd_of);
	ClassDB::bind_method(D_METHOD("evaluated_count"), &NativeWallDecision::evaluated_count);
	ClassDB::bind_method(D_METHOD("hysteresis_ticks"), &NativeWallDecision::hysteresis_ticks);
	ClassDB::bind_method(D_METHOD("notice_range"), &NativeWallDecision::notice_range);
}

// wall_decision.gd _init: the arrays start at never and zero.
void NativeWallDecision::setup(
		const Ref<NativeWalls> &walls,
		int64_t cadence,
		int64_t span,
		int64_t hysteresis,
		double notice,
		const PackedInt32Array &run_first,
		const PackedInt32Array &run_last) {
	walls_ = walls;
	cadence_ = gd::maxi(cadence, 1);
	span_ = gd::maxi(span, 0);
	hysteresis_ = hysteresis;
	notice_ = notice;
	tick_ = 0;
	evaluated_ = 0;
	ttd_.clear();
	sums_.clear();
	run_first_.clear();
	run_last_.clear();
	const int64_t count = run_first.size();
	if (run_last.size() != count) {
		return;
	}
	ttd_.assign(static_cast<size_t>(count), static_cast<int32_t>(MAX_TICKS));
	sums_.assign(static_cast<size_t>(count), 0);
	for (int64_t segment = 0; segment < count; segment++) {
		run_first_.push_back(run_first[segment]);
		run_last_.push_back(run_last[segment]);
	}
}

// wall_decision.gd _first_due: posmod(-tick, cadence).
int64_t NativeWallDecision::first_due() const {
	return gd::posmod(gd::wrap_neg(tick_), cadence_);
}

// wall_decision.gd begin_tick: forgets the sums of the segments due on this tick.
void NativeWallDecision::begin_tick(int64_t tick) {
	tick_ = tick;
	evaluated_ = 0;
	const int64_t size = static_cast<int64_t>(sums_.size());
	for (int64_t segment = first_due(); segment < size; segment += cadence_) {
		sums_[static_cast<size_t>(segment)] = 0;
	}
}

// wall_decision.gd add_attacker: adds to the segment and to every segment of the same run within
// the neighbour span that is due this tick.
void NativeWallDecision::add_attacker(int64_t segment, int64_t per_300) {
	const int64_t size = static_cast<int64_t>(sums_.size());
	if (segment < 0 || segment >= size || per_300 <= 0) {
		return;
	}
	const size_t at = static_cast<size_t>(segment);
	const int64_t low = gd::maxi(gd::wrap_add(segment, gd::wrap_neg(span_)), run_first_[at]);
	const int64_t high = gd::mini(gd::wrap_add(segment, span_), run_last_[at]);
	for (int64_t near = low; near <= high; near++) {
		if (near < 0 || near >= size) {
			continue;
		}
		if (gd::wrap_add(tick_, near) % cadence_ == 0) {
			sums_[static_cast<size_t>(near)] = gd::wrap_add(sums_[static_cast<size_t>(near)], per_300);
		}
	}
}

// wall_decision.gd end_tick: publishes the time to destruction of every due segment from its
// current health, and never for a due segment nobody is aggroed near.
void NativeWallDecision::end_tick() {
	const int64_t size = static_cast<int64_t>(sums_.size());
	for (int64_t segment = first_due(); segment < size; segment += cadence_) {
		const size_t at = static_cast<size_t>(segment);
		if (sums_[at] > 0) {
			const int64_t health = walls_.is_valid() ? walls_->health_of(segment) : 0;
			ttd_[at] = static_cast<int32_t>(ttd_ticks(health, sums_[at]));
			evaluated_++;
		} else {
			ttd_[at] = static_cast<int32_t>(MAX_TICKS);
		}
	}
}

int64_t NativeWallDecision::ttd_of(int64_t segment) const {
	if (segment < 0 || segment >= static_cast<int64_t>(ttd_.size())) {
		return MAX_TICKS;
	}
	return ttd_[static_cast<size_t>(segment)];
}

int64_t NativeWallDecision::evaluated_count() const {
	return evaluated_;
}

int64_t NativeWallDecision::hysteresis_ticks() const {
	return hysteresis_;
}

double NativeWallDecision::notice_range() const {
	return notice_;
}

// wall_decision.gd damage_per_300: attack_damage * 300 / maxi(interval_ticks, 1), integer division.
int64_t NativeWallDecision::damage_per_300(int64_t attack_damage, int64_t interval_ticks) {
	return gd::wrap_mul(attack_damage, 300) / gd::maxi(interval_ticks, 1);
}

// wall_decision.gd ttd_ticks: rounded up; never when nothing deals damage.
int64_t NativeWallDecision::ttd_ticks(int64_t health, int64_t sum_per_300) {
	if (sum_per_300 <= 0) {
		return MAX_TICKS;
	}
	const int64_t numerator =
			gd::wrap_add(gd::wrap_add(gd::wrap_mul(gd::maxi(health, 0), 300), sum_per_300), -1);
	return gd::mini(numerator / sum_per_300, MAX_TICKS);
}

// wall_decision.gd walk_ticks: rounded up; never for a speed of 0 or less.
int64_t NativeWallDecision::walk_ticks(int64_t distance_cm, int64_t speed_cm_per_s) {
	if (speed_cm_per_s <= 0) {
		return MAX_TICKS;
	}
	const int64_t numerator =
			gd::wrap_add(gd::wrap_add(gd::wrap_mul(gd::maxi(distance_cm, 0), 30), speed_cm_per_s), -1);
	return gd::mini(numerator / speed_cm_per_s, MAX_TICKS);
}

// wall_decision.gd should_break: strictly faster than the detour, or no detour at all.
bool NativeWallDecision::should_break(int64_t ttd, int64_t straight_ticks, int64_t detour_ticks) {
	if (detour_ticks >= MAX_TICKS) {
		return true;
	}
	return gd::mini(gd::wrap_add(ttd, straight_ticks), MAX_TICKS) < detour_ticks;
}

// wall_decision.gd keep_breaking: until the detour wins by more than the hysteresis.
bool NativeWallDecision::keep_breaking(
		int64_t ttd, int64_t straight_ticks, int64_t detour_ticks, int64_t hysteresis) {
	if (detour_ticks >= MAX_TICKS) {
		return true;
	}
	return !(gd::wrap_add(detour_ticks, hysteresis) <
			gd::mini(gd::wrap_add(ttd, straight_ticks), MAX_TICKS));
}
