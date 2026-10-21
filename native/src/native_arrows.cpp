#include "native_arrows.h"

#include <algorithm>
#include <cstdint>

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/basis.hpp>

#include "gd_math.h"

using namespace godot;

void NativeArrows::_bind_methods() {
	ClassDB::bind_method(
			D_METHOD("configure", "capacity", "arc_per_metre", "max_arc_height", "heading_step", "unit_height"),
			&NativeArrows::configure);
	ClassDB::bind_method(D_METHOD("set_mirror", "mirror", "layout"), &NativeArrows::set_mirror);
	ClassDB::bind_method(
			D_METHOD("launch", "origin", "target", "duration", "target_code", "target_id", "color"),
			&NativeArrows::launch);
	ClassDB::bind_method(
			D_METHOD("fill", "delta", "king_ground", "enemy_ids", "enemy_current", "enemy_living"),
			&NativeArrows::fill);
	ClassDB::bind_method(D_METHOD("mirror"), &NativeArrows::mirror);
	ClassDB::bind_method(D_METHOD("count"), &NativeArrows::count);
	ClassDB::bind_method(D_METHOD("live_count"), &NativeArrows::live_count);
	ClassDB::bind_method(D_METHOD("unit_flights"), &NativeArrows::unit_flights);
	ClassDB::bind_method(D_METHOD("drawn_launch", "index"), &NativeArrows::drawn_launch);
	ClassDB::bind_method(D_METHOD("slots_targeting", "target_code"), &NativeArrows::slots_targeting);
	ClassDB::bind_method(D_METHOD("target_id_at", "slot"), &NativeArrows::target_id_at);
	ClassDB::bind_method(D_METHOD("target_at", "slot"), &NativeArrows::target_at);
	ClassDB::bind_method(D_METHOD("set_target", "slot", "target"), &NativeArrows::set_target);

	ClassDB::bind_static_method(
			"NativeArrows",
			D_METHOD("arc_height", "t", "distance", "arc_per_metre", "max_arc_height"),
			&NativeArrows::arc_height);
	ClassDB::bind_static_method(
			"NativeArrows",
			D_METHOD(
					"arrow_transform",
					"origin",
					"target",
					"t",
					"arc_per_metre",
					"max_arc_height",
					"heading_step"),
			&NativeArrows::arrow_transform);

	BIND_CONSTANT(TARGET_FIXED);
	BIND_CONSTANT(TARGET_ENEMY);
	BIND_CONSTANT(TARGET_UNIT);
	BIND_CONSTANT(TARGET_KING);
}

void NativeArrows::configure(
		int64_t capacity,
		double arc_per_metre,
		double max_arc_height,
		double heading_step,
		double unit_height) {
	arc_per_metre_ = arc_per_metre;
	max_arc_height_ = max_arc_height;
	heading_step_ = heading_step;
	unit_height_ = unit_height;
	cursor_ = 0;
	live_ = 0;
	unit_live_ = 0;
	count_ = 0;
	origins_.clear();
	targets_.clear();
	elapsed_.clear();
	durations_.clear();
	target_ids_.clear();
	target_codes_.clear();
	colors_.clear();
	active_.clear();
	drawn_launches_.clear();
	if (capacity < 1 || capacity > MAX_CAPACITY) {
		return;
	}
	const size_t slots = static_cast<size_t>(capacity);
	origins_.resize(slots);
	targets_.resize(slots);
	elapsed_.assign(slots, 0.0f);
	durations_.assign(slots, 0.0f);
	target_ids_.assign(slots, 0);
	target_codes_.assign(slots, TARGET_FIXED);
	colors_.resize(slots);
	active_.assign(slots, 0);
	drawn_launches_.resize(slots);
}

bool NativeArrows::set_mirror(const PackedFloat32Array &mirror, const PackedInt64Array &layout) {
	duskhold::MirrorLayout parsed;
	if (!duskhold::layout_from(layout, mirror.size(), parsed)) {
		return false;
	}
	mirror_ = mirror;
	layout_ = parsed;
	mirror_ready_ = true;
	return true;
}

bool NativeArrows::in_flight(int64_t slot) const {
	return slot >= 0 && slot < static_cast<int64_t>(active_.size()) &&
			active_[static_cast<size_t>(slot)] != 0;
}

int64_t NativeArrows::launch(
		const Vector3 &origin,
		const Vector3 &target,
		double duration,
		int64_t target_code,
		int64_t target_id,
		const Color &color) {
	const int64_t capacity = static_cast<int64_t>(active_.size());
	for (int64_t step = 0; step < capacity; step++) {
		const int64_t slot = (cursor_ + step) % capacity;
		const size_t at = static_cast<size_t>(slot);
		if (active_[at] != 0) {
			continue;
		}
		cursor_ = (slot + 1) % capacity;
		origins_[at] = origin;
		targets_[at] = target;
		elapsed_[at] = 0.0f;
		durations_[at] = static_cast<float>(duration);
		target_ids_[at] = static_cast<int32_t>(target_id);
		target_codes_[at] =
				(target_code >= TARGET_FIXED && target_code <= TARGET_KING) ? static_cast<int32_t>(target_code)
																			 : static_cast<int32_t>(TARGET_FIXED);
		colors_[at] = color;
		active_[at] = 1;
		live_++;
		if (target_codes_[at] == TARGET_UNIT) {
			unit_live_++;
		}
		return slot;
	}
	return -1;
}

int64_t NativeArrows::fill(
		double delta,
		const Vector2 &king_ground,
		const PackedInt64Array &enemy_ids,
		const PackedVector2Array &enemy_current,
		const PackedByteArray &enemy_living) {
	// CrowdBatch.begin(): no instance is held until one is written.
	count_ = 0;
	if (!mirror_ready_ || active_.empty()) {
		return 0;
	}
	const int64_t enemy_total = enemy_ids.size();
	const bool enemies_usable = enemy_current.size() == enemy_total && enemy_living.size() == enemy_total;
	const int64_t *ids = enemy_ids.ptr();
	const Vector2 *current = enemy_current.ptr();
	const uint8_t *living = enemy_living.ptr();
	const real_t height = static_cast<real_t>(unit_height_);
	float *buffer = mirror_.ptrw();
	const Color no_custom = Color(0.0f, 0.0f, 0.0f, 0.0f);
	const size_t slots = active_.size();

	for (size_t slot = 0; slot < slots; slot++) {
		if (active_[slot] == 0) {
			continue;
		}
		elapsed_[slot] = static_cast<float>(static_cast<double>(elapsed_[slot]) + delta);
		const int32_t code = target_codes_[slot];
		if (code == TARGET_ENEMY) {
			if (enemies_usable) {
				const int64_t wanted = static_cast<int64_t>(target_ids_[slot]);
				const int64_t *found = std::lower_bound(ids, ids + enemy_total, wanted);
				if (found != ids + enemy_total && *found == wanted) {
					const int64_t at = found - ids;
					if (living[at] != 0) {
						targets_[slot] = Vector3(current[at].x, height, current[at].y);
					}
				}
			}
		} else if (code == TARGET_KING) {
			targets_[slot] = Vector3(king_ground.x, height, king_ground.y);
		}
		const double t = gd::clampf(
				static_cast<double>(elapsed_[slot]) / static_cast<double>(durations_[slot]), 0.0, 1.0);
		const Pose pose = pose_of(
				origins_[slot], targets_[slot], t, arc_per_metre_, max_arc_height_, heading_step_);
		if (count_ < layout_.capacity) {
			duskhold::write_transform(
					buffer,
					layout_,
					count_,
					pose.x_axis,
					pose.y_axis,
					pose.z_axis,
					pose.position,
					no_custom,
					colors_[slot]);
			drawn_launches_[static_cast<size_t>(count_)] = origins_[slot];
			count_++;
		}
		if (t >= 1.0) {
			active_[slot] = 0;
			live_--;
			if (code == TARGET_UNIT) {
				unit_live_--;
			}
		}
	}
	return count_;
}

PackedFloat32Array NativeArrows::mirror() const {
	return mirror_;
}

int64_t NativeArrows::count() const {
	return count_;
}

int64_t NativeArrows::live_count() const {
	return live_;
}

int64_t NativeArrows::unit_flights() const {
	return unit_live_;
}

Vector3 NativeArrows::drawn_launch(int64_t index) const {
	if (index < 0 || index >= count_) {
		return Vector3(0.0f, 0.0f, 0.0f);
	}
	return drawn_launches_[static_cast<size_t>(index)];
}

PackedInt32Array NativeArrows::slots_targeting(int64_t target_code) const {
	PackedInt32Array result;
	for (size_t slot = 0; slot < active_.size(); slot++) {
		if (active_[slot] != 0 && static_cast<int64_t>(target_codes_[slot]) == target_code) {
			result.append(static_cast<int32_t>(slot));
		}
	}
	return result;
}

int64_t NativeArrows::target_id_at(int64_t slot) const {
	if (!in_flight(slot)) {
		return -1;
	}
	return static_cast<int64_t>(target_ids_[static_cast<size_t>(slot)]);
}

Vector3 NativeArrows::target_at(int64_t slot) const {
	if (!in_flight(slot)) {
		return Vector3(0.0f, 0.0f, 0.0f);
	}
	return targets_[static_cast<size_t>(slot)];
}

void NativeArrows::set_target(int64_t slot, const Vector3 &target) {
	if (!in_flight(slot)) {
		return;
	}
	targets_[static_cast<size_t>(slot)] = target;
}

// ProjectileVfx.arc_height: "if t <= 0.0 or t >= 1.0: return 0.0; var peak: float =
// minf(maxf(distance, 0.0) * ARC_PER_METRE, MAX_ARC_HEIGHT); return 4.0 * t * (1.0 - t) * peak".
double NativeArrows::arc_height(
		double t, double distance, double arc_per_metre, double max_arc_height) {
	if (t <= 0.0 || t >= 1.0) {
		return 0.0;
	}
	const double peak = gd::minf(gd::maxf(distance, 0.0) * arc_per_metre, max_arc_height);
	return 4.0 * t * (1.0 - t) * peak;
}

// ProjectileVfx._path_point: "origin.lerp(target, t) + Vector3.UP * arc_height(t, distance)", the
// lerp weight and the arc height narrowed to real_t at the operators.
Vector3 NativeArrows::path_point(
		const Vector3 &origin,
		const Vector3 &target,
		double t,
		double distance,
		double arc_per_metre,
		double max_arc_height) {
	const Vector3 line = gd::lerp(origin, target, static_cast<real_t>(t));
	const Vector3 arc =
			Vector3(0.0f, 1.0f, 0.0f) * static_cast<real_t>(arc_height(t, distance, arc_per_metre, max_arc_height));
	return line + arc;
}

// ProjectileVfx.arrow_transform, line by line.
NativeArrows::Pose NativeArrows::pose_of(
		const Vector3 &origin,
		const Vector3 &target,
		double t,
		double arc_per_metre,
		double max_arc_height,
		double heading_step) {
	const double progress = gd::clampf(t, 0.0, 1.0);
	const double distance = static_cast<double>(gd::distance_to(origin, target));
	const Vector3 here = path_point(origin, target, progress, distance, arc_per_metre, max_arc_height);
	const Vector3 behind = path_point(
			origin,
			target,
			gd::maxf(progress - heading_step, 0.0),
			distance,
			arc_per_metre,
			max_arc_height);
	const Vector3 ahead = path_point(
			origin,
			target,
			gd::minf(progress + heading_step, 1.0),
			distance,
			arc_per_metre,
			max_arc_height);
	Vector3 heading = ahead - behind;
	if (static_cast<double>(gd::length(heading)) < 0.0001) {
		heading = target - origin;
	}
	Pose pose;
	pose.position = here;
	if (static_cast<double>(gd::length(heading)) < 0.0001) {
		pose.x_axis = Vector3(1.0f, 0.0f, 0.0f);
		pose.y_axis = Vector3(0.0f, 1.0f, 0.0f);
		pose.z_axis = Vector3(0.0f, 0.0f, 1.0f);
		return pose;
	}
	const Vector3 forward = gd::normalized(heading);
	Vector3 across = gd::cross(Vector3(0.0f, 1.0f, 0.0f), forward);
	across = static_cast<double>(gd::length(across)) > 0.001 ? gd::normalized(across) : Vector3(1.0f, 0.0f, 0.0f);
	const Vector3 upright = gd::cross(forward, across);
	pose.x_axis = across;
	pose.y_axis = upright;
	pose.z_axis = forward;
	return pose;
}

Transform3D NativeArrows::arrow_transform(
		const Vector3 &origin,
		const Vector3 &target,
		double t,
		double arc_per_metre,
		double max_arc_height,
		double heading_step) {
	const Pose pose = pose_of(origin, target, t, arc_per_metre, max_arc_height, heading_step);
	return Transform3D(Basis(pose.x_axis, pose.y_axis, pose.z_axis), pose.position);
}
