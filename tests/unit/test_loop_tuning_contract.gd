extends GutTest
## Data contract for the hold-to-build pace (D-05 as amended by UAT G-01-58, UAT G-01-4). The
## shipped first interval must stay inside D-05's documented range, a fresh LoopTuning must pace
## holds like the shipped data on all five pacing fields, no shipped hold may be shorter than
## 0.5 s or longer than the owner's 3 s cap, and holds must accelerate and never shrink with cost.
## Tier costs are derived from the loaded .tres data, never from literals.

const TUNING := "res://data/tuning/loop_tuning.tres"
const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
## UAT G-01-4 judged the 0.4 s House I hold too short; no shipped hold may be shorter than this.
const MIN_HOLD_S: float = 0.5
## UAT G-01-58 (owner): a hold never takes longer than 3 s.
const OWNER_MAX_HOLD_S: float = 3.0
## Coins looked at when checking that holds accelerate.
const ACCELERATION_WINDOW: int = 10
const HUGE_COST: int = 1000
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


func test_shipped_cap_is_set_and_at_most_the_owner_maximum() -> void:
	var tuning: LoopTuning = _tuning()
	assert_gt(tuning.max_build_hold_seconds, 0.0, "the shipped hold has a cap")
	assert_lte(tuning.max_build_hold_seconds, OWNER_MAX_HOLD_S + EPSILON, "no longer than 3 s")
	assert_almost_eq(
		tuning.build_hold_seconds(HUGE_COST),
		tuning.max_build_hold_seconds,
		EPSILON,
		"a huge tier takes exactly the cap"
	)


func test_every_shipped_hold_is_capped_and_never_shorter_than_a_cheaper_one() -> void:
	var tuning: LoopTuning = _tuning()
	var costs: Array[int] = _tier_costs()
	for cost: int in costs:
		assert_lte(
			tuning.build_hold_seconds(cost),
			tuning.max_build_hold_seconds + EPSILON,
			"a %d-coin hold is within the cap" % cost
		)
		for other: int in costs:
			if other < cost:
				assert_gte(
					tuning.build_hold_seconds(cost),
					tuning.build_hold_seconds(other) - EPSILON,
					"a %d-coin hold is not shorter than a %d-coin one" % [cost, other]
				)
