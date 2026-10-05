class_name BuildingTierDef
extends Resource
## One purchasable tier of a building. Data only: every number lives in .tres (D-09).

## Gold price of this tier.
@export var cost: int = 1
## Gold this tier pays at dawn (0 for non-economy buildings).
@export var dawn_income: int = 0
## Attack range in metres (0.0 for non-defense buildings).
@export var attack_range: float = 0.0
## Damage per hit (0 for non-defense buildings).
@export var attack_damage: int = 0
## Hit points this tier stands at when built, upgraded or rebuilt (BLDG-07). Must be above 0.
@export var max_health: int = 10
## Seconds between a tower's shots (towers only; read by the tower plan).
@export var attack_interval: float = 1.0
## Metres per second of a tower's arrow (towers only; read by the tower plan).
@export var projectile_speed: float = 0.0


## One-line effect text shown next to the cost, e.g. "+2 gold at dawn".
func effect_line() -> String:
	if dawn_income > 0:
		return "+%d gold at dawn" % dawn_income
	if attack_damage > 0:
		return "Range %s · Damage %d" % [String.num(attack_range), attack_damage]
	return ""
