extends GutTest
## BLDG-07: buildings have health from data, take hits, and fall at zero exactly once. Every number
## is read from house.tres and tower.tres, so retuning cannot break these tests.

const TUNING := "res://data/tuning/loop_tuning.tres"
const HOUSE_PATH := "res://data/buildings/house.tres"
const TOWER_PATH := "res://data/buildings/tower.tres"
const GRUNT_PATH := "res://data/enemies/grunt.tres"
const HOUSE_A: StringName = &"house_1"
const HOUSE_B: StringName = &"house_2"
const TOWER_A: StringName = &"tower_1"
## Where the king stands when he must be nowhere near the fight.
const KING_FAR := Vector2(500.0, 500.0)

var _house: BuildingDef
var _tower: BuildingDef
var _tuning: LoopTuning
var _events: SimEvents
var _buildings: BuildingSystem


func before_each() -> void:
	_house = load(HOUSE_PATH)
	_tower = load(TOWER_PATH)
	_tuning = load(TUNING)
	var map: MapConfig = E2eSupport.waveless_prototype_map()
	_events = SimEvents.new()
	_buildings = BuildingSystem.new(map, _events)


func _hp(def: BuildingDef, tier: int) -> int:
	return def.tier_def(tier).max_health


func _stand(spot_id: StringName, times: int = 1) -> void:
	for _step: int in range(times):
		_buildings.apply_next_tier(spot_id)


func _params(signal_name: String, index: int) -> Array:
	var params: Variant = get_signal_parameters(_events, signal_name, index)
	return params as Array if params != null else []


func test_a_new_building_stands_at_its_tier_one_health() -> void:
	_stand(HOUSE_A)
	_stand(TOWER_A)
	assert_eq(_buildings.health_of(HOUSE_A), _hp(_house, 1), "House tier I")
	assert_eq(_buildings.max_health_of(HOUSE_A), _hp(_house, 1), "House max health")
	assert_eq(_buildings.health_of(TOWER_A), _hp(_tower, 1), "Tower tier I")
	assert_false(_buildings.is_destroyed(HOUSE_A), "it stands")


func test_an_upgrade_stands_at_the_new_tiers_full_health() -> void:
	_stand(HOUSE_A)
	_buildings.damage_building(HOUSE_A, 3)
	_stand(HOUSE_A)
	assert_eq(_buildings.health_of(HOUSE_A), _hp(_house, 2), "hurt tier I becomes whole tier II")
	_stand(HOUSE_A)
	assert_eq(_buildings.health_of(HOUSE_A), _hp(_house, 3), "and whole tier III")
	assert_eq(_buildings.max_health_of(HOUSE_A), _hp(_house, 3), "max follows the tier")


func test_a_hit_reports_the_amount_and_what_is_left() -> void:
	_stand(HOUSE_A)
	var max_hp: int = _hp(_house, 1)
	watch_signals(_events)
	_buildings.damage_building(HOUSE_A, 3)
	assert_signal_emit_count(_events, "building_damaged", 1)
	assert_eq(_params("building_damaged", 0), [HOUSE_A, 3, max_hp - 3, max_hp])
	assert_eq(_buildings.health_of(HOUSE_A), max_hp - 3, "the system agrees")
	assert_signal_not_emitted(_events, "building_destroyed")


func test_overkill_clamps_at_zero_and_destroys_exactly_once() -> void:
	_stand(HOUSE_A)
	var max_hp: int = _hp(_house, 1)
	_buildings.damage_building(HOUSE_A, 3)
	watch_signals(_events)
	_buildings.damage_building(HOUSE_A, max_hp * 4)
	assert_eq(_buildings.health_of(HOUSE_A), 0, "hp stops at 0, never negative")
	assert_true(_buildings.is_destroyed(HOUSE_A), "destroyed")
	assert_signal_emit_count(_events, "building_damaged", 1)
	assert_eq(
		_params("building_damaged", 0), [HOUSE_A, max_hp - 3, 0, max_hp], "points actually lost"
	)
	assert_signal_emit_count(_events, "building_destroyed", 1)
	assert_eq(_params("building_destroyed", 0), [HOUSE_A, &"house", 1], "which building and tier")
	_buildings.damage_building(HOUSE_A, 5)
	assert_signal_emit_count(_events, "building_damaged", 1, "a hit on rubble changes nothing")
	assert_signal_emit_count(_events, "building_destroyed", 1, "and destroys nothing twice")
	assert_eq(_buildings.health_of(HOUSE_A), 0, "still 0")


func test_one_hit_point_stands_and_exactly_zero_destroys() -> void:
	_stand(HOUSE_A)
	var max_hp: int = _hp(_house, 1)
	_buildings.damage_building(HOUSE_A, max_hp - 1)
	assert_eq(_buildings.health_of(HOUSE_A), 1, "1 hp")
	assert_false(_buildings.is_destroyed(HOUSE_A), "1 hp still stands")
	assert_true(_buildings.standing_spot_ids().has(HOUSE_A), "and still counts as standing")
	_buildings.damage_building(HOUSE_A, 1)
	assert_true(_buildings.is_destroyed(HOUSE_A), "a hit to exactly 0 destroys it")


func test_the_destroyed_event_names_the_tier_it_fell_at() -> void:
	_stand(TOWER_A, 2)
	watch_signals(_events)
	_buildings.damage_building(TOWER_A, _hp(_tower, 2))
	assert_eq(_params("building_destroyed", 0), [TOWER_A, &"tower", 2])


func test_hits_that_name_nothing_are_dropped() -> void:
	_stand(HOUSE_A)
	watch_signals(_events)
	_buildings.damage_building(&"nowhere", 5)
	_buildings.damage_building(&"", 5)
	_buildings.damage_building(HOUSE_B, 5)
	_buildings.damage_building(HOUSE_A, 0)
	_buildings.damage_building(HOUSE_A, -4)
	assert_signal_not_emitted(
		_events, "building_damaged", "unknown, empty, unbuilt and bad amounts"
	)
	assert_eq(_buildings.health_of(HOUSE_A), _hp(_house, 1), "nothing changed")


func test_unbuilt_and_unknown_spots_report_zero() -> void:
	assert_eq(_buildings.health_of(HOUSE_B), 0, "unbuilt health")
	assert_eq(_buildings.max_health_of(HOUSE_B), 0, "unbuilt max health")
	assert_false(_buildings.is_destroyed(HOUSE_B), "an empty plot is not destroyed")
	assert_eq(_buildings.health_of(&"nowhere"), 0, "unknown health")
	assert_eq(_buildings.radius_of(&"nowhere"), 0.0, "unknown radius")
	assert_eq(_buildings.radius_of(HOUSE_A), _house.body_radius, "a plot knows its building radius")
	assert_eq(_buildings.radius_of(TOWER_A), _tower.body_radius, "a tower plot too")


func test_spot_index_round_trips_in_map_order() -> void:
	var ids: Array[StringName] = _buildings.spot_ids()
	for index: int in range(ids.size()):
		assert_eq(_buildings.spot_index(ids[index]), index, "index of %s" % ids[index])
		assert_eq(_buildings.spot_at_index(index), ids[index], "spot at %d" % index)
	assert_eq(_buildings.spot_index(&"nowhere"), -1, "unknown id")
	assert_eq(_buildings.spot_at_index(-1), &"", "below range")
	assert_eq(_buildings.spot_at_index(ids.size()), &"", "above range")


func test_standing_spots_are_built_and_not_destroyed_in_map_order() -> void:
	_stand(TOWER_A)
	_stand(HOUSE_B)
	_stand(HOUSE_A)
	assert_eq(_buildings.standing_spot_ids(), [HOUSE_A, HOUSE_B, TOWER_A] as Array[StringName])
	_buildings.damage_building(HOUSE_B, _hp(_house, 1))
	assert_eq(_buildings.standing_spot_ids(), [HOUSE_A, TOWER_A] as Array[StringName])


func test_a_destroyed_building_pays_no_dawn_income_and_its_snapshot_says_so() -> void:
	_stand(HOUSE_A)
	_stand(HOUSE_B)
	var income: int = _house.tier_def(1).dawn_income
	assert_eq(_buildings.dawn_income_by_spot(), {HOUSE_A: income, HOUSE_B: income})
	_buildings.damage_building(HOUSE_A, _hp(_house, 1))
	assert_eq(_buildings.dawn_income_by_spot(), {HOUSE_B: income}, "the fallen House pays nothing")
	var snapshot: BuildingInstance = _buildings.get_instance(HOUSE_A)
	assert_true(snapshot.destroyed, "the snapshot reports destroyed")
	assert_eq(snapshot.health, 0, "and 0 health")
	snapshot.health = 99
	assert_eq(_buildings.health_of(HOUSE_A), 0, "a snapshot cannot heal the building")


func test_a_dawn_after_a_loss_pays_only_the_survivors() -> void:
	var map: MapConfig = E2eSupport.waveless_prototype_map()
	map.starting_gold = 0
	var ctx: RunContext = RunContext.new(map, _tuning)
	ctx.buildings.apply_next_tier(HOUSE_A)
	ctx.buildings.apply_next_tier(HOUSE_B)
	watch_signals(ctx.events)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	ctx.buildings.damage_building(HOUSE_A, _hp(_house, 1))
	ctx.run_manager.tick(_tuning.placeholder_night_seconds + 0.1)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "dawn reached")
	var payout: Array = get_signal_parameters(ctx.events, "dawn_payout", 0) as Array
	var income: int = _house.tier_def(1).dawn_income
	var base: int = map.base_dawn_income
	assert_eq(payout[0], income + base, "one House paid, and the castle its base income")
	assert_eq(
		payout[1],
		{HOUSE_B: income, MapConfig.CASTLE_PAYOUT_KEY: base},
		"the survivor and the castle"
	)
	assert_false(payout[1].has(HOUSE_A), "the fallen House is not listed")
	assert_eq(ctx.economy.get_gold(), income + base, "gold rose by those two only")


## Several grunts striking one House on one tick. Returns the context after that tick.
func _swarm_a_house(grunt_count: int) -> RunContext:
	var map: MapConfig = E2eSupport.waveless_prototype_map()
	var ctx: RunContext = RunContext.new(map, _tuning)
	ctx.buildings.apply_next_tier(HOUSE_A)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	ctx.king.report_position(KING_FAR)
	var grunt: EnemyDef = load(GRUNT_PATH)
	var centre: Vector3 = ctx.buildings.get_spot(HOUSE_A).position
	var stop: float = _house.body_radius + grunt.attack_range
	for index: int in range(grunt_count):
		var angle: float = TAU * float(index) / float(grunt_count)
		var offset: Vector2 = Vector2(cos(angle), sin(angle)) * stop
		ctx.night.get_enemies().spawn(grunt, Vector2(centre.x, centre.z) + offset)
	return ctx


func test_two_strikes_on_one_tick_destroy_the_house_once() -> void:
	var grunt: EnemyDef = load(GRUNT_PATH)
	var count: int = _hp(_house, 1) / grunt.attack_damage + 2
	var ctx: RunContext = _swarm_a_house(count)
	watch_signals(ctx.events)
	ctx.step()
	assert_true(ctx.buildings.is_destroyed(HOUSE_A), "overwhelmed on the first tick")
	assert_signal_emit_count(ctx.events, "attack_fired", count, "every grunt struck")
	assert_signal_emit_count(ctx.events, "building_destroyed", 1, "destroyed exactly once")
	var lost: int = 0
	for index: int in range(get_signal_emit_count(ctx.events, "building_damaged")):
		lost += (get_signal_parameters(ctx.events, "building_damaged", index) as Array)[1] as int
	assert_eq(lost, _hp(_house, 1), "the damage events add up to the health lost, no more")
	for _tick: int in range(60):
		ctx.step()
	assert_signal_emit_count(ctx.events, "building_destroyed", 1, "still once afterwards")


func test_enemies_stop_attacking_a_building_once_it_has_fallen() -> void:
	var ctx: RunContext = _swarm_a_house(3)
	ctx.buildings.damage_building(HOUSE_A, _hp(_house, 1))
	watch_signals(ctx.events)
	for _tick: int in range(90):
		ctx.step()
	for index: int in range(get_signal_emit_count(ctx.events, "attack_fired")):
		var params: Array = get_signal_parameters(ctx.events, "attack_fired", index) as Array
		assert_ne(params[2], PendingHits.KIND_BUILDING, "no strike on the fallen House")


func test_max_health_must_be_above_zero_in_data() -> void:
	var map: MapConfig = E2eSupport.waveless_prototype_map()
	assert_eq(map.validate().size(), 0, "the shipped prototype validates clean")
	map.buildings[0].tiers[1].max_health = 0
	var errors: PackedStringArray = map.validate()
	assert_eq(errors.size(), 1, "exactly the one bad tier is reported")
	if errors.size() == 1:
		assert_string_contains(errors[0], "max_health", "and it names the field")
	map.buildings[0].tiers[1].max_health = -3
	assert_eq(map.validate().size(), 1, "a negative value is reported too")


func test_every_shipped_tier_has_health_and_the_tower_tiers_have_their_shot_data() -> void:
	for def: BuildingDef in [_house, _tower]:
		for tier: int in range(1, def.max_tier() + 1):
			assert_gt(def.tier_def(tier).max_health, 0, "%s tier %d" % [def.id, tier])
		assert_gt(def.body_radius, 0.0, "%s has a footprint" % def.id)
	for tier: int in range(1, _tower.max_tier() + 1):
		assert_gt(_tower.tier_def(tier).attack_interval, 0.0, "tower tier %d interval" % tier)
		assert_gt(_tower.tier_def(tier).projectile_speed, 0.0, "tower tier %d arrow speed" % tier)
