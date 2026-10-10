extends GutTest
## UNIT-10 (D-09): move and attack-move on a hand-built field (BuildingSystem, SquadSystem,
## EnemySystem and PendingHits, no RunContext). A move walks every unit to its slot around a ground
## point, ignoring enemies on the way, and the squad then guards that spot as its post without
## holding. An attack-move does the same but each unit engages what comes within guard_range of its
## own position on the way, finishes the walk after the fight and then guards the spot.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const BARRACKS: StringName = &"barracks_1"
const ONLY_BARRACKS: Array[StringName] = [&"barracks_1"]
const KING := Vector2(4.0, 6.0)
const TARGET := Vector2(20.0, 0.0)
const KILL_DAMAGE: int = 1000
const WALK_STEPS: int = 500
const NIGHT_STEPS_TO_RESCAN: int = 40
const ARRIVED_DISTANCE: float = 0.3

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
	_step(false)


func _units() -> UnitSystem:
	return _squads.get_units()


func _step(night: bool) -> void:
	_squads.step(_tick, _enemies, _hits, night, KING)
	_squads.remove_dead()
	_tick += 1


func _give(verb: StringName, point: Vector2) -> void:
	var points: Array[Vector2] = [point]
	_squads.apply_order(ONLY_BARRACKS, verb, points, false, KING)


func _enemy_at(pos: Vector2) -> int:
	return _enemies.spawn(_map.find_enemy(&"grunt"), pos)


func _targeting(enemy_id: int) -> bool:
	for unit_id: int in _squads.unit_ids_of(BARRACKS):
		if _units().target_of(unit_id) == enemy_id:
			return true
	return false


func _finished() -> bool:
	return _squads.orders_of(BARRACKS).is_empty()


func _all_at_slots(anchor: Vector2, tolerance: float) -> bool:
	var spacing: float = _squads.unit_def_of(BARRACKS).formation_spacing
	for unit_id: int in _squads.unit_ids_of(BARRACKS):
		var slot: Vector2 = (
			anchor
			+ SquadFormation.slot_offset(
				_units().slot_of(unit_id), _squads.max_count(BARRACKS), spacing
			)
		)
		if _units().position_of(unit_id).distance_to(slot) > tolerance:
			return false
	return true


## Steps until the squad's order list is empty; returns the steps taken (WALK_STEPS when it never
## finished).
func _run_to_the_end(night: bool) -> int:
	var steps: int = 0
	while not _finished() and steps < WALK_STEPS:
		_step(night)
		steps += 1
	return steps


func test_a_move_sets_the_anchor_to_the_point_and_rests_in_post() -> void:
	_give(SquadOrder.VERB_MOVE, TARGET)
	assert_eq(_squads.anchor_of(BARRACKS), TARGET, "the formation centres on the point")
	assert_eq(_squads.resting_stance(BARRACKS), SquadOrder.STANCE_POST, "it ends in post, not hold")
	assert_eq(_squads.executing_verb(BARRACKS), &"", "a plain move shows no one-shot verb")
	assert_eq(_squads.orders_of(BARRACKS).size(), 1, "the move is the running order")


func test_a_move_by_day_walks_every_unit_to_its_slot_and_finishes() -> void:
	_give(SquadOrder.VERB_MOVE, TARGET)
	var steps: int = _run_to_the_end(false)
	assert_lt(steps, WALK_STEPS, "the walk ended")
	assert_true(_all_at_slots(TARGET, SquadOrders.ARRIVE_DISTANCE), "units stand at their slots")
	assert_eq(_squads.alive_count(BARRACKS), 4, "nobody was lost")


func test_a_move_ignores_an_enemy_on_the_way_and_then_guards_the_spot() -> void:
	var on_the_way: int = _enemy_at(Vector2(5.0, 0.0))
	_give(SquadOrder.VERB_MOVE, TARGET)
	var steps: int = 0
	while not _finished() and steps < WALK_STEPS:
		_step(true)
		steps += 1
		assert_false(_targeting(on_the_way), "a walking unit takes no target, step %d" % steps)
	assert_lt(steps, WALK_STEPS, "the walk ended")
	assert_eq(_squads.anchor_of(BARRACKS), TARGET, "and the spot is the squad's post now")
	assert_eq(_squads.resting_stance(BARRACKS), SquadOrder.STANCE_POST, "resting in post")
	var near_spot: int = _enemy_at(TARGET + Vector2(0.0, 4.0))
	for _i: int in range(NIGHT_STEPS_TO_RESCAN):
		_step(true)
	assert_true(_targeting(near_spot), "once there the squad guards the spot")
	assert_false(_targeting(on_the_way), "and the enemy left behind is out of its guard range")


func test_an_attack_move_engages_an_enemy_on_the_way_and_finishes_the_walk() -> void:
	var on_the_way: int = _enemy_at(Vector2(0.0, 0.0))
	_give(SquadOrder.VERB_ATTACK_MOVE, TARGET)
	assert_eq(_squads.executing_verb(BARRACKS), SquadOrder.VERB_ATTACK_MOVE, "it is running")
	var engaged: bool = false
	var steps: int = 0
	while not engaged and steps < WALK_STEPS:
		_step(true)
		steps += 1
		engaged = _targeting(on_the_way)
	assert_true(engaged, "a unit took the enemy 20 m from the destination")
	assert_false(_finished(), "the attack-move is still the running order")
	_enemies.damage(on_the_way, KILL_DAMAGE, &"test")
	_enemies.remove_dead()
	steps = _run_to_the_end(true)
	assert_lt(steps, WALK_STEPS, "the walk resumed and ended after the fight")
	assert_eq(_squads.executing_verb(BARRACKS), &"", "nothing is executing once it arrived")
	assert_eq(_squads.anchor_of(BARRACKS), TARGET, "at the point")
	assert_true(_all_at_slots(TARGET, SquadOrders.ARRIVE_DISTANCE), "in formation")


func test_an_attack_move_reports_its_verb_until_arrival() -> void:
	_give(SquadOrder.VERB_ATTACK_MOVE, TARGET)
	for _i: int in range(10):
		_step(false)
		assert_eq(_squads.executing_verb(BARRACKS), SquadOrder.VERB_ATTACK_MOVE, "still walking")
	_run_to_the_end(false)
	assert_eq(_squads.executing_verb(BARRACKS), &"", "empty after arrival")
	assert_eq(_squads.resting_stance(BARRACKS), SquadOrder.STANCE_POST, "and it rests in post")


func test_an_attack_move_guards_the_spot_after_it_arrives() -> void:
	_give(SquadOrder.VERB_ATTACK_MOVE, TARGET)
	_run_to_the_end(true)
	var near_spot: int = _enemy_at(TARGET + Vector2(0.0, 4.0))
	for _i: int in range(NIGHT_STEPS_TO_RESCAN):
		_step(true)
	assert_true(_targeting(near_spot), "the squad guards the point it walked to")


func test_a_fight_does_not_use_up_the_walk_budget() -> void:
	var blocker: int = _enemy_at(Vector2(8.0, 0.0))
	_give(SquadOrder.VERB_ATTACK_MOVE, TARGET)
	for _i: int in range(WALK_STEPS):
		_step(true)
	assert_true(_targeting(blocker), "the squad is still fighting the enemy it cannot kill")
	assert_false(_finished(), "and the attack-move waits for the fight")
	_enemies.damage(blocker, KILL_DAMAGE, &"test")
	_enemies.remove_dead()
	assert_lt(_run_to_the_end(true), WALK_STEPS, "then it finishes the walk")


func test_a_move_after_a_follow_stops_following_the_king() -> void:
	var follow_ids: Array[StringName] = ONLY_BARRACKS
	_squads.apply_order(follow_ids, SquadOrder.VERB_FOLLOW, [] as Array[Vector2], false, KING)
	_step(false)
	_give(SquadOrder.VERB_MOVE, TARGET)
	_squads.step(_tick, _enemies, _hits, false, KING + Vector2(9.0, 9.0))
	assert_eq(_squads.anchor_of(BARRACKS), TARGET, "the king moving away moves nothing")
	assert_eq(_squads.resting_stance(BARRACKS), SquadOrder.STANCE_POST, "post, no longer follow")


func test_a_squad_with_nobody_alive_accepts_a_move_and_replacements_walk_to_the_new_anchor(
) -> void:
	var post: Vector2 = _squads.anchor_of(BARRACKS)
	for unit_id: int in _squads.unit_ids_of(BARRACKS):
		_squads.damage_unit(unit_id, KILL_DAMAGE, &"test")
	_squads.remove_dead()
	assert_eq(_squads.alive_count(BARRACKS), 0, "nobody is left")
	_give(SquadOrder.VERB_MOVE, TARGET)
	assert_eq(_squads.anchor_of(BARRACKS), TARGET, "the order was accepted")
	var steps: int = 0
	while _squads.alive_count(BARRACKS) == 0 and steps < 2000:
		_step(true)
		steps += 1
	assert_gt(_squads.alive_count(BARRACKS), 0, "a replacement arrived")
	for _i: int in range(150):
		_step(true)
	var unit_id: int = _squads.unit_ids_of(BARRACKS)[0]
	assert_lt(
		_units().position_of(unit_id).distance_to(TARGET),
		post.distance_to(TARGET) - 5.0,
		"it walks to the new anchor, not back to the old post"
	)


func test_the_order_survives_the_night_starting_mid_walk() -> void:
	_give(SquadOrder.VERB_MOVE, TARGET)
	for _i: int in range(20):
		_step(false)
	_squads.begin_night()
	assert_eq(_squads.anchor_of(BARRACKS), TARGET, "the anchor is untouched")
	assert_false(_finished(), "and the walk goes on")
	assert_lt(_run_to_the_end(true), WALK_STEPS, "to the end")
