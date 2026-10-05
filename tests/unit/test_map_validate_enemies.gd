extends GutTest
## Review WR-01: MapConfig.validate() reports enemy and castle numbers that would make a night
## impossible to end (an enemy that never acquires its target stands at its stop distance forever,
## and a real night has no clock) or that are plainly meaningless. Each case edits a deep copy of
## the shipped map and calls validate() directly, never through RunContext, whose push_error would
## fail the test. The shipped map reports nothing, and each bad item adds exactly one error that
## names it.


func _map() -> MapConfig:
	return E2eSupport.shipped_prototype_map()


## Asserts validate() reports exactly one error and that it contains `needle`.
func _assert_one_error(map: MapConfig, needle: String, label: String) -> void:
	var errors: PackedStringArray = map.validate()
	assert_eq(errors.size(), 1, "%s reports exactly one error: %s" % [label, errors])
	if errors.size() == 1:
		assert_string_contains(errors[0], needle, "%s names the item" % label)


func test_the_shipped_enemies_notice_what_they_stop_to_attack() -> void:
	for enemy: EnemyDef in _map().enemies:
		assert_gt(enemy.aggro_range, enemy.attack_range, "'%s' aggro outreaches attack" % enemy.id)
		assert_gte(enemy.leash_range, enemy.aggro_range, "'%s' leash holds aggro" % enemy.id)
	assert_eq(_map().validate(), PackedStringArray(), "and the shipped map is clean")


func test_an_enemy_that_stops_beyond_its_aggro_range_is_reported() -> void:
	var map: MapConfig = _map()
	var ranged: EnemyDef = map.find_enemy(&"ranged")
	ranged.aggro_range = ranged.attack_range - 1.0
	_assert_one_error(map, "aggro_range", "an aggro range below the attack range")


func test_an_enemy_whose_aggro_range_equals_its_attack_range_is_reported() -> void:
	var map: MapConfig = _map()
	var grunt: EnemyDef = map.find_enemy(&"grunt")
	grunt.aggro_range = grunt.attack_range
	_assert_one_error(map, "aggro_range", "an aggro range equal to the attack range")


func test_an_enemy_that_gives_up_before_it_notices_is_reported() -> void:
	var map: MapConfig = _map()
	var grunt: EnemyDef = map.find_enemy(&"grunt")
	grunt.leash_range = grunt.aggro_range - 1.0
	_assert_one_error(map, "leash_range", "a leash below the aggro range")


func test_an_enemy_with_no_body_is_reported() -> void:
	var map: MapConfig = _map()
	map.enemies[0].radius = 0.0
	_assert_one_error(map, "radius", "a zero radius")


func test_an_enemy_with_a_negative_attack_range_is_reported() -> void:
	var map: MapConfig = _map()
	map.enemies[0].attack_range = -0.5
	_assert_one_error(map, "attack_range", "a negative attack range")


func test_an_enemy_that_never_rescans_is_reported() -> void:
	var map: MapConfig = _map()
	map.enemies[0].retarget_interval_seconds = 0.0
	_assert_one_error(map, "retarget_interval_seconds", "a zero retarget interval")


func test_an_enemy_with_a_negative_projectile_speed_is_reported() -> void:
	var map: MapConfig = _map()
	map.enemies[0].projectile_speed = -1.0
	_assert_one_error(map, "projectile_speed", "a negative enemy projectile speed")


func test_a_castle_with_no_radius_is_reported() -> void:
	var map: MapConfig = _map()
	map.castle_radius = 0.0
	_assert_one_error(map, "castle_radius", "a zero castle radius")


func test_a_tower_tier_that_never_fires_again_is_reported() -> void:
	var map: MapConfig = _map()
	var tower: BuildingDef = map.buildings[_index_of_building(map, &"tower")]
	tower.tiers[0].attack_interval = 0.0
	_assert_one_error(map, "attack_interval", "a zero tower attack interval")


func test_a_tower_tier_with_a_negative_projectile_speed_is_reported() -> void:
	var map: MapConfig = _map()
	var tower: BuildingDef = map.buildings[_index_of_building(map, &"tower")]
	tower.tiers[1].projectile_speed = -2.0
	_assert_one_error(map, "projectile_speed", "a negative tower projectile speed")


func test_a_tower_tier_with_a_negative_attack_range_is_reported() -> void:
	var map: MapConfig = _map()
	var tower: BuildingDef = map.buildings[_index_of_building(map, &"tower")]
	tower.tiers[0].attack_range = -1.0
	_assert_one_error(map, "attack_range", "a negative tower attack range")


func _index_of_building(map: MapConfig, building_id: StringName) -> int:
	for index: int in range(map.buildings.size()):
		if map.buildings[index].id == building_id:
			return index
	return -1
