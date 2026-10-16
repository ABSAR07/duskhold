extends GutTest
## ENMY-04, D-09 on the real scene (plan 04-08): with the debug overlay open at night the castle
## flow field is drawn as one arrow per reached open cell and a cross on every blocked cell, rebuilt
## only when the field version changes, and an enemy that makes no progress is drawn as a stuck
## marker. Closing the overlay clears the field drawing.

const FIXTURE := "res://tests/fixtures/fixture_map_walls_gap.tres"
const GRUNT := "res://data/enemies/grunt.tres"
const TOGGLE_ACTION := &"toggle_debug_overlay"
const RUN: StringName = &"wall_west"
const FAR_AWAY := Vector2(-30.0, 0.0)
const STUCK_STEPS: int = 100
const SPAWN_NEVER_S: float = 600.0


func after_each() -> void:
	E2eSupport.release_all_actions()


## The wall fixture on the real scene. Its night starts 10 minutes in, so only the enemies a test
## places walk, and the run it buys stands for the whole test.
func _spawn_map() -> MapRoot:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	var map_root: MapRoot = scene.instantiate()
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	map.nights[0].groups[0].start_delay_seconds = SPAWN_NEVER_S
	map_root.map_config = map
	map_root.fixed_run_seed = 1
	add_child_autofree(map_root)
	await wait_process_frames(2)
	return map_root


func _press_toggle() -> void:
	Input.action_press(TOGGLE_ACTION)
	await wait_process_frames(2)
	Input.action_release(TOGGLE_ACTION)
	await wait_process_frames(2)


func _field_gizmo(map_root: MapRoot) -> FlowFieldGizmo:
	return map_root.find_child("FlowFieldGizmo", true, false) as FlowFieldGizmo


func _path_gizmo(map_root: MapRoot) -> EnemyPathGizmo:
	return map_root.find_child("EnemyPathGizmo", true, false) as EnemyPathGizmo


## A night with the west run bought and the overlay open, one step in so the field stands.
func _walled_night(map_root: MapRoot) -> RunContext:
	var ctx: RunContext = map_root.get_context()
	assert_eq(ctx.commands.submit(BuildIntent.new(RUN)), CommandProcessor.OK, "the run is bought")
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night starts")
	await _press_toggle()
	ctx.step()
	return ctx


## The reached open cells and the blocked cells of the castle field, counted without the gizmo.
func _expected_counts(ctx: RunContext) -> Dictionary:
	var pathing: Pathing = ctx.night.get_pathing()
	var grid: NavGrid = pathing.grid()
	var costs: PackedInt32Array = pathing.castle_field().costs()
	var reached: int = 0
	var blocked: int = 0
	for cell: int in range(grid.width() * grid.height()):
		if grid.is_border(cell):
			continue
		if grid.is_blocked(cell):
			blocked += 1
		elif costs[cell] < FlowField.INF_COST:
			reached += 1
	return {"reached": reached, "blocked": blocked}


func test_the_field_is_an_arrow_per_reached_cell_and_a_cross_per_blocked_cell() -> void:
	var map_root: MapRoot = await _spawn_map()
	var gizmo: FlowFieldGizmo = _field_gizmo(map_root)
	assert_not_null(gizmo, "the overlay added a FlowFieldGizmo under the map")
	if gizmo == null:
		return
	var ctx: RunContext = await _walled_night(map_root)
	gizmo.refresh()
	var expected: Dictionary = _expected_counts(ctx)
	assert_gt(expected["reached"], 0, "the scenario has a field")
	assert_gt(expected["blocked"], 0, "and blocked cells")
	assert_true(gizmo.visible, "visible at night with the overlay open")
	assert_eq(gizmo.arrow_count(), expected["reached"], "one arrow per reached open cell")
	assert_eq(gizmo.blocked_mark_count(), expected["blocked"], "one cross per blocked cell")


func test_the_drawing_is_rebuilt_when_the_field_version_changes() -> void:
	var map_root: MapRoot = await _spawn_map()
	var gizmo: FlowFieldGizmo = _field_gizmo(map_root)
	assert_not_null(gizmo, "the overlay added a FlowFieldGizmo under the map")
	if gizmo == null:
		return
	var ctx: RunContext = await _walled_night(map_root)
	var pathing: Pathing = ctx.night.get_pathing()
	gizmo.refresh()
	assert_eq(gizmo.built_for_version(), pathing.field_version(), "drawn for the current field")
	var before: int = pathing.field_version()
	var first: int = ctx.walls.segments_of(RUN)[0]
	ctx.walls.damage_segment(first, ctx.walls.max_health_of(first))
	ctx.step()
	assert_gt(pathing.field_version(), before, "the break rebuilt the field")
	gizmo.refresh()
	assert_eq(gizmo.built_for_version(), pathing.field_version(), "and the drawing followed it")
	var expected: Dictionary = _expected_counts(ctx)
	assert_eq(gizmo.arrow_count(), expected["reached"], "the arrows follow the new field")
	assert_eq(gizmo.blocked_mark_count(), expected["blocked"], "so do the crosses")


func test_with_the_overlay_off_nothing_is_drawn() -> void:
	var map_root: MapRoot = await _spawn_map()
	var gizmo: FlowFieldGizmo = _field_gizmo(map_root)
	assert_not_null(gizmo, "the overlay added a FlowFieldGizmo under the map")
	if gizmo == null:
		return
	await _walled_night(map_root)
	gizmo.refresh()
	assert_gt(gizmo.arrow_count(), 0, "drawn while the overlay is open")
	await _press_toggle()
	gizmo.refresh()
	assert_false(gizmo.visible, "hidden once the overlay is closed")
	assert_eq(gizmo.arrow_count(), 0, "no arrows")
	assert_eq(gizmo.blocked_mark_count(), 0, "no crosses")


func test_by_day_nothing_is_drawn_even_with_the_overlay_open() -> void:
	var map_root: MapRoot = await _spawn_map()
	var gizmo: FlowFieldGizmo = _field_gizmo(map_root)
	assert_not_null(gizmo, "the overlay added a FlowFieldGizmo under the map")
	if gizmo == null:
		return
	var ctx: RunContext = map_root.get_context()
	ctx.commands.submit(BuildIntent.new(RUN))
	await _press_toggle()
	ctx.step()
	gizmo.refresh()
	assert_false(gizmo.visible, "no night, no field")
	assert_eq(gizmo.arrow_count(), 0, "and nothing drawn")


func test_an_enemy_that_makes_no_progress_is_drawn_as_a_stuck_marker() -> void:
	var map_root: MapRoot = await _spawn_map()
	var ctx: RunContext = map_root.get_context()
	var path_gizmo: EnemyPathGizmo = _path_gizmo(map_root)
	assert_not_null(path_gizmo, "the overlay added an EnemyPathGizmo under the map")
	if path_gizmo == null:
		return
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night starts")
	await _press_toggle()
	var def: EnemyDef = (load(GRUNT) as EnemyDef).duplicate()
	def.move_speed = 0.0
	var id: int = ctx.night.get_enemies().spawn(def, FAR_AWAY)
	path_gizmo.refresh()
	assert_eq(path_gizmo.stuck_marker_count(), 0, "not flagged yet")
	for _i: int in range(STUCK_STEPS):
		ctx.step()
	assert_true(ctx.night.get_pathing().stuck().is_stuck(id), "the held enemy is flagged")
	path_gizmo.refresh()
	assert_eq(path_gizmo.stuck_marker_count(), 1, "and drawn as a stuck marker")
	assert_eq(EnemyPathGizmo.STUCK_COLOR, Color(1.0, 0.2, 0.9, 1.0), "in magenta")
