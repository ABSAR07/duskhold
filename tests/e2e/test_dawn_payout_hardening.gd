extends GutTest
## Malformed and edge-case dawn payouts on the real scene (the happy path is test_dawn_payout.gd,
## which is at gdlint's public-method cap): a payout must never hang or corrupt the HUD readout.

const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const RICH_GOLD: int = 20
const SETTLED_S: float = 3.0
const HOUSE_ONE: StringName = &"house_1"
const HOUSE_TWO: StringName = &"house_2"

var _tuning: LoopTuning


func before_each() -> void:
	_tuning = (load(TUNING) as LoopTuning).duplicate(true)


func _spawn() -> MapRoot:
	var map: MapConfig = (load(PROTOTYPE_MAP) as MapConfig).duplicate(true)
	map.starting_gold = RICH_GOLD
	return await E2eSupport.spawn_map(self, map, _tuning)


func _vfx(map_root: MapRoot) -> DawnPayoutVfx:
	return map_root.get_node("HUD").get_node_or_null("%DawnPayoutVfx") as DawnPayoutVfx


func _hud_gold_settled(map_root: MapRoot) -> bool:
	var label: Label = map_root.get_node("HUD").get_node("%GoldLabel")
	return label.text == "Gold: %d" % map_root.get_context().economy.get_gold()


func _total_shown(map_root: MapRoot) -> bool:
	var label: Label = map_root.get_node("HUD").get_node_or_null("%PayoutTotal") as Label
	return label != null and label.visible


func test_launch_tweens_that_have_fired_are_no_longer_reported_as_waiting() -> void:
	var map_root: MapRoot = await _spawn()
	var ctx: RunContext = map_root.get_context()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return
	ctx.events.dawn_payout.emit(12, {HOUSE_ONE: 6, HOUSE_TWO: 6})
	assert_gt(vfx.get_launch_tweens().size(), 0, "the staggered coins wait on their delays")

	var landed: bool = await E2eSupport.wait_until(self, _total_shown.bind(map_root), SETTLED_S)

	assert_true(landed, "every coin launched and landed")
	assert_eq(vfx.get_launch_tweens().size(), 0, "no launch is waiting once every coin left")


func test_a_payout_with_no_coins_does_not_report_the_previous_payouts_total() -> void:
	var map_root: MapRoot = await _spawn()
	var ctx: RunContext = map_root.get_context()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return
	ctx.events.dawn_payout.emit(3, {HOUSE_ONE: 3})
	var landed: bool = await E2eSupport.wait_until(self, _total_shown.bind(map_root), SETTLED_S)
	assert_true(landed, "the first payout landed")
	assert_eq(vfx.get_last_total(), 3, "and its total was shown")

	ctx.events.dawn_payout.emit(0, {})

	assert_eq(vfx.get_last_total(), 0, "the next payout, with nothing to show, starts from 0")


func test_absurdly_large_amounts_are_clamped_so_the_coin_cap_still_holds() -> void:
	var map_root: MapRoot = await _spawn()
	var ctx: RunContext = map_root.get_context()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return
	watch_signals(vfx)
	var clamped_total: int = 2 * DawnPayoutVfx.MAX_AMOUNT

	# A float far past int range and an int near its top: unclamped, neither is a usable amount.
	ctx.events.dawn_payout.emit(
		clamped_total, {HOUSE_ONE: 1e30, HOUSE_TWO: 9_000_000_000_000_000_000}
	)

	assert_signal_emitted_with_parameters(vfx, "payout_started", [clamped_total])
	assert_lte(vfx.get_launch_delays().size(), DawnPayoutVfx.MAX_COINS, "the coin cap holds")
	var settled: bool = await E2eSupport.wait_until(
		self, _hud_gold_settled.bind(map_root), SETTLED_S
	)
	assert_true(settled, "every coin landed and the HUD shows exactly the ledger gold")
	assert_gte(vfx.get_spawned_count(HOUSE_ONE), 1, "each paying spot still sends a coin")
	assert_gte(vfx.get_spawned_count(HOUSE_TWO), 1, "each paying spot still sends a coin")


func test_start_point_before_the_run_is_bound_falls_back_to_mid_screen() -> void:
	# Only the two labels the payout view looks up by unique name; no run is ever bound.
	var vfx: DawnPayoutVfx = DawnPayoutVfx.new()
	for label_name: String in ["GoldLabel", "PayoutTotal"]:
		var label: Label = Label.new()
		label.name = label_name
		vfx.add_child(label)
		label.owner = vfx
		label.unique_name_in_owner = true
	add_child_autofree(vfx)

	var point: Vector2 = vfx.start_point(HOUSE_ONE)

	assert_eq(point, vfx.get_viewport_rect().size * 0.5, "no run yet, so the middle of the screen")


func test_a_child_that_is_not_a_coin_is_neither_counted_nor_freed_by_a_payout() -> void:
	var map_root: MapRoot = await _spawn()
	var ctx: RunContext = map_root.get_context()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return
	var marker: Control = Control.new()
	vfx.add_child(marker)
	assert_eq(vfx.live_coin_count(), 0, "a non-coin child is not a coin in the air")

	ctx.events.dawn_payout.emit(6, {HOUSE_ONE: 3, HOUSE_TWO: 3})
	ctx.events.dawn_payout.emit(3, {HOUSE_ONE: 3})

	assert_false(marker.is_queued_for_deletion(), "a new payout does not free a non-coin child")
	var landed: bool = await E2eSupport.wait_until(self, _total_shown.bind(map_root), SETTLED_S)
	assert_true(landed, "the last payout landed")
	assert_true(is_instance_valid(marker), "and the child is still there")
	assert_eq(vfx.live_coin_count(), 0, "with every coin gone, none is counted")


func test_a_payout_of_only_negative_amounts_shows_nothing_and_leaves_the_hud_on_the_ledger(
) -> void:
	var map_root: MapRoot = await _spawn()
	var ctx: RunContext = map_root.get_context()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return
	watch_signals(vfx)

	# The Economy was credited the claimed 5, but no per-spot amount can carry a coin.
	ctx.events.dawn_payout.emit(5, {HOUSE_ONE: -3})
	await wait_process_frames(2)

	assert_signal_emitted_with_parameters(vfx, "payout_started", [0])
	assert_push_warning("dawn payout claims 5 gold but its per-spot amounts carry 0")
	assert_eq(vfx.live_coin_count(), 0, "no coin flew")
	assert_eq(vfx.get_last_total(), 0, "no total was shown")
	assert_false(_total_shown(map_root), "and no '+X gold' label appeared")
	assert_true(_hud_gold_settled(map_root), "the readout is not held back by gold no coin carries")


func test_a_payout_claiming_no_gold_but_listing_amounts_is_reported_and_shows_nothing() -> void:
	var map_root: MapRoot = await _spawn()
	var ctx: RunContext = map_root.get_context()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return
	watch_signals(vfx)

	ctx.events.dawn_payout.emit(0, {HOUSE_ONE: 3})
	await wait_process_frames(2)

	assert_push_warning("dawn payout claims 0 gold but lists per-spot amounts")
	assert_push_warning_count(1, "one warning for the disagreement")
	assert_signal_emitted_with_parameters(vfx, "payout_started", [0])
	assert_eq(vfx.live_coin_count(), 0, "the listed amount sends no coin")
	assert_false(_total_shown(map_root), "and no '+X gold' label appears")
	assert_true(_hud_gold_settled(map_root), "the readout stays on the ledger")
