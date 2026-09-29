class_name CameraRig
extends Node3D
## Fixed-angle, smoothed follow camera (KING-02). It is detached from the king, trails the king's
## position only, and the player has no way to change its angle: no zoom, no orbit, no mouse.
## The Camera3D child is aimed once in bind_run and is never touched afterwards.

## Camera position relative to the king. Tunable at the Phase 2 playtest.
@export var offset: Vector3 = Vector3(0.0, 16.0, 11.0)
## Follow stiffness; higher trails less. Frame-rate independent via exp().
@export var follow_sharpness: float = 6.0

var _target: King

@onready var _camera: Camera3D = $Camera3D


func bind_run(_ctx: RunContext, map_root: MapRoot) -> void:
	_target = map_root.get_king()
	global_position = _target.global_position + offset
	_camera.look_at(_target.global_position)


func _physics_process(delta: float) -> void:
	if _target == null:
		return
	var weight: float = 1.0 - exp(-follow_sharpness * delta)
	global_position = global_position.lerp(_target.global_position + offset, weight)
