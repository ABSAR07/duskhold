extends GutTest
## D-11, T-05-16, research Open Question 2 (RESOLVED): the visual-only pond. The shipped layout is
## pinned (the pond holds no plot and no spawn point, every spawn-to-castle road keeps at least 18 m
## from its centre, the Harbor stands on its shore, the water lies on the ground) and
## MapConfig.validate() reports a pond that breaks those rules or carries numbers that are not
## finite. A radius of 0 means no pond and passes. The pond never enters the nav grid
## (test_nav_layout_pin), so none of this can move an enemy path.

const PROTOTYPE := "res://data/maps/prototype_map.tres"
const HARBOR: StringName = &"harbor_1"
## Every road keeps the pond radius (8) plus the validator's 10 m of clear water between them.
const MIN_ROAD_CENTRE_M: float = 18.0
const MAX_SHORE_GAP_M: float = 3.0
const WEST: StringName = &"west"


func _shipped() -> MapConfig:
	return load(PROTOTYPE)


func _copy() -> MapConfig:
	return (load(PROTOTYPE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)


func _ground(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z)


func _spot(map: MapConfig, spot_id: StringName) -> BuildSpotDef:
	for spot: BuildSpotDef in map.spots:
		if spot.id == spot_id:
			return spot
	return null


func _spawn(map: MapConfig, spawn_id: StringName) -> SpawnPointDef:
	return map.find_spawn_point(spawn_id)


func _has(problems: Array[String], needle: String) -> bool:
	for problem: String in problems:
		if problem.contains(needle):
			return true
	return false


func _pond_problems(map: MapConfig) -> Array[String]:
	return EconomyValidation.problems(map)


func test_the_shipped_pond_holds_no_plot_and_no_spawn_point() -> void:
	var map: MapConfig = _shipped()
	for spot: BuildSpotDef in map.spots:
		var apart: float = _ground(spot.position).distance_to(map.pond_center)
		assert_gt(apart, map.pond_radius, "%s is %.1f m from the pond centre" % [spot.id, apart])
	for spawn: SpawnPointDef in map.spawn_points:
		var apart: float = _ground(spawn.position).distance_to(map.pond_center)
		assert_gt(
			apart, map.pond_radius, "spawn %s is %.1f m from the pond centre" % [spawn.id, apart]
		)


func test_every_spawn_to_castle_road_keeps_eighteen_metres_from_the_pond_centre() -> void:
	var map: MapConfig = _shipped()
	var castle: Vector2 = _ground(map.castle_position)
	for spawn: SpawnPointDef in map.spawn_points:
		var at: Vector2 = _ground(spawn.position)
		var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(map.pond_center, at, castle)
		var apart: float = nearest.distance_to(map.pond_center)
		assert_gte(apart, MIN_ROAD_CENTRE_M, "the %s road is %.1f m away" % [spawn.id, apart])


func test_the_harbor_stands_within_three_metres_of_the_pond_edge() -> void:
	var map: MapConfig = _shipped()
	var harbor: BuildSpotDef = _spot(map, HARBOR)
	var to_centre: float = _ground(harbor.position).distance_to(map.pond_center)
	var gap: float = to_centre - map.pond_radius
	assert_gt(gap, 0.0, "on the shore, not in the water")
	assert_lte(gap, MAX_SHORE_GAP_M, "%.1f m from the water's edge" % gap)
	assert_lt(harbor.position.z, map.pond_center.y, "on the north shore")


func test_the_pond_lies_inside_the_ground() -> void:
	var map: MapConfig = _shipped()
	var extent: float = map.ground_half_extent
	assert_lte(absf(map.pond_center.x) + map.pond_radius, extent, "inside along x")
	assert_lte(absf(map.pond_center.y) + map.pond_radius, extent, "inside along z")


func test_the_shipped_pond_validates_clean_and_is_not_a_plot() -> void:
	var map: MapConfig = _shipped()
	assert_eq(_pond_problems(map), [] as Array[String], "no pond problem")
	assert_eq(map.validate().size(), 0, "and validate() is clean as a whole")
	assert_null(_spot(map, &"pond"), "the pond is data of the map, never a plot")


func test_a_radius_of_zero_means_no_pond_and_passes() -> void:
	var map: MapConfig = _copy()
	map.pond_radius = 0.0
	assert_eq(_pond_problems(map), [] as Array[String], "no pond, nothing to check")
	map.pond_center = _ground(_spot(map, HARBOR).position)
	assert_eq(_pond_problems(map), [] as Array[String], "wherever the unused centre lies")


func test_a_centre_that_is_not_finite_is_reported() -> void:
	for bad: float in [NAN, INF]:
		var map: MapConfig = _copy()
		map.pond_center = Vector2(bad, 30.0)
		assert_true(_has(_pond_problems(map), "pond_center"), "x = %s" % bad)
		map.pond_center = Vector2(0.0, -bad)
		assert_true(_has(_pond_problems(map), "pond_center"), "z = %s" % -bad)


func test_a_radius_that_is_not_finite_negative_or_above_thirty_is_reported() -> void:
	for bad: float in [NAN, INF, -1.0, 31.0]:
		var map: MapConfig = _copy()
		map.pond_radius = bad
		assert_true(_has(_pond_problems(map), "pond_radius"), "radius %s" % bad)


func test_a_radius_of_exactly_thirty_is_not_reported_for_its_size() -> void:
	var map: MapConfig = _copy()
	map.pond_radius = EconomyValidation.MAX_POND_RADIUS
	assert_false(_has(_pond_problems(map), "expected at most"), "30 m is the inclusive limit")


func test_a_pond_moved_over_the_harbor_plot_is_reported() -> void:
	var map: MapConfig = _copy()
	map.pond_center = _ground(_spot(map, HARBOR).position)
	assert_true(_has(_pond_problems(map), "contains plot 'harbor_1'"), "the plot")


func test_a_pond_moved_over_a_spawn_point_is_reported() -> void:
	var map: MapConfig = _copy()
	map.pond_center = _ground(_spawn(map, WEST).position)
	assert_true(_has(_pond_problems(map), "contains spawn point 'west'"), "the spawn")


func test_a_pond_within_radius_plus_ten_metres_of_a_road_is_reported() -> void:
	var map: MapConfig = _copy()
	var castle: Vector2 = _ground(map.castle_position)
	var start: Vector2 = _ground(_spawn(map, WEST).position)
	var middle: Vector2 = (start + castle) * 0.5
	var along: Vector2 = (castle - start).normalized()
	# Twelve metres off the road with a radius of 8: under the 18 m the validator wants.
	map.pond_center = middle + along.orthogonal() * 12.0
	assert_true(_has(_pond_problems(map), "road"), "the west road")


func test_a_pond_eighteen_and_a_half_metres_from_the_west_road_is_not_reported_for_it() -> void:
	var map: MapConfig = _copy()
	var castle: Vector2 = _ground(map.castle_position)
	var start: Vector2 = _ground(_spawn(map, WEST).position)
	var middle: Vector2 = (start + castle) * 0.5
	var along: Vector2 = (castle - start).normalized()
	map.pond_radius = 8.0
	map.pond_center = middle - along.orthogonal() * 18.5
	assert_false(_has(_pond_problems(map), "west"), "18.5 m is clear of the west road")
