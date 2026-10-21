extends GutTest
## ECON-05, D-11 on the real prototype scene (the tracer of plan 05-08): the pond is drawn by
## PondView with no collision, the king builds the Fishing Harbor on its shore by holding, no boat
## floats until its first dawn, and across two nights one boat arrives at each dawn and pays through
## the one dawn_payout. The Harbor's numbers are set on a deep copy of the map (cap 3, one gold per
## boat), so the plan 05-11 fit cannot break the test.

const HARBOR: StringName = &"harbor_1"
const HARBOR_VIEW_FILE := "fishing_harbor_t1.tscn"
const POND_CENTER := Vector2(0.0, 30.0)
const POND_RADIUS: float = 8.0
const CAP: int = 3
const BOAT_GOLD: int = 1
const RICH_GOLD: int = 30
const FAST_NIGHT_S: float = 0.5
## Longer than one coin trip, so the payout vfx does not warn that its coins cannot land.
const DAWN_S: float = 1.0
const SETTLE_FRAMES: int = 3
const HOLD_SLACK_S: float = 1.5
const PHASE_TIMEOUT_S: float = 12.0

var _root: MapRoot
var _ctx: RunContext
var _pond: PondView


func before_each() -> void:
	var map: MapConfig = E2eSupport.waveless_prototype_map()
	map.starting_gold = RICH_GOLD
	for building_def: BuildingDef in map.buildings:
		if building_def.id == &"fishing_harbor":
			var tier: BuildingTierDef = building_def.tier_def(1)
			tier.boat_cap = CAP
			tier.boat_income = BOAT_GOLD
	var tuning: LoopTuning = (load(E2eSupport.TUNING_PATH) as LoopTuning).duplicate(true)
	tuning.placeholder_night_seconds = FAST_NIGHT_S
	tuning.dawn_seconds = DAWN_S
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	_root = scene.instantiate()
	_root.map_config = map
	_root.loop_tuning = tuning
	_root.fixed_run_seed = 1
	_root.handle_results_actions = false
	add_child_autofree(_root)
	await wait_process_frames(SETTLE_FRAMES)
	_ctx = _root.get_context()
	_pond = _root.get_node("PondView") as PondView


func after_each() -> void:
	E2eSupport.release_all_actions()


func _harbor_tier() -> BuildingTierDef:
	return _ctx.buildings.get_building_def_for_spot(HARBOR).tier_def(1)


## Presses and holds the action key until the Harbor stands, then lets go.
func _hold_until_built() -> bool:
	var seconds: float = _ctx.tuning.build_hold_seconds(_harbor_tier().cost) + HOLD_SLACK_S
	Input.action_press(&"action_build")
	var built: Callable = func() -> bool: return _ctx.buildings.current_tier(HARBOR) == 1
	var got: bool = await E2eSupport.wait_until(self, built, seconds)
	Input.action_release(&"action_build")
	await wait_process_frames(2)
	return got


func _in_phase(phase: RunManager.RunPhase) -> bool:
	return _ctx.run_manager.get_phase() == phase


func _wait_phase(phase: RunManager.RunPhase) -> bool:
	return await E2eSupport.wait_until(self, _in_phase.bind(phase), PHASE_TIMEOUT_S)


## The nth dawn_payout emission as [total, per_spot].
func _payout(emission: int) -> Array:
	return get_signal_parameters(_ctx.events, "dawn_payout", emission)


func _water() -> MeshInstance3D:
	return _pond.find_child("Water", true, false) as MeshInstance3D


func _collision_nodes() -> Array[Node]:
	var found: Array[Node] = []
	for node: Node in _pond.find_children("*", "", true, false):
		if node is CollisionObject3D or node is CollisionShape3D:
			found.append(node)
	return found


func test_the_pond_is_a_water_disc_at_the_map_pond_with_no_collision() -> void:
	assert_not_null(_pond, "the scene has a PondView")
	assert_true(_pond.has_pond(), "the map names a pond")
	assert_eq(_pond.water_center(), POND_CENTER, "centred at (0, 30)")
	assert_eq(_pond.water_radius(), POND_RADIUS, "radius 8")
	var water: MeshInstance3D = _water()
	assert_not_null(water, "a water disc is drawn")
	var disc: CylinderMesh = water.mesh as CylinderMesh
	assert_not_null(disc, "it is a flat cylinder")
	assert_eq(disc.top_radius, POND_RADIUS, "of the pond's radius")
	assert_lt(disc.height, 0.1, "and flat")
	assert_eq(water.position.x, POND_CENTER.x, "at the pond centre x")
	assert_eq(water.position.z, POND_CENTER.y, "and z")
	assert_gt(water.position.y, 0.0, "a little above the ground")
	assert_eq(_collision_nodes().size(), 0, "nothing in the pond can block anyone")


func test_the_king_builds_the_harbor_and_no_boat_floats_until_the_first_dawn() -> void:
	assert_true(await E2eSupport.stand_at_spot(self, _root, HARBOR), "the king reached the plot")
	var gold: int = _ctx.economy.get_gold()
	assert_true(await _hold_until_built(), "a full hold built the Harbor")
	assert_eq(_ctx.buildings.current_tier(HARBOR), 1, "tier I stands")
	assert_eq(_ctx.economy.get_gold(), gold - _harbor_tier().cost, "for its price")
	var view: Node3D = (_root.get_node("BuildingViews") as BuildingViews).get_view(HARBOR)
	assert_not_null(view, "the plot has a view")
	assert_true(
		str(view.get_meta(&"view_source", "")).ends_with(HARBOR_VIEW_FILE),
		"it is the Harbor's model"
	)
	assert_eq(_ctx.income.boats_of(HARBOR), 0, "no boat the day it is bought")
	assert_eq(_pond.boat_count(HARBOR), 0, "and none on the pond")


func test_two_nights_bring_a_boat_each_and_pay_through_the_one_payout() -> void:
	assert_true(await E2eSupport.stand_at_spot(self, _root, HARBOR), "the king reached the plot")
	assert_true(await _hold_until_built(), "a full hold built the Harbor")
	watch_signals(_ctx.events)

	var gold_before_one: int = _ctx.economy.get_gold()
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night 1")
	assert_true(await _wait_phase(RunManager.RunPhase.DAWN), "dawn 1")
	var first: Array = _payout(0)
	assert_eq((first[1] as Dictionary)[HARBOR], BOAT_GOLD, "dawn 1 pays the first boat")
	assert_eq(_ctx.economy.get_gold(), gold_before_one + int(first[0]), "gold rose by the total")
	assert_eq(_pond.boat_count(HARBOR), 1, "one boat floats on the pond")
	var first_spot: Vector3 = _pond.boat_position(HARBOR, 0)

	assert_true(await _wait_phase(RunManager.RunPhase.DAY), "day 2")
	var gold_before_two: int = _ctx.economy.get_gold()
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night 2")
	assert_true(await _wait_phase(RunManager.RunPhase.DAWN), "dawn 2")
	var second: Array = _payout(1)
	assert_eq((second[1] as Dictionary)[HARBOR], 2 * BOAT_GOLD, "dawn 2 pays two boats")
	assert_eq(_ctx.economy.get_gold(), gold_before_two + int(second[0]), "gold rose by the total")
	assert_signal_emit_count(_ctx.events, "dawn_payout", 2, "one payout event per dawn")
	assert_signal_emit_count(_ctx.events, "harbor_boats_changed", 2, "one event per new boat")
	assert_eq(_pond.boat_count(HARBOR), 2, "two boats float on the pond")
	assert_eq(_pond.boat_position(HARBOR, 0), first_spot, "the first boat never moved")
	var offset: Vector2 = Vector2(first_spot.x, first_spot.z) - POND_CENTER
	assert_lt(offset.length(), POND_RADIUS, "and it floats inside the pond")


func test_the_top_tier_label_reads_the_boats_and_the_next_dawn() -> void:
	assert_not_null(_ctx.buildings.apply_next_tier(HARBOR), "tier I")
	assert_not_null(_ctx.buildings.apply_next_tier(HARBOR), "tier II, as the castle gate allows")
	var top: BuildingTierDef = _ctx.buildings.get_building_def_for_spot(HARBOR).tier_def(2)
	var label: Dictionary = SpotLabelModel.describe(_ctx, HARBOR, 0)
	assert_true(label["max_tier"], "the Harbor is at its top tier")
	var expected: String = "Boats 0 of %d, next dawn %d gold" % [top.boat_cap, top.boat_income]
	assert_eq(label["effect"], expected, "no boat yet, the first dawn brings one")
