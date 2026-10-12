extends GutTest
## 03-12 / D-21: the screenshot runner fails a hud_ or cmd_ shot when a visible HUD control sits in
## the clear centre (x 384..896, y 96..500 of the 1280x720 base). The check is a function of a
## CanvasLayer, so it is tested here on small stand-in layers without a renderer.

var _hud: CanvasLayer


func before_each() -> void:
	_hud = CanvasLayer.new()
	add_child_autofree(_hud)


func _label(label_name: String, rect: Rect2, text_value: String = "text") -> Label:
	var label: Label = Label.new()
	label.name = label_name
	label.text = text_value
	label.position = rect.position
	label.size = rect.size
	return label


func test_the_rectangle_is_the_ui_spec_clear_centre() -> void:
	assert_eq(ShotRunner.PROTECTED_RECT, Rect2(384.0, 96.0, 512.0, 404.0), "x 384..896, y 96..500")


func test_a_label_in_the_centre_is_reported_with_its_path() -> void:
	_hud.add_child(_label("Stray", Rect2(500.0, 200.0, 100.0, 30.0)))
	var found: Array[String] = ShotRunner.protected_violations(_hud)
	assert_eq(found.size(), 1, "one offender")
	assert_true(found[0].begins_with("Stray "), "the line names the node")


func test_controls_outside_the_centre_are_fine() -> void:
	_hud.add_child(_label("Gold", Rect2(16.0, 12.0, 120.0, 36.0)))
	_hud.add_child(_label("Toast", Rect2(410.0, 504.0, 460.0, 32.0)))
	_hud.add_child(_label("Widget", Rect2(16.0, 648.0, 360.0, 56.0)))
	assert_eq(ShotRunner.protected_violations(_hud), [] as Array[String], "all clear")


func test_a_control_that_only_touches_the_edge_does_not_count() -> void:
	_hud.add_child(_label("Below", Rect2(400.0, 500.0, 100.0, 30.0)))
	_hud.add_child(_label("Left", Rect2(300.0, 200.0, 84.0, 30.0)))
	assert_eq(ShotRunner.protected_violations(_hud), [] as Array[String], "touching is clear")


func test_the_exempt_nodes_may_sit_in_the_centre() -> void:
	for exempt: StringName in ShotRunner.EXEMPT_NODES:
		_hud.add_child(_label(String(exempt), Rect2(500.0, 200.0, 100.0, 30.0)))
	assert_eq(ShotRunner.protected_violations(_hud), [] as Array[String], "banners and layers pass")


func test_the_children_of_an_exempt_node_are_exempt_too() -> void:
	var box: CenterContainer = CenterContainer.new()
	box.name = "PhaseBannerBox"
	box.position = Vector2(0.0, 40.0)
	box.size = Vector2(1280.0, 60.0)
	_hud.add_child(box)
	box.add_child(_label("Inner", Rect2(500.0, 100.0, 200.0, 36.0)))
	assert_eq(
		ShotRunner.protected_violations(_hud), [] as Array[String], "the banner's text passes"
	)


func test_a_hidden_control_and_an_empty_label_do_not_count() -> void:
	var hidden: Label = _label("Hidden", Rect2(500.0, 200.0, 100.0, 30.0))
	hidden.visible = false
	_hud.add_child(hidden)
	_hud.add_child(_label("Empty", Rect2(500.0, 250.0, 100.0, 30.0), ""))
	assert_eq(ShotRunner.protected_violations(_hud), [] as Array[String], "nothing drawn")


func test_a_container_that_only_lays_out_is_skipped_but_its_children_are_checked() -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "Row"
	row.position = Vector2(500.0, 150.0)
	row.size = Vector2(300.0, 40.0)
	_hud.add_child(row)
	assert_eq(ShotRunner.protected_violations(_hud), [] as Array[String], "an empty row is clear")
	var inner: Label = Label.new()
	inner.name = "Inner"
	inner.text = "word"
	row.add_child(inner)
	await wait_process_frames(2)
	var found: Array[String] = ShotRunner.protected_violations(_hud)
	assert_eq(found.size(), 1, "the label inside is reported")
	if found.size() == 1:
		assert_true(found[0].begins_with("Row/Inner "), "with its path under the HUD")


func test_a_panel_container_counts_because_it_draws_its_panel() -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "Plate"
	panel.position = Vector2(600.0, 300.0)
	panel.size = Vector2(80.0, 40.0)
	_hud.add_child(panel)
	assert_eq(ShotRunner.protected_violations(_hud).size(), 1, "the plate is reported")


func test_the_drag_box_is_exempt_only_while_it_is_being_dragged() -> void:
	var box: DragBox = DragBox.new()
	box.name = "DragBox"
	_hud.add_child(box)
	box.set_rect_from(Vector2(450.0, 200.0), Vector2(800.0, 400.0))
	assert_true(box.is_dragging(), "the box is up")
	assert_eq(ShotRunner.protected_violations(_hud), [] as Array[String], "dragging is allowed")
	box.end_drag()
	box.visible = true
	box.position = Vector2(450.0, 200.0)
	box.size = Vector2(350.0, 200.0)
	assert_eq(ShotRunner.protected_violations(_hud).size(), 1, "a box left up is a defect")


func test_only_hud_and_cmd_shots_are_checked() -> void:
	var runner: ShotRunner = ShotRunner.new()
	autofree(runner)
	assert_eq(ShotRunner.CHECKED_PREFIXES, ["hud_", "cmd_"] as Array[String], "two prefixes")
	assert_eq(
		runner._centre_offenders(&"night_combat", null),
		[] as Array[String],
		"a Phase 1 or 2 shot is not checked"
	)
