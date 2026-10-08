class_name MapConfig
extends Resource
## Everything the simulation needs to know about one map. Data only.

## The most enemies one night may bring. This is a resource-exhaustion guard against a bad data
## file (threat T-02-04), not a tuning value: a night above it is a validate() error.
const MAX_ENEMIES_PER_NIGHT: int = 300

## The longest castle_attack_interval in seconds (one hour). Like MAX_ENEMIES_PER_NIGHT a guard
## against a bad data file, not a tuning value: a longer interval, such as a typo with an extra
## exponent digit, is a validate() error and never arms the castle (review WR-01).
const MAX_CASTLE_ATTACK_INTERVAL_S: float = 3600.0

## The reserved dawn_payout per_spot key the base income is listed under. No spot may use this id
## (validate() reports it), so a House entry can never be merged with the base income.
const CASTLE_PAYOUT_KEY: StringName = &"castle"

@export var id: StringName = &""
@export var display_name: String = ""
## D-04: sandbox and test maps never appear in the campaign.
@export var is_sandbox: bool = true
@export var starting_gold: int = 0
## Gold every dawn pays besides the buildings, even when no House stands (owner decision
## 2026-10-06, G-02-1): the castle's own income, listed in the dawn payout under CASTLE_PAYOUT_KEY.
## 0 switches it off, which keeps every fixture and the smoke golden unchanged. Towers still pay
## nothing at dawn (D-10).
@export var base_dawn_income: int = 0
@export var king_spawn: Vector3 = Vector3.ZERO
@export var castle_position: Vector3 = Vector3.ZERO
## The building set this map uses.
@export var buildings: Array[BuildingDef] = []
## Order is significant: it breaks nearest-spot ties and fixes payout order.
@export var spots: Array[BuildSpotDef] = []
## The enemy types this map's nights use.
@export var enemies: Array[EnemyDef] = []
## Where enemies arrive from. Order is significant: it fixes the telegraph and preview order.
@export var spawn_points: Array[SpawnPointDef] = []
## The hand-authored nights. `nights[0]` is night 1 and the total number of nights is
## `nights.size()`. An empty list means a waveless map that keeps the Phase 1 timed night.
@export var nights: Array[NightDef] = []
## Hit points of the castle centre; the run is lost when it reaches 0.
@export var castle_max_health: int = 40
## Radius of the castle in metres; enemies stop at this plus their own attack range.
@export var castle_radius: float = 3.5
## The castle's own attack: a simple shot at the nearest enemy whose centre is within
## castle_attack_range, every castle_attack_interval seconds, as an arrow flying at
## castle_projectile_speed metres per second (0 would hit at once). Damage and rate were chosen on
## 2026-10-06 (G-02-1 point 2); reach and arrow speed were raised on 2026-10-07 (G-02-13: 22 m and
## 27 m/s on the shipped map). 0 damage switches the castle attack off, which keeps every fixture
## and the smoke golden unchanged.
@export var castle_attack_damage: int = 0
@export var castle_attack_range: float = 0.0
@export var castle_attack_interval: float = 0.0
@export var castle_projectile_speed: float = 0.0


## The enemy type with this id, or null.
func find_enemy(enemy_id: StringName) -> EnemyDef:
	for enemy: EnemyDef in enemies:
		if enemy != null and enemy.id == enemy_id:
			return enemy
	return null


## The spawn point with this id, or null.
func find_spawn_point(spawn_point_id: StringName) -> SpawnPointDef:
	for spawn_point: SpawnPointDef in spawn_points:
		if spawn_point != null and spawn_point.id == spawn_point_id:
			return spawn_point
	return null


## The definition of a 1-based night number; null when the number is outside 1..nights.size().
func night_def(night_number: int) -> NightDef:
	if night_number < 1 or night_number > nights.size():
		return null
	return nights[night_number - 1]


## Human-readable data errors; empty when the map is well formed (T-01-10).
func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if starting_gold < 0:
		errors.append("starting_gold is negative (%d)" % starting_gold)
	if base_dawn_income < 0:
		errors.append("base_dawn_income is negative (%d)" % base_dawn_income)
	var building_ids: Dictionary = {}
	for building_def: BuildingDef in buildings:
		if building_def == null:
			errors.append("a building entry is empty")
			continue
		if building_def.id == &"":
			errors.append("a building has an empty id")
		if building_ids.has(building_def.id):
			errors.append("duplicate building id '%s'" % building_def.id)
		building_ids[building_def.id] = true
		if building_def.tiers.is_empty():
			errors.append("building '%s' has no tiers" % building_def.id)
		for index: int in range(building_def.tiers.size()):
			var tier: BuildingTierDef = building_def.tiers[index]
			if tier == null:
				errors.append("building '%s' tier %d is empty" % [building_def.id, index + 1])
				continue
			if tier.cost <= 0:
				errors.append(
					"building '%s' tier %d cost is %d" % [building_def.id, index + 1, tier.cost]
				)
			if tier.dawn_income < 0:
				errors.append(
					"building '%s' tier %d dawn_income is negative" % [building_def.id, index + 1]
				)
			if tier.max_health <= 0:
				errors.append(
					(
						"building '%s' tier %d max_health is %d"
						% [building_def.id, index + 1, tier.max_health]
					)
				)
			errors.append_array(_validate_tier_combat(building_def.id, index, tier))
	var spot_ids: Dictionary = {}
	for spot: BuildSpotDef in spots:
		if spot == null:
			errors.append("a spot entry is empty")
			continue
		if spot.id == &"":
			errors.append("a spot has an empty id")
		if spot.id == CASTLE_PAYOUT_KEY:
			errors.append("spot id '%s' is reserved for the base income payout" % spot.id)
		if spot_ids.has(spot.id):
			errors.append("duplicate spot id '%s'" % spot.id)
		spot_ids[spot.id] = true
		if not building_ids.has(spot.building_id):
			errors.append("spot '%s' uses unknown building id '%s'" % [spot.id, spot.building_id])
	errors.append_array(_validate_night_data())
	return errors


func _validate_night_data() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if castle_max_health <= 0:
		errors.append("castle_max_health is %d" % castle_max_health)
	if not is_finite(castle_radius):
		errors.append("castle_radius is not finite (%s)" % castle_radius)
	elif castle_radius <= 0.0:
		errors.append("castle_radius is %s" % castle_radius)
	errors.append_array(_validate_castle_attack())
	var enemy_ids: Dictionary = {}
	for enemy: EnemyDef in enemies:
		if enemy == null:
			errors.append("an enemy entry is empty")
			continue
		if enemy.id == &"":
			errors.append("an enemy has an empty id")
		if enemy_ids.has(enemy.id):
			errors.append("duplicate enemy id '%s'" % enemy.id)
		enemy_ids[enemy.id] = true
		errors.append_array(_validate_enemy(enemy))
	var spawn_ids: Dictionary = {}
	for spawn_point: SpawnPointDef in spawn_points:
		if spawn_point == null:
			errors.append("a spawn point entry is empty")
			continue
		if spawn_point.id == &"":
			errors.append("a spawn point has an empty id")
		if spawn_ids.has(spawn_point.id):
			errors.append("duplicate spawn point id '%s'" % spawn_point.id)
		spawn_ids[spawn_point.id] = true
	for index: int in range(nights.size()):
		errors.append_array(_validate_night(index + 1, nights[index], enemy_ids, spawn_ids))
	return errors


## The errors of the castle's attack numbers (T-02-33, review WR-02): none may be negative or not
## finite, and a castle that attacks (damage above 0) needs a range and an interval above 0, else
## it would never or always shoot. An infinite interval, or one below a simulation step, would make
## the castle fire every tick because SimClock.ticks floors at one tick, and a NaN would silently
## disarm it, so all of them are reported. An interval above MAX_CASTLE_ATTACK_INTERVAL_S is
## reported too (review WR-01). A value that is not finite or is negative is reported once, as
## that, not again as missing.
func _validate_castle_attack() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if castle_attack_damage < 0:
		errors.append("castle_attack_damage is negative (%d)" % castle_attack_damage)
	errors.append_array(_castle_number_errors("castle_attack_range", castle_attack_range))
	errors.append_array(_castle_number_errors("castle_attack_interval", castle_attack_interval))
	errors.append_array(_castle_number_errors("castle_projectile_speed", castle_projectile_speed))
	if castle_attack_damage > 0 and castle_attack_range == 0.0:
		errors.append("castle_attack_range is 0 but the castle attacks (castle_attack_damage > 0)")
	if castle_attack_damage > 0 and castle_attack_interval == 0.0:
		errors.append(
			"castle_attack_interval is 0 but the castle attacks (castle_attack_damage > 0)"
		)
	if (
		castle_attack_damage > 0
		and is_finite(castle_attack_interval)
		and castle_attack_interval > 0.0
		and castle_attack_interval < SimClock.STEP
	):
		errors.append(
			"castle_attack_interval is below one simulation step (%s)" % castle_attack_interval
		)
	if is_finite(castle_attack_interval) and castle_attack_interval > MAX_CASTLE_ATTACK_INTERVAL_S:
		errors.append(
			(
				"castle_attack_interval (%s) is above the longest allowed (%s s)"
				% [castle_attack_interval, MAX_CASTLE_ATTACK_INTERVAL_S]
			)
		)
	return errors


## The errors of one castle float: not finite, or negative.
func _castle_number_errors(field: String, value: float) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if not is_finite(value):
		errors.append("%s is not finite (%s)" % [field, value])
	elif value < 0.0:
		errors.append("%s is negative (%s)" % [field, value])
	return errors


## The errors of one enemy type's numbers. An enemy only attacks once it has a target, and it only
## gets one when the target's edge is within aggro_range, yet it stops walking at attack_range from
## that edge: with aggro_range at or below attack_range it would stand there forever, and a real
## night has no clock to end it (WR-01). The comparison is strict because at equality float
## rounding in the stop position can leave the edge a hair beyond aggro_range. A float that is NaN
## or infinite passes every one of those comparisons, so it is reported once, as that, and the
## range comparisons are skipped (review IN-03).
func _validate_enemy(enemy: EnemyDef) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if enemy.max_health <= 0:
		errors.append("enemy '%s' max_health is %d" % [enemy.id, enemy.max_health])
	var enemy_floats: Dictionary = {
		"move_speed": enemy.move_speed,
		"radius": enemy.radius,
		"attack_range": enemy.attack_range,
		"attack_interval": enemy.attack_interval,
		"aggro_range": enemy.aggro_range,
		"leash_range": enemy.leash_range,
		"retarget_interval_seconds": enemy.retarget_interval_seconds,
		"projectile_speed": enemy.projectile_speed,
	}
	var all_finite: bool = true
	for field: String in enemy_floats:
		var value: float = enemy_floats[field]
		if not is_finite(value):
			all_finite = false
			errors.append("enemy '%s' %s is not finite (%s)" % [enemy.id, field, value])
	if not all_finite:
		return errors
	if enemy.move_speed <= 0.0:
		errors.append("enemy '%s' move_speed is %s" % [enemy.id, enemy.move_speed])
	if enemy.attack_interval <= 0.0:
		errors.append("enemy '%s' attack_interval is %s" % [enemy.id, enemy.attack_interval])
	if enemy.radius <= 0.0:
		errors.append("enemy '%s' radius is %s" % [enemy.id, enemy.radius])
	if enemy.attack_range < 0.0:
		errors.append("enemy '%s' attack_range is %s" % [enemy.id, enemy.attack_range])
	if enemy.aggro_range <= enemy.attack_range:
		errors.append(
			(
				"enemy '%s' aggro_range (%s) is not above attack_range (%s): it would never attack"
				% [enemy.id, enemy.aggro_range, enemy.attack_range]
			)
		)
	if enemy.leash_range < enemy.aggro_range:
		errors.append(
			(
				"enemy '%s' leash_range (%s) is below aggro_range (%s)"
				% [enemy.id, enemy.leash_range, enemy.aggro_range]
			)
		)
	if enemy.retarget_interval_seconds <= 0.0:
		errors.append(
			(
				"enemy '%s' retarget_interval_seconds is %s"
				% [enemy.id, enemy.retarget_interval_seconds]
			)
		)
	if enemy.projectile_speed < 0.0:
		errors.append("enemy '%s' projectile_speed is %s" % [enemy.id, enemy.projectile_speed])
	return errors


## The errors of one building tier's combat numbers; the ones a tower's shots depend on.
func _validate_tier_combat(
	building_id: StringName, index: int, tier: BuildingTierDef
) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var label: String = "building '%s' tier %d" % [building_id, index + 1]
	if tier.attack_range < 0.0:
		errors.append("%s attack_range is %s" % [label, tier.attack_range])
	if tier.attack_interval <= 0.0:
		errors.append("%s attack_interval is %s" % [label, tier.attack_interval])
	if tier.projectile_speed < 0.0:
		errors.append("%s projectile_speed is %s" % [label, tier.projectile_speed])
	return errors


## The errors of one night (1-based). A night that totals no enemy is reported once: when its
## groups are missing, or when every group is already reported for its own count.
func _validate_night(
	night_number: int, night: NightDef, enemy_ids: Dictionary, spawn_ids: Dictionary
) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if night == null:
		errors.append("night %d is empty" % night_number)
		return errors
	var total: int = 0
	for index: int in range(night.groups.size()):
		var group: SpawnGroupDef = night.groups[index]
		var label: String = "night %d group %d" % [night_number, index + 1]
		if group == null:
			errors.append("%s is empty" % label)
			continue
		if not spawn_ids.has(group.spawn_point_id):
			errors.append("%s uses unknown spawn point '%s'" % [label, group.spawn_point_id])
		if not enemy_ids.has(group.enemy_id):
			errors.append("%s uses unknown enemy '%s'" % [label, group.enemy_id])
		if group.count <= 0:
			errors.append("%s has count %d" % [label, group.count])
		if group.start_delay_seconds < 0.0:
			errors.append("%s has a negative start_delay_seconds" % label)
		if group.interval_seconds < 0.0:
			errors.append("%s has a negative interval_seconds" % label)
		total += maxi(group.count, 0)
	if total <= 0 and errors.is_empty():
		errors.append("night %d has no enemies" % night_number)
	if total > MAX_ENEMIES_PER_NIGHT:
		errors.append(
			(
				"night %d has %d enemies, more than the %d allowed"
				% [night_number, total, MAX_ENEMIES_PER_NIGHT]
			)
		)
	return errors
