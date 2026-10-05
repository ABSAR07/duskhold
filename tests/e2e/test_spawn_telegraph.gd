extends GutTest
## LOOP-02 on the real scene: by day each spawn point that will send enemies in the coming night
## wears a marker with that night's count (on screen over the point, or clamped to the screen edge
## with an arrow), the HUD says how many enemies from how many directions, and by night the banner
## counts down what is left. Counts come from the map data.

const WEST: StringName = &"west"
const EAST: StringName = &"east"
const BESIDE_WEST_SPAWN := Vector3(4.0, 0.0, 0.0)
const MARKER_TIMEOUT_S: float = 1.5
## Steps that spawn the first enemy of a night (the first spawn is due after half a second).
const STEPS_TO_FIRST_SPAWN: int = 30
const MAX_CLEAR_STEPS: int = 1500
const MAX_DAWN_STEPS: int = 1500


func _hud(map_root: MapRoot) -> Node:
	return map_root.get_node("HUD")


func _telegraph(map_root: MapRoot) -> SpawnTelegraph:
	return _hud(map_root).find_child("SpawnTelegraph", true, false) as SpawnTelegraph


func _preview(map_root: MapRoot) -> Label:
	return _hud(map_root).get_node_or_null("%NightPreview") as Label


func _banner(map_root: MapRoot) -> Label:
	return _hud(map_root).get_node_or_null("%PhaseBanner") as Label


## The real map scene on a seeded run, with `map` as its data.
func _spawn_seeded(map: MapConfig) -> MapRoot:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	var map_root: MapRoot = scene.instantiate()
	map_root.map_config = map
	map_root.fixed_run_seed = 1
	add_child_autofree(map_root)
	await wait_process_frames(2)
	return map_root


func _total(map: MapConfig, night_number: int) -> int:
	var total: int = 0
	for count: int in WaveSchedule.preview_counts(map, night_number).values():
		total += count
	return total


func _banner_text(map: MapConfig, night_number: int, left: int) -> String:
	return "Night %d of %d — %d enemies left" % [night_number, map.nights.size(), left]


func _step_n(ctx: RunContext, steps: int) -> void:
	for _i: int in range(steps):
		ctx.step()


## Kills every living enemy each step until the night hands over to dawn, then steps through dawn
## into the next day.
func _clear_night_and_reach_the_next_day(ctx: RunContext) -> void:
	for _i: int in range(MAX_CLEAR_STEPS):
		for id: int in ctx.night.get_enemies().ids():
			ctx.night.get_enemies().damage(id, 9999, &"king")
		ctx.step()
		if ctx.run_manager.get_phase() == RunManager.RunPhase.DAWN:
			break
	for _i: int in range(MAX_DAWN_STEPS):
		if ctx.run_manager.get_phase() == RunManager.RunPhase.DAY:
			break
		ctx.step()


func test_by_day_one_marker_shows_the_count_of_the_coming_night() -> void:
	var map: MapConfig = E2eSupport.shipped_prototype_map()
	var map_root: MapRoot = await _spawn_seeded(map)
	var telegraph: SpawnTelegraph = _telegraph(map_root)
	assert_not_null(telegraph, "the HUD has a SpawnTelegraph")
	if telegraph == null:
		return

	assert_eq(telegraph.marker_count(), 1, "night one comes from one spawn point")
	assert_eq(
		telegraph.marker_text(WEST),
		str(WaveSchedule.preview_counts(map, 1)[WEST]),
		"the marker carries that night's enemy count"
	)
	assert_eq(telegraph.marker_text(EAST), "", "a spawn point with no enemies has no marker")


func test_with_the_king_at_the_castle_the_west_marker_is_clamped_to_the_screen_edge() -> void:
	var map_root: MapRoot = await _spawn_seeded(E2eSupport.shipped_prototype_map())
	var telegraph: SpawnTelegraph = _telegraph(map_root)
	assert_not_null(telegraph, "the HUD has a SpawnTelegraph")
	if telegraph == null:
		return

	assert_false(telegraph.is_marker_on_screen(WEST), "the spawn point is about 70 m out of view")


func test_riding_to_the_west_spawn_point_brings_its_marker_onto_the_screen() -> void:
	var map: MapConfig = E2eSupport.shipped_prototype_map()
	var map_root: MapRoot = await _spawn_seeded(map)
	var telegraph: SpawnTelegraph = _telegraph(map_root)
	assert_not_null(telegraph, "the HUD has a SpawnTelegraph")
	if telegraph == null:
		return

	E2eSupport.teleport_king(map_root, map.find_spawn_point(WEST).position + BESIDE_WEST_SPAWN)
	var shown: bool = await E2eSupport.wait_until(
		self, func() -> bool: return telegraph.is_marker_on_screen(WEST), MARKER_TIMEOUT_S
	)

	assert_true(shown, "the marker sits over the spawn point once the camera arrives")


func test_the_preview_line_names_the_night_its_enemies_and_one_direction() -> void:
	var map: MapConfig = E2eSupport.shipped_prototype_map()
	var map_root: MapRoot = await _spawn_seeded(map)
	var preview: Label = _preview(map_root)
	assert_not_null(preview, "the HUD has a night preview label")
	if preview == null:
		return

	assert_true(preview.visible, "the preview shows by day")
	assert_eq(
		preview.text,
		"Night 1: %d enemies from 1 direction" % _total(map, 1),
		"one direction reads in the singular"
	)


func test_a_night_from_two_spawn_points_reads_in_the_plural() -> void:
	var map: MapConfig = E2eSupport.shipped_prototype_map()
	var extra: SpawnGroupDef = SpawnGroupDef.new()
	extra.spawn_point_id = EAST
	extra.enemy_id = &"grunt"
	extra.count = 3
	map.night_def(1).groups.append(extra)
	var map_root: MapRoot = await _spawn_seeded(map)
	var preview: Label = _preview(map_root)
	var telegraph: SpawnTelegraph = _telegraph(map_root)
	assert_not_null(preview, "the HUD has a night preview label")
	assert_not_null(telegraph, "the HUD has a SpawnTelegraph")
	if preview == null or telegraph == null:
		return

	assert_eq(
		preview.text,
		"Night 1: %d enemies from 2 directions" % _total(map, 1),
		"the total sums both spawn points"
	)
	assert_eq(telegraph.marker_count(), 2, "one marker per spawn point")
	assert_eq(telegraph.marker_text(EAST), "3", "the east marker carries its own count")


func test_starting_the_night_hides_the_markers_and_the_banner_counts_what_is_left() -> void:
	var map: MapConfig = E2eSupport.shipped_prototype_map()
	var map_root: MapRoot = await _spawn_seeded(map)
	var ctx: RunContext = map_root.get_context()
	var telegraph: SpawnTelegraph = _telegraph(map_root)
	var preview: Label = _preview(map_root)
	var banner: Label = _banner(map_root)
	assert_not_null(telegraph, "the HUD has a SpawnTelegraph")
	assert_not_null(preview, "the HUD has a night preview label")
	assert_not_null(banner, "the HUD has a phase banner")
	if telegraph == null or preview == null or banner == null:
		return
	var total: int = _total(map, 1)

	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "the night starts")

	assert_eq(telegraph.marker_count(), 0, "no markers at night")
	assert_false(preview.visible, "no preview at night")
	assert_true(banner.visible, "the banner shows")
	assert_eq(banner.text, _banner_text(map, 1, total), "every enemy of the night is still to come")

	_step_n(ctx, STEPS_TO_FIRST_SPAWN)
	var ids: Array[int] = ctx.night.get_enemies().ids()
	assert_gt(ids.size(), 0, "the first enemy has spawned")
	if ids.is_empty():
		return
	ctx.night.get_enemies().damage(ids[0], 9999, &"king")
	ctx.step()

	assert_eq(banner.text, _banner_text(map, 1, total - 1), "the count falls as enemies die")


func test_the_next_day_shows_the_next_nights_markers() -> void:
	var map: MapConfig = E2eSupport.shipped_prototype_map()
	var map_root: MapRoot = await _spawn_seeded(map)
	var ctx: RunContext = map_root.get_context()
	var telegraph: SpawnTelegraph = _telegraph(map_root)
	assert_not_null(telegraph, "the HUD has a SpawnTelegraph")
	if telegraph == null:
		return
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night one starts")

	_clear_night_and_reach_the_next_day(ctx)
	await wait_process_frames(2)

	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAY, "the next day arrived")
	assert_eq(telegraph.marker_count(), WaveSchedule.preview_counts(map, 2).size(), "night two")
	assert_eq(
		telegraph.marker_text(WEST),
		str(WaveSchedule.preview_counts(map, 2)[WEST]),
		"the marker carries night two's count"
	)


func test_a_waveless_map_shows_no_marker_no_preview_and_a_plain_night_banner() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var ctx: RunContext = map_root.get_context()
	var telegraph: SpawnTelegraph = _telegraph(map_root)
	var preview: Label = _preview(map_root)
	var banner: Label = _banner(map_root)
	assert_not_null(telegraph, "the HUD has a SpawnTelegraph")
	assert_not_null(preview, "the HUD has a night preview label")
	assert_not_null(banner, "the HUD has a phase banner")
	if telegraph == null or preview == null or banner == null:
		return

	assert_eq(telegraph.marker_count(), 0, "no authored nights, no markers")
	assert_false(preview.visible, "and no preview line")
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "the night starts")
	assert_eq(banner.text, "Night 1", "the timed night keeps the plain banner")
