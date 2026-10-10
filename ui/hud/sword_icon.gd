class_name SwordIcon
extends RefCounted
## The sword on the king widget's ability icon (D-22), drawn in code so the project needs no asset:
## a white blade with a tip, a cross guard, a grip and a pommel on a transparent square. The parts
## are laid out on a 48 unit grid and scaled to the requested size.

## The grid the part rectangles below are written on.
const GRID: float = 48.0
const MIN_SIZE: int = 8
const WHITE_CLEAR := Color(1.0, 1.0, 1.0, 0.0)
## Blade tip, blade, cross guard, grip, pommel as Rect2(x, y, width, height) on the grid.
const PARTS: Array[Rect2] = [
	Rect2(23.0, 4.0, 2.0, 4.0),
	Rect2(22.0, 8.0, 4.0, 22.0),
	Rect2(14.0, 30.0, 20.0, 4.0),
	Rect2(22.0, 34.0, 4.0, 8.0),
	Rect2(20.0, 42.0, 8.0, 4.0),
]


## A square texture of `size` pixels (at least MIN_SIZE) with the white sword on it.
static func make_texture(size: int) -> ImageTexture:
	var side: int = maxi(size, MIN_SIZE)
	var image: Image = Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
	image.fill(WHITE_CLEAR)
	var unit: float = float(side) / GRID
	for part: Rect2 in PARTS:
		var left: int = roundi(part.position.x * unit)
		var top: int = roundi(part.position.y * unit)
		var width: int = maxi(roundi(part.size.x * unit), 1)
		var height: int = maxi(roundi(part.size.y * unit), 1)
		image.fill_rect(Rect2i(left, top, width, height), Color.WHITE)
	return ImageTexture.create_from_image(image)
