extends GutTest
## UAT G-01-58 (D-05 as amended): the coin stream follows the accelerating hold. A coin flies for
## 90% of the gap to the next coin, so on every shipped build the coins still arrive one at a time,
## and the coins the 3 s cap pays in one frame leave staggered inside a short window. The flight
## ceiling is derived from LoopTuning's D-05 bound (review IN-02). Pure math, no scene tree.

const TUNING := "res://data/tuning/loop_tuning.tres"
const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const EPSILON: float = 0.0001
const FIXTURE_GAP_S: float = 0.2
const TINY_GAP_S: float = 0.01
const HUGE_GAP_S: float = 5.0
const STAGGER_GROUP_SIZES: Array[int] = [2, 6, 12, 26, 100]


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


func test_a_flight_is_ninety_percent_of_the_gap() -> void:
	assert_almost_eq(
		CoinDripVfx.flight_seconds_for(FIXTURE_GAP_S),
		FIXTURE_GAP_S * CoinDripVfx.FLIGHT_FRACTION_OF_INTERVAL,
		EPSILON,
		"0.2 s gap flies for 0.18 s"
	)


func test_a_tiny_zero_or_negative_gap_flies_for_the_minimum() -> void:
	for gap: float in [TINY_GAP_S, 0.0, -1.0]:
		assert_eq(
			CoinDripVfx.flight_seconds_for(gap),
			CoinDripVfx.MIN_FLIGHT_SECONDS,
			"gap %s is lifted to the shortest readable flight" % gap
		)


func test_a_huge_gap_flies_for_the_ceiling() -> void:
	assert_eq(
		CoinDripVfx.flight_seconds_for(HUGE_GAP_S),
		CoinDripVfx.MAX_FLIGHT_SECONDS,
		"a slow drip never flies longer than the ceiling"
	)


func test_the_ceiling_is_derived_from_the_d05_bound() -> void:
	assert_almost_eq(
		CoinDripVfx.MAX_FLIGHT_SECONDS,
		CoinDripVfx.FLIGHT_FRACTION_OF_INTERVAL * LoopTuning.COIN_DRIP_INTERVAL_MAX_S,
		EPSILON,
		"no hand-edited flight number (review IN-02)"
	)


func test_every_shipped_coin_lands_before_the_next_one_leaves() -> void:
	var tuning: LoopTuning = _tuning()
	var costs: Array[int] = _tier_costs()
	assert_gt(costs.size(), 0, "the shipped map has tiers")
	for cost: int in costs:
		for coin: int in range(1, cost):
			var gap_s: float = tuning.coin_interval(coin + 1)
			assert_lt(
				CoinDripVfx.flight_seconds_for(gap_s),
				gap_s,
				"coin %d of a %d-coin tier lands before coin %d leaves" % [coin, cost, coin + 1]
			)


func test_the_first_coin_leaves_no_visible_gap() -> void:
	var gap_s: float = _tuning().coin_interval(2)
	assert_gte(
		CoinDripVfx.flight_seconds_for(gap_s),
		CoinDripVfx.FLIGHT_FRACTION_OF_INTERVAL * gap_s - EPSILON,
		"the first coin flies for the full 90% of its gap"
	)


func test_the_stagger_is_positive_and_never_above_the_pair_gap() -> void:
	for count: int in STAGGER_GROUP_SIZES:
		var stagger_s: float = CoinDripVfx.launch_stagger(count)
		assert_gt(stagger_s, 0.0, "a group of %d is staggered" % count)
		assert_lte(
			stagger_s, CoinDripVfx.STAGGER_SECONDS + EPSILON, "never wider than the pair gap"
		)


func test_every_group_fits_the_burst_window() -> void:
	for count: int in STAGGER_GROUP_SIZES:
		assert_lte(
			float(count - 1) * CoinDripVfx.launch_stagger(count),
			CoinDripVfx.BURST_WINDOW_SECONDS + EPSILON,
			"a group of %d leaves inside the window" % count
		)


func test_a_pair_is_staggered_by_the_pair_gap() -> void:
	assert_almost_eq(
		CoinDripVfx.launch_stagger(2), CoinDripVfx.STAGGER_SECONDS, EPSILON, "two coins, one gap"
	)
