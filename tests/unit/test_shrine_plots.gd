extends GutTest
## D-09, D-12, research P3 and E5: the two Shrine plots of the prototype map. Plan 05-09 appends
## shrine_west at (-46, 0, 30) and shrine_east at (46, 0, 30) as spots 22 and 23 (index 21 and 22),
## each beside a road so that enemies die near it and it can wake (within 15 m of a spawn-to-castle
## segment), yet clear of it (12 m or more), inside the nav content box so NavGrid keeps its layout,
## and apart from every other plot. The generic Phase 5 plot rules in test_prototype_map_economy
## cover them too; this script holds what is specific to the Shrines. That script is at the 20-test
## cap, so these tests live here.

const PROTOTYPE := "res://data/maps/prototype_map.tres"
const WEST: StringName = &"shrine_west"
const EAST: StringName = &"shrine_east"
const WEST_INDEX: int = 21
const EAST_INDEX: int = 22
const WEST_AT := Vector3(-46.0, 0.0, 30.0)
const EAST_AT := Vector3(46.0, 0.0, 30.0)
const NEAR_ROAD_M: float = 15.0
const MIN_ROAD_CLEARANCE_M: float = 12.0
const MIN_PLOT_SPACING_M: float = 5.0


func _map() -> MapConfig:
	return load(PROTOTYPE)


func _ground(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z)


func _spot(map: MapConfig, spot_id: StringName) -> BuildSpotDef:
	for spot: BuildSpotDef in map.spots:
		if spot.id == spot_id:
			return spot
	return null


func _road_distance(map: MapConfig, point: Vector2) -> float:
	var nearest: float = INF
	var castle: Vector2 = _ground(map.castle_position)
	for spawn: SpawnPointDef in map.spawn_points:
		var on_road: Vector2 = Geometry2D.get_closest_point_to_segment(
			point, _ground(spawn.position), castle
		)
		nearest = minf(nearest, point.distance_to(on_road))
	return nearest


func test_the_shrines_are_the_last_two_spots_in_order() -> void:
	var map: MapConfig = _map()
	assert_eq(map.spots[WEST_INDEX].id, WEST, "shrine_west is index 21")
	assert_eq(map.spots[EAST_INDEX].id, EAST, "shrine_east is index 22")
	assert_eq(map.spots.size(), EAST_INDEX + 1, "nothing follows")


func test_each_shrine_stands_where_the_plan_puts_it_and_takes_the_shrine() -> void:
	var map: MapConfig = _map()
	for pair: Array in [[WEST, WEST_AT], [EAST, EAST_AT]]:
		var spot: BuildSpotDef = _spot(map, pair[0])
		assert_eq(spot.building_id, &"shrine", "%s takes the Shrine" % pair[0])
		assert_eq(spot.position, pair[1], "%s is at the planned place" % pair[0])
		assert_null(spot.wall_run, "%s is no wall plot" % pair[0])
		assert_false(spot.is_castle, "%s is not the castle plot" % pair[0])
		assert_eq(spot.requires_spot, &"", "%s needs no other plot" % pair[0])


func test_each_shrine_is_beside_a_road_so_enemies_pass_and_clear_of_it() -> void:
	var map: MapConfig = _map()
	for spot_id: StringName in [WEST, EAST]:
		var apart: float = _road_distance(map, _ground(_spot(map, spot_id).position))
		assert_lte(apart, NEAR_ROAD_M, "%s is %.1f m from a road: enemies pass" % [spot_id, apart])
		assert_gte(apart, MIN_ROAD_CLEARANCE_M, "%s is %.1f m: clear of it" % [spot_id, apart])


func test_each_shrine_stands_five_metres_from_every_other_plot() -> void:
	var map: MapConfig = _map()
	for spot_id: StringName in [WEST, EAST]:
		var here: Vector2 = _ground(_spot(map, spot_id).position)
		for other: BuildSpotDef in map.spots:
			if other.id == spot_id or other.wall_run != null:
				continue
			var apart: float = here.distance_to(_ground(other.position))
			assert_gte(
				apart, MIN_PLOT_SPACING_M, "%s is %.1f m from %s" % [spot_id, apart, other.id]
			)


func test_the_shrines_are_apart_and_mirror_each_other() -> void:
	var map: MapConfig = _map()
	var west: Vector3 = _spot(map, WEST).position
	var east: Vector3 = _spot(map, EAST).position
	assert_eq(west.x, -east.x, "mirrored across the road centre")
	assert_eq(west.z, east.z, "at the same depth")


func test_the_shipped_shrine_is_an_awakened_building_with_its_own_stats() -> void:
	var def: BuildingDef = null
	for building_def: BuildingDef in _map().buildings:
		if building_def.id == &"shrine":
			def = building_def
	assert_not_null(def, "the map lists the Shrine")
	assert_eq(def.income_curve, BuildingDef.IncomeCurve.AWAKENED, "awakened curve")
	assert_eq(def.max_tier(), 1, "one tier")
	assert_eq(def.damage_stat, &"shrine.damage", "its own damage stat")
	assert_eq(def.range_stat, &"shrine.range", "its own range stat")
	assert_true(StatIds.is_known(def.damage_stat), "which the registry knows")
	assert_true(StatIds.is_known(def.range_stat), "and so is the range")
