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
## Units this tier fields; 0 for non-military buildings.
@export var squad_size: int = 0
## Seconds per replacement unit at night (read by the squad respawn rule).
@export var squad_respawn_seconds: float = 0.0
## The cards this tier is bought with (BLDG-05): the player picks exactly one when buying it, and
## the pick lasts the run. Empty means no branching, a plain upgrade. Any building tier may carry
## cards; the castle's tier II is the first user.
@export var choices: Array[ChoiceDef] = []
## The castle tier this tier needs before it can be bought (D-03, BLDG-09). 0 means none. Checked
## only on a map that has a castle plot; a castle exactly at this tier is enough.
@export var requires_castle_tier: int = 0
## Gold a DECLINING building (the Gold Mine only) pays less at each later dawn it pays. For such a
## building dawn_income is the first payout. 0 on every other curve; MapConfig.validate() reports a
## value set where the curve does not use it.
@export var income_step: int = 0
## The least a DECLINING building ever pays at a dawn it stands, never 0 (D-12). 0 on every other
## curve, like income_step.
@export var income_floor: int = 0


## One-line effect text shown next to the cost, e.g. "+2 gold at dawn".
func effect_line() -> String:
	if dawn_income > 0:
		return "+%d gold at dawn" % dawn_income
	if attack_damage > 0:
		return "Range %s · Damage %d" % [String.num(attack_range), attack_damage]
	if squad_size > 0:
		return "Squad of %d" % squad_size
	return ""
