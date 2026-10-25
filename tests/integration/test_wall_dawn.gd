extends GutTest
## LOOP-04, D-05: dawn heals every hurt wall segment and rebuilds every broken one for free, after
## the repairs and before the payout, announced once. A dawn with nothing to restore announces
## nothing, and the rebuilt wall blocks again on the next night.
## Gap round G-05-2: a break is 100000 damage and a hurt 400, against the shipped 3000-health
## segments.

const FIXTURE := "res://tests/fixtures/fixture_map_walls.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const RING: StringName = &"wall_ring"
const SEGMENTS: int = 32
const MAX_STEPS: int = 600
const TWO_NIGHT_TICKS: int = 6000

var _tuning: LoopTuning
var _map: MapConfig


func before_each() -> void:
	_tuning = load(TUNING)
	_map = load(FIXTURE)


## The wall fixture with its authored nights removed: the Phase 1 timed night, so the test breaks
## segments itself and does not depend on which segment the grunts pick.
func _timed_context() -> RunContext:
	var map: MapConfig = _map.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	var no_nights: Array[NightDef] = []
	map.nights = no_nights
	return RunContext.new(map, _tuning, 1)


func _step_until(ctx: RunContext, phase: RunManager.RunPhase) -> bool:
	for _step: int in range(MAX_STEPS):
		if ctx.run_manager.get_phase() == phase:
			return true
		ctx.step()
	return ctx.run_manager.get_phase() == phase


func _index_of(lines: PackedStringArray, event_name: String) -> int:
	for index: int in range(lines.size()):
		if lines[index].split(" ")[1] == event_name:
			return index
	return -1


func _count(lines: PackedStringArray, event_name: String) -> int:
	var total: int = 0
	for line: String in lines:
		if line.split(" ")[1] == event_name:
			total += 1
	return total


func test_dawn_restores_every_segment_once_before_the_rebuilt_list_and_the_payout() -> void:
	var ctx: RunContext = _timed_context()
	var recorder: SimRecorder = SimRecorder.attach(ctx)
	ctx.commands.submit(BuildIntent.new(RING))
	ctx.commands.submit(StartNightIntent.new())
	ctx.walls.damage_segment(5, 100000)
	ctx.walls.damage_segment(6, 400)
	assert_false(ctx.walls.is_intact(5), "the night broke a segment")
	assert_lt(ctx.walls.health_of(6), ctx.walls.max_health_of(6), "and hurt another")
	var version: int = ctx.walls.version()
	var gold: int = ctx.economy.get_gold()
	assert_true(_step_until(ctx, RunManager.RunPhase.DAWN), "the timed night ends in dawn")
	for segment: int in range(SEGMENTS):
		assert_eq(ctx.walls.health_of(segment), ctx.walls.max_health_of(segment), "whole again")
	assert_gt(ctx.walls.version(), version, "closing the hole bumps the version")
	assert_eq(ctx.economy.get_gold(), gold, "the rebuild cost nothing")
	var lines: PackedStringArray = recorder.lines()
	assert_eq(_count(lines, "walls_restored"), 1, "announced once")
	var restored: int = _index_of(lines, "walls_restored")
	assert_true(lines[restored].ends_with("walls_restored wall_ring"), "with the run that changed")
	assert_lt(restored, _index_of(lines, "buildings_rebuilt"), "before the rebuilt list")
	assert_lt(restored, _index_of(lines, "dawn_payout"), "and before the payout")


func test_a_second_restore_at_the_same_dawn_changes_nothing() -> void:
	var ctx: RunContext = _timed_context()
	ctx.commands.submit(BuildIntent.new(RING))
	ctx.commands.submit(StartNightIntent.new())
	ctx.walls.damage_segment(2, 100000)
	assert_true(_step_until(ctx, RunManager.RunPhase.DAWN), "dawn")
	var recorder: SimRecorder = SimRecorder.attach(ctx)
	var version: int = ctx.walls.version()
	assert_true(ctx.night.restore_walls().is_empty(), "nothing is left to restore")
	assert_eq(ctx.walls.version(), version, "so nothing changed")
	assert_eq(_count(recorder.lines(), "walls_restored"), 0, "and nothing was announced")


func test_a_dawn_with_every_segment_whole_announces_nothing() -> void:
	var ctx: RunContext = _timed_context()
	var recorder: SimRecorder = SimRecorder.attach(ctx)
	ctx.commands.submit(BuildIntent.new(RING))
	ctx.commands.submit(StartNightIntent.new())
	assert_true(_step_until(ctx, RunManager.RunPhase.DAWN), "dawn")
	assert_eq(_count(recorder.lines(), "walls_restored"), 0, "no restore without damage")
	assert_eq(_count(recorder.lines(), "buildings_rebuilt"), 1, "the dawn itself happened")


func test_a_dawn_with_no_wall_built_announces_nothing() -> void:
	var ctx: RunContext = _timed_context()
	var recorder: SimRecorder = SimRecorder.attach(ctx)
	ctx.commands.submit(StartNightIntent.new())
	assert_true(_step_until(ctx, RunManager.RunPhase.DAWN), "dawn")
	assert_eq(_count(recorder.lines(), "walls_restored"), 0, "nothing was ever built")


func test_the_rebuilt_wall_blocks_again_on_the_next_night() -> void:
	var bot: PlaytestBot = PlaytestBot.new()
	bot.build_order = [RING, &"tower_1"]
	var result: Dictionary = ReplayDriver.run(_map, _tuning, 1, bot, TWO_NIGHT_TICKS, 2)
	var lines: PackedStringArray = result["lines"]
	var second_night: int = -1
	var starts: int = 0
	for index: int in range(lines.size()):
		if lines[index].split(" ")[1] == "night_started":
			starts += 1
			if starts == 2:
				second_night = index
	assert_gt(second_night, 0, "the run reached the second night")
	assert_lt(_index_of(lines, "walls_restored"), second_night, "the wall was rebuilt first")
	var attacks_on_night_two: int = 0
	for index: int in range(second_night, lines.size()):
		if lines[index].contains(" attack_fired enemy ") and lines[index].contains(" wall "):
			attacks_on_night_two += 1
	assert_gt(attacks_on_night_two, 0, "an enemy attacked the rebuilt wall")
