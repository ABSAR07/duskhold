class_name DragBox
extends Panel
## The live drag rectangle of box selection (UI-SPEC "Drag box"): a flat Panel filled #8CEBFF at
## alpha 0.16 with a 2 px #8CEBFF border at alpha 0.9 and no radius. Hidden until a drag starts;
## the SelectionController moves it between the press point and the cursor and hides it when the
## drag ends or is cancelled. It is the one HUD element allowed inside the protected clear centre,
## and only while dragging. It ignores the mouse so it never takes a click. Display only.

const FILL := Color(0.549, 0.9216, 1.0, 0.16)
const BORDER := Color(0.549, 0.9216, 1.0, 0.9)
const BORDER_WIDTH: int = 2

var _dragging: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = FILL
	style.border_color = BORDER
	style.set_border_width_all(BORDER_WIDTH)
	style.set_corner_radius_all(0)
	add_theme_stylebox_override(&"panel", style)


## Shows the box spanning the corners `a` and `b` (screen pixels, either order).
func set_rect_from(a: Vector2, b: Vector2) -> void:
	position = a.min(b)
	size = (a - b).abs()
	_dragging = true
	visible = true


## Hides the box and ends the drag.
func end_drag() -> void:
	_dragging = false
	visible = false


## True from the first set_rect_from until end_drag.
func is_dragging() -> bool:
	return _dragging
