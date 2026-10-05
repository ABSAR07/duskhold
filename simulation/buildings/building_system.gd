class_name BuildingSystem
extends RefCounted
## Fixed build spots and the building standing on each. Reads never mutate; the mutations are
## apply_next_tier, which leaves affordability and range to CommandProcessor, its only caller, and
## damage_building, which the night's hit resolver calls (BLDG-07).
## The BuildingInstance objects handed out are snapshots, so a reader cannot change what stands on
## a spot. The BuildSpotDef and BuildingDef resources are shared with the MapConfig and returned
## by reference: treat them as read-only.

var _events: SimEvents
var _order: Array[StringName] = []
var _spots: Dictionary = {}
var _defs: Dictionary = {}
var _instances: Dictionary = {}


func _init(map: MapConfig, events: SimEvents) -> void:
	_events = events
	# A null entry is a data error MapConfig.validate() already reported; skip it rather than crash.
	for building_def: BuildingDef in map.buildings:
		# An empty or duplicate id is a reported data error too. Skip an empty id (a spot whose
		# building_id was left unset would otherwise resolve to it); keep the first def of a
		# duplicate, as spots do.
		if building_def == null or building_def.id == &"" or _defs.has(building_def.id):
			continue
		_defs[building_def.id] = building_def
	for spot: BuildSpotDef in map.spots:
		# An empty or duplicate id is also a reported data error. Skip an empty id (it could not be
		# told apart from "no spot in range"); keep the first def of a duplicate so spot_ids() is unique.
		if spot == null or spot.id == &"" or _spots.has(spot.id):
			continue
		_order.append(spot.id)
		_spots[spot.id] = spot


## Spot ids in MapConfig order. A copy: changing it cannot corrupt the system's own order.
func spot_ids() -> Array[StringName]:
	return _order.duplicate()


## Null if the spot is unknown.
func get_spot(spot_id: StringName) -> BuildSpotDef:
	return _spots.get(spot_id) as BuildSpotDef


func get_building_def_for_spot(spot_id: StringName) -> BuildingDef:
	var spot: BuildSpotDef = get_spot(spot_id)
	if spot == null:
		return null
	return _defs.get(spot.building_id) as BuildingDef


## A snapshot of the building on the spot: changing it does not change the building. Null if the
## spot is empty or unknown.
func get_instance(spot_id: StringName) -> BuildingInstance:
	return _snapshot(_instances.get(spot_id) as BuildingInstance)


## 0 if the spot is empty.
func current_tier(spot_id: StringName) -> int:
	var instance: BuildingInstance = _instances.get(spot_id) as BuildingInstance
	if instance == null:
		return 0
	return instance.tier


## Gold price of the next build or upgrade, or -1 when nothing can be bought.
func next_action_cost(spot_id: StringName) -> int:
	var tier_def: BuildingTierDef = _next_tier_def(spot_id)
	if tier_def == null:
		return -1
	return tier_def.cost


## What each standing building pays at dawn: spot_id -> gold, in MapConfig order, listing only
## spots whose current tier pays more than 0. A destroyed building pays nothing, and neither does
## one rebuilt this dawn (LOOP-05). Pure: it never mutates anything.
func dawn_income_by_spot() -> Dictionary:
	var income: Dictionary = {}
	for spot_id: StringName in _order:
		var instance: BuildingInstance = _instances.get(spot_id) as BuildingInstance
		if instance == null or instance.destroyed or instance.rebuilt_this_dawn:
			continue
		var building_def: BuildingDef = _defs.get(instance.building_id) as BuildingDef
		if building_def == null:
			continue
		var tier_def: BuildingTierDef = building_def.tier_def(instance.tier)
		if tier_def != null and tier_def.dawn_income > 0:
			income[spot_id] = tier_def.dawn_income
	return income


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


## Builds tier I on an empty spot or raises the tier by one, then emits building_built, and returns
## a snapshot of the building as it now stands.
## Affordability and range are not checked: only CommandProcessor calls this. Null, and nothing
## changes, for an unknown spot, a spot whose building has no definition, or a spot at max tier.
func apply_next_tier(spot_id: StringName) -> BuildingInstance:
	var spot: BuildSpotDef = get_spot(spot_id)
	if spot == null or _next_tier_def(spot_id) == null:
		return null
	var instance: BuildingInstance = _instances.get(spot_id) as BuildingInstance
	if instance == null:
		instance = BuildingInstance.new()
		instance.spot_id = spot_id
		instance.building_id = spot.building_id
		instance.tier = 1
		_instances[spot_id] = instance
	else:
		instance.tier += 1
	instance.health = _max_health_of(instance)
	_events.building_built.emit(spot_id, instance.building_id, instance.tier)
	return _snapshot(instance)


## Position of the spot in spot_ids(), the id a building hit carries; -1 for an unknown spot.
func spot_index(spot_id: StringName) -> int:
	return _order.find(spot_id)


## The spot at that index of spot_ids(); &"" when the index is out of range.
func spot_at_index(index: int) -> StringName:
	if index < 0 or index >= _order.size():
		return &""
	return _order[index]


## Spots with a building that has not fallen, in MapConfig order. A fresh array.
func standing_spot_ids() -> Array[StringName]:
	var standing: Array[StringName] = []
	for spot_id: StringName in _order:
		var instance: BuildingInstance = _instances.get(spot_id) as BuildingInstance
		if instance != null and not instance.destroyed:
			standing.append(spot_id)
	return standing


## True once the building on the spot has fallen; false for an empty or unknown spot.
func is_destroyed(spot_id: StringName) -> bool:
	var instance: BuildingInstance = _instances.get(spot_id) as BuildingInstance
	return instance != null and instance.destroyed


## Hit points left on the spot's building; 0 for an empty or unknown spot or a fallen building.
func health_of(spot_id: StringName) -> int:
	var instance: BuildingInstance = _instances.get(spot_id) as BuildingInstance
	return instance.health if instance != null else 0


## Hit points the building's current tier stands at; 0 for an empty or unknown spot.
func max_health_of(spot_id: StringName) -> int:
	return _max_health_of(_instances.get(spot_id) as BuildingInstance)


## Footprint radius of the building type the spot takes, standing or not; 0.0 for an unknown spot.
func radius_of(spot_id: StringName) -> float:
	var building_def: BuildingDef = get_building_def_for_spot(spot_id)
	return building_def.body_radius if building_def != null else 0.0


## Removes up to `amount` hit points (never below 0) from the spot's building and emits
## building_damaged with the points actually lost; the hit that reaches 0 then emits
## building_destroyed, once. A hit on an unknown spot, an empty plot or a fallen building, or a
## non-positive amount, is dropped silently: a hit on a thing that is gone is not an error.
func damage_building(spot_id: StringName, amount: int) -> void:
	var instance: BuildingInstance = _instances.get(spot_id) as BuildingInstance
	if instance == null or instance.destroyed or amount <= 0:
		return
	var lost: int = mini(amount, instance.health)
	instance.health -= lost
	_events.building_damaged.emit(spot_id, lost, instance.health, _max_health_of(instance))
	if instance.health == 0:
		instance.destroyed = true
		_events.building_destroyed.emit(spot_id, instance.building_id, instance.tier)


## Dawn (LOOP-04): stands every fallen building again at the tier it had, at full health, for no
## gold, and marks it rebuilt_this_dawn so it pays nothing at this dawn (LOOP-05). Returns the spot
## ids rebuilt in MapConfig order; a second call finds nothing left and returns an empty array.
func rebuild_destroyed() -> Array[StringName]:
	var rebuilt: Array[StringName] = []
	for spot_id: StringName in _order:
		var instance: BuildingInstance = _instances.get(spot_id) as BuildingInstance
		if instance == null or not instance.destroyed:
			continue
		instance.destroyed = false
		instance.health = _max_health_of(instance)
		instance.rebuilt_this_dawn = true
		rebuilt.append(spot_id)
	return rebuilt


## Dawn: every standing building is back at its tier's full health. A fallen building is left to
## rebuild_destroyed.
func repair_standing() -> void:
	for spot_id: StringName in _order:
		var instance: BuildingInstance = _instances.get(spot_id) as BuildingInstance
		if instance != null and not instance.destroyed:
			instance.health = _max_health_of(instance)


## A new night: no building counts as rebuilt this dawn any more.
func clear_rebuilt_marks() -> void:
	for instance: BuildingInstance in _instances.values():
		instance.rebuilt_this_dawn = false


## A copy of `instance` that nothing else holds; null for null.
func _snapshot(instance: BuildingInstance) -> BuildingInstance:
	if instance == null:
		return null
	var copy: BuildingInstance = BuildingInstance.new()
	copy.spot_id = instance.spot_id
	copy.building_id = instance.building_id
	copy.tier = instance.tier
	copy.health = instance.health
	copy.destroyed = instance.destroyed
	copy.rebuilt_this_dawn = instance.rebuilt_this_dawn
	return copy


## Hit points of the instance's current tier; 0 for null or a building no map definition covers.
func _max_health_of(instance: BuildingInstance) -> int:
	if instance == null:
		return 0
	var building_def: BuildingDef = _defs.get(instance.building_id) as BuildingDef
	if building_def == null:
		return 0
	var tier_def: BuildingTierDef = building_def.tier_def(instance.tier)
	return tier_def.max_health if tier_def != null else 0


## Null at max tier or for an unknown spot.
func _next_tier_def(spot_id: StringName) -> BuildingTierDef:
	var building_def: BuildingDef = get_building_def_for_spot(spot_id)
	if building_def == null:
		return null
	return building_def.tier_def(current_tier(spot_id) + 1)
