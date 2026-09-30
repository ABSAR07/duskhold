extends GutTest
## DEV-03: DebugOverlay.register_section works whatever the bind order, and bind_run is idempotent.
## Nodes in the run_bound group are bound in no guaranteed order, so a Phase 2 caller can register
## its section before the overlay is bound, or bind the overlay twice; neither may lose a section.

const OVERLAY_SCENE := "res://ui/overlay/debug_overlay.tscn"
const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"


func after_each() -> void:
	E2eSupport.release_all_actions()


func _context() -> RunContext:
	var map: MapConfig = (load(PROTOTYPE_MAP) as MapConfig).duplicate(true)
	var tuning: LoopTuning = (load(TUNING) as LoopTuning).duplicate(true)
	return RunContext.new(map, tuning)


func _overlay() -> DebugOverlay:
	var overlay: DebugOverlay = (load(OVERLAY_SCENE) as PackedScene).instantiate()
	add_child_autofree(overlay)
	return overlay


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

	overlay.bind_run(_context(), null)

	var text: String = await _shown_text(overlay)
	assert_string_contains(text, "Kept", "a repeat bind_run does not discard the section")
	assert_string_contains(text, "Wave: 3", "or its rows")


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
	assert_push_warning("debug overlay section 'Ghost' not registered: its owner was freed")


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
