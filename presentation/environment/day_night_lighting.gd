class_name DayNightLighting
extends Node3D
## Day, night and dawn lighting moods (D-12), driven only by SimEvents.phase_changed. Attach it to
## the node that parents the Sun (DirectionalLight3D) and the WorldEnvironment. NIGHT_TRANSITION
## and NIGHT share the night mood. The moods are presentation tuning, so they are exported
## properties set in the text scene; gameplay numbers stay in loop_tuning.tres.

@export var day_sun_color: Color = Color(1.0, 0.96, 0.88)
@export var day_sun_energy: float = 1.0
@export var day_ambient_energy: float = 1.0
@export var night_sun_color: Color = Color(0.45, 0.55, 0.9)
@export var night_sun_energy: float = 0.25
@export var night_ambient_energy: float = 0.3
@export var dawn_sun_color: Color = Color(1.0, 0.7, 0.45)
@export var dawn_sun_energy: float = 0.7
@export var dawn_ambient_energy: float = 0.7
@export var transition_seconds: float = 1.0

var _mood: StringName = &"day"
var _tween: Tween
var _environment: Environment

@onready var _sun: DirectionalLight3D = $Sun
@onready var _world_environment: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	# The Environment is a sub-resource shared by every instance of the scene, so each instance
	# tweens its own copy and a new run never starts in the previous run's night lighting.
	_environment = _world_environment.environment.duplicate()
	_world_environment.environment = _environment
	_apply_mood_now(&"day")


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	_apply_mood_now(_mood_for_phase(ctx.run_manager.get_phase()))
	ctx.events.phase_changed.connect(_on_phase_changed)


## &"day", &"night" or &"dawn". Changes at once; the light itself eases over transition_seconds.
func get_mood() -> StringName:
	return _mood


func _on_phase_changed(_old_phase: int, new_phase: int) -> void:
	var mood: StringName = _mood_for_phase(new_phase as RunManager.RunPhase)
	if mood == _mood:
		return
	_mood = mood
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_sun, "light_color", _sun_color_for(mood), transition_seconds)
	_tween.tween_property(_sun, "light_energy", _sun_energy_for(mood), transition_seconds)
	_tween.tween_property(
		_environment, "ambient_light_energy", _ambient_energy_for(mood), transition_seconds
	)


func _apply_mood_now(mood: StringName) -> void:
	_mood = mood
	if _tween != null:
		_tween.kill()
	_sun.light_color = _sun_color_for(mood)
	_sun.light_energy = _sun_energy_for(mood)
	_environment.ambient_light_energy = _ambient_energy_for(mood)


func _mood_for_phase(phase: RunManager.RunPhase) -> StringName:
	match phase:
		RunManager.RunPhase.NIGHT_TRANSITION, RunManager.RunPhase.NIGHT:
			return &"night"
		RunManager.RunPhase.DAWN:
			return &"dawn"
	return &"day"


func _sun_color_for(mood: StringName) -> Color:
	match mood:
		&"night":
			return night_sun_color
		&"dawn":
			return dawn_sun_color
	return day_sun_color


func _sun_energy_for(mood: StringName) -> float:
	match mood:
		&"night":
			return night_sun_energy
		&"dawn":
			return dawn_sun_energy
	return day_sun_energy


func _ambient_energy_for(mood: StringName) -> float:
	match mood:
		&"night":
			return night_ambient_energy
		&"dawn":
			return dawn_ambient_energy
	return day_ambient_energy
