class_name DayNightLighting
extends Node3D
## Signature-only stub for the RED commit; the real mood driver replaces it.

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


func get_mood() -> StringName:
	return &"day"
