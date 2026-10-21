extends GutTest
## ECON-04, D-10, D-13, D-03: the Mill and its Fields on the prototype map's RunContext, with gold
## granted.
## The three Fields are locked from day 1 by requires_spot (plan 05-05's mechanism): refused for
## free until mill_1 stands at tier I. Once built the Mill and each Field pay their own flat gold at
## dawn through the one dawn_payout, listed in MapConfig order before the castle key. The Mill's
## third tier is the first shipped top tier gated at castle II (D-03). Expected numbers are read
## from the shipped .tres (or set on a deep copy), never repeated here: plan 05-11's fit cannot
## break these tests, and test_economy_data_contract is the one place the numbers are pinned.

const TUNING := "res://data/tuning/loop_tuning.tres"
const MILL: StringName = &"mill_1"
const FIELD_1: StringName = &"field_1"
const FIELD_2: StringName = &"field_2"
const FIELD_3: StringName = &"field_3"
const FIELDS: Array[StringName] = [FIELD_1, FIELD_2, FIELD_3]
const CASTLE: StringName = &"castle_plot"
const RICH_GOLD: int = 200

var _tuning: LoopTuning
var _map: MapConfig
var _ctx: RunContext


func before_each() -> void:
	_tuning = load(TUNING)
	_map = E2eSupport.waveless_prototype_map()
	_map.starting_gold = RICH_GOLD
	_new_context()


## A fresh run on the (possibly edited) map copy, its events watched.
func _new_context() -> void:
	_ctx = RunContext.new(_map, _tuning)
	watch_signals(_ctx.events)


func _buy(spot_id: StringName, choice_id: StringName = &"") -> void:
	var reason: StringName = _ctx.commands.submit(BuildIntent.new(spot_id, choice_id))
	assert_eq(reason, CommandProcessor.OK, "%s bought" % spot_id)


func _income(spot_id: StringName, tier: int) -> int:
	return _ctx.buildings.get_building_def_for_spot(spot_id).tier_def(tier).dawn_income


func _castle_two_pick() -> StringName:
	var castle: BuildingDef = _ctx.buildings.get_building_def_for_spot(CASTLE)
	return castle.tier_def(2).choices[0].id


## Night then dawn, by ticking the run manager through the timed night; the payout it emits.
func _next_payout() -> Dictionary:
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	_ctx.run_manager.tick(_tuning.placeholder_night_seconds + 0.1)
	assert_eq(_ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "dawn reached")
	var emissions: int = get_signal_emit_count(_ctx.events, "dawn_payout")
	var params: Variant = get_signal_parameters(_ctx.events, "dawn_payout", emissions - 1)
	return (params as Array)[1] if params != null else {}


func test_a_field_is_refused_for_free_while_the_mill_is_unbuilt() -> void:
	var gold: int = _ctx.economy.get_gold()
	for field_id: StringName in FIELDS:
		assert_eq(_ctx.commands.validate_build(field_id), CommandProcessor.NEEDS_SPOT, field_id)
		var reason: StringName = _ctx.commands.submit(BuildIntent.new(field_id))
		assert_eq(reason, CommandProcessor.NEEDS_SPOT, "%s refused" % field_id)
		assert_eq(_ctx.buildings.current_tier(field_id), 0, "%s was not built" % field_id)
	assert_eq(_ctx.economy.get_gold(), gold, "nothing was spent")
	assert_signal_emit_count(_ctx.events, "command_rejected", 3, "each refusal was announced")


func test_the_lock_lifts_when_the_mill_reaches_tier_one() -> void:
	_buy(MILL)
	for field_id: StringName in FIELDS:
		assert_eq(
			_ctx.commands.validate_build(field_id), CommandProcessor.OK, "%s opens" % field_id
		)


func test_the_lock_follows_the_required_tier_in_data() -> void:
	for spot: BuildSpotDef in _map.spots:
		if spot.requires_spot == MILL:
			spot.requires_spot_tier = 2
	_new_context()
	_buy(MILL)
	assert_eq(_ctx.commands.validate_build(FIELD_1), CommandProcessor.NEEDS_SPOT, "Mill I is short")
	_buy(MILL)
	assert_eq(_ctx.commands.validate_build(FIELD_1), CommandProcessor.OK, "Mill II opens it")


func test_a_field_costs_and_pays_its_flat_gold_at_dawn() -> void:
	_buy(MILL)
	var gold: int = _ctx.economy.get_gold()
	_buy(FIELD_2)
	var field_def: BuildingDef = _ctx.buildings.get_building_def_for_spot(FIELD_2)
	assert_eq(
		_ctx.economy.get_gold(), gold - field_def.tier_def(1).cost, "it cost its tier I price"
	)
	assert_eq(field_def.income_curve, BuildingDef.IncomeCurve.FLAT, "a Field is FLAT")
	assert_eq(field_def.max_tier(), 1, "and has one tier")
	var payout: Dictionary = _next_payout()
	assert_eq(payout[FIELD_2], _income(FIELD_2, 1), "it paid its flat gold")


func test_mill_and_field_pay_in_map_order_before_the_castle_key() -> void:
	_buy(MILL)
	_buy(FIELD_2)
	_buy(FIELD_1)
	var payout: Dictionary = _next_payout()
	var order: Array = [MILL, FIELD_1, FIELD_2, MapConfig.CASTLE_PAYOUT_KEY]
	assert_eq(payout.keys(), order, "map order, castle last")
	assert_eq(payout[MILL], _income(MILL, 1), "the Mill pays its tier I income")
	assert_eq(payout[FIELD_1], _income(FIELD_1, 1), "Field one pays its flat gold")
	assert_eq(payout[FIELD_2], _income(FIELD_2, 1), "Field two pays its flat gold")


func test_with_only_the_mill_built_no_field_is_in_the_payout() -> void:
	_buy(MILL)
	var payout: Dictionary = _next_payout()
	assert_true(payout.has(MILL), "the Mill pays")
	for field_id: StringName in FIELDS:
		assert_false(payout.has(field_id), "%s is unbuilt and absent" % field_id)


func test_exactly_one_built_field_is_the_only_field_in_the_payout() -> void:
	_buy(MILL)
	_buy(FIELD_3)
	var payout: Dictionary = _next_payout()
	assert_eq(payout[FIELD_3], _income(FIELD_3, 1), "field_3 carries its gold")
	assert_false(payout.has(FIELD_1), "field_1 is not in it")
	assert_false(payout.has(FIELD_2), "field_2 is not in it")


func test_mill_two_raises_only_the_mills_own_payout() -> void:
	_buy(MILL)
	_buy(FIELD_1)
	_buy(MILL)
	assert_eq(_ctx.buildings.current_tier(MILL), 2, "Mill II stands")
	var payout: Dictionary = _next_payout()
	assert_eq(payout[MILL], _income(MILL, 2), "the Mill pays its tier II income")
	assert_eq(payout[FIELD_1], _income(FIELD_1, 1), "the Field is unchanged")
	assert_eq(_ctx.buildings.current_tier(FIELD_1), 1, "and no Field gained a tier")


func test_mill_three_needs_the_castle_at_tier_two_and_not_before() -> void:
	_buy(MILL)
	_buy(MILL)
	var gold: int = _ctx.economy.get_gold()
	assert_eq(_ctx.commands.validate_build(MILL), CommandProcessor.CASTLE_TIER, "castle I is short")
	assert_eq(_ctx.commands.submit(BuildIntent.new(MILL)), CommandProcessor.CASTLE_TIER, "refused")
	assert_eq(_ctx.economy.get_gold(), gold, "for free")
	_buy(CASTLE, _castle_two_pick())
	assert_eq(_ctx.buildings.current_tier(CASTLE), 2, "the castle is at tier II")
	assert_eq(_ctx.commands.validate_build(MILL), CommandProcessor.OK, "Mill III is now buyable")
	_buy(MILL)
	assert_eq(_ctx.buildings.current_tier(MILL), 3, "Mill III stands")


func test_mill_tiers_one_and_two_are_not_gated_by_the_castle() -> void:
	var mill: BuildingDef = _ctx.buildings.get_building_def_for_spot(MILL)
	assert_eq(mill.tier_def(1).requires_castle_tier, 0, "tier I needs no castle")
	assert_eq(mill.tier_def(2).requires_castle_tier, 0, "tier II needs no castle")
	assert_gt(mill.tier_def(3).requires_castle_tier, 0, "the top tier is gated (D-03)")
	assert_eq(_ctx.commands.validate_build(MILL), CommandProcessor.OK, "Mill I is buyable at once")


func test_a_king_equidistant_from_two_plots_focuses_the_earlier_in_map_order() -> void:
	var radius: float = _tuning.interaction_radius
	var field_1: Vector3 = _ctx.buildings.get_spot(FIELD_1).position
	var field_2: Vector3 = _ctx.buildings.get_spot(FIELD_2).position
	var middle: Vector3 = (field_1 + field_2) * 0.5
	var found: StringName = _ctx.buildings.nearest_spot_in_range(middle, radius + 1.0)
	assert_eq(found, FIELD_1, "field_1 comes before field_2 in the map")
	var mill: Vector3 = _ctx.buildings.get_spot(MILL).position
	var between_mill_and_field_two: Vector3 = (mill + field_2) * 0.5
	found = _ctx.buildings.nearest_spot_in_range(between_mill_and_field_two, radius + 1.0)
	assert_eq(found, MILL, "mill_1 comes before field_2 in the map")
