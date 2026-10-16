extends GutTest
## PLAT-01: EnemySystem.read_view() hands the enemy batches packed arrays instead of three id calls
## per enemy (RESEARCH F3). It must agree with the id API, change its version only when the field
## changes, and read without emitting a SimEvents signal.

const GRUNT_PATH := "res://data/enemies/grunt.tres"
const SPAWN_COUNT: int = 12

var _grunt: EnemyDef
var _events: SimEvents
var _castle: CastleState
var _enemies: EnemySystem
var _hits: PendingHits


func before_each() -> void:
	_grunt = load(GRUNT_PATH)
	_events = SimEvents.new()
	_castle = CastleState.new(MapConfig.new(), _events)
	_enemies = EnemySystem.new(_events)
	_hits = PendingHits.new()


func _spawn_field() -> void:
	for index: int in range(SPAWN_COUNT):
		_enemies.spawn(_grunt, Vector2(30.0 + float(index) * 1.5, -10.0 + float(index % 4)))


func _step(tick: int) -> void:
	_enemies.step(tick, _castle, null, _hits)


func _assert_matches_the_id_api() -> void:
	var view: CrowdReadView = _enemies.read_view()
	var ids: Array[int] = _enemies.ids()
	assert_eq(view.ids.size(), ids.size(), "one slot per enemy")
	assert_eq(view.previous.size(), ids.size(), "a previous position per enemy")
	assert_eq(view.current.size(), ids.size(), "a current position per enemy")
	for index: int in range(mini(ids.size(), view.ids.size())):
		assert_eq(view.ids[index], ids[index], "ascending ids, slot %d" % index)
		assert_eq(view.previous[index], _enemies.previous_position_of(ids[index]), "previous")
		assert_eq(view.current[index], _enemies.position_of(ids[index]), "current")


func test_an_empty_field_reads_empty_arrays() -> void:
	var view: CrowdReadView = _enemies.read_view()
	assert_eq(view.ids.size(), 0, "no ids")
	assert_eq(view.previous.size(), 0, "no previous positions")
	assert_eq(view.current.size(), 0, "no current positions")


func test_the_view_agrees_with_the_id_api_after_spawning() -> void:
	_spawn_field()
	_assert_matches_the_id_api()


func test_the_view_agrees_with_the_id_api_after_steps_moved_the_field() -> void:
	_spawn_field()
	for tick: int in range(1, 6):
		_step(tick)
	_assert_matches_the_id_api()
	var view: CrowdReadView = _enemies.read_view()
	assert_ne(view.previous[0], view.current[0], "the first enemy really moved")


func test_a_second_read_with_no_change_returns_the_same_version() -> void:
	_spawn_field()
	var first: int = _enemies.read_view().version
	var second: int = _enemies.read_view().version
	assert_eq(second, first, "nothing changed, nothing rebuilt")


func test_spawn_step_remove_dead_and_clear_each_bump_the_version() -> void:
	var seen: int = _enemies.read_view().version
	_enemies.spawn(_grunt, Vector2(40.0, 0.0))
	var after_spawn: int = _enemies.read_view().version
	assert_ne(after_spawn, seen, "spawn bumps it")
	_step(1)
	var after_step: int = _enemies.read_view().version
	assert_ne(after_step, after_spawn, "a step bumps it")
	_enemies.damage(_enemies.ids()[0], 100000, &"tower")
	_enemies.remove_dead()
	var after_removal: int = _enemies.read_view().version
	assert_ne(after_removal, after_step, "remove_dead bumps it")
	_enemies.clear()
	var after_clear: int = _enemies.read_view().version
	assert_ne(after_clear, after_removal, "clear bumps it")
	assert_eq(_enemies.read_view().ids.size(), 0, "and the view is empty")


func test_a_dead_enemy_stays_in_the_view_until_it_is_removed() -> void:
	_spawn_field()
	var victim: int = _enemies.ids()[3]
	_enemies.damage(victim, 100000, &"tower")
	assert_true(victim in _enemies.read_view().ids, "ids() still lists it, so the view does")
	_enemies.remove_dead()
	assert_false(victim in _enemies.read_view().ids, "removal takes it out")
	_assert_matches_the_id_api()


func test_reading_the_view_emits_no_signal() -> void:
	_spawn_field()
	_step(1)
	watch_signals(_events)
	_enemies.read_view()
	_enemies.read_view()
	for signal_name: String in SimSignals.ALL:
		assert_signal_not_emitted(_events, signal_name, "%s stays quiet" % signal_name)
