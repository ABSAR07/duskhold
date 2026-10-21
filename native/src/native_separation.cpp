#include "native_separation.h"

#include <algorithm>
#include <cstdint>
#include <utility>
#include <vector>

#include "cell_key.h"
#include "gd_math.h"

using namespace godot;

// A line-by-line port of simulation/squads/separation.gd under exact_port_rules 1 to 5: Vector2
// values are real_t (single precision), every GDScript float is a double, a scalar meets a
// Vector2 only through a cast to real_t at the operator, partners are visited in ascending index
// order, and nothing is reassociated.

namespace duskhold {

namespace {

// separation.gd MIN_CELL; its _cell_key is gd::cell_key (cell_key.h).
constexpr double MIN_CELL = 0.001;

PackedVector2Array zero_displacements(int64_t count) {
	PackedVector2Array result;
	result.resize(count);
	Vector2 *out = result.ptrw();
	for (int64_t index = 0; index < count; index++) {
		out[index] = Vector2(0.0f, 0.0f);
	}
	return result;
}

// The push of the pair (first, second), first below second, written once because the pairwise and
// the bucketed pass use the same expressions: separation.gd lines "var min_gap" to "var push".
// Returns false when the circles do not overlap. `amount` is `direction * push`.
bool pair_push(
		const Vector2 *positions,
		const double *radii,
		const int64_t *ids,
		int64_t first,
		int64_t second,
		Vector2 &amount) {
	const double min_gap = radii[first] + radii[second];
	const Vector2 delta = positions[second] - positions[first];
	if (gd::absf(static_cast<double>(delta.x)) >= min_gap) {
		return false;
	}
	const double d2 = static_cast<double>(gd::length_squared(delta));
	if (d2 >= min_gap * min_gap) {
		return false;
	}
	Vector2 direction;
	double gap = 0.0;
	if (d2 == 0.0) {
		direction = (ids[first] % 2 == 0) ? Vector2(1.0f, 0.0f) : Vector2(0.0f, 1.0f);
	} else {
		gap = gd::sqrt(d2);
		direction = delta / static_cast<real_t>(gap);
	}
	const double push = (min_gap - gap) * 0.5;
	amount = direction * static_cast<real_t>(push);
	return true;
}

} // namespace

void separation_displacements_raw(
		const Vector2 *pos, const double *rad, const int64_t *idv, int64_t count, Vector2 *out) {
	for (int64_t index = 0; index < count; index++) {
		out[index] = Vector2(0.0f, 0.0f);
	}
	for (int64_t first = 0; first < count; first++) {
		for (int64_t second = first + 1; second < count; second++) {
			Vector2 amount;
			if (!pair_push(pos, rad, idv, first, second, amount)) {
				continue;
			}
			out[first] -= amount;
			out[second] += amount;
		}
	}
}

PackedVector2Array separation_displacements(
		const PackedVector2Array &positions,
		const PackedFloat64Array &radii,
		const PackedInt64Array &ids) {
	const int64_t count = positions.size();
	PackedVector2Array result = zero_displacements(count);
	if (radii.size() != count || ids.size() != count) {
		return result;
	}
	separation_displacements_raw(positions.ptr(), radii.ptr(), ids.ptr(), count, result.ptrw());
	return result;
}

void separation_displacements_bucketed_raw(
		const Vector2 *pos,
		const double *rad,
		const int64_t *idv,
		int64_t count,
		double cell,
		Vector2 *out,
		SeparationScratch &scratch) {
	for (int64_t index = 0; index < count; index++) {
		out[index] = Vector2(0.0f, 0.0f);
	}
	if (count < 2) {
		return;
	}
	const double edge = gd::maxf(cell, MIN_CELL);
	double largest = 0.0;
	for (int64_t index = 0; index < count; index++) {
		largest = gd::maxf(largest, rad[index]);
	}
	const int64_t span = gd::maxi(gd::ceili(2.0 * largest / edge), 1);
	// Every circle visits (2 * span + 1) squared cells, so a small caller-chosen `cell` makes the
	// work grow with the square of 1 / cell (review WR-11). A block that holds at least as many
	// cells as there are circles is never cheaper than the pairwise pass, which answers the same
	// bits (the cell decides the work, never an answer), so the pairwise pass answers instead.
	const int64_t side = gd::wrap_add(gd::wrap_mul(2, span), 1);
	if (span >= count || side >= count || gd::wrap_mul(side, side) >= count) {
		separation_displacements_raw(pos, rad, idv, count, out);
		return;
	}

	const size_t size = static_cast<size_t>(count);
	std::vector<int64_t> &cell_x = scratch.cell_x;
	std::vector<int64_t> &cell_y = scratch.cell_y;
	cell_x.resize(size);
	cell_y.resize(size);
	// (key, index) in ascending order: the circles of one cell come out in ascending index order,
	// exactly the order the GDScript dictionary appended them in.
	std::vector<std::pair<int64_t, int64_t>> &cells = scratch.cells;
	cells.clear();
	cells.reserve(size);
	for (int64_t index = 0; index < count; index++) {
		const size_t slot = static_cast<size_t>(index);
		cell_x[slot] = gd::floori(static_cast<double>(pos[index].x) / edge);
		cell_y[slot] = gd::floori(static_cast<double>(pos[index].y) / edge);
		cells.emplace_back(gd::cell_key(cell_x[slot], cell_y[slot]), index);
	}
	std::sort(cells.begin(), cells.end());

	std::vector<int64_t> &partners = scratch.partners;
	for (int64_t index = 0; index < count; index++) {
		const size_t slot = static_cast<size_t>(index);
		// separation.gd _partner_sum: the partners from the cells within `span`, sorted ascending.
		partners.clear();
		for (int64_t offset_x = -span; offset_x <= span; offset_x++) {
			for (int64_t offset_y = -span; offset_y <= span; offset_y++) {
				const int64_t key = gd::cell_key(
						gd::wrap_add(cell_x[slot], offset_x), gd::wrap_add(cell_y[slot], offset_y));
				auto bucket = std::lower_bound(
						cells.begin(), cells.end(), std::make_pair(key, static_cast<int64_t>(INT64_MIN)));
				for (; bucket != cells.end() && bucket->first == key; ++bucket) {
					partners.push_back(bucket->second);
				}
			}
		}
		std::sort(partners.begin(), partners.end());
		Vector2 total = Vector2(0.0f, 0.0f);
		for (const int64_t other : partners) {
			if (other == index) {
				continue;
			}
			const int64_t first = gd::mini(index, other);
			const int64_t second = gd::maxi(index, other);
			Vector2 amount;
			if (!pair_push(pos, rad, idv, first, second, amount)) {
				continue;
			}
			if (other < index) {
				total += amount;
			} else {
				total -= amount;
			}
		}
		out[index] = total;
	}
}

PackedVector2Array separation_displacements_bucketed(
		const PackedVector2Array &positions,
		const PackedFloat64Array &radii,
		const PackedInt64Array &ids,
		double cell) {
	const int64_t count = positions.size();
	PackedVector2Array result = zero_displacements(count);
	if (radii.size() != count || ids.size() != count || count < 2) {
		return result;
	}
	SeparationScratch scratch;
	separation_displacements_bucketed_raw(
			positions.ptr(), radii.ptr(), ids.ptr(), count, cell, result.ptrw(), scratch);
	return result;
}

} // namespace duskhold
