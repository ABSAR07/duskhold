class_name WeaponDef
extends Resource
## What the king carries: a passive attack that fires on its own and an active slam the player
## triggers (D-17, D-18). The weapon is data, so the meta phases can swap it.

## Stable id of the weapon.
@export var id: StringName = &""
## Name shown to the player.
@export var display_name: String = ""
## Metres within which the passive attack reaches an enemy's centre (inclusive).
@export var attack_range: float = 3.0
## Damage of one passive attack.
@export var attack_damage: int = 3
## Seconds between two passive attacks.
@export var attack_interval: float = 0.8
## Metres around the king within which the slam reaches an enemy's centre (inclusive); 0 means
## the weapon has no slam.
@export var slam_radius: float = 0.0
## Damage the slam does to every enemy it reaches.
@export var slam_damage: int = 0
## Seconds before the slam can be used again.
@export var slam_cooldown_seconds: float = 0.0


## True when the weapon has a usable slam.
func is_slam_armed() -> bool:
	return false
