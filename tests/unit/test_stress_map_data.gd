extends GutTest
## D-11: the tools-only stress map is data the gate stress reads, so its shape is pinned here. One
## long wall with a single 4 m gate, one huge night of 300 stress grunts that match the shipped
## grunt in everything but health, an unarmed castle on the low-z side, and the pass geometry the
## harness derives from it (the finish line and the sink come from this data, never from code).
## Gap round G-05-2 (owner decision 2026-10-25): health and damage are 100 times larger, so the
## stress grunt strikes for the shipped 200 and every huge pool is 10000000; every ratio of the
## stress night is unchanged.

const GRUNT := "res://data/enemies/grunt.tres"
const WALL_Z: float = 30.0
const GAP_HALF_CM: int = 200
const WALL_Z_CM: int = 3000
const NIGHT_SIZE: int = 300
const HUGE_HEALTH: int = 10000000
const FOOTMAN := "res://data/units/footman.tres"
const TOWER_PLOTS: int = 20
const BARRACKS_PLOTS: int = 2
const TOWER_ROWS: Array[float] = [12.0, 20.0]
const BARRACKS_POSTS: Array[float] = [-12.0, 12.0]


func _map() -> MapConfig:
	return load(GateStress.STRESS_MAP) as MapConfig


func _gate_spot(map: MapConfig) -> BuildSpotDef:
	for spot: BuildSpotDef in map.spots:
		if spot.id == GateStress.GATE_SPOT:
			return spot
	return null


func test_the_stress_map_validates_clean() -> void:
	assert_eq(_map().validate(), PackedStringArray(), "no data error")


func test_it_has_exactly_one_wall_plot_called_gate_wall() -> void:
	var map: MapConfig = _map()
	var wall_plots: int = 0
	for plot: BuildSpotDef in map.spots:
		wall_plots += 1 if plot.wall_run != null else 0
	assert_eq(wall_plots, 1, "one wall plot")
	var spot: BuildSpotDef = _gate_spot(map)
	assert_not_null(spot, "gate_wall exists")
	assert_not_null(spot.wall_run, "and carries a wall run")
	assert_true(GateStress.has_gate(map), "the harness finds the gate")


func test_the_run_leaves_a_single_four_metre_gap_at_x_minus_two_to_two_on_z_thirty() -> void:
	var run: WallRunDef = _gate_spot(_map()).wall_run
	var flat: PackedInt32Array = run.expand()
	assert_gt(flat.size(), 0, "the run expands")
	@warning_ignore("integer_division")
	var segments: int = flat.size() / 4
	var west: int = 0
	var east: int = 0
	for index: int in range(segments):
		var ax: int = flat[index * 4]
		var az: int = flat[index * 4 + 1]
		var bx: int = flat[index * 4 + 2]
		var bz: int = flat[index * 4 + 3]
		assert_eq([az, bz], [WALL_Z_CM, WALL_Z_CM], "segment %d lies on z 30" % index)
		var low: int = mini(ax, bx)
		var high: int = maxi(ax, bx)
		assert_true(high <= -GAP_HALF_CM or low >= GAP_HALF_CM, "segment %d clears the gap" % index)
		west += 1 if high <= -GAP_HALF_CM else 0
		east += 1 if low >= GAP_HALF_CM else 0
	assert_eq(west + east, segments, "every segment is west or east of the gap")
	assert_gt(west, 0, "wall west of the gate")
	assert_gt(east, 0, "wall east of the gate")


func test_night_one_is_three_hundred_stress_grunts_from_four_spawn_points() -> void:
	var map: MapConfig = _map()
	assert_eq(map.nights.size(), 1, "one night")
	assert_eq(map.spawn_points.size(), 4, "four spawn points")
	var total: int = 0
	var used: Dictionary = {}
	for group: SpawnGroupDef in map.nights[0].groups:
		total += group.count
		used[group.spawn_point_id] = true
		assert_eq(group.enemy_id, &"stress_grunt", "a stress grunt group")
	assert_eq(total, NIGHT_SIZE, "300 enemies")
	assert_eq(total, MapConfig.MAX_ENEMIES_PER_NIGHT, "the shipped per-night cap")
	assert_eq(used.size(), 4, "each spawn point is used")


func test_stress_grunt_matches_the_shipped_grunt_except_for_health() -> void:
	var stress: EnemyDef = _map().find_enemy(&"stress_grunt")
	var grunt: EnemyDef = load(GRUNT) as EnemyDef
	assert_not_null(stress, "the map defines it")
	for field: String in [
		"move_speed",
		"radius",
		"attack_range",
		"attack_damage",
		"attack_interval",
		"aggro_range",
		"leash_range",
		"retarget_interval_seconds",
		"projectile_speed"
	]:
		assert_eq(stress.get(field), grunt.get(field), "%s matches the grunt" % field)
	assert_eq(stress.max_health, HUGE_HEALTH, "so tower fire cannot thin the night")
	assert_false(stress.ignores_walls, "it respects walls")


func test_the_castle_is_unarmed_and_the_wall_has_one_huge_tier() -> void:
	var map: MapConfig = _map()
	assert_eq(map.castle_attack_damage, 0, "unarmed castle")
	assert_eq(map.castle_max_health, HUGE_HEALTH, "it outlives the surge")
	var wall: BuildingDef = map.buildings[0]
	assert_eq(wall.id, &"stress_wall", "the stress wall")
	assert_eq(wall.tiers.size(), 1, "a single tier")
	assert_eq(wall.tiers[0].max_health, HUGE_HEALTH, "so the break-or-detour rule prefers the gate")


func test_the_castle_is_below_the_wall_and_every_spawn_is_above_it() -> void:
	var map: MapConfig = _map()
	assert_lt(map.castle_position.z, WALL_Z, "castle on the low-z side")
	for spawn: SpawnPointDef in map.spawn_points:
		assert_gt(
			spawn.position.z - spawn.scatter_radius, WALL_Z, "%s starts beyond the wall" % spawn.id
		)


func test_the_pass_geometry_is_read_from_the_data() -> void:
	var map: MapConfig = _map()
	assert_eq(GateStress.finish_z(map), 28.0, "the line z 30 minus the margin")
	assert_eq(GateStress.sink_radius(map), 7.5, "the castle radius 3.5 plus the margin")


func test_moving_the_wall_moves_the_finish_line() -> void:
	var copy: MapConfig = _map().duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	var run: WallRunDef = _gate_spot(copy).wall_run
	run.points = PackedVector2Array([Vector2(-40.0, 40.0), Vector2(40.0, 40.0)])
	assert_eq(GateStress.finish_z(copy), 38.0, "finish_z follows the wall")
	copy.castle_radius = 5.0
	assert_eq(GateStress.sink_radius(copy), 9.0, "sink_radius follows the castle")


func test_a_map_without_the_gate_has_no_finish_line() -> void:
	var map: MapConfig = load("res://tests/fixtures/fixture_map_walls_gap.tres") as MapConfig
	assert_false(GateStress.has_gate(map), "no gate_wall plot")
	assert_true(is_nan(GateStress.finish_z(map)), "so no finish line")


func _plots_of(map: MapConfig, building_id: StringName) -> Array[BuildSpotDef]:
	var found: Array[BuildSpotDef] = []
	for spot: BuildSpotDef in map.spots:
		if spot.building_id == building_id:
			found.append(spot)
	return found


func _building(map: MapConfig, building_id: StringName) -> BuildingDef:
	for def: BuildingDef in map.buildings:
		if def.id == building_id:
			return def
	return null


func test_there_are_twenty_stress_tower_plots_in_two_rows_on_the_castle_side() -> void:
	var map: MapConfig = _map()
	var towers: Array[BuildSpotDef] = _plots_of(map, &"stress_tower")
	assert_eq(towers.size(), TOWER_PLOTS, "20 tower plots")
	var per_row: Dictionary = {}
	for spot: BuildSpotDef in towers:
		assert_true(TOWER_ROWS.has(spot.position.z), "%s stands on a tower row" % spot.id)
		assert_lt(spot.position.z, WALL_Z, "%s is on the castle side of the wall" % spot.id)
		per_row[spot.position.z] = int(per_row.get(spot.position.z, 0)) + 1
	assert_eq(per_row.size(), 2, "two rows")
	for row: float in TOWER_ROWS:
		assert_eq(per_row[row], TOWER_PLOTS / 2, "ten towers on the row at z %s" % row)


func test_there_are_two_stress_barracks_plots_beside_the_castle() -> void:
	var barracks: Array[BuildSpotDef] = _plots_of(_map(), &"stress_barracks")
	assert_eq(barracks.size(), BARRACKS_PLOTS, "2 barracks plots")
	var posts: Array[float] = []
	for spot: BuildSpotDef in barracks:
		posts.append(spot.position.x)
		assert_eq(spot.position.z, 6.0, "%s stands at z 6" % spot.id)
	posts.sort()
	assert_eq(posts, BARRACKS_POSTS, "at x -12 and 12")


func test_the_stress_tower_tier_shoots_slow_arrows_often() -> void:
	var tower: BuildingDef = _building(_map(), &"stress_tower")
	assert_not_null(tower, "the map defines the stress tower")
	assert_eq(tower.tiers.size(), 1, "one tier")
	var tier: BuildingTierDef = tower.tiers[0]
	assert_eq(tier.projectile_speed, 5.0, "slow arrows keep about 200 or more in the air")
	assert_eq(tier.attack_interval, 0.15, "every 0.15 s")
	assert_eq(tier.attack_range, 30.0, "from 30 m")
	assert_eq(tier.attack_damage, 100, "real hits of 100 through PendingHits")
	assert_eq(tier.max_health, HUGE_HEALTH, "it outlives the surge")


func test_each_stress_barracks_fields_twenty_five_stress_footmen() -> void:
	var map: MapConfig = _map()
	var barracks: BuildingDef = _building(map, &"stress_barracks")
	assert_not_null(barracks, "the map defines the stress barracks")
	assert_eq(barracks.unit_id, &"stress_footman", "it fields the stress footman")
	assert_eq(barracks.tiers.size(), 1, "one tier")
	assert_eq(barracks.tiers[0].squad_size, 25, "25 units per squad, 50 over the two plots")
	assert_eq(barracks.tiers[0].max_health, HUGE_HEALTH, "it outlives the surge")
	assert_not_null(map.find_unit(&"stress_footman"), "and the map defines that unit")


func test_the_stress_footman_matches_the_shipped_footman_except_for_health() -> void:
	var stress: UnitDef = _map().find_unit(&"stress_footman")
	var footman: UnitDef = load(FOOTMAN) as UnitDef
	for field: String in [
		"move_speed",
		"radius",
		"attack_range",
		"attack_damage",
		"attack_interval",
		"guard_range",
		"leash_range",
		"retarget_interval_seconds",
		"projectile_speed",
		"formation_spacing"
	]:
		assert_eq(stress.get(field), footman.get(field), "%s matches the footman" % field)
	assert_eq(stress.max_health, HUGE_HEALTH, "so the squad stays at full size")


func test_night_one_and_the_wall_are_the_same_with_the_added_plots() -> void:
	var map: MapConfig = _map()
	assert_eq(map.nights.size(), 1, "still one night")
	assert_eq(map.spots[0].id, GateStress.GATE_SPOT, "the wall plot stays first")
	assert_eq(map.buildings[0].id, &"stress_wall", "and its def stays first")
	assert_eq(map.spots.size(), 1 + TOWER_PLOTS + BARRACKS_PLOTS, "wall, towers and barracks")
