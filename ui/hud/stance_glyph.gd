class_name StanceGlyph
extends Control
## The stance symbol of a squad slot (D-23): 20x20, drawn in code with a line width of 2 in the
## secondary text colour. The five shapes read without colour: post is a small filled square on a
## base line, follow two chevrons, hold a square outline with a bar through it, patrol a
## double-headed horizontal arrow and attack-move a right arrow with a filled, pointed head. A
## stance this class does not know draws a plain dot, so the glyph is never blank.

const GLYPH_SIZE := Vector2(20.0, 20.0)
const LINE_WIDTH: float = 2.0
const GLYPH_COLOR := Color("#C8CCD4")
const SHAPE_POST := &"square_on_base"
const SHAPE_FOLLOW := &"chevrons"
const SHAPE_HOLD := &"square_with_bar"
const SHAPE_PATROL := &"double_arrow"
const SHAPE_ATTACK_MOVE := &"spike_arrow"
const SHAPE_UNKNOWN := &"unknown"
## Which shape each stance (or one-shot verb) draws.
const SHAPES: Dictionary = {
	SquadOrder.STANCE_POST: SHAPE_POST,
	SquadOrder.STANCE_FOLLOW: SHAPE_FOLLOW,
	SquadOrder.STANCE_HOLD: SHAPE_HOLD,
	SquadOrder.STANCE_PATROL: SHAPE_PATROL,
	SquadOrder.VERB_ATTACK_MOVE: SHAPE_ATTACK_MOVE,
}

## The stance or verb drawn; changing it redraws.
var stance: StringName = SquadOrder.STANCE_POST:
	set(value):
		stance = value
		queue_redraw()


## The shape id drawn for a stance; SHAPE_UNKNOWN for any name outside the five.
static func shape_for(stance_name: StringName) -> StringName:
	return SHAPES.get(stance_name, SHAPE_UNKNOWN)


func _init() -> void:
	custom_minimum_size = GLYPH_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## The shape being drawn now.
func current_shape() -> StringName:
	return shape_for(stance)


func _draw() -> void:
	match current_shape():
		SHAPE_POST:
			draw_rect(Rect2(6.0, 3.0, 8.0, 8.0), GLYPH_COLOR, true)
			draw_line(Vector2(2.0, 16.0), Vector2(18.0, 16.0), GLYPH_COLOR, LINE_WIDTH)
		SHAPE_FOLLOW:
			_draw_chevron(2.0)
			_draw_chevron(10.0)
		SHAPE_HOLD:
			draw_rect(Rect2(3.0, 3.0, 14.0, 14.0), GLYPH_COLOR, false, LINE_WIDTH)
			draw_line(Vector2(0.0, 10.0), Vector2(20.0, 10.0), GLYPH_COLOR, LINE_WIDTH)
		SHAPE_PATROL:
			draw_line(Vector2(3.0, 10.0), Vector2(17.0, 10.0), GLYPH_COLOR, LINE_WIDTH)
			_draw_head(Vector2(2.0, 10.0), 1.0)
			_draw_head(Vector2(18.0, 10.0), -1.0)
		SHAPE_ATTACK_MOVE:
			draw_line(Vector2(1.0, 10.0), Vector2(11.0, 10.0), GLYPH_COLOR, LINE_WIDTH)
			var tip: PackedVector2Array = [
				Vector2(10.0, 4.0), Vector2(19.0, 10.0), Vector2(10.0, 16.0)
			]
			draw_colored_polygon(tip, GLYPH_COLOR)
		_:
			draw_circle(Vector2(10.0, 10.0), 3.0, GLYPH_COLOR)


## One ">" whose left end sits at `left`.
func _draw_chevron(left: float) -> void:
	var points: PackedVector2Array = [
		Vector2(left, 4.0), Vector2(left + 6.0, 10.0), Vector2(left, 16.0)
	]
	draw_polyline(points, GLYPH_COLOR, LINE_WIDTH)


## An open arrow head with its point at `tip`, opening toward +x when `direction` is 1.
func _draw_head(tip: Vector2, direction: float) -> void:
	var points: PackedVector2Array = [
		tip + Vector2(5.0 * direction, -5.0), tip, tip + Vector2(5.0 * direction, 5.0)
	]
	draw_polyline(points, GLYPH_COLOR, LINE_WIDTH)
