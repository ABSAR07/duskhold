class_name HealthBar3D
extends Node3D
## Stub for the RED commit: the real bar arrives with the GREEN commit.

@export var bar_width: float = 1.4
@export var height_offset: float = 2.6


static func should_show(_hp: int, _max_hp: int) -> bool:
	return false


func get_fill_ratio() -> float:
	return 1.0


func set_health(_hp: int, _max_hp: int) -> void:
	pass
