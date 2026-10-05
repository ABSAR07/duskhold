class_name King
extends CharacterBody3D
## The mounted king. Moves in WORLD axes so movement stays camera-aligned (KING-02): the camera
## rig has yaw 0, so move_forward is always screen-up.
## Once the run is over (won or lost) he ignores movement input.
## KING-06 on screen: when the simulation knocks him out, the model gives way to a translucent
## ghost that cannot move, and when the countdown ends he reappears at the castle. A hurt-only
## health bar floats over him. The node reads the run and reacts to its events; the simulation
## state is written only by MapRoot, which pushes this node's position (T-02-06).

## Below this horizontal speed (m/s) the model keeps its current facing.
const FACING_MIN_SPEED: float = 0.1
## Where the health bar floats above the king's feet and how wide it is.
const HEALTH_BAR_HEIGHT: float = 3.0
const HEALTH_BAR_WIDTH: float = 1.6

@export var def: KingDef

var _ctx: RunContext
var _health_bar: HealthBar3D

@onready var _model: Node3D = $Model
@onready var _ghost: Node3D = $Ghost


## Speed in metres per second for the walking or sprinting king.
static func move_speed(king_def: KingDef, sprinting: bool) -> float:
	if sprinting:
		return king_def.walk_speed * king_def.sprint_multiplier
	return king_def.walk_speed


## Binds the king to one run (MapRoot calls this once; a repeat call is ignored).
func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	_health_bar = HealthBar3D.new()
	_health_bar.name = "HealthBar"
	_health_bar.bar_width = HEALTH_BAR_WIDTH
	_health_bar.height_offset = HEALTH_BAR_HEIGHT
	add_child(_health_bar)
	ctx.events.king_damaged.connect(_on_king_damaged)
	ctx.events.king_downed.connect(_on_king_downed)
	ctx.events.king_respawned.connect(_on_king_respawned)
	ctx.events.dawn_payout.connect(_on_dawn_payout)
	_refresh_health_bar()


## The king's health bar: hidden at full health, shown once he is hurt (D-12 rule).
func get_health_bar() -> HealthBar3D:
	return _health_bar


## True while the ghost stands in for the knocked-out king.
func is_ghost_shown() -> bool:
	return _ghost.visible


func _physics_process(delta: float) -> void:
	if _ctx != null and (_ctx.king.is_down() or _ctx.run_manager.is_run_over()):
		velocity = Vector3.ZERO
		return
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


func _on_king_damaged(_amount: int, hp: int, max_hp: int) -> void:
	_health_bar.set_health(hp, max_hp)


func _on_king_downed(_respawn_ticks: int, _knockout_number: int) -> void:
	velocity = Vector3.ZERO
	_model.visible = false
	_ghost.visible = true
	_refresh_health_bar()


## Back at the castle with full health: the model returns, the ghost and the bar go.
func _on_king_respawned() -> void:
	global_position = _ctx.map.king_spawn
	velocity = Vector3.ZERO
	_model.visible = true
	_ghost.visible = false
	_refresh_health_bar()


## Dawn heals the king in place without an event of its own; the payout is announced right after
## the heal, so the bar follows it.
func _on_dawn_payout(_total: int, _per_spot: Dictionary) -> void:
	_refresh_health_bar()


func _refresh_health_bar() -> void:
	_health_bar.set_health(_ctx.king.get_health(), _ctx.king.get_max_health())
