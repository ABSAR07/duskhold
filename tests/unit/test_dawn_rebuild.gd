extends GutTest
## LOOP-04 and LOOP-05: at dawn every building that fell in the night is rebuilt for free at the
## tier it had, the survivors and the castle are repaired and the king is whole again, and only the
## buildings that stood through the night pay income, while the castle's base income (G-02-1) is
## paid on every waveless-map dawn regardless. Every amount is read from house.tres, tower.tres and
## the maps, so retuning cannot break these tests.

const FIXTURE := "res://tests/fixtures/fixture_map_one_night.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const HOUSE_PATH := "res://data/buildings/house.tres"
const RICH_GOLD: int = 500
const HOUSE_A: StringName = &"house_1"
const HOUSE_B: StringName = &"house_2"
const HOUSE_C: StringName = &"house_3"
const TOWER: StringName = &"tower_1"
## The king's hold point in front of the west route of the fixture (see test_night_loop.gd).
const KING_AT := Vector2(-4.5, 0.0)
const KING_FAR := Vector2(500.0, 500.0)
const MAX_NIGHT_STEPS: int = 900
const ROOMY_STEPS: int = 2500
const IDLE_NIGHT_STEPS: int = 120

var _tuning: LoopTuning
var _house: BuildingDef
var _rebuilt_lists: Array = []
var _payouts: Array = []
var _gold_deltas: Array[int] = []
var _sequence: Array[String] = []
var _deaths: int = 0
var _fell_at_tick: int = -1


func before_each() -> void:
	_tuning = load(TUNING)
	_house = load(HOUSE_PATH)
	_rebuilt_lists = []
	_payouts = []
	_gold_deltas = []
	_sequence = []
	_deaths = 0
	_fell_at_tick = -1


func _waveless_context() -> RunContext:
	var map: MapConfig = E2eSupport.waveless_prototype_map()
	map.starting_gold = RICH_GOLD
	return _watched(RunContext.new(map, _tuning))


func _fixture_context() -> RunContext:
	var shipped: MapConfig = load(FIXTURE)
	var map: MapConfig = shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	map.starting_gold = RICH_GOLD
	var ctx: RunContext = _watched(RunContext.new(map, _tuning, 1))
	ctx.king.report_position(KING_AT)
	return ctx


## Records what the dawn emits, in order, without altering the run.
func _watched(ctx: RunContext) -> RunContext:
	ctx.events.buildings_rebuilt.connect(
		func(spot_ids: Array) -> void:
			_rebuilt_lists.append(spot_ids.duplicate())
			_sequence.append("rebuilt")
	)
	ctx.events.dawn_payout.connect(
		func(total: int, per_spot: Dictionary) -> void:
			_payouts.append([total, per_spot.duplicate()])
			_sequence.append("payout")
	)
	ctx.events.gold_changed.connect(
		func(_amount: int, delta: int) -> void: _gold_deltas.append(delta)
	)
	ctx.events.phase_changed.connect(
		func(_old: int, new_phase: int) -> void:
			if new_phase == RunManager.RunPhase.DAWN:
				_sequence.append("dawn")
	)
	return ctx


func _build(ctx: RunContext, spot_id: StringName, times: int = 1) -> void:
	for step: int in range(times):
		assert_eq(
			ctx.commands.submit(BuildIntent.new(spot_id)),
			CommandProcessor.OK,
			"%s build step %d" % [spot_id, step + 1]
		)


func _income(tier: int) -> int:
	return _house.tier_def(tier).dawn_income


## The base income the shipped map pays each dawn; the one-night fixture leaves it off.
func _base() -> int:
	return E2eSupport.waveless_prototype_map().base_dawn_income


func _max_hp(tier: int) -> int:
	return _house.tier_def(tier).max_health


func _start_night(ctx: RunContext) -> void:
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "the night starts")


## Takes the building down with the same call a night's hits make.
func _fall(ctx: RunContext, spot_id: StringName) -> void:
	ctx.buildings.damage_building(spot_id, ctx.buildings.max_health_of(spot_id))
	assert_true(ctx.buildings.is_destroyed(spot_id), "%s fell" % spot_id)


## Runs the Phase 1 timed night out on a waveless map.
func _into_dawn(ctx: RunContext) -> void:
	ctx.run_manager.tick(_tuning.placeholder_night_seconds + 0.1)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "dawn reached")


func _into_day(ctx: RunContext) -> void:
	ctx.run_manager.tick(_tuning.dawn_seconds)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAY, "the day returned")


## Steps a fixture night until dawn, or until `limit` steps have run.
func _step_to_dawn(ctx: RunContext, limit: int) -> void:
	for _i: int in range(limit):
		ctx.step()
		if ctx.run_manager.get_phase() == RunManager.RunPhase.DAWN:
			return


func _ids(values: Array) -> Array[StringName]:
	var ids: Array[StringName] = []
	for value: Variant in values:
		ids.append(value)
	return ids


func test_dawn_rebuilds_what_fell_for_free_and_pays_only_the_survivors() -> void:
	var ctx: RunContext = _waveless_context()
	_build(ctx, HOUSE_A, 2)
	_build(ctx, HOUSE_B)
	var gold_before: int = ctx.economy.get_gold()
	_gold_deltas = []
	_start_night(ctx)
	_fall(ctx, HOUSE_B)

	_into_dawn(ctx)

	assert_eq(_rebuilt_lists.size(), 1, "one rebuild report per dawn")
	assert_eq(_ids(_rebuilt_lists[0]), [HOUSE_B] as Array[StringName], "the fallen House")
	assert_false(ctx.buildings.is_destroyed(HOUSE_B), "it stands again")
	assert_eq(ctx.buildings.current_tier(HOUSE_B), 1, "at the tier it had")
	assert_eq(ctx.buildings.health_of(HOUSE_B), _max_hp(1), "at full health")
	assert_eq(_payouts.size(), 1, "one payout")
	assert_eq(
		_payouts[0],
		[_income(2) + _base(), {HOUSE_A: _income(2), MapConfig.CASTLE_PAYOUT_KEY: _base()}],
		"only the survivor and the castle paid"
	)
	assert_eq(
		ctx.economy.get_gold(),
		gold_before + _income(2) + _base(),
		"gold rose by the survivor and the base income only"
	)
	for delta: int in _gold_deltas:
		assert_gt(delta, 0, "the rebuild charged nothing")


func test_a_survivor_the_castle_and_the_king_are_whole_again_at_dawn() -> void:
	var ctx: RunContext = _waveless_context()
	_build(ctx, HOUSE_A, 2)
	_start_night(ctx)
	ctx.buildings.damage_building(HOUSE_A, 3)
	assert_lt(ctx.buildings.health_of(HOUSE_A), _max_hp(2), "the House is hurt")
	var castle_max: int = ctx.castle.get_max_health()
	ctx.castle.damage(castle_max - 10)
	assert_eq(ctx.castle.get_health(), 10, "the castle is down to 10")
	ctx.king.take_damage(2)
	assert_lt(ctx.king.get_health(), ctx.king.get_max_health(), "the king is hurt")

	_into_dawn(ctx)

	assert_eq(ctx.buildings.health_of(HOUSE_A), _max_hp(2), "the hurt House is repaired")
	assert_eq(ctx.castle.get_health(), castle_max, "the castle is repaired")
	assert_eq(ctx.king.get_health(), ctx.king.get_max_health(), "the king is whole")
	assert_eq(
		_payouts[0],
		[_income(2) + _base(), {HOUSE_A: _income(2), MapConfig.CASTLE_PAYOUT_KEY: _base()}],
		"a repaired survivor still pays"
	)


func test_a_rebuilt_house_pays_nothing_at_its_dawn_and_pays_at_the_next_one() -> void:
	var ctx: RunContext = _waveless_context()
	_build(ctx, HOUSE_A, 2)
	_build(ctx, HOUSE_B)
	_start_night(ctx)
	_fall(ctx, HOUSE_B)
	_into_dawn(ctx)
	assert_true(ctx.buildings.get_instance(HOUSE_B).rebuilt_this_dawn, "marked as rebuilt")
	assert_eq(ctx.buildings.dawn_income_by_spot(), {HOUSE_A: _income(2)}, "it is not paying")
	_into_day(ctx)

	_start_night(ctx)
	_into_dawn(ctx)

	assert_eq(_payouts.size(), 2, "two dawns")
	assert_eq(
		_payouts[1],
		[
			_income(2) + _income(1) + _base(),
			{HOUSE_A: _income(2), HOUSE_B: _income(1), MapConfig.CASTLE_PAYOUT_KEY: _base()}
		]
	)
	assert_eq(_ids(_rebuilt_lists[1]), [] as Array[StringName], "nothing fell the second night")


func test_a_house_that_falls_on_the_tick_the_last_enemy_dies_is_rebuilt_and_pays_nothing() -> void:
	var ctx: RunContext = _fixture_context()
	_build(ctx, HOUSE_A, 2)
	var total: int = ctx.map.night_def(1).groups[0].count
	ctx.events.enemy_died.connect(
		func(_id: int, _def: StringName, _pos: Vector2, _killer: StringName) -> void:
			_deaths += 1
			if _deaths == total:
				ctx.buildings.damage_building(HOUSE_A, ctx.buildings.max_health_of(HOUSE_A))
				_fell_at_tick = ctx.tick_count
	)
	_start_night(ctx)
	for _i: int in range(MAX_NIGHT_STEPS):
		ctx.step()
		if _fell_at_tick >= 0:
			break
	assert_gte(_fell_at_tick, 0, "the last grunt died and the House fell with it")
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "dawn came on that very step")
	assert_eq(_rebuilt_lists.size(), 1, "one rebuild report")
	assert_eq(_ids(_rebuilt_lists[0]), [HOUSE_A] as Array[StringName], "the House is in it")
	assert_false(ctx.buildings.is_destroyed(HOUSE_A), "and stands")
	assert_eq(_payouts[0], [0, {}], "it paid nothing that dawn")


func test_a_night_with_no_losses_rebuilds_nothing_and_reports_an_empty_list() -> void:
	var ctx: RunContext = _waveless_context()
	_build(ctx, HOUSE_A)
	_start_night(ctx)

	_into_dawn(ctx)

	assert_eq(_rebuilt_lists.size(), 1, "the report still fires")
	assert_eq(_rebuilt_lists[0].size(), 0, "with an empty list")
	assert_false(ctx.buildings.get_instance(HOUSE_A).rebuilt_this_dawn, "nothing was marked")
	assert_eq(
		_payouts[0],
		[_income(1) + _base(), {HOUSE_A: _income(1), MapConfig.CASTLE_PAYOUT_KEY: _base()}],
		"the survivor paid as usual, and the castle its base"
	)


func test_two_fallen_buildings_are_listed_in_map_order_whatever_fell_first() -> void:
	var ctx: RunContext = _waveless_context()
	_build(ctx, HOUSE_C)
	_build(ctx, HOUSE_A)
	_build(ctx, TOWER)
	_start_night(ctx)
	_fall(ctx, TOWER)
	_fall(ctx, HOUSE_C)
	_fall(ctx, HOUSE_A)

	_into_dawn(ctx)

	var expected: Array[StringName] = []
	for spot_id: StringName in ctx.buildings.spot_ids():
		if [HOUSE_A, HOUSE_C, TOWER].has(spot_id):
			expected.append(spot_id)
	assert_eq(_ids(_rebuilt_lists[0]), expected, "MapConfig order")
	assert_eq(expected.size(), 3, "all three were listed")


func test_a_second_rebuild_call_in_the_same_dawn_changes_nothing() -> void:
	var ctx: RunContext = _waveless_context()
	_build(ctx, HOUSE_A)
	_build(ctx, HOUSE_B, 2)
	_start_night(ctx)
	_fall(ctx, HOUSE_B)
	_into_dawn(ctx)
	var gold: int = ctx.economy.get_gold()
	var hp: int = ctx.buildings.health_of(HOUSE_B)
	var events_before: int = _rebuilt_lists.size()

	var again: Array[StringName] = ctx.buildings.rebuild_destroyed()

	assert_eq(again.size(), 0, "nothing left to rebuild")
	assert_eq(ctx.buildings.current_tier(HOUSE_B), 2, "the tier is unchanged")
	assert_eq(ctx.buildings.health_of(HOUSE_B), hp, "so is the health")
	assert_true(ctx.buildings.get_instance(HOUSE_B).rebuilt_this_dawn, "and the mark")
	assert_false(ctx.buildings.get_instance(HOUSE_A).rebuilt_this_dawn, "a survivor is not marked")
	assert_eq(ctx.economy.get_gold(), gold, "no gold moved")
	assert_eq(_rebuilt_lists.size(), events_before, "and nothing was announced")


func test_during_the_night_a_fallen_building_stays_down_and_dawn_rebuilds_it_once() -> void:
	var ctx: RunContext = _waveless_context()
	_build(ctx, HOUSE_A)
	_start_night(ctx)
	_fall(ctx, HOUSE_A)
	for _i: int in range(IDLE_NIGHT_STEPS):
		ctx.step()
		ctx.buildings.damage_building(HOUSE_A, 5)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.NIGHT, "still night")
	assert_true(ctx.buildings.is_destroyed(HOUSE_A), "still down")
	assert_eq(ctx.buildings.health_of(HOUSE_A), 0, "with no health, whatever hits arrive")
	assert_eq(_rebuilt_lists.size(), 0, "nothing was rebuilt by night")

	_into_dawn(ctx)

	assert_eq(_rebuilt_lists.size(), 1, "one rebuild, at dawn")
	assert_false(ctx.buildings.is_destroyed(HOUSE_A), "standing")


func test_a_rebuilt_building_starts_the_next_night_whole_with_its_mark_cleared() -> void:
	var ctx: RunContext = _waveless_context()
	_build(ctx, HOUSE_A, 3)
	_start_night(ctx)
	_fall(ctx, HOUSE_A)
	_into_dawn(ctx)
	assert_true(ctx.buildings.get_instance(HOUSE_A).rebuilt_this_dawn, "marked at dawn")
	_into_day(ctx)
	assert_true(ctx.buildings.get_instance(HOUSE_A).rebuilt_this_dawn, "the day keeps the mark")

	_start_night(ctx)

	var instance: BuildingInstance = ctx.buildings.get_instance(HOUSE_A)
	assert_false(instance.rebuilt_this_dawn, "the next night clears it")
	assert_eq(instance.tier, 3, "still the tier it had")
	assert_eq(instance.health, _max_hp(3), "and whole")


func test_a_destroyed_house_keeps_its_top_tier_and_that_tiers_health() -> void:
	var ctx: RunContext = _waveless_context()
	_build(ctx, HOUSE_A, _house.max_tier())
	_start_night(ctx)
	_fall(ctx, HOUSE_A)

	_into_dawn(ctx)

	assert_eq(ctx.buildings.current_tier(HOUSE_A), _house.max_tier(), "top tier rebuilt")
	assert_eq(ctx.buildings.health_of(HOUSE_A), _max_hp(_house.max_tier()), "its full health")


func test_when_every_house_fell_the_dawn_pays_nothing_and_rebuilds_them_all() -> void:
	var ctx: RunContext = _waveless_context()
	_build(ctx, HOUSE_A)
	_build(ctx, HOUSE_B, 2)
	var gold: int = ctx.economy.get_gold()
	_gold_deltas = []
	_start_night(ctx)
	_fall(ctx, HOUSE_A)
	_fall(ctx, HOUSE_B)

	_into_dawn(ctx)

	assert_eq(_ids(_rebuilt_lists[0]), [HOUSE_A, HOUSE_B] as Array[StringName], "both rebuilt")
	assert_eq(
		_payouts[0],
		[_base(), {MapConfig.CASTLE_PAYOUT_KEY: _base()}],
		"only the castle's base income paid"
	)
	assert_eq(ctx.economy.get_gold(), gold + _base(), "gold rose by the base income only")
	assert_eq(_gold_deltas.size(), 1, "gold moved once")


func test_the_payout_lists_survivors_in_map_order_and_omits_rebuilt_spots() -> void:
	var ctx: RunContext = _waveless_context()
	_build(ctx, HOUSE_C)
	_build(ctx, HOUSE_B)
	_build(ctx, HOUSE_A)
	_start_night(ctx)
	_fall(ctx, HOUSE_B)

	_into_dawn(ctx)

	var per_spot: Dictionary = _payouts[0][1]
	assert_eq(
		per_spot.keys(),
		[HOUSE_A, HOUSE_C, MapConfig.CASTLE_PAYOUT_KEY],
		"MapConfig order, the rebuilt House left out, the castle last"
	)
	assert_eq(_payouts[0][0], _income(1) * 2 + _base(), "the total is the survivors' income + base")


func test_the_dawn_reports_in_order_phase_then_rebuild_then_payout() -> void:
	var ctx: RunContext = _waveless_context()
	_build(ctx, HOUSE_A)
	_start_night(ctx)
	_fall(ctx, HOUSE_A)

	_into_dawn(ctx)

	assert_eq(_sequence, ["dawn", "rebuilt", "payout"] as Array[String], "dawn, rebuild, payout")


func test_rebuilding_charges_nothing_and_skips_a_building_that_never_fell() -> void:
	var events: SimEvents = SimEvents.new()
	var map: MapConfig = E2eSupport.waveless_prototype_map()
	var buildings: BuildingSystem = BuildingSystem.new(map, events)
	buildings.apply_next_tier(HOUSE_A)
	buildings.apply_next_tier(HOUSE_B)
	buildings.damage_building(HOUSE_B, 1000)
	buildings.damage_building(HOUSE_A, 2)
	var hurt: int = buildings.health_of(HOUSE_A)

	var rebuilt: Array[StringName] = buildings.rebuild_destroyed()

	assert_eq(rebuilt, [HOUSE_B] as Array[StringName], "only the fallen one")
	assert_eq(buildings.health_of(HOUSE_A), hurt, "rebuilding does not heal a survivor")
	assert_false(buildings.get_instance(HOUSE_A).rebuilt_this_dawn, "nor mark it")
	buildings.repair_standing()
	assert_eq(buildings.health_of(HOUSE_A), _max_hp(1), "repair does")
	buildings.clear_rebuilt_marks()
	assert_false(buildings.get_instance(HOUSE_B).rebuilt_this_dawn, "marks are cleared on demand")
	assert_eq(buildings.rebuild_destroyed().size(), 0, "an empty or unbuilt plot is never rebuilt")


func test_a_rebuilt_tower_fires_again_the_next_night() -> void:
	var ctx: RunContext = _fixture_context()
	_build(ctx, TOWER)
	_start_night(ctx)
	_fall(ctx, TOWER)
	_step_to_dawn(ctx, ROOMY_STEPS)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "night one ends")
	assert_false(ctx.buildings.is_destroyed(TOWER), "the Tower stands again")
	assert_eq(ctx.buildings.health_of(TOWER), ctx.buildings.max_health_of(TOWER), "whole")
	_into_day(ctx)
	ctx.king.report_position(KING_FAR)
	var tower_index: int = ctx.buildings.spot_index(TOWER)
	var shots: Array = []
	ctx.events.attack_fired.connect(
		func(kind: StringName, id: int, _tk: StringName, _tid: int, _flight: int) -> void:
			if kind == PendingHits.KIND_BUILDING and id == tower_index:
				shots.append(id)
	)

	_start_night(ctx)
	for _i: int in range(MAX_NIGHT_STEPS):
		ctx.step()
		if not shots.is_empty() or ctx.run_manager.get_phase() == RunManager.RunPhase.DAWN:
			break

	assert_false(shots.is_empty(), "the rebuilt Tower shot at the second night's grunts")
