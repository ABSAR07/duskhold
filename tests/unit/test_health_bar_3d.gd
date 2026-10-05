extends GutTest
## D-12 hurt-only rule as a reusable bar: shown while 0 < hp < max, hidden at full health and
## at 0, with the fill following hp / max. The king, the castle, and later buildings and enemies
## use it.


func _bar() -> HealthBar3D:
	var bar: HealthBar3D = HealthBar3D.new()
	add_child_autofree(bar)
	return bar


## The fill quad's mesh, or null (with a failed assertion) when the bar has none.
func _fill_mesh(bar: HealthBar3D) -> QuadMesh:
	var fill: MeshInstance3D = bar.get_node_or_null("Fill") as MeshInstance3D
	assert_not_null(fill, "the bar has a Fill quad")
	return fill.mesh as QuadMesh if fill != null else null


func test_should_show_is_false_at_full_health() -> void:
	assert_false(HealthBar3D.should_show(10, 10), "a full bar stays hidden")


func test_should_show_is_true_one_point_below_full() -> void:
	assert_true(HealthBar3D.should_show(9, 10), "max - 1 shows")
	assert_true(HealthBar3D.should_show(1, 10), "one point left shows")


func test_should_show_is_false_at_zero_and_for_a_bad_maximum() -> void:
	assert_false(HealthBar3D.should_show(0, 10), "a dead owner shows no bar")
	assert_false(HealthBar3D.should_show(5, 0), "no maximum shows nothing")
	assert_false(HealthBar3D.should_show(-3, 10), "negative hp shows nothing")


func test_a_new_bar_is_hidden() -> void:
	assert_false(_bar().visible, "hidden until something is hurt")


func test_set_health_updates_the_fill_ratio_and_shows_the_bar() -> void:
	var bar: HealthBar3D = _bar()
	bar.set_health(3, 4)
	assert_almost_eq(bar.get_fill_ratio(), 0.75, 0.0001, "hp / max")
	assert_true(bar.visible, "hurt, so shown")
	var fill_mesh: QuadMesh = _fill_mesh(bar)
	if fill_mesh == null:
		return
	assert_almost_eq(fill_mesh.size.x, bar.bar_width * 0.75, 0.0001, "the fill is 3/4 wide")


func test_the_fill_stays_anchored_to_the_left_edge() -> void:
	var bar: HealthBar3D = _bar()
	bar.set_health(1, 4)
	var fill_mesh: QuadMesh = _fill_mesh(bar)
	if fill_mesh == null:
		return
	var left_edge: float = fill_mesh.center_offset.x - fill_mesh.size.x * 0.5
	assert_almost_eq(left_edge, -bar.bar_width * 0.5, 0.0001, "the left edge does not move")


func test_the_bar_hides_again_at_full_health_and_at_zero() -> void:
	var bar: HealthBar3D = _bar()
	bar.set_health(2, 4)
	assert_true(bar.visible, "shown when hurt")
	bar.set_health(4, 4)
	assert_false(bar.visible, "hidden once healed")
	assert_almost_eq(bar.get_fill_ratio(), 1.0, 0.0001, "full")
	bar.set_health(0, 4)
	assert_false(bar.visible, "hidden at 0")
	assert_almost_eq(bar.get_fill_ratio(), 0.0, 0.0001, "empty")


func test_set_health_before_the_node_enters_the_tree_is_remembered() -> void:
	var bar: HealthBar3D = HealthBar3D.new()
	bar.set_health(1, 4)
	add_child_autofree(bar)
	assert_true(bar.visible, "hurt state survives _ready")
	assert_almost_eq(bar.get_fill_ratio(), 0.25, 0.0001, "ratio survives _ready")
	var fill_mesh: QuadMesh = _fill_mesh(bar)
	if fill_mesh == null:
		return
	assert_almost_eq(fill_mesh.size.x, bar.bar_width * 0.25, 0.0001, "and the fill is sized")


func test_the_bar_floats_at_its_height_offset() -> void:
	var bar: HealthBar3D = HealthBar3D.new()
	bar.height_offset = 4.5
	add_child_autofree(bar)
	assert_almost_eq(bar.position.y, 4.5, 0.0001, "height_offset sets the height")
