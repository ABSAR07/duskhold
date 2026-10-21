extends GutTest
## ECON-06, D-12, D-14: the Shrine's kill credit and its wake, kept by IncomeState beside
## BuildingSystem. Every enemy death within the wake radius of a built Shrine adds the dead enemy's
## max health to its credit, from any killer; reaching the threshold wakes it for good and emits
## shrine_woke once; it pays its dawn income only while awake, standing and not rebuilt this dawn.
## Deaths are emitted by hand. The wake numbers are set on a deep copy of the shipped Shrine (radius
## 18 m, threshold twice a grunt's health, 1 gold at dawn), so a later fit of the shipped numbers
## cannot break these tests; test_economy_data_contract is the one place they are pinned.

const WEST: StringName = &"shrine_west"
const EAST: StringName = &"shrine_east"
const HOUSE: StringName = &"house_1"
const GRUNT: StringName = &"grunt"
const SKIRMISHER: StringName = &"ranged"
const WEST_AT := Vector2(-46.0, 30.0)
const EAST_AT := Vector2(46.0, 30.0)
const BETWEEN_AT := Vector2(0.0, 30.0)
const RADIUS: float = 18.0
const GRUNTS_TO_WAKE: int = 2
const PAY: int = 1
const JUST_OUTSIDE: float = 0.01
const WIDE_RADIUS: float = 60.0

var _map: MapConfig
var _events: SimEvents
var _buildings: BuildingSystem
var _income: IncomeState
var _threshold: int = 0


func before_each() -> void:
	_map = E2eSupport.waveless_prototype_map()
	_threshold = _hp(GRUNT) * GRUNTS_TO_WAKE
	_set_shrine(RADIUS, _threshold)
	_rebuild_systems()


func _hp(enemy_id: StringName) -> int:
	return _map.find_enemy(enemy_id).max_health


func _set_shrine(radius: float, threshold: int) -> void:
	for building_def: BuildingDef in _map.buildings:
		if building_def.id == &"shrine":
			var tier: BuildingTierDef = building_def.tier_def(1)
			tier.wake_radius = radius
			tier.wake_threshold_hp = threshold
			tier.dawn_income = PAY


func _rebuild_systems() -> void:
	_events = SimEvents.new()
	_buildings = BuildingSystem.new(_map, _events)
	_income = IncomeState.new(_map, _buildings, _events)
	watch_signals(_events)


func _build(spot_id: StringName) -> void:
	assert_not_null(_buildings.apply_next_tier(spot_id), "%s built" % spot_id)


func _die(enemy_id: StringName, at: Vector2) -> void:
	_events.enemy_died.emit(1, enemy_id, at, &"tower")


func _woke() -> int:
	return get_signal_emit_count(_events, "shrine_woke")


func _fall(spot_id: StringName) -> void:
	_buildings.damage_building(spot_id, _buildings.max_health_of(spot_id))
	assert_true(_buildings.is_destroyed(spot_id), "%s fell" % spot_id)


func test_a_death_exactly_at_the_wake_radius_counts() -> void:
	_build(WEST)
	_die(GRUNT, WEST_AT + Vector2(RADIUS, 0.0))
	assert_eq(_income.kill_credit(WEST), _hp(GRUNT), "the grunt's max health is credited")


func test_a_death_just_outside_the_wake_radius_credits_nothing() -> void:
	_build(WEST)
	_die(GRUNT, WEST_AT + Vector2(RADIUS + JUST_OUTSIDE, 0.0))
	assert_eq(_income.kill_credit(WEST), 0, "0.01 m outside is outside")
	_die(GRUNT, WEST_AT + Vector2(0.0, -(RADIUS + JUST_OUTSIDE)))
	assert_eq(_income.kill_credit(WEST), 0, "on the other axis too")


func test_credit_is_the_dead_enemys_max_health_whoever_it_was() -> void:
	_build(WEST)
	_die(SKIRMISHER, WEST_AT)
	assert_eq(_income.kill_credit(WEST), _hp(SKIRMISHER), "a skirmisher is worth its own health")
	_die(GRUNT, WEST_AT)
	assert_eq(_income.kill_credit(WEST), _hp(SKIRMISHER) + _hp(GRUNT), "and a grunt its own")


func test_a_credit_exactly_equal_to_the_threshold_wakes_the_shrine() -> void:
	_build(WEST)
	_die(GRUNT, WEST_AT)
	assert_false(_income.is_awake(WEST), "half the threshold is still asleep")
	assert_eq(_woke(), 0, "no event yet")
	_die(GRUNT, WEST_AT)
	assert_eq(_income.kill_credit(WEST), _threshold, "exactly the threshold")
	assert_true(_income.is_awake(WEST), "equal wakes it")
	assert_signal_emit_count(_events, "shrine_woke", 1, "one wake event")
	assert_eq(get_signal_parameters(_events, "shrine_woke", 0), [WEST], "for this Shrine")


func test_a_credit_one_short_of_the_threshold_stays_asleep() -> void:
	_set_shrine(RADIUS, _threshold + 1)
	_rebuild_systems()
	_build(WEST)
	_die(GRUNT, WEST_AT)
	_die(GRUNT, WEST_AT)
	assert_eq(_income.kill_credit(WEST), _threshold, "one short of the new threshold")
	assert_false(_income.is_awake(WEST), "asleep")
	_die(GRUNT, WEST_AT)
	assert_true(_income.is_awake(WEST), "the next death passes it")


func test_further_deaths_keep_crediting_but_never_wake_it_twice() -> void:
	_build(WEST)
	for death: int in range(GRUNTS_TO_WAKE + 3):
		_die(GRUNT, WEST_AT)
	assert_eq(_income.kill_credit(WEST), _hp(GRUNT) * (GRUNTS_TO_WAKE + 3), "credit keeps growing")
	assert_signal_emit_count(_events, "shrine_woke", 1, "and only the first crossing announces")
	assert_eq(_income.awake_count(), 1, "one Shrine is awake")


func test_deaths_before_the_shrine_is_built_credit_nothing() -> void:
	for death: int in range(GRUNTS_TO_WAKE + 1):
		_die(GRUNT, WEST_AT)
	assert_eq(_income.kill_credit(WEST), 0, "an empty plot holds no credit")
	assert_false(_income.is_awake(WEST), "and does not wake")
	_build(WEST)
	assert_eq(_income.kill_credit(WEST), 0, "building it later starts from nothing")
	assert_eq(_woke(), 0, "no event")


func test_a_death_inside_both_radii_credits_both_in_map_order() -> void:
	_set_shrine(WIDE_RADIUS, _hp(GRUNT))
	_rebuild_systems()
	_build(EAST)
	_build(WEST)
	_die(GRUNT, BETWEEN_AT)
	assert_eq(_income.kill_credit(WEST), _hp(GRUNT), "the west Shrine is credited")
	assert_eq(_income.kill_credit(EAST), _hp(GRUNT), "so is the east one")
	assert_signal_emit_count(_events, "shrine_woke", 2, "both woke")
	assert_eq(get_signal_parameters(_events, "shrine_woke", 0), [WEST], "west first: map order")
	assert_eq(get_signal_parameters(_events, "shrine_woke", 1), [EAST], "then east")
	assert_eq(_income.awake_count(), 2, "two awake")


func test_a_death_credits_only_the_shrine_whose_radius_holds_it() -> void:
	_build(WEST)
	_build(EAST)
	_die(GRUNT, EAST_AT)
	assert_eq(_income.kill_credit(EAST), _hp(GRUNT), "the east Shrine is credited")
	assert_eq(_income.kill_credit(WEST), 0, "the west one, 92 m away, is not")


func test_a_plot_that_is_not_a_shrine_keeps_no_credit() -> void:
	_build(HOUSE)
	var house_at: Vector3 = _buildings.get_spot(HOUSE).position
	_die(GRUNT, Vector2(house_at.x, house_at.z))
	assert_eq(_income.kill_credit(HOUSE), 0, "a House is not credited")
	assert_false(_income.is_awake(HOUSE), "and never wakes")
	assert_eq(_income.awake_count(), 0, "nobody is awake")


func test_a_death_of_an_unknown_enemy_credits_nothing() -> void:
	_build(WEST)
	_die(&"dragon", WEST_AT)
	assert_eq(
		_income.kill_credit(WEST), 0, "an enemy the map does not list has no health to credit"
	)


func test_a_dormant_shrine_pays_nothing_at_dawn() -> void:
	_build(WEST)
	_die(GRUNT, WEST_AT)
	assert_false(_income.dawn_payouts().has(WEST), "asleep: no payout entry")


func test_an_awake_standing_shrine_pays_its_dawn_income() -> void:
	_build(WEST)
	for death: int in range(GRUNTS_TO_WAKE):
		_die(GRUNT, WEST_AT)
	assert_eq(int(_income.dawn_payouts().get(WEST, 0)), PAY, "awake and standing pays")
	assert_false(_buildings.dawn_income_by_spot().has(WEST), "and only IncomeState pays it")


func test_a_fallen_or_rebuilt_shrine_pays_nothing_but_stays_awake() -> void:
	_build(WEST)
	for death: int in range(GRUNTS_TO_WAKE):
		_die(GRUNT, WEST_AT)
	_fall(WEST)
	assert_false(_income.dawn_payouts().has(WEST), "a fallen Shrine pays nothing")
	assert_true(_income.is_awake(WEST), "and is still awake")
	_buildings.rebuild_destroyed()
	assert_false(_income.dawn_payouts().has(WEST), "rebuilt this dawn: nothing again")
	assert_true(_income.is_awake(WEST), "still awake")
	_buildings.clear_rebuilt_marks()
	assert_eq(int(_income.dawn_payouts().get(WEST, 0)), PAY, "the next dawn it pays")


func test_a_fallen_shrine_keeps_being_credited() -> void:
	_build(WEST)
	_die(GRUNT, WEST_AT)
	_fall(WEST)
	_die(GRUNT, WEST_AT)
	assert_eq(_income.kill_credit(WEST), _threshold, "the death beside the rubble counted")
	assert_true(_income.is_awake(WEST), "and woke it while it lay in rubble")


func test_empty_and_unknown_plots_read_as_zero() -> void:
	assert_eq(_income.kill_credit(WEST), 0, "an empty Shrine plot has no credit")
	assert_false(_income.is_awake(WEST), "and is not awake")
	assert_eq(_income.kill_credit(&"nowhere"), 0, "an unknown plot has no credit")
	assert_false(_income.is_awake(&"nowhere"), "and is not awake")
	assert_eq(_income.awake_count(), 0, "no Shrine is awake")


func test_the_shrine_says_what_wakes_it() -> void:
	var def: BuildingDef = _buildings.get_building_def_for_spot(WEST)
	assert_true(def.pays_income(1), "the tier names dawn gold, so the crossed coin applies")
	assert_eq(
		def.tier_effect_line(1),
		(
			"Wakes after %d enemy health falls within %d m, then shoots and pays %d"
			% [_threshold, 18, PAY]
		),
		"the tier line"
	)
	assert_eq(def.damage_stat, &"shrine.damage", "its damage goes through the shrine stat")
	assert_eq(def.range_stat, &"shrine.range", "and its reach")
