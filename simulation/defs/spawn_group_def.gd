class_name SpawnGroupDef
extends Resource
## A run of identical enemies arriving from one spawn point. Data only.

## The SpawnPointDef.id the group arrives from.
@export var spawn_point_id: StringName = &""
## The EnemyDef.id of every enemy in the group.
@export var enemy_id: StringName = &""
## How many enemies the group contains.
@export var count: int = 1
## Seconds after the night starts at which the first enemy spawns.
@export var start_delay_seconds: float = 0.0
## Seconds between two enemies of the group; 0.0 spawns the whole group on one tick.
@export var interval_seconds: float = 1.0
