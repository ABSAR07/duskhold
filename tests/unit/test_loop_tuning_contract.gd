extends GutTest
## Data contract for the hold-to-build pace (D-05, UAT G-01-4). The shipped drip interval must
## stay inside D-05's documented range, a fresh LoopTuning must pace holds like the shipped data,
## no shipped hold may be too short, and the coin flight must not leave a gap between coins.
## Tier costs are derived from the loaded .tres data, never from literals.

const TUNING := "res://data/tuning/loop_tuning.tres"
const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
## D-05's documented per-coin drip range, inclusive (seconds).
const MIN_DRIP_INTERVAL_S: float = 0.15
const MAX_DRIP_INTERVAL_S: float = 0.3
## UAT G-01-4 judged the 0.4 s House I hold too short; no shipped hold may be shorter than this.
const MIN_HOLD_S: float = 0.5
const EPSILON: float = 0.0001


func _tuning() -> LoopTuning:
	return load(TUNING)


## The cheapest tier cost over every tier of every building on the shipped prototype map.
func _cheapest_tier_cost() -> int:
	var map: MapConfig = load(PROTOTYPE_MAP)
	var cheapest: int = -1
	for building_def: BuildingDef in map.buildings:
		for tier: BuildingTierDef in building_def.tiers:
			if cheapest < 0 or tier.cost < cheapest:
				cheapest = tier.cost
	return cheapest


func test_shipped_drip_interval_is_within_the_d05_range() -> void:
	var interval: float = _tuning().coin_drip_interval
	assert_gte(interval, MIN_DRIP_INTERVAL_S - EPSILON, "not faster than D-05's range")
	assert_lte(interval, MAX_DRIP_INTERVAL_S + EPSILON, "not slower than D-05's range")


func test_script_default_matches_the_shipped_interval() -> void:
	assert_almost_eq(
		LoopTuning.new().coin_drip_interval,
		_tuning().coin_drip_interval,
		EPSILON,
		"a fresh LoopTuning paces holds like the shipped data"
	)


func test_shortest_shipped_hold_is_at_least_the_minimum() -> void:
	var cheapest: int = _cheapest_tier_cost()
	assert_gt(cheapest, 0, "the prototype map has priced tiers")
	var shortest_hold_s: float = float(cheapest) * _tuning().coin_drip_interval
	assert_gte(
		shortest_hold_s,
		MIN_HOLD_S - EPSILON,
		"the cheapest build or upgrade takes at least %s s to hold" % MIN_HOLD_S
	)


func test_coin_flight_keeps_the_stream_unbroken_at_the_shipped_interval() -> void:
	var interval: float = _tuning().coin_drip_interval
	assert_gte(
		CoinDripVfx.MAX_FLIGHT_SECONDS,
		interval * CoinDripVfx.FLIGHT_FRACTION_OF_INTERVAL - EPSILON,
		"the flight cap does not cut the coin flight short of 90% of the interval"
	)
	assert_lt(
		CoinDripVfx.MAX_FLIGHT_SECONDS, interval, "each coin lands before the next one leaves"
	)
