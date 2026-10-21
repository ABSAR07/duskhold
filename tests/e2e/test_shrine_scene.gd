extends GutTest
## ECON-06 on the real scene (the tracer of plan 05-09): on a small fixture map the king builds the
## Shrine and a tower by holding (a second tower is bought by intent), the night's grunts die beside
## the Shrine, it wakes within 60 s of real time and the projectile layer then draws a bolt that
## leaves from the Shrine's plot. The fixture carries its own inline copy of the Shrine, so the plan
## 05-11 fit cannot move when it wakes.

const FIXTURE := "res://tests/fixtures/fixture_map_shrine.tres"
const SHRINE: StringName = &"shrine_1"
const TOWER: StringName = &"tower_1"
const SECOND_TOWER: StringName = &"tower_2"
const SETTLE_FRAMES: int = 3
const HOLD_SLACK_S: float = 1.5
const WAKE_TIMEOUT_S: float = 60.0
const BOLT_TIMEOUT_S: float = 20.0
const KING_AWAY := Vector3(40.0, 0.0, 40.0)
const COORDINATE_EPSILON: float = 0.01

var _root: MapRoot
var _ctx: RunContext


func before_each() -> void:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	_root = scene.instantiate()
	_root.map_config = load(FIXTURE)
	_root.fixed_run_seed = 1
	_root.handle_results_actions = false
	add_child_autofree(_root)
	await wait_process_frames(SETTLE_FRAMES)
	_ctx = _root.get_context()


func after_each() -> void:
	E2eSupport.release_all_actions()


func _tier_of(spot_id: StringName) -> BuildingTierDef:
	return _ctx.buildings.get_building_def_for_spot(spot_id).tier_def(1)


## The king rides to the plot and holds the action key until the building stands.
func _hold_to_build(spot_id: StringName) -> bool:
	if not await E2eSupport.stand_at_spot(self, _root, spot_id):
		return false
	var seconds: float = _ctx.tuning.build_hold_seconds(_tier_of(spot_id).cost) + HOLD_SLACK_S
	Input.action_press(&"action_build")
	var built: Callable = func() -> bool: return _ctx.buildings.current_tier(spot_id) == 1
	var got: bool = await E2eSupport.wait_until(self, built, seconds)
	Input.action_release(&"action_build")
	await wait_process_frames(2)
	return got


func _bolt_leaves_from(vfx: ProjectileVfx, plot: Vector3) -> bool:
	for index: int in range(vfx.arrow_count()):
		var launch: Vector3 = vfx.arrow_launch_at(index)
		if (
			absf(launch.x - plot.x) < COORDINATE_EPSILON
			and absf(launch.z - plot.z) < COORDINATE_EPSILON
		):
			return true
	return false


func test_the_king_builds_the_shrine_and_it_starts_asleep() -> void:
	assert_true(await _hold_to_build(SHRINE), "a full hold built the Shrine")
	assert_eq(_ctx.buildings.current_tier(SHRINE), 1, "tier I stands")
	assert_false(_ctx.income.is_awake(SHRINE), "it is dormant")
	assert_eq(_ctx.income.kill_credit(SHRINE), 0, "with no credit")
	var view: Node3D = (_root.get_node("BuildingViews") as BuildingViews).get_view(SHRINE)
	assert_not_null(view, "the plot has a view")
	assert_true(
		str(view.get_meta(&"view_source", "")).ends_with("shrine_t1.tscn"),
		"it is the Shrine's model"
	)


func test_the_night_wakes_the_shrine_and_a_bolt_leaves_its_plot() -> void:
	assert_true(await _hold_to_build(TOWER), "the tower stands")
	var second: StringName = _ctx.commands.submit(BuildIntent.new(SECOND_TOWER))
	assert_eq(second, CommandProcessor.OK, "the second tower is bought beside the road")
	assert_true(await _hold_to_build(SHRINE), "the Shrine stands")
	E2eSupport.teleport_king(_root, KING_AWAY)
	var vfx: ProjectileVfx = _root.get_node("ProjectileVfx") as ProjectileVfx
	var plot: Vector3 = _ctx.buildings.get_spot(SHRINE).position
	watch_signals(_ctx.events)
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night starts")
	var woke: Callable = func() -> bool: return _ctx.income.is_awake(SHRINE)
	assert_true(await E2eSupport.wait_until(self, woke, WAKE_TIMEOUT_S), "it wakes within 60 s")
	assert_signal_emit_count(_ctx.events, "shrine_woke", 1, "once")
	var threshold: int = _tier_of(SHRINE).wake_threshold_hp
	assert_gte(_ctx.income.kill_credit(SHRINE), threshold, "the credit reached the threshold")
	var drawn: Callable = func() -> bool: return _bolt_leaves_from(vfx, plot)
	assert_true(await E2eSupport.wait_until(self, drawn, BOLT_TIMEOUT_S), "a Shrine bolt is drawn")
