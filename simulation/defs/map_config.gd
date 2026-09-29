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
	return errors
