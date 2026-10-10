extends GutTest
## UNIT-10 (D-09): patrol on a hand-built field. A patrol walks a path that starts at the squad's
## centroid at the moment the patrol becomes active and ping-pongs through its points, engaging
## what comes within guard_range of each unit as an attack-move does and resuming the path when the
## enemy is dead. The stance and the path persist through nights and dawns (D-14).

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const BARRACKS: StringName = &"barracks_1"
const ARCHERY: StringName = &"archery_1"
const ONLY_BARRACKS: Array[StringName] = [&"barracks_1"]
const KING := Vector2(4.0, 6.0)
const FIRST := Vector2(0.0, -10.0)
const SECOND := Vector2(8.0, -10.0)
const KILL_DAMAGE: int = 1000
const SETTLE_STEPS: int = 240
const PATROL_STEPS: int = 1500
const NIGHT_STEPS_TO_RESCAN: int = 40

var _map: MapConfig
var _events: SimEvents
var _buildings: BuildingSystem
var _squads: SquadSystem
var _enemies: EnemySystem
var _hits: PendingHits
var _tick: int = 0


func before_each() -> void:
	var shipped: MapConfig = load(FIXTURE)
	_map = shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	_events = SimEvents.new()
	_buildings = BuildingSystem.new(_map, _events)
	_squads = SquadSystem.new(_map, _buildings, _events)
	_enemies = EnemySystem.new(_events)
	_hits = PendingHits.new()
	_tick = 0
	_buildings.apply_next_tier(BARRACKS)
	_buildings.apply_next_tier(ARCHERY)
	_step(false)


func _units() -> UnitSystem:
	return _squads.get_units()


func _step(night: bool) -> void:
	_squads.step(_tick, _enemies, _hits, night, KING)
	_squads.remove_dead()
	_tick += 1


func _steps(count: int, night: bool) -> void:
	for _i: int in range(count):
		_step(night)


func _patrol(points: Array[Vector2]) -> void:
	_squads.apply_order(ONLY_BARRACKS, SquadOrder.VERB_PATROL, points, false, KING)


func _enemy_at(pos: Vector2) -> int:
	return _enemies.spawn(_map.find_enemy(&"grunt"), pos)


func _targeting(enemy_id: int) -> bool:
	for unit_id: int in _squads.unit_ids_of(BARRACKS):
		if _units().target_of(unit_id) == enemy_id:
			return true
	return false


## The anchors the squad centres on, in the order it first reaches each, until `count` are seen.
func _anchor_sequence(count: int, night: bool) -> Array[Vector2]:
	var seen: Array[Vector2] = [_squads.anchor_of(BARRACKS)]
	var steps: int = 0
	while seen.size() < count and steps < PATROL_STEPS:
		_step(night)
		steps += 1
		var anchor: Vector2 = _squads.anchor_of(BARRACKS)
		if anchor != seen.back():
			seen.append(anchor)
	return seen


func test_a_patrol_starts_at_the_centroid_and_ping_pongs_through_its_points() -> void:
	_steps(SETTLE_STEPS, false)
	var centroid: Vector2 = SquadOrders.centroid(
		_units(), _squads.unit_ids_of(BARRACKS), Vector2.ZERO
	)
	_patrol([FIRST, SECOND] as Array[Vector2])
	var path: Array[Vector2] = _squads.patrol_path_of(BARRACKS)
	assert_eq(path.size(), 3, "the centroid plus the two points")
	assert_eq(path[0], centroid, "the path starts at the centroid at the apply tick")
	assert_eq(path[1], FIRST, "then the first point")
	assert_eq(path[2], SECOND, "then the second")
	var seen: Array[Vector2] = _anchor_sequence(6, false)
	assert_eq(
		seen,
		[centroid, FIRST, SECOND, FIRST, centroid, FIRST] as Array[Vector2],
		"start, p1, p2, p1, start, p1"
	)


func test_a_one_point_patrol_goes_back_and_forth() -> void:
	_steps(SETTLE_STEPS, false)
	_patrol([FIRST] as Array[Vector2])
	var path: Array[Vector2] = _squads.patrol_path_of(BARRACKS)
	assert_eq(path.size(), 2, "the centroid and the point")
	var seen: Array[Vector2] = _anchor_sequence(4, false)
	assert_eq(seen, [path[0], FIRST, path[0], FIRST] as Array[Vector2], "to and fro")


func test_the_resting_stance_is_patrol_and_the_path_is_reported() -> void:
	_patrol([FIRST, SECOND] as Array[Vector2])
	assert_eq(_squads.resting_stance(BARRACKS), SquadOrder.STANCE_PATROL, "resting patrol")
	assert_eq(_squads.executing_verb(BARRACKS), &"", "patrol is a stance, not a one-shot verb")
	assert_true(
		_squads.orders_of(BARRACKS).is_empty(), "a patrol acts at once and leaves the queue"
	)
	assert_eq(_squads.patrol_path_of(ARCHERY).size(), 0, "another squad has no path")
	assert_eq(_squads.patrol_path_of(&"ghost").size(), 0, "nor an unknown one")


func test_the_returned_path_is_a_copy() -> void:
	_patrol([FIRST] as Array[Vector2])
	var path: Array[Vector2] = _squads.patrol_path_of(BARRACKS)
	path.clear()
	assert_eq(_squads.patrol_path_of(BARRACKS).size(), 2, "clearing the copy changed nothing")


func test_a_patrol_engages_what_comes_close_and_resumes_when_it_is_dead() -> void:
	_steps(SETTLE_STEPS, false)
	_patrol([FIRST, SECOND] as Array[Vector2])
	var near_path: int = _enemy_at(FIRST + Vector2(0.0, -2.0))
	var steps: int = 0
	while not _targeting(near_path) and steps < PATROL_STEPS:
		_step(true)
		steps += 1
	assert_true(_targeting(near_path), "a unit took the enemy beside the path")
	var held_at: Vector2 = _squads.anchor_of(BARRACKS)
	_steps(NIGHT_STEPS_TO_RESCAN, true)
	assert_true(_targeting(near_path), "it keeps the target while the enemy lives")
	_enemies.damage(near_path, KILL_DAMAGE, &"test")
	_enemies.remove_dead()
	var seen: Array[Vector2] = _anchor_sequence(3, true)
	assert_true(seen.has(SECOND), "the patrol went on to the second point")
	assert_ne(held_at, SECOND, "it had not got there before the fight")


func test_the_stance_and_the_path_survive_the_night_and_the_dawn() -> void:
	_patrol([FIRST, SECOND] as Array[Vector2])
	var path: Array[Vector2] = _squads.patrol_path_of(BARRACKS)
	_squads.begin_night()
	_steps(30, true)
	_squads.restore_for_dawn()
	_steps(30, false)
	assert_eq(_squads.resting_stance(BARRACKS), SquadOrder.STANCE_PATROL, "still patrolling")
	assert_eq(_squads.patrol_path_of(BARRACKS), path, "on the same path")
	var seen: Array[Vector2] = _anchor_sequence(3, false)
	assert_gte(seen.size(), 2, "and still walking it")


func test_a_move_after_a_patrol_ends_the_patrol() -> void:
	_patrol([FIRST, SECOND] as Array[Vector2])
	var points: Array[Vector2] = [Vector2(20.0, 0.0)]
	_squads.apply_order(ONLY_BARRACKS, SquadOrder.VERB_MOVE, points, false, KING)
	assert_eq(_squads.patrol_path_of(BARRACKS).size(), 0, "no path any more")
	assert_eq(_squads.resting_stance(BARRACKS), SquadOrder.STANCE_POST, "post")
	assert_eq(_squads.anchor_of(BARRACKS), Vector2(20.0, 0.0), "at the new point")


func test_a_queued_patrol_starts_its_path_at_the_centroid_when_it_becomes_active() -> void:
	var first_leg: Array[Vector2] = [Vector2(-5.0, 6.0)]
	_squads.apply_order(ONLY_BARRACKS, SquadOrder.VERB_MOVE, first_leg, false, KING)
	_squads.apply_order(
		ONLY_BARRACKS, SquadOrder.VERB_PATROL, [FIRST] as Array[Vector2], true, KING
	)
	assert_eq(_squads.patrol_path_of(BARRACKS).size(), 0, "not patrolling while the move runs")
	var steps: int = 0
	while _squads.patrol_path_of(BARRACKS).is_empty() and steps < PATROL_STEPS:
		_step(false)
		steps += 1
	var path: Array[Vector2] = _squads.patrol_path_of(BARRACKS)
	assert_eq(path.size(), 2, "the patrol began after the move")
	assert_lt(path[0].distance_to(first_leg[0]), 2.0, "its start is where the squad stood then")


func test_a_patrol_with_nobody_alive_waits_at_its_start() -> void:
	for unit_id: int in _squads.unit_ids_of(BARRACKS):
		_squads.damage_unit(unit_id, KILL_DAMAGE, &"test")
	_squads.remove_dead()
	_patrol([FIRST] as Array[Vector2])
	var start: Vector2 = _squads.patrol_path_of(BARRACKS)[0]
	_steps(30, false)
	assert_eq(_squads.anchor_of(BARRACKS), start, "no leg is walked with nobody to walk it")
