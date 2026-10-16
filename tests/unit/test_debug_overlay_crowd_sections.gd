extends GutTest
## ENMY-04, D-09, ROADMAP success criterion 2 (plan 04-08): the debug overlay's Walls, Field and
## Crowd sections. The Walls rows count built runs and intact and broken segments and give the
## shortest time to breach; the Field rows give the field version, the grid and reached cells, the
## stuck count and the longest stuck streak; the Crowd rows give the frame time and the drawn
## counts. Every row builder is a pure read of getters: collecting them emits no event and builds no
## goal field. A RunContext on the wall fixture, stepped with ctx.step(), no scene tree except for
## the one test that binds a real overlay.

const FIXTURE := "res://tests/fixtures/fixture_map_walls_gap.tres"
const OVERLAY_SCENE := "res://ui/overlay/debug_overlay.tscn"
const RUN: StringName = &"wall_west"
const SEGMENTS: int = 6
const EM_DASH := "—"
const FAR_AWAY := Vector2(-30.0, 0.0)
const STUCK_STEPS: int = 100
const SPAWN_NEVER_S: float = 600.0
const FIVE_GRUNTS_PER_300: int = 100
const READ_ONLY_REPEATS: int = 100
const NEW_LABELS: Array[String] = [
	"Runs built",
	"Segments intact",
	"Segments broken",
	"Walls evaluated",
	"Fastest breach",
	"Field version",
	"Grid cells",
	"Reached cells",
	"Stuck now",
	"Longest stuck",
	"Frame ms",
	"Drawn enemies",
	"Drawn units",
	"Arrows in flight",
]

var _tuning: LoopTuning


func before_each() -> void:
	_tuning = OverlayTestSupport.new_tuning()


func after_each() -> void:
	E2eSupport.release_all_actions()


## The gap fixture with its night pushed 10 minutes out, so the test's own enemy is the only one.
func _context() -> RunContext:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	map.nights[0].groups[0].start_delay_seconds = SPAWN_NEVER_S
	return RunContext.new(map, _tuning, 1)


func _built(ctx: RunContext) -> RunContext:
	assert_eq(ctx.commands.submit(BuildIntent.new(RUN)), CommandProcessor.OK, "the run is bought")
	return ctx


func _step_n(ctx: RunContext, steps: int) -> void:
	for _i: int in range(steps):
		ctx.step()


func _row(rows: Array, label: String) -> Variant:
	return OverlayTestSupport.row_value({"rows": rows}, label)


func _stalled_night(ctx: RunContext) -> int:
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night starts")
	var def: EnemyDef = (load("res://data/enemies/grunt.tres") as EnemyDef).duplicate()
	def.move_speed = 0.0
	var id: int = ctx.night.get_enemies().spawn(def, FAR_AWAY)
	_step_n(ctx, STUCK_STEPS)
	return id


func test_before_any_wall_the_wall_rows_read_zero_and_the_breach_is_a_dash() -> void:
	var rows: Array = CrowdOverlaySections.wall_rows(_context())
	assert_eq(_row(rows, "Runs built"), "0", "nothing bought")
	assert_eq(_row(rows, "Segments intact"), "0", "no segment stands")
	assert_eq(_row(rows, "Segments broken"), "0", "none broke")
	assert_eq(_row(rows, "Walls evaluated"), "0", "nothing evaluated")
	assert_eq(_row(rows, "Fastest breach"), EM_DASH, "no crowd, no breach time")


func test_a_bought_run_counts_its_six_segments_intact() -> void:
	var rows: Array = CrowdOverlaySections.wall_rows(_built(_context()))
	assert_eq(_row(rows, "Runs built"), "1", "one run built")
	assert_eq(_row(rows, "Segments intact"), str(SEGMENTS), "all six stand")
	assert_eq(_row(rows, "Segments broken"), "0", "none broken")


func test_a_broken_segment_moves_from_intact_to_broken() -> void:
	var ctx: RunContext = _built(_context())
	var first: int = ctx.walls.segments_of(RUN)[0]
	ctx.walls.damage_segment(first, ctx.walls.max_health_of(first))
	var rows: Array = CrowdOverlaySections.wall_rows(ctx)
	assert_eq(_row(rows, "Runs built"), "1", "the run is still built")
	assert_eq(_row(rows, "Segments intact"), str(SEGMENTS - 1), "five stand")
	assert_eq(_row(rows, "Segments broken"), "1", "one is a hole")


func test_the_fastest_breach_is_the_shortest_published_time_to_destruction() -> void:
	var ctx: RunContext = _built(_context())
	var decision: WallDecision = ctx.night.get_pathing().decision()
	decision.begin_tick(0)
	decision.add_attacker(0, FIVE_GRUNTS_PER_300)
	decision.end_tick()
	var rows: Array = CrowdOverlaySections.wall_rows(ctx)
	assert_eq(_row(rows, "Walls evaluated"), "1", "one segment weighed")
	assert_eq(_row(rows, "Fastest breach"), "3.0 s", "30 hp against 100 per 10 s is 90 ticks")


func test_the_field_rows_follow_the_castle_field() -> void:
	var ctx: RunContext = _built(_context())
	_step_n(ctx, 1)
	var pathing: Pathing = ctx.night.get_pathing()
	var rows: Array = CrowdOverlaySections.field_rows(ctx)
	assert_eq(_row(rows, "Field version"), str(pathing.field_version()), "the rebuild count")
	assert_gt(int(_row(rows, "Field version")), 0, "the field was built")
	var cells: int = pathing.grid().width() * pathing.grid().height()
	assert_eq(_row(rows, "Grid cells"), str(cells), "the grid")
	assert_eq(_row(rows, "Reached cells"), str(pathing.castle_field().reached_count()), "reached")
	assert_gt(int(_row(rows, "Reached cells")), 0, "the castle can be reached")


func test_without_walls_the_field_rows_read_zero() -> void:
	var rows: Array = CrowdOverlaySections.field_rows(_context())
	assert_eq(_row(rows, "Field version"), "0", "no field yet")
	assert_eq(_row(rows, "Reached cells"), "0", "nothing reached")
	assert_eq(_row(rows, "Stuck now"), "0", "nobody flagged")
	assert_eq(_row(rows, "Longest stuck"), "0.0 s", "no streak")


func test_the_stuck_rows_match_the_tracker() -> void:
	var ctx: RunContext = _context()
	var id: int = _stalled_night(ctx)
	var stuck: StuckTracker = ctx.night.get_pathing().stuck()
	assert_true(stuck.is_stuck(id), "the held enemy is flagged")
	var rows: Array = CrowdOverlaySections.field_rows(ctx)
	assert_eq(_row(rows, "Stuck now"), str(stuck.stuck_count()), "the count")
	var longest: String = "%.1f s" % (float(stuck.longest_streak_ticks()) * SimClock.STEP)
	assert_eq(_row(rows, "Longest stuck"), longest, "the longest streak in seconds")
	assert_ne(longest, "0.0 s", "and it is not zero")


func test_the_crowd_rows_read_a_frame_time_and_dashes_without_a_scene() -> void:
	var rows: Array = CrowdOverlaySections.crowd_rows(_context(), null)
	assert_true(String(_row(rows, "Frame ms")).is_valid_float(), "a number of milliseconds")
	for label: String in ["Drawn enemies", "Drawn units", "Arrows in flight"]:
		assert_eq(_row(rows, label), EM_DASH, "%s has no view to read" % label)


func test_collecting_every_section_emits_nothing_and_builds_no_goal_field() -> void:
	var ctx: RunContext = _built(_context())
	_stalled_night(ctx)
	var pathing: Pathing = ctx.night.get_pathing()
	watch_signals(ctx.events)
	var version_before: int = pathing.field_version()
	var tick_before: int = ctx.tick_count
	for _i: int in range(READ_ONLY_REPEATS):
		assert_false(CrowdOverlaySections.wall_rows(ctx).is_empty(), "walls read")
		assert_false(CrowdOverlaySections.field_rows(ctx).is_empty(), "field reads")
		assert_false(CrowdOverlaySections.crowd_rows(ctx, null).is_empty(), "crowd reads")
	for signal_name: String in SimSignals.ALL:
		assert_signal_not_emitted(ctx.events, signal_name)
	assert_eq(pathing.get("_squad_cache"), null, "no squad goal field was asked for")
	assert_eq(pathing.field_version(), version_before, "the castle field was not rebuilt")
	assert_eq(ctx.tick_count, tick_before, "no tick ran")


func _labels(rows: Array) -> Array[String]:
	var labels: Array[String] = []
	for row: Array in rows:
		labels.append(row[0])
	return labels


func _older_labels(ctx: RunContext) -> Array[String]:
	var labels: Array[String] = []
	for section: Dictionary in DebugOverlayModel.new(ctx).collect(60.0):
		labels.append_array(_labels(section["rows"]))
	labels.append_array(_labels(NightOverlaySections.wave_rows(ctx)))
	labels.append_array(_labels(NightOverlaySections.king_rows(ctx)))
	labels.append_array(_labels(NightOverlaySections.path_rows(ctx)))
	labels.append_array(_labels(SquadOverlaySections.squad_rows(ctx)))
	return labels


func test_the_new_row_labels_are_the_planned_ones_and_unique() -> void:
	var ctx: RunContext = _context()
	var labels: Array[String] = []
	labels.append_array(_labels(CrowdOverlaySections.wall_rows(ctx)))
	labels.append_array(_labels(CrowdOverlaySections.field_rows(ctx)))
	labels.append_array(_labels(CrowdOverlaySections.crowd_rows(ctx, null)))
	assert_eq(labels, NEW_LABELS, "fourteen rows in the planned order")
	var seen: Dictionary = {}
	for label: String in labels:
		seen[label] = true
	assert_eq(seen.size(), labels.size(), "no label repeats inside the new sections")


func test_no_new_label_repeats_a_label_of_the_older_sections() -> void:
	var ctx: RunContext = _context()
	var older: Array[String] = _older_labels(ctx)
	assert_gt(older.size(), 10, "the older sections were read")
	for label: String in NEW_LABELS:
		assert_false(older.has(label), "'%s' is new to the flattened overlay" % label)


func test_the_overlay_lists_the_three_sections_after_the_squads() -> void:
	var ctx: RunContext = _built(_context())
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
	for title: String in ["Walls", "Field", "Crowd"]:
		assert_true(text.contains(title), "the %s section is shown" % title)
	assert_gt(text.find("Walls"), text.find("Squads"), "after the squads")
	assert_gt(text.find("Field"), text.find("Walls"), "Field follows Walls")
	assert_gt(text.find("Crowd"), text.find("Field"), "Crowd follows Field")
	assert_true(text.contains("Segments intact: %d" % SEGMENTS), "and the rows are filled")
