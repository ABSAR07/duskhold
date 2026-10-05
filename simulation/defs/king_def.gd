class_name KingDef
extends Resource
## King movement and passive-attack numbers. The 1.6 ratio is the source game's walk-to-sprint
## ratio.

@export var walk_speed: float = 5.0
@export var sprint_multiplier: float = 1.6
## Rate (m/s squared) at which velocity approaches the target velocity.
@export var acceleration: float = 40.0
## Rate (rad/s) at which the model turns to face the movement direction.
@export var turn_speed: float = 12.0
## Hit points; the king is knocked out at 0.
@export var max_health: int = 30
## Radius of the king's body in metres.
@export var body_radius: float = 0.6
## Metres within which the passive attack reaches an enemy's centre (inclusive).
@export var attack_range: float = 3.0
## Damage of one passive attack.
@export var attack_damage: int = 3
## Seconds between two passive attacks.
@export var attack_interval: float = 0.8
