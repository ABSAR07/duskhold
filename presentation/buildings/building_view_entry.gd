class_name BuildingViewEntry
extends Resource
## One model-scene assignment: the scene shown for `building_id` at `tier` (1-based).

@export var building_id: StringName
@export var tier: int = 1
@export var scene: PackedScene
