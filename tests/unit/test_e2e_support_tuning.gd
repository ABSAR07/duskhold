extends GutTest
## The slow-drip fixtures of the scene tests build their tuning with E2eSupport.flat_drip_tuning,
## so retuning the shipped acceleration or any cap a later retune might set (D-05 as amended, UAT
## G-01-58 and G-01-59) cannot change what those tests observe. This pins the helper: flat,
## uncapped, otherwise shipped, and a copy.

const SHIPPED_PATH := "res://data/tuning/loop_tuning.tres"
const PACE_S: float = 1.0
const COINS_CHECKED: int = 40
const COST_CHECKED: int = 10


func test_every_coin_takes_the_same_interval() -> void:
	var tuning: LoopTuning = E2eSupport.flat_drip_tuning(PACE_S)
	for coin: int in range(1, COINS_CHECKED + 1):
		assert_almost_eq(tuning.coin_interval(coin), PACE_S, 0.0001, "coin %d is flat" % coin)


func test_a_long_hold_is_not_capped() -> void:
	var tuning: LoopTuning = E2eSupport.flat_drip_tuning(PACE_S)
	assert_almost_eq(
		tuning.build_hold_seconds(COST_CHECKED), PACE_S * COST_CHECKED, 0.0001, "ten coins, ten s"
	)


func test_every_other_field_is_the_shipped_value() -> void:
	var shipped: LoopTuning = load(SHIPPED_PATH)
	var tuning: LoopTuning = E2eSupport.flat_drip_tuning(PACE_S)
	assert_eq(tuning.interaction_radius, shipped.interaction_radius, "interaction_radius")
	assert_eq(
		tuning.start_night_hold_seconds,
		shipped.start_night_hold_seconds,
		"start_night_hold_seconds"
	)
	assert_eq(tuning.placeholder_night_seconds, shipped.placeholder_night_seconds, "night seconds")
	assert_eq(tuning.dawn_seconds, shipped.dawn_seconds, "dawn_seconds")
	assert_eq(tuning.coin_drip_steady_coins, shipped.coin_drip_steady_coins, "steady coins")
	assert_eq(tuning.coin_drip_min_interval, shipped.coin_drip_min_interval, "min interval")


func test_the_helper_hands_out_a_copy_and_leaves_the_shipped_tuning_alone() -> void:
	var shipped: LoopTuning = load(SHIPPED_PATH)
	var decay_before: float = shipped.coin_drip_decay
	var cap_before: float = shipped.max_build_hold_seconds
	var interval_before: float = shipped.coin_drip_interval
	var tuning: LoopTuning = E2eSupport.flat_drip_tuning(PACE_S)
	assert_ne(tuning, shipped, "not the cached shipped resource")
	assert_eq(shipped.coin_drip_decay, decay_before, "shipped decay untouched")
	assert_eq(shipped.max_build_hold_seconds, cap_before, "shipped cap untouched")
	assert_eq(shipped.coin_drip_interval, interval_before, "shipped first interval untouched")
	assert_lt(shipped.coin_drip_decay, 1.0, "the shipped hold still accelerates")
	assert_ne(shipped.coin_drip_interval, PACE_S, "the helper's pace differs, so a write shows")
