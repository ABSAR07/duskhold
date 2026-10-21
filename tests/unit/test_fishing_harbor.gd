extends GutTest
## ECON-05, D-12, D-14: the Fishing Harbor's boats, kept by IncomeState beside BuildingSystem. One
## boat is gained at every dawn the Harbor stands and was not rebuilt, up to the cap of its tier,
## and every boat pays the tier's gold; harbor_boats_changed is emitted only when the count
## changes. The numbers are set on a deep copy of the shipped def (cap 3 then 5, gold per boat 1
## then 2), so a later fit of the shipped numbers cannot break these tests;
## test_economy_data_contract is the one place the shipped numbers are pinned.

const HARBOR: StringName = &"harbor_1"
const HOUSE: StringName = &"house_1"
const CAP_ONE: int = 3
const CAP_TWO: int = 5
const GOLD_ONE: int = 1
const GOLD_TWO: int = 2
const RICH_GOLD: int = 100

var _map: MapConfig
var _events: SimEvents
var _buildings: BuildingSystem
var _income: IncomeState


func before_each() -> void:
	_map = E2eSupport.waveless_prototype_map()
	_map.starting_gold = RICH_GOLD
	_set_tiers(CAP_ONE, GOLD_ONE, CAP_TWO, GOLD_TWO)
	_rebuild_systems()


func _set_tiers(cap_one: int, gold_one: int, cap_two: int, gold_two: int) -> void:
	for building_def: BuildingDef in _map.buildings:
		if building_def.id == &"fishing_harbor":
			var one: BuildingTierDef = building_def.tier_def(1)
			one.boat_cap = cap_one
			one.boat_income = gold_one
			var two: BuildingTierDef = building_def.tier_def(2)
			two.boat_cap = cap_two
			two.boat_income = gold_two


func _rebuild_systems() -> void:
	_events = SimEvents.new()
	_buildings = BuildingSystem.new(_map, _events)
	_income = IncomeState.new(_map, _buildings, _events)
	watch_signals(_events)


func _build(spot_id: StringName) -> void:
	assert_not_null(_buildings.apply_next_tier(spot_id), "%s built" % spot_id)


func _payout_of(spot_id: StringName) -> int:
	return int(_income.dawn_payouts().get(spot_id, 0))


## A new night begins: nothing counts as rebuilt this dawn any more.
func _next_night() -> void:
	_buildings.clear_rebuilt_marks()


## `dawns` standing dawns in a row; the payouts in order.
func _dawns(dawns: int) -> Array[int]:
	var paid: Array[int] = []
	for dawn: int in range(dawns):
		paid.append(_payout_of(HARBOR))
		_next_night()
	return paid


func _changes() -> int:
	return get_signal_emit_count(_events, "harbor_boats_changed")


func test_four_standing_dawns_give_one_two_three_three_boats_paying_the_same() -> void:
	_build(HARBOR)
	var boats: Array[int] = []
	var paid: Array[int] = []
	for dawn: int in range(4):
		paid.append(_payout_of(HARBOR))
		boats.append(_income.boats_of(HARBOR))
		_next_night()
	assert_eq(boats, [1, 2, 3, 3] as Array[int], "one boat a dawn up to the cap of 3")
	assert_eq(paid, [1, 2, 3, 3] as Array[int], "each boat pays 1")


func test_the_event_is_emitted_for_each_new_count_and_never_at_the_cap() -> void:
	_build(HARBOR)
	_dawns(4)
	assert_signal_emit_count(_events, "harbor_boats_changed", 3, "1, 2 and 3; the fourth is silent")
	assert_eq(get_signal_parameters(_events, "harbor_boats_changed", 0), [HARBOR, 1], "first boat")
	assert_eq(get_signal_parameters(_events, "harbor_boats_changed", 1), [HARBOR, 2], "second boat")
	assert_eq(get_signal_parameters(_events, "harbor_boats_changed", 2), [HARBOR, 3], "third boat")


func test_after_the_upgrade_the_next_dawns_give_four_and_five_boats_and_stop() -> void:
	_build(HARBOR)
	_dawns(3)
	_build(HARBOR)
	assert_eq(_income.boats_of(HARBOR), CAP_ONE, "the upgrade bought by day keeps the boats")
	var boats: Array[int] = []
	var paid: Array[int] = []
	for dawn: int in range(3):
		paid.append(_payout_of(HARBOR))
		boats.append(_income.boats_of(HARBOR))
		_next_night()
	assert_eq(boats, [4, 5, 5] as Array[int], "the new cap of 5 is reached and held")
	assert_eq(
		paid,
		[4 * GOLD_TWO, 5 * GOLD_TWO, 5 * GOLD_TWO] as Array[int],
		"every boat pays the second tier's gold"
	)
	assert_signal_emit_count(_events, "harbor_boats_changed", 5, "1, 2, 3, 4, 5 and no more")


func test_a_harbor_bought_today_has_no_boat_and_pays_nothing_until_its_first_dawn() -> void:
	_build(HARBOR)
	assert_eq(_income.boats_of(HARBOR), 0, "no boat the day it is bought")
	assert_eq(_changes(), 0, "and no event")
	assert_eq(_payout_of(HARBOR), GOLD_ONE, "its first dawn gives the first boat and pays for it")
	assert_eq(_income.boats_of(HARBOR), 1, "now one boat")


func test_an_unbuilt_harbor_is_absent_from_the_payouts_and_has_no_boats() -> void:
	var payouts: Dictionary = _income.dawn_payouts()
	assert_false(payouts.has(HARBOR), "an empty plot pays nothing")
	assert_eq(_income.boats_of(HARBOR), 0, "and has no boats")
	assert_eq(_income.next_payout(HARBOR), 0, "and promises nothing")
	assert_eq(_changes(), 0, "no event")


func test_a_rebuilt_harbor_gains_no_boat_pays_nothing_and_keeps_every_boat() -> void:
	_build(HARBOR)
	_dawns(2)
	_buildings.damage_building(HARBOR, _buildings.max_health_of(HARBOR))
	assert_true(_buildings.is_destroyed(HARBOR), "the Harbor fell in the night")
	assert_eq(_income.boats_of(HARBOR), 2, "its boats stay when it falls")
	var events_before: int = _changes()
	_buildings.rebuild_destroyed()
	var dawn: Dictionary = _income.dawn_payouts()
	assert_false(dawn.has(HARBOR), "rebuilt this dawn: no payout entry")
	assert_eq(_income.boats_of(HARBOR), 2, "no boat gained")
	assert_eq(_changes(), events_before, "and no event")
	_next_night()
	assert_eq(_payout_of(HARBOR), 3 * GOLD_ONE, "the next dawn the third boat arrives and pays")


func test_a_fallen_harbor_that_was_not_rebuilt_pays_nothing_and_keeps_its_boats() -> void:
	_build(HARBOR)
	_dawns(2)
	_buildings.damage_building(HARBOR, _buildings.max_health_of(HARBOR))
	var events_before: int = _changes()
	assert_false(_income.dawn_payouts().has(HARBOR), "a destroyed Harbor is skipped")
	assert_eq(_income.boats_of(HARBOR), 2, "its boats stay")
	assert_eq(_changes(), events_before, "no event")


func test_next_payout_before_each_dawn_is_what_that_dawn_pays() -> void:
	_build(HARBOR)
	for dawn: int in range(5):
		var promised: int = _income.next_payout(HARBOR)
		assert_eq(_payout_of(HARBOR), promised, "dawn %d pays what next_payout said" % (dawn + 1))
		_next_night()


func test_reading_the_boats_and_the_promise_changes_nothing() -> void:
	_build(HARBOR)
	for read: int in range(10):
		_income.next_payout(HARBOR)
		_income.boats_of(HARBOR)
	assert_eq(_income.boats_of(HARBOR), 0, "no dawn has come yet")
	assert_eq(_changes(), 0, "no event")
	assert_eq(_payout_of(HARBOR), GOLD_ONE, "the first dawn still pays one boat")


func test_a_harbor_with_a_cap_of_zero_never_gains_a_boat() -> void:
	_set_tiers(0, GOLD_ONE, CAP_TWO, GOLD_TWO)
	_rebuild_systems()
	_build(HARBOR)
	assert_eq(_dawns(3), [0, 0, 0] as Array[int], "no boats, no gold")
	assert_eq(_income.boats_of(HARBOR), 0, "bad data never adds a boat")
	assert_eq(_changes(), 0, "and never announces one")


func test_the_harbor_pays_beside_a_house_in_map_order() -> void:
	_build(HARBOR)
	_build(HOUSE)
	var flat: Dictionary = _buildings.dawn_income_by_spot()
	assert_true(flat.has(HOUSE), "the House is paid by BuildingSystem")
	assert_false(flat.has(HARBOR), "the Harbor never is: one payer per curve")
	assert_true(_income.dawn_payouts().has(HARBOR), "IncomeState pays the Harbor")


func test_the_harbor_tiers_say_they_pay_and_describe_their_boats() -> void:
	var def: BuildingDef = _buildings.get_building_def_for_spot(HARBOR)
	assert_true(def.pays_income(1), "tier I names gold per boat")
	assert_true(def.pays_income(2), "and so does tier II")
	assert_eq(
		def.tier_effect_line(1),
		"+1 boat each dawn, up to %d, %d gold each" % [CAP_ONE, GOLD_ONE],
		"tier I line"
	)
	assert_eq(
		def.tier_effect_line(2),
		"+1 boat each dawn, up to %d, %d gold each" % [CAP_TWO, GOLD_TWO],
		"tier II line"
	)
