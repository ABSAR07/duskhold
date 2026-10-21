extends GutTest
## ECON-03, D-12, D-14: the Gold Mine's declining payout, kept by IncomeState beside BuildingSystem.
## The curve numbers are set on a deep copy of the shipped def (first payout 3, step 1, floor 1), so
## a later fit of the shipped cost and first payout cannot break these tests;
## test_economy_data_contract is the one place the shipped numbers are pinned.

const MINE: StringName = &"gold_mine_1"
const HOUSE: StringName = &"house_1"
const START: int = 3
const STEP: int = 1
const FLOOR: int = 1
const RICH_GOLD: int = 100

var _map: MapConfig
var _events: SimEvents
var _buildings: BuildingSystem
var _income: IncomeState


func before_each() -> void:
	_map = E2eSupport.waveless_prototype_map()
	_map.starting_gold = RICH_GOLD
	_set_curve(START, STEP, FLOOR)
	_rebuild_systems()


func _set_curve(start: int, step: int, floor_gold: int) -> void:
	for building_def: BuildingDef in _map.buildings:
		if building_def.id == &"gold_mine":
			var tier: BuildingTierDef = building_def.tier_def(1)
			tier.dawn_income = start
			tier.income_step = step
			tier.income_floor = floor_gold


func _rebuild_systems() -> void:
	_events = SimEvents.new()
	_buildings = BuildingSystem.new(_map, _events)
	_income = IncomeState.new(_map, _buildings, _events)


func _build(spot_id: StringName) -> void:
	assert_not_null(_buildings.apply_next_tier(spot_id), "%s built" % spot_id)


## One dawn the way RunManager runs it: the rebuild first (the caller does that), then the payouts.
func _payout_of(spot_id: StringName) -> int:
	return int(_income.dawn_payouts().get(spot_id, 0))


## A new night begins: nothing counts as rebuilt this dawn any more.
func _next_night() -> void:
	_buildings.clear_rebuilt_marks()


func test_five_standing_dawns_pay_three_two_one_one_one() -> void:
	_build(MINE)
	var paid: Array[int] = []
	for dawn: int in range(5):
		paid.append(_payout_of(MINE))
		_next_night()
	assert_eq(paid, [3, 2, 1, 1, 1] as Array[int], "start 3, step 1, floor 1: never 0")


func test_the_paid_dawn_count_stops_at_the_first_count_that_pays_the_floor() -> void:
	_build(MINE)
	var counts: Array[int] = []
	for dawn: int in range(5):
		_income.dawn_payouts()
		counts.append(_income.mine_paid_dawns(MINE))
	assert_eq(counts, [1, 2, 2, 2, 2] as Array[int], "it stops at ceil((3 - 1) / 1) = 2")


func test_next_payout_before_each_dawn_is_what_that_dawn_pays() -> void:
	_build(MINE)
	for dawn: int in range(5):
		var promised: int = _income.next_payout(MINE)
		assert_eq(_payout_of(MINE), promised, "dawn %d pays what next_payout said" % (dawn + 1))


func test_reading_next_payout_and_the_count_changes_nothing() -> void:
	_build(MINE)
	for read: int in range(10):
		_income.next_payout(MINE)
		_income.mine_paid_dawns(MINE)
	assert_eq(_income.mine_paid_dawns(MINE), 0, "no dawn has paid yet")
	assert_eq(_payout_of(MINE), START, "the first dawn still pays the starting gold")


func test_a_step_of_two_stops_at_the_count_that_reaches_the_floor() -> void:
	_set_curve(4, 2, 1)
	_rebuild_systems()
	_build(MINE)
	var paid: Array[int] = []
	for dawn: int in range(4):
		paid.append(_payout_of(MINE))
	assert_eq(paid, [4, 2, 1, 1] as Array[int], "4, 2, then 4 - 2 * 2 = 0 clamps to the floor 1")
	assert_eq(_income.mine_paid_dawns(MINE), 2, "ceil((4 - 1) / 2) = 2 and no more")


func test_a_rebuilt_mine_pays_nothing_and_makes_no_progress() -> void:
	_build(MINE)
	assert_eq(_payout_of(MINE), START, "dawn 1")
	_next_night()
	_buildings.damage_building(MINE, _buildings.max_health_of(MINE))
	assert_true(_buildings.is_destroyed(MINE), "the Mine fell in night 2")
	_buildings.rebuild_destroyed()
	var dawn_two: Dictionary = _income.dawn_payouts()
	assert_false(dawn_two.has(MINE), "rebuilt this dawn: no payout entry")
	assert_eq(_income.mine_paid_dawns(MINE), 1, "its count is unchanged")
	assert_eq(_income.next_payout(MINE), START - STEP, "the skipped dawn is still ahead")
	_next_night()
	assert_eq(_payout_of(MINE), START - STEP, "dawn 3 pays exactly what dawn 2 would have")


func test_a_fallen_mine_that_was_not_rebuilt_pays_nothing_and_keeps_its_count() -> void:
	_build(MINE)
	_income.dawn_payouts()
	_next_night()
	_buildings.damage_building(MINE, _buildings.max_health_of(MINE))
	assert_false(_income.dawn_payouts().has(MINE), "a fallen Mine pays nothing")
	assert_eq(_income.mine_paid_dawns(MINE), 1, "and loses nothing it accumulated")


func test_with_no_mine_built_there_are_no_payouts_and_nothing_to_promise() -> void:
	assert_eq(_income.dawn_payouts(), {}, "empty")
	assert_eq(_income.next_payout(MINE), 0, "an empty plot promises nothing")
	assert_eq(_income.mine_paid_dawns(MINE), 0, "and has paid nothing")


func test_a_flat_house_is_never_in_the_non_flat_payouts() -> void:
	_build(HOUSE)
	_build(MINE)
	var payouts: Dictionary = _income.dawn_payouts()
	assert_false(payouts.has(HOUSE), "the House is paid by BuildingSystem")
	assert_eq(_income.next_payout(HOUSE), 0, "a flat building has no decline to promise")
	assert_eq(_income.mine_paid_dawns(HOUSE), 0, "and no count")


func test_the_mine_is_never_in_the_flat_payouts() -> void:
	_build(HOUSE)
	_build(MINE)
	var flat: Dictionary = _buildings.dawn_income_by_spot()
	assert_true(flat.has(HOUSE), "the House pays through BuildingSystem")
	assert_false(flat.has(MINE), "the Mine is paid by IncomeState alone, never twice")


func test_a_step_below_one_never_lowers_the_payout_or_counts() -> void:
	_set_curve(START, 0, FLOOR)
	_rebuild_systems()
	_build(MINE)
	for dawn: int in range(5):
		assert_eq(_payout_of(MINE), START, "bad data pays the first payout every dawn")
	assert_eq(_income.mine_paid_dawns(MINE), 0, "and no counter grows")


func test_the_payout_is_data_not_a_literal() -> void:
	_set_curve(7, 2, 3)
	_rebuild_systems()
	_build(MINE)
	var paid: Array[int] = []
	for dawn: int in range(4):
		paid.append(_payout_of(MINE))
	assert_eq(paid, [7, 5, 3, 3] as Array[int], "7, 5, 3 then the floor 3")
