extends GutTest
## DEV-03: the debug overlay model's registered sections. A provider that cannot be called, or that
## returns something other than rows, is skipped or trimmed instead of raising a script error on
## every refresh, and each problem is named once per failure streak. A streak that turns from one
## problem into a different one names the new problem too, so a section that keeps failing in a new
## way is never silent.


func _model() -> DebugOverlayModel:
	return DebugOverlayModel.new(OverlayTestSupport.context_with_one_house(self))


func test_a_provider_whose_problem_changes_within_one_streak_is_named_again() -> void:
	var model: DebugOverlayModel = _model()
	var rows: Array = [[["Short"], ["Wave", "3"]]]
	model.register_section("Shifty", func() -> Variant: return rows[0])

	model.collect(60.0)
	model.collect(60.0)
	rows[0] = null
	model.collect(60.0)
	model.collect(60.0)
	rows[0] = "not rows"
	model.collect(60.0)
	model.collect(60.0)

	assert_push_warning("debug overlay section 'Shifty' dropped 1 malformed row(s)")
	assert_push_warning("debug overlay section 'Shifty' skipped: it returned Nil, not an Array")
	assert_push_warning("debug overlay section 'Shifty' skipped: it returned String, not an Array")
	assert_push_warning_count(3, "one warning per distinct problem, not per refresh")


func test_the_count_of_malformed_rows_changing_is_not_a_new_problem() -> void:
	var model: DebugOverlayModel = _model()
	var rows: Array = [[["Short"], ["Wave", "3"]]]
	model.register_section("Counted", func() -> Variant: return rows[0])

	model.collect(60.0)
	rows[0] = [["Short"], 7, ["Wave", "3"]]
	model.collect(60.0)

	assert_push_warning("debug overlay section 'Counted' dropped 1 malformed row(s)")
	assert_push_warning_count(1, "still the same problem, so still one warning")


func test_every_skip_code_except_none_has_a_message() -> void:
	# collect() looks the message up by code on every refresh, so a code without one would raise a
	# script error there instead of naming the skipped section.
	for code_name: String in DebugOverlayModel.Skip.keys():
		var code: int = DebugOverlayModel.Skip[code_name]
		if code == DebugOverlayModel.Skip.NONE:
			continue
		assert_true(DebugOverlayModel.SKIP_MESSAGES.has(code), "%s has a message" % code_name)


func test_a_freed_section_provider_is_skipped_instead_of_crashing() -> void:
	var model: DebugOverlayModel = _model()
	var owner_node: Node = Node.new()
	model.register_section("Ghost", owner_node.get_children)
	model.register_section("Live", func() -> Array: return [["Answer", "42"]])
	owner_node.free()

	var sections: Array = model.collect(60.0)

	assert_eq(
		OverlayTestSupport.section(sections, "Ghost"),
		{},
		"the invalid provider's section is left out"
	)
	assert_eq(
		OverlayTestSupport.row_value(OverlayTestSupport.section(sections, "Live"), "Answer"),
		"42",
		"valid sections still show"
	)
	assert_push_warning("debug overlay section 'Ghost' skipped")


func test_a_provider_with_an_invalid_callable_is_dropped_after_its_one_warning() -> void:
	var model: DebugOverlayModel = _model()
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
	assert_eq(
		OverlayTestSupport.row_value(OverlayTestSupport.section(sections, "Ghost"), "Back"),
		"yes",
		"and it works again"
	)


func test_a_lambda_that_captured_a_freed_object_is_skipped_when_it_names_that_owner() -> void:
	var model: DebugOverlayModel = _model()
	var watched: Node = Node.new()
	# Callable.is_valid() stays true for this lambda after `watched` is freed; only the owner tells.
	var provider: Callable = func() -> Array: return [["Kids", str(watched.get_child_count())]]
	model.register_section("Watched", provider, watched)
	model.register_section("Live", func() -> Array: return [["Answer", "42"]])
	assert_eq(
		OverlayTestSupport.row_value(
			OverlayTestSupport.section(model.collect(60.0), "Watched"), "Kids"
		),
		"0",
		"shown while alive"
	)
	watched.free()

	var sections: Array = model.collect(60.0)
	model.collect(60.0)

	assert_eq(
		OverlayTestSupport.section(sections, "Watched"),
		{},
		"the section of a freed owner is left out"
	)
	assert_eq(
		OverlayTestSupport.row_value(OverlayTestSupport.section(sections, "Live"), "Answer"),
		"42",
		"valid sections still show"
	)
	assert_push_warning("debug overlay section 'Watched' skipped: its owner was freed")
	assert_push_warning_count(1, "named once, then dropped")


func test_a_lambda_that_captured_a_live_object_keeps_showing_with_or_without_an_owner() -> void:
	var model: DebugOverlayModel = _model()
	var watched: Node = autofree(Node.new())
	var counter: RefCounted = RefCounted.new()
	model.register_section(
		"Owned", func() -> Array: return [["Kids", str(watched.get_child_count())]], watched
	)
	model.register_section("Unowned", func() -> Array: return [["Type", counter.get_class()]])

	var sections: Array = model.collect(60.0)
	sections = model.collect(60.0)

	assert_eq(
		OverlayTestSupport.row_value(OverlayTestSupport.section(sections, "Owned"), "Kids"),
		"0",
		"a live owner is not skipped"
	)
	assert_eq(
		OverlayTestSupport.row_value(OverlayTestSupport.section(sections, "Unowned"), "Type"),
		"RefCounted",
		"no owner, no check"
	)
	assert_push_warning_count(0, "nothing was skipped")


func test_a_provider_that_needs_an_argument_is_skipped_instead_of_crashing() -> void:
	var model: DebugOverlayModel = _model()
	model.register_section("Needy", func(wave: int) -> Array: return [["Wave", str(wave)]])
	model.register_section("Live", func() -> Array: return [["Answer", "42"]])

	var sections: Array = model.collect(60.0)

	assert_eq(
		OverlayTestSupport.section(sections, "Needy"),
		{},
		"a provider needing an argument is left out"
	)
	assert_eq(
		OverlayTestSupport.row_value(OverlayTestSupport.section(sections, "Live"), "Answer"),
		"42",
		"valid sections still show"
	)
	assert_push_warning("debug overlay section 'Needy' skipped")


func test_a_skipped_provider_is_warned_about_once_however_often_the_overlay_refreshes() -> void:
	var model: DebugOverlayModel = _model()
	model.register_section(
		"Defaulted", func(verbose: bool = false) -> Array: return [["Verbose", str(verbose)]]
	)

	model.collect(60.0)
	model.collect(60.0)
	model.collect(60.0)

	assert_push_warning("debug overlay section 'Defaulted' skipped")
	assert_push_warning_count(1, "one warning, not one per refresh")


func test_replacing_a_warned_provider_lets_the_new_one_warn_again() -> void:
	var model: DebugOverlayModel = _model()
	model.register_section("Wave", func(wave: int) -> Array: return [["Wave", str(wave)]])
	model.collect(60.0)

	model.register_section("Wave", func() -> Variant: return null)
	model.collect(60.0)
	model.collect(60.0)

	assert_push_warning("debug overlay section 'Wave' skipped: it declares parameters")
	assert_push_warning("debug overlay section 'Wave' skipped: it returned Nil")
	assert_push_warning_count(2, "one warning per provider, however often the overlay refreshes")


func test_a_provider_that_returns_a_non_array_is_skipped_instead_of_crashing() -> void:
	var model: DebugOverlayModel = _model()
	model.register_section("Null", func() -> Variant: return null)
	model.register_section("Text", func() -> Variant: return "not rows")
	model.register_section("Live", func() -> Array: return [["Answer", "42"]])

	var sections: Array = model.collect(60.0)

	assert_eq(
		OverlayTestSupport.section(sections, "Null"), {}, "a null return leaves its section out"
	)
	assert_eq(
		OverlayTestSupport.section(sections, "Text"),
		{},
		"a non-Array return leaves its section out"
	)
	assert_eq(
		OverlayTestSupport.row_value(OverlayTestSupport.section(sections, "Live"), "Answer"),
		"42",
		"valid sections still show"
	)
	assert_push_warning("debug overlay section 'Null' skipped: it returned Nil, not an Array")
	assert_push_warning("debug overlay section 'Text' skipped: it returned String, not an Array")
	assert_push_warning_count(2, "each non-Array provider is named once")


func test_a_flapping_provider_warns_again_after_it_recovers() -> void:
	var model: DebugOverlayModel = _model()
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
	var model: DebugOverlayModel = _model()
	model.register_section("Flat", func() -> Array: return ["Wave", "3"])
	model.register_section(
		"Mixed", func() -> Array: return [["Short"], 7, ["Answer", 42], ["Wide", "1", "extra"]]
	)

	var sections: Array = model.collect(60.0)
	model.collect(60.0)
	model.collect(60.0)

	assert_eq(
		OverlayTestSupport.section(sections, "Flat")["rows"],
		[],
		"a flat pair has no [label, value] rows"
	)
	var mixed: Dictionary = OverlayTestSupport.section(sections, "Mixed")
	assert_eq(mixed["rows"].size(), 1, "the short, non-Array and over-long rows are dropped")
	assert_eq(
		OverlayTestSupport.row_value(mixed, "Answer"),
		"42",
		"a non-String value is turned into text"
	)
	assert_null(
		OverlayTestSupport.row_value(mixed, "Wide"),
		"a row with entries beyond label and value is dropped, not truncated"
	)
	assert_push_warning("debug overlay section 'Flat' dropped 2 malformed row(s)")
	assert_push_warning("debug overlay section 'Mixed' dropped 3 malformed row(s)")
	assert_push_warning_count(2, "each provider is named once, not on every refresh")


func test_registering_a_default_section_title_is_refused_instead_of_showing_it_twice() -> void:
	var model: DebugOverlayModel = _model()

	for title: String in DebugOverlayModel.DEFAULT_TITLES:
		model.register_section(title, func() -> Array: return [["Rogue", "1"]])
		assert_push_warning("debug overlay section '%s' not registered" % title)

	var titles: Array[String] = []
	for section: Dictionary in model.collect(60.0):
		titles.append(section["title"])
	assert_eq(titles, ["Perf", "Loop", "Agents"] as Array[String], "each default shows once")
	assert_null(
		OverlayTestSupport.row_value(
			OverlayTestSupport.section(model.collect(60.0), "Loop"), "Rogue"
		),
		"the built-in rows"
	)


func test_registering_a_title_twice_replaces_the_section_instead_of_duplicating_it() -> void:
	var model: DebugOverlayModel = _model()
	model.register_section("Wave", func() -> Array: return [["Wave", "1"]])
	model.register_section("Other", func() -> Array: return [["Answer", "42"]])

	model.register_section("Wave", func() -> Array: return [["Wave", "2"]])

	var titles: Array[String] = []
	for section: Dictionary in model.collect(60.0):
		titles.append(section["title"])
	assert_eq(titles.count("Wave"), 1, "the section is listed once")
	assert_eq(titles.slice(-2), ["Wave", "Other"] as Array[String], "in its original position")
	assert_eq(
		OverlayTestSupport.row_value(
			OverlayTestSupport.section(model.collect(60.0), "Wave"), "Wave"
		),
		"2",
		"the newer provider"
	)


func test_a_section_whose_owner_was_already_freed_is_refused_with_a_warning() -> void:
	var model: DebugOverlayModel = _model()
	var gone: Node = Node.new()
	gone.free()

	# The owner is a Variant parameter, so this raises no script error in this frame.
	model.register_section("Late", func() -> Array: return [["Answer", "42"]], gone)
	model.register_section("Live", func() -> Array: return [["Answer", "42"]])

	var sections: Array = model.collect(60.0)
	assert_eq(OverlayTestSupport.section(sections, "Late"), {}, "the refused section never shows")
	assert_eq(
		OverlayTestSupport.row_value(OverlayTestSupport.section(sections, "Live"), "Answer"), "42"
	)
	assert_push_warning("debug overlay section 'Late' not registered: its owner was freed")
	assert_push_warning_count(1, "named once at registration, not on every refresh")


func test_a_section_whose_owner_is_not_an_object_is_refused_as_such_not_as_freed() -> void:
	var model: DebugOverlayModel = _model()

	model.register_section("Number", func() -> Array: return [["Answer", "42"]], 5)
	model.register_section("Text", func() -> Array: return [["Answer", "42"]], "owner")

	var sections: Array = model.collect(60.0)
	assert_eq(OverlayTestSupport.section(sections, "Number"), {}, "an int owner is refused")
	assert_eq(OverlayTestSupport.section(sections, "Text"), {}, "and so is a String owner")
	assert_push_warning("debug overlay section 'Number' not registered: its owner is not an Object")
	assert_push_warning("debug overlay section 'Text' not registered: its owner is not an Object")
	assert_push_warning_count(2, "each refusal is named once, and none says the owner was freed")
