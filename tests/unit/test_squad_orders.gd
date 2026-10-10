extends GutTest
## UNIT-05, UNIT-06, UNIT-10 on a hand-built field (BuildingSystem, SquadSystem, EnemySystem and
## PendingHits, no RunContext): follow keeps the anchor on the king and the squad guards around him;
## hold freezes the anchor at the centroid of the living units (the post when nobody is alive),
## fights inside guard_range of it and goes back to it; rally walks to the king's position at the
## apply tick ignoring enemies and then holds there. The king position is passed in by the caller,
## so these tests decide where he is.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const BARRACKS: StringName = &"barracks_1"
const ARCHERY: StringName = &"archery_1"
const ONLY_BARRACKS: Array[StringName] = [&"barracks_1"]
const BOTH: Array[StringName] = [&"archery_1", &"barracks_1"]
const NO_POINTS: Array[Vector2] = []
const KING := Vector2(4.0, 6.0)
const KILL_DAMAGE: int = 1000
const SETTLE_STEPS: int = 240
const SLOT_EPSILON: float = 0.05
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


func _units() -> UnitSystem:
	return _squads.get_units()


## One squad step; enemies stand still unless a test moves them.
func _step(night: bool, king: Vector2 = KING) -> void:
	_squads.step(_tick, _enemies, _hits, night, king)
	_squads.remove_dead()
	_tick += 1


func _steps(count: int, night: bool, king: Vector2 = KING) -> void:
	for _i: int in range(count):
		_step(night, king)


func _stand(spot: StringName) -> void:
	_buildings.apply_next_tier(spot)
	_step(false)


func _order(
	ids: Array[StringName],
	verb: StringName,
	king: Vector2 = KING,
	points: Array[Vector2] = NO_POINTS
) -> void:
	_squads.apply_order(ids, verb, points, false, king)


func _enemy_at(pos: Vector2) -> int:
	return _enemies.spawn(_map.find_enemy(&"grunt"), pos)


func _targeting(squad: StringName, enemy_id: int) -> bool:
	for unit_id: int in _squads.unit_ids_of(squad):
		if _units().target_of(unit_id) == enemy_id:
			return true
	return false


func _slot_of(squad: StringName, unit_id: int, anchor: Vector2) -> Vector2:
	var spacing: float = _squads.unit_def_of(squad).formation_spacing
	return (
		anchor
		+ SquadFormation.slot_offset(_units().slot_of(unit_id), _squads.max_count(squad), spacing)
	)


func _all_at_slots(squad: StringName, anchor: Vector2, tolerance: float) -> bool:
	for unit_id: int in _squads.unit_ids_of(squad):
		if _units().position_of(unit_id).distance_to(_slot_of(squad, unit_id, anchor)) > tolerance:
			return false
	return true


func _min_pair_distance() -> float:
	var ids: Array[int] = _units().ids()
	var smallest: float = INF
	for first: int in range(ids.size()):
		for second: int in range(first + 1, ids.size()):
			var gap: float = _units().position_of(ids[first]).distance_to(
				_units().position_of(ids[second])
			)
			smallest = minf(smallest, gap)
	return smallest


func test_follow_puts_the_anchor_on_the_king_every_step_by_day_and_at_night() -> void:
	_stand(BARRACKS)
	_order(ONLY_BARRACKS, SquadOrder.VERB_FOLLOW)
	for index: int in range(10):
		var king: Vector2 = KING + Vector2(float(index) * 0.5, 0.0)
		_step(false, king)
		assert_eq(
			_squads.anchor_of(BARRACKS), king, "by day the anchor is the king, step %d" % index
		)
	for index: int in range(10):
		var king: Vector2 = KING - Vector2(0.0, float(index) * 0.5)
		_step(true, king)
		assert_eq(_squads.anchor_of(BARRACKS), king, "at night too, step %d" % index)


func test_follow_reports_the_follow_stance_and_no_executing_verb() -> void:
	_stand(BARRACKS)
	_order(ONLY_BARRACKS, SquadOrder.VERB_FOLLOW)
	assert_eq(_squads.resting_stance(BARRACKS), SquadOrder.STANCE_FOLLOW, "resting follow")
	assert_eq(_squads.executing_verb(BARRACKS), &"", "follow is a stance, not a one-shot verb")


func test_a_following_squad_walks_to_slots_around_the_king() -> void:
	_stand(BARRACKS)
	_order(ONLY_BARRACKS, SquadOrder.VERB_FOLLOW)
	_steps(SETTLE_STEPS, false)
	assert_true(_all_at_slots(BARRACKS, KING, SLOT_EPSILON), "every footman stands at its slot")
	assert_eq(_squads.alive_count(BARRACKS), 4, "nobody was lost on the way")


func test_a_following_squad_fights_what_comes_near_the_king() -> void:
	_stand(BARRACKS)
	_order(ONLY_BARRACKS, SquadOrder.VERB_FOLLOW)
	_steps(SETTLE_STEPS, false)
	var enemy: int = _enemy_at(KING + Vector2(3.0, 0.0))
	_steps(NIGHT_STEPS_TO_RESCAN, true)
	assert_true(_targeting(BARRACKS, enemy), "the guard around the king takes the enemy")


func test_a_following_squad_already_at_its_slots_does_not_move() -> void:
	_stand(BARRACKS)
	_order(ONLY_BARRACKS, SquadOrder.VERB_FOLLOW)
	var ids: Array[int] = _squads.unit_ids_of(BARRACKS)
	var resting: Dictionary = {}
	for unit_id: int in ids:
		resting[unit_id] = _slot_of(BARRACKS, unit_id, KING) + Vector2(0.1, 0.0)
		_units().set_position_of(unit_id, resting[unit_id])
	_steps(30, false)
	for unit_id: int in ids:
		assert_eq(_units().position_of(unit_id), resting[unit_id], "unit %d stood still" % unit_id)


func test_two_squads_following_the_king_are_kept_apart_not_stacked() -> void:
	_stand(BARRACKS)
	_stand(ARCHERY)
	_order(BOTH, SquadOrder.VERB_FOLLOW)
	_steps(SETTLE_STEPS * 2, false)
	assert_eq(_units().count(), 8, "four footmen and four archers")
	assert_gt(_min_pair_distance(), 0.5, "no two units share a point")
	assert_eq(_squads.anchor_of(BARRACKS), _squads.anchor_of(ARCHERY), "both centre on the king")
	for squad: StringName in BOTH:
		assert_true(_all_at_slots(squad, KING, 1.0), "%s kept a formation round the king" % squad)


func test_hold_freezes_the_anchor_at_the_centroid_of_the_living_units() -> void:
	_stand(BARRACKS)
	var ids: Array[int] = _squads.unit_ids_of(BARRACKS)
	var scattered: Array[Vector2] = [
		Vector2(-4.0, 0.0), Vector2(-2.0, 0.0), Vector2(-4.0, 2.0), Vector2(-2.0, 2.0)
	]
	for index: int in range(ids.size()):
		_units().set_position_of(ids[index], scattered[index])
	_order(ONLY_BARRACKS, SquadOrder.VERB_HOLD)
	assert_eq(_squads.anchor_of(BARRACKS), Vector2(-3.0, 1.0), "the centroid at the apply tick")
	assert_eq(_squads.resting_stance(BARRACKS), SquadOrder.STANCE_HOLD, "resting hold")
	assert_eq(_squads.executing_verb(BARRACKS), &"", "hold is a stance, not a one-shot verb")
	_steps(SETTLE_STEPS, false, Vector2(30.0, 30.0))
	assert_eq(_squads.anchor_of(BARRACKS), Vector2(-3.0, 1.0), "the king leaving moves nothing")
	assert_true(_all_at_slots(BARRACKS, Vector2(-3.0, 1.0), SLOT_EPSILON), "units shuffle to slots")


func test_a_held_squad_fights_inside_guard_range_of_the_spot_and_goes_back_to_it() -> void:
	_stand(BARRACKS)
	var ids: Array[int] = _squads.unit_ids_of(BARRACKS)
	var cluster: Array[Vector2] = [
		Vector2(10.0, 10.0), Vector2(12.0, 10.0), Vector2(10.0, 12.0), Vector2(12.0, 12.0)
	]
	for index: int in range(ids.size()):
		_units().set_position_of(ids[index], cluster[index])
	_order(ONLY_BARRACKS, SquadOrder.VERB_HOLD)
	var spot: Vector2 = _squads.anchor_of(BARRACKS)
	var guard: float = _squads.unit_def_of(BARRACKS).guard_range
	var near_enemy: int = _enemy_at(spot + Vector2(guard - 2.0, 0.0))
	var far_enemy: int = _enemy_at(spot + Vector2(0.0, guard + 2.0))
	_steps(NIGHT_STEPS_TO_RESCAN, true)
	assert_true(
		_targeting(BARRACKS, near_enemy), "an enemy inside guard_range of the spot is taken"
	)
	assert_false(_targeting(BARRACKS, far_enemy), "one outside it is left alone")
	_enemies.damage(near_enemy, KILL_DAMAGE, &"test")
	_enemies.remove_dead()
	_steps(SETTLE_STEPS, true)
	assert_eq(_squads.anchor_of(BARRACKS), spot, "the spot never moved")
	assert_true(_all_at_slots(BARRACKS, spot, SLOT_EPSILON), "the squad is back round the spot")
	assert_false(_targeting(BARRACKS, far_enemy), "and still ignores the far enemy")


func test_hold_on_a_squad_with_nobody_alive_anchors_at_the_buildings_post() -> void:
	_stand(BARRACKS)
	var post: Vector2 = _squads.anchor_of(BARRACKS)
	_order(ONLY_BARRACKS, SquadOrder.VERB_FOLLOW)
	_step(false)
	assert_eq(_squads.anchor_of(BARRACKS), KING, "the squad was following")
	for unit_id: int in _squads.unit_ids_of(BARRACKS):
		_squads.damage_unit(unit_id, KILL_DAMAGE, &"test")
	_squads.remove_dead()
	assert_eq(_squads.alive_count(BARRACKS), 0, "nobody is left")
	_order(ONLY_BARRACKS, SquadOrder.VERB_HOLD)
	assert_eq(_squads.anchor_of(BARRACKS), post, "hold falls back to the post")


func test_hold_after_follow_stops_following() -> void:
	_stand(BARRACKS)
	_order(ONLY_BARRACKS, SquadOrder.VERB_FOLLOW)
	_step(false)
	_order(ONLY_BARRACKS, SquadOrder.VERB_HOLD)
	var held: Vector2 = _squads.anchor_of(BARRACKS)
	_step(false, KING + Vector2(9.0, 9.0))
	assert_eq(_squads.anchor_of(BARRACKS), held, "the anchor stays where hold froze it")
	assert_eq(_squads.resting_stance(BARRACKS), SquadOrder.STANCE_HOLD, "resting hold")


func test_rally_walks_to_the_king_ignoring_enemies_and_then_holds_there() -> void:
	_stand(BARRACKS)
	var rally_point := Vector2(5.0, 0.0)
	_order(ONLY_BARRACKS, SquadOrder.VERB_RALLY, rally_point)
	assert_eq(_squads.anchor_of(BARRACKS), rally_point, "the anchor is the king at the apply tick")
	assert_eq(_squads.resting_stance(BARRACKS), SquadOrder.STANCE_HOLD, "it will rest in hold")
	assert_eq(_squads.executing_verb(BARRACKS), &"", "rally shows no one-shot verb")
	var enemy: int = _enemy_at(rally_point + Vector2(0.0, 3.0))
	for index: int in range(20):
		_step(true, Vector2(40.0, 40.0))
		assert_false(_targeting(BARRACKS, enemy), "walking units ignore the enemy, step %d" % index)
	assert_eq(_squads.anchor_of(BARRACKS), rally_point, "the king leaving moves nothing")
	var steps: int = 0
	while not _targeting(BARRACKS, enemy) and steps < SETTLE_STEPS * 2:
		_step(true, Vector2(40.0, 40.0))
		steps += 1
	assert_true(_targeting(BARRACKS, enemy), "once arrived the squad fights near the rally point")
	assert_eq(_squads.anchor_of(BARRACKS), rally_point, "and still holds there")


func test_two_squads_rallied_to_one_point_do_not_ignore_enemies_for_ever() -> void:
	_stand(BARRACKS)
	_stand(ARCHERY)
	var rally_point := Vector2(5.0, 0.0)
	_order(BOTH, SquadOrder.VERB_RALLY, rally_point)
	var enemy: int = _enemy_at(rally_point + Vector2(0.0, 3.0))
	var steps: int = 0
	while not _targeting(BARRACKS, enemy) and steps < SETTLE_STEPS * 4:
		_step(true)
		steps += 1
	assert_true(_targeting(BARRACKS, enemy), "the crowded squad stopped walking and took the enemy")


func test_a_squad_that_is_not_ordered_stays_at_its_post() -> void:
	_stand(BARRACKS)
	_stand(ARCHERY)
	var post: Vector2 = _squads.anchor_of(ARCHERY)
	_order(ONLY_BARRACKS, SquadOrder.VERB_FOLLOW)
	_steps(30, false, Vector2(20.0, 20.0))
	assert_eq(_squads.anchor_of(ARCHERY), post, "the other squad kept its post")
	assert_eq(_squads.resting_stance(ARCHERY), SquadOrder.STANCE_POST, "and its stance")
