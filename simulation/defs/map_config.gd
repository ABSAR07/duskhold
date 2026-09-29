class_name MapConfig
extends Resource
## Everything the simulation needs to know about one map. Data only.

@export var id: StringName = &""
@export var display_name: String = ""
## D-04: sandbox and test maps never appear in the campaign.
@export var is_sandbox: bool = true
@export var starting_gold: int = 0
@export var king_spawn: Vector3 = Vector3.ZERO
@export var castle_position: Vector3 = Vector3.ZERO
## The building set this map uses.
@export var buildings: Array[BuildingDef] = []
## Order is significant: it breaks nearest-spot ties and fixes payout order.
@export var spots: Array[BuildSpotDef] = []


## Human-readable data errors; empty when the map is well formed. (RED-phase stub.)
func validate() -> PackedStringArray:
	return PackedStringArray()
