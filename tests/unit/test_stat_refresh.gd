extends GutTest
## META-08, Pitfall 8: a change to a stat's maximum (king, unit, building, wall, castle health)
## raises current health by the gain of the maximum and never heals beyond it; a hurt building stays
## hurt by the same amount, a broken wall segment stays broken, a fallen building stays fallen
## until the dawn rebuild. Removing the source lowers the maximum and clamps current health into
## [1, max] for a standing thing. Hand-built systems on the existing fixtures, one shared stack.

const SQUADS_FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const WALLS_FIXTURE := "res://tests/fixtures/fixture_map_walls.tres"
const KING_PATH := "res://data/king/king.tres"
const BARRACKS: StringName = &"barracks_1"
const HOUSE: StringName = &"house_1"
const WALL: StringName = &"wall_ring"
const PLUS_HALF := 50

var _events: SimEvents
var _stats: StatStack
var _map: MapConfig
var _buildings: BuildingSystem


func before_each() -> void:
	_events = SimEvents.new()
	_stats = StatStack.new()
	_map = (load(SQUADS_FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	_buildings = BuildingSystem.new(_map, _events, _stats)


func _percent(source: StringName, stat: StringName, value: int) -> void:
	var mod: StatModifierDef = StatModifierDef.new()
	mod.stat = stat
	mod.bucket = StatModifierDef.Bucket.PERCENT
	mod.value = value
	var mods: Array[StatModifierDef] = [mod]
	assert_true(_stats.add_source(source, mods), "source %s accepted" % source)


func _house_hp() -> int:
	return (load("res://data/buildings/house.tres") as BuildingDef).tier_def(1).max_health


func test_a_standing_house_is_raised_to_the_new_maximum() -> void:
	_buildings.apply_next_tier(HOUSE)
	assert_eq(_buildings.health_of(HOUSE), _house_hp(), "full before")
	_percent(&"masons", &"building.max_health", PLUS_HALF)
	assert_eq(_buildings.max_health_of(HOUSE), roundi(_house_hp() * 1.5), "maximum raised")
	assert_eq(_buildings.health_of(HOUSE), _buildings.max_health_of(HOUSE), "and it is full")


func test_a_hurt_house_stays_hurt_by_the_same_amount() -> void:
	_buildings.apply_next_tier(HOUSE)
	_buildings.damage_building(HOUSE, 5)
	var hurt_by: int = _buildings.max_health_of(HOUSE) - _buildings.health_of(HOUSE)
	_percent(&"masons", &"building.max_health", PLUS_HALF)
	var gain: int = roundi(_house_hp() * 1.5) - _house_hp()
	assert_eq(_buildings.health_of(HOUSE), _house_hp() - 5 + gain, "raised by the gain")
	assert_eq(_buildings.max_health_of(HOUSE) - _buildings.health_of(HOUSE), hurt_by, "still hurt")


func test_a_destroyed_house_stays_down_and_is_rebuilt_at_the_new_maximum() -> void:
	_buildings.apply_next_tier(HOUSE)
	_buildings.damage_building(HOUSE, _house_hp())
	assert_true(_buildings.is_destroyed(HOUSE), "it fell")
	_percent(&"masons", &"building.max_health", PLUS_HALF)
	assert_eq(_buildings.health_of(HOUSE), 0, "still at zero")
	assert_true(_buildings.is_destroyed(HOUSE), "still fallen")
	_buildings.rebuild_destroyed()
	assert_eq(_buildings.health_of(HOUSE), roundi(_house_hp() * 1.5), "rebuilt at the new maximum")


func test_removing_the_building_source_lowers_the_maximum_and_clamps_health() -> void:
	_buildings.apply_next_tier(HOUSE)
	_percent(&"masons", &"building.max_health", PLUS_HALF)
	_buildings.damage_building(HOUSE, _buildings.max_health_of(HOUSE) - 1)
	assert_eq(_buildings.health_of(HOUSE), 1, "almost down")
	_stats.remove_source(&"masons")
	assert_eq(_buildings.max_health_of(HOUSE), _house_hp(), "maximum back to the data")
	assert_eq(_buildings.health_of(HOUSE), 1, "a standing house is never below 1")
	assert_false(_buildings.is_destroyed(HOUSE), "and it did not fall")


func test_a_wall_source_raises_intact_segments_and_leaves_a_broken_one_broken() -> void:
	var map: MapConfig = (load(WALLS_FIXTURE) as MapConfig).duplicate_deep(
		Resource.DEEP_DUPLICATE_ALL
	)
	var buildings: BuildingSystem = BuildingSystem.new(map, _events, _stats)
	var walls: WallSystem = WallSystem.new(map, buildings, _events, _stats)
	buildings.apply_next_tier(WALL)
	var segments: PackedInt32Array = walls.segments_of(WALL)
	var base: int = walls.max_health_of(segments[0])
	walls.damage_segment(segments[0], base)
	walls.damage_segment(segments[1], 10)
	var intact_before: int = walls.intact_count()
	_percent(&"masons", &"wall.max_health", PLUS_HALF)
	var raised: int = roundi(base * 1.5)
	assert_eq(walls.max_health_of(segments[0]), raised, "a broken segment's maximum is raised too")
	assert_eq(walls.health_of(segments[0]), 0, "but it stays broken")
	assert_false(walls.is_intact(segments[0]), "and a hole")
	assert_eq(walls.health_of(segments[1]), raised - 10, "a hurt segment stays hurt by 10")
	assert_eq(walls.health_of(segments[2]), raised, "an untouched one is full")
	assert_eq(walls.intact_count(), intact_before, "no segment stood up or fell")
	_stats.remove_source(&"masons")
	assert_eq(walls.health_of(segments[1]), base - 10, "removal lowers it again")
	assert_eq(walls.health_of(segments[0]), 0, "the broken one is still broken")


func test_a_king_health_gain_raises_current_health_by_the_gain() -> void:
	var king: KingState = KingState.new(load(KING_PATH), Vector2.ZERO, _events, null, _stats)
	var base: int = king.get_max_health()
	king.take_damage(10)
	_percent(&"royal_training", &"king.max_health", PLUS_HALF)
	var raised: int = roundi(base * 1.5)
	assert_eq(king.get_max_health(), raised, "maximum raised")
	assert_eq(king.get_health(), base - 10 + (raised - base), "current raised by the gain")
	_stats.remove_source(&"royal_training")
	assert_eq(king.get_max_health(), base, "back to the data")
	assert_eq(king.get_health(), base - 10, "and hurt by the same amount")


func test_a_downed_king_is_not_stood_up_by_a_health_source() -> void:
	var king: KingState = KingState.new(load(KING_PATH), Vector2.ZERO, _events, null, _stats)
	king.take_damage(king.get_max_health())
	assert_true(king.is_down(), "he is down")
	_percent(&"royal_training", &"king.max_health", PLUS_HALF)
	assert_true(king.is_down(), "still down")
	assert_eq(king.get_health(), 0, "at zero")
	king.restore_for_dawn()
	assert_eq(king.get_health(), king.get_max_health(), "the dawn restores to the new maximum")


func test_every_living_unit_is_raised_by_a_unit_health_gain() -> void:
	var squads: SquadSystem = SquadSystem.new(_map, _buildings, _events, _stats)
	var enemies: EnemySystem = EnemySystem.new(_events)
	var hits: PendingHits = PendingHits.new()
	_buildings.apply_next_tier(BARRACKS)
	squads.step(0, enemies, hits, false)
	var units: UnitSystem = squads.get_units()
	var ids: Array[int] = units.ids()
	var base: int = units.health_of(ids[0])
	squads.damage_unit(ids[0], 3, &"test")
	_percent(&"commander", &"unit.max_health", PLUS_HALF)
	var gain: int = roundi(base * 1.5) - base
	assert_eq(units.health_of(ids[0]), base - 3 + gain, "the hurt unit gained")
	assert_eq(units.health_of(ids[1]), base + gain, "an unhurt unit is full at the new maximum")
	squads.restore_for_dawn()
	assert_eq(units.health_of(ids[0]), roundi(base * 1.5), "the dawn heal uses the stacked maximum")
	_stats.remove_source(&"commander")
	assert_eq(units.health_of(ids[1]), base, "removal lowers it again")


func test_the_castle_gains_health_with_its_maximum_and_never_beyond_it() -> void:
	var map: MapConfig = MapConfig.new()
	map.castle_max_health = 40
	var castle: CastleState = CastleState.new(map, _events, _stats)
	castle.damage(10)
	_percent(&"fort", &"castle.max_health", PLUS_HALF)
	assert_eq(castle.get_max_health(), 60, "maximum raised")
	assert_eq(castle.get_health(), 30 + 20, "current raised by the gain")
	_stats.remove_source(&"fort")
	assert_eq(castle.get_max_health(), 40, "back to the map")
	assert_eq(castle.get_health(), 30, "hurt by the same amount")
	castle.repair()
	assert_eq(castle.get_health(), 40, "repair fills to the maximum")


func test_a_refresh_announces_no_damage_or_heal_event() -> void:
	_buildings.apply_next_tier(HOUSE)
	var king: KingState = KingState.new(load(KING_PATH), Vector2.ZERO, _events, null, _stats)
	king.take_damage(5)
	watch_signals(_events)
	_percent(&"all", &"building.max_health", PLUS_HALF)
	_percent(&"king", &"king.max_health", PLUS_HALF)
	assert_signal_not_emitted(_events, "building_damaged")
	assert_signal_not_emitted(_events, "king_damaged")
	assert_signal_not_emitted(_events, "king_healed")
