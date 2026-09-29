extends GutTest
## D-12 / ECON-02 on the real scene: at dawn a coin pops out of the plot of each paying House and
## flies to the gold counter, the counter ticks up as they land, and a "+X gold" total follows.
## Amounts come from house.tres and every duration from loop_tuning.tres.

const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const HOUSE := "res://data/buildings/house.tres"
const RICH_GOLD: int = 20
const FAST_NIGHT_S: float = 0.5
const WAIT_SLACK_S: float = 3.0
const EARLY_S: float = 0.5
const SETTLED_S: float = 3.0
const LAND_SLACK_S: float = 0.2
const HOUSE_ONE: StringName = &"house_1"
const HOUSE_TWO: StringName = &"house_2"

var _tuning: LoopTuning


func before_each() -> void:
	_tuning = (load(TUNING) as LoopTuning).duplicate(true)
	_tuning.placeholder_night_seconds = FAST_NIGHT_S


func after_each() -> void:
	E2eSupport.release_all_actions()


func _rich_map() -> MapConfig:
	var map: MapConfig = (load(PROTOTYPE_MAP) as MapConfig).duplicate(true)
	map.starting_gold = RICH_GOLD
	return map


func _hud(map_root: MapRoot) -> Node:
	return map_root.get_node("HUD")


func _gold_text(map_root: MapRoot) -> String:
	return (_hud(map_root).get_node("%GoldLabel") as Label).text


func _payout_total(map_root: MapRoot) -> Label:
	return _hud(map_root).get_node_or_null("%PayoutTotal") as Label


func _vfx(map_root: MapRoot) -> DawnPayoutVfx:
	return _hud(map_root).get_node_or_null("%DawnPayoutVfx") as DawnPayoutVfx


func _coins_launched(vfx: DawnPayoutVfx, expected: int) -> bool:
	return vfx.get_spawned_count(HOUSE_ONE) + vfx.get_spawned_count(HOUSE_TWO) >= expected


func _is_dawn(ctx: RunContext) -> bool:
	return ctx.run_manager.get_phase() == RunManager.RunPhase.DAWN


func _hud_gold_settled(map_root: MapRoot) -> bool:
	var ctx: RunContext = map_root.get_context()
	return _gold_text(map_root) == "Gold: %d" % ctx.economy.get_gold()


func _total_shown(map_root: MapRoot) -> bool:
	var label: Label = _payout_total(map_root)
	return label != null and label.visible


func _total_hidden(map_root: MapRoot) -> bool:
	return not _total_shown(map_root)


## house_1 at tier I and house_2 at tier II, the night started, the scene waiting at the first
## frames of dawn.
func _dawn_with_two_houses() -> MapRoot:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map(), _tuning)
	var ctx: RunContext = map_root.get_context()
	assert_eq(ctx.commands.submit(BuildIntent.new(HOUSE_ONE)), CommandProcessor.OK, "house_1 I")
	assert_eq(ctx.commands.submit(BuildIntent.new(HOUSE_TWO)), CommandProcessor.OK, "house_2 I")
	assert_eq(ctx.commands.submit(BuildIntent.new(HOUSE_TWO)), CommandProcessor.OK, "house_2 II")
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	var reached: bool = await E2eSupport.wait_until(
		self, _is_dawn.bind(ctx), FAST_NIGHT_S + WAIT_SLACK_S
	)
	assert_true(reached, "dawn arrived")
	return map_root


func _expected_amounts() -> Array[int]:
	var house: BuildingDef = load(HOUSE)
	var tier_one: int = house.tiers[0].dawn_income
	var tier_two: int = house.tiers[1].dawn_income
	return [tier_one, tier_two]


func test_coins_are_in_flight_and_the_counter_lags_early_in_dawn() -> void:
	var map_root: MapRoot = await _dawn_with_two_houses()
	var ctx: RunContext = map_root.get_context()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return

	await wait_seconds(EARLY_S * 0.5)

	assert_gte(vfx.live_coin_count(), 1, "at least one coin is in the air")
	var shown: int = _gold_text(map_root).trim_prefix("Gold: ").to_int()
	assert_lt(shown, ctx.economy.get_gold(), "the payout is still landing, HUD lags the ledger")


func test_after_landing_the_hud_settles_on_the_ledger_and_the_total_is_shown() -> void:
	var map_root: MapRoot = await _dawn_with_two_houses()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	var label: Label = _payout_total(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	assert_not_null(label, "the HUD has a PayoutTotal label")
	if vfx == null or label == null:
		return
	var amounts: Array[int] = _expected_amounts()
	var expected_total: int = amounts[0] + amounts[1]

	var shown: bool = await E2eSupport.wait_until(self, _total_shown.bind(map_root), SETTLED_S)

	assert_true(shown, "the total appears once the coins have landed")
	assert_eq(label.text, "+%d gold" % expected_total, "the total is derived from house.tres")
	assert_eq(vfx.get_last_total(), expected_total, "the vfx reports the same total")
	var settled: bool = await E2eSupport.wait_until(
		self, _hud_gold_settled.bind(map_root), SETTLED_S
	)
	assert_true(settled, "the HUD shows exactly the ledger gold once the coins landed")
	assert_eq(vfx.live_coin_count(), 0, "no coin is left in the air")


func test_the_total_fades_after_a_couple_of_seconds() -> void:
	var map_root: MapRoot = await _dawn_with_two_houses()
	var appeared: bool = await E2eSupport.wait_until(self, _total_shown.bind(map_root), SETTLED_S)
	assert_true(appeared, "the total appears")

	var gone: bool = await E2eSupport.wait_until(self, _total_hidden.bind(map_root), SETTLED_S)

	assert_true(gone, "the total is hidden again a moment later")


func test_each_house_spawns_as_many_coins_as_it_pays() -> void:
	var map_root: MapRoot = await _dawn_with_two_houses()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return
	var amounts: Array[int] = _expected_amounts()
	var gold_paid: int = amounts[0] + amounts[1]
	# One coin per gold only holds while the payout fits the coin budget; a rebalance past it
	# should fail here, with a reason, rather than as a wrong coin count below.
	assert_lte(
		gold_paid, DawnPayoutVfx.MAX_COINS, "the payout fits the coin cap: one coin per gold"
	)

	var all_launched: bool = await E2eSupport.wait_until(
		self, _coins_launched.bind(vfx, gold_paid), SETTLED_S
	)

	assert_true(all_launched, "every coin left its plot")
	assert_eq(vfx.get_spawned_count(HOUSE_ONE), amounts[0], "the tier I House sends its income")
	assert_eq(vfx.get_spawned_count(HOUSE_TWO), amounts[1], "the tier II House sends its income")
	assert_eq(vfx.get_spawned_count(&"house_3"), 0, "an unbuilt plot sends nothing")


func test_a_huge_payout_is_capped_in_coins_and_the_readout_never_goes_negative() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map(), _tuning)
	var ctx: RunContext = map_root.get_context()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return
	var per_spot: Dictionary = {HOUSE_ONE: 120, HOUSE_TWO: 83}
	var total: int = 203

	ctx.events.dawn_payout.emit(total, per_spot)
	await wait_process_frames(2)

	assert_eq(
		_gold_text(map_root), "Gold: 0", "the lagging readout is clamped at zero, not negative"
	)
	var settled: bool = await E2eSupport.wait_until(
		self, _hud_gold_settled.bind(map_root), SETTLED_S
	)
	assert_true(settled, "every coin landed and the HUD shows exactly the ledger gold")
	var launched: int = vfx.get_spawned_count(HOUSE_ONE) + vfx.get_spawned_count(HOUSE_TWO)
	assert_lte(launched, DawnPayoutVfx.MAX_COINS, "a big payout is capped in coins")
	assert_gte(vfx.get_spawned_count(HOUSE_ONE), 1, "each paying spot still sends a coin")
	assert_gte(vfx.get_spawned_count(HOUSE_TWO), 1, "each paying spot still sends a coin")
	assert_eq(vfx.get_last_total(), total, "the total shown is the full payout")


func test_the_last_coin_lands_inside_the_dawn_window_however_many_spots_pay() -> void:
	var short_tuning: LoopTuning = _tuning.duplicate(true)
	short_tuning.dawn_seconds = 1.0
	var map_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map(), short_tuning)
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return
	var many_spots_coins: int = 40

	var stagger: float = vfx.launch_stagger(many_spots_coins)

	var last_lands_at: float = float(many_spots_coins - 1) * stagger + DawnPayoutVfx.TRIP_SECONDS
	assert_lte(last_lands_at, short_tuning.dawn_seconds + 0.001, "the flight fits the dawn window")
	assert_lte(stagger, DawnPayoutVfx.STAGGER_SECONDS, "never slower than the default stagger")
	assert_eq(
		vfx.launch_stagger(2), DawnPayoutVfx.STAGGER_SECONDS, "a small payout keeps the default"
	)


func test_a_real_payout_lands_every_coin_inside_a_short_dawn_window() -> void:
	# 12 coins at the default 0.08 s stagger would launch the last one at 0.88 s and land it at
	# 1.48 s, well past a 1.0 s dawn. The tightened stagger must land it inside the window.
	var short_tuning: LoopTuning = _tuning.duplicate(true)
	short_tuning.dawn_seconds = 1.0
	var map_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map(), short_tuning)
	var ctx: RunContext = map_root.get_context()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return
	var per_spot: Dictionary = {HOUSE_ONE: 6, HOUSE_TWO: 6}
	var total: int = 12

	ctx.events.dawn_payout.emit(total, per_spot)
	await wait_seconds(short_tuning.dawn_seconds + LAND_SLACK_S)

	assert_eq(
		vfx.get_spawned_count(HOUSE_ONE) + vfx.get_spawned_count(HOUSE_TWO), total, "12 coins"
	)
	assert_true(_hud_gold_settled(map_root), "every coin landed before the dawn window ended")
	assert_eq(vfx.get_last_total(), total, "the total was shown once the last coin landed")
	assert_eq(vfx.live_coin_count(), 0, "no coin is still in the air")


func test_a_payout_with_no_coin_to_fly_does_not_leave_the_hud_short() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map(), _tuning)
	var ctx: RunContext = map_root.get_context()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return
	var total: int = 5

	ctx.events.dawn_payout.emit(total, {})
	await wait_process_frames(2)

	assert_eq(vfx.live_coin_count(), 0, "no coin flew")
	assert_true(_hud_gold_settled(map_root), "the readout is not held back by gold no coin carries")
	assert_eq(vfx.get_last_total(), total, "the total is still shown")


func test_a_dawn_that_pays_nothing_shows_no_coins_and_no_total() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map(), _tuning)
	var ctx: RunContext = map_root.get_context()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	var reached: bool = await E2eSupport.wait_until(
		self, _is_dawn.bind(ctx), FAST_NIGHT_S + WAIT_SLACK_S
	)
	assert_true(reached, "dawn arrived")

	await wait_seconds(EARLY_S)

	assert_eq(vfx.live_coin_count(), 0, "no coins with no Houses")
	assert_true(_total_hidden(map_root), "no '+0 gold' total is shown")
	assert_eq(vfx.get_last_total(), 0, "nothing was paid")
	assert_true(_hud_gold_settled(map_root), "the HUD shows the ledger gold")


func test_a_payout_naming_an_unknown_spot_still_lands_its_coin_and_settles_the_hud() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map(), _tuning)
	var ctx: RunContext = map_root.get_context()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return
	var total: int = 1

	ctx.events.dawn_payout.emit(total, {&"no_such_spot": total})

	var settled: bool = await E2eSupport.wait_until(
		self, _hud_gold_settled.bind(map_root), SETTLED_S
	)
	assert_true(settled, "the coin still landed, so the readout is not held back for good")
	assert_eq(vfx.get_last_total(), total, "the total was shown")
