class_name PadChords
extends RefCounted
## Pure resolution of the gamepad twin presses (D-12, RESEARCH Open Question 3). Inert skeleton.


static func resolve(
	_just_pressed: Array[StringName], _layer_held: bool, _group_mode_held: bool
) -> Array[StringName]:
	return []


static func is_pad_press(_action: StringName, _just_pressed: Array[StringName]) -> bool:
	return false
