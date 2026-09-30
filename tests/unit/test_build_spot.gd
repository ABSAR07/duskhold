extends GutTest
## BLDG-01: buildings exist only on fixed map spots, one type per spot, with deterministic
## nearest-spot resolution (adjacency tie, exact-radius boundary, empty map, unknown id).

const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const FIXTURE_TIE := "res://tests/fixtures/fixture_map_tie.tres"
const FIXTURE_EMPTY := "res://tests/fixtures/fixture_map_empty.tres"
const TIE_REPEATS: int = 10
const JUST_OUTSIDE: float = 0.01


func _context_for(map: MapConfig) -> RunContext:
	return RunContext.new(map, load(TUNING))


func _rich_prototype() -> RunContext:
	var map: MapConfig = (load(PROTOTYPE_MAP) as MapConfig).duplicate(true)
	map.starting_gold = 1000
	return _context_for(map)


func test_each_spot_builds_only_its_own_building_type() -> void:
	var ctx: RunContext = _rich_prototype()
	for spot_id: StringName in ctx.buildings.spot_ids():
		var result: StringName = ctx.commands.submit(BuildIntent.new(spot_id))
		assert_eq(result, CommandProcessor.OK, "%s accepts a build" % spot_id)
		var instance: BuildingInstance = ctx.buildings.get_instance(spot_id)
		assert_not_null(instance, "%s now holds a building" % spot_id)
		if instance != null:
			var expected: StringName = ctx.buildings.get_spot(spot_id).building_id
			assert_eq(instance.building_id, expected, "%s holds its own type" % spot_id)


func test_a_reader_changing_the_instance_it_was_given_does_not_change_the_building() -> void:
	var ctx: RunContext = _rich_prototype()
	var spot_id: StringName = ctx.buildings.spot_ids()[0]
	var built: BuildingInstance = ctx.buildings.get_instance(spot_id)
	assert_null(built, "the spot starts empty")
	var returned: BuildingInstance = ctx.buildings.apply_next_tier(spot_id)
	assert_eq(ctx.buildings.current_tier(spot_id), 1, "tier I stands")

	returned.tier = 99
	var read: BuildingInstance = ctx.buildings.get_instance(spot_id)
	read.tier = 42
	read.building_id = &"tampered"

	assert_eq(ctx.buildings.current_tier(spot_id), 1, "the standing tier is untouched")
	var again: BuildingInstance = ctx.buildings.get_instance(spot_id)
	assert_eq(again.tier, 1, "a later read still sees tier I")
	assert_eq(again.building_id, ctx.buildings.get_spot(spot_id).building_id, "and its own type")


func test_unknown_and_empty_spot_ids_are_rejected_and_change_nothing() -> void:
	var ctx: RunContext = _rich_prototype()
	var start_gold: int = ctx.economy.get_gold()
	for bad_id: StringName in [&"no_such_spot", &"", &"House_1"]:
		assert_eq(ctx.commands.validate_build(bad_id), CommandProcessor.UNKNOWN_SPOT, "check")
		assert_eq(ctx.commands.submit(BuildIntent.new(bad_id)), CommandProcessor.UNKNOWN_SPOT)
	assert_eq(ctx.economy.get_gold(), start_gold, "gold unchanged")
	for spot_id: StringName in ctx.buildings.spot_ids():
		assert_null(ctx.buildings.get_instance(spot_id), "no building appeared on %s" % spot_id)


func test_spot_ids_always_come_back_in_map_order() -> void:
	var map: MapConfig = load(PROTOTYPE_MAP)
	var ctx: RunContext = _context_for(map)
	for _pass: int in range(3):
		var ids: Array[StringName] = ctx.buildings.spot_ids()
		assert_eq(ids.size(), map.spots.size(), "every spot is listed")
		for index: int in range(mini(ids.size(), map.spots.size())):
			assert_eq(ids[index], map.spots[index].id, "index %d keeps MapConfig order" % index)


func test_changing_the_returned_spot_ids_does_not_change_the_system() -> void:
	var ctx: RunContext = _context_for(load(PROTOTYPE_MAP))
	var before: Array[StringName] = ctx.buildings.spot_ids()
	var scribbled: Array[StringName] = ctx.buildings.spot_ids()

	scribbled.clear()

	assert_eq(ctx.buildings.spot_ids(), before, "the system's spot order is untouched")


func test_the_nearer_of_two_in_range_spots_wins() -> void:
	var ctx: RunContext = _context_for(load(FIXTURE_TIE))
	var near_a: Vector3 = Vector3(1.5, 0.0, 0.0)
	var near_b: Vector3 = Vector3(-1.5, 0.0, 0.0)
	assert_eq(ctx.buildings.nearest_spot_in_range(near_a, 5.0), &"a", "closer to a")
	assert_eq(ctx.buildings.nearest_spot_in_range(near_b, 5.0), &"b", "closer to b")


func test_an_exact_distance_tie_goes_to_the_earlier_spot_every_time() -> void:
	var ctx: RunContext = _context_for(load(FIXTURE_TIE))
	for _repeat: int in range(TIE_REPEATS):
		var found: StringName = ctx.buildings.nearest_spot_in_range(Vector3.ZERO, 5.0)
		assert_eq(found, &"a", "tie resolves to the spot earlier in MapConfig.spots")


func test_a_king_exactly_at_the_radius_is_in_range_and_just_beyond_is_not() -> void:
	var ctx: RunContext = _context_for(load(FIXTURE_TIE))
	var spot: BuildSpotDef = ctx.buildings.get_spot(&"a")
	var radius: float = 2.0
	var on_edge: Vector3 = spot.position + Vector3(radius, 0.0, 0.0)
	var beyond: Vector3 = spot.position + Vector3(radius + JUST_OUTSIDE, 0.0, 0.0)
	assert_eq(ctx.buildings.nearest_spot_in_range(on_edge, radius), &"a", "exactly at the radius")
	assert_eq(ctx.buildings.nearest_spot_in_range(beyond, radius), &"", "just outside the radius")


func test_a_map_with_no_spots_yields_no_focus() -> void:
	var ctx: RunContext = _context_for(load(FIXTURE_EMPTY))
	assert_eq(ctx.buildings.spot_ids().size(), 0, "the fixture really has no spots")
	assert_eq(ctx.buildings.nearest_spot_in_range(Vector3.ZERO, 100.0), &"", "empty StringName")
	assert_eq(ctx.commands.submit(BuildIntent.new(&"")), CommandProcessor.UNKNOWN_SPOT, "rejected")
