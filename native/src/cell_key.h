#pragma once

// The one packed spatial-hash cell key the port uses (IN-05). The GDScript it replaces carried a
// copy in every index (wall_system.gd _key, separation.gd _cell_key, structure_index.gd and
// enemy_index.gd _key): `(cell_x + KEY_OFFSET) * KEY_STRIDE + (cell_y + KEY_OFFSET)`, with
// KEY_OFFSET = 1 << 19 and KEY_STRIDE = 1 << 20, wrapping like a GDScript int. The walls, the
// structures, the enemies and the separation pass call this function, so a cell has one key
// everywhere. The wrapping arithmetic is gd::wrap_add and gd::wrap_mul in gd_math.h.

#include <cstdint>

#include "gd_math.h"

namespace gd {

constexpr int64_t CELL_KEY_OFFSET = static_cast<int64_t>(1) << 19;
constexpr int64_t CELL_KEY_STRIDE = static_cast<int64_t>(1) << 20;

inline int64_t cell_key(int64_t cell_x, int64_t cell_y) {
	return wrap_add(
			wrap_mul(wrap_add(cell_x, CELL_KEY_OFFSET), CELL_KEY_STRIDE), wrap_add(cell_y, CELL_KEY_OFFSET));
}

} // namespace gd
