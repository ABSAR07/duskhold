extends GutTest
## PLAT-01 (plan 04-27, exact_port_rules 10, T-04-71): the entry points of NativeUnitViews against
## good and bad input. The fill itself is pinned byte for byte by test_unit_fill_pins; this file
## covers what those runs never ask: arrays of different sizes, hit points before a maximum, a flood
## past the draw cap, a def slot with no batch, mirrors of the wrong shape or missing, unknown
## batches, the hurt-only rule at its edges and the neutral answers for a unit that is not drawn.
## Mirrors are read back through real CrowdBatches fed by commit_buffer, as in play.

const MAX_VIEWS: int = 8
const FLOOD_TOTAL: int = 300
const FLOOD_CAP: int = 256
const TYPES: int = 2
const BAR_HEIGHT: float = 1.8
const EPSILON: float = 0.0001

var _views: NativeUnitViews
var _batches: Array[CrowdBatch] = []
var _bars: CrowdBatch


func before_each() -> void:
	_build(MAX_VIEWS)


## Type batches and a bar batch of `capacity` instances, the draw cap `max_views` (the capacity
## when negative).
func _build(capacity: int, max_views: int = -1) -> void:
	_batches.clear()
	_views = NativeUnitViews.new()
	_views.configure(capacity if max_views < 0 else max_views, BAR_HEIGHT, TYPES)
	for batch_index: int in range(TYPES):
		var batch: CrowdBatch = CrowdBatch.new()
		add_child_autofree(batch)
		batch.setup(BoxMesh.new(), StandardMaterial3D.new(), capacity, false)
		assert_true(_views.set_mirror(batch_index, batch.mirror(), batch.layout()), "mirror taken")
		_batches.append(batch)
	_bars = CrowdBatch.new()
	add_child_autofree(_bars)
	_bars.setup(QuadMesh.new(), StandardMaterial3D.new(), capacity, false)
	assert_true(_views.set_bar_mirror(_bars.mirror(), _bars.layout()), "bar mirror taken")


## Hands every native mirror to its batch, as UnitViews does after a fill.
func _commit() -> void:
	for batch_index: int in range(TYPES):
		var taken: bool = _batches[batch_index].commit_buffer(
			_views.mirror(batch_index), _views.count(batch_index)
		)
		assert_true(taken, "batch %d takes its buffer" % batch_index)
	assert_true(_bars.commit_buffer(_views.bar_mirror(), _views.bar_count()), "bars take theirs")


func _ids(total: int) -> PackedInt64Array:
	var ids: PackedInt64Array = PackedInt64Array()
	for index: int in range(total):
		ids.append(index + 1)
	return ids


func _line(total: int, offset: float = 0.0) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in range(total):
		points.append(Vector2(float(index) + offset, 1.0))
	return points


## One def slot per unit, cycling through `slots` slots.
func _slots(total: int, slots: int = 1) -> PackedInt32Array:
	var def_slots: PackedInt32Array = PackedInt32Array()
	for index: int in range(total):
		def_slots.append(index % slots)
	return def_slots


func _fill(
	total: int, batch_of_def: PackedInt32Array = PackedInt32Array([0]), blend: float = 1.0
) -> int:
	return _views.fill(blend, _ids(total), _line(total), _line(total), _slots(total), batch_of_def)


func _remember(total: int, max_hp: int = 10) -> void:
	for id: int in range(1, total + 1):
		_views.set_max_hp(id, max_hp)


func test_arrays_of_different_sizes_draw_nothing() -> void:
	var one_batch: PackedInt32Array = PackedInt32Array([0])
	var drawn: int = _views.fill(1.0, _ids(2), _line(1), _line(2), _slots(2), one_batch)
	assert_eq(drawn, 0, "previous is short")
	drawn = _views.fill(1.0, _ids(2), _line(2), _line(3), _slots(2), one_batch)
	assert_eq(drawn, 0, "current is long")
	drawn = _views.fill(1.0, _ids(2), _line(2), _line(2), _slots(3), one_batch)
	assert_eq(drawn, 0, "the def slots are long")
	assert_eq(_views.drawn_count(), 0, "nothing is drawn")
	assert_eq(_views.count(0), 0, "and no batch holds anything")
	assert_eq(_fill(2), 2, "right sizes draw both")


func test_hit_points_before_a_maximum_are_ignored() -> void:
	_views.set_hp(99, 5)
	assert_eq(_views.known_count(), 0, "an unknown id is not remembered")
	assert_eq(_views.hp_of(99), -1, "no hit points")
	_views.set_max_hp(99, 10)
	assert_eq(_views.hp_of(99), -1, "a later maximum does not inherit the ignored hit")
	assert_eq(_views.max_hp_of(99), 10, "its maximum is the one set")
	assert_eq(_views.max_hp_of(7), 0, "an unknown unit has no maximum")


func test_three_hundred_units_in_a_256_cap_draw_256_and_stop() -> void:
	_build(FLOOD_CAP)
	_remember(FLOOD_TOTAL)
	assert_eq(_views.known_count(), FLOOD_TOTAL, "all remembered")
	assert_eq(_fill(FLOOD_TOTAL), FLOOD_CAP, "256 drawn")
	assert_eq(_views.drawn_count(), FLOOD_CAP, "the count agrees")
	assert_eq(_views.count(0), FLOOD_CAP, "all in the first batch")
	assert_true(_views.has_view(FLOOD_CAP), "the oldest are the ones drawn")
	assert_false(_views.has_view(FLOOD_CAP + 1), "the first one past the cap is left out")
	assert_false(_views.has_view(FLOOD_TOTAL), "and so is the newest")


func test_a_draw_cap_below_the_batch_capacity_stops_there() -> void:
	_build(MAX_VIEWS, 3)
	assert_eq(_fill(6), 3, "three drawn")
	assert_eq(_views.count(0), 3, "three in the batch")


func test_a_def_slot_without_a_batch_is_skipped() -> void:
	var total: int = 6
	# Slots 0, 1, 2 cycle over the units: slot 0 -> batch 0, slot 1 -> -1, slot 2 -> out of range.
	var drawn: int = _views.fill(
		1.0, _ids(total), _line(total), _line(total), _slots(total, 3), PackedInt32Array([0, -1])
	)
	assert_eq(drawn, 2, "units 1 and 4 only")
	assert_true(_views.has_view(1), "unit 1")
	assert_true(_views.has_view(4), "unit 4")
	assert_false(_views.has_view(2), "unit 2 has batch -1")
	assert_false(_views.has_view(3), "unit 3 has a slot past the table")
	var wild: PackedInt32Array = PackedInt32Array([TYPES, 0])
	var wild_drawn: int = _views.fill(1.0, _ids(2), _line(2), _line(2), _slots(2, 2), wild)
	assert_eq(wild_drawn, 1, "a batch index past type_count is skipped, the next draws")
	assert_true(_views.has_view(2), "unit 2 is the one drawn")
	var negative: PackedInt32Array = PackedInt32Array([-5])
	assert_eq(_fill(2, negative), 0, "a negative batch draws nothing")


func test_a_batch_whose_mesh_is_not_ready_skips_its_units() -> void:
	var partial: NativeUnitViews = NativeUnitViews.new()
	partial.configure(MAX_VIEWS, BAR_HEIGHT, TYPES)
	assert_true(partial.set_bar_mirror(_bars.mirror(), _bars.layout()), "bars")
	assert_true(partial.set_mirror(1, _batches[1].mirror(), _batches[1].layout()), "second type")
	var drawn: int = partial.fill(
		1.0, _ids(4), _line(4), _line(4), _slots(4, 2), PackedInt32Array([0, 1])
	)
	assert_eq(drawn, 2, "only the units of the ready type")
	assert_eq(partial.count(0), 0, "the first type holds nothing")
	assert_eq(partial.count(1), 2, "the second holds two")


func test_each_unit_lands_in_the_batch_of_its_def() -> void:
	var total: int = 6
	var drawn: int = _views.fill(
		1.0, _ids(total), _line(total), _line(total), _slots(total, 2), PackedInt32Array([1, 0])
	)
	assert_eq(drawn, total, "all drawn")
	assert_eq(_views.count(1), 3, "slot 0 units went to batch 1")
	assert_eq(_views.count(0), 3, "slot 1 units went to batch 0")
	_commit()
	assert_eq(_batches[1].origin_of(0), Vector3(0.0, 0.0, 1.0), "unit 1 first in batch 1")
	assert_eq(_batches[0].origin_of(0), Vector3(1.0, 0.0, 1.0), "unit 2 first in batch 0")


func test_the_blend_interpolates_between_previous_and_current() -> void:
	var drawn: int = _views.fill(
		0.5, _ids(1), _line(1, 0.0), _line(1, 4.0), _slots(1), PackedInt32Array([0])
	)
	assert_eq(drawn, 1, "one drawn")
	assert_almost_eq(
		_views.puppet_position(1), Vector3(2.0, 0.0, 1.0), Vector3.ONE * EPSILON, "half"
	)
	_commit()
	assert_almost_eq(
		_batches[0].origin_of(0), Vector3(2.0, 0.0, 1.0), Vector3.ONE * EPSILON, "mirror"
	)


func test_a_bar_shows_only_for_a_hurt_living_unit_with_a_maximum() -> void:
	_views.set_max_hp(1, 10)
	_views.set_max_hp(2, 10)
	_views.set_max_hp(3, 10)
	_views.set_max_hp(4, 0)
	_views.set_max_hp(5, 10)
	_views.set_hp(1, 4)
	_views.set_hp(2, 10)
	_views.set_hp(3, 0)
	_views.set_hp(4, 3)
	_views.set_hp(5, -2)
	assert_eq(_fill(5), 5, "five drawn")
	assert_eq(_views.bar_count(), 1, "only the unit at 4 of 10 shows a bar")
	_commit()
	assert_almost_eq(_bars.custom_of(0).r, 0.4, EPSILON, "filled to hp over max")
	assert_almost_eq(
		_bars.origin_of(0), Vector3(0.0, BAR_HEIGHT, 1.0), Vector3.ONE * EPSILON, "above"
	)


func test_forget_hp_hides_the_bar_and_forget_drops_the_unit() -> void:
	_remember(3)
	_views.set_hp(2, 3)
	_views.set_hp(3, 3)
	assert_eq(_fill(3), 3, "three drawn")
	assert_eq(_views.bar_count(), 2, "two hurt")
	_views.forget_hp(2)
	_views.forget_hp(404)
	assert_eq(_views.hp_of(2), -1, "restored")
	assert_eq(_views.max_hp_of(2), 10, "the maximum stays")
	assert_eq(_fill(3), 3, "still drawn")
	assert_eq(_views.bar_count(), 1, "one bar left")
	_views.forget(3)
	_views.forget(404)
	assert_eq(_views.known_count(), 2, "forgetting one, and one never known")
	assert_eq(_views.hp_of(3), -1, "its hit points went with it")
	assert_eq(_fill(3), 3, "a unit with no record is still drawn")
	assert_eq(_views.bar_count(), 0, "without a bar")


func test_set_mirror_refuses_a_wrong_size_and_an_unknown_batch() -> void:
	var fresh: NativeUnitViews = NativeUnitViews.new()
	fresh.configure(MAX_VIEWS, BAR_HEIGHT, TYPES)
	var batch: CrowdBatch = _batches[0]
	var layout: PackedInt64Array = batch.layout()
	assert_false(fresh.set_mirror(-1, batch.mirror(), layout), "batch -1")
	assert_false(fresh.set_mirror(TYPES, batch.mirror(), layout), "batch past type_count")
	assert_false(fresh.set_mirror(0, PackedFloat32Array([1.0, 2.0]), layout), "a short mirror")
	assert_false(fresh.set_mirror(0, batch.mirror(), PackedInt64Array([MAX_VIEWS, 16])), "layout")
	assert_false(fresh.set_bar_mirror(PackedFloat32Array([1.0]), layout), "a short bar mirror")
	assert_eq(fresh.mirror(0).size(), 0, "a refusal keeps nothing")
	assert_true(fresh.set_mirror(0, batch.mirror(), layout), "the batch's own mirror and layout")
	var unconfigured: NativeUnitViews = NativeUnitViews.new()
	assert_false(unconfigured.set_mirror(0, batch.mirror(), layout), "before configure")


func test_a_fill_without_the_bar_mirror_or_without_configure_draws_nothing() -> void:
	var partial: NativeUnitViews = NativeUnitViews.new()
	partial.configure(MAX_VIEWS, BAR_HEIGHT, TYPES)
	partial.set_mirror(0, _batches[0].mirror(), _batches[0].layout())
	var one_batch: PackedInt32Array = PackedInt32Array([0])
	var drawn: int = partial.fill(1.0, _ids(1), _line(1), _line(1), _slots(1), one_batch)
	assert_eq(drawn, 0, "the bars have no mirror")
	var bare: NativeUnitViews = NativeUnitViews.new()
	assert_eq(bare.fill(1.0, _ids(1), _line(1), _line(1), _slots(1), one_batch), 0, "unconfigured")
	bare.configure(0, BAR_HEIGHT, TYPES)
	bare.set_bar_mirror(_bars.mirror(), _bars.layout())
	assert_eq(bare.fill(1.0, _ids(1), _line(1), _line(1), _slots(1), one_batch), 0, "a cap of 0")
	bare.configure(MAX_VIEWS, BAR_HEIGHT, -1)
	assert_eq(bare.fill(1.0, _ids(1), _line(1), _line(1), _slots(1), one_batch), 0, "type_count -1")


func test_unknown_batches_answer_empty() -> void:
	assert_eq(_views.mirror(-1).size(), 0, "batch -1 has no mirror")
	assert_eq(_views.mirror(9).size(), 0, "batch 9 has no mirror")
	assert_eq(_views.count(-1), 0, "batch -1 holds nothing")
	assert_eq(_views.count(9), 0, "batch 9 holds nothing")


func test_a_unit_that_is_not_drawn_answers_neutrally() -> void:
	assert_eq(_fill(2), 2, "two drawn")
	assert_false(_views.has_view(3), "unit 3 was not in the view")
	assert_false(_views.has_view(0), "unit 0 neither")
	assert_eq(_views.puppet_position(3), Vector3.ZERO, "the zero vector")
	assert_eq(_views.hp_of(3), -1, "no hit points")
	assert_eq(_views.max_hp_of(3), 0, "no maximum")
	assert_eq(_fill(0), 0, "an empty view draws nothing")
	assert_false(_views.has_view(1), "and the earlier frame is forgotten")
