extends GutTest
## OverlayTestSupport promises private copies of the cached map and tuning. A copy that still shared
## a building definition or tier with the cached resource would let one suite's edit change the next
## suite's data, so the result of a run would depend on script order.

## The spot position the editing test writes to its copy. The cached spot is compared with this, not
## with the copy's property: were the two the same object, restoring the cache would also reset the
## copy, and the comparison would then pass exactly when it should fail.
const EDITED_SPOT := Vector3(123.0, 0.0, 456.0)


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
	var cached_tier: BuildingTierDef = cached.buildings[0].tiers[0]
	var cost_before: int = cached_tier.cost
	var income_before: int = cached_tier.dawn_income
	var spot_before: Vector3 = cached.spots[0].position

	var copy: MapConfig = OverlayTestSupport.new_map()
	copy.buildings[0].tiers[0].cost = cost_before + 100
	copy.buildings[0].tiers[0].dawn_income = income_before + 100
	copy.spots[0].position = EDITED_SPOT
	var cost_seen: int = cached_tier.cost
	var income_seen: int = cached_tier.dawn_income
	var spot_seen: Vector3 = cached.spots[0].position
	var later: MapConfig = OverlayTestSupport.new_map()
	var later_cost: int = later.buildings[0].tiers[0].cost

	# Put the cached values back before asserting. If the copy shared a resource with the cache, the
	# writes above landed on it; restoring here keeps that failure in this test instead of leaving
	# a dirtied cache for every suite that runs after it.
	cached_tier.cost = cost_before
	cached_tier.dawn_income = income_before
	cached.spots[0].position = spot_before

	assert_eq(cost_seen, cost_before, "the cached cost is unchanged")
	assert_eq(income_seen, income_before, "and its dawn income")
	assert_ne(spot_seen, EDITED_SPOT, "and its spot position is not the one written to the copy")
	assert_eq(later_cost, cost_before, "a later copy starts clean")


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
	# LoopTuning has no subresource today, so nothing can be shared and this passes without checking
	# anything yet. It fails the day one is added and new_tuning() copies it shallowly, which is what
	# new_tuning's "copied all the way down" promise (DEEP_DUPLICATE_ALL) is there to prevent. That
	# the check would notice is shown by the test below, on stand-in resources.
	var cached: LoopTuning = load(OverlayTestSupport.TUNING)
	var copy: LoopTuning = OverlayTestSupport.new_tuning()

	assert_eq(
		_shared_resources(cached, copy),
		[] as Array[Resource],
		"no subresource is shared with the cache (LoopTuning has none yet, so this guards a later one)"
	)


func test_the_sharing_check_finds_a_nested_resource_under_a_base_script_property() -> void:
	# The subresource sits two levels down, behind a property declared on a base script, so a check
	# that looked only at the top level's own properties would miss it.
	var inner: Resource = Resource.new()
	var first: _Holder = _holder_around(_holder_around(inner))
	var second: _Holder = _holder_around(_holder_around(inner))
	var unrelated: _Holder = _holder_around(_holder_around(Resource.new()))

	assert_eq(
		_shared_resources(first, second), [inner] as Array[Resource], "the shared one is found"
	)
	assert_eq(
		_shared_resources(first, unrelated),
		[] as Array[Resource],
		"and a private copy is not flagged"
	)


func _holder_around(child: Resource) -> _Holder:
	var holder: _Holder = _Holder.new()
	holder.child = child
	return holder


## The Resources both `first` and `second` reach through their stored properties (see _reachable).
func _shared_resources(first: Resource, second: Resource) -> Array[Resource]:
	var in_second: Array[Resource] = _reachable(second, [])
	var shared: Array[Resource] = []
	for resource: Resource in _reachable(first, []):
		if in_second.has(resource):
			shared.append(resource)
	return shared


## Every Resource below `root`, at any depth, through every stored property, base scripts included.
## `script` is skipped: it is the script resource every instance of a class shares, not data.
func _reachable(root: Resource, found: Array[Resource]) -> Array[Resource]:
	for property: Dictionary in root.get_property_list():
		var prop_name: String = property["name"]
		if (property["usage"] as int) & PROPERTY_USAGE_STORAGE == 0 or prop_name == "script":
			continue
		for resource: Resource in _resources_in(root.get(prop_name)):
			if not found.has(resource):
				found.append(resource)
				_reachable(resource, found)
	return found


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


## Stand-ins for a Resource with a subresource: one property on a base script, one on its subclass.
class _HolderBase:
	extends Resource
	@export_storage var child: Resource


class _Holder:
	extends _HolderBase
	@export_storage var label: String = ""
