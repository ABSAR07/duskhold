class_name StanceGlyph
extends Control
## RED skeleton: the 20x20 stance symbol of a squad slot. Drawn in the implementation step.

const SHAPE_UNKNOWN := &"unknown"

var stance: StringName = &"post"


## The shape id drawn for a stance.
static func shape_for(_stance: StringName) -> StringName:
	return SHAPE_UNKNOWN


func current_shape() -> StringName:
	return SHAPE_UNKNOWN
