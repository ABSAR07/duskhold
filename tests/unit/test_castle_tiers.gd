extends GutTest
## BLDG-08, D-01, D-04: the castle is a plot that starts standing at tier I and is bought up like
## any plot. Tier I is the map's own castle fields (no number has two homes); tiers II to IV take
## their numbers from castle_center.tres. CastleState alone owns the castle's health: the plot's
## BuildingSystem instance carries only the tier (health_of and max_health_of read 0), is never a
## target, never pays per-spot income and is never damaged or rebuilt there. Every expected number
## is read from the data, so plan 05-11's retune does not break the test.

const FIXTURE := "res://tests/fixtures/fixture_map_castle.tres"
const PROTOTYPE := "res://data/maps/prototype_map.tres"
const NO_CASTLE_FIXTURE := "res://tests/fixtures/fixture_map_one_night.tres"
const CASTLE_DEF := "res://data/buildings/castle_center.tres"
const GRUNT_PATH := "res://data/enemies/grunt.tres"
const KING_PATH := "res://data/king/king.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const CASTLE: StringName = &"castle_plot"
const COMMANDER: StringName = &"commander"
const PROSPERITY: StringName = &"prosperity"
const MASONS: StringName = &"masons"
const GOLD: int = 200

var _payouts: Array[Dictionary] = []
var _damage_events: int = 0


func before_each() -> void:
	_payouts = []
	_damage_events = 0


func _def() -> BuildingDef:
	return load(CASTLE_DEF)


func _tier(tier: int) -> BuildingTierDef:
	return _def().tier_def(tier)


func _context(path: String = FIXTURE) -> RunContext:
	var map: MapConfig = (load(path) as MapConfig).duplicate(true)
	map.starting_gold = GOLD
	var ctx: RunContext = RunContext.new(map, load(TUNING))
	ctx.events.dawn_payout.connect(_on_payout)
	ctx.events.building_damaged.connect(_on_damage_event)
	ctx.events.building_destroyed.connect(_on_destroy_event)
	return ctx


func _on_payout(_total: int, per_spot: Dictionary) -> void:
	_payouts.append(per_spot)


func _on_damage_event(_spot: StringName, _amount: int, _hp: int, _max_hp: int) -> void:
	_damage_events += 1


func _on_destroy_event(_spot: StringName, _building: StringName, _tier: int) -> void:
	_damage_events += 1


func _buy(ctx: RunContext, card: StringName = &"") -> void:
	assert_eq(ctx.commands.submit(BuildIntent.new(CASTLE, card)), CommandProcessor.OK, "bought")


## One full placeholder night ending in the next day, so the dawn payout lands in _payouts.
func _through_a_night(ctx: RunContext) -> void:
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night")
	ctx.run_manager.tick(ctx.tuning.placeholder_night_seconds + 0.1)
	ctx.run_manager.tick(ctx.tuning.dawn_seconds)


func test_building_the_systems_emits_no_building_built_for_the_castle() -> void:
	var events: SimEvents = SimEvents.new()
	watch_signals(events)
	var buildings: BuildingSystem = BuildingSystem.new(load(FIXTURE), events)
	assert_signal_not_emitted(events, "building_built", "the castle simply stands")
	assert_eq(buildings.current_tier(CASTLE), 1, "at tier I")


func test_the_castle_plot_stands_at_tier_one_and_is_not_a_standing_building() -> void:
	var ctx: RunContext = _context(PROTOTYPE)
	assert_eq(ctx.buildings.current_tier(CASTLE), 1, "tier I from the start")
	assert_false(ctx.buildings.standing_spot_ids().has(CASTLE), "never a target")
	assert_false(ctx.buildings.dawn_income_by_spot().has(CASTLE), "never a per-spot payer")
	assert_true(ctx.buildings.spot_ids().has(CASTLE), "but a spot the king can hold at")


func test_at_tier_one_every_number_is_the_maps_castle_field() -> void:
	var ctx: RunContext = _context(PROTOTYPE)
	var map: MapConfig = ctx.map
	assert_true(ctx.castle.has_tiers(), "the prototype castle has tiers")
	assert_eq(ctx.castle.tier(), 1, "tier I")
	assert_eq(ctx.castle.plot_id(), CASTLE, "on its plot")
	assert_eq(ctx.castle.get_max_health(), map.castle_max_health, "health")
	assert_eq(ctx.castle.get_health(), map.castle_max_health, "whole")
	assert_eq(ctx.castle.arrow_damage(), map.castle_attack_damage, "arrow damage")
	assert_eq(ctx.castle.arrow_range(), map.castle_attack_range, "arrow range")
	assert_eq(ctx.castle.arrow_interval(), map.castle_attack_interval, "arrow interval")
	assert_eq(ctx.castle.arrow_speed(), map.castle_projectile_speed, "arrow speed")
	assert_eq(ctx.castle.base_income(), map.base_dawn_income, "base income")


func test_a_map_copy_with_a_smaller_castle_starts_the_castle_at_that_health() -> void:
	var map: MapConfig = (load(PROTOTYPE) as MapConfig).duplicate(true)
	map.castle_max_health = 1
	var ctx: RunContext = RunContext.new(map, load(TUNING))
	assert_eq(ctx.castle.get_max_health(), 1, "tier I reads the map")
	assert_eq(ctx.castle.get_health(), 1, "and starts there")


func test_a_map_without_a_castle_plot_has_no_tiers_and_keeps_the_map_numbers() -> void:
	var ctx: RunContext = _context(NO_CASTLE_FIXTURE)
	var map: MapConfig = ctx.map
	assert_false(ctx.castle.has_tiers(), "no tiers")
	assert_eq(ctx.castle.tier(), 0, "tier 0")
	assert_eq(ctx.castle.plot_id(), &"", "no plot")
	assert_eq(ctx.castle.get_max_health(), map.castle_max_health, "health")
	assert_eq(ctx.castle.arrow_damage(), map.castle_attack_damage, "arrow damage")
	assert_eq(ctx.castle.arrow_range(), map.castle_attack_range, "arrow range")
	assert_eq(ctx.castle.base_income(), maxi(map.base_dawn_income, 0), "base income")


func test_buying_tier_two_gives_the_castle_the_tier_two_numbers() -> void:
	var ctx: RunContext = _context()
	_buy(ctx, COMMANDER)
	var tier: BuildingTierDef = _tier(2)
	assert_eq(ctx.castle.tier(), 2, "tier II")
	assert_eq(ctx.castle.get_max_health(), tier.max_health, "maximum health")
	assert_eq(ctx.castle.get_health(), tier.max_health, "and whole")
	assert_eq(ctx.castle.arrow_damage(), tier.attack_damage, "arrow damage")
	assert_eq(ctx.castle.arrow_range(), tier.attack_range, "arrow range")
	assert_eq(ctx.castle.arrow_interval(), tier.attack_interval, "arrow interval")
	assert_eq(ctx.castle.arrow_speed(), tier.projectile_speed, "arrow speed")
	assert_eq(ctx.castle.base_income(), tier.dawn_income, "base income")


func test_tiers_three_and_four_raise_the_numbers_again() -> void:
	var ctx: RunContext = _context()
	_buy(ctx, COMMANDER)
	_buy(ctx, &"headsmans_edge")
	assert_eq(ctx.castle.get_max_health(), _tier(3).max_health, "tier III health")
	assert_eq(ctx.castle.arrow_damage(), _tier(3).attack_damage, "tier III arrow")
	_buy(ctx, &"iron_discipline")
	assert_eq(ctx.castle.tier(), 4, "tier IV")
	assert_eq(ctx.castle.get_max_health(), _tier(4).max_health, "tier IV health")
	assert_eq(ctx.castle.arrow_damage(), _tier(4).attack_damage, "tier IV arrow")
	assert_eq(ctx.castle.base_income(), _tier(4).dawn_income, "tier IV income")
	assert_eq(ctx.commands.validate_build(CASTLE), CommandProcessor.MAX_TIER, "nothing left")


func test_the_upgrade_heals_a_hurt_castle_to_the_new_maximum() -> void:
	var ctx: RunContext = _context()
	ctx.castle.damage(10)
	assert_lt(ctx.castle.get_health(), ctx.castle.get_max_health(), "hurt")
	_buy(ctx, COMMANDER)
	assert_eq(ctx.castle.get_health(), _tier(2).max_health, "whole at the new maximum")


func test_the_next_dawn_pays_the_tier_two_income_under_the_castle_key() -> void:
	var ctx: RunContext = _context()
	_buy(ctx, COMMANDER)
	_through_a_night(ctx)
	assert_eq(_payouts.size(), 1, "one payout")
	assert_eq(_payouts[0].get(MapConfig.CASTLE_PAYOUT_KEY), _tier(2).dawn_income, "tier II income")
	assert_false(_payouts[0].has(CASTLE), "and nothing under the plot id")


func test_the_prosperity_card_adds_its_gold_to_the_tier_income() -> void:
	var ctx: RunContext = _context()
	_buy(ctx, PROSPERITY)
	var bonus: int = ctx.choices.find_choice(PROSPERITY).modifiers[0].value
	assert_eq(ctx.castle.base_income(), _tier(2).dawn_income + bonus, "income plus the card")


func test_the_plot_instance_carries_only_the_tier_and_no_health() -> void:
	var ctx: RunContext = _context(PROTOTYPE)
	assert_false(ctx.buildings.is_destroyed(CASTLE), "not destroyed")
	assert_eq(ctx.buildings.health_of(CASTLE), 0, "the instance has no health")
	assert_eq(ctx.buildings.max_health_of(CASTLE), 0, "and no maximum")
	assert_eq(ctx.castle.get_max_health(), ctx.map.castle_max_health, "CastleState owns it")


func test_after_a_purchase_the_instance_still_reads_zero_while_the_castle_reads_the_tier() -> void:
	var ctx: RunContext = _context()
	_buy(ctx, MASONS)
	assert_eq(ctx.buildings.health_of(CASTLE), 0, "still no health there")
	assert_eq(ctx.buildings.max_health_of(CASTLE), 0, "even with a building health card")
	assert_eq(ctx.castle.get_max_health(), _tier(2).max_health, "the castle reads the tier")


func test_a_hit_on_the_castle_plot_is_dropped_and_leaves_the_castle_alone() -> void:
	var ctx: RunContext = _context(PROTOTYPE)
	ctx.buildings.damage_building(CASTLE, 5)
	assert_eq(_damage_events, 0, "no building_damaged and no building_destroyed")
	assert_eq(ctx.castle.get_health(), ctx.map.castle_max_health, "the castle is untouched")
	assert_false(ctx.buildings.is_destroyed(CASTLE), "still standing")


func test_the_dawn_rebuild_and_repair_leave_the_castle_plot_alone() -> void:
	var ctx: RunContext = _context(PROTOTYPE)
	ctx.buildings.damage_building(CASTLE, 1000)
	var rebuilt: Array[StringName] = ctx.buildings.rebuild_destroyed()
	ctx.buildings.repair_standing()
	assert_false(rebuilt.has(CASTLE), "never rebuilt")
	assert_false(ctx.buildings.is_destroyed(CASTLE), "never destroyed")
	assert_eq(ctx.buildings.get_instance(CASTLE).rebuilt_this_dawn, false, "no rebuilt mark")


func test_an_enemy_next_to_the_castle_plot_never_takes_it_as_a_building_target() -> void:
	var events: SimEvents = SimEvents.new()
	var map: MapConfig = load(FIXTURE)
	var castle: CastleState = CastleState.new(map, events)
	var buildings: BuildingSystem = BuildingSystem.new(map, events)
	var king: KingState = KingState.new(
		load(KING_PATH), Vector2(500.0, 500.0), events, load(TUNING)
	)
	king.report_position(Vector2(500.0, 500.0))
	var enemies: EnemySystem = EnemySystem.new(events)
	var hits: PendingHits = PendingHits.new()
	var plot: Vector3 = buildings.get_spot(CASTLE).position
	var id: int = enemies.spawn(load(GRUNT_PATH), Vector2(plot.x, plot.z + 0.5))
	enemies.step(0, castle, king, hits, buildings)
	var building_target: Dictionary = {
		"kind": PendingHits.KIND_BUILDING, "id": buildings.spot_index(CASTLE)
	}
	assert_ne(enemies.target_of(id), building_target, "the plot is not a target")
	assert_eq(enemies.target_of(id).get("kind"), PendingHits.KIND_CASTLE, "the castle is")


func test_two_castle_plots_are_reported_by_validate() -> void:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	assert_eq(map.validate().size(), 0, "one castle plot is fine")
	var extra: BuildSpotDef = map.spots[1].duplicate()
	extra.id = &"second_castle_plot"
	extra.position = Vector3(20.0, 0.0, 20.0)
	map.spots.append(extra)
	var report: String = ", ".join(map.validate())
	assert_true(report.contains("castle plots"), "a second one is reported: %s" % report)
