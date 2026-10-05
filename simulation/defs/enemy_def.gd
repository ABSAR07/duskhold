class_name EnemyDef
extends Resource
## One enemy type. Data only: every number lives in .tres (D-09). Seconds here are converted to
## whole simulation ticks once, with SimClock.ticks.

@export var id: StringName = &""
@export var display_name: String = ""
## Hit points; an enemy dies at 0.
@export var max_health: int = 1
## Metres per second on the ground.
@export var move_speed: float = 3.0
## Body radius in metres; also the puppet's capsule radius.
@export var radius: float = 0.5
## Metres from its target's edge at which the enemy stops and attacks.
@export var attack_range: float = 1.0
## Damage per hit.
@export var attack_damage: int = 1
## Seconds between two attacks.
@export var attack_interval: float = 1.0
## Metres within which the enemy notices a target on its way to the castle.
@export var aggro_range: float = 6.0
## Metres beyond which the enemy gives up a target it chased.
@export var leash_range: float = 10.0
## Seconds between looking for a nearer target.
@export var retarget_interval_seconds: float = 0.5
## Metres per second of a ranged attacker's shot; 0.0 means a melee enemy.
@export var projectile_speed: float = 0.0
