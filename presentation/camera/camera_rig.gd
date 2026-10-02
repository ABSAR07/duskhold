class_name CameraRig
extends Node3D
## Fixed-angle, smoothed follow camera (KING-02). It is detached from the king and trails the
## king's position only. The player cannot orbit it and no mouse input exists: zoom_in / zoom_out
## only slide the rig nearer or farther along the fixed offset direction, clamped to
## [zoom_min, zoom_max]. The Camera3D child is aimed once in bind_run and never touched afterwards.
## Zooming is presentation only; it never reads or writes the simulation.

## Camera position relative to the king at zoom 1.0. Tunable at the Phase 2 playtest.
@export var offset: Vector3 = Vector3(0.0, 16.0, 11.0)
## Follow stiffness; higher trails less. Frame-rate independent via exp().
@export var follow_sharpness: float = 6.0
## Closest zoom, as a multiplier of `offset`.
@export var zoom_min: float = 0.7
## Farthest zoom, as a multiplier of `offset`.
@export var zoom_max: float = 1.5
## Zoom units per second at full input; the right stick is analog, so a partial push is slower.
@export var zoom_speed: float = 0.6

var _target: King
var _zoom: float = 1.0

@onready var _camera: Camera3D = $Camera3D


func bind_run(_ctx: RunContext, map_root: MapRoot) -> void:
	_target = map_root.get_king()
	_zoom = clampf(1.0, zoom_min, zoom_max)
	global_position = _target.global_position + get_effective_offset()
	_camera.look_at(_target.global_position)


func get_zoom() -> float:
	return _zoom


## The camera's position relative to the king right now: `offset` scaled by the current zoom.
func get_effective_offset() -> Vector3:
	return offset * _zoom


func _physics_process(delta: float) -> void:
	if _target == null:
		return
	var zoom_input: float = Input.get_axis(&"zoom_in", &"zoom_out")
	_zoom = clampf(_zoom + zoom_input * zoom_speed * delta, zoom_min, zoom_max)
	var weight: float = 1.0 - exp(-follow_sharpness * delta)
	global_position = global_position.lerp(_target.global_position + get_effective_offset(), weight)
