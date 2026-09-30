extends GutTest
## DEV-03: the debug overlay model is built from registered sections and is strictly read-only.
## Reading it any number of times never changes gold, phase or buildings and never emits an event.


func _model() -> DebugOverlayModel:
	return DebugOverlayModel.new(OverlayTestSupport.context_with_one_house(self))


func test_unit_and_enemy_counts_are_zero_in_phase_one() -> void:
	var ctx: RunContext = OverlayTestSupport.context_with_one_house(self)
	assert_eq(ctx.get_unit_count(), 0, "no units exist in Phase 1")
	assert_eq(ctx.get_enemy_count(), 0, "no enemies exist in Phase 1")


func test_default_sections_are_perf_loop_agents_in_order() -> void:
	var model: DebugOverlayModel = _model()
	var sections: Array = model.collect(60.0)
	var titles: Array[String] = []
	for section: Dictionary in sections:
		titles.append(section["title"])
	assert_eq(titles, ["Perf", "Loop", "Agents"] as Array[String], "default section order")


func test_every_row_is_a_label_value_string_pair() -> void:
	var model: DebugOverlayModel = _model()
	var sections: Array = model.collect(60.0)
	assert_false(sections.is_empty(), "collect returns sections")
	for section: Dictionary in sections:
		assert_true(section["rows"].size() > 0, "%s has rows" % section["title"])
		for row: Array in section["rows"]:
			assert_eq(row.size(), 2, "row is [label, value]")
			assert_true(row[0] is String and row[1] is String, "row entries are strings")


func test_default_rows_report_fps_phase_gold_buildings_units_enemies() -> void:
	var ctx: RunContext = OverlayTestSupport.context_with_one_house(self)
	var sections: Array = DebugOverlayModel.new(ctx).collect(59.6)
	assert_eq(
		OverlayTestSupport.row_value(OverlayTestSupport.section(sections, "Perf"), "FPS"),
		"60",
		"FPS is rounded to an integer"
	)
	var loop: Dictionary = OverlayTestSupport.section(sections, "Loop")
	assert_eq(
		OverlayTestSupport.row_value(loop, "Phase"),
		"DAY",
		"phase name comes from the RunPhase keys"
	)
	assert_eq(OverlayTestSupport.row_value(loop, "Gold"), str(ctx.economy.get_gold()), "gold row")
	assert_eq(OverlayTestSupport.row_value(loop, "Buildings"), "1", "one House stands")
	var agents: Dictionary = OverlayTestSupport.section(sections, "Agents")
	assert_eq(OverlayTestSupport.row_value(agents, "Units"), "0", "units row")
	assert_eq(OverlayTestSupport.row_value(agents, "Enemies"), "0", "enemies row")


func test_registered_section_is_appended_last_and_reads_its_provider() -> void:
	var model: DebugOverlayModel = _model()
	var provider: Callable = func() -> Array: return [["Wave", "3"]]
	model.register_section("Test", provider)
	var sections: Array = model.collect(60.0)
	assert_eq(sections.size(), 4, "three defaults plus the registered section")
	assert_eq(sections[3]["title"], "Test", "registered sections come after the defaults")
	assert_eq(
		OverlayTestSupport.row_value(sections[3], "Wave"), "3", "rows come from provider.call()"
	)


func test_registered_sections_keep_registration_order() -> void:
	var model: DebugOverlayModel = _model()
	var provider: Callable = func() -> Array: return []
	model.register_section("First", provider)
	model.register_section("Second", provider)
	var sections: Array = model.collect(60.0)
	assert_eq(sections[3]["title"], "First", "first registered")
	assert_eq(sections[4]["title"], "Second", "second registered")


func test_collecting_200_times_changes_no_state_and_emits_no_events() -> void:
	var ctx: RunContext = OverlayTestSupport.context_with_one_house(self)
	var model: DebugOverlayModel = DebugOverlayModel.new(ctx)
	assert_false(model.collect(1.0).is_empty(), "the model actually reads something")

	OverlayTestSupport.assert_collecting_is_read_only(self, ctx, model)


func test_the_watched_signals_are_every_signal_the_simulation_declares() -> void:
	var declared: Array[String] = []
	for info: Dictionary in SimEvents.new().get_script().get_script_signal_list():
		declared.append(info["name"])
	declared.sort()
	var watched: Array[String] = SimSignals.ALL.duplicate()
	watched.sort()

	assert_eq(watched, declared, "a new SimEvents signal must be added to SimSignals.ALL")
