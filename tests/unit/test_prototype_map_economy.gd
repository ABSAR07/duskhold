extends GutTest
## D-09 and research Open Question 1 (RESOLVED): the prototype map's plot counts, pinned in one
## place. The castle plot is infrastructure: the map ends the phase with 22 buildable plots and 23
## spots (the 22 plus the castle plot). After plan 05-02 it has 15 spots: the fourteen Phase 4 plots
## and castle_plot appended last (so no PendingHits building index moves). Plans 05-06 to 05-09 add
## their plots and raise the numbers below, this file being the single place they change.

const PROTOTYPE := "res://data/maps/prototype_map.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const CASTLE: StringName = &"castle_plot"
const SPOT_COUNT: int = 15
const BUILDABLE_PLOT_COUNT: int = 14
const CASTLE_PLOT_INDEX: int = 14
## The castle plot stands this far (at most) outside the keep's edge.
const MAX_GAP_TO_KEEP_M: float = 3.0


func _map() -> MapConfig:
	return load(PROTOTYPE)


func _ground(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z)


func _castle_spots(map: MapConfig) -> Array[BuildSpotDef]:
	var found: Array[BuildSpotDef] = []
	for spot: BuildSpotDef in map.spots:
		if spot.is_castle:
			found.append(spot)
	return found


func test_the_map_has_fifteen_spots() -> void:
	assert_eq(_map().spots.size(), SPOT_COUNT, "14 Phase 4 plots plus the castle plot")


func test_exactly_one_spot_is_the_castle_plot_and_it_is_appended_last() -> void:
	var map: MapConfig = _map()
	var castle_spots: Array[BuildSpotDef] = _castle_spots(map)
	assert_eq(castle_spots.size(), 1, "one castle plot")
	assert_eq(map.spots[CASTLE_PLOT_INDEX].id, CASTLE, "it is spot 15 (index 14)")
	assert_true(map.spots[CASTLE_PLOT_INDEX].is_castle, "marked in data")
	assert_eq(map.spots[CASTLE_PLOT_INDEX].building_id, &"castle_center", "buys the castle")


func test_fourteen_buildable_plots_besides_the_castle() -> void:
	var buildable: int = 0
	for spot: BuildSpotDef in _map().spots:
		if not spot.is_castle:
			buildable += 1
	assert_eq(buildable, BUILDABLE_PLOT_COUNT, "the 14 plots the Phase 4 map had")


func test_the_shipped_map_validates_clean() -> void:
	var errors: PackedStringArray = _map().validate()
	assert_eq(errors.size(), 0, "no validation error: %s" % [errors])


func test_the_castle_plot_id_is_not_the_reserved_payout_key() -> void:
	assert_ne(CASTLE, MapConfig.CASTLE_PAYOUT_KEY, "castle is reserved for the payout")


func test_the_castle_plot_is_clear_of_the_king_spawn() -> void:
	var map: MapConfig = _map()
	var tuning: LoopTuning = load(TUNING)
	var plot: BuildSpotDef = _castle_spots(map)[0]
	var apart: float = _ground(plot.position).distance_to(_ground(map.king_spawn))
	assert_gt(apart, tuning.interaction_radius, "the castle label does not pop up at spawn")


func test_the_castle_plot_stands_just_outside_the_keep() -> void:
	var map: MapConfig = _map()
	var plot: BuildSpotDef = _castle_spots(map)[0]
	var apart: float = _ground(plot.position).distance_to(_ground(map.castle_position))
	assert_gt(apart, map.castle_radius, "outside the keep")
	assert_lt(apart, map.castle_radius + MAX_GAP_TO_KEEP_M, "and within a few metres of it")


func test_the_castle_plot_is_inside_the_ring_wall() -> void:
	var map: MapConfig = _map()
	var plot: Vector2 = _ground(_castle_spots(map)[0].position)
	for spot: BuildSpotDef in map.spots:
		if spot.id == &"wall_ring":
			for point: Vector2 in spot.wall_run.points:
				assert_lt(plot.distance_to(_ground(map.castle_position)), point.length(), "inside")
			return
	fail_test("the map has no ring wall")
