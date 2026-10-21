extends GutTest
## ECON-06, D-12, D-15: awake Shrines strengthen each other through the StatStack. With n Shrines
## awake, one source `shrine_synergy` holds a PERCENT modifier of synergy_percent x (n - 1) on
## shrine.damage; IncomeState replaces the source whenever n changes and removes it below two, so
## repeated wakes can never pile up (T-05-18). The Shrine's data (synergy_percent) is the one home
## of the 20. The percent bucket is shared with every other percent source on the stat, so a Golden
## Age card adds in the same bucket. The numbers are set on a deep copy of the shipped Shrine
## (radius 18 m, threshold twice a grunt's health, synergy 20, damage 3), so a later fit of the
## shipped Shrine cannot break these tests.

const WEST: StringName = &"shrine_west"
const EAST: StringName = &"shrine_east"
const SOURCE: StringName = &"shrine_synergy"
const DAMAGE_STAT: StringName = &"shrine.damage"
const GRUNT: StringName = &"grunt"
const WEST_AT := Vector2(-46.0, 30.0)
const EAST_AT := Vector2(46.0, 30.0)
const BETWEEN_AT := Vector2(0.0, 30.0)
const RADIUS: float = 18.0
const WIDE_RADIUS: float = 60.0
const GRUNTS_TO_WAKE: int = 2
const SYNERGY: int = 20
const DAMAGE: int = 3
const BASE_THREE_WITH_TWENTY: int = 4
const BASE_THREE_WITH_FIFTY: int = 5
const GOLDEN_AGE_PERCENT: int = 25
const BASE_THREE_WITH_FORTY_FIVE: int = 4
const TOUGH_HEALTH: int = 100000
const NEAR: float = 5.0

var _map: MapConfig
var _events: SimEvents
var _stats: StatStack
var _buildings: BuildingSystem
var _income: IncomeState
var _threshold: int = 0


func before_each() -> void:
	_map = E2eSupport.waveless_prototype_map()
	_threshold = _hp() * GRUNTS_TO_WAKE
	_set_shrine(RADIUS, SYNERGY)
	_rebuild_systems()


func _hp() -> int:
	return _map.find_enemy(GRUNT).max_health


func _set_shrine(radius: float, synergy: int) -> void:
	for building_def: BuildingDef in _map.buildings:
		if building_def.id == &"shrine":
			var tier: BuildingTierDef = building_def.tier_def(1)
			tier.wake_radius = radius
			tier.wake_threshold_hp = _threshold
			tier.synergy_percent = synergy
			tier.attack_damage = DAMAGE


func _rebuild_systems() -> void:
	_events = SimEvents.new()
	_stats = StatStack.new()
	_buildings = BuildingSystem.new(_map, _events, _stats)
	_income = IncomeState.new(_map, _buildings, _events, _stats)
	watch_signals(_events)
	watch_signals(_stats)
	assert_not_null(_buildings.apply_next_tier(WEST), "west built")
	assert_not_null(_buildings.apply_next_tier(EAST), "east built")


func _wake(at: Vector2) -> void:
	for death: int in range(GRUNTS_TO_WAKE):
		_events.enemy_died.emit(death, GRUNT, at, &"tower")


func _pct() -> int:
	return int(_stats.sums_of(DAMAGE_STAT)["pct"])


func _modifier(bucket: StatModifierDef.Bucket, value: int) -> StatModifierDef:
	var mod: StatModifierDef = StatModifierDef.new()
	mod.stat = DAMAGE_STAT
	mod.bucket = bucket
	mod.value = value
	return mod


func test_with_no_shrine_awake_there_is_no_synergy_source() -> void:
	assert_false(_stats.has_source(SOURCE), "nobody is awake")
	assert_eq(_stats.int_value(DAMAGE_STAT, DAMAGE), DAMAGE, "the damage is the base")


func test_with_exactly_one_awake_the_source_is_absent_and_the_damage_is_the_base() -> void:
	_wake(WEST_AT)
	assert_eq(_income.awake_count(), 1, "one awake")
	assert_false(_stats.has_source(SOURCE), "nothing to strengthen it")
	assert_eq(_stats.int_value(DAMAGE_STAT, DAMAGE), DAMAGE, "its damage equals the base")
	assert_signal_not_emitted(_stats, "changed", "the stack was not touched")


func test_with_both_awake_the_source_is_twenty_percent_on_shrine_damage() -> void:
	_wake(WEST_AT)
	_wake(EAST_AT)
	assert_eq(_income.awake_count(), 2, "both awake")
	assert_true(_stats.has_source(SOURCE), "the synergy source exists")
	assert_eq(_pct(), SYNERGY, "PERCENT +20 for one other awake Shrine")
	assert_eq(_stats.sums_of(DAMAGE_STAT)["flat"], 0, "no flat part")
	assert_eq((_stats.sums_of(DAMAGE_STAT)["mults"] as Array).size(), 0, "no multiplier")
	assert_eq(
		_stats.int_value(DAMAGE_STAT, DAMAGE), BASE_THREE_WITH_TWENTY, "3 x 1.2 = 3.6 rounds to 4"
	)
	assert_eq(_stats.source_ids(), [SOURCE] as Array[StringName], "and it is the only source")


func test_the_percent_comes_from_the_shrine_data() -> void:
	_set_shrine(RADIUS, 50)
	_rebuild_systems()
	_wake(WEST_AT)
	_wake(EAST_AT)
	assert_eq(_pct(), 50, "a Shrine whose data says 50 gives +50")
	assert_eq(
		_stats.int_value(DAMAGE_STAT, DAMAGE), BASE_THREE_WITH_FIFTY, "3 x 1.5 = 4.5 rounds up"
	)


func test_a_synergy_of_zero_in_the_data_adds_no_source() -> void:
	_set_shrine(RADIUS, 0)
	_rebuild_systems()
	_wake(WEST_AT)
	_wake(EAST_AT)
	assert_eq(_income.awake_count(), 2, "both awake")
	assert_false(_stats.has_source(SOURCE), "a Shrine with no synergy adds none")


func test_waking_both_on_the_same_tick_sets_the_source_once_and_announces_in_map_order() -> void:
	_set_shrine(WIDE_RADIUS, SYNERGY)
	_rebuild_systems()
	_events.enemy_died.emit(1, GRUNT, BETWEEN_AT, &"tower")
	_events.enemy_died.emit(2, GRUNT, BETWEEN_AT, &"tower")
	assert_eq(_income.awake_count(), 2, "one pair of deaths woke both")
	assert_signal_emit_count(_events, "shrine_woke", 2, "two wake events")
	assert_eq(get_signal_parameters(_events, "shrine_woke", 0), [WEST], "west first")
	assert_eq(get_signal_parameters(_events, "shrine_woke", 1), [EAST], "then east")
	assert_eq(_pct(), SYNERGY, "the source ends at the final count")
	assert_signal_emit_count(_stats, "changed", 1, "and the stack changed once, not twice")


func test_repeated_deaths_and_wakes_never_pile_the_source_up() -> void:
	_wake(WEST_AT)
	_wake(EAST_AT)
	for death: int in range(20):
		_events.enemy_died.emit(death, GRUNT, WEST_AT, &"tower")
		_events.enemy_died.emit(death, GRUNT, EAST_AT, &"tower")
	assert_eq(_pct(), SYNERGY, "still +20, not more")
	assert_eq(_stats.source_ids(), [SOURCE] as Array[StringName], "one source")
	assert_signal_emit_count(_stats, "changed", 1, "and the stack was touched only by the wake")


func test_a_golden_age_card_and_the_synergy_add_in_the_percent_bucket() -> void:
	var golden: Array[StatModifierDef] = [
		_modifier(StatModifierDef.Bucket.PERCENT, GOLDEN_AGE_PERCENT)
	]
	assert_true(_stats.add_source(&"golden_age", golden), "the card is armed")
	_wake(WEST_AT)
	_wake(EAST_AT)
	assert_eq(_pct(), GOLDEN_AGE_PERCENT + SYNERGY, "+25 and +20 sum to +45")
	assert_eq(
		_stats.int_value(DAMAGE_STAT, DAMAGE),
		BASE_THREE_WITH_FORTY_FIVE,
		"3 x 1.45 = 4.35 rounds to 4, not 3 x 1.25 x 1.2 = 4.5"
	)
	assert_eq(_stats.int_value(DAMAGE_STAT, 20), 29, "a base of 20 gives 29 (x1.45)")


func test_the_synergy_never_touches_the_tower_stats() -> void:
	_wake(WEST_AT)
	_wake(EAST_AT)
	assert_eq(_stats.int_value(&"tower.damage", DAMAGE), DAMAGE, "tower damage is the base")
	assert_eq(_stats.float_value(&"tower.range", 9.0), 9.0, "and tower range")
	assert_false(_stats.is_modified(&"tower.damage"), "nothing modifies it")


func test_each_awake_shrines_bolt_carries_the_boosted_damage() -> void:
	_wake(WEST_AT)
	_wake(EAST_AT)
	var enemies: EnemySystem = EnemySystem.new(_events)
	var hits: PendingHits = PendingHits.new()
	var towers: TowerSystem = TowerSystem.new(_buildings, _events, _stats, _income)
	towers.begin_night()
	var tough: EnemyDef = (_map.find_enemy(GRUNT)).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	tough.max_health = TOUGH_HEALTH
	enemies.spawn(tough, WEST_AT + Vector2(NEAR, 0.0))
	enemies.spawn(tough, EAST_AT + Vector2(NEAR, 0.0))
	towers.step(0, enemies, hits)
	var landed: Array[int] = []
	var horizon: int = 100
	for tick: int in range(horizon):
		for hit: PendingHits.Hit in hits.take_due(tick):
			landed.append(hit.amount)
	assert_eq(
		landed,
		[BASE_THREE_WITH_TWENTY, BASE_THREE_WITH_TWENTY] as Array[int],
		"both Shrines hit for 4"
	)
