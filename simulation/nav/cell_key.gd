class_name CellKey
extends RefCounted
## The one packed spatial-hash cell key of the simulation: (cell_x + KEY_OFFSET) * KEY_STRIDE +
## (cell_y + KEY_OFFSET), wrapping like any GDScript int. The native sources pack the same key in
## native/src/cell_key.h, so a cell has one key on both sides. Pure RefCounted code under
## simulation/ (DR-1 to DR-10).

const KEY_OFFSET: int = 1 << 19
const KEY_STRIDE: int = 1 << 20


static func pack(cell_x: int, cell_y: int) -> int:
	return (cell_x + KEY_OFFSET) * KEY_STRIDE + (cell_y + KEY_OFFSET)
