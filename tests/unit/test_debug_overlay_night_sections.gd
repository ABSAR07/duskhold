extends GutTest
## DEV-03 extension (ROADMAP success criterion 3): the Wave, King and Paths sections read the
## night, and collecting them is strictly read-only. A RunContext on the shipped map (or its
## waveless copy), stepped with ctx.step() and no scene tree. Counts come from the map data.

const OVERLAY_SCENE := "res://ui/overlay/debug_overlay.tscn"
const WEST: StringName = &"west"
const EM_DASH := "—"
const MAX_STEPS: int = 2400
## Steps that spawn the first enemy of a night and let it take a first look around.
const STEPS_AFTER_FIRST_SPAWN: int = 24
const READ_ONLY_REPEATS: int = 100

var _tuning: LoopTuning


func before_each() -> void:
	_tuning = OverlayTestSupport.new_tuning()


func after_each() -> void:
	E2eSupport.release_all_actions()


func _context(map: MapConfig = null) -> RunContext:
	var used: MapConfig = map if map != null else E2eSupport.shipped_prototype_map()
	return RunContext.new(used, _tuning, 1)


func _start_night(ctx: RunContext) -> void:
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "the night starts")


func _step_n(ctx: RunContext, steps: int) -> void:
	for _i: int in range(steps):
		ctx.step()


func _row(rows: Array, label: String) -> Variant:
	return OverlayTestSupport.row_value({"rows": rows}, label)


func _kills_everything_until_dawn(ctx: RunContext) -> void:
	for _i: int in range(MAX_STEPS):
		for id: int in ctx.night.get_enemies().ids():
			ctx.night.get_enemies().damage(id, 9999, &"king")
		ctx.step()
		if ctx.run_manager.get_phase() == RunManager.RunPhase.DAWN:
			return


func _overlay() -> DebugOverlay:
	var overlay: DebugOverlay = (load(OVERLAY_SCENE) as PackedScene).instantiate()
	add_child_autofree(overlay)
	return overlay


func _shown_text(overlay: DebugOverlay) -> String:
	await wait_process_frames(1)
	Input.action_press(DebugOverlay.TOGGLE_ACTION)
	await wait_process_frames(2)
	Input.action_release(DebugOverlay.TOGGLE_ACTION)
	await wait_process_frames(1)
	return overlay.get_text()


func test_wave_rows_at_the_start_of_night_one() -> void:
	var ctx: RunContext = _context()
	var group: SpawnGroupDef = ctx.map.night_def(1).groups[0]
	_start_night(ctx)

	var rows: Array = NightOverlaySections.wave_rows(ctx)

	assert_eq(_row(rows, "Night"), "1 of %d" % ctx.map.nights.size(), "night n of the total")
	assert_eq(_row(rows, "Spawned"), "0 of %d" % group.count, "nothing has spawned yet")
	assert_eq(_row(rows, "Alive"), str(ctx.get_enemy_count()), "alive is the live count")
	assert_eq(_row(rows, "Next spawn"), "%.1f s" % group.start_delay_seconds, "the first spawn")
	assert_eq(_row(rows, "Cleared"), "no", "the night is not cleared")
	assert_eq(_row(rows, "Seed"), str(ctx.run_seed), "the run seed")


func test_wave_rows_once_everything_has_spawned() -> void:
	var ctx: RunContext = _context()
	var total: int = ctx.map.night_def(1).groups[0].count
	_start_night(ctx)
	for _i: int in range(MAX_STEPS):
		if ctx.night.spawned_count() == total:
			break
		ctx.step()

	var rows: Array = NightOverlaySections.wave_rows(ctx)

	assert_eq(_row(rows, "Spawned"), "%d of %d" % [total, total], "all spawned")
	assert_eq(_row(rows, "Next spawn"), EM_DASH, "nothing left to spawn")
	assert_eq(_row(rows, "Alive"), str(total), "all of them still walking")
	assert_eq(_row(rows, "Alive"), str(ctx.get_enemy_count()), "and that is the live count")
	assert_eq(_row(rows, "Cleared"), "no", "alive enemies keep the night open")


func test_wave_rows_after_the_night_is_cleared() -> void:
	var ctx: RunContext = _context()
	_start_night(ctx)
	_kills_everything_until_dawn(ctx)

	var rows: Array = NightOverlaySections.wave_rows(ctx)

	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "the night ended")
	assert_eq(_row(rows, "Cleared"), "yes", "every group spawned and nobody is alive")
	assert_eq(_row(rows, "Alive"), "0", "nobody left")


func test_wave_rows_by_day_say_night_zero_and_not_cleared() -> void:
	var ctx: RunContext = _context()

	var rows: Array = NightOverlaySections.wave_rows(ctx)

	assert_eq(_row(rows, "Night"), "0 of %d" % ctx.map.nights.size(), "no night yet")
	assert_eq(_row(rows, "Next spawn"), EM_DASH, "nothing scheduled")
	assert_eq(_row(rows, "Cleared"), "no", "nothing to clear")


func test_wave_rows_on_a_waveless_map_call_the_night_timed() -> void:
	var ctx: RunContext = _context(E2eSupport.waveless_prototype_map())
	_start_night(ctx)

	var rows: Array = NightOverlaySections.wave_rows(ctx)

	assert_eq(_row(rows, "Night"), "1 (timed)", "no authored nights, so no total")


func test_king_rows_for_a_healthy_king() -> void:
	var ctx: RunContext = _context()

	var rows: Array = NightOverlaySections.king_rows(ctx)

	var max_hp: int = ctx.king.get_max_health()
	assert_eq(_row(rows, "HP"), "%d / %d" % [max_hp, max_hp], "full health")
	assert_eq(_row(rows, "State"), "Up", "standing")
	assert_eq(_row(rows, "Respawn"), EM_DASH, "no countdown")
	assert_eq(_row(rows, "Knockouts"), "0 / 0", "none this night, none this run")


func test_king_rows_for_a_knocked_out_king() -> void:
	var ctx: RunContext = _context()
	_start_night(ctx)
	ctx.king.take_damage(ctx.king.get_max_health())

	var rows: Array = NightOverlaySections.king_rows(ctx)

	assert_eq(_row(rows, "HP"), "0 / %d" % ctx.king.get_max_health(), "no health left")
	assert_eq(_row(rows, "State"), "Down", "knocked out")
	assert_eq(_row(rows, "Respawn"), "%.1f s" % _tuning.respawn_seconds(1), "the first countdown")
	assert_eq(_row(rows, "Knockouts"), "1 / 1", "one this night, one this run")


func test_king_knockouts_split_into_this_night_and_this_run() -> void:
	var ctx: RunContext = _context()
	_start_night(ctx)
	ctx.king.take_damage(ctx.king.get_max_health())
	ctx.king.begin_night()

	var rows: Array = NightOverlaySections.king_rows(ctx)

	assert_eq(_row(rows, "Knockouts"), "0 / 1", "the night count resets, the run count stays")


func test_path_rows_count_marching_enemies_before_any_has_a_target() -> void:
	var ctx: RunContext = _context()
	_start_night(ctx)
	_step_n(ctx, STEPS_AFTER_FIRST_SPAWN)

	var rows: Array = NightOverlaySections.path_rows(ctx)

	assert_gt(ctx.get_enemy_count(), 0, "the scenario has an enemy")
	assert_eq(_row(rows, "Marching"), str(ctx.get_enemy_count()), "all of them still marching")
	assert_eq(_row(rows, "To king"), "0", "nobody heads for the king")
	assert_eq(_row(rows, "To castle"), "0", "nor the castle")
	assert_eq(_row(rows, "To building"), "0", "nor a building")


func test_path_rows_count_enemies_by_what_they_head_for_and_add_up_to_the_alive_count() -> void:
	var ctx: RunContext = _context()
	var spawn: Vector3 = ctx.map.find_spawn_point(WEST).position
	ctx.king.report_position(Vector2(spawn.x + 2.0, spawn.z))
	_start_night(ctx)
	_step_n(ctx, STEPS_AFTER_FIRST_SPAWN)
	var by_kind: Dictionary = {PendingHits.KIND_KING: 0, PendingHits.KIND_CASTLE: 0, &"": 0}
	by_kind[PendingHits.KIND_BUILDING] = 0
	for id: int in ctx.night.get_enemies().ids():
		var target: Dictionary = ctx.night.get_enemies().target_of(id)
		by_kind[target.get("kind", &"")] += 1

	var rows: Array = NightOverlaySections.path_rows(ctx)

	assert_gt(by_kind[PendingHits.KIND_KING], 0, "the scenario has an enemy heading for the king")
	assert_eq(_row(rows, "To king"), str(by_kind[PendingHits.KIND_KING]), "king")
	assert_eq(_row(rows, "To castle"), str(by_kind[PendingHits.KIND_CASTLE]), "castle")
	assert_eq(_row(rows, "To building"), str(by_kind[PendingHits.KIND_BUILDING]), "building")
	assert_eq(_row(rows, "Marching"), str(by_kind[&""]), "marching")
	var summed: int = 0
	for label: String in ["To king", "To castle", "To building", "Marching"]:
		summed += int(_row(rows, label))
	assert_eq(summed, ctx.get_enemy_count(), "every enemy is counted exactly once")


func test_collecting_the_night_sections_changes_no_state_and_emits_no_events() -> void:
	var ctx: RunContext = _context()
	var spawn: Vector3 = ctx.map.find_spawn_point(WEST).position
	ctx.king.report_position(Vector2(spawn.x + 2.0, spawn.z))
	_start_night(ctx)
	_step_n(ctx, STEPS_AFTER_FIRST_SPAWN)
	var ticks_before: int = ctx.tick_count
	var gold_before: int = ctx.economy.get_gold()
	var king_before: int = ctx.king.get_health()
	var castle_before: int = ctx.castle.get_health()
	var enemies_before: int = ctx.get_enemy_count()
	watch_signals(ctx.events)

	for _i: int in range(READ_ONLY_REPEATS):
		NightOverlaySections.wave_rows(ctx)
		NightOverlaySections.king_rows(ctx)
		NightOverlaySections.path_rows(ctx)

	assert_eq(ctx.tick_count, ticks_before, "no tick ran")
	assert_eq(ctx.economy.get_gold(), gold_before, "gold unchanged")
	assert_eq(ctx.king.get_health(), king_before, "king health unchanged")
	assert_eq(ctx.castle.get_health(), castle_before, "castle health unchanged")
	assert_eq(ctx.get_enemy_count(), enemies_before, "the field is unchanged")
	for signal_name: String in SimSignals.ALL:
		assert_signal_not_emitted(ctx.events, signal_name)


func test_the_loop_section_has_no_timer_row_during_a_real_night_but_keeps_it_at_dawn() -> void:
	var ctx: RunContext = _context()
	var model: DebugOverlayModel = DebugOverlayModel.new(ctx)
	_start_night(ctx)
	_step_n(ctx, STEPS_AFTER_FIRST_SPAWN)

	var night_loop: Dictionary = OverlayTestSupport.section(model.collect(60.0), "Loop")

	assert_eq(OverlayTestSupport.row_value(night_loop, "Phase"), "NIGHT", "a night is running")
	assert_null(OverlayTestSupport.row_value(night_loop, "Timer"), "a real night has no clock")
	assert_eq(ctx.run_manager.get_phase_time_remaining(), 0.0, "and reports no time left")
	assert_false(ctx.run_manager.is_timed_night(), "a map with nights plays real nights")
	_kills_everything_until_dawn(ctx)
	var dawn_loop: Dictionary = OverlayTestSupport.section(model.collect(60.0), "Loop")
	assert_not_null(OverlayTestSupport.row_value(dawn_loop, "Timer"), "dawn still shows its clock")


func test_a_waveless_map_plays_a_timed_night() -> void:
	var ctx: RunContext = _context(E2eSupport.waveless_prototype_map())

	assert_true(ctx.run_manager.is_timed_night(), "no authored nights, so the Phase 1 timed night")
	_start_night(ctx)
	assert_eq(
		ctx.run_manager.get_phase_time_remaining(),
		_tuning.placeholder_night_seconds,
		"and it keeps its clock"
	)


func test_the_overlay_lists_wave_king_and_paths_after_the_defaults_and_earlier_sections() -> void:
	var overlay: DebugOverlay = _overlay()
	overlay.register_section("Early", func() -> Array: return [["A", "1"]])
	overlay.bind_run(_context(), null)

	var text: String = await _shown_text(overlay)

	var lines: PackedStringArray = text.split("\n")
	var order: Array[String] = []
	for line: String in lines:
		if not line.begins_with("  "):
			order.append(line)
	assert_eq(
		order,
		["Perf", "Loop", "Agents", "Early", "Wave", "King", "Paths"] as Array[String],
		"the defaults first, registration order kept, the night sections after them"
	)
