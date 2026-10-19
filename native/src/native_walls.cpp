#include "native_walls.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>
#include <vector>

#include <godot_cpp/core/class_db.hpp>

#include "gd_math.h"

using namespace godot;

namespace {

// wall_solids.gd MAX_PASSES and REACH_MARGIN.
constexpr int MAX_PASSES = 3;
constexpr double REACH_MARGIN = 0.01;
// wall_system.gd BUCKET_CELL, KEY_OFFSET and KEY_STRIDE.
constexpr double BUCKET_CELL = 4.0;
constexpr int64_t KEY_OFFSET = static_cast<int64_t>(1) << 19;
constexpr int64_t KEY_STRIDE = static_cast<int64_t>(1) << 20;
// A query whose cell range holds more cells than this would never return in the GDScript; only
// then is the range cut to the cells that can hold a segment.
constexpr uint64_t MAX_WALKED_CELLS = static_cast<uint64_t>(1) << 22;

// GDScript int arithmetic wraps on overflow; the port does the same in unsigned arithmetic so a
// pathological coordinate cannot be undefined behaviour and aliases to the same key as before.
int64_t wrap_add(int64_t a, int64_t b) {
	return static_cast<int64_t>(static_cast<uint64_t>(a) + static_cast<uint64_t>(b));
}

int64_t wrap_mul(int64_t a, int64_t b) {
	return static_cast<int64_t>(static_cast<uint64_t>(a) * static_cast<uint64_t>(b));
}

// wall_system.gd _key.
int64_t cell_key(int64_t cell_x, int64_t cell_y) {
	return wrap_add(wrap_mul(wrap_add(cell_x, KEY_OFFSET), KEY_STRIDE), wrap_add(cell_y, KEY_OFFSET));
}

// wall_solids.gd _closest_on: `squared` is a GDScript float (the real_t length_squared widened),
// t is computed in double from the real_t dot, and `along * t` narrows t to real_t.
Vector2 closest_on(const Vector2 &start, const Vector2 &end, const Vector2 &pos) {
	const Vector2 along = end - start;
	const double squared = static_cast<double>(gd::length_squared(along));
	if (squared <= 0.0) {
		return start;
	}
	const double t = gd::clampf(static_cast<double>(gd::dot(pos - start, along)) / squared, 0.0, 1.0);
	return start + along * static_cast<real_t>(t);
}

// wall_solids.gd _point_distance.
double point_distance(const Vector2 &pos, const Vector2 &start, const Vector2 &end) {
	return static_cast<double>(gd::distance_to(pos, closest_on(start, end, pos)));
}

// wall_solids.gd _segments_distance: the cross products are real_t widened to double, the side
// products are double, and the least of the four end-to-segment distances is taken in double.
double segments_distance(const Vector2 &a, const Vector2 &b, const Vector2 &c, const Vector2 &d) {
	const double side_c = static_cast<double>(gd::cross(b - a, c - a));
	const double side_d = static_cast<double>(gd::cross(b - a, d - a));
	const double side_a = static_cast<double>(gd::cross(d - c, a - c));
	const double side_b = static_cast<double>(gd::cross(d - c, b - c));
	if (side_c * side_d < 0.0 && side_a * side_b < 0.0) {
		return 0.0;
	}
	return gd::minf(
			gd::minf(point_distance(a, c, d), point_distance(b, c, d)),
			gd::minf(point_distance(c, a, b), point_distance(d, a, b)));
}

} // namespace

void NativeWalls::_bind_methods() {
	ClassDB::bind_method(D_METHOD("setup", "starts", "ends", "half"), &NativeWalls::setup);
	ClassDB::bind_method(D_METHOD("set_health", "segment", "health"), &NativeWalls::set_health);
	ClassDB::bind_method(D_METHOD("intact_count"), &NativeWalls::intact_count);
	ClassDB::bind_method(D_METHOD("is_intact", "segment"), &NativeWalls::is_intact);
	ClassDB::bind_method(D_METHOD("segments_near", "pos", "reach"), &NativeWalls::segments_near);
	ClassDB::bind_method(
			D_METHOD("first_blocking", "from", "to", "radius"), &NativeWalls::first_blocking);
	ClassDB::bind_method(D_METHOD("push_out", "pos", "radius"), &NativeWalls::push_out);
	ClassDB::bind_method(D_METHOD("closest_point", "segment", "pos"), &NativeWalls::closest_point);
}

void NativeWalls::setup(
		const PackedVector2Array &starts,
		const PackedVector2Array &ends,
		const PackedFloat64Array &half) {
	starts_.clear();
	ends_.clear();
	half_.clear();
	health_.clear();
	buckets_.clear();
	intact_ = 0;
	min_cell_x_ = 0;
	max_cell_x_ = 0;
	min_cell_y_ = 0;
	max_cell_y_ = 0;
	const int64_t count = starts.size();
	if (ends.size() != count || half.size() != count) {
		return;
	}
	bool first_cell = true;
	for (int64_t segment = 0; segment < count; segment++) {
		const Vector2 start = starts[segment];
		const Vector2 end = ends[segment];
		const double thickness = half[segment];
		starts_.push_back(start);
		ends_.push_back(end);
		half_.push_back(thickness);
		health_.push_back(0);
		// wall_system.gd _bucket: the segment goes into every cell its box, inflated by the half
		// thickness, touches; floori runs on doubles.
		const int64_t low_x = gd::floori(
				(gd::minf(static_cast<double>(start.x), static_cast<double>(end.x)) - thickness) /
				BUCKET_CELL);
		const int64_t high_x = gd::floori(
				(gd::maxf(static_cast<double>(start.x), static_cast<double>(end.x)) + thickness) /
				BUCKET_CELL);
		const int64_t low_y = gd::floori(
				(gd::minf(static_cast<double>(start.y), static_cast<double>(end.y)) - thickness) /
				BUCKET_CELL);
		const int64_t high_y = gd::floori(
				(gd::maxf(static_cast<double>(start.y), static_cast<double>(end.y)) + thickness) /
				BUCKET_CELL);
		if (high_x < low_x || high_y < low_y) {
			continue;
		}
		for (int64_t cell_x = low_x;; cell_x++) {
			for (int64_t cell_y = low_y;; cell_y++) {
				buckets_[cell_key(cell_x, cell_y)].push_back(static_cast<int32_t>(segment));
				if (cell_y == high_y) {
					break;
				}
			}
			if (cell_x == high_x) {
				break;
			}
		}
		if (first_cell) {
			min_cell_x_ = low_x;
			max_cell_x_ = high_x;
			min_cell_y_ = low_y;
			max_cell_y_ = high_y;
			first_cell = false;
		} else {
			min_cell_x_ = gd::mini(min_cell_x_, low_x);
			max_cell_x_ = gd::maxi(max_cell_x_, high_x);
			min_cell_y_ = gd::mini(min_cell_y_, low_y);
			max_cell_y_ = gd::maxi(max_cell_y_, high_y);
		}
	}
}

void NativeWalls::set_health(int64_t segment, int64_t health) {
	if (!valid(segment)) {
		return;
	}
	const bool was_intact = health_[static_cast<size_t>(segment)] > 0;
	health_[static_cast<size_t>(segment)] = health;
	const bool now_intact = health > 0;
	if (was_intact && !now_intact) {
		intact_--;
	} else if (!was_intact && now_intact) {
		intact_++;
	}
}

int64_t NativeWalls::intact_count() const {
	return intact_;
}

int64_t NativeWalls::segment_count() const {
	return static_cast<int64_t>(starts_.size());
}

bool NativeWalls::valid(int64_t segment) const {
	return segment >= 0 && segment < static_cast<int64_t>(starts_.size());
}

bool NativeWalls::is_intact(int64_t segment) const {
	return valid(segment) && health_[static_cast<size_t>(segment)] > 0;
}

PackedInt32Array NativeWalls::segments_near(const Vector2 &pos, double reach) const {
	std::vector<int32_t> found;
	near_segments(pos, reach, found);
	PackedInt32Array result;
	result.resize(static_cast<int64_t>(found.size()));
	for (size_t index = 0; index < found.size(); index++) {
		result[static_cast<int64_t>(index)] = found[index];
	}
	return result;
}

// wall_system.gd segments_near.
void NativeWalls::near_segments(const Vector2 &pos, double reach, std::vector<int32_t> &out) const {
	out.clear();
	if (buckets_.empty() || !std::isfinite(reach) || reach < 0.0) {
		return;
	}
	const double x = static_cast<double>(pos.x);
	const double y = static_cast<double>(pos.y);
	int64_t low_x = gd::floori((x - reach) / BUCKET_CELL);
	int64_t high_x = gd::floori((x + reach) / BUCKET_CELL);
	int64_t low_y = gd::floori((y - reach) / BUCKET_CELL);
	int64_t high_y = gd::floori((y + reach) / BUCKET_CELL);
	if (high_x < low_x || high_y < low_y) {
		return;
	}
	const bool several_cells = high_x > low_x || high_y > low_y;
	const uint64_t span_x = static_cast<uint64_t>(high_x) - static_cast<uint64_t>(low_x) + 1;
	const uint64_t span_y = static_cast<uint64_t>(high_y) - static_cast<uint64_t>(low_y) + 1;
	if (span_x > MAX_WALKED_CELLS || span_y > MAX_WALKED_CELLS ||
			span_x * span_y > MAX_WALKED_CELLS) {
		low_x = gd::maxi(low_x, min_cell_x_);
		high_x = gd::mini(high_x, max_cell_x_);
		low_y = gd::maxi(low_y, min_cell_y_);
		high_y = gd::mini(high_y, max_cell_y_);
		if (high_x < low_x || high_y < low_y) {
			return;
		}
	}
	for (int64_t cell_x = low_x;; cell_x++) {
		for (int64_t cell_y = low_y;; cell_y++) {
			const auto bucket = buckets_.find(cell_key(cell_x, cell_y));
			if (bucket != buckets_.end()) {
				out.insert(out.end(), bucket->second.begin(), bucket->second.end());
			}
			if (cell_y == high_y) {
				break;
			}
		}
		if (cell_x == high_x) {
			break;
		}
	}
	if (several_cells) {
		std::sort(out.begin(), out.end());
		out.erase(std::unique(out.begin(), out.end()), out.end());
	}
}

Vector2 NativeWalls::closest_point(int64_t segment, const Vector2 &pos) const {
	return closest_on_segment(segment, pos);
}

// wall_solids.gd closest_point: an index out of range answers the zero vector.
Vector2 NativeWalls::closest_on_segment(int64_t segment, const Vector2 &pos) const {
	if (!valid(segment)) {
		return Vector2(0.0f, 0.0f);
	}
	return closest_on(starts_[static_cast<size_t>(segment)], ends_[static_cast<size_t>(segment)], pos);
}

int64_t NativeWalls::first_blocking(const Vector2 &from, const Vector2 &to, double radius) const {
	return blocking_segment(from, to, radius);
}

// wall_solids.gd first_blocking.
int64_t NativeWalls::blocking_segment(const Vector2 &from, const Vector2 &to, double radius) const {
	if (intact_ == 0) {
		return -1;
	}
	const Vector2 middle = (from + to) * static_cast<real_t>(0.5);
	const double reach = static_cast<double>(gd::distance_to(from, to)) * 0.5 + radius + REACH_MARGIN;
	int64_t best = -1;
	double best_distance = std::numeric_limits<double>::infinity();
	near_segments(middle, reach, scratch_);
	for (const int32_t candidate : scratch_) {
		const size_t segment = static_cast<size_t>(candidate);
		if (health_[segment] <= 0) {
			continue;
		}
		const Vector2 &start = starts_[segment];
		const Vector2 &end = ends_[segment];
		if (segments_distance(from, to, start, end) >= half_[segment] + radius) {
			continue;
		}
		const double distance = static_cast<double>(gd::distance_to(from, closest_on(start, end, from)));
		if (distance < best_distance) {
			best_distance = distance;
			best = candidate;
		}
	}
	return best;
}

Vector2 NativeWalls::push_out(const Vector2 &pos, double radius) const {
	return pushed_position(pos, radius);
}

// wall_solids.gd push_out: the candidates are taken once, at the start.
Vector2 NativeWalls::pushed_position(const Vector2 &pos, double radius) const {
	if (intact_ == 0) {
		return pos;
	}
	Vector2 result = pos;
	near_segments(pos, radius + REACH_MARGIN, scratch_);
	if (scratch_.empty()) {
		return pos;
	}
	for (int pass = 0; pass < MAX_PASSES; pass++) {
		bool moved = false;
		for (const int32_t candidate : scratch_) {
			if (health_[static_cast<size_t>(candidate)] <= 0) {
				continue;
			}
			const Vector2 pushed = pushed_from(candidate, result, radius);
			if (pushed.x != result.x || pushed.y != result.y) {
				result = pushed;
				moved = true;
			}
		}
		if (!moved) {
			break;
		}
	}
	return result;
}

// wall_solids.gd _pushed_from: `pos` moved out of one segment when it overlaps it, else `pos`.
Vector2 NativeWalls::pushed_from(int64_t segment, const Vector2 &pos, double radius) const {
	const size_t index = static_cast<size_t>(segment);
	const Vector2 &start = starts_[index];
	const Vector2 &end = ends_[index];
	const Vector2 nearest = closest_on(start, end, pos);
	const double reach = half_[index] + radius;
	const Vector2 offset = pos - nearest;
	const double squared = static_cast<double>(gd::length_squared(offset));
	if (squared >= reach * reach) {
		return pos;
	}
	if (squared > 0.0) {
		return nearest + offset / static_cast<real_t>(gd::sqrt(squared)) * static_cast<real_t>(reach);
	}
	const Vector2 along = end - start;
	const double length = static_cast<double>(gd::length(along));
	if (length <= 0.0) {
		return nearest + Vector2(1.0f, 0.0f) * static_cast<real_t>(reach);
	}
	return nearest + Vector2(-along.y, along.x) / static_cast<real_t>(length) * static_cast<real_t>(reach);
}
