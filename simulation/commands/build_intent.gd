class_name BuildIntent
extends RefCounted
## Request to build or upgrade the building on a spot. Carries no gold or phase snapshot:
## CommandProcessor re-validates everything when the intent is applied.

var spot_id: StringName = &""


func _init(target_spot: StringName) -> void:
	spot_id = target_spot
