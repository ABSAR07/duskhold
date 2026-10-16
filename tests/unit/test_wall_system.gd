extends GutTest
## BLDG-10: a wall plot buys a whole run of segments at once, each segment keeps its own health, a
## hit that reaches 0 breaks it once and leaves a hole, and dawn makes the run whole again for free.
## Every number is read from wall.tres and the wall fixture, so retuning cannot break these tests.

const FIXTURE := "res://tests/fixtures/fixture_map_walls.tres"
const WALL_PATH := "res://data/buildings/wall.tres"
const RING: StringName = &"wall_ring"
const TOWER: StringName = &"tower_1"
const SEGMENTS_IN_RING: int = 32
const SEGMENT_METRES: float = 3.0
const TOLERANCE: float = 0.0001

var _map: MapConfig
var _wall: BuildingDef
var _events: SimEvents
var _buildings: BuildingSystem
var _walls: WallSystem


func before_each() -> void:
	_map = load(FIXTURE)
	_wall = load(WALL_PATH)
	_events = SimEvents.new()
	_buildings = BuildingSystem.new(_map, _events)
	_walls = WallSystem.new(_map, _buildings, _events)


func _tier_health(tier: int) -> int:
	return _wall.tier_def(tier).max_health


func _build(times: int = 1) -> void:
	for _step: int in range(times):
		_buildings.apply_next_tier(RING)


func _params(signal_name: String, index: int) -> Array:
	var params: Variant = get_signal_parameters(_events, signal_name, index)
	return params as Array if params != null else []


func _run(
	points: PackedVector2Array, gaps: PackedVector2Array = PackedVector2Array()
) -> WallRunDef:
	var run: WallRunDef = WallRunDef.new()
	run.points = points
	run.gaps = gaps
	return run


func test_the_closed_ring_expands_to_32_segments_of_3_m_ending_on_the_corners() -> void:
	var expanded: PackedInt32Array = _map.spots[1].wall_run.expand()
	assert_eq(expanded.size(), SEGMENTS_IN_RING * 4, "four numbers per segment")
	assert_eq(
		Array(expanded.slice(0, 4)),
		[-1200, -1200, -900, -1200],
		"the first segment, in centimetres"
	)
	assert_eq(_walls.segment_count(), SEGMENTS_IN_RING, "the system holds them all")
	for segment: int in range(SEGMENTS_IN_RING):
		var length: float = _walls.segment_start(segment).distance_to(_walls.segment_end(segment))
		assert_almost_eq(length, SEGMENT_METRES, TOLERANCE, "segment %d is 3 m long" % segment)
	assert_eq(_walls.segment_end(7), Vector2(12.0, -12.0), "the first corner ends a segment")
	assert_eq(_walls.segment_end(15), Vector2(12.0, 12.0), "the second corner")
	assert_eq(_walls.segment_end(23), Vector2(-12.0, 12.0), "the third corner")
	assert_eq(_walls.segment_end(31), Vector2(-12.0, -12.0), "the ring closes where it began")


func test_a_gap_stays_exactly_as_wide_as_authored() -> void:
	var line: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(20.0, 0.0)])
	var expanded: PackedInt32Array = _run(line, PackedVector2Array([Vector2(16.0, 20.0)])).expand()
	assert_eq(expanded.size(), 6 * 4, "16 m of wall in pieces of at most 3 m make six segments")
	assert_eq(expanded[0], 0, "the wall starts at the start of the path")
	assert_eq(expanded[expanded.size() - 2], 1600, "and stops where the gap begins")
	for index: int in range(0, expanded.size(), 4):
		assert_lt(maxi(expanded[index], expanded[index + 2]), 1601, "nothing inside the gap")
		var length: int = expanded[index + 2] - expanded[index]
		assert_between(length, 266, 267, "six equal pieces of 2.67 m")


func test_unusable_run_data_expands_to_nothing() -> void:
	var line: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(20.0, 0.0)])
	var nan_run: WallRunDef = _run(PackedVector2Array([Vector2(0.0, 0.0), Vector2(NAN, 0.0)]))
	assert_true(nan_run.expand().is_empty(), "a NaN point")
	var zero_length: WallRunDef = _run(line)
	zero_length.segment_length = 0.0
	assert_true(zero_length.expand().is_empty(), "a segment length of zero")
	zero_length.segment_length = -1.0
	assert_true(zero_length.expand().is_empty(), "a negative segment length")
	var too_many: WallRunDef = _run(line)
	too_many.segment_length = 0.05
	assert_true(too_many.expand().is_empty(), "more than MAX_SEGMENTS_PER_RUN pieces")
	assert_eq(too_many.segment_count(), 0, "and a count of zero")
	var one_point: WallRunDef = _run(PackedVector2Array([Vector2(1.0, 1.0)]))
	assert_true(one_point.expand().is_empty(), "a single point is no line")
	var bad_gap: WallRunDef = _run(line, PackedVector2Array([Vector2(INF, 5.0)]))
	assert_true(bad_gap.expand().is_empty(), "a non-finite gap")


func test_before_any_purchase_no_segment_stands() -> void:
	assert_eq(_walls.intact_count(), 0, "nothing stands")
	assert_false(_walls.is_intact(0), "not even the first")
	assert_eq(_walls.max_health_of(0), 0, "an unbuilt segment has no maximum")
	assert_eq(_walls.version(), 0, "and nothing has changed yet")


func test_one_purchase_builds_every_segment_at_the_tiers_per_segment_health() -> void:
	var before: int = _walls.version()
	_build()
	assert_eq(_walls.intact_count(), SEGMENTS_IN_RING, "the whole run stands")
	for segment: int in range(SEGMENTS_IN_RING):
		assert_eq(_walls.health_of(segment), _tier_health(1), "segment %d health" % segment)
		assert_eq(_walls.max_health_of(segment), _tier_health(1), "segment %d max" % segment)
	assert_gt(_walls.version(), before, "the purchase bumps the version")


func test_each_upgrade_raises_every_segment() -> void:
	_build()
	_walls.damage_segment(3, 5)
	_build()
	for segment: int in range(SEGMENTS_IN_RING):
		assert_eq(_walls.health_of(segment), _tier_health(2), "tier II whole at %d" % segment)
	_build()
	assert_eq(_walls.health_of(10), _tier_health(3), "and tier III")
	assert_eq(_walls.max_health_of(10), _tier_health(3), "max follows the tier")


func test_a_hit_reports_the_points_lost_what_is_left_and_the_maximum() -> void:
	_build()
	watch_signals(_events)
	_walls.damage_segment(4, 7)
	assert_signal_emit_count(_events, "wall_damaged", 1)
	assert_eq(_params("wall_damaged", 0), [RING, 4, 7, _tier_health(1) - 7, _tier_health(1)])
	assert_eq(_walls.health_of(4), _tier_health(1) - 7, "only that segment lost health")
	assert_eq(_walls.health_of(5), _tier_health(1), "its neighbour is untouched")
	assert_signal_not_emitted(_events, "wall_segment_broken")


func test_a_hit_for_exactly_the_remaining_health_breaks_the_segment_once() -> void:
	_build()
	_walls.damage_segment(6, _tier_health(1) - 5)
	var version: int = _walls.version()
	watch_signals(_events)
	_walls.damage_segment(6, 5)
	assert_eq(_params("wall_damaged", 0), [RING, 6, 5, 0, _tier_health(1)], "the last 5 points")
	assert_signal_emit_count(_events, "wall_segment_broken", 1)
	assert_eq(_params("wall_segment_broken", 0), [RING, 6])
	assert_false(_walls.is_intact(6), "it is a hole now")
	assert_eq(_walls.intact_count(), SEGMENTS_IN_RING - 1, "one fewer stands")
	assert_gt(_walls.version(), version, "the break bumps the version")


func test_an_overkill_hit_reports_only_the_points_lost() -> void:
	_build()
	_walls.damage_segment(2, _tier_health(1) - 7)
	watch_signals(_events)
	_walls.damage_segment(2, _tier_health(1))
	assert_eq(_params("wall_damaged", 0), [RING, 2, 7, 0, _tier_health(1)], "7 points were left")
	assert_eq(_walls.health_of(2), 0, "never below zero")


func test_a_hit_on_nothing_that_stands_drops_silently() -> void:
	_build()
	_walls.damage_segment(1, _tier_health(1))
	watch_signals(_events)
	var version: int = _walls.version()
	_walls.damage_segment(1, 3)
	_walls.damage_segment(-1, 3)
	_walls.damage_segment(999, 3)
	_walls.damage_segment(0, 0)
	_walls.damage_segment(0, -4)
	assert_signal_not_emitted(_events, "wall_damaged")
	assert_signal_not_emitted(_events, "wall_segment_broken")
	assert_eq(_walls.health_of(0), _tier_health(1), "a non-positive amount changes nothing")
	assert_eq(_walls.version(), version, "and neither does a hit on a hole")


func test_a_hit_on_a_segment_nobody_built_drops_silently() -> void:
	watch_signals(_events)
	_walls.damage_segment(0, 3)
	assert_signal_not_emitted(_events, "wall_damaged")
	assert_eq(_walls.health_of(0), 0, "still unbuilt")


func test_a_broken_segment_stays_broken_through_an_upgrade_until_dawn() -> void:
	_build()
	_walls.damage_segment(9, _tier_health(1))
	watch_signals(_events)
	_buildings.apply_next_tier(RING)
	assert_eq(_walls.health_of(9), 0, "the hole is still open")
	assert_eq(_walls.max_health_of(9), _tier_health(2), "but its maximum follows the tier")
	assert_false(_walls.is_intact(9), "and it does not stand")
	assert_eq(_walls.health_of(8), _tier_health(2), "a standing segment is raised")
	assert_eq(_walls.intact_count(), SEGMENTS_IN_RING - 1, "one hole")
	assert_signal_not_emitted(_events, "wall_segment_broken")
	assert_signal_not_emitted(_events, "wall_damaged")
	var restored: Array[StringName] = _walls.restore_all()
	assert_eq(restored, [RING] as Array[StringName], "dawn rebuilds it")
	assert_true(_walls.is_intact(9), "now it stands")
	assert_eq(_walls.health_of(9), _tier_health(2), "at the full health of the tier")


func test_dawn_heals_and_rebuilds_once_and_a_second_call_changes_nothing() -> void:
	_build()
	_walls.damage_segment(12, 4)
	_walls.damage_segment(13, _tier_health(1))
	var version: int = _walls.version()
	watch_signals(_events)
	var restored: Array[StringName] = _walls.restore_all()
	assert_eq(restored, [RING] as Array[StringName], "the run that changed")
	assert_signal_emit_count(_events, "walls_restored", 1)
	assert_eq(_params("walls_restored", 0), [[RING]], "announced once with the run")
	assert_eq(_walls.health_of(12), _tier_health(1), "the damaged segment is healed")
	assert_eq(_walls.health_of(13), _tier_health(1), "the broken segment is rebuilt")
	assert_gt(_walls.version(), version, "a hole closing bumps the version")
	var again: Array[StringName] = _walls.restore_all()
	assert_true(again.is_empty(), "a second restore finds nothing")
	assert_signal_emit_count(_events, "walls_restored", 1)


func test_a_dawn_with_every_segment_whole_emits_nothing() -> void:
	_build()
	watch_signals(_events)
	assert_true(_walls.restore_all().is_empty(), "nothing to restore")
	assert_signal_not_emitted(_events, "walls_restored")
	var bare: WallSystem = WallSystem.new(_map, _buildings, SimEvents.new())
	assert_true(bare.restore_all().is_empty(), "an unbuilt run is not restored either")


func test_segment_indices_ascend_in_spot_order_and_name_their_owner() -> void:
	var map: MapConfig = _map.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	var east: BuildSpotDef = BuildSpotDef.new()
	east.id = &"wall_east"
	east.position = Vector3(40.0, 0.0, 0.0)
	east.building_id = &"wall"
	east.wall_run = _run(PackedVector2Array([Vector2(30.0, 0.0), Vector2(30.0, 9.0)]))
	map.spots.append(east)
	var buildings: BuildingSystem = BuildingSystem.new(map, _events)
	var walls: WallSystem = WallSystem.new(map, buildings, _events)
	assert_eq(walls.segment_count(), SEGMENTS_IN_RING + 3, "the ring then three more")
	assert_eq(walls.spot_of(0), RING, "the first belongs to the ring")
	assert_eq(walls.spot_of(31), RING, "so does the last of the ring")
	assert_eq(walls.spot_of(32), &"wall_east", "the next plot follows in map order")
	assert_eq(Array(walls.segments_of(&"wall_east")), [32, 33, 34], "its segments, ascending")
	assert_true(walls.segments_of(TOWER).is_empty(), "a tower plot has none")
	assert_eq(walls.spot_of(99), &"", "an index out of range has no owner")


func test_segments_near_lists_each_segment_once_in_ascending_order() -> void:
	var corner: PackedInt32Array = _walls.segments_near(Vector2(12.0, -12.0), 1.0)
	assert_gt(corner.size(), 1, "a corner touches more than one segment")
	for index: int in range(1, corner.size()):
		assert_gt(corner[index], corner[index - 1], "strictly ascending, so no repeats")
	assert_true(_walls.segments_near(Vector2(0.0, 0.0), 1.0).is_empty(), "the castle is clear")
	assert_true(_walls.segments_near(Vector2.ZERO, NAN).is_empty(), "a bad reach finds nothing")


func test_a_purchase_on_a_plot_that_is_not_a_wall_changes_nothing() -> void:
	var version: int = _walls.version()
	_buildings.apply_next_tier(TOWER)
	assert_eq(_walls.version(), version, "a tower is not a wall")
	assert_eq(_walls.intact_count(), 0, "and no segment stands")
