extends GutTest
## T-02-04: MapConfig.validate() reports bad night and enemy data without blocking, and caps the
## size of one night. Every case edits a deep copy of the shipped map (DR-12) and calls validate()
## directly, never through RunContext, whose push_error would fail the test. The shipped map
## reports nothing, and each bad item adds exactly one error that names it.

const TUNING := "res://data/tuning/loop_tuning.tres"


func _map() -> MapConfig:
	return E2eSupport.shipped_prototype_map()


## Asserts validate() reports exactly one error and that it contains `needle`.
func _assert_one_error(map: MapConfig, needle: String, label: String) -> void:
	var errors: PackedStringArray = map.validate()
	assert_eq(errors.size(), 1, "%s reports exactly one error: %s" % [label, errors])
	if errors.size() == 1:
		assert_string_contains(errors[0], needle, "%s names the item" % label)


func _group(map: MapConfig, night_number: int, group_index: int) -> SpawnGroupDef:
	return map.night_def(night_number).groups[group_index]


func test_the_shipped_map_reports_no_error() -> void:
	assert_eq(_map().validate(), PackedStringArray(), "the shipped map is clean")


func test_a_null_enemy_entry_is_reported() -> void:
	var map: MapConfig = _map()
	map.enemies.append(null)
	_assert_one_error(map, "enemy entry", "a null enemy")


func test_a_duplicate_enemy_id_is_reported() -> void:
	var map: MapConfig = _map()
	var twin: EnemyDef = map.enemies[0].duplicate()
	map.enemies.append(twin)
	_assert_one_error(map, "'grunt'", "a duplicate enemy id")


func test_an_enemy_with_no_health_is_reported() -> void:
	var map: MapConfig = _map()
	map.enemies[0].max_health = 0
	_assert_one_error(map, "max_health", "zero max_health")


func test_an_enemy_that_cannot_move_is_reported() -> void:
	var map: MapConfig = _map()
	map.enemies[0].move_speed = 0.0
	_assert_one_error(map, "move_speed", "zero move_speed")


func test_an_enemy_with_no_attack_interval_is_reported() -> void:
	var map: MapConfig = _map()
	map.enemies[0].attack_interval = 0.0
	_assert_one_error(map, "attack_interval", "zero attack_interval")


func test_a_null_spawn_point_is_reported() -> void:
	var map: MapConfig = _map()
	map.spawn_points.append(null)
	_assert_one_error(map, "spawn point entry", "a null spawn point")


func test_a_duplicate_spawn_point_id_is_reported() -> void:
	var map: MapConfig = _map()
	map.spawn_points.append(map.spawn_points[0].duplicate())
	_assert_one_error(map, "'west'", "a duplicate spawn point id")


func test_a_null_night_is_reported() -> void:
	var map: MapConfig = _map()
	map.nights.append(null)
	_assert_one_error(map, "night 9", "a null night")


func test_a_night_with_no_groups_has_no_enemies() -> void:
	var map: MapConfig = _map()
	map.night_def(3).groups.clear()
	_assert_one_error(map, "night 3 has no enemies", "a night with no groups")


func test_a_night_whose_groups_total_zero_has_one_error_not_two() -> void:
	var map: MapConfig = _map()
	_group(map, 1, 0).count = 0
	var errors: PackedStringArray = map.validate()
	assert_eq(errors.size(), 1, "one error for the zero-count group, none more: %s" % [errors])
	if errors.size() == 1:
		assert_string_contains(errors[0], "night 1", "it names the night")
		assert_string_contains(errors[0], "group 1", "and the group")


func test_a_group_with_an_unknown_spawn_point_is_reported() -> void:
	var map: MapConfig = _map()
	_group(map, 3, 0).spawn_point_id = &"nowhere"
	_assert_one_error(map, "'nowhere'", "an unknown spawn point")


func test_a_group_with_an_unknown_enemy_is_reported() -> void:
	var map: MapConfig = _map()
	_group(map, 3, 0).enemy_id = &"dragon"
	_assert_one_error(map, "'dragon'", "an unknown enemy")


func test_a_group_with_a_zero_count_is_reported() -> void:
	var map: MapConfig = _map()
	_group(map, 3, 0).count = 0
	_assert_one_error(map, "night 3 group 1", "a zero count")


func test_a_negative_start_delay_is_reported() -> void:
	var map: MapConfig = _map()
	_group(map, 3, 1).start_delay_seconds = -1.0
	_assert_one_error(map, "night 3 group 2", "a negative start delay")


func test_a_negative_interval_is_reported() -> void:
	var map: MapConfig = _map()
	_group(map, 3, 1).interval_seconds = -1.0
	_assert_one_error(map, "night 3 group 2", "a negative interval")


func test_a_night_above_the_cap_is_reported_and_exactly_the_cap_is_accepted() -> void:
	var map: MapConfig = _map()
	var group: SpawnGroupDef = _group(map, 1, 0)
	group.count = MapConfig.MAX_ENEMIES_PER_NIGHT
	assert_eq(map.validate(), PackedStringArray(), "exactly the cap is accepted")
	group.count = MapConfig.MAX_ENEMIES_PER_NIGHT + 1
	_assert_one_error(map, "night 1", "one enemy over the cap")


func test_the_cap_counts_the_whole_night_not_one_group() -> void:
	var map: MapConfig = _map()
	var night: NightDef = map.night_def(3)
	var half: int = roundi(MapConfig.MAX_ENEMIES_PER_NIGHT * 0.5)
	night.groups[0].count = half
	night.groups[1].count = half
	assert_eq(map.validate(), PackedStringArray(), "two groups making exactly the cap")
	night.groups[1].count = half + 1
	_assert_one_error(map, "night 3", "two groups over the cap together")


func test_a_castle_with_no_health_is_reported() -> void:
	var map: MapConfig = _map()
	map.castle_max_health = 0
	_assert_one_error(map, "castle_max_health", "zero castle health")


func test_a_night_past_the_authored_list_spawns_nothing_and_is_cleared_at_once() -> void:
	var map: MapConfig = _map()
	map.nights.resize(1)
	assert_eq(map.validate(), PackedStringArray(), "a valid one-night map")
	var events: SimEvents = SimEvents.new()
	var king_def: KingDef = load(RunContext.DEFAULT_KING_PATH)
	var king: KingState = KingState.new(king_def, Vector2.ZERO, events)
	var night: NightSim = NightSim.new(map, events, king, 1)
	watch_signals(events)
	night.begin_night(5)
	assert_true(night.is_cleared(), "cleared before the first step")
	for tick: int in range(30):
		night.step(tick)
		assert_true(night.is_cleared(), "still cleared on step %d" % tick)
	assert_eq(night.spawned_count(), 0, "nothing spawned")
	assert_signal_not_emitted(events, "enemy_spawned")
