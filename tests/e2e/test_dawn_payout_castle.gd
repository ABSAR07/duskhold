extends GutTest
## G-02-1 on the real scene: the castle's base income pays at every dawn, even with no House, and
## its coin flies to the gold counter from the castle (the House coins are test_dawn_payout.gd,
## which is at gdlint's public-method cap).

const TUNING := "res://data/tuning/loop_tuning.tres"
const FAST_NIGHT_S: float = 0.5
const WAIT_SLACK_S: float = 3.0
const SETTLED_S: float = 3.0

var _tuning: LoopTuning


func before_each() -> void:
	_tuning = (load(TUNING) as LoopTuning).duplicate(true)
	_tuning.placeholder_night_seconds = FAST_NIGHT_S


func after_each() -> void:
	E2eSupport.release_all_actions()


func _rich_map() -> MapConfig:
	return E2eSupport.waveless_prototype_map()


func _hud(map_root: MapRoot) -> Node:
	return map_root.get_node("HUD")


func _payout_total(map_root: MapRoot) -> Label:
	return _hud(map_root).get_node_or_null("%PayoutTotal") as Label


func _vfx(map_root: MapRoot) -> DawnPayoutVfx:
	return _hud(map_root).get_node_or_null("%DawnPayoutVfx") as DawnPayoutVfx


func _coins_launched(vfx: DawnPayoutVfx, expected: int) -> bool:
	return vfx.get_spawned_count(MapConfig.CASTLE_PAYOUT_KEY) >= expected


func _is_dawn(ctx: RunContext) -> bool:
	return ctx.run_manager.get_phase() == RunManager.RunPhase.DAWN


func _hud_gold_settled(map_root: MapRoot) -> bool:
	var label: Label = _hud(map_root).get_node("%GoldLabel")
	return label.text == "Gold: %d" % map_root.get_context().economy.get_gold()


func _total_shown(map_root: MapRoot) -> bool:
	var label: Label = _payout_total(map_root)
	return label != null and label.visible


func test_the_base_income_coin_flies_from_the_castle() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map(), _tuning)
	var ctx: RunContext = map_root.get_context()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return
	var camera: Camera3D = vfx.get_viewport().get_camera_3d()
	assert_not_null(camera, "the map has a current camera")
	if camera == null:
		return
	var castle_xz: Vector2 = ctx.castle.get_position()
	var castle_world: Vector3 = Vector3(castle_xz.x, 0.0, castle_xz.y) + DawnPayoutVfx.CASTLE_ANCHOR
	var middle: Vector2 = vfx.get_viewport_rect().size * 0.5
	var base: int = ctx.map.base_dawn_income
	assert_gt(base, 0, "the shipped map pays a base income")

	assert_eq(
		vfx.start_point(MapConfig.CASTLE_PAYOUT_KEY),
		camera.unproject_position(castle_world),
		"the base income's coin starts above the castle on screen"
	)
	assert_ne(vfx.start_point(MapConfig.CASTLE_PAYOUT_KEY), middle, "and not mid-screen")
	assert_eq(vfx.start_point(&"no_such_spot"), middle, "an unknown key still starts mid-screen")

	ctx.events.dawn_payout.emit(base, {MapConfig.CASTLE_PAYOUT_KEY: base})

	var launched: bool = await E2eSupport.wait_until(
		self, _coins_launched.bind(vfx, base), SETTLED_S
	)
	assert_true(launched, "the castle's coin launched")
	assert_eq(vfx.get_spawned_count(MapConfig.CASTLE_PAYOUT_KEY), base, "one coin per gold")
	var settled: bool = await E2eSupport.wait_until(
		self, _hud_gold_settled.bind(map_root), SETTLED_S
	)
	assert_true(settled, "the coin landed and the HUD shows the ledger gold")


func test_a_real_dawn_with_nothing_built_pays_the_base_income_coin() -> void:
	var map: MapConfig = E2eSupport.waveless_prototype_map()
	var map_root: MapRoot = await E2eSupport.spawn_map(self, map, _tuning)
	var ctx: RunContext = map_root.get_context()
	var vfx: DawnPayoutVfx = _vfx(map_root)
	assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
	if vfx == null:
		return
	var base: int = map.base_dawn_income
	var landed: Array[int] = []
	vfx.coin_landed.connect(func(amount: int) -> void: landed.append(amount))
	watch_signals(vfx)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")

	var reached: bool = await E2eSupport.wait_until(
		self, _is_dawn.bind(ctx), FAST_NIGHT_S + WAIT_SLACK_S
	)
	assert_true(reached, "dawn arrived")
	var shown: bool = await E2eSupport.wait_until(self, _total_shown.bind(map_root), SETTLED_S)

	assert_true(shown, "the total appeared once the castle's coin landed")
	assert_signal_emit_count(vfx, "payout_started", 1, "one payout")
	assert_signal_emitted_with_parameters(vfx, "payout_started", [base])
	var landed_sum: int = 0
	for amount: int in landed:
		landed_sum += amount
	assert_eq(landed_sum, base, "the coins that landed carry exactly the base income")
	assert_eq(_payout_total(map_root).text, "+%d gold" % base, "the total shows the base income")
	assert_eq(ctx.economy.get_gold(), map.starting_gold + base, "starting gold plus the base")
	var settled: bool = await E2eSupport.wait_until(
		self, _hud_gold_settled.bind(map_root), SETTLED_S
	)
	assert_true(settled, "the HUD readout settled on the ledger")
	assert_eq(vfx.live_coin_count(), 0, "no coin is left in the air")
