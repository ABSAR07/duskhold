extends GutTest
## PLAT-01 (plan 04-17, rule 10 and threats T-04-45 and T-04-46): the native wall mirror answers
## what the GDScript answered for bad input (-1, the zero vector, an empty array), and the copy that
## WallSystem keeps in step never disagrees with WallSystem about which segments stand. The answers
## to good input are pinned by test_wall_geometry_pins.

const WALL_PATH := "res://data/buildings/wall.tres"
const RUN_ID: StringName = &"wall_line"
const HALF: float = 0.4
const RADIUS: float = 0.5
const BREAK_DAMAGE: int = 1000000

var _events: SimEvents
var _buildings: BuildingSystem
var _walls: WallSystem


func before_each() -> void:
	var map: MapConfig = MapConfig.new()
	map.id = &"native_walls"
	map.buildings.append(load(WALL_PATH))
	var run: WallRunDef = WallRunDef.new()
	run.points = PackedVector2Array([Vector2(0.0, 0.0), Vector2(12.0, 0.0)])
	run.half_thickness = HALF
	var spot: BuildSpotDef = BuildSpotDef.new()
	spot.id = RUN_ID
	spot.building_id = &"wall"
	spot.wall_run = run
	map.spots.append(spot)
	_events = SimEvents.new()
	_buildings = BuildingSystem.new(map, _events)
	_walls = WallSystem.new(map, _buildings, _events)


func _agree() -> bool:
	var mirror: NativeWalls = _walls.native()
	if mirror.intact_count() != _walls.intact_count():
		return false
	for segment: int in range(-1, _walls.segment_count() + 1):
		if mirror.is_intact(segment) != _walls.is_intact(segment):
			return false
	return true


func test_a_fresh_mirror_has_nothing_standing() -> void:
	var mirror: NativeWalls = _walls.native()
	assert_eq(mirror.intact_count(), 0, "nothing is built yet")
	assert_false(mirror.is_intact(0), "an unbuilt segment does not stand")
	assert_eq(mirror.first_blocking(Vector2(1.5, -3.0), Vector2(1.5, 3.0), RADIUS), -1, "clear")
	var inside: Vector2 = Vector2(1.5, 0.2)
	assert_eq(mirror.push_out(inside, RADIUS), inside, "pushes nothing")


func test_the_mirror_follows_a_purchase_a_break_and_the_dawn_restore() -> void:
	_buildings.apply_next_tier(RUN_ID)
	assert_true(_agree(), "after the purchase")
	assert_eq(_walls.native().intact_count(), _walls.segment_count(), "all standing")
	_walls.damage_segment(1, BREAK_DAMAGE)
	assert_true(_agree(), "after a break")
	assert_false(_walls.native().is_intact(1), "the broken one is a hole")
	assert_eq(_walls.native().intact_count(), _walls.segment_count() - 1, "one fewer")
	_walls.restore_all()
	assert_true(_agree(), "after the dawn restore")
	assert_true(_walls.native().is_intact(1), "whole again")


func test_a_hit_that_does_not_break_keeps_the_segment_standing_in_the_mirror() -> void:
	_buildings.apply_next_tier(RUN_ID)
	_walls.damage_segment(0, 1)
	assert_gt(_walls.health_of(0), 0, "still has health")
	assert_true(_walls.native().is_intact(0), "and still stands natively")
	assert_true(_agree(), "in step")


func test_a_tier_purchase_leaves_a_broken_segment_broken_in_the_mirror() -> void:
	_buildings.apply_next_tier(RUN_ID)
	_walls.damage_segment(2, BREAK_DAMAGE)
	_buildings.apply_next_tier(RUN_ID)
	assert_false(_walls.is_intact(2), "broken until dawn (D-05)")
	assert_true(_agree(), "the mirror says so too")


func test_indices_out_of_range_answer_the_zero_vector_and_false() -> void:
	_buildings.apply_next_tier(RUN_ID)
	var mirror: NativeWalls = _walls.native()
	var count: int = _walls.segment_count()
	for segment: int in [-1, count, count + 5, -100, 1 << 40]:
		assert_eq(
			mirror.closest_point(segment, Vector2(3.0, 4.0)), Vector2.ZERO, "zero for %d" % segment
		)
		assert_false(mirror.is_intact(segment), "%d does not stand" % segment)
	mirror.set_health(-1, 5)
	mirror.set_health(count, 5)
	assert_true(_agree(), "a health write out of range is ignored")


func test_a_non_finite_or_negative_reach_gives_an_empty_array() -> void:
	_buildings.apply_next_tier(RUN_ID)
	var mirror: NativeWalls = _walls.native()
	for reach: float in [INF, -INF, NAN, -1.0, -0.0001]:
		assert_true(mirror.segments_near(Vector2(1.0, 0.0), reach).is_empty(), "reach %s" % reach)
	assert_false(mirror.segments_near(Vector2(1.0, 0.0), 0.0).is_empty(), "a zero reach is fine")
	var line: int = mirror.first_blocking(Vector2.ZERO, Vector2(INF, 0.0), RADIUS)
	assert_eq(line, -1, "a line to infinity blocks nothing")
	var pos: Vector2 = Vector2(1.5, 0.2)
	assert_eq(mirror.push_out(pos, NAN), pos, "a NaN radius pushes nothing")


func test_a_mirror_set_up_with_mismatched_arrays_is_empty() -> void:
	var mirror: NativeWalls = NativeWalls.new()
	mirror.setup(
		PackedVector2Array([Vector2.ZERO, Vector2.ONE]),
		PackedVector2Array([Vector2.RIGHT]),
		PackedFloat64Array([0.4, 0.4])
	)
	mirror.set_health(0, 10)
	assert_eq(mirror.intact_count(), 0, "no segments")
	assert_true(mirror.segments_near(Vector2.ZERO, 5.0).is_empty(), "nothing near")
	assert_eq(mirror.first_blocking(Vector2(-5.0, 0.0), Vector2(5.0, 0.0), 0.5), -1, "no line")
