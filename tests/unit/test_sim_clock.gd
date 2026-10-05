extends GutTest
## DR-2 and DR-3: the fixed 30 Hz step is a determinism contract. Changing STEP regenerates every
## golden replay digest, so it is pinned here; the accumulator makes any frame split run the same
## steps and clamps a stalled frame.

const FIXTURE := "res://tests/fixtures/fixture_map_one_night.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"


func _context() -> RunContext:
	return RunContext.new(load(FIXTURE), load(TUNING))


func _advance_all(ctx: RunContext, frames: Array[float]) -> int:
	var steps: int = 0
	for frame: float in frames:
		steps += ctx.advance(frame)
	return steps


func test_the_step_is_pinned_at_30_hz() -> void:
	assert_eq(SimClock.STEP, 1.0 / 30.0, "STEP is 1/30 s")
	assert_eq(SimClock.MAX_ADVANCE_SECONDS, 0.25, "a frame is clamped to a quarter second")


func test_data_seconds_convert_to_whole_ticks_once() -> void:
	assert_eq(SimClock.ticks(0.8), 24, "0.8 s is 24 ticks, not 25")
	assert_eq(SimClock.ticks(1.0), 30, "one second is 30 ticks")
	assert_eq(SimClock.ticks(0.001), 1, "a tiny positive duration still takes a tick")
	assert_eq(SimClock.ticks(0.0), 0, "zero is zero ticks")
	assert_eq(SimClock.ticks(-1.0), 0, "negative is zero ticks")
	assert_almost_eq(SimClock.seconds(30), 1.0, 0.000001, "30 ticks last a second")


func test_sixty_frames_of_a_sixtieth_run_exactly_thirty_steps() -> void:
	var ctx: RunContext = _context()
	var frames: Array[float] = []
	for _i: int in range(60):
		frames.append(1.0 / 60.0)
	assert_eq(_advance_all(ctx, frames), 30, "30 steps")
	assert_eq(ctx.tick_count, 30, "the tick counter agrees")


func test_an_uneven_split_of_one_second_runs_exactly_thirty_steps() -> void:
	var ctx: RunContext = _context()
	var frames: Array[float] = [0.1, 0.2, 0.05, 0.15, 0.25, 0.125, 0.125]
	assert_eq(_advance_all(ctx, frames), 30, "30 steps however the frames fall")


func test_one_stalled_frame_runs_at_most_the_clamp() -> void:
	var ctx: RunContext = _context()
	assert_eq(ctx.advance(5.0), 7, "a quarter second is 7 whole steps")


func test_a_negative_frame_runs_nothing() -> void:
	var ctx: RunContext = _context()
	assert_eq(ctx.advance(-1.0), 0, "no negative time")
	assert_eq(ctx.tick_count, 0, "no step ran")


func test_alpha_stays_below_one() -> void:
	var ctx: RunContext = _context()
	var frames: Array[float] = [0.01, 0.02, 0.031, 0.0333, 0.0334, 0.017, 0.2]
	for frame: float in frames:
		ctx.advance(frame)
		assert_true(ctx.alpha() >= 0.0 and ctx.alpha() < 1.0, "alpha in [0, 1) after %s" % frame)
