class_name BuildSpotDef
extends Resource
## A fixed build plot. Each spot allows exactly one building type, fixed in map data (D-02).

@export var id: StringName = &""
## World position; only the XZ components matter (y = 0).
@export var position: Vector3 = Vector3.ZERO
## The one building type this spot allows.
@export var building_id: StringName = &""
