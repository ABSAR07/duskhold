extends GutTest
## META-08: every modifiable stat is read through the stack at the point the game already read the
## def value. Each consumer is built by hand on an existing fixture with a shared StatStack, once
## with no source (the old value) and once with a source (the modified value). Expectations come
## from the data files, so tuning cannot break them. Health refresh is in test_stat_refresh.gd.

const SQUADS_FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const WALLS_FIXTURE := "res://tests/fixtures/fixture_map_walls.tres"
const KING_PATH := "res://data/king/king.tres"
const GRUNT_PATH := "res://data/enemies/grunt.tres"
const FOOTMAN_PATH := "res://data/units/footman.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const BARRACKS: StringName = &"barracks_1"
const HOUSE: StringName = &"house_1"
const WALL: StringName = &"wall_ring"
const TOUGH_HEALTH: int = 100000
const WITHIN_SWORD := Vector2(1.0, 0.0)

var _events: SimEvents
var _stats: StatStack
var _hits: PendingHits
var _enemies: EnemySystem


func before_each() -> void:
	_events = SimEvents.new()
	_stats = StatStack.new()
	_hits = PendingHits.new()
	_enemies = EnemySystem.new(_events)


func _add(source: StringName, stat: StringName, bucket: StatModifierDef.Bucket, value: int) -> void:
	var mod: StatModifierDef = StatModifierDef.new()
	mod.stat = stat
	mod.bucket = bucket
	mod.value = value
	var mods: Array[StatModifierDef] = [mod]
	assert_true(_stats.add_source(source, mods), "source %s accepted" % source)


func _map(path: String) -> MapConfig:
	return (load(path) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)


func _king() -> KingState:
	return KingState.new(load(KING_PATH), Vector2.ZERO, _events, load(TUNING), _stats)


func _tough_grunt() -> EnemyDef:
	var def: EnemyDef = (load(GRUNT_PATH) as EnemyDef).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	def.max_health = TOUGH_HEALTH
	return def


## The amounts of the hits queued so far, in queue order.
func _amounts() -> Array[int]:
	var amounts: Array[int] = []
	for hit: PendingHits.Hit in _hits.take_due(1000000):
		amounts.append(hit.amount)
	return amounts


func test_the_king_reads_health_damage_and_slam_through_the_stack() -> void:
	var weapon: WeaponDef = (load(KING_PATH) as KingDef).weapon
	var base_health: int = (load(KING_PATH) as KingDef).max_health
	assert_eq(_king().get_max_health(), base_health, "no source: the def's health")
	_add(&"hp", &"king.max_health", StatModifierDef.Bucket.PERCENT, 50)
	_add(&"blade", &"king.attack_damage", StatModifierDef.Bucket.FLAT, 2)
	_add(&"slam", &"king.slam_damage", StatModifierDef.Bucket.FLAT, 3)
	var king: KingState = _king()
	assert_eq(king.get_max_health(), roundi(base_health * 1.5), "+50% health")
	assert_eq(king.get_health(), king.get_max_health(), "he starts at the stacked maximum")
	_enemies.spawn(_tough_grunt(), WITHIN_SWORD)
	king.step(0, _enemies, _hits)
	king.activate_ability()
	king.resolve_ability(0, _enemies, _hits)
	assert_eq(_amounts(), [weapon.attack_damage + 2, weapon.slam_damage + 3] as Array[int])


func test_with_no_source_the_king_hits_for_the_weapon_numbers() -> void:
	var weapon: WeaponDef = (load(KING_PATH) as KingDef).weapon
	var king: KingState = _king()
	_enemies.spawn(_tough_grunt(), WITHIN_SWORD)
	king.step(0, _enemies, _hits)
	king.activate_ability()
	king.resolve_ability(0, _enemies, _hits)
	assert_eq(_amounts(), [weapon.attack_damage, weapon.slam_damage] as Array[int], "unchanged")


func test_the_king_attack_interval_follows_the_stack() -> void:
	var weapon: WeaponDef = (load(KING_PATH) as KingDef).weapon
	_add(&"assassin", &"king.attack_interval", StatModifierDef.Bucket.MULTIPLIER, 200)
	var king: KingState = _king()
	_enemies.spawn(_tough_grunt(), WITHIN_SWORD)
	var ticks_at: Array[int] = []
	for tick: int in range(200):
		king.step(tick, _enemies, _hits)
		if not _hits.take_due(tick).is_empty():
			ticks_at.append(tick)
	assert_gt(ticks_at.size(), 1, "he swings more than once")
	assert_eq(ticks_at[1], SimClock.ticks(weapon.attack_interval * 2.0), "the gap doubled")


func test_damage_the_king_takes_follows_the_stack_and_never_drops_a_hit_to_nothing() -> void:
	_add(&"armor", &"king.damage_taken", StatModifierDef.Bucket.MULTIPLIER, 75)
	var king: KingState = _king()
	var before: int = king.get_health()
	king.take_damage(4)
	assert_eq(before - king.get_health(), 3, "a 4 hit takes 3")
	before = king.get_health()
	king.take_damage(1)
	assert_eq(before - king.get_health(), 1, "a 1 hit still takes 1")


func test_a_unit_spawned_after_a_health_source_has_the_stacked_health() -> void:
	var footman: UnitDef = load(FOOTMAN_PATH)
	_add(&"commander", &"unit.max_health", StatModifierDef.Bucket.PERCENT, 25)
	var squads: SquadSystem = _squads(_map(SQUADS_FIXTURE))
	var units: UnitSystem = squads.get_units()
	var ids: Array[int] = units.ids()
	assert_false(ids.is_empty(), "the barracks fielded its squad")
	assert_eq(units.health_of(ids[0]), roundi(footman.max_health * 1.25), "+25%")


func _squads(map: MapConfig) -> SquadSystem:
	var buildings: BuildingSystem = BuildingSystem.new(map, _events, _stats)
	var squads: SquadSystem = SquadSystem.new(map, buildings, _events, _stats)
	buildings.apply_next_tier(BARRACKS)
	squads.step(0, _enemies, _hits, false)
	return squads


func test_a_unit_hit_carries_the_stacked_unit_damage() -> void:
	var footman: UnitDef = load(FOOTMAN_PATH)
	_add(&"commander", &"unit.attack_damage", StatModifierDef.Bucket.FLAT, 2)
	var map: MapConfig = _map(SQUADS_FIXTURE)
	var squads: SquadSystem = _squads(map)
	var anchor: Vector2 = squads.anchor_of(BARRACKS)
	_enemies.spawn(_tough_grunt(), anchor + Vector2(1.5, 0.0))
	var seen: Array[int] = []
	for tick: int in range(1, 200):
		squads.step(tick, _enemies, _hits, true)
		seen.append_array(_amounts())
		if not seen.is_empty():
			break
	assert_false(seen.is_empty(), "a unit struck")
	assert_eq(seen[0], footman.attack_damage + 2, "the def's damage plus the source")


func test_a_squad_respawn_time_follows_the_stack() -> void:
	_add(&"banner", &"squad.respawn_seconds", StatModifierDef.Bucket.MULTIPLIER, 50)
	var map: MapConfig = _map(SQUADS_FIXTURE)
	var squads: SquadSystem = _squads(map)
	var building: BuildingDef = BuildingSystem.new(map, _events).get_building_def_for_spot(BARRACKS)
	var seconds: float = building.tier_def(1).squad_respawn_seconds
	squads.damage_unit(squads.unit_ids_of(BARRACKS)[0], 1000, &"test")
	squads.remove_dead()
	var steps: int = 0
	while squads.alive_count(BARRACKS) < squads.max_count(BARRACKS) and steps < 2000:
		squads.step(steps + 1, _enemies, _hits, true)
		steps += 1
	assert_eq(steps, SimClock.ticks(seconds * 0.5), "half the data's seconds")


func test_a_house_built_after_a_health_source_stands_at_the_stacked_health() -> void:
	var map: MapConfig = _map(SQUADS_FIXTURE)
	var house: BuildingDef = load("res://data/buildings/house.tres")
	var base: int = house.tier_def(1).max_health
	var buildings: BuildingSystem = BuildingSystem.new(map, _events, _stats)
	buildings.apply_next_tier(HOUSE)
	assert_eq(buildings.max_health_of(HOUSE), base, "no source: the tier's health")
	_add(&"masons", &"building.max_health", StatModifierDef.Bucket.PERCENT, 30)
	var fresh: BuildingSystem = BuildingSystem.new(map, _events, _stats)
	fresh.apply_next_tier(HOUSE)
	assert_eq(fresh.max_health_of(HOUSE), roundi(base * 1.3), "+30%")
	assert_eq(fresh.health_of(HOUSE), fresh.max_health_of(HOUSE), "built at full health")


func test_a_wall_run_built_after_a_health_source_has_stacked_segments() -> void:
	var map: MapConfig = _map(WALLS_FIXTURE)
	var wall: BuildingDef = load("res://data/buildings/wall.tres")
	var base: int = wall.tier_def(1).max_health
	_add(&"masons", &"wall.max_health", StatModifierDef.Bucket.PERCENT, 30)
	var buildings: BuildingSystem = BuildingSystem.new(map, _events, _stats)
	var walls: WallSystem = WallSystem.new(map, buildings, _events, _stats)
	buildings.apply_next_tier(WALL)
	var segments: PackedInt32Array = walls.segments_of(WALL)
	assert_false(segments.is_empty(), "the run has segments")
	assert_eq(walls.max_health_of(segments[0]), roundi(base * 1.3), "39 for a 30-health tier")
	assert_eq(walls.health_of(segments[0]), walls.max_health_of(segments[0]), "built whole")
	assert_eq(buildings.max_health_of(WALL), base, "the plot's own instance keeps the raw tier")


func _armed_map() -> MapConfig:
	var map: MapConfig = MapConfig.new()
	map.castle_max_health = 40
	map.castle_attack_damage = 2
	map.castle_attack_range = 22.0
	map.castle_attack_interval = 1.5
	map.castle_projectile_speed = 27.0
	map.base_dawn_income = 1
	return map


func test_with_no_source_the_castle_reads_the_map_numbers() -> void:
	var map: MapConfig = _armed_map()
	var castle: CastleState = CastleState.new(map, _events, _stats)
	assert_eq(castle.get_max_health(), 40, "health")
	assert_eq(castle.arrow_damage(), 2, "arrow damage")
	assert_eq(castle.arrow_range(), 22.0, "arrow range")
	assert_eq(castle.arrow_interval(), 1.5, "arrow interval")
	assert_eq(castle.arrow_speed(), 27.0, "arrow speed")
	assert_eq(castle.base_income(), 1, "base income")


func test_the_castle_reads_health_arrow_and_income_through_the_stack() -> void:
	_add(&"fort", &"castle.max_health", StatModifierDef.Bucket.PERCENT, 50)
	_add(&"fort_arrow", &"castle.arrow_damage", StatModifierDef.Bucket.FLAT, 1)
	_add(&"fort_reach", &"castle.arrow_range", StatModifierDef.Bucket.PERCENT, 50)
	_add(&"fort_gold", &"castle.base_income", StatModifierDef.Bucket.FLAT, 2)
	var castle: CastleState = CastleState.new(_armed_map(), _events, _stats)
	assert_eq(castle.get_max_health(), 60, "40 + 50%")
	assert_eq(castle.get_health(), 60, "and it stands at it")
	assert_eq(castle.arrow_damage(), 3, "2 + 1")
	assert_almost_eq(castle.arrow_range(), 33.0, 0.000001, "22 m + 50%")
	assert_eq(castle.base_income(), 3, "1 + 2")


func test_the_castle_arrow_hit_carries_the_stacked_damage() -> void:
	_add(&"fort_arrow", &"castle.arrow_damage", StatModifierDef.Bucket.FLAT, 1)
	var map: MapConfig = _armed_map()
	var castle: CastleState = CastleState.new(map, _events, _stats)
	var attack: CastleAttack = CastleAttack.new(map, castle, _events)
	_enemies.spawn(_tough_grunt(), Vector2(6.0, 0.0))
	attack.step(0, _enemies, _hits)
	assert_eq(_amounts(), [3] as Array[int], "2 from the map plus 1")


func test_the_next_dawn_pays_the_stacked_castle_income_under_the_castle_key() -> void:
	var map: MapConfig = E2eSupport.waveless_prototype_map()
	var tuning: LoopTuning = load(TUNING)
	var ctx: RunContext = RunContext.new(map, tuning)
	var base: int = map.base_dawn_income
	var extra: StatModifierDef = StatModifierDef.new()
	extra.stat = &"castle.base_income"
	extra.bucket = StatModifierDef.Bucket.FLAT
	extra.value = 2
	var mods: Array[StatModifierDef] = [extra]
	assert_true(ctx.stat_stack.add_source(&"prosperity", mods), "source accepted")
	watch_signals(ctx.events)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night starts")
	ctx.run_manager.tick(tuning.placeholder_night_seconds + 0.1)
	var payout: Dictionary = get_signal_parameters(ctx.events, "dawn_payout", 0)[1]
	assert_eq(payout[MapConfig.CASTLE_PAYOUT_KEY], base + 2, "the castle key carries base + 2")
