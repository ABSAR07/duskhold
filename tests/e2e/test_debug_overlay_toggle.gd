extends GutTest
## DEV-03 on the real scene: toggle_debug_overlay (F3 / gamepad Back) shows and hides a read-only
## overlay that is hidden by default, shows the required fields and refreshes about 4 times/s.

const TOGGLE_ACTION := &"toggle_debug_overlay"
const RIDE_TIMEOUT_S: float = 5.0
const REFRESH_WINDOW_S: float = 1.0
const REQUIRED_FIELDS: Array[String] = [
	"FPS",
	"Phase: DAY",
	"Day: 1",
	"Night: 0",
	"Gold",
	"Buildings",
	"Units",
	"Enemies",
]


func after_each() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	E2eSupport.release_all_actions()


func _overlay_of(map_root: MapRoot) -> DebugOverlay:
	return map_root.get_node_or_null("HUD/DebugOverlay") as DebugOverlay


func _press_toggle() -> void:
	Input.action_press(TOGGLE_ACTION)
	await wait_process_frames(2)
	Input.action_release(TOGGLE_ACTION)
	await wait_process_frames(2)


func test_overlay_is_hidden_on_scene_start() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var overlay: DebugOverlay = _overlay_of(map_root)
	assert_not_null(overlay, "the HUD instances the debug overlay")
	if overlay == null:
		return
	assert_false(overlay.is_overlay_visible(), "hidden by default")


func test_toggle_action_shows_then_hides_the_overlay() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var overlay: DebugOverlay = _overlay_of(map_root)
	assert_not_null(overlay, "the HUD instances the debug overlay")
	if overlay == null:
		return
	await _press_toggle()
	assert_true(overlay.is_overlay_visible(), "first press shows the overlay")
	await _press_toggle()
	assert_false(overlay.is_overlay_visible(), "second press hides it again")


func test_shown_overlay_lists_the_required_fields() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var overlay: DebugOverlay = _overlay_of(map_root)
	assert_not_null(overlay, "the HUD instances the debug overlay")
	if overlay == null:
		return
	await _press_toggle()
	var text: String = overlay.get_text()
	for field: String in REQUIRED_FIELDS:
		assert_string_contains(text, field, "overlay text has %s" % field)


func test_shown_overlay_refreshes_the_buildings_row_after_a_build() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var overlay: DebugOverlay = _overlay_of(map_root)
	assert_not_null(overlay, "the HUD instances the debug overlay")
	if overlay == null:
		return
	await _press_toggle()
	assert_string_contains(overlay.get_text(), "Buildings: 0", "no building yet")

	var ctx: RunContext = map_root.get_context()
	var spot_id: StringName = ctx.buildings.spot_ids()[0]
	var arrived: bool = await E2eSupport.ride_until_focused(self, map_root, spot_id, RIDE_TIMEOUT_S)
	assert_true(arrived, "the king rode into range of the House plot")
	var cost: int = ctx.buildings.next_action_cost(spot_id)
	var hold_seconds: float = float(cost) * ctx.tuning.coin_drip_interval + 0.5
	await E2eSupport.hold_action_seconds(self, &"action_build", hold_seconds)
	assert_eq(ctx.buildings.current_tier(spot_id), 1, "the House was built through the input path")

	var refreshed: bool = await E2eSupport.wait_until(
		self, func() -> bool: return overlay.get_text().contains("Buildings: 1"), REFRESH_WINDOW_S
	)
	assert_true(refreshed, "the Buildings row shows 1 within %s s" % REFRESH_WINDOW_S)


func test_overlay_toggles_and_refreshes_while_the_tree_is_paused() -> void:
	# A later phase's pause menu pauses the tree; the F3 toggle and the refresh must still run.
	# after_each unpauses the tree, so a failure here cannot leave every later suite paused.
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var overlay: DebugOverlay = _overlay_of(map_root)
	assert_not_null(overlay, "the HUD instances the debug overlay")
	if overlay == null:
		return
	get_tree().paused = true

	await _press_toggle()
	assert_true(overlay.is_overlay_visible(), "F3 shows the overlay while the tree is paused")
	assert_string_contains(overlay.get_text(), "Buildings: 0", "and it fills at once")

	# A build through the command gate needs no tree processing, so only the overlay's own refresh
	# can bring the new count onto the screen while the tree stays paused.
	var ctx: RunContext = map_root.get_context()
	var spot_id: StringName = ctx.buildings.spot_ids()[0]
	var result: StringName = ctx.commands.submit(BuildIntent.new(spot_id))
	assert_eq(result, CommandProcessor.OK, "the House was built through the command gate")
	var refreshed: bool = await E2eSupport.wait_until(
		self, func() -> bool: return overlay.get_text().contains("Buildings: 1"), REFRESH_WINDOW_S
	)
	assert_true(refreshed, "the overlay refreshes within %s s while paused" % REFRESH_WINDOW_S)

	await _press_toggle()
	assert_false(overlay.is_overlay_visible(), "F3 hides it again while the tree is paused")


func test_overlay_keeps_refreshing_while_the_engine_time_scale_is_zero() -> void:
	# A later debug fast-forward or freeze scales _process delta; the overlay runs on real time.
	# after_each restores the time scale, so a failure here cannot freeze every later suite.
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var overlay: DebugOverlay = _overlay_of(map_root)
	assert_not_null(overlay, "the HUD instances the debug overlay")
	if overlay == null:
		return
	await _press_toggle()
	assert_string_contains(overlay.get_text(), "Buildings: 0", "no building yet")

	Engine.time_scale = 0.0
	var ctx: RunContext = map_root.get_context()
	var spot_id: StringName = ctx.buildings.spot_ids()[0]
	var result: StringName = ctx.commands.submit(BuildIntent.new(spot_id))
	assert_eq(result, CommandProcessor.OK, "the House was built through the command gate")
	var refreshed: bool = await E2eSupport.wait_until(
		self, func() -> bool: return overlay.get_text().contains("Buildings: 1"), REFRESH_WINDOW_S
	)
	assert_true(refreshed, "the overlay refreshes within %s s of real time" % REFRESH_WINDOW_S)
