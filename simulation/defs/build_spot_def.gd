class_name BuildSpotDef
extends Resource
## A fixed build plot. Each spot allows exactly one building type, fixed in map data (D-02).

@export var id: StringName = &""
## World position; only the XZ components matter (y = 0).
@export var position: Vector3 = Vector3.ZERO
## The one building type this spot allows.
@export var building_id: StringName = &""
## A non-null run marks a wall plot (D-01): holding at it builds every segment of the run at once.
## The plot's kind is data, not an id convention; null is an ordinary plot.
@export var wall_run: WallRunDef
## True marks the castle plot (BLDG-08): the castle's upgrade plot, whose building is the castle. At
## most one per map. The plot's kind is data, not an id convention (the id `castle` is reserved for
## the dawn payout). The castle stands from the start, is never a target and never pays per-spot
## income; CastleState owns its health and numbers.
@export var is_castle: bool = false
