#include "native_structures.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>
#include <vector>

#include <godot_cpp/core/class_db.hpp>

#include "cell_key.h"
#include "gd_math.h"

using namespace godot;

namespace {

// A block of cells wider than this many cells per side is never walked: every candidate is tested.
constexpr double MAX_REACH_CELLS = 1.0e6;

} // namespace

void NativeStructures::_bind_methods() {
	ClassDB::bind_method(
			D_METHOD(
					"rebuild",
					"unit_ids",
					"unit_positions",
					"unit_radii",
					"building_indices",
					"building_centres",
					"building_radii",
					"castle_position",
					"castle_radius"),
			&NativeStructures::rebuild);
	ClassDB::bind_method(D_METHOD("nearest", "pos", "aggro_range"), &NativeStructures::nearest);
	ClassDB::bind_method(
			D_METHOD("nearest_visible", "pos", "aggro_range", "walls", "radius", "ranged_reach"),
			&NativeStructures::nearest_visible);
	ClassDB::bind_method(
			D_METHOD("nearest_through_walls", "pos", "aggro_range"),
			&NativeStructures::nearest_through_walls);
	ClassDB::bind_method(D_METHOD("unit_position", "id"), &NativeStructures::unit_position);
	ClassDB::bind_method(D_METHOD("unit_radius", "id"), &NativeStructures::unit_radius);
	ClassDB::bind_method(D_METHOD("has_unit", "id"), &NativeStructures::has_unit);
	ClassDB::bind_method(
			D_METHOD("building_centre", "spot_index"), &NativeStructures::building_centre);
	ClassDB::bind_method(
			D_METHOD("building_radius", "spot_index"), &NativeStructures::building_radius);
	ClassDB::bind_method(D_METHOD("is_standing", "spot_index"), &NativeStructures::is_standing);
	ClassDB::bind_method(D_METHOD("candidate_count"), &NativeStructures::candidate_count);
}

// structure_index.gd rebuild: living units by ascending id, standing buildings in spot order, the
// castle last. The caller gathers them in that order; this only keeps them.
void NativeStructures::rebuild(
		const PackedInt64Array &unit_ids,
		const PackedVector2Array &unit_positions,
		const PackedFloat64Array &unit_radii,
		const PackedInt32Array &building_indices,
		const PackedVector2Array &building_centres,
		const PackedFloat64Array &building_radii,
		const Vector2 &castle_position,
		double castle_radius) {
	centres_.clear();
	radii_.clear();
	kinds_.clear();
	ids_.clear();
	cells_.clear();
	unit_ids_.clear();
	building_indices_.clear();
	largest_radius_ = 0.0;
	unit_count_ = 0;
	units_sorted_ = true;
	buildings_sorted_ = true;
	const int64_t units = unit_ids.size();
	if (unit_positions.size() == units && unit_radii.size() == units) {
		for (int64_t slot = 0; slot < units; slot++) {
			const int64_t id = unit_ids[slot];
			if (!unit_ids_.empty() && id <= unit_ids_.back()) {
				units_sorted_ = false;
			}
			unit_ids_.push_back(id);
			insert(unit_positions[slot], unit_radii[slot], KIND_UNIT, static_cast<int32_t>(id));
			unit_count_++;
		}
	}
	const int64_t buildings = building_indices.size();
	if (building_centres.size() == buildings && building_radii.size() == buildings) {
		for (int64_t slot = 0; slot < buildings; slot++) {
			const int32_t spot_index = building_indices[slot];
			if (!building_indices_.empty() && spot_index <= building_indices_.back()) {
				buildings_sorted_ = false;
			}
			building_indices_.push_back(spot_index);
			insert(building_centres[slot], building_radii[slot], KIND_BUILDING, spot_index);
		}
	}
	insert(castle_position, castle_radius, KIND_CASTLE, 0);
}

// structure_index.gd _insert.
void NativeStructures::insert(const Vector2 &centre, double radius, int32_t kind, int32_t id) {
	const int32_t index = static_cast<int32_t>(centres_.size());
	centres_.push_back(centre);
	radii_.push_back(radius);
	kinds_.push_back(kind);
	ids_.push_back(id);
	largest_radius_ = gd::maxf(largest_radius_, radius);
	const int64_t cell_x = gd::floori(static_cast<double>(centre.x) / CELL);
	const int64_t cell_y = gd::floori(static_cast<double>(centre.y) / CELL);
	const int64_t key = gd::cell_key(cell_x, cell_y);
	cells_[key].push_back(index);
}

Vector3i NativeStructures::nearest(const Vector2 &pos, double aggro_range) const {
	return scan_nearest(pos, aggro_range);
}

Vector3i NativeStructures::nearest_visible(
		const Vector2 &pos,
		double aggro_range,
		const Ref<NativeWalls> &walls,
		double radius,
		double ranged_reach) const {
	return scan_visible(pos, aggro_range, walls.ptr(), radius, ranged_reach);
}

Vector3i NativeStructures::nearest_through_walls(const Vector2 &pos, double aggro_range) const {
	return scan_through_walls(pos, aggro_range);
}

Vector3i NativeStructures::scan_nearest(const Vector2 &pos, double aggro_range) const {
	return scan(pos, aggro_range, nullptr, false, 0.0, -1.0, false);
}

Vector3i NativeStructures::scan_visible(
		const Vector2 &pos,
		double aggro_range,
		const NativeWalls *walls,
		double radius,
		double ranged_reach) const {
	return scan(pos, aggro_range, walls, true, radius, ranged_reach, false);
}

Vector3i NativeStructures::scan_through_walls(const Vector2 &pos, double aggro_range) const {
	return scan(pos, aggro_range, nullptr, false, 0.0, -1.0, true);
}

// structure_index.gd _scan: the candidates of the block of cells around `pos`, ascending, tested
// with `edge <= aggro_range and edge < best_edge`; only an improving candidate pays the line test.
Vector3i NativeStructures::scan(
		const Vector2 &pos,
		double aggro_range,
		const NativeWalls *walls,
		bool filter,
		double radius,
		double ranged_reach,
		bool skip_castle) const {
	const Vector3i none(0, 0, 0);
	// A NaN range or position can never pass `edge <= aggro_range`, so nothing is in range.
	if (std::isnan(aggro_range) || !gd::is_finite(pos)) {
		return none;
	}
	gather(pos, aggro_range);
	double best_edge = std::numeric_limits<double>::infinity();
	Vector3i found = none;
	for (const int32_t candidate : scratch_) {
		const size_t index = static_cast<size_t>(candidate);
		if (skip_castle && kinds_[index] == KIND_CASTLE) {
			continue;
		}
		const double edge = static_cast<double>(gd::distance_to(pos, centres_[index])) - radii_[index];
		if (edge <= aggro_range && edge < best_edge) {
			if (filter && !seen(pos, index, edge, walls, radius, ranged_reach)) {
				continue;
			}
			best_edge = edge;
			found = Vector3i(kinds_[index], ids_[index], 1);
		}
	}
	return found;
}

// The candidates in the block of cells around `pos`, ascending into scratch_.
void NativeStructures::gather(const Vector2 &pos, double aggro_range) const {
	scratch_.clear();
	const double reach = (aggro_range + largest_radius_ + REACH_MARGIN) / CELL;
	const bool everything =
			!std::isfinite(reach) || reach > MAX_REACH_CELLS ||
			(2.0 * reach + 1.0) * (2.0 * reach + 1.0) > static_cast<double>(cells_.size()) * 4.0 + 16.0;
	if (everything) {
		// The block would cover more cells than the grid holds: test every candidate, the scan the
		// grid replaces (a superset over an exact test, already in ascending order).
		for (size_t index = 0; index < centres_.size(); index++) {
			scratch_.push_back(static_cast<int32_t>(index));
		}
		return;
	}
	const int64_t reach_cells = gd::ceili(reach);
	const int64_t cell_x = gd::floori(static_cast<double>(pos.x) / CELL);
	const int64_t cell_y = gd::floori(static_cast<double>(pos.y) / CELL);
	for (int64_t offset_x = -reach_cells; offset_x <= reach_cells; offset_x++) {
		for (int64_t offset_y = -reach_cells; offset_y <= reach_cells; offset_y++) {
			const int64_t key = gd::cell_key(gd::wrap_add(cell_x, offset_x), gd::wrap_add(cell_y, offset_y));
			const auto bucket = cells_.find(key);
			if (bucket != cells_.end()) {
				scratch_.insert(scratch_.end(), bucket->second.begin(), bucket->second.end());
			}
		}
	}
	std::sort(scratch_.begin(), scratch_.end());
}

// structure_index.gd _seen.
bool NativeStructures::seen(
		const Vector2 &pos,
		size_t index,
		double edge,
		const NativeWalls *walls,
		double radius,
		double ranged_reach) const {
	if (walls == nullptr || walls->blocking_segment(pos, centres_[index], radius) < 0) {
		return true;
	}
	return ranged_reach >= 0.0 && edge <= ranged_reach;
}

int64_t NativeStructures::find_unit(int64_t id) const {
	if (units_sorted_) {
		const auto at = std::lower_bound(unit_ids_.begin(), unit_ids_.end(), id);
		if (at != unit_ids_.end() && *at == id) {
			return static_cast<int64_t>(at - unit_ids_.begin());
		}
		return -1;
	}
	for (size_t slot = 0; slot < unit_ids_.size(); slot++) {
		if (unit_ids_[slot] == id) {
			return static_cast<int64_t>(slot);
		}
	}
	return -1;
}

int64_t NativeStructures::find_building(int64_t spot_index) const {
	if (spot_index < std::numeric_limits<int32_t>::min() ||
			spot_index > std::numeric_limits<int32_t>::max()) {
		return -1;
	}
	const int32_t wanted = static_cast<int32_t>(spot_index);
	if (buildings_sorted_) {
		const auto at = std::lower_bound(building_indices_.begin(), building_indices_.end(), wanted);
		if (at != building_indices_.end() && *at == wanted) {
			return static_cast<int64_t>(at - building_indices_.begin());
		}
		return -1;
	}
	for (size_t slot = 0; slot < building_indices_.size(); slot++) {
		if (building_indices_[slot] == wanted) {
			return static_cast<int64_t>(slot);
		}
	}
	return -1;
}

Vector2 NativeStructures::unit_position(int64_t id) const {
	const int64_t slot = find_unit(id);
	return slot < 0 ? Vector2(0.0f, 0.0f) : centres_[static_cast<size_t>(slot)];
}

double NativeStructures::unit_radius(int64_t id) const {
	const int64_t slot = find_unit(id);
	return slot < 0 ? 0.0 : radii_[static_cast<size_t>(slot)];
}

bool NativeStructures::has_unit(int64_t id) const {
	return find_unit(id) >= 0;
}

Vector2 NativeStructures::building_centre(int64_t spot_index) const {
	const int64_t slot = find_building(spot_index);
	if (slot < 0) {
		return Vector2(0.0f, 0.0f);
	}
	return centres_[unit_count_ + static_cast<size_t>(slot)];
}

double NativeStructures::building_radius(int64_t spot_index) const {
	const int64_t slot = find_building(spot_index);
	if (slot < 0) {
		return 0.0;
	}
	return radii_[unit_count_ + static_cast<size_t>(slot)];
}

bool NativeStructures::is_standing(int64_t spot_index) const {
	return find_building(spot_index) >= 0;
}

int64_t NativeStructures::candidate_count() const {
	return static_cast<int64_t>(centres_.size());
}
