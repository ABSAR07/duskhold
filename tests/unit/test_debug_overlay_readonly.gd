extends GutTest
## DEV-03: the debug overlay model is built from registered sections and is strictly read-only.
## Reading it any number of times never changes gold, phase or buildings and never emits an event.

const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const COLLECT_REPEATS: int = 200
const SIM_SIGNALS: Array[String] = [
	"gold_changed",
	"building_built",
	"command_rejected",
	"phase_changed",
	"night_started",
	"dawn_payout",
	"day_started",
]


func _prototype_with_one_house() -> RunContext:
	# Duplicated like the e2e tests do, so the read-only guarantee is never tested against a shared
	# cached resource that some other test or RunContext wrote to.
	var map: MapConfig = (load(PROTOTYPE_MAP) as MapConfig).duplicate(true)
	var tuning: LoopTuning = (load(TUNING) as LoopTuning).duplicate(true)
	var ctx: RunContext = RunContext.new(map, tuning)
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
	assert_push_warning("debug overlay section 'Ghost' skipped")


func test_a_provider_whose_owner_was_freed_is_dropped_after_its_one_warning() -> void:
	var model: DebugOverlayModel = DebugOverlayModel.new(_prototype_with_one_house())
	var owner_node: Node = Node.new()
	model.register_section("Ghost", owner_node.get_children)
	model.register_section("Live", func() -> Array: return [["Answer", "42"]])
	owner_node.free()
	model.collect(60.0)
	model.collect(60.0)
	assert_push_warning("debug overlay section 'Ghost' skipped: its callable is no longer valid")
	assert_push_warning_count(1, "named once, however often the overlay refreshes")

	# A dropped section is gone, so its title registers as a new section (appended after Live)
	# instead of replacing the dead one in place (which would keep it ahead of Live).
	model.register_section("Ghost", func() -> Array: return [["Back", "yes"]])
	var sections: Array = model.collect(60.0)

	var titles: Array[String] = []
	for section: Dictionary in sections:
		titles.append(section["title"])
	assert_eq(titles, ["Perf", "Loop", "Agents", "Live", "Ghost"], "Ghost re-registered last")
	assert_eq(_row_value(_section(sections, "Ghost"), "Back"), "yes", "and it works again")


func test_a_lambda_that_captured_a_freed_object_is_skipped_when_it_names_that_owner() -> void:
	var model: DebugOverlayModel = DebugOverlayModel.new(_prototype_with_one_house())
	var watched: Node = Node.new()
	# Callable.is_valid() stays true for this lambda after `watched` is freed; only the owner tells.
	var provider: Callable = func() -> Array: return [["Kids", str(watched.get_child_count())]]
	model.register_section("Watched", provider, watched)
	model.register_section("Live", func() -> Array: return [["Answer", "42"]])
	assert_eq(
		_row_value(_section(model.collect(60.0), "Watched"), "Kids"), "0", "shown while alive"
	)
	watched.free()

	var sections: Array = model.collect(60.0)
	model.collect(60.0)

	assert_eq(_section(sections, "Watched"), {}, "the section of a freed owner is left out")
	assert_eq(_row_value(_section(sections, "Live"), "Answer"), "42", "valid sections still show")
	assert_push_warning("debug overlay section 'Watched' skipped: its owner was freed")
	assert_push_warning_count(1, "named once, then dropped")


func test_a_lambda_that_captured_a_live_object_keeps_showing_with_or_without_an_owner() -> void:
	var model: DebugOverlayModel = DebugOverlayModel.new(_prototype_with_one_house())
	var watched: Node = autofree(Node.new())
	var counter: RefCounted = RefCounted.new()
	model.register_section(
		"Owned", func() -> Array: return [["Kids", str(watched.get_child_count())]], watched
	)
	model.register_section("Unowned", func() -> Array: return [["Type", counter.get_class()]])

	var sections: Array = model.collect(60.0)
	sections = model.collect(60.0)

	assert_eq(_row_value(_section(sections, "Owned"), "Kids"), "0", "a live owner is not skipped")
	assert_eq(_row_value(_section(sections, "Unowned"), "Type"), "RefCounted", "no owner, no check")
	assert_push_warning_count(0, "nothing was skipped")


func test_a_provider_that_needs_an_argument_is_skipped_instead_of_crashing() -> void:
	var model: DebugOverlayModel = DebugOverlayModel.new(_prototype_with_one_house())
	model.register_section("Needy", func(wave: int) -> Array: return [["Wave", str(wave)]])
	model.register_section("Live", func() -> Array: return [["Answer", "42"]])

	var sections: Array = model.collect(60.0)

	assert_eq(_section(sections, "Needy"), {}, "a provider needing an argument is left out")
	assert_eq(_row_value(_section(sections, "Live"), "Answer"), "42", "valid sections still show")
	assert_push_warning("debug overlay section 'Needy' skipped")


func test_a_skipped_provider_is_warned_about_once_however_often_the_overlay_refreshes() -> void:
	var model: DebugOverlayModel = DebugOverlayModel.new(_prototype_with_one_house())
	model.register_section(
		"Defaulted", func(verbose: bool = false) -> Array: return [["Verbose", str(verbose)]]
	)

	model.collect(60.0)
	model.collect(60.0)
	model.collect(60.0)

	assert_push_warning("debug overlay section 'Defaulted' skipped")
	assert_push_warning_count(1, "one warning, not one per refresh")


func test_replacing_a_warned_provider_lets_the_new_one_warn_again() -> void:
	var model: DebugOverlayModel = DebugOverlayModel.new(_prototype_with_one_house())
	model.register_section("Wave", func(wave: int) -> Array: return [["Wave", str(wave)]])
	model.collect(60.0)

	model.register_section("Wave", func() -> Variant: return null)
	model.collect(60.0)
	model.collect(60.0)

	assert_push_warning("debug overlay section 'Wave' skipped: it declares parameters")
	assert_push_warning("debug overlay section 'Wave' skipped: it returned Nil")
	assert_push_warning_count(2, "one warning per provider, however often the overlay refreshes")


func test_a_provider_that_returns_a_non_array_is_skipped_instead_of_crashing() -> void:
	var model: DebugOverlayModel = DebugOverlayModel.new(_prototype_with_one_house())
	model.register_section("Null", func() -> Variant: return null)
	model.register_section("Text", func() -> Variant: return "not rows")
	model.register_section("Live", func() -> Array: return [["Answer", "42"]])

	var sections: Array = model.collect(60.0)

	assert_eq(_section(sections, "Null"), {}, "a null return leaves its section out")
	assert_eq(_section(sections, "Text"), {}, "a non-Array return leaves its section out")
	assert_eq(_row_value(_section(sections, "Live"), "Answer"), "42", "valid sections still show")
	assert_push_warning("debug overlay section 'Null' skipped: it returned Nil, not an Array")
	assert_push_warning("debug overlay section 'Text' skipped: it returned String, not an Array")
	assert_push_warning_count(2, "each non-Array provider is named once")


func test_a_flapping_provider_warns_again_after_it_recovers() -> void:
	var model: DebugOverlayModel = DebugOverlayModel.new(_prototype_with_one_house())
	var healthy: Array = [false]
	model.register_section(
		"Flap", func() -> Variant: return [["Wave", "3"]] if healthy[0] else null
	)

	model.collect(60.0)
	model.collect(60.0)
	healthy[0] = true
	model.collect(60.0)
	healthy[0] = false
	model.collect(60.0)
	model.collect(60.0)

	assert_push_warning("debug overlay section 'Flap' skipped: it returned Nil")
	assert_push_warning_count(2, "once per failure streak, not once per refresh or once ever")


func test_a_provider_with_malformed_rows_keeps_only_the_well_formed_ones() -> void:
	var model: DebugOverlayModel = DebugOverlayModel.new(_prototype_with_one_house())
	model.register_section("Flat", func() -> Array: return ["Wave", "3"])
	model.register_section(
		"Mixed", func() -> Array: return [["Short"], 7, ["Answer", 42], ["Wide", "1", "extra"]]
	)

	var sections: Array = model.collect(60.0)
	model.collect(60.0)
	model.collect(60.0)

	assert_eq(_section(sections, "Flat")["rows"], [], "a flat pair has no [label, value] rows")
	var mixed: Dictionary = _section(sections, "Mixed")
	assert_eq(mixed["rows"].size(), 2, "the short row and the non-Array row are dropped")
	assert_eq(_row_value(mixed, "Answer"), "42", "a non-String value is turned into text")
	assert_eq(_row_value(mixed, "Wide"), "1", "extra entries beyond label and value are ignored")
	assert_push_warning("debug overlay section 'Flat' dropped 2 malformed row(s)")
	assert_push_warning("debug overlay section 'Mixed' dropped 2 malformed row(s)")
	assert_push_warning_count(2, "each provider is named once, not on every refresh")


func test_the_watched_signals_are_every_signal_the_simulation_declares() -> void:
	var declared: Array[String] = []
	for info: Dictionary in SimEvents.new().get_script().get_script_signal_list():
		declared.append(info["name"])
	declared.sort()
	var watched: Array[String] = SIM_SIGNALS.duplicate()
	watched.sort()

	assert_eq(watched, declared, "a new SimEvents signal must be added to SIM_SIGNALS")


func test_registering_a_default_section_title_is_refused_instead_of_showing_it_twice() -> void:
	var model: DebugOverlayModel = DebugOverlayModel.new(_prototype_with_one_house())

	for title: String in DebugOverlayModel.DEFAULT_TITLES:
		model.register_section(title, func() -> Array: return [["Rogue", "1"]])
		assert_push_warning("debug overlay section '%s' not registered" % title)

	var titles: Array[String] = []
	for section: Dictionary in model.collect(60.0):
		titles.append(section["title"])
	assert_eq(titles, ["Perf", "Loop", "Agents"] as Array[String], "each default shows once")
	assert_eq(_row_value(_section(model.collect(60.0), "Loop"), "Rogue"), "", "the built-in rows")


func test_registering_a_title_twice_replaces_the_section_instead_of_duplicating_it() -> void:
	var model: DebugOverlayModel = DebugOverlayModel.new(_prototype_with_one_house())
	model.register_section("Wave", func() -> Array: return [["Wave", "1"]])
	model.register_section("Other", func() -> Array: return [["Answer", "42"]])

	model.register_section("Wave", func() -> Array: return [["Wave", "2"]])

	var titles: Array[String] = []
	for section: Dictionary in model.collect(60.0):
		titles.append(section["title"])
	assert_eq(titles.count("Wave"), 1, "the section is listed once")
	assert_eq(titles.slice(-2), ["Wave", "Other"] as Array[String], "in its original position")
	assert_eq(_row_value(_section(model.collect(60.0), "Wave"), "Wave"), "2", "the newer provider")
