extends GutTest
## DEV-03: DebugOverlay.register_section works whatever the bind order, and bind_run is idempotent.
## Nodes in the run_bound group are bound in no guaranteed order, so a Phase 2 caller can register
## its section before the overlay is bound, or bind the overlay twice; neither may lose a section.

const OVERLAY_SCENE := "res://ui/overlay/debug_overlay.tscn"
## Synthetic frames for the cadence test: two seconds at 60 fps, driven without waiting.
const SIMULATED_FPS: int = 60
const SIMULATED_FRAMES: int = 120


func after_each() -> void:
	E2eSupport.release_all_actions()


func _context() -> RunContext:
	return RunContext.new(OverlayTestSupport.new_map(), OverlayTestSupport.new_tuning())


func _overlay() -> DebugOverlay:
	var overlay: DebugOverlay = (load(OVERLAY_SCENE) as PackedScene).instantiate()
	add_child_autofree(overlay)
	return overlay


## A provider that counts its calls in `calls[0]` (an Array, so the lambda can write it).
func _counting_provider(calls: Array[int]) -> Callable:
	return func() -> Array:
		calls[0] += 1
		return [["n", str(calls[0])]]


## Shows the overlay the way the player does, by pressing the toggle action. Showing it refreshes it
## at once, so the text is current after a couple of frames and no refresh interval is waited on.
## The leading frame lets the overlay run its first _process before the press.
func _shown_text(overlay: DebugOverlay) -> String:
	await wait_process_frames(1)
	Input.action_press(DebugOverlay.TOGGLE_ACTION)
	await wait_process_frames(2)
	Input.action_release(DebugOverlay.TOGGLE_ACTION)
	await wait_process_frames(1)
	assert_true(overlay.is_overlay_visible(), "the toggle action shows the overlay")
	return overlay.get_text()


func test_a_section_registered_before_bind_run_shows_once_the_overlay_is_bound() -> void:
	var overlay: DebugOverlay = _overlay()
	overlay.register_section("Early", func() -> Array: return [["Wave", "3"]])

	overlay.bind_run(_context(), null)

	var text: String = await _shown_text(overlay)
	assert_string_contains(text, "Early", "the early section's title is listed")
	assert_string_contains(text, "Wave: 3", "and its provider's rows")
	assert_string_contains(text, "Phase: DAY", "next to the default rows")


func test_sections_registered_before_and_after_bind_run_keep_registration_order() -> void:
	var overlay: DebugOverlay = _overlay()
	overlay.register_section("First", func() -> Array: return [["A", "1"]])
	overlay.register_section("Second", func() -> Array: return [["B", "2"]])
	overlay.bind_run(_context(), null)
	overlay.register_section("Third", func() -> Array: return [["C", "3"]])

	var text: String = await _shown_text(overlay)

	var first: int = text.find("First")
	var second: int = text.find("Second")
	var third: int = text.find("Third")
	assert_true(first > -1, "First is listed")
	assert_true(first < second and second < third, "in the order they were registered")


func test_a_second_bind_run_keeps_the_sections_registered_so_far() -> void:
	var overlay: DebugOverlay = _overlay()
	var ctx: RunContext = _context()
	overlay.bind_run(ctx, null)
	overlay.register_section("Kept", func() -> Array: return [["Wave", "3"]])

	overlay.bind_run(ctx, null)

	var text: String = await _shown_text(overlay)
	assert_string_contains(text, "Kept", "a repeat bind_run does not discard the section")
	assert_string_contains(text, "Wave: 3", "or its rows")
	assert_push_warning_count(0, "and binding the same run again is not a mistake")


func test_a_repeat_bind_run_with_another_context_warns_and_keeps_reading_the_first_run() -> void:
	var overlay: DebugOverlay = _overlay()
	var first: RunContext = _context()
	var second: RunContext = _context()
	first.economy.grant(7)
	second.economy.grant(99)
	overlay.bind_run(first, null)
	overlay.register_section("Kept", func() -> Array: return [["Wave", "3"]])

	overlay.bind_run(second, null)

	assert_push_warning(DebugOverlay.REBIND_IGNORED_WARNING)
	var text: String = await _shown_text(overlay)
	assert_string_contains(text, "Gold: %d" % first.economy.get_gold(), "the first run is read")
	assert_false(text.contains("Gold: %d" % second.economy.get_gold()), "and the second run is not")
	assert_string_contains(text, "Wave: 3", "the registered section survives")


func test_bind_run_with_no_context_warns_and_leaves_the_overlay_free_to_bind_properly() -> void:
	var overlay: DebugOverlay = _overlay()
	overlay.register_section("Kept", func() -> Array: return [["Wave", "3"]])

	overlay.bind_run(null, null)

	assert_push_warning(DebugOverlay.NO_CONTEXT_WARNING)
	var ctx: RunContext = _context()
	ctx.economy.grant(7)
	overlay.bind_run(ctx, null)
	var text: String = await _shown_text(overlay)
	assert_string_contains(
		text, "Gold: %d" % ctx.economy.get_gold(), "the later bind reads its run"
	)
	assert_string_contains(text, "Wave: 3", "and the section registered before it survives")
	assert_push_warning_count(1, "the refused bind is the only warning")


func test_a_pending_section_whose_owner_died_before_bind_run_is_left_out_with_a_warning() -> void:
	var overlay: DebugOverlay = _overlay()
	var watched: Node = Node.new()
	overlay.register_section(
		"Ghost", func() -> Array: return [["Kids", str(watched.get_child_count())]], watched
	)
	overlay.register_section("Live", func() -> Array: return [["Answer", "42"]])
	watched.free()

	overlay.bind_run(_context(), null)

	var text: String = await _shown_text(overlay)
	assert_false(text.contains("Ghost"), "the freed owner's section is left out")
	assert_string_contains(text, "Answer: 42", "the other pending section still shows")
	assert_push_warning(
		"debug overlay section 'Ghost' not registered: its owner was freed before bind_run"
	)
	assert_push_warning_count(1, "the freed owner is named once")


func test_a_pending_section_whose_owner_is_freed_after_bind_run_is_dropped_with_a_warning() -> void:
	var overlay: DebugOverlay = _overlay()
	var watched: Node = Node.new()
	overlay.register_section(
		"Watched", func() -> Array: return [["Kids", str(watched.get_child_count())]], watched
	)
	overlay.register_section("Live", func() -> Array: return [["Answer", "42"]])
	overlay.bind_run(_context(), null)
	var before: String = await _shown_text(overlay)
	assert_string_contains(before, "Kids: 0", "the section shows while its owner is alive")

	watched.free()
	# One refresh interval of synthetic time, so the refresh runs without a real-time wait.
	overlay._process(DebugOverlay.REFRESH_INTERVAL_S)

	var after: String = overlay.get_text()
	assert_false(after.contains("Watched"), "the section ends once its owner is freed")
	assert_string_contains(after, "Answer: 42", "and the other pending section still shows")
	assert_push_warning("debug overlay section 'Watched' skipped: its owner was freed")
	assert_push_warning_count(1, "the freed owner is named once, not on every refresh")


func test_binding_an_overlay_that_is_already_shown_fills_it_at_once() -> void:
	var overlay: DebugOverlay = _overlay()
	overlay.register_section("Early", func() -> Array: return [["Wave", "3"]])
	await wait_process_frames(1)
	Input.action_press(DebugOverlay.TOGGLE_ACTION)
	await wait_process_frames(2)
	Input.action_release(DebugOverlay.TOGGLE_ACTION)
	await wait_process_frames(1)
	assert_true(overlay.is_overlay_visible(), "the overlay was shown before it was bound")
	assert_eq(overlay.get_text(), "", "with no run to read, it has nothing to show yet")

	overlay.bind_run(_context(), null)

	# No frames or refresh interval are waited on: the bind itself fills the label.
	assert_string_contains(overlay.get_text(), "Phase: DAY", "the default rows show at once")
	assert_string_contains(
		overlay.get_text(), "Wave: 3", "and so does the section registered early"
	)


func test_a_shown_overlay_refreshes_once_the_interval_has_passed_and_not_before() -> void:
	var overlay: DebugOverlay = _overlay()
	var calls: Array[int] = [0]
	overlay.register_section("Count", _counting_provider(calls))
	overlay.bind_run(_context(), null)
	overlay.visible = true

	overlay._process(DebugOverlay.REFRESH_INTERVAL_S * 0.8)
	assert_eq(calls[0], 0, "less than one interval has passed: no refresh yet")
	overlay._process(DebugOverlay.REFRESH_INTERVAL_S * 0.4)
	assert_eq(calls[0], 1, "the interval has now passed: one refresh")
	overlay._process(DebugOverlay.REFRESH_INTERVAL_S * 0.8)
	assert_eq(calls[0], 1, "the timer restarted at the refresh: no second one yet")


func test_a_shown_overlay_refreshes_about_four_times_a_second_and_a_hidden_one_never() -> void:
	var overlay: DebugOverlay = _overlay()
	var calls: Array[int] = [0]
	overlay.register_section("Count", _counting_provider(calls))
	overlay.bind_run(_context(), null)

	for frame: int in SIMULATED_FRAMES:
		overlay._process(1.0 / float(SIMULATED_FPS))
	assert_eq(calls[0], 0, "a hidden overlay does not refresh")

	overlay.visible = true
	for frame: int in SIMULATED_FRAMES:
		overlay._process(1.0 / float(SIMULATED_FPS))
	# Two simulated seconds at 60 fps: 8 refreshes at a 0.25 s interval, 1 either way for rounding.
	assert_between(calls[0], 7, 9, "about 4 refreshes per second, not one per frame")


func test_a_pending_section_replaced_before_bind_run_does_not_warn_about_the_old_owner() -> void:
	var overlay: DebugOverlay = _overlay()
	var old_owner: Node = Node.new()
	overlay.register_section(
		"Wave", func() -> Array: return [["Old", str(old_owner.get_child_count())]], old_owner
	)
	old_owner.free()
	overlay.register_section("Wave", func() -> Array: return [["Wave", "4"]])

	overlay.bind_run(_context(), null)

	var text: String = await _shown_text(overlay)
	assert_string_contains(text, "Wave: 4", "the replacement's rows show")
	assert_false(text.contains("Old:"), "and the replaced provider's rows do not")
	assert_push_warning_count(0, "the freed owner belonged to a section that was replaced")


func test_a_pending_section_replaced_before_bind_run_keeps_its_place_in_the_order() -> void:
	var overlay: DebugOverlay = _overlay()
	overlay.register_section("First", func() -> Array: return [["A", "1"]])
	overlay.register_section("Second", func() -> Array: return [["B", "2"]])
	overlay.register_section("Third", func() -> Array: return [["C", "3"]])
	overlay.register_section("Second", func() -> Array: return [["B", "22"]])
	overlay.bind_run(_context(), null)

	var text: String = await _shown_text(overlay)

	assert_string_contains(text, "B: 22", "the replacement's rows show")
	assert_eq(text.count("Second"), 1, "the section is listed once")
	var first: int = text.find("First")
	var second: int = text.find("Second")
	var third: int = text.find("Third")
	assert_true(first > -1 and first < second and second < third, "in its original position")


func test_a_refused_pending_replacement_leaves_the_registered_section_alone() -> void:
	var overlay: DebugOverlay = _overlay()
	var gone: Node = Node.new()
	gone.free()
	overlay.register_section("Wave", func() -> Array: return [["Wave", "3"]])

	overlay.register_section("Wave", func() -> Array: return [["Wave", "9"]], gone)

	assert_push_warning("debug overlay section 'Wave' not registered: its owner was freed")
	overlay.bind_run(_context(), null)
	var text: String = await _shown_text(overlay)
	assert_string_contains(text, "Wave: 3", "the earlier registration still stands")


func test_a_section_registered_with_an_already_freed_owner_is_refused_before_and_after_bind_run(
) -> void:
	var overlay: DebugOverlay = _overlay()
	var gone: Node = Node.new()
	gone.free()

	overlay.register_section("Early", func() -> Array: return [["Wave", "3"]], gone)
	overlay.bind_run(_context(), null)
	overlay.register_section("Late", func() -> Array: return [["Wave", "4"]], gone)

	var text: String = await _shown_text(overlay)
	assert_false(text.contains("Early") or text.contains("Late"), "neither section is listed")
	assert_push_warning("debug overlay section 'Early' not registered: its owner was freed")
	assert_push_warning("debug overlay section 'Late' not registered: its owner was freed")
	assert_push_warning_count(2, "each refusal is named once")


func test_an_owner_that_is_not_an_object_is_refused_before_and_after_bind_run_as_such() -> void:
	var overlay: DebugOverlay = _overlay()

	overlay.register_section("Early", func() -> Array: return [["Wave", "3"]], 5)
	overlay.bind_run(_context(), null)
	overlay.register_section("Late", func() -> Array: return [["Wave", "4"]], "owner")

	var text: String = await _shown_text(overlay)
	assert_false(text.contains("Early") or text.contains("Late"), "neither section is listed")
	assert_push_warning("debug overlay section 'Early' not registered: its owner is not an Object")
	assert_push_warning("debug overlay section 'Late' not registered: its owner is not an Object")
	assert_push_warning_count(2, "each refusal is named once, and none says the owner was freed")


func test_a_default_title_is_refused_at_once_before_bind_run_and_never_buffered() -> void:
	var overlay: DebugOverlay = _overlay()

	overlay.register_section("Perf", func() -> Array: return [["Shadow", "1"]])

	# Refused when it is registered, not later when bind_run would replay it.
	assert_push_warning(
		"debug overlay section 'Perf' not registered: the title is a default section"
	)
	overlay.bind_run(_context(), null)
	var text: String = await _shown_text(overlay)
	assert_false(text.contains("Shadow"), "the refused section never shows")
	assert_eq(text.count("Perf"), 1, "and the default Perf section is listed once")
	assert_push_warning_count(1, "the refusal is named once, not again at bind_run")


func test_a_default_title_is_refused_the_same_way_after_bind_run() -> void:
	var overlay: DebugOverlay = _overlay()
	overlay.bind_run(_context(), null)

	overlay.register_section("Loop", func() -> Array: return [["Shadow", "1"]])

	assert_push_warning(
		"debug overlay section 'Loop' not registered: the title is a default section"
	)
	var text: String = await _shown_text(overlay)
	assert_false(text.contains("Shadow"), "the refused section never shows")
	assert_push_warning_count(1, "the refusal is named once")


func test_get_text_before_the_overlay_is_in_the_tree_is_empty_instead_of_a_script_error() -> void:
	# instantiate() without add_child: the @onready label does not exist yet.
	var overlay: DebugOverlay = autofree((load(OVERLAY_SCENE) as PackedScene).instantiate())

	assert_eq(overlay.get_text(), "", "there is no text to read before the overlay is ready")


func test_register_section_does_not_name_a_parameter_after_the_node_owner_property() -> void:
	# `owner` would shadow Node.owner on the CanvasLayer; the model keeps the same name as the view.
	for script: GDScript in [DebugOverlay, DebugOverlayModel]:
		var arg_names: Array[String] = []
		for method: Dictionary in script.get_script_method_list():
			if method["name"] == "register_section":
				for arg: Dictionary in method["args"]:
					arg_names.append(arg["name"])
		assert_eq(
			arg_names,
			["title", "provider", "lifetime_owner"] as Array[String],
			"%s.register_section parameters" % script.get_global_name()
		)
