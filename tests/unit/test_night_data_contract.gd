extends GutTest
## Data contract for the shipped prototype map's nights. The header names the decisions pinned:
## D-07 (eight hand-authored nights), D-09 (spawn points open up: night 1 comes from one, the
## number in use never decreases and reaches three, each spawn point on the castle-to-tower ray so
## a straight march crosses a tower plot) and D-10 (the nights escalate). Plan 02-10 retunes counts;
## these pins hold the structure, not the numbers. D-08 (two enemy types: the melee grunt and a
## ranged attacker that first joins on night 4 and never before night 3) was added by plan 02-05.

const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const NIGHT_COUNT: int = 8
const SPAWN_POINT_COUNT: int = 3
## How far from the castle-to-tower ray a spawn point may sit.
const RAY_TOLERANCE_M: float = 1.0
const TOWER_BUILDING: StringName = &"tower"
const GRUNT: StringName = &"grunt"
const RANGED: StringName = &"ranged"
## D-08: the ranged type may not appear before this night, and is expected on FIRST_RANGED_NIGHT.
const EARLIEST_RANGED_NIGHT: int = 3
const FIRST_RANGED_NIGHT: int = 4
## Per-night enemy totals fixed by plan 02-02; adding the ranged type only splits groups.
const NIGHT_TOTALS: Array[int] = [5, 8, 11, 14, 18, 22, 27, 33]


func _map() -> MapConfig:
	return load(PROTOTYPE_MAP)


func _xz(position: Vector3) -> Vector2:
	return Vector2(position.x, position.z)


func _distinct_spawn_points(night: NightDef) -> int:
	var seen: Dictionary = {}
	for group: SpawnGroupDef in night.groups:
		seen[group.spawn_point_id] = true
	return seen.size()


func _total_enemies(night: NightDef) -> int:
	var total: int = 0
	for group: SpawnGroupDef in night.groups:
		total += group.count
	return total


## Distance from `point` to the ray that starts at `origin` and runs through `through`.
func _distance_to_ray(point: Vector2, origin: Vector2, through: Vector2) -> float:
	var direction: Vector2 = (through - origin).normalized()
	var along: float = maxf((point - origin).dot(direction), 0.0)
	return point.distance_to(origin + direction * along)


func test_the_prototype_map_has_exactly_eight_nights() -> void:
	assert_eq(_map().nights.size(), NIGHT_COUNT, "D-07: eight hand-authored nights")


func test_night_one_comes_from_exactly_one_spawn_point() -> void:
	assert_eq(_distinct_spawn_points(_map().night_def(1)), 1, "D-09: night 1 uses one spawn point")


func test_the_spawn_points_in_use_never_decrease_and_reach_three_on_the_last_night() -> void:
	var map: MapConfig = _map()
	var previous: int = 0
	for night_number: int in range(1, map.nights.size() + 1):
		var used: int = _distinct_spawn_points(map.night_def(night_number))
		assert_gte(
			used,
			previous,
			"night %d uses no fewer spawn points than the night before" % night_number
		)
		previous = used
	assert_eq(previous, SPAWN_POINT_COUNT, "D-09: the last night uses all three")


func test_each_spawn_point_sits_beyond_a_tower_plot_on_its_castle_ray() -> void:
	var map: MapConfig = _map()
	assert_eq(map.spawn_points.size(), SPAWN_POINT_COUNT, "exactly three spawn points")
	var castle: Vector2 = _xz(map.castle_position)
	var matched_plots: Dictionary = {}
	for spawn_point: SpawnPointDef in map.spawn_points:
		var found: StringName = &""
		for spot: BuildSpotDef in map.spots:
			if spot.building_id != TOWER_BUILDING:
				continue
			var plot: Vector2 = _xz(spot.position)
			var spawn: Vector2 = _xz(spawn_point.position)
			var near_ray: bool = _distance_to_ray(spawn, castle, plot) <= RAY_TOLERANCE_M
			var beyond: bool = spawn.distance_to(castle) > plot.distance_to(castle)
			if near_ray and beyond:
				found = spot.id
		assert_ne(found, &"", "spawn point '%s' is beyond a tower plot on its ray" % spawn_point.id)
		assert_false(matched_plots.has(found), "no two spawn points share the plot '%s'" % found)
		matched_plots[found] = true


func test_the_total_enemies_per_night_never_decreases() -> void:
	var map: MapConfig = _map()
	var previous: int = 0
	for night_number: int in range(1, map.nights.size() + 1):
		var total: int = _total_enemies(map.night_def(night_number))
		assert_gte(
			total, previous, "D-10: night %d is no easier than the night before" % night_number
		)
		previous = total
	assert_gt(
		previous, _total_enemies(map.night_def(1)), "and the last night is harder than the first"
	)


func test_every_enemy_in_a_group_is_a_type_the_map_lists() -> void:
	var map: MapConfig = _map()
	for night_number: int in range(1, map.nights.size() + 1):
		for group: SpawnGroupDef in map.night_def(night_number).groups:
			assert_not_null(
				map.find_enemy(group.enemy_id), "night %d uses a listed enemy" % night_number
			)


func _has_ranged(night: NightDef) -> bool:
	for group: SpawnGroupDef in night.groups:
		if group.enemy_id == RANGED:
			return true
	return false


func test_the_map_lists_exactly_the_grunt_and_the_ranged_type() -> void:
	var ids: Array[String] = []
	for def: EnemyDef in _map().enemies:
		ids.append(String(def.id))
	ids.sort()
	assert_eq(ids, [String(GRUNT), String(RANGED)] as Array[String], "D-08: exactly two types")


func test_the_ranged_type_is_a_real_shooter_and_the_grunt_is_melee() -> void:
	var map: MapConfig = _map()
	var ranged: EnemyDef = map.find_enemy(RANGED)
	var grunt: EnemyDef = map.find_enemy(GRUNT)
	assert_not_null(ranged, "the ranged def is on the map")
	assert_not_null(grunt, "the grunt def is on the map")
	if ranged == null or grunt == null:
		return
	assert_gt(ranged.projectile_speed, 0.0, "D-08: the ranged type shoots projectiles")
	assert_eq(grunt.projectile_speed, 0.0, "the grunt is melee")
	assert_gt(ranged.attack_range, grunt.attack_range, "and it outranges the grunt")


func test_no_ranged_enemy_appears_before_night_three() -> void:
	var map: MapConfig = _map()
	for night_number: int in range(1, EARLIEST_RANGED_NIGHT):
		assert_false(
			_has_ranged(map.night_def(night_number)),
			"D-08: night %d has no ranged enemy" % night_number
		)


func test_the_ranged_type_first_appears_on_night_four_and_stays() -> void:
	var map: MapConfig = _map()
	var first: int = 0
	for night_number: int in range(1, map.nights.size() + 1):
		if _has_ranged(map.night_def(night_number)):
			if first == 0:
				first = night_number
		elif first > 0:
			fail_test("D-08: night %d dropped the ranged type again" % night_number)
	assert_eq(first, FIRST_RANGED_NIGHT, "D-08: the first ranged night")


func test_the_per_night_totals_are_unchanged_by_the_ranged_type() -> void:
	var map: MapConfig = _map()
	var totals: Array[int] = []
	for night_number: int in range(1, map.nights.size() + 1):
		totals.append(_total_enemies(map.night_def(night_number)))
	assert_eq(totals, NIGHT_TOTALS, "5, 8, 11, 14, 18, 22, 27, 33")
