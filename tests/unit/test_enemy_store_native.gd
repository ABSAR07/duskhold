extends GutTest
## PLAT-01 (plan 04-19): the facade contract of EnemySystem that the native enemy store must keep.
## No rule is tested here (the traces and the goldens pin the rules); this pins the 18-method API:
## ids that only grow, the answers for an unknown id, damage and removal with their events, the
## read view's version, a def number changed between two steps and the living_within superset.

const GRUNT_PATH := "res://data/enemies/grunt.tres"
const FAR: Vector2 = Vector2(60.0, 0.0)

var _grunt: EnemyDef
var _events: SimEvents
var _castle: CastleState
var _enemies: EnemySystem
var _hits: PendingHits
var _spawned: Array = []
var _damaged: Array = []
var _died: Array = []


func before_each() -> void:
	_grunt = load(GRUNT_PATH)
	_events = SimEvents.new()
	_castle = CastleState.new(MapConfig.new(), _events)
	_enemies = EnemySystem.new(_events)
	_hits = PendingHits.new()
	_spawned = []
	_damaged = []
	_died = []
	_events.enemy_spawned.connect(_on_spawned)
	_events.enemy_damaged.connect(_on_damaged)
	_events.enemy_died.connect(_on_died)


func _on_spawned(enemy_id: int, def_id: StringName, pos: Vector2) -> void:
	_spawned.append([enemy_id, def_id, pos])


func _on_damaged(enemy_id: int, amount: int, hp: int) -> void:
	_damaged.append([enemy_id, amount, hp])


func _on_died(enemy_id: int, def_id: StringName, pos: Vector2, killer: StringName) -> void:
	_died.append([enemy_id, def_id, pos, killer])


func test_ids_start_at_one_and_only_grow_across_clear() -> void:
	var first: int = _enemies.spawn(_grunt, FAR)
	var second: int = _enemies.spawn(_grunt, FAR + Vector2(2.0, 0.0))
	assert_eq(first, 1, "the first id is 1")
	assert_eq(second, 2, "ids count up")
	_enemies.clear()
	assert_eq(_enemies.count(), 0, "clear empties the field")
	assert_eq(_enemies.ids().size(), 0, "no ids after clear")
	assert_eq(_enemies.died_count(), 0, "clear resets the died count")
	assert_eq(_enemies.spawn(_grunt, FAR), 3, "an id is never reused")
	assert_eq(_enemies.ids(), [3] as Array[int], "only the new enemy is listed")


func test_spawn_reports_the_event_and_the_def_numbers() -> void:
	var id: int = _enemies.spawn(_grunt, FAR)
	assert_eq(_spawned, [[id, &"grunt", FAR]], "one enemy_spawned with the def id and position")
	assert_eq(_enemies.count(), 1, "counted")
	assert_true(_enemies.is_alive(id), "alive at spawn")
	assert_eq(_enemies.health_of(id), _grunt.max_health, "full health")
	assert_eq(_enemies.def_of(id), _grunt, "the def it was spawned with")
	assert_eq(_enemies.position_of(id), FAR, "where it was spawned")
	assert_eq(_enemies.previous_position_of(id), FAR, "previous starts at the spawn point")
	assert_eq(_enemies.target_of(id), {}, "no target yet")


func test_an_unknown_id_gives_the_defaults() -> void:
	for bad: int in [0, -1, 7, 1 << 40]:
		assert_false(_enemies.is_alive(bad), "not alive %d" % bad)
		assert_eq(_enemies.position_of(bad), Vector2.ZERO, "zero position %d" % bad)
		assert_eq(_enemies.previous_position_of(bad), Vector2.ZERO, "zero previous %d" % bad)
		assert_eq(_enemies.health_of(bad), 0, "zero health %d" % bad)
		assert_eq(_enemies.target_of(bad), {}, "empty target %d" % bad)
		assert_null(_enemies.def_of(bad), "null def %d" % bad)


func test_damage_removes_hit_points_and_emits_enemy_damaged() -> void:
	var id: int = _enemies.spawn(_grunt, FAR)
	_enemies.damage(id, 2, &"tower")
	assert_eq(_enemies.health_of(id), _grunt.max_health - 2, "two points gone")
	assert_eq(_damaged, [[id, 2, _grunt.max_health - 2]], "one enemy_damaged with the points left")
	assert_true(_enemies.is_alive(id), "still alive")


func test_damage_on_unknown_dead_or_non_positive_is_ignored() -> void:
	var id: int = _enemies.spawn(_grunt, FAR)
	_enemies.damage(99, 3, &"tower")
	_enemies.damage(id, 0, &"tower")
	_enemies.damage(id, -4, &"tower")
	assert_eq(_damaged.size(), 0, "nothing emitted for unknown id, zero or negative amount")
	assert_eq(_enemies.health_of(id), _grunt.max_health, "health untouched")
	_enemies.damage(id, 100000, &"tower")
	assert_eq(_enemies.health_of(id), 0, "a lethal hit stops at 0")
	assert_false(_enemies.is_alive(id), "dead")
	assert_eq(_damaged.size(), 1, "the lethal hit emitted once")
	_enemies.damage(id, 5, &"king")
	assert_eq(_damaged.size(), 1, "a hit on a dead enemy emits nothing")
	assert_eq(_enemies.health_of(id), 0, "and changes nothing")


func test_a_lethal_hit_remembers_its_killer_kind() -> void:
	var id: int = _enemies.spawn(_grunt, FAR)
	_enemies.damage(id, 100000, &"tower")
	_enemies.damage(id, 100000, &"king")
	_enemies.remove_dead()
	assert_eq(_died.size(), 1, "one enemy_died")
	assert_eq(_died[0][3], &"tower", "the killer is the attacker of the lethal hit")


func test_remove_dead_removes_in_ascending_id_with_one_event_each() -> void:
	var ids: Array[int] = []
	for index: int in range(5):
		ids.append(_enemies.spawn(_grunt, FAR + Vector2(float(index) * 3.0, 1.0)))
	_enemies.damage(ids[3], 100000, &"unit")
	_enemies.damage(ids[1], 100000, &"king")
	var first_position: Vector2 = _enemies.position_of(ids[1])
	_enemies.remove_dead()
	assert_eq(_died.size(), 2, "one event per dead enemy")
	assert_eq(_died[0][0], ids[1], "the lower id first")
	assert_eq(_died[1][0], ids[3], "then the higher")
	assert_eq(_died[0][1], &"grunt", "the def id")
	assert_eq(_died[0][2], first_position, "the position")
	assert_eq(_died[0][3], &"king", "the killer of the first")
	assert_eq(_died[1][3], &"unit", "the killer of the second")
	assert_eq(_enemies.died_count(), 2, "counted")
	assert_eq(_enemies.ids(), [ids[0], ids[2], ids[4]] as Array[int], "the others stay, ascending")
	assert_eq(_enemies.count(), 3, "three left")
	assert_eq(_enemies.health_of(ids[1]), 0, "a removed id reads as unknown")
	assert_null(_enemies.def_of(ids[1]), "and has no def")


func test_ids_returns_a_copy() -> void:
	_enemies.spawn(_grunt, FAR)
	var listed: Array[int] = _enemies.ids()
	listed.append(77)
	assert_eq(_enemies.ids().size(), 1, "changing the copy changes nothing")


func test_a_step_moves_toward_the_castle_and_remembers_where_it_was() -> void:
	var id: int = _enemies.spawn(_grunt, FAR)
	_enemies.step(1, _castle, null, _hits)
	assert_eq(_enemies.previous_position_of(id), FAR, "previous is where it stood before the step")
	assert_lt(_enemies.position_of(id).x, FAR.x, "it walked toward the castle at the origin")
	var after_first: Vector2 = _enemies.position_of(id)
	_enemies.step(2, _castle, null, _hits)
	assert_eq(_enemies.previous_position_of(id), after_first, "previous follows each step")


func test_read_view_keeps_its_version_until_something_changes() -> void:
	_enemies.spawn(_grunt, FAR)
	var view: CrowdReadView = _enemies.read_view()
	var version: int = view.version
	assert_same(_enemies.read_view(), view, "the same object every time")
	assert_eq(_enemies.read_view().version, version, "nothing changed, same version")
	_enemies.step(1, _castle, null, _hits)
	var after: CrowdReadView = _enemies.read_view()
	assert_ne(after.version, version, "a step changes the version")
	assert_eq(after.current[0], _enemies.position_of(1), "and refills the arrays")
	assert_eq(after.previous[0], FAR, "with the previous position")
	assert_eq(after.ids[0], 1, "and the ids")


func test_a_def_number_changed_between_two_steps_is_used_by_the_second() -> void:
	var def: EnemyDef = _grunt.duplicate() as EnemyDef
	def.move_speed = 3.0
	var id: int = _enemies.spawn(def, FAR)
	_enemies.step(1, _castle, null, _hits)
	var first_step: float = FAR.x - _enemies.position_of(id).x
	assert_almost_eq(first_step, 3.0 * SimClock.STEP, 0.001, "the first step at 3 m/s")
	def.move_speed = 6.0
	var before: Vector2 = _enemies.position_of(id)
	_enemies.step(2, _castle, null, _hits)
	var second_step: float = before.x - _enemies.position_of(id).x
	assert_almost_eq(second_step, 6.0 * SimClock.STEP, 0.001, "the second step at 6 m/s")


func test_living_within_lists_every_living_enemy_in_reach_ascending() -> void:
	var ids: Array[int] = []
	for index: int in range(12):
		var pos: Vector2 = Vector2(20.0 + float(index) * 2.5, float(index % 3) * 4.0 - 3.0)
		ids.append(_enemies.spawn(_grunt, pos))
	_enemies.damage(ids[4], 100000, &"tower")
	var centre: Vector2 = Vector2(30.0, 0.0)
	var reach: float = 6.0
	var found: PackedInt64Array = _enemies.living_within(centre, reach)
	for index: int in range(1, found.size()):
		assert_gt(found[index], found[index - 1], "ascending")
	for id: int in ids:
		if _enemies.is_alive(id) and _enemies.position_of(id).distance_to(centre) <= reach:
			assert_true(id in found, "living enemy %d within reach is listed" % id)
	# A dead enemy that is not removed yet "may be listed" (EnemySystem.living_within), so the test
	# only holds the living ones to the contract.
	assert_false(_enemies.is_alive(ids[4]), "the enemy killed above is dead")
	var empty: PackedInt64Array = _enemies.living_within(Vector2(-500.0, 500.0), 1.0)
	for index: int in range(1, empty.size()):
		assert_gt(
			empty[index], empty[index - 1], "ascending when the block is wider than the field"
		)


func test_living_within_follows_the_field_after_a_step() -> void:
	var id: int = _enemies.spawn(_grunt, Vector2(40.0, 0.0))
	assert_true(id in _enemies.living_within(Vector2(40.0, 0.0), 1.0), "found where it spawned")
	for tick: int in range(1, 200):
		_enemies.step(tick, _castle, null, _hits)
	var now: Vector2 = _enemies.position_of(id)
	assert_ne(now, Vector2(40.0, 0.0), "it walked")
	assert_true(id in _enemies.living_within(now, 1.0), "found where it stands now")


func test_a_destroyed_castle_leaves_the_field_standing_still() -> void:
	var id: int = _enemies.spawn(_grunt, FAR)
	_castle.damage(1 << 30)
	assert_true(_castle.is_destroyed(), "the castle fell")
	_enemies.step(1, _castle, null, _hits)
	assert_eq(_enemies.position_of(id), FAR, "nobody moves")
	assert_eq(_enemies.previous_position_of(id), FAR, "previous still copied")
	assert_eq(_hits.size(), 0, "no hit queued")
