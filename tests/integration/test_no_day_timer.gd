extends GutTest
## LOOP-01 with real nights: nothing ends the day except the deliberate start-night input. No
## timer, no automatic night, no countdown. A RunContext on the shipped map, no scene tree.

const TUNING := "res://data/tuning/loop_tuning.tres"
## 10 simulated minutes at 30 steps a second.
const TEN_MINUTES_OF_STEPS: int = 18000
const SPOT: StringName = &"house_1"

var _tuning: LoopTuning


func before_each() -> void:
	_tuning = load(TUNING)


func _context() -> RunContext:
	return RunContext.new(E2eSupport.shipped_prototype_map(), _tuning, 1)


func test_ten_minutes_of_day_steps_leave_the_day_untouched() -> void:
	var ctx: RunContext = _context()
	watch_signals(ctx.events)

	for _i: int in range(TEN_MINUTES_OF_STEPS):
		ctx.step()

	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAY, "still day")
	assert_eq(ctx.run_manager.get_night_number(), 0, "no night began")
	assert_eq(ctx.tick_count, TEN_MINUTES_OF_STEPS, "every step really ran")
	assert_signal_not_emitted(ctx.events, "night_started")
	assert_signal_not_emitted(ctx.events, "phase_changed")
	assert_eq(ctx.get_enemy_count(), 0, "and nothing spawned")


func test_a_double_start_night_starts_exactly_one_night() -> void:
	var ctx: RunContext = _context()
	watch_signals(ctx.events)

	var first: StringName = ctx.commands.submit(StartNightIntent.new())
	var second: StringName = ctx.commands.submit(StartNightIntent.new())

	assert_eq(first, CommandProcessor.OK, "the first submit starts the night")
	assert_eq(second, CommandProcessor.NOT_DAY, "the second finds no day to end")
	assert_eq(ctx.run_manager.get_night_number(), 1, "night_number rose by exactly one")
	assert_signal_emit_count(ctx.events, "night_started", 1, "one night_started")


func test_a_build_then_start_night_in_one_tick_lands_the_build_and_starts_the_night() -> void:
	var ctx: RunContext = _context()
	var gold_before: int = ctx.economy.get_gold()
	var cost: int = ctx.buildings.next_action_cost(SPOT)

	var built: StringName = ctx.commands.submit(BuildIntent.new(SPOT))
	var started: StringName = ctx.commands.submit(StartNightIntent.new())
	ctx.step()

	assert_eq(built, CommandProcessor.OK, "the build was accepted first")
	assert_eq(started, CommandProcessor.OK, "then the night started")
	assert_eq(ctx.buildings.current_tier(SPOT), 1, "the building stands")
	assert_eq(ctx.economy.get_gold(), gold_before - cost, "and was paid for")
	assert_eq(ctx.run_manager.get_night_number(), 1, "night one is running")


func test_a_start_night_then_build_in_one_tick_starts_the_night_and_rejects_the_build() -> void:
	var ctx: RunContext = _context()
	var gold_before: int = ctx.economy.get_gold()

	var started: StringName = ctx.commands.submit(StartNightIntent.new())
	var built: StringName = ctx.commands.submit(BuildIntent.new(SPOT))
	ctx.step()

	assert_eq(started, CommandProcessor.OK, "the night started first")
	assert_eq(built, CommandProcessor.NOT_DAY, "so the build finds no day")
	assert_eq(ctx.buildings.current_tier(SPOT), 0, "nothing was built")
	assert_eq(ctx.economy.get_gold(), gold_before, "no gold was spent")
	assert_eq(ctx.run_manager.get_night_number(), 1, "night one is running")
