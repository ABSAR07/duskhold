extends GutTest
## LOOP-06 and LOOP-07 through the whole simulation: the castle falling loses the run in that very
## step (and beats a same-step win), clearing the last authored night wins it with no last dawn,
## and WON and LOST are terminal. Fixtures are deep copies of fixture_map_one_night.tres (two
## nights), stepped with ctx.step() and no scene tree. Damage and health come from grunt.tres and
## the fixture, so a retune cannot break these tests.

const FIXTURE := "res://tests/fixtures/fixture_map_one_night.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
## The king's hold point in front of the west route: his passive attack reaches the grunts.
const KING_AT := Vector2(-4.5, 0.0)
const KING_FAR := Vector2(500.0, 500.0)
## Close enough to hit a grunt at the castle edge (attack range 3 m) yet outside its aggro range.
const KING_NEAR_GRUNT := Vector2(-6.7, 0.0)
const MAX_NIGHT_STEPS: int = 1500
const IDLE_STEPS: int = 90

var _tuning: LoopTuning


func before_each() -> void:
	_tuning = load(TUNING)


func _fixture_copy() -> MapConfig:
	var shipped: MapConfig = load(FIXTURE)
	return shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)


func _group(count: int) -> SpawnGroupDef:
	var group: SpawnGroupDef = SpawnGroupDef.new()
	group.spawn_point_id = &"west"
	group.enemy_id = &"grunt"
	group.count = count
	group.start_delay_seconds = 0.0
	group.interval_seconds = 1.0
	return group


## Night 1 spawns `grunts` grunts, all on the first tick, standing exactly at the castle's stop
## distance (castle radius plus the grunt's attack range), so each one strikes the castle at once.
func _siege_map(castle_hp: int, grunts: int) -> MapConfig:
	var map: MapConfig = _fixture_copy()
	map.castle_max_health = castle_hp
	var grunt: EnemyDef = map.enemies[0]
	var west: SpawnPointDef = map.find_spawn_point(&"west")
	west.position = Vector3(-(map.castle_radius + grunt.attack_range), 0.0, 0.0)
	west.scatter_radius = 0.0
	map.nights[0].groups.clear()
	for _i: int in range(grunts):
		map.nights[0].groups.append(_group(1))
	return map


func _context(map: MapConfig, king_at: Vector2 = KING_FAR) -> RunContext:
	var ctx: RunContext = RunContext.new(map, _tuning, 1)
	ctx.king.report_position(king_at)
	return ctx


func _start_night(ctx: RunContext) -> void:
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "the night starts")


func _phase(ctx: RunContext) -> int:
	return ctx.run_manager.get_phase()


## Steps until `done` is true or `max_steps` run out; returns whether it became true.
func _step_until(ctx: RunContext, done: Callable, max_steps: int) -> bool:
	for _i: int in range(max_steps):
		if done.call():
			return true
		ctx.step()
	return done.call()


func _into_phase(ctx: RunContext, phase: int, max_steps: int = MAX_NIGHT_STEPS) -> bool:
	return _step_until(ctx, func() -> bool: return _phase(ctx) == phase, max_steps)


## Plays night 1 of the two-night fixture to its dawn, then through the dawn to the next day.
func _clear_night_one(ctx: RunContext) -> void:
	_start_night(ctx)
	assert_true(_into_phase(ctx, RunManager.RunPhase.DAWN), "night 1 ends in dawn")
	assert_true(_into_phase(ctx, RunManager.RunPhase.DAY, 400), "and the dawn hands over to day 2")


func _emit_counts(ctx: RunContext) -> Dictionary:
	var counts: Dictionary = {}
	for signal_name: String in SimSignals.ALL:
		counts[signal_name] = get_signal_emit_count(ctx.events, signal_name)
	return counts


func test_the_run_is_lost_in_the_step_the_castle_reaches_zero() -> void:
	var map: MapConfig = _siege_map(_fixture_copy().enemies[0].attack_damage + 1, 1)
	var ctx: RunContext = _context(map)
	watch_signals(ctx.events)
	_start_night(ctx)
	var fell_at: int = -1
	var steps_before: int = 0
	for _i: int in range(MAX_NIGHT_STEPS):
		ctx.step()
		if ctx.castle.is_destroyed():
			fell_at = ctx.tick_count
			break
		steps_before += 1
		assert_eq(_phase(ctx), RunManager.RunPhase.NIGHT, "the castle still stands: night goes on")
		assert_eq(get_signal_emit_count(ctx.events, "run_ended"), 0, "no end while it stands")
	assert_gt(fell_at, 0, "the grunt brought the castle down")
	assert_gt(steps_before, 0, "it took more than one hit: the castle held at 1 hp first")
	assert_eq(_phase(ctx), RunManager.RunPhase.LOST, "lost in the very step the castle fell")
	assert_eq(ctx.castle.get_health(), 0, "overkill clamps at 0, never below")
	assert_signal_emit_count(ctx.events, "castle_destroyed", 1)
	assert_signal_emit_count(ctx.events, "run_ended", 1)
	assert_signal_emitted_with_parameters(ctx.events, "run_ended", [&"defeat"])
	assert_signal_emitted_with_parameters(
		ctx.events, "phase_changed", [RunManager.RunPhase.NIGHT, RunManager.RunPhase.LOST]
	)
	assert_true(ctx.run_manager.is_run_over(), "the run is over")


func test_a_castle_at_one_hit_point_keeps_the_run_going() -> void:
	var map: MapConfig = _siege_map(_fixture_copy().enemies[0].attack_damage + 1, 1)
	var ctx: RunContext = _context(map)
	watch_signals(ctx.events)
	_start_night(ctx)
	ctx.step()
	assert_eq(ctx.castle.get_health(), 1, "one strike leaves 1 hp")
	assert_false(ctx.castle.is_destroyed(), "not destroyed at 1 hp")
	assert_eq(_phase(ctx), RunManager.RunPhase.NIGHT, "the run goes on")
	assert_signal_not_emitted(ctx.events, "run_ended")
	assert_signal_not_emitted(ctx.events, "castle_destroyed")


func test_several_hits_on_the_same_step_end_the_run_once() -> void:
	var damage: int = _fixture_copy().enemies[0].attack_damage
	var ctx: RunContext = _context(_siege_map(damage, 3))
	watch_signals(ctx.events)
	_start_night(ctx)
	ctx.step()
	assert_eq(ctx.castle.get_health(), 0, "the first strike took the last point")
	assert_eq(_phase(ctx), RunManager.RunPhase.LOST, "lost")
	assert_signal_emit_count(ctx.events, "castle_destroyed", 1, "once, whatever else lands")
	assert_signal_emit_count(ctx.events, "castle_damaged", 1, "the later hits were dropped")
	assert_signal_emit_count(ctx.events, "run_ended", 1, "one end")
	for _i: int in range(IDLE_STEPS):
		ctx.step()
	assert_signal_emit_count(ctx.events, "castle_destroyed", 1, "still once")
	assert_signal_emit_count(ctx.events, "run_ended", 1, "still one end")


func test_the_last_enemy_dying_in_the_step_the_castle_falls_is_a_loss() -> void:
	var damage: int = _fixture_copy().enemies[0].attack_damage
	var map: MapConfig = _siege_map(damage, 1)
	map.enemies[0].max_health = 1
	map.enemies[0].aggro_range = map.enemies[0].attack_range + 0.3
	var ctx: RunContext = _context(map, KING_NEAR_GRUNT)
	watch_signals(ctx.events)
	_start_night(ctx)
	ctx.step()
	assert_signal_emit_count(ctx.events, "enemy_died", 1, "the king killed the last enemy")
	assert_true(ctx.castle.is_destroyed(), "and the castle fell in that same step")
	assert_true(ctx.night.is_cleared(), "the night was cleared in that step too")
	assert_eq(_phase(ctx), RunManager.RunPhase.LOST, "loss beats the win: no dawn")
	assert_signal_not_emitted(ctx.events, "buildings_rebuilt")
	assert_signal_not_emitted(ctx.events, "dawn_payout")
	assert_signal_emit_count(ctx.events, "phase_changed", 3, "transition, night, lost")
	assert_signal_emitted_with_parameters(ctx.events, "run_ended", [&"defeat"])
	assert_eq(ctx.castle.get_health(), 0, "the castle stays at 0: no repair ran")


func test_clearing_a_night_before_the_last_enters_dawn() -> void:
	var ctx: RunContext = _context(_fixture_copy(), KING_AT)
	watch_signals(ctx.events)
	_start_night(ctx)
	assert_true(_into_phase(ctx, RunManager.RunPhase.DAWN), "night 1 of 2 ends in dawn")
	assert_signal_emit_count(ctx.events, "dawn_payout", 1, "the dawn paid")
	assert_signal_not_emitted(ctx.events, "run_ended")
	assert_false(ctx.run_manager.is_run_over(), "the run goes on")


func test_clearing_the_last_night_wins_with_no_last_dawn() -> void:
	var ctx: RunContext = _context(_fixture_copy(), KING_AT)
	watch_signals(ctx.events)
	_clear_night_one(ctx)
	var payouts_before: int = get_signal_emit_count(ctx.events, "dawn_payout")
	var rebuilt_before: int = get_signal_emit_count(ctx.events, "buildings_rebuilt")
	_start_night(ctx)
	assert_eq(ctx.run_manager.get_night_number(), ctx.run_manager.get_total_nights(), "the last")
	assert_true(_into_phase(ctx, RunManager.RunPhase.WON), "clearing night 2 of 2 wins")
	assert_signal_emit_count(ctx.events, "run_ended", 1)
	assert_signal_emitted_with_parameters(ctx.events, "run_ended", [&"victory"])
	assert_signal_emitted_with_parameters(
		ctx.events, "phase_changed", [RunManager.RunPhase.NIGHT, RunManager.RunPhase.WON]
	)
	assert_eq(get_signal_emit_count(ctx.events, "dawn_payout"), payouts_before, "no last payout")
	assert_eq(get_signal_emit_count(ctx.events, "buildings_rebuilt"), rebuilt_before, "no rebuild")
	assert_true(ctx.run_manager.is_run_over(), "the run is over")


func test_the_shipped_map_has_eight_nights_to_clear() -> void:
	var ctx: RunContext = RunContext.new(E2eSupport.shipped_prototype_map(), _tuning, 1)
	assert_eq(ctx.run_manager.get_total_nights(), 8, "eight authored nights")
	var waveless: RunContext = RunContext.new(E2eSupport.waveless_prototype_map(), _tuning, 1)
	assert_eq(waveless.run_manager.get_total_nights(), 0, "a waveless map has none")


func test_a_waveless_map_never_wins_it_keeps_its_timed_night() -> void:
	var ctx: RunContext = RunContext.new(E2eSupport.waveless_prototype_map(), _tuning, 1)
	for _cycle: int in range(3):
		_start_night(ctx)
		ctx.run_manager.tick(_tuning.placeholder_night_seconds + 0.1)
		assert_eq(_phase(ctx), RunManager.RunPhase.DAWN, "the timed night ends in dawn")
		ctx.run_manager.tick(_tuning.dawn_seconds + 0.1)
	assert_false(ctx.run_manager.is_run_over(), "no outcome without authored nights")


func test_the_defeat_is_legal_only_during_the_night() -> void:
	var ctx: RunContext = _context(_fixture_copy(), KING_AT)
	watch_signals(ctx.events)
	assert_false(ctx.run_manager.end_run_in_defeat(), "refused by day")
	_start_night(ctx)
	assert_true(_into_phase(ctx, RunManager.RunPhase.DAWN), "to dawn")
	assert_false(ctx.run_manager.end_run_in_defeat(), "refused at dawn")
	assert_signal_not_emitted(ctx.events, "run_ended")
	assert_true(_into_phase(ctx, RunManager.RunPhase.DAY, 400), "then day")
	_start_night(ctx)
	assert_true(ctx.run_manager.end_run_in_defeat(), "allowed at night")
	assert_eq(_phase(ctx), RunManager.RunPhase.LOST, "lost")
	assert_false(ctx.run_manager.end_run_in_defeat(), "a second time is refused")
	assert_signal_emit_count(ctx.events, "run_ended", 1, "one end")


func test_a_lost_run_is_frozen_and_refuses_every_intent() -> void:
	var damage: int = _fixture_copy().enemies[0].attack_damage
	var ctx: RunContext = _context(_siege_map(damage, 2))
	_start_night(ctx)
	ctx.step()
	assert_eq(_phase(ctx), RunManager.RunPhase.LOST, "lost")
	_assert_frozen(ctx)


func test_a_won_run_is_frozen_and_refuses_every_intent() -> void:
	var ctx: RunContext = _context(_fixture_copy(), KING_AT)
	_clear_night_one(ctx)
	_start_night(ctx)
	assert_true(_into_phase(ctx, RunManager.RunPhase.WON), "won")
	_assert_frozen(ctx)


func _assert_frozen(ctx: RunContext) -> void:
	var ticks: int = ctx.tick_count
	var elapsed: float = ctx.run_manager.get_elapsed()
	var gold: int = ctx.economy.get_gold()
	var enemies: int = ctx.get_enemy_count()
	var castle_hp: int = ctx.castle.get_health()
	watch_signals(ctx.events)
	for _i: int in range(IDLE_STEPS):
		ctx.step()
	ctx.advance(1.0)
	assert_eq(ctx.tick_count, ticks, "no step counted in a terminal phase")
	assert_eq(ctx.run_manager.get_elapsed(), elapsed, "the clock stands still")
	assert_eq(ctx.economy.get_gold(), gold, "gold unchanged")
	assert_eq(ctx.get_enemy_count(), enemies, "enemies unchanged")
	assert_eq(ctx.castle.get_health(), castle_hp, "castle unchanged")
	for signal_name: String in SimSignals.ALL:
		assert_signal_not_emitted(ctx.events, signal_name, "%s stays silent" % signal_name)
	assert_false(ctx.run_manager.is_build_allowed(), "no building")
	assert_true(ctx.run_manager.is_run_over(), "over")
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.NOT_DAY, "no new night")
	assert_eq(
		ctx.commands.submit(BuildIntent.new(&"house_1")), CommandProcessor.NOT_DAY, "no build"
	)
	assert_false(ctx.run_manager.start_night(), "start_night refuses")


func test_run_ended_fires_once_per_run_and_the_counts_hold_when_stepping_on() -> void:
	var damage: int = _fixture_copy().enemies[0].attack_damage
	var ctx: RunContext = _context(_siege_map(damage, 1))
	watch_signals(ctx.events)
	_start_night(ctx)
	ctx.step()
	var counts: Dictionary = _emit_counts(ctx)
	for _i: int in range(IDLE_STEPS):
		ctx.step()
	assert_eq(_emit_counts(ctx), counts, "no event after the end")
	assert_eq(counts["run_ended"], 1, "exactly one end")


func test_a_lost_run_replays_to_the_same_lost_digest_and_stops_there() -> void:
	var damage: int = _fixture_copy().enemies[0].attack_damage
	var map: MapConfig = _siege_map(damage + 1, 1)
	var bot: PlaytestBot = PlaytestBot.new()
	var first: Dictionary = ReplayDriver.run(map, _tuning, 1, bot, 4000)
	var second: Dictionary = ReplayDriver.run(map, _tuning, 1, PlaytestBot.new(), 4000)
	assert_eq(first["outcome"], &"lost", "the castle fell")
	assert_lt(first["ticks"], 4000, "the run stopped at the terminal step")
	assert_eq(first["digest"], second["digest"], "the same digest twice")
	var stats: Dictionary = first["stats"]
	assert_eq(stats["outcome"], &"defeat", "the stats carry the outcome")
	assert_eq(stats["nights_survived"], 0, "no night survived")
	var lines: PackedStringArray = first["lines"]
	var ended: int = 0
	for line: String in lines:
		if line.split(" ")[1] == "run_ended":
			ended += 1
	assert_eq(ended, 1, "the log holds one run_ended line")


func test_a_won_run_replays_to_won_with_the_nights_survived() -> void:
	var bot: PlaytestBot = PlaytestBot.new()
	bot.king_mode = PlaytestBot.KING_HOLD_POINT
	bot.hold_point = KING_AT
	var result: Dictionary = ReplayDriver.run(_fixture_copy(), _tuning, 1, bot, 12000)
	assert_eq(result["outcome"], &"won", "both nights were cleared")
	var stats: Dictionary = result["stats"]
	assert_eq(stats["outcome"], &"victory", "the stats carry the outcome")
	assert_eq(stats["nights_survived"], 2, "two of two")
	assert_eq(result["nights_started"], 2, "two nights were started")
