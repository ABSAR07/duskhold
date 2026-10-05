class_name SpawnPointDef
extends Resource
## A place enemies arrive from. Data only.

@export var id: StringName = &""
@export var display_name: String = ""
## World position; only the XZ components matter (y = 0).
@export var position: Vector3 = Vector3.ZERO
## Each spawned enemy is offset by up to this many metres on each axis, drawn from the night's
## seeded spawn stream.
@export var scatter_radius: float = 0.0
