class_name KingDef
extends Resource
## King movement numbers and the weapon he carries (D-18): the passive attack and the slam live
## on the WeaponDef.

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
## Seconds after the last hit taken before he starts to heal (D-20). 0 together with a fraction of
## 0 switches regeneration off, which keeps fixtures and the smoke golden unchanged; a negative or
## non-finite delay counts as 0.
@export var regen_delay_seconds: float = 0.0
## Share of his maximum health he regains per second once the delay has passed (D-20), as whole
## points. 0, a negative or a non-finite value switches regeneration off.
@export var regen_fraction_per_second: float = 0.0
## The weapon the king carries (D-18). Null falls back to the WeaponDef defaults.
@export var weapon: WeaponDef
