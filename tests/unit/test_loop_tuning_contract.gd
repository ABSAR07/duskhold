extends GutTest
## Data contract for the hold-to-build pace (D-05 as amended by UAT G-01-58 and G-01-59, UAT
## G-01-4). The shipped first interval must stay inside D-05's documented range, a fresh LoopTuning
## must pace holds like the shipped data on all five pacing fields, no shipped hold may be shorter
## than 0.5 s, holds must accelerate down to the owner's floor and never shrink with cost, and the
## shipped data has no cap on purpose: every coin drips at its own due time (this reverses review
## WR-02's premise, and the in-range asserts below are the guard WR-02 asked for).
## Tier costs are derived from the loaded .tres data, never from literals.

const TUNING := "res://data/tuning/loop_tuning.tres"
const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
## UAT G-01-4 judged the 0.4 s House I hold too short; no shipped hold may be shorter than this.
const MIN_HOLD_S: float = 0.5
## UAT G-01-59 (owner): a coin never takes less than this after the acceleration. Retuning it at
## the Phase 2 playtest (D-09) means updating this pin with the owner.
const OWNER_FLOOR_S: float = 0.05
## Coins looked at when checking that holds accelerate.
const ACCELERATION_WINDOW: int = 10
## A tier far pricier than any shipped one, for the no-cap sum.
const LONG_COST: int = 100
## The floor must be reached within this many coins.
const FLOOR_WINDOW: int = 40
const EPSILON: float = 0.0001


func _tuning() -> LoopTuning:
	return load(TUNING)


## Every tier cost on the shipped prototype map, over every tier of every building.
func _tier_costs() -> Array[int]:
	var map: MapConfig = load(PROTOTYPE_MAP)
	var costs: Array[int] = []
	for building_def: BuildingDef in map.buildings:
		for tier: BuildingTierDef in building_def.tiers:
			costs.append(tier.cost)
	return costs


func _cheapest_tier_cost() -> int:
	var cheapest: int = -1
	for cost: int in _tier_costs():
		if cheapest < 0 or cost < cheapest:
			cheapest = cost
	return cheapest


func test_shipped_first_interval_is_within_the_d05_range() -> void:
	var interval: float = _tuning().coin_drip_interval
	assert_gte(
		interval, LoopTuning.COIN_DRIP_INTERVAL_MIN_S - EPSILON, "not faster than D-05's range"
	)
	assert_lte(
		interval, LoopTuning.COIN_DRIP_INTERVAL_MAX_S + EPSILON, "not slower than D-05's range"
	)


func test_script_defaults_match_the_shipped_pacing_data() -> void:
	var fresh: LoopTuning = LoopTuning.new()
	var shipped: LoopTuning = _tuning()
	assert_almost_eq(fresh.coin_drip_interval, shipped.coin_drip_interval, EPSILON, "interval")
	assert_eq(fresh.coin_drip_steady_coins, shipped.coin_drip_steady_coins, "steady coins")
	assert_almost_eq(fresh.coin_drip_decay, shipped.coin_drip_decay, EPSILON, "decay")
	assert_almost_eq(
		fresh.coin_drip_min_interval, shipped.coin_drip_min_interval, EPSILON, "interval floor"
	)
	assert_almost_eq(fresh.max_build_hold_seconds, shipped.max_build_hold_seconds, EPSILON, "cap")


func test_shortest_shipped_hold_is_at_least_the_minimum() -> void:
	var cheapest: int = _cheapest_tier_cost()
	assert_gt(cheapest, 0, "the prototype map has priced tiers")
	assert_gte(
		_tuning().build_hold_seconds(cheapest),
		MIN_HOLD_S - EPSILON,
		"the cheapest build or upgrade takes at least %s s to hold" % MIN_HOLD_S
	)


func test_shipped_holds_accelerate() -> void:
	var tuning: LoopTuning = _tuning()
	var accelerates: bool = false
	for coin: int in range(2, ACCELERATION_WINDOW + 1):
		if tuning.coin_interval(coin) < tuning.coin_interval(1) - EPSILON:
			accelerates = true
		assert_gte(
			tuning.coin_interval(coin),
			tuning.coin_drip_min_interval - EPSILON,
			"coin %d is not faster than the floor" % coin
		)
	assert_true(accelerates, "a later coin comes faster than the first")


func test_shipped_floor_is_the_owners_and_is_reached_and_never_undercut() -> void:
	var tuning: LoopTuning = _tuning()
	var reached: bool = false
	assert_almost_eq(tuning.coin_drip_min_interval, OWNER_FLOOR_S, EPSILON, "the owner's floor")
	for coin: int in range(1, FLOOR_WINDOW + 1):
		if absf(tuning.coin_interval(coin) - OWNER_FLOOR_S) <= EPSILON:
			reached = true
	assert_true(reached, "a coin within the first %d takes exactly the floor" % FLOOR_WINDOW)
	for coin: int in range(1, LONG_COST + 1):
		assert_gte(
			tuning.coin_interval(coin), OWNER_FLOOR_S - EPSILON, "coin %d is not under it" % coin
		)


func test_shipped_data_has_no_cap_so_every_coin_drips() -> void:
	var tuning: LoopTuning = _tuning()
	var plain_sum_s: float = 0.0
	for coin: int in range(1, LONG_COST + 1):
		plain_sum_s += tuning.coin_interval(coin)
	assert_lte(tuning.max_build_hold_seconds, 0.0, "no cap, on purpose (UAT G-01-59)")
	assert_almost_eq(
		tuning.build_hold_seconds(LONG_COST),
		plain_sum_s,
		EPSILON,
		"a %d-coin hold is the plain sum: nothing is fast-forwarded" % LONG_COST
	)


func test_shipped_pacing_fields_are_already_in_range() -> void:
	var tuning: LoopTuning = _tuning()
	assert_gt(tuning.coin_drip_decay, 0.0, "decay above 0")
	assert_lt(tuning.coin_drip_decay, 1.0, "decay below 1")
	assert_gte(tuning.coin_drip_steady_coins, 1, "at least one steady coin")
	assert_gt(tuning.coin_drip_min_interval, 0.0, "floor above 0")
	assert_lte(tuning.coin_drip_min_interval, tuning.coin_drip_interval, "floor within the first")


func test_no_shipped_hold_is_shorter_than_a_cheaper_one() -> void:
	var tuning: LoopTuning = _tuning()
	var costs: Array[int] = _tier_costs()
	for cost: int in costs:
		for other: int in costs:
			if other < cost:
				assert_gte(
					tuning.build_hold_seconds(cost),
					tuning.build_hold_seconds(other) - EPSILON,
					"a %d-coin hold is not shorter than a %d-coin one" % [cost, other]
				)


## D-01: the knockout countdown never exceeds 15 s. The owner may raise it later (D-02), and that
## decision belongs in this pin, not in code.
func test_shipped_respawn_cap_is_fifteen_seconds() -> void:
	assert_almost_eq(_tuning().respawn_cap_seconds, 15.0, EPSILON, "D-01: capped at 15 s")
	for number: int in range(1, 40):
		assert_lte(
			_tuning().respawn_seconds(number), 15.0 + EPSILON, "knockout %d within the cap" % number
		)


## D-02: the start, the step and the cap are tuning data, not constants in code.
func test_respawn_start_step_and_cap_are_exported_tuning_fields() -> void:
	var exported: Dictionary = {}
	for property: Dictionary in LoopTuning.new().get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_STORAGE != 0:
			exported[property["name"]] = true
	for field: String in ["respawn_start_seconds", "respawn_step_seconds", "respawn_cap_seconds"]:
		assert_true(exported.has(field), "%s is a stored, exported field" % field)
	var tuning: LoopTuning = _tuning()
	assert_gt(tuning.respawn_start_seconds, 0.0, "the shipped start is set in the data file")
	assert_gt(tuning.respawn_step_seconds, 0.0, "the shipped step is set in the data file")


## Owner decision 2026-10-06 (UAT G-02-1, speed-up part b): switching fast_forward on at night runs
## the game at this multiple of real time (a toggle since 2026-10-07, G-02-14). The shipped value
## is written in the data file itself and is at least the owner's 1.5; the script default is 1.0
## (off) and the cap is 4.0.
func test_shipped_fast_forward_is_set_in_the_data_file_and_at_least_one_and_a_half() -> void:
	var exported: Dictionary = {}
	for property: Dictionary in LoopTuning.new().get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_STORAGE != 0:
			exported[property["name"]] = true
	assert_true(exported.has("fast_forward_scale"), "a stored, exported field")
	assert_eq(LoopTuning.new().fast_forward_scale, 1.0, "the script default is off")
	assert_eq(LoopTuning.FAST_FORWARD_MAX_SCALE, 4.0, "the cap against bad data")
	var data_text: String = FileAccess.get_file_as_string(TUNING)
	assert_true(
		data_text.contains("\nfast_forward_scale = "),
		"the scale is written in loop_tuning.tres itself, not left to the script default"
	)
	var scale: float = _tuning().fast_forward_scale
	assert_gte(scale, 1.5, "at least the 1.5x the owner asked for")
	assert_lte(scale, 3.0, "not so fast the night is unplayable")


## WR-03: the results screen ignores presses for this many real seconds after it appears, because
## the build key doubles as ui_accept. It is tuning data: long enough to outlast a frantic tap,
## short enough that a player who wants to restart is not kept waiting.
func test_shipped_results_input_grace_is_set_in_the_data_file_and_short() -> void:
	var exported: Dictionary = {}
	for property: Dictionary in LoopTuning.new().get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_STORAGE != 0:
			exported[property["name"]] = true
	assert_true(exported.has("results_input_grace_seconds"), "a stored, exported field")
	# The script default equals the shipped value, so the loaded resource cannot tell a stored value
	# from the default; only the text of the data file can (review IN-03).
	var data_text: String = FileAccess.get_file_as_string(TUNING)
	assert_ne(data_text, "", "the tuning data file can be read")
	assert_true(
		data_text.contains("\nresults_input_grace_seconds = "),
		"the grace is written in loop_tuning.tres itself, not left to the script default"
	)
	var grace: float = _tuning().results_input_grace_seconds
	assert_gte(grace, 0.3, "long enough to outlast a tap")
	assert_lte(grace, 1.0, "short enough not to feel stuck")
