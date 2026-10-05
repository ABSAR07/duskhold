class_name MapConfig
extends Resource
## Everything the simulation needs to know about one map. Data only.

@export var id: StringName = &""
@export var display_name: String = ""
## D-04: sandbox and test maps never appear in the campaign.
@export var is_sandbox: bool = true
@export var starting_gold: int = 0
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
	var spot_ids: Dictionary = {}
	for spot: BuildSpotDef in spots:
		if spot == null:
			errors.append("a spot entry is empty")
			continue
		if spot.id == &"":
			errors.append("a spot has an empty id")
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
	var enemy_ids: Dictionary = {}
	for enemy: EnemyDef in enemies:
		if enemy == null:
			errors.append("an enemy entry is empty")
			continue
		if enemy.id == &"" or enemy_ids.has(enemy.id):
			errors.append("enemy id '%s' is empty or duplicated" % enemy.id)
		enemy_ids[enemy.id] = true
		if enemy.max_health <= 0:
			errors.append("enemy '%s' max_health is %d" % [enemy.id, enemy.max_health])
	var spawn_ids: Dictionary = {}
	for spawn_point: SpawnPointDef in spawn_points:
		if spawn_point == null:
			errors.append("a spawn point entry is empty")
			continue
		if spawn_point.id == &"" or spawn_ids.has(spawn_point.id):
			errors.append("spawn point id '%s' is empty or duplicated" % spawn_point.id)
		spawn_ids[spawn_point.id] = true
	for index: int in range(nights.size()):
		errors.append_array(_validate_night(index + 1, nights[index], enemy_ids, spawn_ids))
	return errors


func _validate_night(
	night_number: int, night: NightDef, enemy_ids: Dictionary, spawn_ids: Dictionary
) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if night == null:
		errors.append("night %d is empty" % night_number)
		return errors
	var total: int = 0
	for group: SpawnGroupDef in night.groups:
		if group == null:
			errors.append("night %d has an empty group" % night_number)
			continue
		if not spawn_ids.has(group.spawn_point_id):
			errors.append(
				"night %d uses unknown spawn point '%s'" % [night_number, group.spawn_point_id]
			)
		if not enemy_ids.has(group.enemy_id):
			errors.append("night %d uses unknown enemy '%s'" % [night_number, group.enemy_id])
		if group.count <= 0 or group.start_delay_seconds < 0.0 or group.interval_seconds < 0.0:
			errors.append("night %d has a group with a bad count or delay" % night_number)
		total += maxi(group.count, 0)
	if total <= 0:
		errors.append("night %d spawns no enemy" % night_number)
	return errors
