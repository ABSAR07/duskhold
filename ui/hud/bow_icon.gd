class_name BowIcon
extends RefCounted
## The unit icon of an archer squad (D-23), drawn in code so the project needs no asset: a curved
## stave, a straight string and a nocked arrow with a pointed head, white on a transparent square.
## The parts are laid out on a 48 unit grid and scaled to the requested size, the same grid the
## sword icon uses.

## The grid the numbers below are written on.
const GRID: float = 48.0
const MIN_SIZE: int = 8
const WHITE_CLEAR := Color(1.0, 1.0, 1.0, 0.0)
## The stave runs from STAVE_TOP to STAVE_BOTTOM; it is x = STAVE_X at the middle row and bends
## toward the string by (distance from the middle row) squared over STAVE_CURVE.
const STAVE_TOP: float = 4.0
const STAVE_BOTTOM: float = 44.0
const STAVE_MIDDLE: float = 24.0
const STAVE_X: float = 12.0
const STAVE_CURVE: float = 24.0
const STAVE_THICKNESS: float = 3.0
## The string joins the two ends of the stave.
const STRING_X: float = 30.0
const STRING_WIDTH: float = 2.0
## The arrow lies on the middle row from its tail to its tip; the head is a triangle at the tip.
const ARROW_TAIL_X: float = 18.0
const ARROW_TIP_X: float = 46.0
const ARROW_WIDTH: float = 2.0
const HEAD_LENGTH: float = 8.0
const HEAD_HALF_HEIGHT: float = 4.0


## A square texture of `size` pixels (at least MIN_SIZE) with the white bow on it.
static func make_texture(size: int) -> ImageTexture:
	var side: int = maxi(size, MIN_SIZE)
	var image: Image = Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
	image.fill(WHITE_CLEAR)
	var unit: float = float(side) / GRID
	_draw_stave(image, unit)
	_fill_grid_rect(image, unit, Rect2(STRING_X, STAVE_TOP, STRING_WIDTH, STAVE_BOTTOM - STAVE_TOP))
	var shaft_top: float = STAVE_MIDDLE - ARROW_WIDTH * 0.5
	var shaft_length: float = ARROW_TIP_X - HEAD_LENGTH - ARROW_TAIL_X
	_fill_grid_rect(image, unit, Rect2(ARROW_TAIL_X, shaft_top, shaft_length, ARROW_WIDTH))
	_draw_head(image, unit)
	return ImageTexture.create_from_image(image)


## The curved stave, one run of pixels per row; a run reaches over to the next row's start so a
## steep part of the curve has no gaps.
static func _draw_stave(image: Image, unit: float) -> void:
	var thickness: int = maxi(roundi(STAVE_THICKNESS * unit), 1)
	var first_row: int = roundi(STAVE_TOP * unit)
	var last_row: int = roundi(STAVE_BOTTOM * unit)
	for row: int in range(first_row, last_row):
		var here: int = roundi(_stave_x((float(row) + 0.5) / unit) * unit)
		var next: int = roundi(_stave_x((float(row) + 1.5) / unit) * unit)
		var left: int = mini(here, next)
		var run: int = maxi(thickness, absi(next - here) + 1)
		image.fill_rect(Rect2i(left, row, run, 1), Color.WHITE)


static func _stave_x(grid_y: float) -> float:
	var away: float = grid_y - STAVE_MIDDLE
	return STAVE_X + away * away / STAVE_CURVE


## The arrow head: columns from the base to the tip, each shorter than the one before.
static func _draw_head(image: Image, unit: float) -> void:
	var base_x: float = ARROW_TIP_X - HEAD_LENGTH
	var first_column: int = roundi(base_x * unit)
	var last_column: int = roundi(ARROW_TIP_X * unit)
	var middle_row: float = STAVE_MIDDLE * unit
	for column: int in range(first_column, last_column):
		var progress: float = (
			float(column - first_column) / float(maxi(last_column - first_column, 1))
		)
		var half: float = HEAD_HALF_HEIGHT * unit * (1.0 - progress)
		var top: int = roundi(middle_row - half)
		var height: int = maxi(roundi(half * 2.0), 1)
		image.fill_rect(Rect2i(column, top, 1, height), Color.WHITE)


static func _fill_grid_rect(image: Image, unit: float, part: Rect2) -> void:
	var left: int = roundi(part.position.x * unit)
	var top: int = roundi(part.position.y * unit)
	var width: int = maxi(roundi(part.size.x * unit), 1)
	var height: int = maxi(roundi(part.size.y * unit), 1)
	image.fill_rect(Rect2i(left, top, width, height), Color.WHITE)
