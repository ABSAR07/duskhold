extends GutTest
## DEV-03 on the real scene: toggle_debug_overlay (F3 / gamepad Back) shows and hides a read-only
## overlay that is hidden by default, shows the required fields, refreshes while shown and does not
## refresh while hidden. The refresh cadence itself (about 4 times/s, REFRESH_INTERVAL_S) is pinned
## with synthetic deltas in tests/unit/test_debug_overlay_registration.gd, not with wall-clock time;
## here a shown overlay only has to catch up within REFRESH_WINDOW_S of real time.

const TOGGLE_ACTION := &"toggle_debug_overlay"
const RIDE_TIMEOUT_S: float = 5.0
const REFRESH_WINDOW_S: float = 1.0
## Rows whose value is known on a fresh map, checked exactly.
const EXPECTED_VALUES: Dictionary = {
	"Phase": "DAY",
	"Day": "1",
	"Night": "0",
	"Buildings": "0",
}
## Rows that must carry an integer whose value depends on tuning or on the frame rate.
const INTEGER_ROWS: Array[String] = ["FPS", "Gold", "Units", "Enemies"]

var _map_root: MapRoot


func after_each() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	E2eSupport.release_all_actions()


## The overlay's rows as {label: value}, parsed from its "  label: value" lines (section titles have
## no indent and are skipped), so a check sees a row's value and not just a substring of the text.
func _rows_of(overlay: DebugOverlay) -> Dictionary:
	var rows: Dictionary = {}
	for line: String in overlay.get_text().split("\n"):
		if not line.begins_with("  "):
			continue
		var parts: PackedStringArray = line.strip_edges().split(": ", true, 1)
		if parts.size() == 2:
			rows[parts[0]] = parts[1]
	return rows


## Spawns the real map and returns its debug overlay, or null (after failing the test) if the HUD
## does not instance one; a caller returns at once on null. Keeps the map in _map_root.
func _spawn_overlay() -> DebugOverlay:
	_map_root = await E2eSupport.spawn_map(self)
	var overlay: DebugOverlay = _map_root.get_node_or_null("HUD/DebugOverlay") as DebugOverlay
	assert_not_null(overlay, "the HUD instances the debug overlay")
	return overlay


## The Buildings row's value in the overlay's current text ("" when the row is missing).
func _buildings_shown(overlay: DebugOverlay) -> String:
	return _rows_of(overlay).get("Buildings", "")


## Waits up to REFRESH_WINDOW_S of real time for the Buildings row to read exactly `count`.
func _wait_for_buildings(overlay: DebugOverlay, count: int) -> bool:
	return await E2eSupport.wait_until(
		self, func() -> bool: return _buildings_shown(overlay) == str(count), REFRESH_WINDOW_S
	)


## Builds the first plot through the command gate, which needs no tree processing.
func _build_first_plot_through_the_gate() -> void:
	var ctx: RunContext = _map_root.get_context()
	var result: StringName = ctx.commands.submit(BuildIntent.new(ctx.buildings.spot_ids()[0]))
	assert_eq(result, CommandProcessor.OK, "the House was built through the command gate")


func _press_toggle() -> void:
	Input.action_press(TOGGLE_ACTION)
	await wait_process_frames(2)
	Input.action_release(TOGGLE_ACTION)
	await wait_process_frames(2)


func test_overlay_is_hidden_on_scene_start() -> void:
	var overlay: DebugOverlay = await _spawn_overlay()
	if overlay == null:
		return
	assert_false(overlay.is_overlay_visible(), "hidden by default")


func test_toggle_action_shows_then_hides_the_overlay() -> void:
	var overlay: DebugOverlay = await _spawn_overlay()
	if overlay == null:
		return
	await _press_toggle()
	assert_true(overlay.is_overlay_visible(), "first press shows the overlay")
	await _press_toggle()
	assert_false(overlay.is_overlay_visible(), "second press hides it again")


func test_shown_overlay_lists_the_required_fields() -> void:
	var overlay: DebugOverlay = await _spawn_overlay()
	if overlay == null:
		return
	await _press_toggle()
	var rows: Dictionary = _rows_of(overlay)
	for label: String in EXPECTED_VALUES:
		assert_eq(rows.get(label), EXPECTED_VALUES[label], "the %s row has its value" % label)
	for label: String in INTEGER_ROWS:
		var value: String = rows.get(label, "")
		assert_true(
			value.is_valid_int(), "the %s row has an integer value, not '%s'" % [label, value]
		)


func test_shown_overlay_refreshes_the_buildings_row_after_a_build() -> void:
	var overlay: DebugOverlay = await _spawn_overlay()
	if overlay == null:
		return
	await _press_toggle()
	assert_eq(_buildings_shown(overlay), "0", "no building yet")

	var ctx: RunContext = _map_root.get_context()
	var spot_id: StringName = ctx.buildings.spot_ids()[0]
	var arrived: bool = await E2eSupport.ride_until_focused(
		self, _map_root, spot_id, RIDE_TIMEOUT_S
	)
	assert_true(arrived, "the king rode into range of the House plot")
	var cost: int = ctx.buildings.next_action_cost(spot_id)
	var hold_seconds: float = ctx.tuning.build_hold_seconds(cost) + 0.5
	await E2eSupport.hold_action_seconds(self, &"action_build", hold_seconds)
	assert_eq(ctx.buildings.current_tier(spot_id), 1, "the House was built through the input path")

	var refreshed: bool = await _wait_for_buildings(overlay, 1)
	assert_true(refreshed, "the Buildings row shows 1 within %s s" % REFRESH_WINDOW_S)


func test_overlay_toggles_and_refreshes_while_the_tree_is_paused() -> void:
	# A later phase's pause menu pauses the tree; the F3 toggle and the refresh must still run.
	# after_each unpauses the tree, so a failure here cannot leave every later suite paused.
	var overlay: DebugOverlay = await _spawn_overlay()
	if overlay == null:
		return
	get_tree().paused = true

	await _press_toggle()
	assert_true(overlay.is_overlay_visible(), "F3 shows the overlay while the tree is paused")
	assert_eq(_buildings_shown(overlay), "0", "and it fills at once")

	# A build through the command gate needs no tree processing, so only the overlay's own refresh
	# can bring the new count onto the screen while the tree stays paused.
	_build_first_plot_through_the_gate()
	var refreshed: bool = await _wait_for_buildings(overlay, 1)
	assert_true(refreshed, "the overlay refreshes within %s s while paused" % REFRESH_WINDOW_S)

	await _press_toggle()
	assert_false(overlay.is_overlay_visible(), "F3 hides it again while the tree is paused")


func test_overlay_keeps_refreshing_while_the_engine_time_scale_is_zero() -> void:
	# A later debug fast-forward or freeze scales _process delta; the overlay runs on real time.
	# after_each restores the time scale, so a failure here cannot freeze every later suite.
	var overlay: DebugOverlay = await _spawn_overlay()
	if overlay == null:
		return
	await _press_toggle()
	assert_eq(_buildings_shown(overlay), "0", "no building yet")

	Engine.time_scale = 0.0
	_build_first_plot_through_the_gate()
	var refreshed: bool = await _wait_for_buildings(overlay, 1)
	assert_true(refreshed, "the overlay refreshes within %s s of real time" % REFRESH_WINDOW_S)


func test_hidden_overlay_does_not_refresh_until_it_is_shown_again() -> void:
	# Deterministic in the failing direction only: a hidden overlay that did refresh would show the
	# new count after a few intervals; a correct one stays stale however long we wait.
	var overlay: DebugOverlay = await _spawn_overlay()
	if overlay == null:
		return
	await _press_toggle()
	assert_eq(_buildings_shown(overlay), "0", "no building yet")
	await _press_toggle()
	assert_false(overlay.is_overlay_visible(), "the second press hides the overlay")

	_build_first_plot_through_the_gate()
	await wait_seconds(REFRESH_WINDOW_S)
	assert_eq(_buildings_shown(overlay), "0", "a hidden overlay does not refresh")

	await _press_toggle()
	assert_eq(_buildings_shown(overlay), "1", "showing it again refreshes at once")
