extends GutTest
## CR-01: a unit definition with max_health <= 0 (a hand-edited .tres that MapConfig.validate
## reports but RunContext does not refuse) must not hang the squad system. The old fill loops
## waited for a living count a born-dead unit can never reach and allocated without bound; the
## loops now run once per missing seat and the stored health is floored at 1, so the squad fills
## to its cap and the step returns.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const BARRACKS: StringName = &"barracks_1"

var _map: MapConfig
var _events: SimEvents
var _buildings: BuildingSystem
var _squads: SquadSystem
var _enemies: EnemySystem
var _hits: PendingHits
var _spawned: int = 0


func before_each() -> void:
	var shipped: MapConfig = load(FIXTURE)
	_map = shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	_events = SimEvents.new()
	_buildings = BuildingSystem.new(_map, _events)
	_squads = SquadSystem.new(_map, _buildings, _events)
	_enemies = EnemySystem.new(_events)
	_hits = PendingHits.new()
	_spawned = 0
	_events.unit_spawned.connect(_on_unit_spawned)


func _on_unit_spawned(_id: int, _squad: StringName, _def_id: StringName, _pos: Vector2) -> void:
	_spawned += 1


func _set_footman_health(value: int) -> void:
	for unit: UnitDef in _map.units:
		if unit.id == &"footman":
			unit.max_health = value


func _stand_barracks() -> void:
	_buildings.apply_next_tier(BARRACKS)
	_squads.step(0, _enemies, _hits, false)


func test_a_zero_health_unit_fills_the_squad_to_its_cap_and_the_step_returns() -> void:
	_set_footman_health(0)
	_stand_barracks()
	var cap: int = _squads.max_count(BARRACKS)
	assert_gt(cap, 0, "the squad has seats")
	assert_eq(_spawned, cap, "exactly one unit per seat was raised, not an unbounded number")
	assert_eq(_squads.alive_count(BARRACKS), cap, "every seat holds a living unit")


func test_a_negative_health_unit_is_bounded_the_same_way() -> void:
	_set_footman_health(-5)
	_stand_barracks()
	assert_eq(_spawned, _squads.max_count(BARRACKS), "one unit per seat")
	assert_eq(_squads.alive_count(BARRACKS), _squads.max_count(BARRACKS), "all alive")


func test_the_dawn_restore_is_bounded_for_a_zero_health_unit() -> void:
	_set_footman_health(0)
	_stand_barracks()
	var cap: int = _squads.max_count(BARRACKS)
	_squads.damage_unit(_squads.unit_ids_of(BARRACKS)[0], 1000, &"test")
	_squads.remove_dead()
	_spawned = 0
	_squads.restore_for_dawn()
	assert_eq(_spawned, 1, "only the one missing seat is raised")
	assert_eq(_squads.alive_count(BARRACKS), cap, "the squad is whole again")
