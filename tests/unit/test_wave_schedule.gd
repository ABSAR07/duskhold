extends GutTest
## LOOP-02 data side: WaveSchedule.preview_counts is the one answer to "who comes from where in the
## coming night". Counts are read from the map data, never typed as literals, so a retune of the
## night ramp cannot break these tests.

const WEST: StringName = &"west"
const EAST: StringName = &"east"
const NORTH: StringName = &"north"


func _shipped() -> MapConfig:
	return E2eSupport.shipped_prototype_map()


## What the data says one spawn point brings in one night: the sum of its groups' counts.
func _authored(map: MapConfig, night_number: int, spawn_point_id: StringName) -> int:
	var total: int = 0
	for group: SpawnGroupDef in map.night_def(night_number).groups:
		if group.spawn_point_id == spawn_point_id:
			total += group.count
	return total


func _group(spawn_point_id: StringName, count: int) -> SpawnGroupDef:
	var group: SpawnGroupDef = SpawnGroupDef.new()
	group.spawn_point_id = spawn_point_id
	group.enemy_id = &"grunt"
	group.count = count
	return group


func test_night_one_on_the_shipped_map_comes_from_the_west_only() -> void:
	var map: MapConfig = _shipped()

	var counts: Dictionary = WaveSchedule.preview_counts(map, 1)

	assert_eq(counts.keys(), [WEST], "only the west road is used on night one")
	assert_eq(counts[WEST], _authored(map, 1, WEST), "and it brings what the data says")
	assert_gt(counts[WEST], 0, "a real night has enemies")


func test_night_three_lists_west_then_east_with_the_authored_totals() -> void:
	var map: MapConfig = _shipped()

	var counts: Dictionary = WaveSchedule.preview_counts(map, 3)

	assert_eq(counts.keys(), [WEST, EAST], "spawn points appear in MapConfig order")
	assert_eq(counts[WEST], _authored(map, 3, WEST), "west total")
	assert_eq(counts[EAST], _authored(map, 3, EAST), "east total")


func test_a_spawn_point_with_two_groups_reports_their_sum() -> void:
	var map: MapConfig = _shipped()
	var night: NightDef = map.night_def(1)
	var before: int = WaveSchedule.preview_counts(map, 1)[WEST]
	night.groups.append(_group(WEST, 4))

	var counts: Dictionary = WaveSchedule.preview_counts(map, 1)

	assert_eq(counts[WEST], before + 4, "both west groups are summed into one count")
	assert_eq(counts.size(), 1, "still one entry for the one spawn point")


func test_the_order_follows_the_map_not_the_order_of_the_groups() -> void:
	var map: MapConfig = _shipped()
	var night: NightDef = map.night_def(1)
	# An east group authored before the west one: the preview still lists west first.
	night.groups.insert(0, _group(EAST, 2))

	var counts: Dictionary = WaveSchedule.preview_counts(map, 1)

	assert_eq(counts.keys(), [WEST, EAST], "MapConfig spawn-point order, not group order")


func test_a_night_past_the_last_and_night_zero_have_no_preview() -> void:
	var map: MapConfig = _shipped()

	assert_eq(WaveSchedule.preview_counts(map, map.nights.size() + 1), {}, "past the last night")
	assert_eq(WaveSchedule.preview_counts(map, 0), {}, "no night zero")
	assert_eq(WaveSchedule.preview_counts(map, -3), {}, "no negative night")


func test_a_waveless_map_has_no_preview() -> void:
	var map: MapConfig = E2eSupport.waveless_prototype_map()

	assert_eq(WaveSchedule.preview_counts(map, 1), {}, "no authored nights, nothing to preview")


func test_a_group_of_zero_enemies_adds_no_entry() -> void:
	var map: MapConfig = _shipped()
	var night: NightDef = map.night_def(1)
	night.groups.append(_group(NORTH, 0))

	var counts: Dictionary = WaveSchedule.preview_counts(map, 1)

	assert_false(counts.has(NORTH), "a spawn point with no enemies that night is not listed")


func test_two_calls_return_equal_dictionaries_with_the_same_key_order() -> void:
	var map: MapConfig = _shipped()

	for night_number: int in range(1, map.nights.size() + 1):
		var first: Dictionary = WaveSchedule.preview_counts(map, night_number)
		var second: Dictionary = WaveSchedule.preview_counts(map, night_number)
		assert_eq(first, second, "night %d is the same on every call" % night_number)
		assert_eq(first.keys(), second.keys(), "and lists the same order")


func test_the_preview_adds_up_to_the_schedule_the_night_will_play() -> void:
	var map: MapConfig = _shipped()

	for night_number: int in range(1, map.nights.size() + 1):
		var previewed: int = 0
		for count: int in WaveSchedule.preview_counts(map, night_number).values():
			previewed += count
		assert_eq(
			previewed,
			WaveSchedule.new(map, night_number).total_count(),
			"night %d: the telegraphed enemies are the enemies that spawn" % night_number
		)


## A night of `group_count` groups that each ask for `per_group` grunts from the west road, on a
## copy of the shipped map. The spawn point and enemy are real, so no group is skipped.
func _crowded_night(group_count: int, per_group: int) -> MapConfig:
	var map: MapConfig = _shipped()
	map.night_def(1).groups.clear()
	for _index: int in range(group_count):
		map.night_def(1).groups.append(_group(WEST, per_group))
	return map


func _previewed(map: MapConfig, night_number: int) -> int:
	var previewed: int = 0
	for count: int in WaveSchedule.preview_counts(map, night_number).values():
		previewed += count
	return previewed


func test_one_oversized_group_never_spawns_more_than_a_night_may_hold() -> void:
	var map: MapConfig = _crowded_night(1, MapConfig.MAX_ENEMIES_PER_NIGHT * 5)

	var schedule: WaveSchedule = WaveSchedule.new(map, 1)

	assert_eq(
		schedule.total_count(),
		MapConfig.MAX_ENEMIES_PER_NIGHT,
		"a group asking for far more spawns exactly the night limit"
	)


func test_many_oversized_groups_together_stay_inside_the_night_limit() -> void:
	var map: MapConfig = _crowded_night(20, 500)

	var schedule: WaveSchedule = WaveSchedule.new(map, 1)

	assert_lte(
		schedule.total_count(),
		MapConfig.MAX_ENEMIES_PER_NIGHT,
		"twenty groups of five hundred cannot spawn ten thousand enemies"
	)
	assert_gt(schedule.total_count(), 0, "the night is capped, not emptied")


func test_the_night_limit_is_shared_out_in_group_order() -> void:
	var limit: int = MapConfig.MAX_ENEMIES_PER_NIGHT
	var map: MapConfig = _crowded_night(2, limit - 10)

	var schedule: WaveSchedule = WaveSchedule.new(map, 1)

	assert_eq(schedule.total_count(), limit, "the first group fills most, the second the rest")
	var from_second: int = 0
	for entry: WaveSchedule.Entry in schedule.take_due(1000000):
		if entry.group_index == 1:
			from_second += 1
	assert_eq(from_second, 10, "the second group gets only what the first left over")


func test_the_preview_agrees_with_a_capped_schedule() -> void:
	var map: MapConfig = _crowded_night(20, 500)

	assert_eq(
		_previewed(map, 1),
		WaveSchedule.new(map, 1).total_count(),
		"the telegraph shows the enemies the capped night will actually bring"
	)


## IN-01: a group whose enemy the map does not define is skipped by the schedule, so it must not be
## previewed and must not spend the night budget in the preview either.
func test_the_preview_skips_an_unknown_enemy_group_like_the_schedule() -> void:
	var map: MapConfig = _shipped()
	var night: NightDef = map.night_def(1)
	night.groups.clear()
	var ghost: SpawnGroupDef = _group(WEST, MapConfig.MAX_ENEMIES_PER_NIGHT)
	ghost.enemy_id = &"no_such_enemy"
	night.groups.append(ghost)
	night.groups.append(_group(EAST, 5))

	var counts: Dictionary = WaveSchedule.preview_counts(map, 1)

	assert_eq(WaveSchedule.new(map, 1).total_count(), 5, "the schedule skips the unknown enemy")
	assert_eq(counts, {EAST: 5}, "the preview lists the valid group only, with its full count")
	assert_eq(_previewed(map, 1), WaveSchedule.new(map, 1).total_count(), "and the totals agree")


## IN-02: the night budget is the only cap. A second per-group cap with the same number could never
## decide anything, so it must not come back as a constant.
func test_the_night_budget_is_the_only_cap_constant() -> void:
	var constants: Dictionary = (
		WaveSchedule.new(_shipped(), 1).get_script().get_script_constant_map()
	)

	assert_false(constants.has("MAX_GROUP_COUNT"), "no dead per-group cap beside the night budget")
