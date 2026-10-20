extends GutTest
## PLAT-01 (plan 04-26, exact_port_rules 7): the enemy bodies, flashes, hurt-only bars and death
## puffs pinned on the GDScript per-enemy fill that shipped before any native enemy-view code
## existed. Four runs drive an EnemyViews frame by frame: the 300-enemy stress night (the stress
## shape of the bench: every plot built, the king parked; towers hurt up to 135 enemies at once
## but nobody dies in 2400 frames, so it pins bodies, flashes and bars), the walls and army replay
## scenarios (two frames per simulation tick; a few deaths each) and a puff flood (hundreds of
## deaths of unknown enemies past the ring's cap, so the puff ring's fill, refusal, expiry and
## wrap are pinned). Frame deltas cycle through six unequal values, and the view's
## millisecond clock is a deterministic one (EnemyViews.set_clock) that moves by the rounded frame
## delta, so every flash and every puff age is the same on every run. After every frame one
## SHA-256 per run is fed the view, bar and puff counts and then, for the child batches "Grunts",
## "Skirmishers", "Others", "Bars" and "Puffs" in that order, the batch's count and its whole CPU
## mirror (instances, colours, custom data and the stale tail past the count). The pins were
## computed on the GDScript fill and are never edited: the native fill must reproduce them
## unchanged, and so must the native puff ring, because the puff batch is hashed too. The view only
## reads the run, so the golden digests do not move (the replay wrappers prove it).

const Probe := preload("res://tools/stress/step_attribution.gd")
const DELTAS: Array[float] = [1.0 / 144.0, 1.0 / 60.0, 1.0 / 240.0, 0.021, 1.0 / 30.0, 0.0047]
const STRESS_VARIANT := "full"
const STRESS_ENEMIES: int = 300
const STRESS_FRAMES: int = 2400
const FRAMES_PER_TICK: int = 2
## The puff flood: frames driven, the frame that gets the one big burst, and how big the burst is
## (past DeathPuffBatch.MAX_PUFFS, so the cap and the ring's wrap are both pinned).
const FLOOD_FRAMES: int = 900
const FLOOD_BURST_FRAME: int = 200
const FLOOD_BURST: int = 150
const FLOOD_FIRST_ID: int = 9000
const FLOOD_DEFS: Array[StringName] = [&"grunt", &"ranged", &"brute"]
const CLOCK_START_MS: int = 100000
## The batches hashed after every frame, in this order.
const BATCH_NAMES: Array[String] = ["Grunts", "Skirmishers", "Others", "Bars", "Puffs"]
## D-10's enemy bar: the stress night must put at least this many enemies on screen at once.
const STRESS_VIEW_FLOOR: int = 300
const PINS: Dictionary = {
	"stress":
	{
		"digest": "e8183d664f3f784734e49c2612422f007b4558153fbf0af5ea5e2bdd0e0643dc",
		"frames": 2400,
		"most_views": 300,
		"most_bars": 135,
		"most_puffs": 0,
	},
	"walls":
	{
		"digest": "fdeb2c226c927763599cdc1d7c215d3d22475bed9a431514ebc251e1c9b23e55",
		"frames": 3922,
		"most_views": 12,
		"most_bars": 2,
		"most_puffs": 2,
	},
	"army":
	{
		"digest": "ad55a687330e8bc6f48f43fb94c2cd665b1665dbcf4f57f6013640bd6ccc3b67",
		"frames": 2706,
		"most_views": 17,
		"most_bars": 3,
		"most_puffs": 3,
	},
	"flood":
	{
		"digest": "8495d93e355e09d750ff7041d778e34c9d22571401cfaadf8f2adc557a8a43b9",
		"frames": 900,
		"most_views": 0,
		"most_bars": 0,
		"most_puffs": 128,
	},
}


## Drives one EnemyViews on a deterministic clock and hashes what it draws after every frame.
class Driver:
	extends RefCounted

	var views: EnemyViews
	var frames: int = 0
	var most_views: int = 0
	var most_bars: int = 0
	var most_puffs: int = 0
	var _clock: Array[int] = [CLOCK_START_MS]
	var _context: HashingContext = HashingContext.new()
	var _bound: bool = false

	func _init(view: EnemyViews) -> void:
		views = view
		var cell: Array[int] = _clock
		views.set_clock(func() -> int: return cell[0])
		_context.start(HashingContext.HASH_SHA256)

	## The replay observer: binds on the first call, then drives FRAMES_PER_TICK frames.
	func on_tick(ctx: RunContext) -> void:
		if not _bound:
			views.bind_run(ctx, null)
			_bound = true
		for _frame: int in range(FRAMES_PER_TICK):
			var delta: float = DELTAS[frames % DELTAS.size()]
			tick_clock(delta)
			draw_frame()

	## Moves the clock by the frame's whole milliseconds.
	func tick_clock(delta: float) -> void:
		_clock[0] += roundi(delta * 1000.0)

	## One frame of the fill, then everything it drew goes into the hash.
	func draw_frame() -> void:
		views._process(0.0)
		var drawn: int = views.view_count()
		var bars: int = views.bar_count()
		var puffs: int = views.puff_count()
		most_views = maxi(most_views, drawn)
		most_bars = maxi(most_bars, bars)
		most_puffs = maxi(most_puffs, puffs)
		_context.update(PackedInt64Array([drawn, bars, puffs]).to_byte_array())
		for batch_name: String in BATCH_NAMES:
			var batch: CrowdBatch = views.get_node(batch_name) as CrowdBatch
			_context.update(PackedInt64Array([batch.count()]).to_byte_array())
			_context.update(batch.mirror().to_byte_array())
		frames += 1

	func bind_first(ctx: RunContext) -> void:
		views.bind_run(ctx, null)
		_bound = true

	func result() -> Dictionary:
		return {
			"digest": _context.finish().hex_encode(),
			"frames": frames,
			"most_views": most_views,
			"most_bars": most_bars,
			"most_puffs": most_puffs,
		}


func _new_driver() -> Driver:
	var views: EnemyViews = EnemyViews.new()
	add_child_autofree(views)
	views.set_process(false)
	return Driver.new(views)


## {digest, frames, most_views, most_bars, most_puffs} of `STRESS_FRAMES` frames of the stress
## night.
func _stress_run() -> Dictionary:
	var ctx: RunContext = Probe.build_context(STRESS_VARIANT, STRESS_ENEMIES)
	var driver: Driver = _new_driver()
	driver.bind_first(ctx)
	for frame: int in range(STRESS_FRAMES):
		var delta: float = DELTAS[frame % DELTAS.size()]
		driver.tick_clock(delta)
		ctx.king.report_position(Probe.KING_PARK)
		ctx.advance(delta)
		driver.draw_frame()
	return driver.result()


## The same fields for the puff flood: no enemy ever stands (the stress context is never advanced),
## deaths of unknown enemies leave puffs at their event positions, a few every frame and one big
## burst past the cap, so the ring fills, refuses, expires and wraps. Nothing but the puff batch
## moves, so it is the pin of the ring itself.
func _flood_run() -> Dictionary:
	var ctx: RunContext = Probe.build_context(STRESS_VARIANT, STRESS_ENEMIES)
	var driver: Driver = _new_driver()
	driver.bind_first(ctx)
	var next_id: int = FLOOD_FIRST_ID
	for frame: int in range(FLOOD_FRAMES):
		driver.tick_clock(DELTAS[frame % DELTAS.size()])
		var deaths: int = frame % 4
		if frame == FLOOD_BURST_FRAME:
			deaths = FLOOD_BURST
		for _death: int in range(deaths):
			var spot: Vector2 = Vector2(float(next_id % 37) * 0.75, float(next_id % 11) * 1.25)
			var def_id: StringName = FLOOD_DEFS[next_id % FLOOD_DEFS.size()]
			ctx.events.enemy_died.emit(next_id, def_id, spot, &"king")
			next_id += 1
		driver.draw_frame()
	return driver.result()


## The same fields for a replay scenario run at its default seed.
func _replay_run(scenario: StringName) -> Dictionary:
	var driver: Driver = _new_driver()
	ReplayScenarios.run(scenario, ReplayScenarios.default_seed(scenario), driver.on_tick)
	return driver.result()


func _assert_pinned(run: Dictionary, key: String, label: String) -> void:
	var pin: Dictionary = PINS.get(key, {})
	assert_eq(run["digest"], pin.get("digest", ""), "%s: the four mirrors and the counts" % label)
	assert_eq(run["frames"], pin.get("frames", -1), "%s: frames driven" % label)
	assert_eq(run["most_views"], pin.get("most_views", -1), "%s: the most enemies drawn" % label)
	assert_eq(run["most_bars"], pin.get("most_bars", -1), "%s: the most bars drawn" % label)
	assert_eq(run["most_puffs"], pin.get("most_puffs", -1), "%s: the most puffs standing" % label)


func test_the_stress_night_fill_is_pinned() -> void:
	var run: Dictionary = _stress_run()
	_assert_pinned(run, "stress", "the stress night")
	assert_gte(int(run["most_views"]), STRESS_VIEW_FLOOR, "D-10's 300 enemies were reached")


func test_the_walls_replay_fill_is_pinned() -> void:
	var run: Dictionary = _replay_run(&"walls")
	_assert_pinned(run, "walls", "the walls replay")
	assert_gte(int(run["most_views"]), 1, "the walls replay drew some enemy")


func test_the_army_replay_fill_is_pinned() -> void:
	var run: Dictionary = _replay_run(&"army")
	_assert_pinned(run, "army", "the army replay")
	assert_gte(int(run["most_views"]), 1, "the army replay drew some enemy")


func test_the_puff_flood_fill_is_pinned() -> void:
	var run: Dictionary = _flood_run()
	_assert_pinned(run, "flood", "the puff flood")
	assert_eq(run["most_puffs"], DeathPuffBatch.MAX_PUFFS, "the flood filled the ring to its cap")


func test_the_pins_are_present_and_differ() -> void:
	assert_eq(PINS.size(), 4, "one pin per run")
	var digests: Dictionary = {}
	for key: String in PINS:
		var pin: Dictionary = PINS[key]
		var digest: String = pin.get("digest", "")
		assert_eq(digest.length(), 64, "%s holds a sha256 hex digest" % key)
		digests[digest] = true
	assert_eq(digests.size(), 4, "the four runs read differently")
