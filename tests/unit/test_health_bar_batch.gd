extends GutTest
## HealthBarBatch (PLAT-01): hurt-only billboard bars in one batch. The hurt-only rule is
## HealthBar3D.should_show, the ratio rides in the instance's custom data, and nothing here reads
## the MultiMesh back (the headless renderer returns zeros, RESEARCH F6).

const CAPACITY: int = 4
const WIDTH: float = 0.9
const EPSILON: float = 0.0001
const ORIGIN := Vector3(2.0, 2.1, -3.0)

var _bars: HealthBarBatch


func before_each() -> void:
	_bars = HealthBarBatch.new()
	add_child_autofree(_bars)


func test_setup_builds_a_quad_of_the_bar_size_with_one_slot_per_capacity() -> void:
	assert_true(_bars.setup_bars(WIDTH, CAPACITY), "a valid setup succeeds")
	var mesh: QuadMesh = _bars.multimesh.mesh as QuadMesh
	assert_not_null(mesh, "the bar is a quad")
	if mesh == null:
		return
	assert_almost_eq(mesh.size.x, WIDTH, EPSILON, "the width")
	assert_almost_eq(mesh.size.y, HealthBar3D.BAR_HEIGHT, EPSILON, "the shared bar height")
	assert_eq(_bars.multimesh.instance_count, CAPACITY, "one slot per capacity")
	assert_eq(_bars.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "no shadow")
	assert_true(_bars.material_override is ShaderMaterial, "drawn by its own shader")


func test_a_hurt_enemy_adds_a_bar_filled_to_its_health_ratio() -> void:
	_bars.setup_bars(WIDTH, CAPACITY)
	_bars.begin()
	assert_true(_bars.add_if_hurt(ORIGIN, 3, 6), "hp 3 of 6 is hurt")
	assert_eq(_bars.count(), 1, "one bar")
	assert_almost_eq(_bars.ratio_of(0), 0.5, EPSILON, "half full")
	assert_eq(_bars.origin_of(0), ORIGIN, "at the origin it was given")
	_bars.commit()
	assert_eq(_bars.multimesh.visible_instance_count, 1, "and it is shown")


func test_a_full_or_dead_enemy_adds_no_bar() -> void:
	_bars.setup_bars(WIDTH, CAPACITY)
	_bars.begin()
	assert_false(_bars.add_if_hurt(ORIGIN, 6, 6), "full health shows nothing")
	assert_false(_bars.add_if_hurt(ORIGIN, 0, 6), "a dead enemy shows nothing")
	assert_false(_bars.add_if_hurt(ORIGIN, 3, 0), "no max health shows nothing")
	assert_eq(_bars.count(), 0, "nothing was added")


func test_a_full_batch_refuses_one_more_bar() -> void:
	_bars.setup_bars(WIDTH, CAPACITY)
	_bars.begin()
	for index: int in range(CAPACITY):
		assert_true(_bars.add_if_hurt(ORIGIN, 1 + index, 10), "bar %d" % index)
	assert_false(_bars.add_if_hurt(ORIGIN, 1, 10), "the fifth does not fit")
	assert_eq(_bars.count(), CAPACITY, "the count stays at the capacity")


func test_a_frame_with_no_bar_commits_nothing() -> void:
	_bars.setup_bars(WIDTH, CAPACITY)
	_bars.begin()
	_bars.add_if_hurt(ORIGIN, 1, 10)
	_bars.commit()
	_bars.begin()
	_bars.commit()
	assert_eq(_bars.multimesh.visible_instance_count, 0, "an empty frame draws nothing")
	assert_eq(_bars.ratio_of(0), -1.0, "and a bar that is not there has no ratio")
