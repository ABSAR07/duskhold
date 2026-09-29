class_name King
extends CharacterBody3D
## The mounted king. Moves in WORLD axes so movement stays camera-aligned (KING-02): the camera
## rig has yaw 0, so move_forward is always screen-up.

## Below this horizontal speed (m/s) the model keeps its current facing.
const FACING_MIN_SPEED: float = 0.1

@export var def: KingDef

@onready var _model: Node3D = $Model


## Speed in metres per second for the walking or sprinting king.
static func move_speed(king_def: KingDef, sprinting: bool) -> float:
	if sprinting:
		return king_def.walk_speed * king_def.sprint_multiplier
	return king_def.walk_speed


func _physics_process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector(
		&"move_left", &"move_right", &"move_forward", &"move_back"
	)
	var speed: float = move_speed(def, Input.is_action_pressed(&"sprint"))
	var target: Vector3 = Vector3(direction.x * speed, 0.0, direction.y * speed)
	velocity = velocity.move_toward(target, def.acceleration * delta)
	velocity.y = 0.0
	move_and_slide()
	global_position.y = 0.0
	_face_movement(delta)


## Turns only the Model pivot toward the horizontal velocity; the body root never rotates.
func _face_movement(delta: float) -> void:
	var horizontal: Vector2 = Vector2(velocity.x, velocity.z)
	if horizontal.length() <= FACING_MIN_SPEED:
		return
	var target_yaw: float = atan2(velocity.x, velocity.z)
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, minf(def.turn_speed * delta, 1.0))
