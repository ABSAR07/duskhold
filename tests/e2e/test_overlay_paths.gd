extends GutTest
## DEV-03 extension on the real scene: with the debug overlay open during a night it lists the Wave,
## King and Paths sections, its Enemies row is the live count, and a 3D gizmo draws each spawn
## point's road to the castle and each enemy's line to its target. Closing the overlay hides the
## gizmo, and the gizmo is also hidden by day.

const TOGGLE_ACTION := &"toggle_debug_overlay"
const WEST: StringName = &"west"
const REFRESH_WINDOW_S: float = 2.0
const MAX_STEPS_TO_A_TARGET: int = 2400


func after_each() -> void:
	E2eSupport.release_all_actions()


func _spawn_seeded() -> MapRoot:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	var map_root: MapRoot = scene.instantiate()
	map_root.map_config = E2eSupport.shipped_prototype_map()
	map_root.fixed_run_seed = 1
	add_child_autofree(map_root)
	await wait_process_frames(2)
	return map_root


func _overlay(map_root: MapRoot) -> DebugOverlay:
	return map_root.get_node_or_null("HUD/DebugOverlay") as DebugOverlay


func _gizmo(map_root: MapRoot) -> EnemyPathGizmo:
	return map_root.find_child("EnemyPathGizmo", true, false) as EnemyPathGizmo


func _press_toggle() -> void:
	Input.action_press(TOGGLE_ACTION)
	await wait_process_frames(2)
	Input.action_release(TOGGLE_ACTION)
	await wait_process_frames(2)


func _titles(overlay: DebugOverlay) -> Array[String]:
	var titles: Array[String] = []
	for line: String in overlay.get_text().split("\n"):
		if not line.begins_with("  "):
			titles.append(line)
	return titles


func _enemies_row(overlay: DebugOverlay) -> String:
	for line: String in overlay.get_text().split("\n"):
		if line.strip_edges().begins_with("Enemies: "):
			return line.strip_edges().trim_prefix("Enemies: ")
	return ""


## Steps the simulation until some enemy has a target to draw a line to.
func _step_until_an_enemy_has_a_target(ctx: RunContext) -> bool:
	var enemies: EnemySystem = ctx.night.get_enemies()
	for _i: int in range(MAX_STEPS_TO_A_TARGET):
		ctx.step()
		for id: int in enemies.ids():
			if not enemies.target_of(id).is_empty():
				return true
	return false


func test_the_overlay_lists_the_night_sections_and_the_live_enemy_count() -> void:
	var map_root: MapRoot = await _spawn_seeded()
	var ctx: RunContext = map_root.get_context()
	var overlay: DebugOverlay = _overlay(map_root)
	assert_not_null(overlay, "the HUD instances the debug overlay")
	if overlay == null:
		return
	await _press_toggle()
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "the night starts")
	var reached: bool = _step_until_an_enemy_has_a_target(ctx)
	assert_true(reached, "an enemy found something to attack")

	var listed: bool = await E2eSupport.wait_until(
		self,
		func() -> bool: return _enemies_row(overlay) == str(ctx.get_enemy_count()),
		REFRESH_WINDOW_S
	)

	assert_true(listed, "the Agents section's Enemies row follows the live count")
	var titles: Array[String] = _titles(overlay)
	for title: String in ["Wave", "King", "Paths"]:
		assert_true(title in titles, "the overlay lists the %s section" % title)


func test_the_gizmo_draws_the_roads_and_the_enemy_lines_while_the_overlay_is_open() -> void:
	var map_root: MapRoot = await _spawn_seeded()
	var ctx: RunContext = map_root.get_context()
	var overlay: DebugOverlay = _overlay(map_root)
	var gizmo: EnemyPathGizmo = _gizmo(map_root)
	assert_not_null(overlay, "the HUD instances the debug overlay")
	assert_not_null(gizmo, "the overlay added an EnemyPathGizmo under the map")
	if overlay == null or gizmo == null:
		return
	await _press_toggle()
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "the night starts")
	assert_true(_step_until_an_enemy_has_a_target(ctx), "an enemy found something to attack")

	gizmo.refresh()

	var enemies: EnemySystem = ctx.night.get_enemies()
	var targeted: int = 0
	for id: int in enemies.ids():
		if not enemies.target_of(id).is_empty():
			targeted += 1
	var roads: int = WaveSchedule.preview_counts(ctx.map, ctx.run_manager.get_night_number()).size()
	assert_true(gizmo.visible, "the gizmo shows at night with the overlay open")
	assert_gt(targeted, 0, "the scenario has an enemy with a target")
	assert_gte(
		gizmo.line_count(), roads + targeted, "a road per used spawn point, a line per target"
	)


func test_closing_the_overlay_hides_the_gizmo() -> void:
	var map_root: MapRoot = await _spawn_seeded()
	var ctx: RunContext = map_root.get_context()
	var gizmo: EnemyPathGizmo = _gizmo(map_root)
	assert_not_null(gizmo, "the overlay added an EnemyPathGizmo under the map")
	if gizmo == null:
		return
	await _press_toggle()
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "the night starts")
	await wait_process_frames(2)
	assert_true(gizmo.visible, "visible while the overlay is open")

	await _press_toggle()

	assert_false(gizmo.visible, "hidden once the overlay is closed")
	assert_eq(gizmo.line_count(), 0, "and it draws nothing")


func test_the_gizmo_is_hidden_by_day_even_with_the_overlay_open() -> void:
	var map_root: MapRoot = await _spawn_seeded()
	var gizmo: EnemyPathGizmo = _gizmo(map_root)
	assert_not_null(gizmo, "the overlay added an EnemyPathGizmo under the map")
	if gizmo == null:
		return

	await _press_toggle()
	await wait_process_frames(2)

	assert_false(gizmo.visible, "no night, no lines")
	assert_eq(gizmo.line_count(), 0, "and nothing drawn")
