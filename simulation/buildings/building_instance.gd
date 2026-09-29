class_name BuildingInstance
extends RefCounted
## A building standing on a spot. Only ever holds completed tiers (no partial-payment state, D-06).

var spot_id: StringName = &""
var building_id: StringName = &""
var tier: int = 0
