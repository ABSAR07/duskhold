#include "native_field.h"

#include <cmath>
#include <cstdint>
#include <limits>
#include <vector>

#include <godot_cpp/core/class_db.hpp>

#include "gd_math.h"
#include "native_wall_decision.h"

using namespace godot;

namespace {

// flow_field.gd STEP_ORTHOGONAL and STEP_DIAGONAL, per neighbour index (the four orthogonal
// neighbours first, then the four diagonal ones).
constexpr int32_t STEPS[8] = { 10, 10, 10, 10, 14, 14, 14, 14 };
// flow_field.gd WALL_PENALTY: a blocked or unreached neighbour counts as this much dearer than the
// cell being read, so a direction bends away from walls.
constexpr int64_t WALL_PENALTY = 25;
// flow_field.gd MIN_DIRECTION_LENGTH: a blended direction shorter than this is no direction at all.
constexpr double MIN_DIRECTION_LENGTH = 0.000001;
// flow_field.gd DIAGONAL_UNIT, sqrt(0.5), as the PackedFloat32Array of unit offsets stored it.
constexpr double DIAGONAL_UNIT = 0.7071067811865476;
constexpr float DIAGONAL_UNIT_F = static_cast<float>(DIAGONAL_UNIT);
// flow_field.gd _unit_x and _unit_y: the unit offset of each neighbour (east, west, south, north,
// then the four diagonals), as float32 exactly like the GDScript arrays.
constexpr float UNIT_X[8] = { 1.0f, -1.0f, 0.0f, 0.0f, DIAGONAL_UNIT_F, -DIAGONAL_UNIT_F, DIAGONAL_UNIT_F, -DIAGONAL_UNIT_F };
constexpr float UNIT_Y[8] = { 0.0f, 0.0f, 1.0f, -1.0f, DIAGONAL_UNIT_F, DIAGONAL_UNIT_F, -DIAGONAL_UNIT_F, -DIAGONAL_UNIT_F };
// flow_field.gd STEP_ORTHOGONAL, the divisor of detour_ticks.
constexpr int64_t STEP_ORTHOGONAL = gd::FIELD_STEP_ORTHOGONAL;
// pathing.gd PROBE_STEPS: cells an enemy pressed into a wall's blocked band is stepped back, at
// most, to read its route.
constexpr int PROBE_STEPS = 3;

} // namespace

// --- NativeGrid -------------------------------------------------------------------------------

void NativeGrid::_bind_methods() {
	ClassDB::bind_method(
			D_METHOD("set_layout", "armed", "origin", "cell", "width", "height"),
			&NativeGrid::set_layout);
	ClassDB::bind_method(D_METHOD("set_masks", "blocked", "owner"), &NativeGrid::set_masks);
	ClassDB::bind_method(D_METHOD("is_armed"), &NativeGrid::is_armed);
	ClassDB::bind_method(D_METHOD("is_ready"), &NativeGrid::is_ready);
	ClassDB::bind_method(D_METHOD("width"), &NativeGrid::width);
	ClassDB::bind_method(D_METHOD("height"), &NativeGrid::height);
	ClassDB::bind_method(D_METHOD("cell_size"), &NativeGrid::cell_size);
	ClassDB::bind_method(D_METHOD("origin"), &NativeGrid::origin);
	ClassDB::bind_method(D_METHOD("cell_of", "pos"), &NativeGrid::cell_of);
	ClassDB::bind_method(D_METHOD("is_blocked", "cell"), &NativeGrid::is_blocked);
	ClassDB::bind_method(D_METHOD("is_border", "cell"), &NativeGrid::is_border);
	ClassDB::bind_method(D_METHOD("owner_of", "cell"), &NativeGrid::owner_of);
}

void NativeGrid::set_layout(
		bool armed, const Vector2 &origin, double cell, int64_t width, int64_t height) {
	armed_ = false;
	ready_ = false;
	origin_ = origin;
	cell_ = cell;
	width_ = 0;
	height_ = 0;
	blocked_.clear();
	owner_.clear();
	if (!armed || width <= 0 || height <= 0) {
		return;
	}
	// A cell that cannot divide (zero, negative, NaN, infinite) or a grid whose cell count does not
	// fit the 32-bit mask size the GDScript arrays are bound by (width * height cannot overflow).
	if (!(cell > 0.0) || !std::isfinite(cell) || width > std::numeric_limits<int32_t>::max() / height) {
		return;
	}
	width_ = width;
	height_ = height;
	armed_ = true;
}

void NativeGrid::set_masks(const PackedByteArray &blocked, const PackedInt32Array &owner) {
	if (!armed_) {
		return;
	}
	const int64_t cells = width_ * height_;
	if (blocked.size() != cells || owner.size() != cells) {
		return;
	}
	blocked_.assign(blocked.ptr(), blocked.ptr() + cells);
	owner_.assign(owner.ptr(), owner.ptr() + cells);
	ready_ = true;
}

bool NativeGrid::is_armed() const {
	return armed_;
}

bool NativeGrid::is_ready() const {
	return armed_ && ready_;
}

int64_t NativeGrid::width() const {
	return width_;
}

int64_t NativeGrid::height() const {
	return height_;
}

double NativeGrid::cell_size() const {
	return cell_;
}

Vector2 NativeGrid::origin() const {
	return origin_;
}

// nav_grid.gd cell_of: floori in double of (pos - origin) / cell, border cells included.
int64_t NativeGrid::cell_of(const Vector2 &pos) const {
	if (!armed_) {
		return -1;
	}
	const int64_t cell_x = gd::floori((static_cast<double>(pos.x) - static_cast<double>(origin_.x)) / cell_);
	const int64_t cell_y = gd::floori((static_cast<double>(pos.y) - static_cast<double>(origin_.y)) / cell_);
	if (cell_x < 0 || cell_y < 0 || cell_x >= width_ || cell_y >= height_) {
		return -1;
	}
	return cell_y * width_ + cell_x;
}

// nav_grid.gd is_blocked.
bool NativeGrid::is_blocked(int64_t cell) const {
	return cell < 0 || cell >= static_cast<int64_t>(blocked_.size()) ||
			blocked_[static_cast<size_t>(cell)] != 0;
}

// nav_grid.gd is_border: the GDScript's % and / truncate toward zero, as C++ does.
bool NativeGrid::is_border(int64_t cell) const {
	if (width_ <= 0) {
		return false;
	}
	const int64_t cell_x = cell % width_;
	const int64_t cell_y = cell / width_;
	return cell_x == 0 || cell_y == 0 || cell_x == width_ - 1 || cell_y == height_ - 1;
}

// nav_grid.gd owner_of.
int64_t NativeGrid::owner_of(int64_t cell) const {
	if (cell >= 0 && cell < static_cast<int64_t>(owner_.size())) {
		return owner_[static_cast<size_t>(cell)];
	}
	return -1;
}

// --- NativeField ------------------------------------------------------------------------------

void NativeField::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_costs", "costs", "grid"), &NativeField::set_costs);
	ClassDB::bind_method(D_METHOD("cost_at", "pos"), &NativeField::cost_at);
	ClassDB::bind_method(D_METHOD("is_reached", "pos"), &NativeField::is_reached);
	ClassDB::bind_method(D_METHOD("direction_at", "pos"), &NativeField::direction_at);
}

// flow_field.gd build, after Dial: the arrays are sized to the cost array, the generation moves on
// (the old stamps stay, so every cell is stale) and the neighbour offsets follow the grid's width.
void NativeField::set_costs(const PackedInt32Array &costs, const Ref<NativeGrid> &grid) {
	grid_ = grid;
	const int64_t count = costs.size();
	cost_.assign(costs.ptr(), costs.ptr() + count);
	dir_x_.resize(static_cast<size_t>(count));
	dir_y_.resize(static_cast<size_t>(count));
	stamp_.resize(static_cast<size_t>(count), 0);
	generation_ += 1;
	const int64_t width = grid_.is_valid() ? grid_->width() : 0;
	offsets_[0] = 1;
	offsets_[1] = -1;
	offsets_[2] = width;
	offsets_[3] = -width;
	offsets_[4] = width + 1;
	offsets_[5] = width - 1;
	offsets_[6] = -width + 1;
	offsets_[7] = -width - 1;
}

// The cost of a cell of the array; a cell outside it is unreached.
int64_t NativeField::cost_of(int64_t cell) const {
	if (cell < 0 || cell >= static_cast<int64_t>(cost_.size())) {
		return INF_COST;
	}
	return cost_[static_cast<size_t>(cell)];
}

// flow_field.gd cost_at.
int64_t NativeField::cost_at(const Vector2 &pos) const {
	if (!grid_.is_valid()) {
		return INF_COST;
	}
	const int64_t cell = grid_->cell_of(pos);
	if (cell < 0 || cell >= static_cast<int64_t>(cost_.size())) {
		return INF_COST;
	}
	const int64_t here = cost_[static_cast<size_t>(cell)];
	if (here < INF_COST) {
		return here;
	}
	if (grid_->is_border(cell) || !grid_->is_blocked(cell)) {
		return INF_COST;
	}
	int64_t best = INF_COST;
	for (int index = 0; index < 8; index++) {
		const int64_t next = cost_of(cell + offsets_[index]);
		if (next < INF_COST) {
			best = gd::mini(best, next + STEPS[index]);
		}
	}
	return best;
}

// flow_field.gd is_reached.
bool NativeField::is_reached(const Vector2 &pos) const {
	return cost_at(pos) < INF_COST;
}

// flow_field.gd direction_at: the four surrounding cell directions blended bilinearly and
// normalised; the zero vector when they are all zero.
Vector2 NativeField::direction_at(const Vector2 &pos) const {
	if (!grid_.is_valid() || cost_.empty() || !grid_->is_ready()) {
		return Vector2(0.0f, 0.0f);
	}
	const double size = grid_->cell_size();
	const Vector2 origin = grid_->origin();
	const double fraction_x = (static_cast<double>(pos.x) - static_cast<double>(origin.x)) / size - 0.5;
	const double fraction_y = (static_cast<double>(pos.y) - static_cast<double>(origin.y)) / size - 0.5;
	const int64_t cell_x = gd::floori(fraction_x);
	const int64_t cell_y = gd::floori(fraction_y);
	const double weight_x = fraction_x - static_cast<double>(cell_x);
	const double weight_y = fraction_y - static_cast<double>(cell_y);
	const Vector2 near_edge = gd::lerp(
			cell_direction(cell_x, cell_y), cell_direction(cell_x + 1, cell_y), static_cast<real_t>(weight_x));
	const Vector2 far_edge = gd::lerp(
			cell_direction(cell_x, cell_y + 1),
			cell_direction(cell_x + 1, cell_y + 1),
			static_cast<real_t>(weight_x));
	const Vector2 blended = gd::lerp(near_edge, far_edge, static_cast<real_t>(weight_y));
	const double squared = static_cast<double>(gd::length_squared(blended));
	if (squared <= MIN_DIRECTION_LENGTH * MIN_DIRECTION_LENGTH) {
		return Vector2(0.0f, 0.0f);
	}
	return blended / static_cast<real_t>(gd::sqrt(squared));
}

// flow_field.gd _cell_direction_at: the direction of cell (cell_x, cell_y), zero outside the grid;
// computed on the first ask of the generation and kept.
Vector2 NativeField::cell_direction(int64_t cell_x, int64_t cell_y) const {
	if (cell_x < 0 || cell_y < 0 || cell_x >= grid_->width() || cell_y >= grid_->height()) {
		return Vector2(0.0f, 0.0f);
	}
	const int64_t cell = cell_y * grid_->width() + cell_x;
	if (cell >= static_cast<int64_t>(cost_.size())) {
		return Vector2(0.0f, 0.0f);
	}
	const size_t index = static_cast<size_t>(cell);
	if (static_cast<int64_t>(stamp_[index]) != generation_) {
		compute_direction(cell);
	}
	return Vector2(dir_x_[index], dir_y_[index]);
}

// flow_field.gd _compute_direction: an open reached cell sums the unit offsets of its neighbours
// weighted by how much cheaper they are; a blocked cell points at its cheapest open neighbour; the
// border and unreached cells have none. The blocked mask is the grid's live one.
void NativeField::compute_direction(int64_t cell) const {
	const size_t index = static_cast<size_t>(cell);
	stamp_[index] = static_cast<int32_t>(generation_);
	dir_x_[index] = 0.0f;
	dir_y_[index] = 0.0f;
	if (grid_->is_border(cell)) {
		return;
	}
	const int64_t here = cost_[index];
	if (grid_->is_blocked(cell)) {
		point_at_cheapest(cell);
		return;
	}
	if (here >= INF_COST) {
		return;
	}
	double sum_x = 0.0;
	double sum_y = 0.0;
	for (int step = 0; step < 8; step++) {
		const int64_t next = cell + offsets_[step];
		int64_t next_cost = here + WALL_PENALTY;
		if (!grid_->is_blocked(next) && cost_of(next) < INF_COST) {
			next_cost = cost_of(next);
		}
		const double gain = static_cast<double>(here - next_cost);
		sum_x += static_cast<double>(UNIT_X[step]) * gain;
		sum_y += static_cast<double>(UNIT_Y[step]) * gain;
	}
	const double squared = sum_x * sum_x + sum_y * sum_y;
	if (squared <= 0.0) {
		return;
	}
	const double length = gd::sqrt(squared);
	dir_x_[index] = static_cast<float>(sum_x / length);
	dir_y_[index] = static_cast<float>(sum_y / length);
}

// flow_field.gd _point_at_cheapest: a blocked cell points at its cheapest reached neighbour (the
// first in neighbour order on a tie).
void NativeField::point_at_cheapest(int64_t cell) const {
	const size_t index = static_cast<size_t>(cell);
	int64_t best = INF_COST;
	int best_step = -1;
	for (int step = 0; step < 8; step++) {
		const int64_t next_cost = cost_of(cell + offsets_[step]);
		if (next_cost < best) {
			best = next_cost;
			best_step = step;
		}
	}
	if (best_step >= 0) {
		dir_x_[index] = UNIT_X[best_step];
		dir_y_[index] = UNIT_Y[best_step];
	}
}

// --- NativeRoute ------------------------------------------------------------------------------

void NativeRoute::_bind_methods() {
	ClassDB::bind_method(
			D_METHOD("set_world", "grid", "walls", "castle", "tuning_cell_size"),
			&NativeRoute::set_world);
	ClassDB::bind_method(D_METHOD("set_castle_field", "field"), &NativeRoute::set_castle_field);
	ClassDB::bind_method(D_METHOD("is_sealed", "pos"), &NativeRoute::is_sealed);
	ClassDB::bind_method(D_METHOD("castle_cost_at", "pos"), &NativeRoute::castle_cost_at);
	ClassDB::bind_method(D_METHOD("castle_distance_cm", "pos"), &NativeRoute::castle_distance_cm);
	ClassDB::bind_method(
			D_METHOD("detour_ticks", "pos", "speed_cm_per_s"), &NativeRoute::detour_ticks);
	ClassDB::bind_method(
			D_METHOD("straight_ticks", "pos", "speed_cm_per_s"), &NativeRoute::straight_ticks);
	ClassDB::bind_method(D_METHOD("march_step", "pos", "max_distance"), &NativeRoute::march_step);
	ClassDB::bind_method(D_METHOD("probe_of", "pos"), &NativeRoute::probe_of);
	ClassDB::bind_method(D_METHOD("has_intact_walls"), &NativeRoute::has_intact_walls);
}

void NativeRoute::set_world(
		const Ref<NativeGrid> &grid,
		const Ref<NativeWalls> &walls,
		const Vector2 &castle,
		double tuning_cell_size) {
	grid_ = grid;
	walls_ = walls;
	castle_ = castle;
	tuning_cell_size_ = tuning_cell_size;
}

void NativeRoute::set_castle_field(const Ref<NativeField> &field) {
	field_ = field;
}

// pathing.gd has_intact_walls: walls exist and at least one segment stands.
bool NativeRoute::has_intact_walls() const {
	return walls_.is_valid() && walls_->intact_count() > 0;
}

// pathing.gd is_sealed: true while walls stand and no route is known from `pos` to the castle. The
// open review item WR-03 (an enemy outside the grid reads unreached, so counts as sealed) is ported
// unchanged on purpose: fixing it would move a digest.
bool NativeRoute::is_sealed(const Vector2 &pos) const {
	if (!has_intact_walls()) {
		return false;
	}
	return !field_.is_valid() || !field_->is_reached(probe_of(pos));
}

// pathing.gd castle_cost_at.
int64_t NativeRoute::castle_cost_at(const Vector2 &pos) const {
	return field_.is_valid() ? field_->cost_at(pos) : NativeField::INF_COST;
}

// pathing.gd castle_distance_cm: the straight distance to the castle's centre in whole centimetres.
int64_t NativeRoute::castle_distance_cm(const Vector2 &pos) const {
	return gd::roundi(static_cast<double>(gd::distance_to(pos, castle_)) * 100.0);
}

// pathing.gd detour_ticks: ticks to walk the castle field's route, rounded up; MAX_TICKS when there
// is none.
int64_t NativeRoute::detour_ticks(const Vector2 &pos, int64_t speed_cm_per_s) const {
	const Vector2 probe = probe_of(pos);
	const int64_t cost = castle_cost_at(probe);
	if (cost >= NativeField::INF_COST) {
		return gd::SIM_MAX_TICKS;
	}
	const int64_t distance_cm = gd::wrap_mul(cost, gd::roundi(tuning_cell_size_ * 100.0)) / STEP_ORTHOGONAL;
	return NativeWallDecision::walk_ticks(
			gd::wrap_add(distance_cm, gd::roundi(static_cast<double>(gd::distance_to(pos, probe)) * 100.0)),
			speed_cm_per_s);
}

// pathing.gd straight_ticks.
int64_t NativeRoute::straight_ticks(const Vector2 &pos, int64_t speed_cm_per_s) const {
	return NativeWallDecision::walk_ticks(castle_distance_cm(pos), speed_cm_per_s);
}

// pathing.gd march_step: the field direction, or the exact straight step of
// EnemySystem.desired_step (pos.move_toward(goal, maxf(max_distance, 0.0)) - pos) when there is no
// field or no direction there.
Vector2 NativeRoute::march_step(const Vector2 &pos, double max_distance) const {
	const real_t reach = static_cast<real_t>(gd::maxf(max_distance, 0.0));
	if (field_.is_valid()) {
		const Vector2 direction = field_->direction_at(pos);
		if (!(direction.x == 0.0f && direction.y == 0.0f)) {
			return direction * reach;
		}
	}
	return gd::move_toward(pos, castle_, reach) - pos;
}

// pathing.gd _probe_of: where to read the route of an enemy at `pos`. A position in a blocked cell
// is stepped away from the segment that blocks it, a cell at a time, onto its own side; an open
// position, and a grid that is not ready, read where they stand.
Vector2 NativeRoute::probe_of(const Vector2 &pos) const {
	if (!field_.is_valid() || !grid_.is_valid() || !grid_->is_ready()) {
		return pos;
	}
	Vector2 probe = pos;
	for (int attempt = 0; attempt < PROBE_STEPS; attempt++) {
		const int64_t cell = grid_->cell_of(probe);
		if (cell < 0 || !grid_->is_blocked(cell)) {
			return probe;
		}
		const int64_t segment = grid_->owner_of(cell);
		if (segment < 0) {
			return probe;
		}
		const Vector2 nearest = walls_.is_valid() ? walls_->closest_on_segment(segment, probe) : Vector2(0.0f, 0.0f);
		const Vector2 away = probe - nearest;
		if (static_cast<double>(gd::length_squared(away)) <= 0.0) {
			return probe;
		}
		probe = probe + gd::normalized(away) * static_cast<real_t>(grid_->cell_size());
	}
	return probe;
}
