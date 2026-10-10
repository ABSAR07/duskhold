extends GutTest
## DEV-03 extension (plan 03-05): the Squads section of the debug overlay lists each squad in
## creation order with its alive / max, its stance and the seconds to its next replacement, and
## reading it is strictly read-only. A RunContext on the squad fixture, stepped with ctx.step() and
## no scene tree except for the one test that binds a real overlay.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const OVERLAY_SCENE := "res://ui/overlay/debug_overlay.tscn"
const BARRACKS: StringName = &"barracks_1"
const ARCHERY: StringName = &"archery_1"
const EM_DASH := "—"
const BARRACKS_LABEL := "Squad barracks_1"
const ARCHERY_LABEL := "Squad archery_1"
const KILL_DAMAGE: int = 1000
const CRAWL_SPEED: float = 0.001
const STEPS_AFTER_DEATHS: int = 45
const READ_ONLY_REPEATS: int = 100

var _tuning: LoopTuning


func before_each() -> void:
	_tuning = OverlayTestSupport.new_tuning()


func after_each() -> void:
	E2eSupport.release_all_actions()


func _context() -> RunContext:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	for enemy: EnemyDef in map.enemies:
		enemy.move_speed = CRAWL_SPEED
	return RunContext.new(map, _tuning, 1)


func _build(ctx: RunContext, spot: StringName) -> void:
	assert_eq(ctx.commands.submit(BuildIntent.new(spot)), CommandProcessor.OK, "built %s" % spot)


func _step_n(ctx: RunContext, steps: int) -> void:
	for _i: int in range(steps):
		ctx.step()


func _kill(ctx: RunContext, spot: StringName, count: int) -> void:
	var ids: Array[int] = ctx.squads.unit_ids_of(spot)
	for index: int in range(mini(count, ids.size())):
		ctx.squads.damage_unit(ids[index], KILL_DAMAGE, &"test")
	ctx.squads.remove_dead()


func _row(rows: Array, label: String) -> Variant:
	return OverlayTestSupport.row_value({"rows": rows}, label)


func _night_with_two_dead(ctx: RunContext) -> void:
	_build(ctx, BARRACKS)
	_step_n(ctx, 1)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night starts")
	_step_n(ctx, 1)
	_kill(ctx, BARRACKS, 2)
	_step_n(ctx, STEPS_AFTER_DEATHS)


func test_with_no_squad_the_section_shows_one_dash_row() -> void:
	var ctx: RunContext = _context()
	_step_n(ctx, 1)

	var rows: Array = SquadOverlaySections.squad_rows(ctx)

	assert_eq(rows.size(), 1, "one row")
	assert_eq(_row(rows, "Squad"), SquadOverlaySections.NONE_TEXT, "the none dash")
	assert_eq(SquadOverlaySections.NONE_TEXT, EM_DASH, "an em dash like the other sections")


func test_a_tier_one_barracks_reads_4_of_4_at_its_post_with_no_replacement() -> void:
	var ctx: RunContext = _context()
	_build(ctx, BARRACKS)
	_step_n(ctx, 1)

	var rows: Array = SquadOverlaySections.squad_rows(ctx)

	assert_eq(rows.size(), 1, "one squad, one row")
	var value: String = _row(rows, BARRACKS_LABEL)
	assert_true(value.contains("4/4"), "alive / max: %s" % value)
	assert_true(value.contains("post"), "the stance: %s" % value)
	assert_true(value.ends_with(EM_DASH), "no replacement time: %s" % value)


func test_squads_list_in_creation_order() -> void:
	var ctx: RunContext = _context()
	_build(ctx, ARCHERY)
	_step_n(ctx, 1)
	_build(ctx, BARRACKS)
	_step_n(ctx, 1)

	var rows: Array = SquadOverlaySections.squad_rows(ctx)

	assert_eq(rows.size(), 2, "two squads")
	assert_eq(rows[0][0], ARCHERY_LABEL, "the Range was built first")
	assert_eq(rows[1][0], BARRACKS_LABEL, "then the Barracks")


func test_after_two_deaths_at_night_the_row_shows_2_of_4_and_whole_seconds_to_the_next() -> void:
	var ctx: RunContext = _context()
	_night_with_two_dead(ctx)

	var value: String = _row(SquadOverlaySections.squad_rows(ctx), BARRACKS_LABEL)

	assert_true(value.contains("2/4"), "two are up: %s" % value)
	assert_true(value.contains("post"), "still at the post: %s" % value)
	var seconds_left: float = ctx.squads.replacement_seconds_left(BARRACKS)
	var expected: int = ceili(seconds_left - 0.000001)
	assert_gt(expected, 0, "a countdown is running")
	assert_true(value.ends_with("%d s" % expected), "rounded up to whole seconds: %s" % value)


func test_a_rubble_barracks_reads_rubble_instead_of_a_countdown() -> void:
	var ctx: RunContext = _context()
	_night_with_two_dead(ctx)
	ctx.buildings.damage_building(BARRACKS, KILL_DAMAGE)

	var value: String = _row(SquadOverlaySections.squad_rows(ctx), BARRACKS_LABEL)

	assert_true(value.ends_with("rubble"), "a frozen countdown is not shown as time: %s" % value)


func test_seconds_left_is_zero_without_a_countdown_and_for_an_unknown_squad() -> void:
	var ctx: RunContext = _context()
	_build(ctx, BARRACKS)
	_step_n(ctx, 1)

	assert_eq(ctx.squads.replacement_seconds_left(BARRACKS), 0.0, "a full squad runs no countdown")
	assert_eq(ctx.squads.replacement_seconds_left(&"nobody"), 0.0, "an unknown squad has none")


func test_seconds_left_counts_down_with_the_night_steps() -> void:
	var ctx: RunContext = _context()
	_night_with_two_dead(ctx)
	var before: float = ctx.squads.replacement_seconds_left(BARRACKS)

	_step_n(ctx, 30)

	var after: float = ctx.squads.replacement_seconds_left(BARRACKS)
	assert_almost_eq(before - after, 1.0, 0.001, "30 steps are one second")


func test_row_labels_start_with_squad_so_they_cannot_collide_with_other_sections() -> void:
	var ctx: RunContext = _context()
	_build(ctx, BARRACKS)
	_build(ctx, ARCHERY)
	_step_n(ctx, 1)
	var model: DebugOverlayModel = DebugOverlayModel.new(ctx)
	var other_labels: Dictionary = {}
	for section: Dictionary in model.collect(1.0):
		for row: Array in section["rows"]:
			other_labels[row[0]] = true
	for squad_row: Array in SquadOverlaySections.squad_rows(ctx):
		assert_true(str(squad_row[0]).begins_with("Squad"), "%s starts with Squad" % squad_row[0])
		assert_false(other_labels.has(squad_row[0]), "%s is not a default row" % squad_row[0])
	assert_eq(SquadOverlaySections.SQUADS_TITLE, "Squads", "the section title")


func test_reading_the_section_emits_no_event_and_changes_no_state() -> void:
	var ctx: RunContext = _context()
	_night_with_two_dead(ctx)
	var alive: int = ctx.squads.alive_count(BARRACKS)
	var progress: float = ctx.squads.replacement_progress(BARRACKS)
	var ticks: int = ctx.tick_count
	var gold: int = ctx.economy.get_gold()
	watch_signals(ctx.events)

	for _i: int in range(READ_ONLY_REPEATS):
		SquadOverlaySections.squad_rows(ctx)

	for signal_name: String in SimSignals.ALL:
		assert_signal_not_emitted(ctx.events, signal_name)
	assert_eq(ctx.squads.alive_count(BARRACKS), alive, "nobody appeared or fell")
	assert_eq(ctx.squads.replacement_progress(BARRACKS), progress, "the countdown did not move")
	assert_eq(ctx.tick_count, ticks, "no step was run")
	assert_eq(ctx.economy.get_gold(), gold, "no gold moved")


func test_a_bound_overlay_lists_the_squads_section_after_the_night_sections() -> void:
	var ctx: RunContext = _context()
	_build(ctx, BARRACKS)
	_step_n(ctx, 1)
	var overlay: DebugOverlay = (load(OVERLAY_SCENE) as PackedScene).instantiate()
	add_child_autofree(overlay)
	overlay.bind_run(ctx, null)
	await wait_process_frames(1)
	Input.action_press(DebugOverlay.TOGGLE_ACTION)
	await wait_process_frames(2)
	Input.action_release(DebugOverlay.TOGGLE_ACTION)
	await wait_process_frames(1)

	var text: String = overlay.get_text()

	assert_true(text.contains(SquadOverlaySections.SQUADS_TITLE), "the section title is shown")
	assert_true(text.contains(BARRACKS_LABEL), "and the squad row")
	assert_gt(text.find(SquadOverlaySections.SQUADS_TITLE), text.find("Paths"), "after Paths")
