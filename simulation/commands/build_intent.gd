class_name BuildIntent
extends RefCounted
## Request to build or upgrade the building on a spot. Carries no gold or phase snapshot:
## CommandProcessor re-validates everything when the intent is applied. When the tier being bought
## offers cards (BLDG-05), the pick rides the same intent as `choice_id`, so the upgrade and its
## choice reach the simulation as one stamped command (D-05).

var spot_id: StringName = &""
## The card picked with this purchase; empty for a tier with no cards.
var choice_id: StringName = &""


func _init(target_spot: StringName, choice: StringName = &"") -> void:
	spot_id = target_spot
	choice_id = choice
