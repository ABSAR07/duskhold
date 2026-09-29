class_name BuildingViewCatalog
extends Resource
## Lookup from (building_id, tier) to a model scene, plus the castle landmark scene. A missing
## entry returns null so BuildingViews falls back to its primitive stand-in.

@export var entries: Array[BuildingViewEntry] = []
@export var castle_scene: PackedScene


## The scene for this building and tier, or null if none is assigned.
func find(building_id: StringName, tier: int) -> PackedScene:
	for entry: BuildingViewEntry in entries:
		if entry != null and entry.building_id == building_id and entry.tier == tier:
			return entry.scene
	return null


func find_castle() -> PackedScene:
	return castle_scene
