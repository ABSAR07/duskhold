class_name SquadFormation
extends RefCounted
## Pure formation geometry: where slot `slot` of a squad of `cap` units stands relative to the
## squad's anchor. An axis-aligned grid centred on the anchor, filled row by row, so a squad of 4 is
## a 2x2 block and a squad of 14 is a 4x4 block with two empty seats. No trigonometry (DR-7):
## headings are not simulated, so the grid never turns.


## Offset from the anchor of slot `slot` (0-based) in a squad with `cap` seats, `spacing` metres
## between neighbouring slots. A `cap` below 1 is treated as 1.
static func slot_offset(slot: int, cap: int, spacing: float) -> Vector2:
	var seats: int = maxi(cap, 1)
	var columns: int = maxi(ceili(sqrt(float(seats))), 1)
	var rows: int = ceili(float(seats) / float(columns))
	var column: int = slot % columns
	var row: int = floori(float(slot) / float(columns))
	return Vector2(
		(float(column) - float(columns - 1) * 0.5) * spacing,
		(float(row) - float(rows - 1) * 0.5) * spacing
	)
