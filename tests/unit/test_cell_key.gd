extends GutTest
## CellKey, the one packed cell key of the simulation (IN-05): the offset and stride shared with
## native/src/cell_key.h, so a cell has one key on both sides.

const OFFSET: int = 524288
const STRIDE: int = 1048576


func test_the_origin_cell_packs_to_the_offset_pair() -> void:
	assert_eq(CellKey.pack(0, 0), OFFSET * STRIDE + OFFSET, "the origin is offset on both axes")


func test_pack_is_x_major_and_distinguishes_neighbours() -> void:
	assert_eq(CellKey.pack(1, 0) - CellKey.pack(0, 0), STRIDE, "one cell east is one stride")
	assert_eq(CellKey.pack(0, 1) - CellKey.pack(0, 0), 1, "one cell south is one key")
	assert_ne(CellKey.pack(-1, 7), CellKey.pack(7, -1), "swapped cells are different keys")


func test_negative_cells_inside_the_offset_stay_distinct() -> void:
	assert_eq(CellKey.pack(-3, -4), (-3 + OFFSET) * STRIDE + (-4 + OFFSET), "the formula")
