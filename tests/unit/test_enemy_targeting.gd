extends GutTest
## D-11 targeting and the castle fight, on a hand-built night (EnemySystem, CastleState and
## PendingHits, no RunContext). Numbers come from grunt.tres; the castle is the MapConfig default
## (radius 3.5) at the origin.

const GRUNT_PATH := "res://data/enemies/grunt.tres"
const KING_PATH := "res://data/king/king.tres"
## Where the king stands when he is nowhere near any test enemy.
const KING_FAR := Vector2(500.0, 500.0)
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
## Slack for "standing at the stop distance": float32 positions land a hair off the exact value.
const EDGE_EPSILON: float = 0.02

var _grunt: EnemyDef
var _map: MapConfig
var _events: SimEvents
var _castle: CastleState
var _king: KingState
var _king_def: KingDef
var _king_hit_ticks: Array[int] = []
var _enemies: EnemySystem
var _hits: PendingHits
var _tick_now: int = 0
var _castle_hit_ticks: Array[int] = []
var _castle_hp_after: Array[int] = []


func before_each() -> void:
	_grunt = load(GRUNT_PATH)
	_map = MapConfig.new()
	_build()


func _build() -> void:
	_events = SimEvents.new()
	_castle = CastleState.new(_map, _events)
	_king_def = load(KING_PATH)
	_king = KingState.new(_king_def, KING_FAR, _events, load(TUNING_PATH))
	_king.report_position(KING_FAR)
	_enemies = EnemySystem.new(_events)
	_hits = PendingHits.new()
	_castle_hit_ticks = []
	_castle_hp_after = []
	_king_hit_ticks = []
	_events.king_damaged.connect(_on_king_damaged)
	_events.castle_damaged.connect(_on_castle_damaged)


func _on_castle_damaged(_amount: int, hp: int, _max_hp: int) -> void:
	_castle_hit_ticks.append(_tick_now)
	_castle_hp_after.append(hp)


func _on_king_damaged(_amount: int, _hp: int, _max_hp: int) -> void:
	_king_hit_ticks.append(_tick_now)


## One night step in the DR-8 order: enemies decide and move, due hits resolve, the dead leave.
func _tick(tick: int) -> void:
	_tick_now = tick
	_enemies.step(tick, _castle, _king, _hits)
	for hit: PendingHits.Hit in _hits.take_due(tick):
		if hit.target_kind == PendingHits.KIND_CASTLE:
			_castle.damage(hit.amount)
		elif hit.target_kind == PendingHits.KIND_KING:
			_king.take_damage(hit.amount)
	_enemies.remove_dead()


func _stop_distance() -> float:
	return _map.castle_radius + _grunt.attack_range


func test_a_grunt_at_the_castle_edge_strikes_once_per_interval() -> void:
	_enemies.spawn(_grunt, Vector2(_stop_distance(), 0.0))
	var interval: int = SimClock.ticks(_grunt.attack_interval)
	for tick: int in range(0, interval * 3):
		_tick(tick)
	assert_eq(
		_castle_hit_ticks, [0, interval, interval * 2] as Array[int], "one strike per interval"
	)
	var expected: Array[int] = []
	for strike: int in range(1, 4):
		expected.append(_map.castle_max_health - _grunt.attack_damage * strike)
	assert_eq(_castle_hp_after, expected, "each strike takes attack_damage")


func test_a_marching_grunt_strikes_once_it_has_reached_the_edge() -> void:
	var start: float = _stop_distance() + 4.3
	_enemies.spawn(_grunt, Vector2(start, 0.0))
	var ticks_to_walk: int = ceili(4.3 / (_grunt.move_speed * SimClock.STEP))
	for tick: int in range(0, ticks_to_walk + 3):
		_tick(tick)
	assert_false(_castle_hit_ticks.is_empty(), "the grunt struck")
	assert_between(
		_castle_hit_ticks[0], ticks_to_walk - 2, ticks_to_walk + 1, "first strike on arrival"
	)
	assert_almost_eq(
		_enemies.position_of(1).length(), _stop_distance(), EDGE_EPSILON, "at the edge"
	)


func test_the_castle_hp_clamps_at_zero_and_is_destroyed_exactly_once() -> void:
	_map.castle_max_health = 3
	_build()
	for index: int in range(3):
		_enemies.spawn(_grunt, Vector2(_stop_distance(), float(index) * 0.01))
	watch_signals(_events)
	_tick(0)
	assert_eq(_castle.get_health(), 0, "hp stops at 0, never negative")
	assert_true(_castle.is_destroyed(), "destroyed")
	assert_signal_emit_count(_events, "castle_destroyed", 1)
	assert_signal_emit_count(_events, "castle_damaged", 2, "the third hit landed on a dead castle")
	for tick: int in range(1, 90):
		_tick(tick)
	assert_signal_emit_count(_events, "castle_destroyed", 1, "still once after more strikes")
	assert_signal_emit_count(_events, "castle_damaged", 2, "no more damage events")


func test_a_destroyed_castle_is_no_target_and_enemies_stand_still() -> void:
	_map.castle_max_health = 2
	_build()
	_enemies.spawn(_grunt, Vector2(_stop_distance(), 0.0))
	_tick(0)
	assert_true(_castle.is_destroyed(), "one strike destroys it")
	var late: int = _enemies.spawn(_grunt, Vector2(20.0, 0.0))
	var before: Vector2 = _enemies.position_of(late)
	for tick: int in range(1, 30):
		_tick(tick)
	assert_eq(_enemies.position_of(late), before, "an enemy with nothing to attack stands still")
	assert_eq(_enemies.target_of(late), {}, "and has no target")


func test_the_castle_is_targeted_inside_aggro_range_only() -> void:
	var reach: float = _grunt.aggro_range + _map.castle_radius
	var near: int = _enemies.spawn(_grunt, Vector2(reach - 0.1, 0.0))
	var far: int = _enemies.spawn(_grunt, Vector2(reach + 0.1, 20.0))
	_tick(0)
	assert_eq(
		_enemies.target_of(near), {"kind": PendingHits.KIND_CASTLE, "id": 0}, "inside aggro range"
	)
	assert_eq(_enemies.target_of(far), {}, "outside it the enemy keeps marching")


func test_target_of_returns_a_fresh_dictionary_each_call() -> void:
	var id: int = _enemies.spawn(_grunt, Vector2(_stop_distance(), 0.0))
	_tick(0)
	var first: Dictionary = _enemies.target_of(id)
	first["kind"] = &"tampered"
	assert_eq(_enemies.target_of(id)["kind"], PendingHits.KIND_CASTLE, "callers cannot change it")


func test_two_enemies_rescan_on_different_ticks() -> void:
	var rescan_ticks: int = SimClock.ticks(_grunt.retarget_interval_seconds)
	assert_eq(rescan_ticks, 15, "0.5 s is 15 ticks at 30 Hz")
	var ticks_one: Array[int] = []
	var ticks_two: Array[int] = []
	for tick: int in range(0, rescan_ticks * 4):
		if EnemySystem.is_rescan_tick(tick, 1, rescan_ticks):
			ticks_one.append(tick)
		if EnemySystem.is_rescan_tick(tick, 2, rescan_ticks):
			ticks_two.append(tick)
	assert_eq(ticks_one.size(), 4, "id 1 rescans once per interval")
	assert_eq(ticks_two.size(), 4, "id 2 rescans once per interval")
	for tick: int in ticks_one:
		assert_false(ticks_two.has(tick), "tick %d is not shared" % tick)
	assert_true(EnemySystem.is_rescan_tick(14, 1, rescan_ticks), "(tick + id) % ticks == 0")


func test_ten_grunts_on_one_point_spread_out_while_marching() -> void:
	var positions: Array[Vector2] = _march_a_crowd()
	for first: int in range(positions.size()):
		for second: int in range(first + 1, positions.size()):
			var apart: float = positions[first].distance_to(positions[second])
			assert_gte(apart, _grunt.radius * 2.0 * 0.9, "grunts %d and %d" % [first, second])


func test_the_same_crowd_gives_the_same_positions_on_two_runs() -> void:
	assert_eq(_march_a_crowd(), _march_a_crowd(), "separation has no hidden state or randomness")


## Ten grunts spawned on one point 30 m out, marched for one second. Returns their positions.
func _march_a_crowd() -> Array[Vector2]:
	_build()
	for _index: int in range(10):
		_enemies.spawn(_grunt, Vector2(30.0, 0.0))
	for tick: int in range(0, SimClock.ticks(1.0)):
		_tick(tick)
	var positions: Array[Vector2] = []
	for id: int in _enemies.ids():
		positions.append(_enemies.position_of(id))
	return positions


func test_nearest_enemy_prefers_the_nearer_then_the_lower_id_and_is_inclusive() -> void:
	var far: int = _enemies.spawn(_grunt, Vector2(2.0, 0.0))
	var near: int = _enemies.spawn(_grunt, Vector2(1.0, 0.0))
	assert_eq(TargetQuery.nearest_enemy(_enemies, Vector2.ZERO, 3.0), near, "the nearer one")
	assert_eq(TargetQuery.nearest_enemy(_enemies, Vector2.ZERO, 1.0), near, "exactly at reach")
	assert_eq(TargetQuery.nearest_enemy(_enemies, Vector2.ZERO, 0.99), -1, "just outside")
	var tie_a: int = _enemies.spawn(_grunt, Vector2(0.0, -5.0))
	_enemies.spawn(_grunt, Vector2(0.0, 5.0))
	assert_eq(TargetQuery.nearest_enemy(_enemies, Vector2(0.0, 0.0), 5.0), near, "near still wins")
	_enemies.damage(far, 100, PendingHits.KIND_KING)
	_enemies.damage(near, 100, PendingHits.KIND_KING)
	assert_eq(TargetQuery.nearest_enemy(_enemies, Vector2.ZERO, 5.0), tie_a, "lower id on a tie")


func _king_target() -> Dictionary:
	return {"kind": PendingHits.KIND_KING, "id": 0}


func _castle_target() -> Dictionary:
	return {"kind": PendingHits.KIND_CASTLE, "id": 0}


func test_a_king_inside_aggro_range_pulls_an_enemy_off_the_castle_on_its_rescan_tick() -> void:
	var id: int = _enemies.spawn(_grunt, Vector2(_stop_distance(), 0.0))
	var rescan_ticks: int = SimClock.ticks(_grunt.retarget_interval_seconds)
	_tick(0)
	assert_eq(_enemies.target_of(id), _castle_target(), "the castle while the king is far")
	_king.report_position(Vector2(_stop_distance(), _grunt.aggro_range - 1.0))
	var switched_at: int = -1
	for tick: int in range(1, rescan_ticks * 2):
		_tick(tick)
		if switched_at < 0 and _enemies.target_of(id) == _king_target():
			switched_at = tick
	assert_eq(switched_at, rescan_ticks - id, "it switches on the tick where (tick + id) % N == 0")


func test_two_enemies_switch_to_the_king_on_different_ticks() -> void:
	var first: int = _enemies.spawn(_grunt, Vector2(_stop_distance(), 0.0))
	var second: int = _enemies.spawn(_grunt, Vector2(_stop_distance(), 0.3))
	_tick(0)
	_king.report_position(Vector2(_stop_distance(), 3.0))
	var switched: Dictionary = {}
	for tick: int in range(1, SimClock.ticks(_grunt.retarget_interval_seconds) * 2):
		_tick(tick)
		for id: int in [first, second]:
			if not switched.has(id) and _enemies.target_of(id) == _king_target():
				switched[id] = tick
	assert_eq(switched.size(), 2, "both switched")
	if switched.size() < 2:
		return
	assert_ne(switched[first], switched[second], "staggered by id")


func test_an_enemy_walks_to_the_king_and_strikes_him_on_the_attack_cadence() -> void:
	var id: int = _enemies.spawn(_grunt, Vector2(5.0, 0.0))
	_king.report_position(Vector2(5.0, 4.0))
	var interval: int = SimClock.ticks(_grunt.attack_interval)
	for tick: int in range(0, 120):
		_tick(tick)
	assert_eq(_enemies.target_of(id), _king_target(), "the king is the target")
	assert_gte(_king_hit_ticks.size(), 3, "he was struck repeatedly")
	if _king_hit_ticks.size() < 2:
		return
	assert_eq(_king_hit_ticks[1] - _king_hit_ticks[0], interval, "once per attack_interval")
	var stand_off: float = _king_def.body_radius + _grunt.attack_range
	assert_almost_eq(
		_enemies.position_of(id).distance_to(_king.get_position()), stand_off, EDGE_EPSILON, "edge"
	)
	assert_eq(
		_king.get_health(), _king_def.max_health - _grunt.attack_damage * _king_hit_ticks.size()
	)


func test_an_enemy_keeps_its_king_target_until_he_is_beyond_the_leash() -> void:
	var id: int = _enemies.spawn(_grunt, Vector2(30.0, 0.0))
	_king.report_position(Vector2(30.0, 5.0))
	_tick(0)
	assert_eq(_enemies.target_of(id), _king_target(), "picked up inside aggro range")
	_king.report_position(Vector2(30.0, _grunt.leash_range - 0.5))
	for tick: int in range(1, 40):
		_tick(tick)
	assert_eq(_enemies.target_of(id), _king_target(), "kept between aggro range and the leash")
	_king.report_position(Vector2(30.0, 60.0))
	_tick(40)
	assert_eq(_enemies.target_of(id), {}, "dropped beyond the leash with the castle far away")


func test_a_downed_king_is_dropped_as_a_target_on_the_next_tick() -> void:
	var id: int = _enemies.spawn(_grunt, Vector2(_stop_distance(), 0.0))
	_king.report_position(Vector2(_stop_distance(), 3.0))
	_tick(0)
	assert_eq(_enemies.target_of(id), _king_target(), "chasing the king")
	_king.take_damage(_king_def.max_health)
	assert_true(_king.is_down(), "he is down")
	_tick(1)
	assert_ne(_enemies.target_of(id), _king_target(), "no longer his target")
	assert_eq(_enemies.target_of(id), _castle_target(), "it goes back to the castle")
