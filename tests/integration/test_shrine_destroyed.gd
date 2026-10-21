extends GutTest
## D-14: a destroyed Shrine loses nothing it earned and only skips that dawn. Credit keeps coming
## for deaths in its radius while it lies in rubble, its awake state never clears, it does not shoot
## while it is down, it is rebuilt free at dawn, pays nothing that morning, and shoots again at the
## next night. A dormant Shrine that fell and was rebuilt keeps its partial credit, wakes when the
## credit later reaches the threshold and, like every rebuilt building that pays, wears the crossed
## coin (the marker asks BuildingDef.pays_income, with no awake check). Part one plays whole nights
## on tests/fixtures/fixture_map_shrine.tres in a RunContext; part two hand-builds the systems.

const FIXTURE := "res://tests/fixtures/fixture_map_shrine.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const SHRINE: StringName = &"shrine_1"
const TOWER: StringName = &"tower_1"
const SECOND_TOWER: StringName = &"tower_2"
const GRUNT: StringName = &"grunt"
const MAX_NIGHT_TICKS: int = 4000
const LATER_DEATHS: int = 3

var _ctx: RunContext
var _shrine_fires: Array[int] = []


func before_each() -> void:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	_ctx = RunContext.new(map, load(TUNING), 1)
	for spot_id: StringName in [TOWER, SECOND_TOWER, SHRINE]:
		assert_eq(_ctx.commands.submit(BuildIntent.new(spot_id)), CommandProcessor.OK, "built")
	_shrine_fires = []
	var shrine_index: int = _ctx.buildings.spot_index(SHRINE)
	_ctx.events.attack_fired.connect(
		func(kind: StringName, id: int, _tk: StringName, _tid: int, _flight: int) -> void:
			if kind == PendingHits.KIND_BUILDING and id == shrine_index:
				_shrine_fires.append(_ctx.tick_count)
	)


func _plot() -> Vector2:
	var at: Vector3 = _ctx.buildings.get_spot(SHRINE).position
	return Vector2(at.x, at.z)


func _hp() -> int:
	return _ctx.map.find_enemy(GRUNT).max_health


func _threshold() -> int:
	return _ctx.buildings.get_building_def_for_spot(SHRINE).tier_def(1).wake_threshold_hp


## Wakes the Shrine by day the way the game does: deaths beside it.
func _wake() -> void:
	var deaths: int = ceili(float(_threshold()) / float(_hp()))
	for death: int in range(deaths):
		_ctx.events.enemy_died.emit(death, GRUNT, _plot(), &"tower")
	assert_true(_ctx.income.is_awake(SHRINE), "the Shrine is awake")


func _start_night() -> void:
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night starts")


func _step_to(phase: RunManager.RunPhase) -> void:
	var steps: int = 0
	while _ctx.run_manager.get_phase() != phase and steps < MAX_NIGHT_TICKS:
		_ctx.step()
		steps += 1
	assert_eq(_ctx.run_manager.get_phase(), phase, "reached the phase in time")


func _fall() -> void:
	_ctx.buildings.damage_building(SHRINE, _ctx.buildings.max_health_of(SHRINE))
	assert_true(_ctx.buildings.is_destroyed(SHRINE), "the Shrine fell")


func test_an_awake_shrine_that_fell_fires_nothing_while_it_is_down() -> void:
	_wake()
	_start_night()
	_fall()
	for step: int in range(MAX_NIGHT_TICKS):
		if _ctx.run_manager.get_phase() != RunManager.RunPhase.NIGHT:
			break
		_ctx.step()
	assert_eq(_shrine_fires.size(), 0, "a fallen Shrine never shot")
	assert_true(_ctx.income.is_awake(SHRINE), "yet it is still awake")


func test_a_fallen_shrine_keeps_its_credit_and_keeps_being_credited() -> void:
	_wake()
	var before: int = _ctx.income.kill_credit(SHRINE)
	_start_night()
	_fall()
	assert_eq(_ctx.income.kill_credit(SHRINE), before, "falling cost it nothing")
	for death: int in range(LATER_DEATHS):
		_ctx.events.enemy_died.emit(death, GRUNT, _plot(), &"tower")
	assert_eq(
		_ctx.income.kill_credit(SHRINE), before + LATER_DEATHS * _hp(), "and deaths still count"
	)
	assert_true(_ctx.income.is_awake(SHRINE), "awake never clears")


func test_the_dawn_rebuilds_it_free_and_it_pays_nothing_that_morning() -> void:
	_wake()
	_start_night()
	_fall()
	var paid: Dictionary = {}
	var rebuilt: Array = []
	_ctx.events.dawn_payout.connect(
		func(_total: int, per_spot: Dictionary) -> void: paid.merge(per_spot)
	)
	_ctx.events.buildings_rebuilt.connect(
		func(spot_ids: Array) -> void: rebuilt.append_array(spot_ids)
	)
	var gold_at_night: int = _ctx.economy.get_gold()
	_step_to(RunManager.RunPhase.DAWN)
	assert_true(rebuilt.has(SHRINE), "the Shrine was rebuilt at dawn")
	assert_false(_ctx.buildings.is_destroyed(SHRINE), "and stands")
	assert_true(_ctx.buildings.get_instance(SHRINE).rebuilt_this_dawn, "marked as rebuilt")
	assert_false(paid.has(SHRINE), "it paid nothing that morning")
	var total: int = 0
	for amount: int in paid.values():
		total += amount
	assert_eq(_ctx.economy.get_gold(), gold_at_night + total, "and the rebuild cost no gold")
	assert_true(_ctx.income.is_awake(SHRINE), "still awake")


func test_the_rebuilt_awake_shrine_wears_the_crossed_coin() -> void:
	_wake()
	var def: BuildingDef = _ctx.buildings.get_building_def_for_spot(SHRINE)
	assert_true(
		def.pays_income(_ctx.buildings.current_tier(SHRINE)), "awake: the marker rule says yes"
	)


func test_it_shoots_again_at_the_next_night() -> void:
	_wake()
	_start_night()
	_fall()
	_step_to(RunManager.RunPhase.DAWN)
	_step_to(RunManager.RunPhase.DAY)
	assert_eq(_shrine_fires.size(), 0, "nothing while it was down")
	_start_night()
	var steps: int = 0
	while _shrine_fires.is_empty() and steps < MAX_NIGHT_TICKS:
		if _ctx.run_manager.get_phase() != RunManager.RunPhase.NIGHT:
			break
		_ctx.step()
		steps += 1
	assert_gt(_shrine_fires.size(), 0, "the rebuilt, awake Shrine fires in night 2")


# ---- Part two: a dormant Shrine that fell, hand-built systems ---------------------------------


func _hand_systems() -> Array:
	var map: MapConfig = E2eSupport.waveless_prototype_map()
	var events: SimEvents = SimEvents.new()
	var buildings: BuildingSystem = BuildingSystem.new(map, events)
	var income: IncomeState = IncomeState.new(map, buildings, events)
	return [map, events, buildings, income]


func test_a_dormant_shrine_that_fell_and_was_rebuilt_keeps_its_partial_credit() -> void:
	var systems: Array = _hand_systems()
	var events: SimEvents = systems[1]
	var buildings: BuildingSystem = systems[2]
	var income: IncomeState = systems[3]
	var west: StringName = &"shrine_west"
	var plot: Vector3 = buildings.get_spot(west).position
	buildings.apply_next_tier(west)
	events.enemy_died.emit(1, GRUNT, Vector2(plot.x, plot.z), &"tower")
	var partial: int = income.kill_credit(west)
	assert_gt(partial, 0, "some credit, short of the threshold")
	assert_false(income.is_awake(west), "asleep")
	buildings.damage_building(west, buildings.max_health_of(west))
	buildings.rebuild_destroyed()
	assert_eq(income.kill_credit(west), partial, "the credit survived the fall")
	assert_false(income.is_awake(west), "and it is still asleep")
	assert_false(income.dawn_payouts().has(west), "a dormant Shrine pays nothing anyway")


func test_a_rebuilt_dormant_shrine_wears_the_crossed_coin_like_an_awake_one() -> void:
	var systems: Array = _hand_systems()
	var buildings: BuildingSystem = systems[2]
	var west: StringName = &"shrine_west"
	buildings.apply_next_tier(west)
	var def: BuildingDef = buildings.get_building_def_for_spot(west)
	assert_true(def.pays_income(buildings.current_tier(west)), "dormant: the marker rule says yes")


func test_a_dormant_shrine_wakes_when_the_credit_later_reaches_the_threshold() -> void:
	var systems: Array = _hand_systems()
	var map: MapConfig = systems[0]
	var events: SimEvents = systems[1]
	var buildings: BuildingSystem = systems[2]
	var income: IncomeState = systems[3]
	var west: StringName = &"shrine_west"
	var plot: Vector3 = buildings.get_spot(west).position
	var at: Vector2 = Vector2(plot.x, plot.z)
	buildings.apply_next_tier(west)
	buildings.damage_building(west, buildings.max_health_of(west))
	buildings.rebuild_destroyed()
	var threshold: int = buildings.get_building_def_for_spot(west).tier_def(1).wake_threshold_hp
	var deaths: int = ceili(float(threshold) / float(map.find_enemy(GRUNT).max_health))
	for death: int in range(deaths - 1):
		events.enemy_died.emit(death, GRUNT, at, &"tower")
	assert_false(income.is_awake(west), "one death short")
	events.enemy_died.emit(deaths, GRUNT, at, &"tower")
	assert_true(income.is_awake(west), "the last death wakes it")
