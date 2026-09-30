extends GutTest
## DEV-03: the debug overlay model names each provider problem once per failure streak. A streak
## that turns from one problem into a different one names the new problem too, so a section that
## keeps failing in a new way is never silent.


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
