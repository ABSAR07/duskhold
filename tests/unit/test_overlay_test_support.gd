extends GutTest
## OverlayTestSupport promises private copies of the cached map and tuning. A copy that still shared
## a building definition or tier with the cached resource would let one suite's edit change the next
## suite's data, so the result of a run would depend on script order.


func test_new_map_shares_no_building_definition_or_tier_with_the_cached_map() -> void:
	var cached: MapConfig = load(OverlayTestSupport.PROTOTYPE_MAP)
	var copy: MapConfig = OverlayTestSupport.new_map()

	assert_ne(copy, cached, "the map is a copy")
	assert_gt(
		cached.buildings.size(), 0, "the map has buildings, so the loops below check something"
	)
	assert_eq(copy.buildings.size(), cached.buildings.size(), "with the same building set")
	for index: int in copy.buildings.size():
		var copy_def: BuildingDef = copy.buildings[index]
		var cached_def: BuildingDef = cached.buildings[index]
		assert_ne(copy_def, cached_def, "building '%s' is a copy" % cached_def.id)
		assert_gt(cached_def.tiers.size(), 0, "'%s' has tiers to compare" % cached_def.id)
		assert_eq(copy_def.tiers.size(), cached_def.tiers.size(), "with the same tiers")
		for tier_index: int in copy_def.tiers.size():
			assert_ne(
				copy_def.tiers[tier_index],
				cached_def.tiers[tier_index],
				"tier %d of '%s' is a copy" % [tier_index + 1, cached_def.id]
			)


func test_editing_a_new_map_copy_leaves_the_cached_map_and_later_copies_alone() -> void:
	var cached: MapConfig = load(OverlayTestSupport.PROTOTYPE_MAP)
	var cost_before: int = cached.buildings[0].tiers[0].cost
	var income_before: int = cached.buildings[0].tiers[0].dawn_income

	var copy: MapConfig = OverlayTestSupport.new_map()
	copy.buildings[0].tiers[0].cost = cost_before + 100
	copy.buildings[0].tiers[0].dawn_income = income_before + 100
	copy.spots[0].position = Vector3(123.0, 0.0, 456.0)

	assert_eq(cached.buildings[0].tiers[0].cost, cost_before, "the cached cost is unchanged")
	assert_eq(cached.buildings[0].tiers[0].dawn_income, income_before, "and its dawn income")
	assert_ne(cached.spots[0].position, copy.spots[0].position, "and its spot position")
	var later: MapConfig = OverlayTestSupport.new_map()
	assert_eq(later.buildings[0].tiers[0].cost, cost_before, "a later copy starts clean")


func test_a_new_map_copy_is_still_a_valid_map_whose_spots_resolve_to_its_own_buildings() -> void:
	var copy: MapConfig = OverlayTestSupport.new_map()

	assert_eq(copy.validate(), PackedStringArray(), "the copy has no data errors")
	var ctx: RunContext = RunContext.new(copy, OverlayTestSupport.new_tuning())
	assert_eq(ctx.buildings.spot_ids().size(), copy.spots.size(), "every spot is registered")


func test_editing_a_new_tuning_copy_leaves_the_cached_tuning_alone() -> void:
	var cached: LoopTuning = load(OverlayTestSupport.TUNING)
	var dawn_before: float = cached.dawn_seconds

	var copy: LoopTuning = OverlayTestSupport.new_tuning()
	copy.dawn_seconds = dawn_before + 100.0

	assert_ne(copy, cached, "the tuning is a copy")
	assert_eq(cached.dawn_seconds, dawn_before, "the cached tuning is unchanged")


func test_a_new_tuning_copy_shares_no_resource_with_the_cached_tuning() -> void:
	# LoopTuning has no subresource today, so this passes trivially now. It fails the day one is
	# added and new_tuning() copies it shallowly, which is what new_tuning's "copied all the way
	# down" promise (DEEP_DUPLICATE_ALL) is there to prevent.
	var cached: LoopTuning = load(OverlayTestSupport.TUNING)
	var copy: LoopTuning = OverlayTestSupport.new_tuning()
	var checked: int = 0
	for property: Dictionary in cached.get_script().get_script_property_list():
		if (property["usage"] as int) & PROPERTY_USAGE_STORAGE == 0:
			continue
		checked += 1
		var name: String = property["name"]
		var copied: Array[Resource] = _resources_in(copy.get(name))
		for resource: Resource in _resources_in(cached.get(name)):
			assert_false(copied.has(resource), "'%s' shares a subresource with the cache" % name)
	assert_gt(checked, 0, "the tuning has stored properties, so the loop above checked something")


## Every Resource held directly by `value` or, for an Array or Dictionary, by its entries.
func _resources_in(value: Variant) -> Array[Resource]:
	var found: Array[Resource] = []
	if value is Resource:
		found.append(value)
	elif value is Array:
		for item: Variant in value:
			found.append_array(_resources_in(item))
	elif value is Dictionary:
		for item: Variant in (value as Dictionary).values():
			found.append_array(_resources_in(item))
	return found
