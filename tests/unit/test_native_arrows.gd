extends GutTest
## PLAT-01 (plan 04-25, exact_port_rules 10, T-04-66): the entry points of NativeArrows against good
## and bad input. The flight itself is pinned byte for byte by test_projectile_fill_pins; this file
## covers what those runs never ask: a mirror of the wrong size, a full ring, enemy arrays that do
## not match, slots outside the ring, an unconfigured class, a batch smaller than the ring, and the
## two statics at their edges.

const CAPACITY: int = 4
const ARC_PER_METRE: float = 0.12
const MAX_ARC: float = 2.5
const HEADING: float = 0.02
const UNIT_HEIGHT: float = 1.2
const ORIGIN := Vector3(1.0, 2.0, 3.0)
const TARGET := Vector3(1.0, 2.0, 13.0)
const TINT := Color(0.5, 0.25, 0.75, 1.0)
const NO_ENEMIES: PackedInt64Array = []

var _arrows: NativeArrows
var _batch: CrowdBatch


func before_each() -> void:
	_batch = CrowdBatch.new()
	add_child_autofree(_batch)
	_batch.setup(BoxMesh.new(), StandardMaterial3D.new(), CAPACITY, true)
	_arrows = NativeArrows.new()
	_arrows.configure(CAPACITY, ARC_PER_METRE, MAX_ARC, HEADING, UNIT_HEIGHT)
	assert_true(_arrows.set_mirror(_batch.mirror(), _batch.layout()), "the batch mirror is taken")


func _launch(code: int, id: int = 0, duration: float = 1.0) -> int:
	return _arrows.launch(ORIGIN, TARGET, duration, code, id, TINT)


func _fill(
	delta: float,
	ids: PackedInt64Array = NO_ENEMIES,
	current: PackedVector2Array = PackedVector2Array(),
	living: PackedByteArray = PackedByteArray()
) -> int:
	return _arrows.fill(delta, Vector2.ZERO, ids, current, living)


func test_set_mirror_refuses_a_wrong_size_and_a_layout_that_does_not_fit() -> void:
	var fresh: NativeArrows = NativeArrows.new()
	var layout: PackedInt64Array = _batch.layout()
	assert_false(fresh.set_mirror(PackedFloat32Array([1.0, 2.0]), layout), "a short mirror")
	assert_false(fresh.set_mirror(_batch.mirror(), PackedInt64Array([CAPACITY, 20])), "two values")
	assert_false(fresh.set_mirror(_batch.mirror(), PackedInt64Array([0, 20, 12, 16])), "capacity 0")
	assert_false(
		fresh.set_mirror(_batch.mirror(), PackedInt64Array([CAPACITY, 20, 12, 18])),
		"custom data would leave the stride"
	)
	assert_false(
		fresh.set_mirror(_batch.mirror(), PackedInt64Array([CAPACITY, 20, 20, 16])),
		"the colour would leave the stride"
	)
	assert_false(
		fresh.set_mirror(_batch.mirror(), PackedInt64Array([CAPACITY, 20, 12, 12])),
		"the custom data would overlap the colour"
	)
	assert_false(
		fresh.set_mirror(_batch.mirror(), PackedInt64Array([CAPACITY + 1, 20, 12, 16])),
		"capacity times stride is not the mirror size"
	)
	assert_eq(fresh.mirror().size(), 0, "a refusal keeps nothing")
	assert_true(fresh.set_mirror(_batch.mirror(), layout), "the batch's own mirror and layout")
	assert_eq(fresh.mirror().size(), CAPACITY * 20, "and then it holds the mirror")


func test_launch_fills_slots_in_ring_order_and_answers_minus_one_when_full() -> void:
	for expected: int in range(CAPACITY):
		assert_eq(_launch(NativeArrows.TARGET_FIXED), expected, "slot %d" % expected)
	assert_eq(_launch(NativeArrows.TARGET_FIXED), -1, "the ring is full")
	assert_eq(_arrows.live_count(), CAPACITY, "every flight counts")


func test_the_cursor_moves_past_a_taken_slot_and_wraps_to_a_freed_one() -> void:
	_arrows.launch(ORIGIN, TARGET, 0.01, NativeArrows.TARGET_FIXED, 0, TINT)
	assert_eq(_launch(NativeArrows.TARGET_FIXED), 1, "slot 1")
	assert_eq(_launch(NativeArrows.TARGET_FIXED), 2, "slot 2")
	_fill(0.02)
	assert_eq(_arrows.live_count(), 2, "the short flight landed and its slot is free")
	assert_eq(_launch(NativeArrows.TARGET_FIXED), 3, "the cursor goes on to slot 3")
	assert_eq(_launch(NativeArrows.TARGET_FIXED), 0, "then wraps to the freed slot 0")
	assert_eq(_launch(NativeArrows.TARGET_FIXED), -1, "and the ring is full again")


func test_fill_writes_the_arrow_as_the_next_instance_exactly_as_the_batch_would() -> void:
	_launch(NativeArrows.TARGET_FIXED)
	assert_eq(_fill(0.5), 1, "one instance written")
	assert_eq(_arrows.count(), 1, "and counted")
	assert_eq(_arrows.live_count(), 1, "the flight is still in the air")
	assert_eq(_arrows.drawn_launch(0), ORIGIN, "the launch point is recorded")
	var pose: Transform3D = NativeArrows.arrow_transform(
		ORIGIN, TARGET, 0.5, ARC_PER_METRE, MAX_ARC, HEADING
	)
	assert_true(_batch.commit_buffer(_arrows.mirror(), _arrows.count()), "the batch takes it")
	assert_eq(_batch.origin_of(0), pose.origin, "the origin is the pose's")
	assert_eq(_batch.basis_of(0), pose.basis, "so is the basis")
	assert_eq(_batch.color_of(0), TINT, "the colour is the flight's")
	assert_eq(_batch.custom_of(0), Color(0.0, 0.0, 0.0, 0.0), "the custom data is zero")


func test_a_flight_that_reaches_progress_one_is_written_once_and_then_freed() -> void:
	_arrows.launch(ORIGIN, TARGET, 0.1, NativeArrows.TARGET_FIXED, 0, TINT)
	assert_eq(_fill(0.2), 1, "its landing frame is still drawn")
	assert_eq(_arrows.live_count(), 0, "and the slot is free after it")
	assert_eq(_fill(0.2), 0, "the next frame draws nothing")
	assert_eq(_arrows.count(), 0, "and holds nothing")


func test_enemy_arrays_that_do_not_match_keep_every_last_target() -> void:
	var slot: int = _launch(NativeArrows.TARGET_ENEMY, 7)
	var ids: PackedInt64Array = PackedInt64Array([7])
	var where: PackedVector2Array = PackedVector2Array([Vector2(4.0, 5.0)])
	_fill(0.1, ids, where, PackedByteArray([1, 1]))
	assert_eq(_arrows.target_at(slot), TARGET, "living of another size finds no enemy")
	_fill(0.1, ids, PackedVector2Array(), PackedByteArray([1]))
	assert_eq(_arrows.target_at(slot), TARGET, "positions of another size find no enemy")
	_fill(
		0.1,
		PackedInt64Array([3, 9]),
		PackedVector2Array([Vector2.ZERO, Vector2.ONE]),
		PackedByteArray([1, 1])
	)
	assert_eq(_arrows.target_at(slot), TARGET, "an id that is not listed keeps the target")
	_fill(0.1, ids, where, PackedByteArray([0]))
	assert_eq(_arrows.target_at(slot), TARGET, "a dead enemy keeps the target")
	_fill(0.1, ids, where, PackedByteArray([1]))
	assert_eq(_arrows.target_at(slot), Vector3(4.0, UNIT_HEIGHT, 5.0), "a living enemy is followed")


func test_a_king_arrow_follows_the_king_and_a_fixed_one_never_moves() -> void:
	var king_slot: int = _launch(NativeArrows.TARGET_KING)
	var fixed_slot: int = _launch(NativeArrows.TARGET_FIXED, 3)
	_arrows.fill(0.1, Vector2(-6.0, 8.0), NO_ENEMIES, PackedVector2Array(), PackedByteArray())
	assert_eq(_arrows.target_at(king_slot), Vector3(-6.0, UNIT_HEIGHT, 8.0), "the king's position")
	assert_eq(_arrows.target_at(fixed_slot), TARGET, "the fixed target stays")
	assert_eq(_arrows.target_id_at(fixed_slot), 3, "and the id is kept")


func test_unit_flights_are_listed_for_gdscript_and_take_the_target_it_sets() -> void:
	var first: int = _launch(NativeArrows.TARGET_UNIT, 11)
	_launch(NativeArrows.TARGET_FIXED)
	var second: int = _launch(NativeArrows.TARGET_UNIT, 12)
	assert_eq(_arrows.slots_targeting(NativeArrows.TARGET_UNIT), PackedInt32Array([first, second]))
	assert_eq(_arrows.slots_targeting(NativeArrows.TARGET_ENEMY).size(), 0, "no enemy flights")
	assert_eq(_arrows.target_id_at(second), 12, "the unit id")
	_arrows.set_target(first, Vector3(9.0, 1.2, 9.0))
	_fill(0.1)
	assert_eq(_arrows.target_at(first), Vector3(9.0, 1.2, 9.0), "a fill leaves a unit target alone")


func test_an_unknown_target_code_behaves_as_a_fixed_target() -> void:
	var slot: int = _launch(9)
	assert_eq(_arrows.slots_targeting(9).size(), 0, "code 9 is not kept")
	assert_eq(_arrows.slots_targeting(NativeArrows.TARGET_FIXED), PackedInt32Array([slot]))
	var negative: int = _launch(-1)
	assert_eq(negative, 1, "the next slot is used")
	assert_eq(_arrows.slots_targeting(-1).size(), 0, "a negative code is not kept either")


func test_slots_outside_the_ring_answer_minus_one_or_zero_and_change_nothing() -> void:
	var slot: int = _launch(NativeArrows.TARGET_FIXED, 5)
	for bad: int in [-1, CAPACITY, 99, slot + 1]:
		assert_eq(_arrows.target_id_at(bad), -1, "id of slot %d" % bad)
		assert_eq(_arrows.target_at(bad), Vector3.ZERO, "target of slot %d" % bad)
		_arrows.set_target(bad, Vector3(7.0, 7.0, 7.0))
	assert_eq(_arrows.target_at(slot), TARGET, "the real flight was not touched")
	assert_eq(_arrows.live_count(), 1, "nor was the count")
	assert_eq(_arrows.target_id_at(slot), 5, "and the id reads back")


func test_drawn_launch_past_the_count_is_the_zero_vector() -> void:
	_launch(NativeArrows.TARGET_FIXED)
	assert_eq(_arrows.drawn_launch(0), Vector3.ZERO, "nothing is drawn before the first fill")
	_fill(0.1)
	assert_eq(_arrows.drawn_launch(0), ORIGIN, "the first instance")
	assert_eq(_arrows.drawn_launch(1), Vector3.ZERO, "past the count")
	assert_eq(_arrows.drawn_launch(-1), Vector3.ZERO, "before the first")
	assert_eq(_arrows.drawn_launch(CAPACITY), Vector3.ZERO, "past the ring")


func test_an_unconfigured_class_launches_and_draws_nothing() -> void:
	var fresh: NativeArrows = NativeArrows.new()
	assert_eq(fresh.launch(ORIGIN, TARGET, 1.0, 0, 0, TINT), -1, "no ring, no slot")
	assert_eq(fresh.fill(0.1, Vector2.ZERO, NO_ENEMIES, PackedVector2Array(), PackedByteArray()), 0)
	assert_eq(fresh.live_count(), 0, "nothing in flight")
	fresh.configure(0, ARC_PER_METRE, MAX_ARC, HEADING, UNIT_HEIGHT)
	assert_eq(fresh.launch(ORIGIN, TARGET, 1.0, 0, 0, TINT), -1, "capacity 0 leaves no ring")
	fresh.configure(CAPACITY, ARC_PER_METRE, MAX_ARC, HEADING, UNIT_HEIGHT)
	assert_eq(fresh.launch(ORIGIN, TARGET, 1.0, 0, 0, TINT), 0, "a ring without a mirror flies")
	assert_eq(
		fresh.fill(0.1, Vector2.ZERO, NO_ENEMIES, PackedVector2Array(), PackedByteArray()),
		0,
		"but draws nothing without a mirror"
	)


func test_a_batch_smaller_than_the_ring_drops_the_arrows_past_its_capacity() -> void:
	var small: CrowdBatch = CrowdBatch.new()
	add_child_autofree(small)
	small.setup(BoxMesh.new(), StandardMaterial3D.new(), 2, true)
	var arrows: NativeArrows = NativeArrows.new()
	arrows.configure(CAPACITY, ARC_PER_METRE, MAX_ARC, HEADING, UNIT_HEIGHT)
	assert_true(arrows.set_mirror(small.mirror(), small.layout()), "the small mirror is taken")
	for _shot: int in range(CAPACITY):
		arrows.launch(ORIGIN, TARGET, 1.0, 0, 0, TINT)
	assert_eq(
		arrows.fill(0.1, Vector2.ZERO, NO_ENEMIES, PackedVector2Array(), PackedByteArray()), 2
	)
	assert_eq(arrows.live_count(), CAPACITY, "every flight is still in the air")
	assert_eq(arrows.mirror().size(), 2 * 20, "and the mirror never grew")


func test_equal_origin_and_target_give_the_identity_basis_at_the_origin() -> void:
	for progress: float in [0.0, 0.3, 0.5, 1.0, 2.0]:
		var pose: Transform3D = NativeArrows.arrow_transform(
			ORIGIN, ORIGIN, progress, ARC_PER_METRE, MAX_ARC, HEADING
		)
		assert_eq(pose.basis, Basis.IDENTITY, "identity basis at progress %.1f" % progress)
		assert_eq(pose.origin, ORIGIN, "at the origin at progress %.1f" % progress)


func test_arc_height_is_zero_at_both_ends_peaks_halfway_and_is_capped() -> void:
	assert_eq(NativeArrows.arc_height(0.0, 10.0, ARC_PER_METRE, MAX_ARC), 0.0, "launch")
	assert_eq(NativeArrows.arc_height(1.0, 10.0, ARC_PER_METRE, MAX_ARC), 0.0, "landing")
	assert_eq(NativeArrows.arc_height(-0.5, 10.0, ARC_PER_METRE, MAX_ARC), 0.0, "before launch")
	assert_eq(NativeArrows.arc_height(1.5, 10.0, ARC_PER_METRE, MAX_ARC), 0.0, "after landing")
	var peak: float = 10.0 * ARC_PER_METRE
	assert_eq(
		NativeArrows.arc_height(0.5, 10.0, ARC_PER_METRE, MAX_ARC),
		4.0 * 0.25 * peak,
		"halfway is 4 * 0.25 * peak"
	)
	assert_eq(NativeArrows.arc_height(0.5, 1000.0, ARC_PER_METRE, MAX_ARC), MAX_ARC, "capped")
	assert_eq(NativeArrows.arc_height(0.5, -5.0, ARC_PER_METRE, MAX_ARC), 0.0, "no negative arc")
