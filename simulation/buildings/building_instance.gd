class_name BuildingInstance
extends RefCounted
## A building standing on a spot. Only ever holds completed tiers (no partial-payment state, D-06).

var spot_id: StringName = &""
var building_id: StringName = &""
var tier: int = 0
## Hit points left; 0 while destroyed.
var health: int = 0
## True from the hit that took the last point until the dawn rebuild.
var destroyed: bool = false
## True for the dawn on which this building was rebuilt; it pays no income at that dawn.
var rebuilt_this_dawn: bool = false
