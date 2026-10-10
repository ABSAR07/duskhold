extends GutTest
## Enemies target friendly units like they target buildings (RESEARCH Pattern 2), on a hand-built
## field: EnemySystem, UnitSystem, BuildingSystem and PendingHits, no RunContext. A living unit
## whose edge is inside aggro_range is chosen over a building at an equal edge distance, enemy
## hits on a unit resolve through PendingHits.KIND_UNIT, and a unit at 0 hp leaves in the cleanup.
## Everything stands far from the castle at the origin so the castle never interferes. Distances use
## exactly representable floats (a unit radius of 0.5, a house radius of 1.5) so "equal" is equal.

const GRUNT_PATH := "res://data/enemies/grunt.tres"
const FOOTMAN_PATH := "res://data/units/footman.tres"
const HOUSE_PATH := "res://data/buildings/house.tres"
const ENEMY_AT := Vector2(100.0, 100.0)
## Building plot whose edge is 3.0 m from ENEMY_AT (centre 4.5 m, radius 1.5).
const PLOT_AT := Vector3(104.5, 0.0, 100.0)

var _grunt: EnemyDef
var _unit_def: UnitDef
var _events: SimEvents
var _map: MapConfig
var _castle: CastleState
var _buildings: BuildingSystem
var _units: UnitSystem
var _enemies: EnemySystem
var _hits: PendingHits


func before_each() -> void:
	_grunt = load(GRUNT_PATH)
	var shipped: UnitDef = load(FOOTMAN_PATH)
	_unit_def = shipped.duplicate()
	_unit_def.radius = 0.5
	var spot: BuildSpotDef = BuildSpotDef.new()
	spot.id = &"plot"
	spot.position = PLOT_AT
	spot.building_id = &"house"
	_map = MapConfig.new()
	_map.buildings = [load(HOUSE_PATH)]
	_map.spots = [spot]
	_events = SimEvents.new()
	_castle = CastleState.new(_map, _events)
	_buildings = BuildingSystem.new(_map, _events)
	_buildings.apply_next_tier(&"plot")
	_units = UnitSystem.new(_events)
	_enemies = EnemySystem.new(_events)
	_hits = PendingHits.new()


func _step(tick: int, with_units: bool = true) -> void:
	var visible_units: UnitSystem = _units if with_units else null
	_enemies.step(tick, _castle, null, _hits, _buildings, visible_units)
	for hit: PendingHits.Hit in _hits.take_due(tick):
		if hit.target_kind == PendingHits.KIND_UNIT:
			_units.damage(hit.target_id, hit.amount, hit.attacker_kind)
	_enemies.remove_dead()
	_units.remove_dead()


## Where a unit stands so a grunt at ENEMY_AT is already at its stop distance.
func _contact_at() -> Vector2:
	return ENEMY_AT + Vector2(0.0, _grunt.attack_range + _unit_def.radius)


func _spawn_unit(pos: Vector2) -> int:
	return _units.spawn(_unit_def, &"barracks_1", 0, pos)


func test_a_unit_wins_a_tie_with_a_building_at_the_same_edge_distance() -> void:
	var enemy_id: int = _enemies.spawn(_grunt, ENEMY_AT)
	var unit_id: int = _spawn_unit(ENEMY_AT + Vector2(0.0, 3.5))
	_step(0)
	assert_eq(
		_enemies.target_of(enemy_id),
		{"kind": PendingHits.KIND_UNIT, "id": unit_id},
		"the unit is chosen over the building"
	)


func test_a_nearer_building_still_beats_a_farther_unit() -> void:
	var enemy_id: int = _enemies.spawn(_grunt, ENEMY_AT)
	_spawn_unit(ENEMY_AT + Vector2(0.0, 3.6))
	_step(0)
	var target: Dictionary = _enemies.target_of(enemy_id)
	assert_eq(target.get("kind"), PendingHits.KIND_BUILDING, "edge distance decides, not the kind")


func test_a_unit_outside_aggro_range_is_not_chosen() -> void:
	var enemy_id: int = _enemies.spawn(_grunt, ENEMY_AT)
	_spawn_unit(ENEMY_AT + Vector2(0.0, _grunt.aggro_range + 0.5 + 0.5))
	_step(0, true)
	var target: Dictionary = _enemies.target_of(enemy_id)
	assert_ne(target.get("kind"), PendingHits.KIND_UNIT, "6.5 m from the edge is out of aggro")


func test_among_equally_near_units_the_lower_id_is_chosen() -> void:
	var enemy_id: int = _enemies.spawn(_grunt, ENEMY_AT)
	var first: int = _spawn_unit(ENEMY_AT + Vector2(0.0, 3.5))
	_spawn_unit(ENEMY_AT + Vector2(0.0, -3.5))
	_step(0)
	assert_eq(_enemies.target_of(enemy_id).get("id"), first, "ascending id order, strict compare")


func test_called_without_the_units_argument_enemies_ignore_units() -> void:
	var enemy_id: int = _enemies.spawn(_grunt, ENEMY_AT)
	_spawn_unit(ENEMY_AT + Vector2(0.0, 1.5))
	_step(0, false)
	var target: Dictionary = _enemies.target_of(enemy_id)
	assert_ne(target.get("kind"), PendingHits.KIND_UNIT, "Phase 2 behaviour is unchanged")
	assert_eq(_units.health_of(1), _unit_def.max_health, "and nobody hurt the unit")


func test_an_enemy_hit_lowers_the_unit_hp_and_announces_it() -> void:
	var unit_id: int = _spawn_unit(_contact_at())
	_enemies.spawn(_grunt, ENEMY_AT)
	watch_signals(_events)
	_step(0)
	assert_eq(_units.health_of(unit_id), _unit_def.max_health - _grunt.attack_damage, "hit landed")
	assert_signal_emitted_with_parameters(
		_events,
		"unit_damaged",
		[unit_id, _grunt.attack_damage, _unit_def.max_health - _grunt.attack_damage]
	)


func test_a_unit_at_zero_hp_leaves_in_the_cleanup_and_names_its_killer() -> void:
	var unit_id: int = _spawn_unit(_contact_at())
	_enemies.spawn(_grunt, ENEMY_AT)
	watch_signals(_events)
	var interval: int = SimClock.ticks(_grunt.attack_interval)
	var strikes: int = ceili(float(_unit_def.max_health) / float(_grunt.attack_damage))
	for tick: int in range(interval * strikes):
		_step(tick)
	assert_false(_units.is_alive(unit_id), "the unit died")
	assert_eq(_units.count(), 0, "and was removed")
	assert_signal_emitted_with_parameters(
		_events, "unit_died", [unit_id, &"barracks_1", _contact_at(), &"enemy"]
	)
	assert_signal_emit_count(_events, "unit_died", 1, "announced exactly once")


func test_a_hit_for_a_unit_that_is_already_gone_drops_silently() -> void:
	var unit_id: int = _spawn_unit(ENEMY_AT)
	_units.damage(unit_id, _unit_def.max_health, PendingHits.KIND_ENEMY)
	_units.remove_dead()
	watch_signals(_events)
	_units.damage(unit_id, 3, PendingHits.KIND_ENEMY)
	_units.damage(9999, 3, PendingHits.KIND_ENEMY)
	assert_signal_not_emitted(_events, "unit_damaged", "nothing to hurt")
	assert_eq(_units.health_of(unit_id), 0, "an unknown id reads as 0 hp")
