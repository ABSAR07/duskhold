extends GutTest
## LOOP-05, D-14 on the real scene: the crossed-out coin hangs over every rebuilt building that
## pays income, whatever its curve. A Gold Mine that fell in the night and was rebuilt at dawn wears
## the mark (it pays nothing that morning and makes no progress), a House rebuilt the same dawn
## wears one too, and a wall plot never does. The marker asks the building (pays_income), not the
## raw dawn_income field, so a curve that pays nothing at its tier is not marked. The marks fade
## when the day starts. The scene runs on the waveless prototype map with a short night, so the
## test controls what falls.

const MINE: StringName = &"gold_mine_1"
const HOUSE: StringName = &"house_1"
const TOWER: StringName = &"tower_1"
const WALL: StringName = &"wall_ring"
const RICH_GOLD: int = 100
const FAST_NIGHT_S: float = 0.5
## Longer than one coin trip, so the payout vfx does not warn that its coins cannot land.
const DAWN_S: float = 1.0
const SETTLE_FRAMES: int = 3
const PHASE_TIMEOUT_S: float = 12.0
const FADE_TIMEOUT_S: float = 2.0

var _root: MapRoot
var _ctx: RunContext
var _map: MapConfig
var _tuning: LoopTuning


func before_each() -> void:
	_map = E2eSupport.waveless_prototype_map()
	_map.starting_gold = RICH_GOLD
	_tuning = (load(E2eSupport.TUNING_PATH) as LoopTuning).duplicate(true)
	_tuning.placeholder_night_seconds = FAST_NIGHT_S
	_tuning.dawn_seconds = DAWN_S


## Instantiates the real scene on the test's map copy; a test that edits `_map` does so first.
func _start() -> void:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	_root = scene.instantiate()
	_root.map_config = _map
	_root.loop_tuning = _tuning
	_root.fixed_run_seed = 1
	_root.handle_results_actions = false
	add_child_autofree(_root)
	await wait_process_frames(SETTLE_FRAMES)
	_ctx = _root.get_context()


func after_each() -> void:
	E2eSupport.release_all_actions()


func _marker() -> DawnNoIncomeMarker:
	return _root.get_node("HUD").get_node_or_null("%DawnNoIncomeMarker") as DawnNoIncomeMarker


func _in_phase(phase: RunManager.RunPhase) -> bool:
	return _ctx.run_manager.get_phase() == phase


## Builds `built` to tier I, starts the night and takes the `fallen` spots down in it.
func _night(built: Array[StringName], fallen: Array[StringName]) -> void:
	for spot_id: StringName in built:
		assert_eq(_ctx.commands.submit(BuildIntent.new(spot_id)), CommandProcessor.OK, "built")
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	for spot_id: StringName in fallen:
		_ctx.buildings.damage_building(spot_id, _ctx.buildings.max_health_of(spot_id))
		assert_true(_ctx.buildings.is_destroyed(spot_id), "%s fell" % spot_id)


func _to_dawn() -> bool:
	return await E2eSupport.wait_until(
		self, _in_phase.bind(RunManager.RunPhase.DAWN), PHASE_TIMEOUT_S
	)


func test_a_rebuilt_mine_wears_the_crossed_coin_and_it_fades_at_day_start() -> void:
	await _start()
	await _night([MINE], [MINE])
	var marker: DawnNoIncomeMarker = _marker()
	assert_not_null(marker, "the HUD has a DawnNoIncomeMarker")
	if marker == null:
		return
	assert_eq(marker.marker_count(), 0, "no mark while the night is on")
	watch_signals(_ctx.events)

	assert_true(await _to_dawn(), "dawn")

	assert_eq(marker.marked_spots(), [MINE] as Array[StringName], "the Mine is marked")
	var per_spot: Dictionary = (get_signal_parameters(_ctx.events, "dawn_payout", 0) as Array)[1]
	assert_false(per_spot.has(MINE), "and it really pays nothing this morning")
	assert_eq(_ctx.income.mine_paid_dawns(MINE), 0, "with no progress made")
	var gone: Callable = func() -> bool: return marker.marker_count() == 0
	assert_true(await E2eSupport.wait_until(self, gone, DAWN_S + FADE_TIMEOUT_S), "the mark fades")


func test_a_house_rebuilt_the_same_dawn_is_marked_with_the_mine_in_map_order() -> void:
	await _start()
	await _night([HOUSE, MINE], [HOUSE, MINE])
	var marker: DawnNoIncomeMarker = _marker()
	if marker == null:
		fail_test("the HUD has a DawnNoIncomeMarker")
		return

	assert_true(await _to_dawn(), "dawn")

	assert_eq(marker.marked_spots(), [HOUSE, MINE] as Array[StringName], "both, in map order")


func test_a_standing_mine_gets_no_mark_and_pays_its_coins() -> void:
	await _start()
	await _night([HOUSE, MINE], [HOUSE])
	var marker: DawnNoIncomeMarker = _marker()
	if marker == null:
		fail_test("the HUD has a DawnNoIncomeMarker")
		return
	watch_signals(_ctx.events)

	assert_true(await _to_dawn(), "dawn")

	assert_eq(marker.marked_spots(), [HOUSE] as Array[StringName], "only the rebuilt House")
	var per_spot: Dictionary = (get_signal_parameters(_ctx.events, "dawn_payout", 0) as Array)[1]
	assert_true(per_spot.has(MINE), "the Mine that stood was paid")


func test_a_wall_plot_and_a_tower_are_never_marked() -> void:
	await _start()
	await _night([WALL, TOWER, MINE], [WALL, TOWER, MINE])
	var marker: DawnNoIncomeMarker = _marker()
	if marker == null:
		fail_test("the HUD has a DawnNoIncomeMarker")
		return

	assert_true(await _to_dawn(), "dawn")

	assert_eq(marker.marked_spots(), [MINE] as Array[StringName], "only the paying Mine")


func test_the_marker_asks_the_building_not_the_raw_income_field() -> void:
	for building_def: BuildingDef in _map.buildings:
		if building_def.id == &"gold_mine":
			# A BOATS building pays per boat, which the Harbor's own plan adds: until then it pays
			# nothing at its tier, whatever dawn_income says, so a rebuilt one is not marked.
			building_def.income_curve = BuildingDef.IncomeCurve.BOATS
	await _start()
	await _night([MINE, HOUSE], [MINE, HOUSE])
	var marker: DawnNoIncomeMarker = _marker()
	if marker == null:
		fail_test("the HUD has a DawnNoIncomeMarker")
		return

	assert_true(await _to_dawn(), "dawn")

	assert_eq(marker.marked_spots(), [HOUSE] as Array[StringName], "the House only")
