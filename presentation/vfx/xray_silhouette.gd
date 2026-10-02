class_name XRaySilhouette
extends Node
## Interface stub for the RED commit; the behavior lands in the GREEN commit.

@export var stencil_color: Color = Color(0.4, 0.9, 1.0, 1.0)


func get_applied_count() -> int:
	return 0


static func apply_xray(_root: Node, _color: Color) -> int:
	return 0
