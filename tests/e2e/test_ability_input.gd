extends GutTest
## KING-04 on the real scene: the ability action reaches the command gate through the polled
## AbilityController, the slam ring shows, and a press during the cooldown is denied. Scripted
## Input.action_press makes no input event, so the controller's edge fallback is what is exercised.

const SETTLE_FRAMES: int = 3
const RING_TIMEOUT_S: float = 2.0

var _used_count: int = 0
var _rings_at_use: int = -1


func before_each() -> void:
	_used_count = 0
	_rings_at_use = -1


func after_each() -> void:
	E2eSupport.release_all_actions()


func _on_used(_hit_count: int, vfx: SlamVfx) -> void:
	_used_count += 1
	if _rings_at_use < 0:
		_rings_at_use = vfx.active_ring_count()


func _tap(frames: int) -> void:
	Input.action_press(&"ability")
	await wait_process_frames(frames)
	Input.action_release(&"ability")
	await wait_process_frames(frames)


func test_the_scene_has_an_ability_controller_and_a_slam_vfx() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	assert_not_null(map_root.get_node_or_null("AbilityController") as AbilityController, "input")
	assert_not_null(map_root.get_node_or_null("SlamVfx") as SlamVfx, "vfx")
	for node_name: StringName in [&"AbilityController", &"SlamVfx"]:
		var node: Node = map_root.get_node_or_null(NodePath(node_name))
		assert_not_null(node, "%s exists" % node_name)
		if node != null:
			assert_true(node.is_in_group(&"run_bound"), "%s is run bound" % node_name)


func test_pressing_the_ability_by_day_slams_once_and_shows_a_ring() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var ctx: RunContext = map_root.get_context()
	var vfx: SlamVfx = map_root.get_node_or_null("SlamVfx") as SlamVfx
	assert_not_null(vfx, "the scene has a SlamVfx")
	if vfx == null:
		return
	ctx.events.king_ability_used.connect(_on_used.bind(vfx))
	assert_eq(vfx.active_ring_count(), 0, "no ring before the press")
	await _tap(SETTLE_FRAMES)
	var arrived: bool = await E2eSupport.wait_until(
		self, func() -> bool: return _used_count > 0, RING_TIMEOUT_S
	)
	assert_true(arrived, "the slam fired")
	assert_eq(_used_count, 1, "one press, one slam")
	assert_gt(_rings_at_use, 0, "a ring is showing as the slam fires")
	assert_gt(ctx.king.ability_ticks_left(), 0, "the cooldown runs")


func test_a_second_press_within_the_cooldown_is_denied_with_the_reason() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var controller: AbilityController = (
		map_root.get_node_or_null("AbilityController") as AbilityController
	)
	assert_not_null(controller, "the scene has an AbilityController")
	if controller == null:
		return
	watch_signals(controller)
	await _tap(SETTLE_FRAMES)
	assert_signal_not_emitted(controller, "denied", "the first press is accepted")
	await _tap(SETTLE_FRAMES)
	assert_signal_emitted_with_parameters(controller, "denied", [CommandProcessor.ABILITY_COOLING])
	assert_signal_emit_count(controller, "denied", 1, "once")


func test_holding_the_action_is_one_press_not_a_stream() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var controller: AbilityController = (
		map_root.get_node_or_null("AbilityController") as AbilityController
	)
	if controller == null:
		fail_test("no AbilityController")
		return
	watch_signals(controller)
	Input.action_press(&"ability")
	await wait_process_frames(12)
	assert_signal_not_emitted(controller, "denied", "a held key does not retrigger")
	Input.action_release(&"ability")
