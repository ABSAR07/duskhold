class_name KingDef
extends Resource
## King movement and passive-attack numbers.

## Walking speed in m/s: 7.5 by owner decision (UAT G-02-18, 2026-10-07), 1.5x the walk of the
## first three playtests. It sets the edge-to-edge ride of D-03 as amended (about 15 s on the
## prototype map).
@export var walk_speed: float = 7.5
## Sprint speed is walk_speed times this. 1.6 keeps the sprint at exactly 12 m/s at walk 7.5
## (owner decision 2026-10-07, G-02-18). The 12 m/s sprint itself is the owner's from UAT G-02-1
## (2026-10-06), half again as fast as the 8 m/s sprint of the first playtest; 1.6 is also the
## source game's walk/sprint ratio.
@export var sprint_multiplier: float = 1.6
## Rate (m/s squared) at which velocity approaches the target velocity. It is also the braking
## rate, and 60 keeps a full-sprint stop (v^2 / 2a = 1.2 m) and a walking stop (0.47 m) inside
## the build radius.
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
