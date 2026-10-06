extends GutTest
## D-12 / ECON-02 on the real scene: at dawn a coin pops out of the plot of each paying House and
## flies to the gold counter, the counter ticks up as they land, and a "+X gold" total follows. The
## castle's base income (G-02-1) adds its own coin from the castle. Amounts come from house.tres
## and the map, every duration from loop_tuning.tres.

const TUNING := "res://data/tuning/loop_tuning.tres"
const HOUSE := "res://data/buildings/house.tres"
const RICH_GOLD: int = 20
const FAST_NIGHT_S: float = 0.5
const WAIT_SLACK_S: float = 3.0
## Ticks the sim this far past the end of the night to be sure it has ended.
const PAST_END_S: float = 0.1
const EARLY_S: float = 0.5
const SETTLED_S: float = 3.0
const HOUSE_ONE: StringName = &"house_1"
const HOUSE_TWO: StringName = &"house_2"

var _tuning: LoopTuning


func before_each() -> void:
	_tuning = (load(TUNING) as LoopTuning).duplicate(true)
	_tuning.placeholder_night_seconds = FAST_NIGHT_S


func after_each() -> void:
	E2eSupport.release_all_actions()


func _rich_map() -> MapConfig:
	var map: MapConfig = E2eSupport.waveless_prototype_map()
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
	var launched: int = (
		vfx.get_spawned_count(HOUSE_ONE)
		+ vfx.get_spawned_count(HOUSE_TWO)
		+ vfx.get_spawned_count(MapConfig.CASTLE_PAYOUT_KEY)
	)
	return launched >= expected


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


## house_1 at tier I and house_2 at tier II, the night just started (no frame has run since).
func _night_with_two_houses() -> MapRoot:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map(), _tuning)
	var ctx: RunContext = map_root.get_context()
	assert_eq(ctx.commands.submit(BuildIntent.new(HOUSE_ONE)), CommandProcessor.OK, "house_1 I")
	assert_eq(ctx.commands.submit(BuildIntent.new(HOUSE_TWO)), CommandProcessor.OK, "house_2 I")
	assert_eq(ctx.commands.submit(BuildIntent.new(HOUSE_TWO)), CommandProcessor.OK, "house_2 II")
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	return map_root


## The same, with the scene waiting at the first frames of dawn.
func _dawn_with_two_houses() -> MapRoot:
	var map_root: MapRoot = await _night_with_two_houses()
	var ctx: RunContext = map_root.get_context()
	var reached: bool = await E2eSupport.wait_until(
		self, _is_dawn.bind(ctx), FAST_NIGHT_S + WAIT_SLACK_S
	)
	assert_true(reached, "dawn arrived")
	return map_root


## The amounts of the two-House dawn: tier I House, tier II House, then the castle's base income.
func _expected_amounts() -> Array[int]:
	var house: BuildingDef = load(HOUSE)
	var tier_one: int = house.tiers[0].dawn_income
	var tier_two: int = house.tiers[1].dawn_income
	return [tier_one, tier_two, _rich_map().base_dawn_income]


func test_coins_are_in_flight_and_the_counter_lags_early_in_dawn() -> void:
	var map_root: MapRoot = await _night_with_two_houses()
	var ctx: RunContext = map_root.get_context()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return

	# The sim is ticked by hand past the night, and nothing awaits afterwards: the first coin
	# launches the instant dawn pays, and no frame or real time passes before the checks below, so
	# a slow runner cannot land it early.
	ctx.run_manager.tick(FAST_NIGHT_S + PAST_END_S)

	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "dawn began")
	assert_gte(vfx.live_coin_count(), 1, "at least one coin is in the air")
	var shown: int = _gold_text(map_root).trim_prefix("Gold: ").to_int()
	assert_lt(shown, ctx.economy.get_gold(), "the payout is still landing, HUD lags the ledger")
	# After the checks: lets the House view that the tier II upgrade replaced finish freeing, so it
	# is not reported as an orphan.
	await wait_process_frames(1)


func test_after_landing_the_hud_settles_on_the_ledger_and_the_total_is_shown() -> void:
	var map_root: MapRoot = await _dawn_with_two_houses()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	var label: Label = _payout_total(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	assert_not_null(label, "the HUD has a PayoutTotal label")
	if vfx == null or label == null:
		return
	var amounts: Array[int] = _expected_amounts()
	var expected_total: int = amounts[0] + amounts[1] + amounts[2]

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
	var gold_paid: int = amounts[0] + amounts[1] + amounts[2]
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
	assert_eq(
		vfx.get_spawned_count(MapConfig.CASTLE_PAYOUT_KEY), amounts[2], "the castle sends its base"
	)
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


func test_a_crowded_payout_tightens_the_stagger_to_fill_the_dawn_window_less_its_margin() -> void:
	var short_tuning: LoopTuning = _tuning.duplicate(true)
	short_tuning.dawn_seconds = 1.0
	var map_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map(), short_tuning)
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return
	var many_spots_coins: int = 40

	var stagger: float = vfx.launch_stagger(many_spots_coins)

	# The expected value comes from the tuning and the gaps between launches, not from stagger.
	var expected: float = (
		(short_tuning.dawn_seconds - DawnPayoutVfx.TRIP_SECONDS - DawnPayoutVfx.DAWN_MARGIN_SECONDS)
		/ float(many_spots_coins - 1)
	)
	assert_almost_eq(
		stagger, expected, 0.0001, "tightened so the last coin lands a margin before dawn ends"
	)
	assert_lt(stagger, DawnPayoutVfx.STAGGER_SECONDS, "and never as slow as the default here")
	assert_eq(
		vfx.launch_stagger(2), DawnPayoutVfx.STAGGER_SECONDS, "a small payout keeps the default"
	)


func test_a_coin_starts_mid_screen_when_its_plot_is_behind_the_camera() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map(), _tuning)
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return
	var camera: Camera3D = vfx.get_viewport().get_camera_3d()
	assert_not_null(camera, "the map has a current camera")
	if camera == null:
		return
	assert_ne(
		vfx.start_point(HOUSE_ONE),
		vfx.get_viewport_rect().size * 0.5,
		"with the camera where it is, the plot has its own screen point"
	)

	# Fly the camera on past the map along its view direction, so every plot is behind it.
	camera.global_position += -camera.global_basis.z * 1000.0

	assert_eq(
		vfx.start_point(HOUSE_ONE),
		vfx.get_viewport_rect().size * 0.5,
		"a plot behind the camera falls back to the middle of the screen, not a mirrored point"
	)


func test_a_real_payout_schedules_its_last_coin_to_land_inside_a_short_dawn_window() -> void:
	# 12 coins at the default 0.08 s stagger would launch the last one at 0.88 s and land it at
	# 1.48 s, well past a 1.0 s dawn. The launch delays the payout really scheduled are compared
	# with the window, so the check is exact and needs no wall-clock timing.
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

	var delays: Array[float] = vfx.get_launch_delays()
	assert_eq(delays.size(), total, "one coin per gold, 12 coins scheduled")
	var stagger: float = vfx.launch_stagger(total)
	assert_lt(stagger, DawnPayoutVfx.STAGGER_SECONDS, "the default stagger is too slow for 1.0 s")
	assert_almost_eq(
		delays[delays.size() - 1],
		float(total - 1) * stagger,
		0.0001,
		"the last coin's launch delay"
	)
	assert_lte(
		delays[delays.size() - 1] + DawnPayoutVfx.TRIP_SECONDS,
		short_tuning.dawn_seconds - DawnPayoutVfx.DAWN_MARGIN_SECONDS + 0.001,
		"the last coin is scheduled to land a margin before the dawn window ends"
	)
	var landed: bool = await E2eSupport.wait_until(
		self, _total_shown.bind(map_root), short_tuning.dawn_seconds + SETTLED_S
	)
	assert_true(landed, "the last coin landed and the total appeared")
	assert_eq(
		vfx.get_spawned_count(HOUSE_ONE) + vfx.get_spawned_count(HOUSE_TWO), total, "12 coins"
	)
	assert_true(_hud_gold_settled(map_root), "every coin landed, so the readout is on the ledger")
	assert_eq(vfx.get_last_total(), total, "the total was shown once the last coin landed")
	assert_eq(vfx.live_coin_count(), 0, "no coin is still in the air")


func test_a_payout_with_no_coin_to_fly_shows_no_total_and_does_not_leave_the_hud_short() -> void:
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
	assert_true(_total_hidden(map_root), "no '+0 gold' total for gold that never flew")
	assert_eq(vfx.get_last_total(), 0, "no total was shown")
	assert_push_warning("dawn payout claims 5 gold but its per-spot amounts carry 0")


func test_a_dawn_that_pays_nothing_shows_no_coins_and_no_total() -> void:
	# With no House the only income is the castle's base, so a dawn that pays nothing needs the base
	# switched off; the real dawn with the base is in test_dawn_payout_castle.gd.
	var no_base_map: MapConfig = _rich_map()
	no_base_map.base_dawn_income = 0
	var map_root: MapRoot = await E2eSupport.spawn_map(self, no_base_map, _tuning)
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


func test_launch_stagger_before_the_run_is_bound_falls_back_to_the_default() -> void:
	var unbound: DawnPayoutVfx = DawnPayoutVfx.new()

	assert_eq(unbound.launch_stagger(40), DawnPayoutVfx.STAGGER_SECONDS, "no dawn window yet")

	unbound.free()


func test_the_label_the_coins_and_the_hud_readout_all_use_the_gold_that_flies() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map(), _tuning)
	var ctx: RunContext = map_root.get_context()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return
	watch_signals(vfx)

	# A negative amount carries no coin, so of the claimed total of 9 only 4 gold ever flies.
	ctx.events.dawn_payout.emit(9, {HOUSE_ONE: 4, HOUSE_TWO: -2})

	assert_signal_emitted_with_parameters(vfx, "payout_started", [4])
	assert_push_warning("dawn payout claims 9 gold but its per-spot amounts carry 4")
	assert_eq(_gold_text(map_root), "Gold: %d" % (RICH_GOLD - 4), "held back by the coins' 4 gold")
	var shown: bool = await E2eSupport.wait_until(self, _total_shown.bind(map_root), SETTLED_S)
	assert_true(shown, "the coins landed and the total appeared")
	assert_eq(
		_payout_total(map_root).text, "+4 gold", "the label shows the 4 gold that flew, not 9"
	)
	assert_eq(vfx.get_last_total(), 4, "and so does the vfx")
	assert_true(_hud_gold_settled(map_root), "those coins released exactly what was held")


func test_a_malformed_payout_entry_does_not_abort_the_payout() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map(), _tuning)
	var ctx: RunContext = map_root.get_context()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return
	watch_signals(vfx)

	# house_1's 4.0 is a whole float, house_2's null is no amount at all, house_3's NAN is not a
	# finite one, and the int key 7 is no spot name.
	ctx.events.dawn_payout.emit(4, {HOUSE_ONE: 4.0, HOUSE_TWO: null, &"house_3": NAN, 7: 3})

	assert_signal_emitted_with_parameters(vfx, "payout_started", [4])
	assert_push_warning("dawn payout for 'house_2' ignored")
	assert_push_warning("dawn payout for 'house_3' ignored")
	assert_push_warning("dawn payout for '7' ignored: its spot id is a int")
	var launched: bool = await E2eSupport.wait_until(self, _coins_launched.bind(vfx, 4), SETTLED_S)
	assert_true(launched, "the float amount still sends its 4 coins")
	assert_eq(vfx.get_spawned_count(HOUSE_ONE), 4, "all of them from house_1")
	assert_eq(vfx.get_spawned_count(HOUSE_TWO), 0, "the null amount sends none")
	assert_eq(vfx.get_spawned_count(&"house_3"), 0, "the NAN amount sends none")
	var settled: bool = await E2eSupport.wait_until(
		self, _hud_gold_settled.bind(map_root), SETTLED_S
	)
	assert_true(settled, "the coins that did fly landed and released what was held")


func test_a_new_payout_stops_the_pending_launches_of_the_one_it_supersedes() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map(), _tuning)
	var ctx: RunContext = map_root.get_context()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return
	ctx.events.dawn_payout.emit(12, {HOUSE_ONE: 6, HOUSE_TWO: 6})
	var waiting: Array[Tween] = vfx.get_launch_tweens()
	assert_gt(waiting.size(), 0, "the staggered coins wait on their launch delays")
	for tween: Tween in waiting:
		assert_true(tween.is_valid(), "and each delay is still running")

	ctx.events.dawn_payout.emit(0, {})

	for tween: Tween in waiting:
		assert_false(tween.is_valid(), "the superseded payout's launch delay was killed")
	assert_eq(vfx.get_launch_tweens().size(), 0, "and none is left on the books")


func test_the_hud_releases_a_held_back_readout_when_dawn_ends() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map(), _tuning)
	var ctx: RunContext = map_root.get_context()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	ctx.run_manager.tick(FAST_NIGHT_S + PAST_END_S)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "a real dawn began")
	# A payout whose coins will never land (the vfx was freed, a tween was killed).
	vfx.payout_started.emit(7)
	assert_false(_hud_gold_settled(map_root), "the readout is held back")

	# The dawn really ends, so every other listener on the bus sees a genuine transition.
	ctx.run_manager.tick(_tuning.dawn_seconds)

	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAY, "the day returned")
	assert_true(_hud_gold_settled(map_root), "dawn ending puts the readout back on the ledger")


func test_the_coin_cap_follows_the_gold_that_flies_not_the_claimed_total() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map(), _tuning)
	var ctx: RunContext = map_root.get_context()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return
	# The claimed total (5) is under the cap but the parts (120 gold) are far over it.
	ctx.events.dawn_payout.emit(5, {HOUSE_ONE: 60, HOUSE_TWO: 60})

	var shown: bool = await E2eSupport.wait_until(self, _total_shown.bind(map_root), SETTLED_S)

	assert_true(shown, "every coin landed")
	assert_push_warning("dawn payout claims 5 gold but its per-spot amounts carry 120")
	assert_eq(_payout_total(map_root).text, "+120 gold", "the label shows the gold that flew")
	var launched: int = vfx.get_spawned_count(HOUSE_ONE) + vfx.get_spawned_count(HOUSE_TWO)
	assert_lte(launched, DawnPayoutVfx.MAX_COINS, "the cap holds for the gold that actually flies")


func test_a_dawn_no_longer_than_one_coin_trip_warns_when_the_payout_view_binds() -> void:
	var too_short: LoopTuning = _tuning.duplicate(true)
	too_short.dawn_seconds = DawnPayoutVfx.TRIP_SECONDS

	await E2eSupport.spawn_map(self, _rich_map(), too_short)

	assert_push_warning("dawn_seconds")
