extends GutTest
## LOOP-03 and KING-03 through the whole simulation: a RunContext on fixture_map_one_night.tres,
## stepped with ctx.step() and no scene tree. Variations of the fixture are deep copies (DR-12).

const FIXTURE := "res://tests/fixtures/fixture_map_one_night.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
## The king's hold point in front of the west route: the grunts stop 4.7 m from the castle.
const KING_AT := Vector2(-4.5, 0.0)
const MAX_NIGHT_STEPS: int = 900
const ROOMY_STEPS: int = 2500

var _tuning: LoopTuning


func before_each() -> void:
	_tuning = load(TUNING)


func _fixture_copy() -> MapConfig:
	var shipped: MapConfig = load(FIXTURE)
	return shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)


func _context(map: MapConfig = null, run_seed: int = 1) -> RunContext:
	var used: MapConfig = map if map != null else load(FIXTURE)
	var ctx: RunContext = RunContext.new(used, _tuning, run_seed)
	ctx.king.report_position(KING_AT)
	return ctx


func _start_night(ctx: RunContext) -> void:
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "the night starts")


func _phase(ctx: RunContext) -> int:
	return ctx.run_manager.get_phase()


func _group(spawn_point: StringName, count: int, delay: float) -> SpawnGroupDef:
	var group: SpawnGroupDef = SpawnGroupDef.new()
	group.spawn_point_id = spawn_point
	group.enemy_id = &"grunt"
	group.count = count
	group.start_delay_seconds = delay
	group.interval_seconds = 1.0
	return group


func test_a_seeded_night_spawns_marches_dies_to_the_king_and_ends_in_dawn() -> void:
	var ctx: RunContext = _context()
	var spawn: SpawnPointDef = ctx.map.find_spawn_point(&"west")
	var count: int = ctx.map.night_def(1).groups[0].count
	watch_signals(ctx.events)
	_start_night(ctx)
	var dawn_tick: int = -1
	var last_death_tick: int = -1
	var deaths: int = 0
	for _i: int in range(MAX_NIGHT_STEPS):
		ctx.step()
		var now_dead: int = get_signal_emit_count(ctx.events, "enemy_died")
		if now_dead > deaths:
			deaths = now_dead
			last_death_tick = ctx.tick_count
		var unfinished: bool = ctx.night.enemy_count() > 0 or ctx.night.remaining_count() > 0
		if _phase(ctx) == RunManager.RunPhase.DAWN:
			dawn_tick = ctx.tick_count
			break
		assert_true(unfinished, "the night never idles in NIGHT with nothing left")
	assert_gt(dawn_tick, 0, "dawn arrives within %d steps" % MAX_NIGHT_STEPS)
	assert_signal_emit_count(ctx.events, "enemy_spawned", count, "every grunt spawned")
	assert_signal_emit_count(ctx.events, "enemy_died", count, "every grunt died")
	for index: int in range(count):
		var spawned: Array = get_signal_parameters(ctx.events, "enemy_spawned", index)
		assert_eq(spawned[0], index + 1, "ids count up in spawn order")
		assert_eq(spawned[1], &"grunt", "the def id")
		var at: Vector2 = spawned[2]
		assert_true(absf(at.x - spawn.position.x) <= spawn.scatter_radius, "x within scatter")
		assert_true(absf(at.y - spawn.position.z) <= spawn.scatter_radius, "z within scatter")
		var died: Array = get_signal_parameters(ctx.events, "enemy_died", index)
		assert_eq(died[3], PendingHits.KIND_KING, "the king made every kill")
	assert_lte(dawn_tick - last_death_tick, 1, "dawn comes with the last death")
	assert_eq(ctx.economy.get_gold(), ctx.map.starting_gold, "kills award no gold")
	assert_signal_not_emitted(ctx.events, "gold_changed")


func test_the_phase_is_night_on_every_step_while_a_spawn_is_pending() -> void:
	var ctx: RunContext = _context()
	_start_night(ctx)
	var steps_in_night: int = 0
	while _phase(ctx) == RunManager.RunPhase.NIGHT and steps_in_night < MAX_NIGHT_STEPS:
		ctx.step()
		steps_in_night += 1
		if ctx.night.spawned_count() < ctx.night.total_count():
			assert_eq(_phase(ctx), RunManager.RunPhase.NIGHT, "a spawn is still pending")
	assert_eq(_phase(ctx), RunManager.RunPhase.DAWN, "and then the night ends")


func test_an_early_death_does_not_end_the_night_while_a_later_spawn_is_pending() -> void:
	var map: MapConfig = _fixture_copy()
	map.nights[0].groups.append(_group(&"west", 1, 20.0))
	var ctx: RunContext = _context(map)
	watch_signals(ctx.events)
	_start_night(ctx)
	var late_tick: int = SimClock.ticks(20.0)
	var first_wave_done_at: int = -1
	for _i: int in range(ROOMY_STEPS):
		ctx.step()
		if first_wave_done_at < 0 and get_signal_emit_count(ctx.events, "enemy_died") == 3:
			first_wave_done_at = ctx.tick_count
			assert_eq(ctx.night.enemy_count(), 0, "the first three are dead")
			assert_false(ctx.night.is_cleared(), "but a spawn is still pending")
			assert_eq(_phase(ctx), RunManager.RunPhase.NIGHT, "so the night goes on")
		if _phase(ctx) == RunManager.RunPhase.DAWN:
			break
	assert_gt(first_wave_done_at, 0, "the first wave died")
	assert_lt(first_wave_done_at, late_tick, "well before the late enemy is due")
	assert_signal_emit_count(ctx.events, "enemy_spawned", 4, "the late enemy spawned")
	assert_signal_emit_count(ctx.events, "enemy_died", 4, "and died")
	assert_eq(_phase(ctx), RunManager.RunPhase.DAWN, "only then dawn")


func test_spawns_due_on_one_tick_follow_group_order_then_index() -> void:
	var map: MapConfig = _fixture_copy()
	var east: SpawnPointDef = SpawnPointDef.new()
	east.id = &"east"
	east.position = Vector3(30.0, 0.0, 0.0)
	map.spawn_points.append(east)
	map.nights[0].groups.clear()
	map.nights[0].groups.append(_group(&"west", 2, 0.5))
	map.nights[0].groups.append(_group(&"east", 2, 0.5))
	var ctx: RunContext = _context(map)
	watch_signals(ctx.events)
	_start_night(ctx)
	for _i: int in range(SimClock.ticks(2.0)):
		ctx.step()
	assert_signal_emit_count(ctx.events, "enemy_spawned", 4, "four spawns")
	var sides: Array[bool] = []
	for index: int in range(4):
		var spawned: Array = get_signal_parameters(ctx.events, "enemy_spawned", index)
		assert_eq(spawned[0], index + 1, "ids strictly increase in spawn order")
		var at: Vector2 = spawned[2]
		sides.append(at.x > 0.0)
	assert_eq(sides, [false, true, false, true] as Array[bool], "group 0 then group 1, per tick")


func test_a_map_with_no_nights_keeps_the_timed_night() -> void:
	var map: MapConfig = _fixture_copy()
	map.nights.clear()
	var ctx: RunContext = _context(map)
	assert_false(ctx.night.has_authored_nights(), "no authored nights")
	_start_night(ctx)
	var steps: int = 0
	while _phase(ctx) == RunManager.RunPhase.NIGHT and steps < MAX_NIGHT_STEPS:
		ctx.step()
		steps += 1
	assert_eq(_phase(ctx), RunManager.RunPhase.DAWN, "the timed night ends in dawn")
	assert_almost_eq(
		SimClock.seconds(steps), _tuning.placeholder_night_seconds, SimClock.STEP * 2.0, "on time"
	)


func test_the_last_spawn_and_the_last_death_on_one_tick_end_the_night_that_tick() -> void:
	var map: MapConfig = _fixture_copy()
	map.enemies[0].max_health = 1
	map.nights[0].groups.clear()
	map.nights[0].groups.append(_group(&"west", 1, 0.0))
	var ctx: RunContext = _context(map)
	ctx.king.report_position(Vector2(-30.0, 0.0))
	watch_signals(ctx.events)
	_start_night(ctx)
	ctx.step()
	assert_signal_emit_count(ctx.events, "enemy_spawned", 1, "spawned on the first tick")
	assert_signal_emit_count(ctx.events, "enemy_died", 1, "and killed on the same tick")
	assert_true(ctx.night.is_cleared(), "cleared: finished spawning and nothing alive")
	assert_eq(_phase(ctx), RunManager.RunPhase.DAWN, "dawn on that same step")


func test_the_telegraph_preview_counts_per_spawn_point_in_map_order() -> void:
	var map: MapConfig = load(FIXTURE)
	assert_eq(WaveSchedule.preview_counts(map, 1), {&"west": 3}, "night 1 brings 3 from the west")
	assert_eq(WaveSchedule.preview_counts(map, 2), {&"west": 4}, "night 2 brings 4")
	assert_eq(WaveSchedule.preview_counts(map, 0), {}, "no night 0")
	assert_eq(WaveSchedule.preview_counts(map, 3), {}, "no night past the last")
