class_name King
extends CharacterBody3D
## The mounted king. Moves in WORLD axes so movement stays camera-aligned (KING-02).

@export var def: KingDef


## Speed in metres per second for the walking or sprinting king.
static func move_speed(king_def: KingDef, sprinting: bool) -> float:
	if sprinting:
		return king_def.walk_speed * king_def.sprint_multiplier
	return king_def.walk_speed


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector(
		&"move_left", &"move_right", &"move_forward", &"move_back"
	)
	var speed: float = move_speed(def, Input.is_action_pressed(&"sprint"))
	velocity = Vector3(direction.x * speed, 0.0, direction.y * speed)
	move_and_slide()
	global_position.y = 0.0
