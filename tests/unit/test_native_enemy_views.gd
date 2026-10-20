extends GutTest
## PLAT-01 (plan 04-26, exact_port_rules 10, T-04-68): the entry points of NativeEnemyViews and
## NativePuffs against good and bad input. The fills themselves are pinned byte for byte by
## test_enemy_fill_pins; this file covers what those runs never ask: arrays of different sizes,
## damage for an enemy nobody spawned, a flood past the draw cap, a flash that runs out, mirrors
## of the wrong shape or missing, unknown batches and kinds, a full archetype batch, the hurt-only
## rule at its edges, and a puff ring past its cap, wrapping and fading. Mirrors are read back
## through real CrowdBatches fed by commit_buffer, as in play.

const MAX_VIEWS: int = 8
const FLOOD_TOTAL: int = 600
const FLOOD_CAP: int = 512
const LIFT: float = 0.8
const LIFTS: PackedFloat32Array = [0.8, 1.0, 0.8]
const CLEARANCE: float = 0.5
const FLASH_S: float = 0.15
const EPSILON: float = 0.0001
const PUFF_CAPACITY: int = 4
const PUFF_S: float = 0.6
const NEVER_BORN: float = -1000.0
const REAL_PUFFS: int = 128
const PUFF_FLOOD: int = 150

var _views: NativeEnemyViews
var _batches: Array[CrowdBatch] = []
## The batch the latest NativePuffs of a test was built beside.
var _puff_batch: CrowdBatch


func before_each() -> void:
	_build(MAX_VIEWS)


## Batches of `capacity` instances, the draw cap `max_views` (the capacity when negative).
func _build(capacity: int, max_views: int = -1) -> void:
	_batches.clear()
	_views = NativeEnemyViews.new()
	_views.configure(capacity if max_views < 0 else max_views, LIFTS, CLEARANCE, FLASH_S)
	for batch_index: int in range(NativeEnemyViews.BATCH_TOTAL):
		var batch: CrowdBatch = CrowdBatch.new()
		add_child_autofree(batch)
		batch.setup(BoxMesh.new(), StandardMaterial3D.new(), capacity, batch_index != 3)
		assert_true(_views.set_mirror(batch_index, batch.mirror(), batch.layout()), "mirror taken")
		_batches.append(batch)


## Hands every native mirror to its batch, as EnemyViews does after a fill.
func _commit() -> void:
	for batch_index: int in range(NativeEnemyViews.BATCH_TOTAL):
		var taken: bool = _batches[batch_index].commit_buffer(
			_views.mirror(batch_index), _views.count(batch_index)
		)
		assert_true(taken, "batch %d takes its buffer" % batch_index)


func _ids(total: int) -> PackedInt64Array:
	var ids: PackedInt64Array = PackedInt64Array()
	for index: int in range(total):
		ids.append(index + 1)
	return ids


func _line(total: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in range(total):
		points.append(Vector2(float(index), 1.0))
	return points


func _fill(total: int, frame_ms: int = 5000, blend: float = 1.0) -> int:
	return _views.fill(frame_ms, blend, _ids(total), _line(total), _line(total))


func test_arrays_of_different_sizes_draw_nothing() -> void:
	_views.on_spawned(1, 0, 10)
	_views.on_spawned(2, 0, 10)
	var drawn: int = _views.fill(5000, 1.0, _ids(2), _line(1), _line(2))
	assert_eq(drawn, 0, "previous is short")
	assert_eq(_views.fill(5000, 1.0, _ids(2), _line(2), _line(3)), 0, "current is long")
	assert_eq(_views.drawn_count(), 0, "nothing is drawn")
	assert_eq(_views.count(0), 0, "and no batch holds anything")
	assert_eq(_fill(2), 2, "right sizes draw both")


func test_damage_for_an_enemy_nobody_spawned_is_ignored() -> void:
	_views.on_damaged(99, 5, 1000)
	assert_eq(_views.known_count(), 0, "an unknown id is not remembered")
	assert_eq(_views.hp_of(99), -1, "no hit points")
	_views.on_spawned(99, 0, 10)
	assert_eq(_views.hp_of(99), -1, "a later spawn does not inherit the ignored hit")
	assert_eq(_views.max_hp_of(99), 10, "its maximum is the spawn's")
	assert_eq(_views.max_hp_of(7), 0, "an unknown enemy has no maximum")


func test_six_hundred_enemies_draw_the_cap_and_stop() -> void:
	_build(FLOOD_CAP)
	for id: int in range(1, FLOOD_TOTAL + 1):
		_views.on_spawned(id, 0, 10)
	assert_eq(_views.known_count(), FLOOD_TOTAL, "all remembered")
	assert_eq(_fill(FLOOD_TOTAL), FLOOD_CAP, "512 drawn")
	assert_eq(_views.drawn_count(), FLOOD_CAP, "the count agrees")
	assert_eq(_views.count(0), FLOOD_CAP, "all in the first batch")
	assert_true(_views.has_view(FLOOD_CAP), "the oldest are the ones drawn")
	assert_false(_views.has_view(FLOOD_CAP + 1), "the first one past the cap is left out")
	assert_false(_views.has_view(FLOOD_TOTAL), "and so is the newest")


func test_a_flash_runs_out_and_the_expired_hit_is_forgotten() -> void:
	_views.on_spawned(1, 0, 10)
	_views.on_damaged(1, 4, 1000)
	_fill(1, 1000)
	assert_almost_eq(_views.flash_of(1), 1.0, EPSILON, "full strength at the hit")
	_commit()
	assert_almost_eq(_batches[0].custom_of(0).r, 1.0, EPSILON, "in the custom data too")
	_fill(1, 1075)
	assert_almost_eq(_views.flash_of(1), 0.5, EPSILON, "half way")
	_fill(1, 1150)
	assert_eq(_views.flash_of(1), 0.0, "gone at the end of the window")
	_fill(1, 1000)
	assert_eq(_views.flash_of(1), 0.0, "an expired hit stays forgotten whatever the clock says")
	assert_eq(_views.hp_of(1), 4, "the hit points outlive the flash")


func test_clear_and_forget_drop_what_was_remembered() -> void:
	_views.on_spawned(3, 0, 10)
	_views.on_spawned(3, 1, 12)
	assert_eq(_views.known_count(), 1, "a second spawn overwrites")
	_views.on_spawned(1, 0, 10)
	_views.on_spawned(2, 0, 10)
	assert_eq(_views.known_count(), 3, "ids spawned out of order are all kept")
	_views.forget(2)
	_views.forget(404)
	assert_eq(_views.known_count(), 2, "forgetting one, and one never known")
	assert_eq(_fill(3), 2, "ids 1 and 3 are drawn, 2 is not")
	_views.clear()
	assert_eq(_views.known_count(), 0, "clear forgets everyone")
	assert_eq(_fill(3), 0, "and nothing is drawn")


func test_set_mirror_refuses_a_wrong_size_and_an_unknown_batch() -> void:
	var fresh: NativeEnemyViews = NativeEnemyViews.new()
	var batch: CrowdBatch = _batches[0]
	var layout: PackedInt64Array = batch.layout()
	assert_false(fresh.set_mirror(-1, batch.mirror(), layout), "batch -1")
	assert_false(fresh.set_mirror(NativeEnemyViews.BATCH_TOTAL, batch.mirror(), layout), "batch 4")
	assert_false(fresh.set_mirror(0, PackedFloat32Array([1.0, 2.0]), layout), "a short mirror")
	assert_false(fresh.set_mirror(0, batch.mirror(), PackedInt64Array([MAX_VIEWS, 20])), "layout")
	assert_eq(fresh.mirror(0).size(), 0, "a refusal keeps nothing")
	assert_true(fresh.set_mirror(0, batch.mirror(), layout), "the batch's own mirror and layout")


func test_a_fill_without_every_mirror_or_without_configure_draws_nothing() -> void:
	var partial: NativeEnemyViews = NativeEnemyViews.new()
	partial.configure(MAX_VIEWS, LIFTS, CLEARANCE, FLASH_S)
	for batch_index: int in range(3):
		partial.set_mirror(
			batch_index, _batches[batch_index].mirror(), _batches[batch_index].layout()
		)
	partial.on_spawned(1, 0, 10)
	assert_eq(partial.fill(5000, 1.0, _ids(1), _line(1), _line(1)), 0, "the bars have no mirror")
	var bare: NativeEnemyViews = NativeEnemyViews.new()
	bare.on_spawned(1, 0, 10)
	assert_eq(bare.fill(5000, 1.0, _ids(1), _line(1), _line(1)), 0, "never configured")
	bare.configure(0, LIFTS, CLEARANCE, FLASH_S)
	assert_eq(bare.fill(5000, 1.0, _ids(1), _line(1), _line(1)), 0, "a cap of 0 stays unconfigured")
	bare.configure(MAX_VIEWS, PackedFloat32Array(), CLEARANCE, FLASH_S)
	assert_eq(bare.fill(5000, 1.0, _ids(1), _line(1), _line(1)), 0, "no lifts stays unconfigured")


func test_unknown_batches_answer_empty() -> void:
	assert_eq(_views.mirror(-1).size(), 0, "batch -1 has no mirror")
	assert_eq(_views.mirror(9).size(), 0, "batch 9 has no mirror")
	assert_eq(_views.count(-1), 0, "batch -1 holds nothing")
	assert_eq(_views.count(9), 0, "batch 9 holds nothing")


func test_an_enemy_of_an_unknown_kind_is_remembered_but_not_drawn() -> void:
	_views.on_spawned(1, 7, 10)
	_views.on_spawned(2, -1, 10)
	_views.on_spawned(3, 1, 10)
	assert_eq(_views.known_count(), 3, "all three are remembered")
	assert_eq(_fill(3), 1, "only the one with a real archetype is drawn")
	assert_true(_views.has_view(3), "enemy 3")
	assert_false(_views.has_view(1), "enemy 1 (kind 7)")
	assert_false(_views.has_view(2), "enemy 2 (kind -1)")
	assert_eq(_views.count(1), 1, "in the second archetype's batch")


func test_a_bar_shows_only_for_a_hurt_living_enemy_with_a_maximum() -> void:
	_views.on_spawned(1, 0, 10)
	_views.on_spawned(2, 0, 10)
	_views.on_spawned(3, 0, 10)
	_views.on_spawned(4, 0, 0)
	_views.on_spawned(5, 0, 10)
	_views.on_damaged(1, 4, 0)
	_views.on_damaged(2, 10, 0)
	_views.on_damaged(3, 0, 0)
	_views.on_damaged(4, 3, 0)
	_views.on_damaged(5, -2, 0)
	assert_eq(_fill(5), 5, "five drawn")
	assert_eq(
		_views.count(NativeEnemyViews.BATCH_BARS), 1, "one bar: only enemy 1 is hurt and alive"
	)
	_commit()
	var bars: CrowdBatch = _batches[NativeEnemyViews.BATCH_BARS]
	assert_almost_eq(bars.custom_of(0).r, 0.4, EPSILON, "filled to hp / max")
	assert_almost_eq(bars.origin_of(0).y, LIFT * 2.0 + CLEARANCE, EPSILON, "above the head")
	assert_almost_eq(bars.origin_of(0).x, 0.0, EPSILON, "over the enemy")
	assert_eq(_views.hp_of(2), 10, "a full-health hit is remembered")
	assert_eq(_views.hp_of(5), -2, "and so is a negative one")


func test_a_not_drawn_enemy_answers_the_neutral_values() -> void:
	_views.on_spawned(1, 0, 10)
	_views.on_damaged(1, 5, 100)
	assert_false(_views.has_view(1), "nothing drawn yet")
	assert_eq(_views.puppet_position(1), Vector3.ZERO, "no position")
	assert_eq(_views.flash_of(1), 0.0, "no flash")
	_fill(1, 100)
	assert_true(_views.has_view(1), "drawn now")
	assert_eq(_views.puppet_position(1), Vector3(0.0, 0.0, 1.0), "on the ground at its point")
	assert_eq(_views.puppet_position(2), Vector3.ZERO, "an unknown id sits nowhere")


func test_the_blend_interpolates_between_the_previous_and_current_point() -> void:
	_views.on_spawned(1, 0, 10)
	var ids: PackedInt64Array = PackedInt64Array([1])
	var previous: PackedVector2Array = PackedVector2Array([Vector2(2.0, 4.0)])
	var current: PackedVector2Array = PackedVector2Array([Vector2(4.0, 8.0)])
	_views.fill(5000, 0.5, ids, previous, current)
	_commit()
	assert_eq(_batches[0].origin_of(0), Vector3(3.0, LIFT, 6.0), "half way, at the lift")


func test_a_full_archetype_batch_skips_an_enemy_and_forgets_its_expired_hit() -> void:
	_build(2, MAX_VIEWS)
	_views.on_spawned(1, 0, 10)
	_views.on_spawned(2, 0, 10)
	_views.on_spawned(3, 0, 10)
	_views.on_spawned(4, 1, 10)
	_views.on_damaged(3, 5, 1000)
	assert_eq(_fill(4, 5000), 3, "the grunts fill their batch of two, the skirmisher is drawn")
	assert_false(_views.has_view(3), "the third grunt did not fit")
	assert_true(_views.has_view(4), "the skirmisher still drew after the skip")
	# Read with the clock set back to the hit, a hit that was not forgotten would flash at 1.0.
	var ids: PackedInt64Array = PackedInt64Array([3, 1])
	assert_eq(_views.fill(1000, 1.0, ids, _line(2), _line(2)), 2, "3 and 1 drawn this time")
	_commit()
	assert_eq(_batches[0].custom_of(0).r, 0.0, "the skipped enemy's expired hit was forgotten")
	assert_eq(_views.hp_of(3), 5, "its hit points are still there")


func test_the_puff_ring_refuses_a_spawn_past_the_capacity() -> void:
	var puffs: NativePuffs = _new_puffs(PUFF_CAPACITY)
	for index: int in range(PUFF_CAPACITY + 2):
		puffs.spawn(Vector3(float(index), 0.8, 0.0), 1.0, Color.WHITE)
	assert_eq(puffs.active_count(), PUFF_CAPACITY, "held at the capacity")
	assert_eq(puffs.refresh(1.0), PUFF_CAPACITY, "and no more than that drawn")


func test_the_puff_ring_draws_the_oldest_first_and_ages_each_puff() -> void:
	var puffs: NativePuffs = _new_puffs(PUFF_CAPACITY)
	var batch: CrowdBatch = _puff_batch
	var tints: Array[Color] = [Color.RED, Color.GREEN, Color.BLUE]
	for index: int in range(3):
		puffs.spawn(Vector3(float(index + 1), 0.8, 0.0), 0.1 * float(index), tints[index])
	var written: int = puffs.refresh(0.3)
	assert_eq(written, 3, "three standing")
	assert_true(batch.commit_buffer(puffs.mirror(), written), "taken by the batch")
	assert_eq(batch.origin_of(0).x, 1.0, "the oldest first")
	assert_eq(batch.origin_of(2).x, 3.0, "the newest last")
	assert_eq(batch.color_of(1), Color.GREEN, "each in its own colour")
	assert_almost_eq(batch.custom_of(0).r, 0.3 / PUFF_S, EPSILON, "age of the oldest")
	assert_almost_eq(batch.custom_of(2).r, 0.1 / PUFF_S, EPSILON, "age of the newest")


func test_no_puff_stands_after_the_lifetime_and_the_slots_come_back() -> void:
	var puffs: NativePuffs = _new_puffs(PUFF_CAPACITY)
	for index: int in range(PUFF_CAPACITY):
		puffs.spawn(Vector3.ZERO, 0.0, Color.WHITE)
	assert_eq(puffs.refresh(PUFF_S), 0, "born at 0, gone at exactly the lifetime")
	assert_eq(puffs.active_count(), 0, "none standing")
	puffs.spawn(Vector3(9.0, 0.8, 0.0), 2.0, Color.WHITE)
	assert_eq(puffs.refresh(2.0), 1, "a freed ring takes a new puff")


func test_the_real_ring_holds_at_128_under_a_flood_of_150() -> void:
	var puffs: NativePuffs = _new_puffs(REAL_PUFFS)
	for index: int in range(PUFF_FLOOD):
		puffs.spawn(Vector3(float(index), 0.8, 0.0), 5.0, Color.WHITE)
	assert_eq(puffs.active_count(), REAL_PUFFS, "128 stand")
	assert_eq(puffs.refresh(5.0), REAL_PUFFS, "and 128 are drawn")


func test_an_unconfigured_ring_or_a_missing_mirror_does_nothing() -> void:
	var bare: NativePuffs = NativePuffs.new()
	bare.spawn(Vector3.ZERO, 1.0, Color.WHITE)
	assert_eq(bare.active_count(), 0, "nothing stands in an unconfigured ring")
	assert_eq(bare.refresh(1.0), 0, "and nothing is drawn")
	bare.configure(0, PUFF_S, NEVER_BORN)
	assert_eq(bare.active_count(), 0, "a capacity of 0 stays unconfigured")
	var no_mirror: NativePuffs = NativePuffs.new()
	no_mirror.configure(PUFF_CAPACITY, PUFF_S, NEVER_BORN)
	no_mirror.spawn(Vector3.ZERO, 1.0, Color.WHITE)
	assert_eq(no_mirror.active_count(), 1, "a puff stands without a mirror")
	assert_eq(no_mirror.refresh(1.0), 0, "but none is drawn")
	assert_false(
		no_mirror.set_mirror(PackedFloat32Array([1.0]), PackedInt64Array([1, 20, 12, 16])), "size"
	)


func _new_puffs(capacity: int) -> NativePuffs:
	var puffs: NativePuffs = NativePuffs.new()
	puffs.configure(capacity, PUFF_S, NEVER_BORN)
	var batch: CrowdBatch = CrowdBatch.new()
	add_child_autofree(batch)
	batch.setup(BoxMesh.new(), StandardMaterial3D.new(), capacity, true)
	assert_true(puffs.set_mirror(batch.mirror(), batch.layout()), "the puff mirror is taken")
	_puff_batch = batch
	return puffs
