extends GutTest
## KING-03: the king's passive attack on EnemySystem + KingState + PendingHits, with no RunContext.
## The expectations come from king.tres and grunt.tres, except the pinned 0.8 s -> 24 ticks.

const KING_PATH := "res://data/king/king.tres"
const GRUNT_PATH := "res://data/enemies/grunt.tres"

var _def: KingDef
var _grunt: EnemyDef
var _events: SimEvents
var _enemies: EnemySystem
var _hits: PendingHits
var _king: KingState


func before_each() -> void:
	_def = load(KING_PATH)
	_grunt = load(GRUNT_PATH)
	_events = SimEvents.new()
	_enemies = EnemySystem.new(_events)
	_hits = PendingHits.new()
	_king = KingState.new(_def, Vector2.ZERO, _events)
	_king.begin_night()


## One night step in the DR-8 order: the king decides, due hits resolve, the dead are removed.
## Returns true when the king attacked this tick.
func _tick(tick: int) -> bool:
	var before: int = _hits.size()
	_king.step(tick, _enemies, _hits)
	var attacked: bool = _hits.size() > before
	for hit: PendingHits.Hit in _hits.take_due(tick):
		_enemies.damage(hit.target_id, hit.amount, hit.attacker_kind)
	_enemies.remove_dead()
	return attacked


func _tough_grunt() -> EnemyDef:
	var def: EnemyDef = _grunt.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	def.max_health = 100000
	return def


func test_an_enemy_exactly_at_attack_range_is_attacked() -> void:
	var id: int = _enemies.spawn(_grunt, Vector2(_def.attack_range, 0.0))
	assert_true(_tick(0), "the king attacks at exactly attack_range")
	assert_lt(_enemies.health_of(id), _grunt.max_health, "and the hit landed")


func test_an_enemy_just_beyond_attack_range_is_not_attacked() -> void:
	var id: int = _enemies.spawn(_grunt, Vector2(_def.attack_range + 0.01, 0.0))
	assert_false(_tick(0), "no attack 0.01 m beyond the range")
	assert_eq(_enemies.health_of(id), _grunt.max_health, "untouched")


func test_two_equally_near_enemies_the_lower_id_is_attacked() -> void:
	var first: int = _enemies.spawn(_tough_grunt(), Vector2(2.0, 0.0))
	var second: int = _enemies.spawn(_tough_grunt(), Vector2(-2.0, 0.0))
	assert_true(_tick(0), "the king attacks")
	assert_lt(_enemies.health_of(first), 100000, "the lower id took the hit")
	assert_eq(_enemies.health_of(second), 100000, "the higher id did not")


func test_the_nearer_enemy_is_attacked_before_the_lower_id() -> void:
	var far: int = _enemies.spawn(_tough_grunt(), Vector2(2.5, 0.0))
	var near: int = _enemies.spawn(_tough_grunt(), Vector2(1.0, 0.0))
	assert_true(_tick(0), "the king attacks")
	assert_eq(_enemies.health_of(far), 100000, "the farther enemy is spared")
	assert_lt(_enemies.health_of(near), 100000, "the nearer one is hit")


func test_with_nothing_in_range_no_attack_and_no_cooldown_is_consumed() -> void:
	_enemies.spawn(_grunt, Vector2(_def.attack_range + 5.0, 0.0))
	for tick: int in range(0, 50):
		assert_false(_tick(tick), "nothing to hit at tick %d" % tick)
	var id: int = _enemies.spawn(_grunt, Vector2(1.0, 0.0))
	assert_true(_tick(50), "an enemy entering range is hit on that same tick")
	assert_lt(_enemies.health_of(id), _grunt.max_health, "the hit landed")


func test_the_king_attacks_once_per_interval_in_whole_ticks() -> void:
	_enemies.spawn(_tough_grunt(), Vector2(1.0, 0.0))
	var interval: int = SimClock.ticks(_def.attack_interval)
	var attack_ticks: Array[int] = []
	for tick: int in range(0, interval * 3):
		if _tick(tick):
			attack_ticks.append(tick)
	assert_eq(attack_ticks, [0, interval, interval * 2] as Array[int], "one attack per interval")
	assert_eq(SimClock.ticks(0.8), 24, "0.8 s is 24 ticks at 30 Hz")


func test_the_hit_resolves_on_the_tick_it_is_made_and_the_dead_leave_that_tick() -> void:
	var id: int = _enemies.spawn(_grunt, Vector2(1.0, 0.0))
	watch_signals(_events)
	var interval: int = SimClock.ticks(_def.attack_interval)
	var hits_to_kill: int = ceili(float(_grunt.max_health) / float(_def.attack_damage))
	var kill_tick: int = interval * (hits_to_kill - 1)
	for tick: int in range(0, kill_tick):
		_tick(tick)
	assert_true(_enemies.is_alive(id), "still alive the tick before the killing hit")
	_tick(kill_tick)
	assert_eq(_enemies.count(), 0, "removed in the cleanup of the tick that killed it")
	assert_signal_emitted_with_parameters(
		_events, "enemy_died", [id, &"grunt", Vector2(1.0, 0.0), PendingHits.KIND_KING]
	)


func test_the_attack_is_announced_with_the_king_as_attacker() -> void:
	var id: int = _enemies.spawn(_grunt, Vector2(1.0, 0.0))
	watch_signals(_events)
	_tick(0)
	assert_signal_emitted_with_parameters(
		_events, "attack_fired", [PendingHits.KIND_KING, 0, PendingHits.KIND_ENEMY, id, 0]
	)


func test_enemy_ids_grow_and_are_never_reused() -> void:
	var first: int = _enemies.spawn(_grunt, Vector2(100.0, 0.0))
	_enemies.damage(first, _grunt.max_health, PendingHits.KIND_KING)
	_enemies.remove_dead()
	var second: int = _enemies.spawn(_grunt, Vector2(100.0, 0.0))
	assert_gt(second, first, "a later spawn never reuses an id")
	_enemies.clear()
	assert_gt(_enemies.spawn(_grunt, Vector2(100.0, 0.0)), second, "not even after a clear")


func test_a_hit_on_a_gone_enemy_is_dropped_silently() -> void:
	watch_signals(_events)
	_enemies.damage(99, 5, PendingHits.KIND_KING)
	assert_signal_not_emitted(_events, "enemy_damaged")


func test_pending_hits_come_back_in_arrival_then_enqueue_order() -> void:
	_hits.enqueue(5, &"a", 1, PendingHits.KIND_ENEMY, 1, 1)
	_hits.enqueue(3, &"b", 2, PendingHits.KIND_ENEMY, 1, 1)
	_hits.enqueue(3, &"c", 3, PendingHits.KIND_ENEMY, 1, 1)
	_hits.enqueue(9, &"d", 4, PendingHits.KIND_ENEMY, 1, 1)
	var due: Array = _hits.take_due(5)
	var attackers: Array[StringName] = []
	for hit: PendingHits.Hit in due:
		attackers.append(hit.attacker_kind)
	assert_eq(attackers, [&"b", &"c", &"a"] as Array[StringName], "tick 3 first, ties by enqueue")
	assert_eq(_hits.size(), 1, "the later hit stays queued")
