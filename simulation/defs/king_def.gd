class_name KingDef
extends Resource
## King movement numbers. The 1.6 ratio is the source game's walk-to-sprint ratio.

@export var walk_speed: float = 5.0
@export var sprint_multiplier: float = 1.6
## Rate (m/s squared) at which velocity approaches the target velocity.
@export var acceleration: float = 40.0
## Rate (rad/s) at which the model turns to face the movement direction.
@export var turn_speed: float = 12.0
