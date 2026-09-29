extends GutTest
## DEV-03: the debug overlay model is built from registered sections and is strictly read-only.
## Reading it any number of times never changes gold, phase or buildings and never emits an event.

const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const COLLECT_REPEATS: int = 200
const SIM_SIGNALS: Array[String] = [
	"gold_changed", "building_built", "command_rejected", "phase_changed"
]


func _prototype_with_one_house() -> RunContext:
	var ctx: RunContext = RunContext.new(load(PROTOTYPE_MAP), load(TUNING))
	var first_spot: StringName = ctx.buildings.spot_ids()[0]
	var result: StringName = ctx.commands.submit(BuildIntent.new(first_spot))
	assert_eq(result, CommandProcessor.OK, "the setup House is built through the command gate")
	return ctx


func _section(sections: Array, title: String) -> Dictionary:
	for section: Dictionary in sections:
		if section["title"] == title:
			return section
	return {}


func _row_value(section: Dictionary, label: String) -> String:
	for row: Array in section.get("rows", []):
		if row[0] == label:
			return row[1]
	return ""


func _tier_snapshot(ctx: RunContext) -> Array[int]:
	var tiers: Array[int] = []
	for spot_id: StringName in ctx.buildings.spot_ids():
		tiers.append(ctx.buildings.current_tier(spot_id))
	return tiers


func test_unit_and_enemy_counts_are_zero_in_phase_one() -> void:
	var ctx: RunContext = _prototype_with_one_house()
	assert_eq(ctx.get_unit_count(), 0, "no units exist in Phase 1")
	assert_eq(ctx.get_enemy_count(), 0, "no enemies exist in Phase 1")


func test_default_sections_are_perf_loop_agents_in_order() -> void:
	var model: DebugOverlayModel = DebugOverlayModel.new(_prototype_with_one_house())
	var sections: Array = model.collect(60.0)
	var titles: Array[String] = []
	for section: Dictionary in sections:
		titles.append(section["title"])
	assert_eq(titles, ["Perf", "Loop", "Agents"] as Array[String], "default section order")


func test_every_row_is_a_label_value_string_pair() -> void:
	var model: DebugOverlayModel = DebugOverlayModel.new(_prototype_with_one_house())
	var sections: Array = model.collect(60.0)
	assert_false(sections.is_empty(), "collect returns sections")
	for section: Dictionary in sections:
		assert_true(section["rows"].size() > 0, "%s has rows" % section["title"])
		for row: Array in section["rows"]:
			assert_eq(row.size(), 2, "row is [label, value]")
			assert_true(row[0] is String and row[1] is String, "row entries are strings")


func test_default_rows_report_fps_phase_gold_buildings_units_enemies() -> void:
	var ctx: RunContext = _prototype_with_one_house()
	var sections: Array = DebugOverlayModel.new(ctx).collect(59.6)
	assert_eq(_row_value(_section(sections, "Perf"), "FPS"), "60", "FPS is rounded to an integer")
	var loop: Dictionary = _section(sections, "Loop")
	assert_eq(_row_value(loop, "Phase"), "DAY", "phase name comes from the RunPhase keys")
	assert_eq(_row_value(loop, "Gold"), str(ctx.economy.get_gold()), "gold row")
	assert_eq(_row_value(loop, "Buildings"), "1", "one House stands")
	var agents: Dictionary = _section(sections, "Agents")
	assert_eq(_row_value(agents, "Units"), "0", "units row")
	assert_eq(_row_value(agents, "Enemies"), "0", "enemies row")


func test_registered_section_is_appended_last_and_reads_its_provider() -> void:
	var model: DebugOverlayModel = DebugOverlayModel.new(_prototype_with_one_house())
	var provider: Callable = func() -> Array: return [["Wave", "3"]]
	model.register_section("Test", provider)
	var sections: Array = model.collect(60.0)
	assert_eq(sections.size(), 4, "three defaults plus the registered section")
	assert_eq(sections[3]["title"], "Test", "registered sections come after the defaults")
	assert_eq(_row_value(sections[3], "Wave"), "3", "rows come from provider.call()")


func test_registered_sections_keep_registration_order() -> void:
	var model: DebugOverlayModel = DebugOverlayModel.new(_prototype_with_one_house())
	var provider: Callable = func() -> Array: return []
	model.register_section("First", provider)
	model.register_section("Second", provider)
	var sections: Array = model.collect(60.0)
	assert_eq(sections[3]["title"], "First", "first registered")
	assert_eq(sections[4]["title"], "Second", "second registered")


func test_collecting_200_times_changes_no_state_and_emits_no_events() -> void:
	var ctx: RunContext = _prototype_with_one_house()
	var model: DebugOverlayModel = DebugOverlayModel.new(ctx)
	var gold_before: int = ctx.economy.get_gold()
	var phase_before: RunManager.RunPhase = ctx.run_manager.get_phase()
	var tiers_before: Array[int] = _tier_snapshot(ctx)
	assert_false(model.collect(1.0).is_empty(), "the model actually reads something")
	watch_signals(ctx.events)
	for i: int in COLLECT_REPEATS:
		model.collect(float(i))
	assert_eq(ctx.economy.get_gold(), gold_before, "gold unchanged")
	assert_eq(ctx.run_manager.get_phase(), phase_before, "phase unchanged")
	assert_eq(_tier_snapshot(ctx), tiers_before, "every spot's tier unchanged")
	for signal_name: String in SIM_SIGNALS:
		assert_signal_not_emitted(ctx.events, signal_name)


func test_a_freed_section_provider_is_skipped_instead_of_crashing() -> void:
	var model: DebugOverlayModel = DebugOverlayModel.new(_prototype_with_one_house())
	var owner_node: Node = Node.new()
	model.register_section("Ghost", owner_node.get_children)
	model.register_section("Live", func() -> Array: return [["Answer", "42"]])
	owner_node.free()

	var sections: Array = model.collect(60.0)

	assert_eq(_section(sections, "Ghost"), {}, "the invalid provider's section is left out")
	assert_eq(_row_value(_section(sections, "Live"), "Answer"), "42", "valid sections still show")


func test_a_provider_that_returns_a_non_array_is_skipped_instead_of_crashing() -> void:
	var model: DebugOverlayModel = DebugOverlayModel.new(_prototype_with_one_house())
	model.register_section("Null", func() -> Variant: return null)
	model.register_section("Text", func() -> Variant: return "not rows")
	model.register_section("Live", func() -> Array: return [["Answer", "42"]])

	var sections: Array = model.collect(60.0)

	assert_eq(_section(sections, "Null"), {}, "a null return leaves its section out")
	assert_eq(_section(sections, "Text"), {}, "a non-Array return leaves its section out")
	assert_eq(_row_value(_section(sections, "Live"), "Answer"), "42", "valid sections still show")
