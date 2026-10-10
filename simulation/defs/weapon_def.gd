class_name WeaponDef
extends Resource
## What the king carries: a passive attack that fires on its own and an active slam the player
## triggers (D-17, D-18). The weapon is data, so the meta phases can swap it.

## The longest slam cooldown that counts as a real one: an hour.
const MAX_SLAM_COOLDOWN_S: float = 3600.0

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


## True when the weapon has a usable slam: a finite radius above 0, damage above 0 and a finite
## cooldown from one simulation step to MAX_SLAM_COOLDOWN_S. A sub-step cooldown would let the slam
## fire every tick (SimClock.ticks floors at one tick) and a NaN or infinite number fails the
## bounds, so bad data can never make the slam free or permanent (T-03-08). This follows
## CastleAttack.is_armed.
func is_slam_armed() -> bool:
	return (
		is_finite(slam_radius)
		and slam_radius > 0.0
		and slam_damage > 0
		and is_finite(slam_cooldown_seconds)
		and slam_cooldown_seconds >= SimClock.STEP
		and slam_cooldown_seconds <= MAX_SLAM_COOLDOWN_S
	)
