extends GutTest
## LOOP-03 on the shipped map: starting night 1 on the prototype brings exactly the telegraphed
## enemies from the west road, and the night ends in dawn only after the last one is dead. Counts
## come from WaveSchedule.preview_counts and the map data, not from literals. A RunContext with no
## scene tree, stepped with ctx.step().

const TUNING := "res://data/tuning/loop_tuning.tres"
## 1800 steps is 60 s of game time: the 70 m march takes about 22 s, the last spawn is due at 6.5 s.
const MAX_NIGHT_STEPS: int = 1800
const WEST: StringName = &"west"

var _tuning: LoopTuning


func before_each() -> void:
	_tuning = load(TUNING)


## The king holds the castle edge on the west approach, where the grunts stop to attack.
func _hold_point(map: MapConfig) -> Vector2:
	var spawn: SpawnPointDef = map.find_spawn_point(WEST)
	var castle: Vector2 = Vector2(map.castle_position.x, map.castle_position.z)
	var from_castle: Vector2 = Vector2(spawn.position.x, spawn.position.z) - castle
	return castle + from_castle.normalized() * map.castle_radius


func _context() -> RunContext:
	var map: MapConfig = E2eSupport.shipped_prototype_map()
	var ctx: RunContext = RunContext.new(map, _tuning, 1)
	ctx.king.report_position(_hold_point(map))
	return ctx


func test_night_one_spawns_exactly_the_previewed_enemies_at_the_west_spawn_point() -> void:
	var ctx: RunContext = _context()
	var counts: Dictionary = WaveSchedule.preview_counts(ctx.map, 1)
	var expected: int = counts[WEST]
	assert_eq(counts.size(), 1, "night 1 comes from one spawn point only")
	assert_true(counts.has(WEST), "and it is the west road")
	var spawn: SpawnPointDef = ctx.map.find_spawn_point(WEST)
	watch_signals(ctx.events)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "the night starts")
	for _i: int in range(MAX_NIGHT_STEPS):
		ctx.step()
		if ctx.run_manager.get_phase() == RunManager.RunPhase.DAWN:
			break
	assert_signal_emit_count(ctx.events, "enemy_spawned", expected, "the previewed count spawned")
	for index: int in range(expected):
		var spawned: Array = get_signal_parameters(ctx.events, "enemy_spawned", index)
		var at: Vector2 = spawned[2]
		assert_true(absf(at.x - spawn.position.x) <= spawn.scatter_radius, "x within scatter")
		assert_true(absf(at.y - spawn.position.z) <= spawn.scatter_radius, "z within scatter")


func test_the_night_stays_night_until_the_last_enemy_is_dead_then_dawn_follows() -> void:
	var ctx: RunContext = _context()
	var expected: int = WaveSchedule.preview_counts(ctx.map, 1)[WEST]
	watch_signals(ctx.events)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "the night starts")
	var last_death_tick: int = -1
	var dawn_tick: int = -1
	var deaths: int = 0
	for _i: int in range(MAX_NIGHT_STEPS):
		ctx.step()
		var dead_now: int = get_signal_emit_count(ctx.events, "enemy_died")
		if dead_now > deaths:
			deaths = dead_now
			last_death_tick = ctx.tick_count
		if ctx.run_manager.get_phase() == RunManager.RunPhase.DAWN:
			dawn_tick = ctx.tick_count
			break
		var unfinished: bool = ctx.night.enemy_count() > 0 or ctx.night.remaining_count() > 0
		assert_true(unfinished, "still NIGHT only while an enemy lives or is yet to spawn")
	assert_gt(dawn_tick, 0, "dawn arrives within %d steps" % MAX_NIGHT_STEPS)
	assert_eq(deaths, expected, "every enemy died before dawn")
	assert_lte(dawn_tick - last_death_tick, 1, "dawn comes with the last death")
	assert_gte(dawn_tick, last_death_tick, "never before it")


func test_the_waveless_copy_has_no_nights_and_leaves_the_shipped_map_untouched() -> void:
	var shipped: MapConfig = load(E2eSupport.PROTOTYPE_MAP_PATH)
	var shipped_nights: int = shipped.nights.size()
	var waveless: MapConfig = E2eSupport.waveless_prototype_map()
	assert_true(waveless.nights.is_empty(), "the waveless copy has no nights")
	assert_eq(waveless.spots.size(), shipped.spots.size(), "but the same spots")
	assert_eq(waveless.buildings.size(), shipped.buildings.size(), "and the same buildings")
	assert_eq(waveless.starting_gold, shipped.starting_gold, "and the same scalars")
	waveless.spots.clear()
	waveless.starting_gold = 999
	var again: MapConfig = load(E2eSupport.PROTOTYPE_MAP_PATH)
	assert_eq(again.nights.size(), shipped_nights, "the cached map kept its nights")
	assert_gt(again.spots.size(), 0, "and its spots")
	assert_ne(again.starting_gold, 999, "and its gold")


func test_the_shipped_copy_keeps_every_authored_night() -> void:
	var shipped: MapConfig = load(E2eSupport.PROTOTYPE_MAP_PATH)
	var copy: MapConfig = E2eSupport.shipped_prototype_map()
	assert_eq(copy.nights.size(), shipped.nights.size(), "all nights kept")
	assert_eq(copy.nights.size(), 8, "the prototype has eight nights (D-07)")
	assert_ne(copy.nights[0], shipped.nights[0], "as a deep copy, not the shared resource")


func test_only_the_shots_that_start_the_night_ask_for_the_timed_night() -> void:
	for shot: StringName in ShotScenarios.ALL_SHOTS:
		var starts_night: bool = (
			shot == ShotScenarios.NIGHT_BANNER or shot == ShotScenarios.DAWN_PAYOUT
		)
		assert_eq(ShotScenarios.needs_timed_night(shot), starts_night, "shot %s" % shot)
