class_name UnitDef
extends Resource
## One friendly unit type, fielded by a military building. Data only: every number lives in .tres
## (D-09). Seconds here are converted to whole simulation ticks once, with SimClock.ticks.

@export var id: StringName = &""
@export var display_name: String = ""
## Hit points; a unit dies at 0.
@export var max_health: int = 10
## Metres per second on the ground.
@export var move_speed: float = 4.0
## Body radius in metres; also the puppet's collision-free footprint for the push-apart pass.
@export var radius: float = 0.45
## Metres from an enemy's edge (melee) or centre (ranged) at which the unit stops and attacks.
@export var attack_range: float = 1.2
## Damage per hit.
@export var attack_damage: int = 1
## Seconds between two attacks.
@export var attack_interval: float = 0.6
## Metres from the squad anchor within which a free unit takes an enemy as its target.
@export var guard_range: float = 7.0
## Metres from the squad anchor beyond which a committed unit gives its target up.
@export var leash_range: float = 12.0
## Seconds between looking for a target while the unit has none.
@export var retarget_interval_seconds: float = 0.5
## Metres per second of a ranged unit's shot; 0.0 means a melee unit.
@export var projectile_speed: float = 0.0
## Metres between neighbouring formation slots.
@export var formation_spacing: float = 1.2
