class_name BuildingSystem
extends RefCounted
## Fixed build spots and the building standing on each. Reads never mutate; the only mutation
## is apply_next_tier, which performs no validation because CommandProcessor is its only caller.

var _events: SimEvents
var _order: Array[StringName] = []
var _spots: Dictionary = {}
var _defs: Dictionary = {}
var _instances: Dictionary = {}


func _init(map: MapConfig, events: SimEvents) -> void:
	_events = events
	for building_def: BuildingDef in map.buildings:
		_defs[building_def.id] = building_def
	for spot: BuildSpotDef in map.spots:
		_order.append(spot.id)
		_spots[spot.id] = spot


## Spot ids in MapConfig order.
func spot_ids() -> Array[StringName]:
	return _order


## Null if the spot is unknown.
func get_spot(spot_id: StringName) -> BuildSpotDef:
	return _spots.get(spot_id) as BuildSpotDef


func get_building_def_for_spot(spot_id: StringName) -> BuildingDef:
	var spot: BuildSpotDef = get_spot(spot_id)
	if spot == null:
		return null
	return _defs.get(spot.building_id) as BuildingDef


## Null if the spot is empty or unknown.
func get_instance(spot_id: StringName) -> BuildingInstance:
	return _instances.get(spot_id) as BuildingInstance


## 0 if the spot is empty.
func current_tier(spot_id: StringName) -> int:
	var instance: BuildingInstance = get_instance(spot_id)
	if instance == null:
		return 0
	return instance.tier


## Null at max tier or for an unknown spot.
func next_tier_def(spot_id: StringName) -> BuildingTierDef:
	var building_def: BuildingDef = get_building_def_for_spot(spot_id)
	if building_def == null:
		return null
	return building_def.tier_def(current_tier(spot_id) + 1)


## Gold price of the next build or upgrade, or -1 when nothing can be bought.
func next_action_cost(spot_id: StringName) -> int:
	var tier_def: BuildingTierDef = next_tier_def(spot_id)
	if tier_def == null:
		return -1
	return tier_def.cost


## Nearest spot within `radius` (XZ distance, inclusive). Ties go to the earlier MapConfig
## order. Returns &"" if none is in range.
func nearest_spot_in_range(pos: Vector3, radius: float) -> StringName:
	var best_id: StringName = &""
	var best_distance: float = INF
	var flat: Vector2 = Vector2(pos.x, pos.z)
	for spot_id: StringName in _order:
		var spot: BuildSpotDef = _spots[spot_id]
		var distance: float = flat.distance_to(Vector2(spot.position.x, spot.position.z))
		if distance <= radius and distance < best_distance:
			best_distance = distance
			best_id = spot_id
	return best_id


## Builds tier I on an empty spot or raises the tier by one, then emits building_built.
## NO validation: only CommandProcessor calls this. Null for an unknown spot.
func apply_next_tier(spot_id: StringName) -> BuildingInstance:
	var spot: BuildSpotDef = get_spot(spot_id)
	if spot == null:
		return null
	var instance: BuildingInstance = get_instance(spot_id)
	if instance == null:
		instance = BuildingInstance.new()
		instance.spot_id = spot_id
		instance.building_id = spot.building_id
		instance.tier = 1
		_instances[spot_id] = instance
	else:
		instance.tier += 1
	_events.building_built.emit(spot_id, instance.building_id, instance.tier)
	return instance
