extends GutTest
## Pure math of the accelerating, uncapped build hold (D-05 as amended by UAT G-01-58 and
## G-01-59). Builds LoopTuning with explicit curve values, independent of the shipped data, and
## pins the interval schedule on the owner's G-01-59 values (0.25 s first, 2 steady coins, decay
## 0.9, floor 0.05 s, no cap), the running due times, the dormant cap mode and the guards against
## bad data (T-01-23). Expected numbers come from the owner table in
## .planning/debug/build-hold-no-cap-min-interval.md. These are characterization tests: if one
## fails, check the arithmetic against that table before touching simulation/defs/loop_tuning.gd.

const FIRST_S: float = 0.25
const STEADY_COINS: int = 2
const DECAY: float = 0.9
## Owner value, UAT G-01-59: the fastest a coin ever drips.
const FLOOR_S: float = 0.05
## The cap argument that means "no cap": the shipped state since UAT G-01-59.
const NO_CAP_S: float = 0.0
## A cap the data could set. Used only by the dormant-cap tests; the shipped data has no cap.
const CAP_FIXTURE_S: float = 3.0
const TOLERANCE: float = 0.001
const EXACT_TOLERANCE: float = 0.0001
const COINS_CHECKED: int = 80
## First coin whose interval sits on the floor (coin 17 is still 0.05147 s).
const FLOOR_COIN: int = 18
const LAST_COIN_ABOVE_FLOOR: int = 17
const LAST_COST_CHECKED: int = 60
const CAP_COINS_CHECKED: int = 50
const HUGE_COST: int = 50
## Owner-table holds (debug file, UAT G-01-59): tier cost -> seconds for a full hold.
const HOLD_COSTS: Array[int] = [2, 3, 4, 5, 6, 10, 15, 30, 50]
const HOLD_SECONDS: Array[float] = [
	0.5, 0.725, 0.9275, 1.10975, 1.273775, 1.78145, 2.17808, 2.93674, 3.93674
]


func _curve(
	first: float = FIRST_S,
	steady: int = STEADY_COINS,
	decay: float = DECAY,
	floor_s: float = FLOOR_S,
	cap: float = NO_CAP_S
) -> LoopTuning:
	var tuning: LoopTuning = LoopTuning.new()
	tuning.coin_drip_interval = first
	tuning.coin_drip_steady_coins = steady
	tuning.coin_drip_decay = decay
	tuning.coin_drip_min_interval = floor_s
	tuning.max_build_hold_seconds = cap
	return tuning


func test_the_first_and_steady_coins_take_the_first_interval() -> void:
	var tuning: LoopTuning = _curve()
	assert_almost_eq(tuning.coin_interval(1), FIRST_S, TOLERANCE, "coin 1")
	assert_almost_eq(tuning.coin_interval(2), FIRST_S, TOLERANCE, "coin 2")


func test_later_coins_take_a_decaying_share() -> void:
	var tuning: LoopTuning = _curve()
	assert_almost_eq(tuning.coin_interval(3), FIRST_S * DECAY, TOLERANCE, "coin 3")
	assert_almost_eq(tuning.coin_interval(4), FIRST_S * DECAY * DECAY, TOLERANCE, "coin 4")


func test_the_interval_never_drops_below_the_floor() -> void:
	var tuning: LoopTuning = _curve()
	assert_gt(tuning.coin_interval(LAST_COIN_ABOVE_FLOOR), FLOOR_S, "coin 17 is still above it")
	assert_almost_eq(tuning.coin_interval(FLOOR_COIN), FLOOR_S, EXACT_TOLERANCE, "coin 18 is on it")
	assert_almost_eq(tuning.coin_interval(HUGE_COST), FLOOR_S, EXACT_TOLERANCE, "and stays on it")


func test_due_seconds_are_the_running_sum_of_intervals() -> void:
	var tuning: LoopTuning = _curve()
	var expected: Array[float] = [0.25, 0.5, 0.725, 0.9275]
	for i: int in expected.size():
		assert_almost_eq(
			tuning.coin_due_seconds(i + 1), expected[i], TOLERANCE, "coin %d" % (i + 1)
		)


func test_hold_seconds_match_the_owner_table() -> void:
	var tuning: LoopTuning = _curve()
	for i: int in HOLD_COSTS.size():
		assert_almost_eq(
			tuning.build_hold_seconds(HOLD_COSTS[i]),
			HOLD_SECONDS[i],
			TOLERANCE,
			"a %d-coin hold" % HOLD_COSTS[i]
		)


func test_each_coin_past_the_floor_adds_exactly_the_floor() -> void:
	var tuning: LoopTuning = _curve()
	for cost: int in range(FLOOR_COIN, LAST_COST_CHECKED + 1):
		assert_almost_eq(
			tuning.build_hold_seconds(cost) - tuning.build_hold_seconds(cost - 1),
			FLOOR_S,
			EXACT_TOLERANCE,
			"coin %d adds the floor" % cost
		)


func test_a_dormant_cap_clamps_every_coin_whose_running_sum_reaches_it() -> void:
	var tuning: LoopTuning = _curve(FIRST_S, STEADY_COINS, DECAY, FLOOR_S, CAP_FIXTURE_S)
	var running_s: float = 0.0
	var before_cap: int = 0
	var at_cap: int = 0
	for coin: int in range(1, CAP_COINS_CHECKED + 1):
		running_s += tuning.coin_interval(coin)
		if running_s >= CAP_FIXTURE_S:
			at_cap += 1
			assert_eq(
				tuning.coin_due_seconds(coin), CAP_FIXTURE_S, "coin %d is due at the cap" % coin
			)
		else:
			before_cap += 1
			assert_almost_eq(
				tuning.coin_due_seconds(coin), running_s, EXACT_TOLERANCE, "coin %d drips" % coin
			)
	assert_gt(before_cap, 0, "some coins are due before the cap")
	assert_gt(at_cap, 0, "some coins are due at the cap")


func test_a_cap_of_zero_or_less_means_no_cap() -> void:
	for cap: float in [0.0, -1.0]:
		var tuning: LoopTuning = _curve(FIRST_S, STEADY_COINS, DECAY, FLOOR_S, cap)
		var plain_sum: float = 0.0
		for coin: int in range(1, HUGE_COST + 1):
			plain_sum += tuning.coin_interval(coin)
		assert_almost_eq(
			tuning.build_hold_seconds(HUGE_COST),
			plain_sum,
			EXACT_TOLERANCE,
			"uncapped, cap %s" % cap
		)
		assert_gt(
			plain_sum, CAP_FIXTURE_S, "the uncapped 50-coin hold is longer than the fixture cap"
		)


func test_intervals_never_increase_and_holds_never_shrink() -> void:
	var tuning: LoopTuning = _curve()
	for coin: int in range(2, COINS_CHECKED + 1):
		assert_lte(tuning.coin_interval(coin), tuning.coin_interval(coin - 1), "coin %d" % coin)
		assert_gte(
			tuning.build_hold_seconds(coin),
			tuning.build_hold_seconds(coin - 1),
			"a dearer tier (%d) never holds shorter" % coin
		)


func test_a_zero_first_interval_still_gives_positive_intervals() -> void:
	var tuning: LoopTuning = _curve(0.0)
	for coin: int in range(1, COINS_CHECKED + 1):
		assert_gte(tuning.coin_interval(coin), LoopTuning.MIN_INTERVAL_S, "coin %d" % coin)


func test_a_decay_above_one_never_makes_an_interval_longer_than_the_first() -> void:
	var tuning: LoopTuning = _curve(FIRST_S, STEADY_COINS, 1.5)
	for coin: int in range(1, COINS_CHECKED + 1):
		assert_lte(tuning.coin_interval(coin), FIRST_S + TOLERANCE, "coin %d" % coin)


func test_a_decay_of_zero_drops_straight_to_the_floor() -> void:
	var tuning: LoopTuning = _curve(FIRST_S, STEADY_COINS, 0.0)
	assert_almost_eq(tuning.coin_interval(STEADY_COINS), FIRST_S, TOLERANCE, "steady coins")
	assert_almost_eq(tuning.coin_interval(STEADY_COINS + 1), FLOOR_S, TOLERANCE, "then the floor")


func test_a_floor_above_the_first_interval_gives_a_flat_first_interval() -> void:
	var tuning: LoopTuning = _curve(FIRST_S, STEADY_COINS, DECAY, 2.0)
	for coin: int in range(1, COINS_CHECKED + 1):
		assert_almost_eq(tuning.coin_interval(coin), FIRST_S, TOLERANCE, "coin %d" % coin)


func test_steady_coins_of_zero_or_less_still_give_coin_one_the_first_interval() -> void:
	for steady: int in [0, -3]:
		var tuning: LoopTuning = _curve(FIRST_S, steady)
		assert_almost_eq(tuning.coin_interval(1), FIRST_S, TOLERANCE, "steady %d" % steady)


func test_a_cost_or_coin_index_of_zero_or_less_takes_no_time() -> void:
	var tuning: LoopTuning = _curve()
	assert_eq(tuning.build_hold_seconds(0), 0.0, "cost 0")
	assert_eq(tuning.build_hold_seconds(-3), 0.0, "cost -3")
	assert_eq(tuning.coin_due_seconds(0), 0.0, "coin 0")
