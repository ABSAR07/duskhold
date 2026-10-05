extends GutTest
## KING-06 and D-01 to D-06 in the simulation: the king is attacked, knocked out, counts down and
## returns at the castle with full health; the respawn data lives in loop_tuning.tres and a
## knockout costs only time. KingState is exercised directly (hand-built night); the enemy-side
## rules run through a real NightSim; dawn and gold run through a RunContext. The expected seconds
## derive from loop_tuning.tres except the pinned 15 s cap (D-01).

const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
const KING_PATH := "res://data/king/king.tres"
const GRUNT_PATH := "res://data/enemies/grunt.tres"
## D-01: the countdown never exceeds this. Raising it later is a deliberate owner decision.
const CAP_PIN: float = 15.0
const SPAWN := Vector2(0.0, 7.0)
const FAR_AWAY := Vector2(40.0, 40.0)
const SEED := 1

var _tuning: LoopTuning
var _def: KingDef
var _grunt: EnemyDef
var _events: SimEvents
var _enemies: EnemySystem
var _hits: PendingHits
var _king: KingState
var _tick: int = 0


func before_each() -> void:
	_tuning = load(TUNING_PATH)
	_def = load(KING_PATH)
	_grunt = load(GRUNT_PATH)
	_build_king()


func _build_king(max_health: int = 6) -> void:
	_def = _def.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	_def.max_health = max_health
	_events = SimEvents.new()
	_enemies = EnemySystem.new(_events)
	_hits = PendingHits.new()
	_king = KingState.new(_def, SPAWN, _events, _tuning)
	_king.begin_night()
	_tick = 0


## Seconds the nth knockout of a night should last: from the data, never above the pinned cap.
func _expected_seconds(knockout_number: int) -> float:
	var seconds: float = _tuning.respawn_start_seconds
	seconds += _tuning.respawn_step_seconds * float(knockout_number - 1)
	return minf(seconds, CAP_PIN)


func _steps(count: int) -> void:
	for _i: int in range(count):
		_king.step(_tick, _enemies, _hits)
		_tick += 1


func _down_ticks(knockout_number: int) -> int:
	return SimClock.ticks(_expected_seconds(knockout_number))


func test_the_shipped_respawn_seconds_are_6_10_14_then_capped_at_15() -> void:
	var seconds: Array[float] = []
	for number: int in range(1, 6):
		seconds.append(_tuning.respawn_seconds(number))
	assert_eq(seconds, [6.0, 10.0, 14.0, 15.0, 15.0] as Array[float], "D-01 with the shipped data")


func test_respawn_seconds_is_sanitised_so_bad_data_cannot_strand_the_king() -> void:
	var odd: LoopTuning = LoopTuning.new()
	odd.respawn_start_seconds = 20.0
	odd.respawn_step_seconds = 4.0
	odd.respawn_cap_seconds = 15.0
	assert_eq(odd.respawn_seconds(1), 15.0, "a start above the cap is held at the cap")
	odd.respawn_start_seconds = 6.0
	odd.respawn_step_seconds = -4.0
	assert_eq(odd.respawn_seconds(3), 6.0, "a negative step counts as 0")
	odd.respawn_step_seconds = 4.0
	assert_eq(odd.respawn_seconds(0), odd.respawn_seconds(1), "knockout 0 counts as the first")
	assert_eq(odd.respawn_seconds(-7), odd.respawn_seconds(1), "so does a negative number")
	odd.respawn_cap_seconds = -3.0
	odd.respawn_start_seconds = -2.0
	assert_eq(odd.respawn_seconds(1), 0.0, "negative data never makes a negative countdown")
	assert_eq(odd.respawn_seconds(1000000), 0.0, "and a huge number stays within the cap")


func test_a_king_at_one_hp_stays_up_and_a_hit_to_exactly_zero_knocks_him_out() -> void:
	_build_king(3)
	watch_signals(_events)
	_king.take_damage(2)
	assert_eq(_king.get_health(), 1, "one hit point left")
	assert_false(_king.is_down(), "still up")
	assert_signal_emitted_with_parameters(_events, "king_damaged", [2, 1, 3])
	assert_signal_not_emitted(_events, "king_downed")
	_king.take_damage(1)
	assert_eq(_king.get_health(), 0, "exactly zero")
	assert_true(_king.is_down(), "knocked out")
	assert_signal_emit_count(_events, "king_downed", 1)
	assert_signal_emitted_with_parameters(_events, "king_downed", [_down_ticks(1), 1])


func test_overkill_clamps_the_health_at_zero() -> void:
	_build_king(3)
	_king.take_damage(5)
	assert_eq(_king.get_health(), 0, "never negative")
	assert_true(_king.is_down(), "down")
	assert_eq(_king.get_max_health(), 3, "the maximum is untouched")


func test_while_down_the_king_takes_no_damage_and_is_downed_only_once() -> void:
	_build_king(3)
	_king.take_damage(3)
	watch_signals(_events)
	_king.take_damage(2)
	_king.take_damage(1)
	assert_signal_not_emitted(_events, "king_damaged")
	assert_signal_not_emitted(_events, "king_downed")
	assert_eq(_king.get_health(), 0, "still zero")
	assert_eq(_king.knockouts_this_night(), 1, "one knockout, not three")


func test_while_down_he_ignores_position_reports_and_does_not_attack() -> void:
	_build_king(3)
	_enemies.spawn(_grunt, SPAWN)
	_king.take_damage(3)
	_king.report_position(FAR_AWAY)
	assert_eq(_king.get_position(), SPAWN, "a position reported while down is ignored")
	var before: int = _hits.size()
	_steps(5)
	assert_eq(_hits.size(), before, "no attack while down, with an enemy in range")


func test_the_countdown_is_whole_ticks_and_the_king_returns_at_the_castle_with_full_health(
) -> void:
	_build_king(3)
	_king.report_position(FAR_AWAY)
	_king.take_damage(3)
	watch_signals(_events)
	var down: int = _down_ticks(1)
	assert_eq(down, SimClock.ticks(_tuning.respawn_seconds(1)), "ticks of the data seconds")
	_steps(down - 1)
	assert_true(_king.is_down(), "still down one tick before the end")
	assert_gt(_king.respawn_seconds_remaining(), 0.0, "the label never reads zero while down")
	assert_eq(ceili(_king.respawn_seconds_remaining()), 1, "the last tick shows 1 s")
	_steps(1)
	assert_false(_king.is_down(), "up after exactly %d ticks" % down)
	assert_eq(_king.get_position(), SPAWN, "back at the castle")
	assert_eq(_king.get_health(), 3, "full health")
	assert_signal_emit_count(_events, "king_respawned", 1)
	assert_eq(_king.respawn_seconds_remaining(), 0.0, "no countdown once up")


func test_the_remaining_seconds_start_at_the_whole_countdown_and_shrink() -> void:
	_build_king(3)
	_king.take_damage(3)
	var start: float = _king.respawn_seconds_remaining()
	assert_almost_eq(start, _expected_seconds(1), 0.001, "the whole countdown")
	assert_eq(ceili(start), int(_expected_seconds(1)), "shown as whole seconds, rounded up")
	_steps(1)
	assert_lt(_king.respawn_seconds_remaining(), start, "it shrinks each tick")


func test_five_knockouts_in_one_night_count_down_6_10_14_15_15_never_above_the_cap() -> void:
	_build_king(3)
	watch_signals(_events)
	var expected: Array[int] = []
	for number: int in range(1, 6):
		_king.take_damage(3)
		assert_signal_emitted_with_parameters(
			_events, "king_downed", [_down_ticks(number), number], number - 1
		)
		expected.append(_down_ticks(number))
		_steps(_down_ticks(number) - 1)
		assert_true(_king.is_down(), "knockout %d still down a tick early" % number)
		_steps(1)
		assert_false(_king.is_down(), "knockout %d over on time" % number)
	assert_eq(_king.knockouts_this_night(), 5, "five this night")
	assert_eq(_king.knockouts_total(), 5, "and five overall")
	assert_eq(expected[4], SimClock.ticks(CAP_PIN), "the fifth is the 15 s cap")
	assert_eq(expected[3], expected[4], "the fourth already hit the cap")


func test_the_count_resets_each_night_but_the_total_does_not() -> void:
	_build_king(3)
	for _n: int in range(3):
		_king.take_damage(3)
		_steps(_down_ticks(_king.knockouts_this_night()))
	assert_eq(_king.knockouts_this_night(), 3, "three knockouts this night")
	_king.begin_night()
	assert_eq(_king.knockouts_this_night(), 0, "a new night starts at zero")
	assert_eq(_king.knockouts_total(), 3, "the total keeps counting")
	watch_signals(_events)
	_king.take_damage(3)
	assert_signal_emitted_with_parameters(_events, "king_downed", [_down_ticks(1), 1])


func test_there_is_no_regeneration_during_a_night() -> void:
	_build_king(6)
	_king.take_damage(4)
	_steps(SimClock.ticks(60.0))
	assert_eq(_king.get_health(), 2, "damage taken stays until dawn or a respawn")


func test_enemies_drop_a_downed_king_and_hits_on_the_knockout_tick_are_dropped() -> void:
	var map: MapConfig = MapConfig.new()
	map.king_spawn = Vector3(SPAWN.x, 0.0, SPAWN.y)
	var events: SimEvents = SimEvents.new()
	var def: KingDef = _def.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	def.max_health = 2
	var king: KingState = KingState.new(def, SPAWN, events, _tuning)
	var night: NightSim = NightSim.new(map, events, king, SEED)
	night.begin_night(1)
	var striker: EnemyDef = _grunt.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	striker.max_health = 100000
	striker.attack_damage = 2
	king.report_position(Vector2(40.0, 0.0))
	var stand_off: float = def.body_radius + striker.attack_range
	var first: int = night.get_enemies().spawn(striker, Vector2(40.0 + stand_off, 0.0))
	var second: int = night.get_enemies().spawn(striker, Vector2(40.0, stand_off))
	watch_signals(events)
	night.step(0)
	assert_true(king.is_down(), "the first hit knocked him out")
	assert_signal_emit_count(events, "king_downed", 1, "once")
	assert_signal_emit_count(events, "king_damaged", 1, "the second hit that tick was dropped")
	night.step(1)
	for id: int in [first, second]:
		assert_ne(
			night.get_enemies().target_of(id).get("kind", &""),
			PendingHits.KIND_KING,
			"enemy %d no longer targets the downed king" % id
		)


func test_enemies_can_target_the_king_again_after_he_respawns() -> void:
	var map: MapConfig = MapConfig.new()
	map.king_spawn = Vector3(SPAWN.x, 0.0, SPAWN.y)
	var events: SimEvents = SimEvents.new()
	var king: KingState = KingState.new(_def, SPAWN, events, _tuning)
	var night: NightSim = NightSim.new(map, events, king, SEED)
	night.begin_night(1)
	king.take_damage(_def.max_health)
	var tick: int = 0
	for _i: int in range(_down_ticks(1)):
		night.step(tick)
		tick += 1
	assert_false(king.is_down(), "he is back")
	var late: int = night.get_enemies().spawn(_grunt, SPAWN + Vector2(3.0, 0.0))
	night.step(tick)
	assert_eq(
		night.get_enemies().target_of(late).get("kind", &""),
		PendingHits.KIND_KING,
		"a new enemy near the respawned king targets him"
	)


func _context() -> RunContext:
	return RunContext.new(E2eSupport.waveless_prototype_map(), _tuning, SEED)


func _step_until_phase(ctx: RunContext, phase: int, limit: int) -> void:
	for _i: int in range(limit):
		if ctx.run_manager.get_phase() == phase:
			return
		ctx.step()
	assert_eq(ctx.run_manager.get_phase(), phase, "the phase arrives within %d steps" % limit)


func test_a_knockout_costs_no_gold_and_does_not_end_the_night() -> void:
	var ctx: RunContext = _context()
	ctx.commands.submit(StartNightIntent.new())
	var gold: int = ctx.economy.get_gold()
	ctx.king.take_damage(ctx.king.get_max_health())
	ctx.step()
	assert_true(ctx.king.is_down(), "he is down")
	assert_eq(ctx.economy.get_gold(), gold, "D-03: no gold penalty")
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.NIGHT, "D-06: the run goes on")


func test_dawn_restores_a_damaged_king_to_full_health() -> void:
	var ctx: RunContext = _context()
	ctx.commands.submit(StartNightIntent.new())
	ctx.king.take_damage(ctx.king.get_max_health() - 1)
	assert_eq(ctx.king.get_health(), 1, "nearly dead, still up")
	_step_until_phase(ctx, RunManager.RunPhase.DAWN, 600)
	assert_eq(ctx.king.get_health(), ctx.king.get_max_health(), "dawn heals fully (D-05)")


func test_a_king_still_down_when_the_night_clears_is_back_at_dawn_exactly_once() -> void:
	var ctx: RunContext = _context()
	var spawn: Vector2 = Vector2(ctx.map.king_spawn.x, ctx.map.king_spawn.z)
	ctx.commands.submit(StartNightIntent.new())
	ctx.king.report_position(spawn + Vector2(15.0, 15.0))
	watch_signals(ctx.events)
	ctx.king.take_damage(ctx.king.get_max_health())
	assert_gt(
		SimClock.ticks(_tuning.respawn_seconds(1)),
		SimClock.ticks(_tuning.placeholder_night_seconds),
		"the countdown outlasts the placeholder night, so he is down when it clears"
	)
	_step_until_phase(ctx, RunManager.RunPhase.DAWN, 600)
	assert_false(ctx.king.is_down(), "up at dawn")
	assert_eq(ctx.king.get_position(), spawn, "at king_spawn")
	assert_eq(ctx.king.get_health(), ctx.king.get_max_health(), "with full health")
	assert_signal_emit_count(ctx.events, "king_respawned", 1, "exactly once")
	_step_until_phase(ctx, RunManager.RunPhase.DAY, 600)
	assert_signal_emit_count(ctx.events, "king_respawned", 1, "still once at day")
	ctx.commands.submit(StartNightIntent.new())
	assert_eq(ctx.king.knockouts_this_night(), 0, "the next night starts at zero")
	assert_eq(ctx.king.knockouts_total(), 1, "the total remembers")
