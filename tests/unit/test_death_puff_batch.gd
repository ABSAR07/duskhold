extends GutTest
## DeathPuffBatch (PLAT-01): a ring of 128 puffs that replaces one particle node and one timer per
## death. A puff lives EnemyViews.PUFF_SECONDS of real time, grows and fades from its age in the
## instance's custom data, and a puff past the cap is not drawn. The tests pass the clock in, so no
## test waits; nothing reads the MultiMesh back (RESEARCH F6).

const EPSILON: float = 0.0001
const ORIGIN := Vector3(4.0, 0.8, -6.0)
const TINT := Color(0.75, 0.18, 0.15)

var _puffs: DeathPuffBatch


func before_each() -> void:
	_puffs = DeathPuffBatch.new()
	add_child_autofree(_puffs)


func test_setup_allocates_the_ring() -> void:
	assert_eq(DeathPuffBatch.MAX_PUFFS, 128, "the ring holds 128 puffs")
	assert_true(_puffs.setup_puffs(), "setup succeeds")
	assert_eq(_puffs.capacity(), DeathPuffBatch.MAX_PUFFS, "one slot per puff")
	assert_eq(_puffs.active_count(), 0, "nothing stands yet")
	assert_eq(_puffs.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "no shadow")


func test_a_puff_stands_for_its_lifetime_and_carries_its_age() -> void:
	_puffs.setup_puffs()
	_puffs.spawn(ORIGIN, 10.0, TINT)
	assert_eq(_puffs.active_count(), 1, "it stands the moment it is spawned")
	_puffs.refresh(10.0 + EnemyViews.PUFF_SECONDS * 0.5)
	assert_eq(_puffs.count(), 1, "one instance drawn")
	assert_almost_eq(_puffs.custom_of(0).r, 0.5, EPSILON, "half way through its life")
	assert_eq(_puffs.origin_of(0), ORIGIN, "where it was spawned")
	assert_eq(_puffs.color_of(0), TINT, "in the colour it was given")
	assert_eq(_puffs.multimesh.visible_instance_count, 1, "and shown")


func test_a_puff_is_gone_after_its_lifetime() -> void:
	_puffs.setup_puffs()
	_puffs.spawn(ORIGIN, 10.0)
	_puffs.refresh(10.0 + EnemyViews.PUFF_SECONDS + EPSILON)
	assert_eq(_puffs.active_count(), 0, "no puff left")
	assert_eq(_puffs.count(), 0, "none drawn")
	assert_eq(_puffs.multimesh.visible_instance_count, 0, "an empty ring shows nothing")


func test_puffs_past_the_cap_in_one_frame_are_not_drawn() -> void:
	_puffs.setup_puffs()
	for index: int in range(DeathPuffBatch.MAX_PUFFS + 22):
		_puffs.spawn(ORIGIN + Vector3(float(index), 0.0, 0.0), 5.0)
	assert_eq(_puffs.active_count(), DeathPuffBatch.MAX_PUFFS, "held at the cap")
	_puffs.refresh(5.0)
	assert_eq(_puffs.count(), DeathPuffBatch.MAX_PUFFS, "and no more than the cap drawn")
	assert_eq(_puffs.origin_of(0).x, ORIGIN.x, "the first puffs are the ones kept")


func test_slots_come_back_once_their_puffs_have_faded() -> void:
	_puffs.setup_puffs()
	for index: int in range(DeathPuffBatch.MAX_PUFFS):
		_puffs.spawn(ORIGIN, 0.0)
	var later: float = EnemyViews.PUFF_SECONDS + 0.4
	_puffs.spawn(ORIGIN + Vector3.RIGHT, later)
	_puffs.spawn(ORIGIN + Vector3.LEFT, later)
	_puffs.refresh(later)
	assert_eq(_puffs.active_count(), 2, "only the two new puffs stand")
	assert_eq(_puffs.count(), 2, "and only they are drawn")
