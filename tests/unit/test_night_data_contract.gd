extends GutTest
## Data contract for the shipped prototype map's nights. The header names the decisions pinned:
## D-07 (eight hand-authored nights), D-09 (spawn points open up: night 1 comes from one, the
## number in use never decreases and reaches three, each spawn point on the castle-to-tower ray so
## a straight march crosses a tower plot) and D-10 (the nights escalate). Plan 02-10 retunes counts;
## these pins hold the structure, not the numbers. D-08 (two enemy types: the melee grunt and a
## ranged attacker that first joins on night 4 and never before night 3) was added by plan 02-05.
## Nights 2 to 5 are now the owner's exact numbers (G-02-15, round 3): the other pins hold the
## structure, the round-three counts test names every changed number. Nights 5 to 8 were raised
## once more for squads (D-08, plan 03-11): the army-building bot wins 8 of 10 seeds with them
## (the Phase 2 bar of 7 or 8), and the retuned counts test names every changed number.

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
## Per-night enemy totals: plan 02-02's ramp until round 3; owner decision 2026-10-07 (G-02-15,
## the full wall): night 2 opens the east road and nights 3 to 5 grow. Nights 1 and 6 to 8 are
## unchanged. Adding the ranged type only splits groups. Retuned for squads (D-08, plan 03-11):
## nights 5 to 8 went from 21, 22, 27, 33 to 25, 31, 39, 39. Night 8 stops at 39 because the
## tower-opening bot (towers_first) still wins seeds 1 and 2 there and a bigger last night ends it.
const NIGHT_TOTALS: Array[int] = [5, 12, 21, 21, 25, 31, 39, 39]
## The owner's round-three counts of nights 2 to 5: [night, spawn point, enemy, count].
const ROUND_THREE_COUNTS: Array = [
	[2, &"west", &"grunt", 8],
	[2, &"east", &"grunt", 4],
	[3, &"west", &"grunt", 11],
	[3, &"east", &"grunt", 10],
	[4, &"west", &"grunt", 11],
	[4, &"east", &"grunt", 7],
	[4, &"east", &"ranged", 3],
	[5, &"west", &"grunt", 11],
	[5, &"east", &"grunt", 10],
	[5, &"west", &"ranged", 2],
	[5, &"east", &"ranged", 2],
]
const ROUND_THREE_NIGHTS: Array[int] = [2, 3, 4, 5]
## The counts nights 6 to 8 carry after the squad retune (D-08, plan 03-11), with the old count of
## each group in the trailing comment: [night, spawn point, enemy, count].
const SQUAD_RETUNE_COUNTS: Array = [
	[6, &"west", &"grunt", 8],  # was 6
	[6, &"east", &"grunt", 7],  # was 5
	[6, &"north", &"grunt", 10],  # was 7
	[6, &"west", &"ranged", 3],  # was 2
	[6, &"east", &"ranged", 3],  # was 2
	[7, &"west", &"grunt", 10],  # was 7
	[7, &"east", &"grunt", 10],  # was 7
	[7, &"north", &"grunt", 10],  # was 7
	[7, &"west", &"ranged", 3],  # was 2
	[7, &"east", &"ranged", 3],  # was 2
	[7, &"north", &"ranged", 3],  # was 2
	[8, &"west", &"grunt", 10],  # was 8
	[8, &"east", &"grunt", 10],  # was 8
	[8, &"north", &"grunt", 10],  # was 8
	[8, &"west", &"ranged", 3],
	[8, &"east", &"ranged", 3],
	[8, &"north", &"ranged", 3],
]
const SQUAD_RETUNE_NIGHTS: Array[int] = [6, 7, 8]
## Night 2's new east group starts at 2.0 s and spaces its grunts 1.5 s apart.
const NIGHT_TWO_EAST_START_S: float = 2.0
const NIGHT_TWO_EAST_INTERVAL_S: float = 1.5
## The Phase 2 wall (the owner's nights 1 to 4), snapshotted from the shipped file before Round 2
## (plan 03-17, G-03-11): [night, spawn point, enemy, count, start delay s, interval s], in the
## order the groups are listed. The Round 2 retune may not move any of these.
const PHASE_TWO_WALL: Array = [
	[1, &"west", &"grunt", 5, 0.5, 1.5],
	[2, &"west", &"grunt", 8, 0.5, 1.5],
	[2, &"east", &"grunt", 4, 2.0, 1.5],
	[3, &"west", &"grunt", 11, 0.5, 1.5],
	[3, &"east", &"grunt", 10, 2.0, 1.5],
	[4, &"west", &"grunt", 11, 0.5, 1.5],
	[4, &"east", &"grunt", 7, 2.0, 1.5],
	[4, &"east", &"ranged", 3, 3.5, 1.5],
]
const PHASE_TWO_WALL_TOTALS: Array[int] = [5, 12, 21, 21]


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


func test_the_per_night_totals_match_the_owner_s_wall() -> void:
	var map: MapConfig = _map()
	var totals: Array[int] = []
	for night_number: int in range(1, map.nights.size() + 1):
		totals.append(_total_enemies(map.night_def(night_number)))
	assert_eq(totals, NIGHT_TOTALS, "5, 12, 21, 21, 25, 31, 39, 39 (squad retune, plan 03-11)")


func _summed_counts(night: NightDef) -> Dictionary:
	var sums: Dictionary = {}
	for group: SpawnGroupDef in night.groups:
		var key: String = "%s/%s" % [group.spawn_point_id, group.enemy_id]
		sums[key] = int(sums.get(key, 0)) + group.count
	return sums


func test_nights_six_to_eight_carry_the_squad_retune_counts() -> void:
	var map: MapConfig = _map()
	for night_number: int in SQUAD_RETUNE_NIGHTS:
		var expected: Dictionary = {}
		for entry: Array in SQUAD_RETUNE_COUNTS:
			if entry[0] == night_number:
				expected["%s/%s" % [entry[1], entry[2]]] = entry[3]
		assert_eq(
			_summed_counts(map.night_def(night_number)),
			expected,
			"D-08: night %d carries the counts retuned for squads" % night_number
		)


func test_every_night_stays_under_the_per_night_enemy_cap_and_the_map_validates() -> void:
	var map: MapConfig = _map()
	for night_number: int in range(1, map.nights.size() + 1):
		assert_lt(
			_total_enemies(map.night_def(night_number)),
			MapConfig.MAX_ENEMIES_PER_NIGHT,
			"night %d is under the cap" % night_number
		)
	assert_eq(map.validate(), PackedStringArray(), "and the retuned map validates clean")


func test_nights_two_to_five_carry_the_owner_s_round_three_counts() -> void:
	var map: MapConfig = _map()
	for night_number: int in ROUND_THREE_NIGHTS:
		var expected: Dictionary = {}
		for entry: Array in ROUND_THREE_COUNTS:
			if entry[0] == night_number:
				expected["%s/%s" % [entry[1], entry[2]]] = entry[3]
		assert_eq(
			_summed_counts(map.night_def(night_number)),
			expected,
			"G-02-15: night %d carries exactly the owner's counts" % night_number
		)
	var groups: Array[SpawnGroupDef] = map.night_def(2).groups
	assert_eq(groups.size(), 2, "night 2 has a west group and an east group")
	if groups.size() != 2:
		return
	assert_eq(groups[0].spawn_point_id, &"west", "night 2 lists the west group first")
	assert_eq(groups[1].spawn_point_id, &"east", "then the new east group")
	assert_eq(groups[1].start_delay_seconds, NIGHT_TWO_EAST_START_S, "east starts at 2.0 s")
	assert_eq(groups[1].interval_seconds, NIGHT_TWO_EAST_INTERVAL_S, "and spaces 1.5 s apart")


func test_the_last_night_is_larger_than_the_night_before() -> void:
	var map: MapConfig = _map()
	var last: int = _total_enemies(map.night_def(NIGHT_COUNT))
	var before: int = _total_enemies(map.night_def(NIGHT_COUNT - 1))
	assert_gt(
		last, before, "G-03-11: night 8 (%d enemies) is larger than night 7 (%d)" % [last, before]
	)


func test_nights_one_to_four_keep_the_phase_two_wall() -> void:
	var map: MapConfig = _map()
	for night_number: int in range(1, 5):
		assert_eq(
			_total_enemies(map.night_def(night_number)),
			PHASE_TWO_WALL_TOTALS[night_number - 1],
			"night %d keeps its Phase 2 total" % night_number
		)
		var expected: Array = []
		for entry: Array in PHASE_TWO_WALL:
			if entry[0] == night_number:
				expected.append(entry)
		var groups: Array[SpawnGroupDef] = map.night_def(night_number).groups
		assert_eq(groups.size(), expected.size(), "night %d keeps its groups" % night_number)
		if groups.size() != expected.size():
			continue
		for index: int in range(groups.size()):
			var group: SpawnGroupDef = groups[index]
			var want: Array = expected[index]
			var label: String = "night %d group %d" % [night_number, index + 1]
			assert_eq(group.spawn_point_id, want[1], "%s spawn point" % label)
			assert_eq(group.enemy_id, want[2], "%s enemy" % label)
			assert_eq(group.count, want[3], "%s count" % label)
			assert_eq(group.start_delay_seconds, want[4], "%s start delay" % label)
			assert_eq(group.interval_seconds, want[5], "%s interval" % label)
