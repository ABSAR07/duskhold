extends GutTest
## T-05-17, ECON-06, D-12: MapConfig.validate() reports bad Shrine data through EconomyValidation
## instead of arming it: a wake_radius that is not finite or lies outside (0, MAX_WAKE_RADIUS], a
## wake_threshold_hp outside 1..MAX_WAKE_THRESHOLD, a synergy_percent outside
## 0..MAX_SYNERGY_PERCENT, an AWAKENED building without attack numbers, wake fields set on a
## building whose curve does not use them, and a damage_stat or range_stat the StatIds registry does
## not know or of the wrong kind.
## Synthetic maps are deep copies of the shipped prototype map with one number broken. The Gold
## Mine, Harbor and pond checks live in test_economy_validation and test_pond_layout (that script is
## at the 20-method cap, so the Shrine checks live here).

const SHRINE: StringName = &"shrine"
const HOUSE: StringName = &"house"
const TOO_WIDE: float = 41.0
const TOO_HIGH: int = 100001
const TOO_STRONG: int = 101


func _map() -> MapConfig:
	return E2eSupport.waveless_prototype_map()


func _building(map: MapConfig, building_id: StringName) -> BuildingDef:
	for building_def: BuildingDef in map.buildings:
		if building_def.id == building_id:
			return building_def
	return null


func _tier(map: MapConfig, building_id: StringName) -> BuildingTierDef:
	return _building(map, building_id).tier_def(1)


func _has(problems: Array[String], needle: String) -> bool:
	for problem: String in problems:
		if problem.contains(needle):
			return true
	return false


func test_the_shipped_shrine_passes() -> void:
	var map: MapConfig = _map()
	assert_eq(EconomyValidation.problems(map), [] as Array[String], "clean")


func test_a_wake_radius_that_is_not_finite_is_reported() -> void:
	var map: MapConfig = _map()
	_tier(map, SHRINE).wake_radius = NAN
	assert_true(_has(EconomyValidation.problems(map), "wake_radius"), "NaN")
	_tier(map, SHRINE).wake_radius = INF
	assert_true(_has(EconomyValidation.problems(map), "wake_radius"), "infinity")


func test_a_wake_radius_of_zero_or_below_is_reported() -> void:
	var map: MapConfig = _map()
	_tier(map, SHRINE).wake_radius = 0.0
	assert_true(_has(EconomyValidation.problems(map), "wake_radius"), "zero wakes nothing")
	_tier(map, SHRINE).wake_radius = -1.0
	assert_true(_has(EconomyValidation.problems(map), "wake_radius"), "negative")


func test_a_wake_radius_above_the_cap_is_reported_and_the_cap_itself_is_allowed() -> void:
	var map: MapConfig = _map()
	_tier(map, SHRINE).wake_radius = TOO_WIDE
	assert_true(_has(EconomyValidation.problems(map), "wake_radius"), "41 m is over the cap")
	_tier(map, SHRINE).wake_radius = EconomyValidation.MAX_WAKE_RADIUS
	assert_false(_has(EconomyValidation.problems(map), "wake_radius"), "40 m exactly is fine")


func test_a_wake_threshold_outside_one_to_the_cap_is_reported() -> void:
	var map: MapConfig = _map()
	_tier(map, SHRINE).wake_threshold_hp = 0
	assert_true(_has(EconomyValidation.problems(map), "wake_threshold_hp"), "0 is always awake")
	_tier(map, SHRINE).wake_threshold_hp = TOO_HIGH
	assert_true(_has(EconomyValidation.problems(map), "wake_threshold_hp"), "100001")
	_tier(map, SHRINE).wake_threshold_hp = EconomyValidation.MAX_WAKE_THRESHOLD
	assert_false(_has(EconomyValidation.problems(map), "wake_threshold_hp"), "the cap is fine")
	_tier(map, SHRINE).wake_threshold_hp = 1
	assert_false(_has(EconomyValidation.problems(map), "wake_threshold_hp"), "and so is 1")


func test_a_synergy_outside_zero_to_one_hundred_is_reported() -> void:
	var map: MapConfig = _map()
	_tier(map, SHRINE).synergy_percent = TOO_STRONG
	assert_true(_has(EconomyValidation.problems(map), "synergy_percent"), "101")
	_tier(map, SHRINE).synergy_percent = -1
	assert_true(_has(EconomyValidation.problems(map), "synergy_percent"), "negative")
	_tier(map, SHRINE).synergy_percent = 0
	assert_false(_has(EconomyValidation.problems(map), "synergy_percent"), "0 is allowed")
	_tier(map, SHRINE).synergy_percent = EconomyValidation.MAX_SYNERGY_PERCENT
	assert_false(_has(EconomyValidation.problems(map), "synergy_percent"), "100 is allowed")


func test_an_awakened_building_without_attack_numbers_is_reported() -> void:
	var map: MapConfig = _map()
	_tier(map, SHRINE).attack_damage = 0
	assert_true(_has(EconomyValidation.problems(map), "attack_damage"), "no damage")
	_tier(map, SHRINE).attack_damage = 3
	_tier(map, SHRINE).attack_range = 0.0
	assert_true(_has(EconomyValidation.problems(map), "attack_range"), "no reach")
	_tier(map, SHRINE).attack_range = 9.0
	_tier(map, SHRINE).attack_interval = 0.0
	assert_true(_has(EconomyValidation.problems(map), "attack_interval"), "no cadence")
	_tier(map, SHRINE).attack_interval = 1.1
	_tier(map, SHRINE).projectile_speed = 0.0
	assert_true(_has(EconomyValidation.problems(map), "projectile_speed"), "no bolt speed")


func test_wake_fields_on_a_building_that_is_not_awakened_are_reported() -> void:
	var map: MapConfig = _map()
	_tier(map, HOUSE).wake_radius = 5.0
	_tier(map, HOUSE).wake_threshold_hp = 10
	_tier(map, HOUSE).synergy_percent = 10
	var problems: Array[String] = EconomyValidation.problems(map)
	assert_true(_has(problems, "sets wake_radius"), "the radius")
	assert_true(_has(problems, "sets wake_threshold_hp"), "the threshold")
	assert_true(_has(problems, "sets synergy_percent"), "the synergy")


func test_a_damage_stat_the_registry_does_not_know_is_reported() -> void:
	var map: MapConfig = _map()
	_building(map, SHRINE).damage_stat = &"shrine.dmg"
	var problems: Array[String] = EconomyValidation.problems(map)
	assert_true(_has(problems, "damage_stat"), "the typo is reported")
	assert_true(_has(problems, "shrine.dmg"), "naming the bad id")


func test_a_range_stat_the_registry_does_not_know_is_reported() -> void:
	var map: MapConfig = _map()
	_building(map, SHRINE).range_stat = &"shrine.reach"
	assert_true(_has(EconomyValidation.problems(map), "range_stat"), "the typo is reported")


func test_a_stat_of_the_wrong_kind_is_reported() -> void:
	var map: MapConfig = _map()
	_building(map, HOUSE).damage_stat = &"tower.range"
	_building(map, HOUSE).range_stat = &"tower.damage"
	var problems: Array[String] = EconomyValidation.problems(map)
	assert_true(_has(problems, "damage_stat"), "a float stat cannot carry damage")
	assert_true(_has(problems, "range_stat"), "an integer stat cannot carry reach")


func test_validate_as_a_whole_carries_the_shrine_problems() -> void:
	var map: MapConfig = _map()
	_tier(map, SHRINE).wake_radius = TOO_WIDE
	var found: bool = false
	for problem: String in map.validate():
		found = found or problem.contains("wake_radius")
	assert_true(found, "MapConfig.validate() reports it")
