extends GutTest
## Review WR-04: MapConfig.validate() reports a wall plot whose building has no tiers or a tier
## without health, instead of letting the player pay for a marker that never becomes a wall. Each
## bad case edits a deep copy of the shipped map (like test_map_wall_validation).

const RING: int = 13


func _map() -> MapConfig:
	return E2eSupport.shipped_prototype_map()


func _wall_building(map: MapConfig) -> BuildingDef:
	var plot_building: StringName = map.spots[RING].building_id
	for building_def: BuildingDef in map.buildings:
		if building_def != null and building_def.id == plot_building:
			return building_def
	return null


func test_the_shipped_wall_building_has_health_in_every_tier() -> void:
	var map: MapConfig = _map()
	var building_def: BuildingDef = _wall_building(map)
	assert_not_null(building_def, "the ring plot names a building")
	assert_gt(building_def.tiers.size(), 0, "with at least one tier")
	assert_eq(WallValidation.errors(map), PackedStringArray(), "and its walls are clean")


func test_a_wall_building_without_tiers_is_reported() -> void:
	var map: MapConfig = _map()
	var no_tiers: Array[BuildingTierDef] = []
	_wall_building(map).tiers = no_tiers
	var errors: PackedStringArray = WallValidation.errors(map)
	assert_gt(errors.size(), 0, "a building with no tiers is reported: %s" % [errors])
	if errors.size() > 0:
		assert_string_contains(errors[0], "wall plot 'wall_", "names the plot")
		assert_string_contains(errors[0], "no tiers", "and the problem")


func test_a_wall_tier_without_health_is_reported() -> void:
	for health: int in [0, -5]:
		var map: MapConfig = _map()
		_wall_building(map).tiers[0].max_health = health
		var errors: PackedStringArray = WallValidation.errors(map)
		assert_gt(errors.size(), 0, "max_health %d is reported: %s" % [health, errors])
		if errors.size() > 0:
			assert_string_contains(errors[0], "wall plot 'wall_", "names the plot")
			assert_string_contains(errors[0], "tier 1 has no health", "and the tier")
