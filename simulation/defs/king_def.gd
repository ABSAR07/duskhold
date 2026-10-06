class_name KingDef
extends Resource
## King movement and passive-attack numbers.

@export var walk_speed: float = 5.0
## Sprint speed is walk_speed times this: 12 m/s at walk 5.0 by owner decision (UAT G-02-1,
## 2026-10-06), half again as fast as the 8 m/s sprint of the first playtest.
@export var sprint_multiplier: float = 2.4
## Rate (m/s squared) at which velocity approaches the target velocity. It is also the braking
## rate, and 60 keeps a full-sprint stop (v^2 / 2a = 1.2 m) inside the build radius.
@export var acceleration: float = 60.0
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
