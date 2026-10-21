extends GutTest
## ECON-06, D-14 on the real scene: how the Shrine looks. Its model has a Glow orb that is hidden
## until the Shrine wakes (BuildingViews.is_shrine_glowing), a rebuilt awake Shrine glows again, the
## plot disc has a colour of its own, a Shrine bolt flies violet while a tower arrow stays gold
## (ProjectileVfx), and the crossed coin hangs over a rebuilt Shrine whether it is awake or asleep
## (the marker asks BuildingDef.pays_income, with no awake check). The scene runs on the waveless
## prototype map with a short night, so the test controls what falls and what wakes.

const WEST: StringName = &"shrine_west"
const TOWER: StringName = &"tower_1"
const GRUNT: StringName = &"grunt"
const RICH_GOLD: int = 100
const FAST_NIGHT_S: float = 0.5
## Longer than one coin trip, so the payout vfx does not warn that its coins cannot land.
const DAWN_S: float = 1.0
const SETTLE_FRAMES: int = 3
const PHASE_TIMEOUT_S: float = 12.0
const FLIGHT_TICKS: int = 30
const PUPPET_AT := Vector2(5.0, 5.0)
const COLOR_EPSILON: float = 0.001

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


func _views() -> BuildingViews:
	return _root.get_node("BuildingViews") as BuildingViews


func _marker() -> DawnNoIncomeMarker:
	return _root.get_node("HUD").get_node_or_null("%DawnNoIncomeMarker") as DawnNoIncomeMarker


func _build(spot_id: StringName) -> void:
	assert_eq(_ctx.commands.submit(BuildIntent.new(spot_id)), CommandProcessor.OK, "built")


func _plot() -> Vector2:
	var at: Vector3 = _ctx.buildings.get_spot(WEST).position
	return Vector2(at.x, at.z)


func _wake() -> void:
	var tier: BuildingTierDef = _ctx.buildings.get_building_def_for_spot(WEST).tier_def(1)
	var hp: int = _ctx.map.find_enemy(GRUNT).max_health
	for death: int in range(ceili(float(tier.wake_threshold_hp) / float(hp))):
		_ctx.events.enemy_died.emit(death, GRUNT, _plot(), &"tower")
	assert_true(_ctx.income.is_awake(WEST), "awake")


func _in_phase(phase: RunManager.RunPhase) -> bool:
	return _ctx.run_manager.get_phase() == phase


func _to_dawn() -> bool:
	return await E2eSupport.wait_until(
		self, _in_phase.bind(RunManager.RunPhase.DAWN), PHASE_TIMEOUT_S
	)


func _assert_color(actual: Color, expected: Color, label: String) -> void:
	assert_almost_eq(actual.r, expected.r, COLOR_EPSILON, "%s r" % label)
	assert_almost_eq(actual.g, expected.g, COLOR_EPSILON, "%s g" % label)
	assert_almost_eq(actual.b, expected.b, COLOR_EPSILON, "%s b" % label)


func test_the_model_has_a_glow_that_is_hidden_until_the_shrine_wakes() -> void:
	_build(WEST)
	await wait_process_frames(1)
	var view: Node3D = _views().get_view(WEST)
	assert_not_null(view.get_node_or_null("Glow"), "the Shrine model carries a Glow child")
	assert_false(_views().is_shrine_glowing(WEST), "asleep: no glow")
	_wake()
	assert_true(_views().is_shrine_glowing(WEST), "awake: it glows")


func test_a_shrine_that_is_already_awake_when_its_view_appears_glows() -> void:
	_build(WEST)
	_wake()
	assert_true(_views().is_shrine_glowing(WEST), "the glow follows shrine_woke")
	_ctx.buildings.damage_building(WEST, _ctx.buildings.max_health_of(WEST))
	assert_false(_views().is_shrine_glowing(WEST), "rubble does not glow")
	var rebuilt: Array[StringName] = _ctx.buildings.rebuild_destroyed()
	_ctx.events.buildings_rebuilt.emit(rebuilt)
	assert_true(_views().is_shrine_glowing(WEST), "the rebuilt, still awake Shrine glows again")


func test_a_glow_query_on_other_plots_is_false() -> void:
	_build(TOWER)
	assert_false(_views().is_shrine_glowing(TOWER), "a tower never glows")
	assert_false(_views().is_shrine_glowing(&"nowhere"), "an unknown plot never glows")
	assert_false(_views().is_shrine_glowing(&"shrine_east"), "an empty Shrine plot never glows")


func test_the_shrine_plot_disc_has_a_colour_of_its_own() -> void:
	var disc: MeshInstance3D = _views().get_node("Spot_%s" % WEST) as MeshInstance3D
	var tower_disc: MeshInstance3D = _views().get_node("Spot_%s" % TOWER) as MeshInstance3D
	var colour: Color = (disc.mesh.material as StandardMaterial3D).albedo_color
	assert_eq(colour, BuildingViews.SHRINE_MARKER_COLOR, "the Shrine colour")
	assert_ne(colour, BuildingViews.HOUSE_MARKER_COLOR, "not the House tan")
	assert_ne(
		colour, (tower_disc.mesh.material as StandardMaterial3D).albedo_color, "nor the tower"
	)


func test_a_shrine_bolt_flies_violet_and_a_tower_arrow_stays_gold() -> void:
	_build(WEST)
	_build(TOWER)
	var vfx: ProjectileVfx = _root.get_node("ProjectileVfx") as ProjectileVfx
	var id: int = _ctx.night.get_enemies().spawn(_ctx.map.find_enemy(GRUNT), PUPPET_AT)
	_ctx.events.attack_fired.emit(
		&"building", _ctx.buildings.spot_index(WEST), &"enemy", id, FLIGHT_TICKS
	)
	await wait_process_frames(1)
	assert_eq(vfx.arrow_count(), 1, "one bolt drawn")
	_assert_color(vfx.arrow_color_at(0), ProjectileVfx.SHRINE_COLOR, "a Shrine bolt is violet")
	_ctx.events.attack_fired.emit(
		&"building", _ctx.buildings.spot_index(TOWER), &"enemy", id, FLIGHT_TICKS
	)
	await wait_process_frames(1)
	assert_eq(vfx.arrow_count(), 2, "and the tower's arrow beside it")
	_assert_color(vfx.arrow_color_at(1), ProjectileVfx.TOWER_COLOR, "a tower arrow stays gold")


func test_a_rebuilt_dormant_shrine_wears_the_crossed_coin() -> void:
	_build(WEST)
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night")
	_ctx.buildings.damage_building(WEST, _ctx.buildings.max_health_of(WEST))
	assert_true(await _to_dawn(), "dawn")
	assert_false(_ctx.income.is_awake(WEST), "it never woke")
	assert_eq(_marker().marked_spots(), [WEST] as Array[StringName], "yet it is marked")


func test_a_rebuilt_awake_shrine_wears_the_crossed_coin_and_pays_nothing() -> void:
	_build(WEST)
	_wake()
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night")
	_ctx.buildings.damage_building(WEST, _ctx.buildings.max_health_of(WEST))
	watch_signals(_ctx.events)
	assert_true(await _to_dawn(), "dawn")
	assert_eq(_marker().marked_spots(), [WEST] as Array[StringName], "marked")
	var per_spot: Dictionary = (get_signal_parameters(_ctx.events, "dawn_payout", 0) as Array)[1]
	assert_false(per_spot.has(WEST), "and it paid nothing that morning")
	assert_true(_ctx.income.is_awake(WEST), "still awake")
