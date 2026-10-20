extends GutTest
## PLAT-01 (plan 04-25, exact_port_rules 7): the arrow batch's per-frame fill pinned on the
## GDScript flight that shipped before any native view code existed. Three runs drive a
## ProjectileVfx frame by frame: the 300-enemy stress night (the stress shape of the bench: every
## plot built, the king parked) and the walls and army replay scenarios (two frames per simulation
## tick). Frame deltas cycle through six unequal values, so the flight sees the clock a real
## window gives it. After every frame one SHA-256 per run is fed the arrow count and live count,
## the whole CPU mirror of the child batch "Arrows" (instances, colours and the stale tail past
## the count) and the launch points of the arrows drawn. The pins were computed on the GDScript
## flight and are never edited: the native flight must reproduce them unchanged. The vfx only
## reads the run, so the golden digests do not move (the replay wrappers prove it).

const Probe := preload("res://tools/stress/step_attribution.gd")
const DELTAS: Array[float] = [1.0 / 144.0, 1.0 / 60.0, 1.0 / 240.0, 0.021, 1.0 / 30.0, 0.0047]
const STRESS_VARIANT := "full"
const STRESS_ENEMIES: int = 300
const STRESS_FRAMES: int = 2400
const FRAMES_PER_TICK: int = 2
## D-10's arrow bar: the stress night must put at least this many arrows in the air at once.
const STRESS_ARROW_FLOOR: int = 200
const PINS: Dictionary = {
	"stress":
	{
		"digest": "870f22e8c574d2a149f4aebbf88c883c50df310d3fcd26a45dd04b3a0dff0b57",
		"frames": 2400,
		"most_arrows": 507,
	},
	"walls":
	{
		"digest": "6aa13d88b607e4bd3cb0ff82976f1bce4f94156b2f7e3c6f60359891366622dc",
		"frames": 3922,
		"most_arrows": 2,
	},
	"army":
	{
		"digest": "0ded61ddad9e92a69c54b86eb16dccb9b8b1e14a79d9c7f2331d16f80010e6bc",
		"frames": 2706,
		"most_arrows": 9,
	},
}


## Drives one ProjectileVfx and hashes what it draws after every frame.
class Driver:
	extends RefCounted

	var vfx: ProjectileVfx
	var frames: int = 0
	var most_arrows: int = 0
	var _context: HashingContext = HashingContext.new()
	var _bound: bool = false

	func _init(view: ProjectileVfx) -> void:
		vfx = view
		_context.start(HashingContext.HASH_SHA256)

	## The replay observer: binds on the first call, then drives FRAMES_PER_TICK frames.
	func on_tick(ctx: RunContext) -> void:
		if not _bound:
			vfx.bind_run(ctx, null)
			_bound = true
		for _frame: int in range(FRAMES_PER_TICK):
			draw_frame(DELTAS[frames % DELTAS.size()])

	## One frame of the flight, then everything it drew goes into the hash.
	func draw_frame(delta: float) -> void:
		vfx._process(delta)
		var batch: CrowdBatch = vfx.get_node("Arrows") as CrowdBatch
		var drawn: int = vfx.arrow_count()
		most_arrows = maxi(most_arrows, drawn)
		_context.update(PackedInt64Array([drawn, vfx.live_count()]).to_byte_array())
		_context.update(batch.mirror().to_byte_array())
		var launches: PackedVector3Array = PackedVector3Array()
		for index: int in range(drawn):
			launches.append(vfx.arrow_launch_at(index))
		if launches.size() > 0:
			_context.update(launches.to_byte_array())
		frames += 1

	func bind_first(ctx: RunContext) -> void:
		vfx.bind_run(ctx, null)
		_bound = true

	func result() -> Dictionary:
		return {
			"digest": _context.finish().hex_encode(), "frames": frames, "most_arrows": most_arrows
		}


func _new_driver() -> Driver:
	var view: ProjectileVfx = ProjectileVfx.new()
	add_child_autofree(view)
	view.set_process(false)
	return Driver.new(view)


## {digest, frames, most_arrows} of `STRESS_FRAMES` frames of the stress night.
func _stress_run() -> Dictionary:
	var ctx: RunContext = Probe.build_context(STRESS_VARIANT, STRESS_ENEMIES)
	var driver: Driver = _new_driver()
	driver.bind_first(ctx)
	for frame: int in range(STRESS_FRAMES):
		var delta: float = DELTAS[frame % DELTAS.size()]
		ctx.king.report_position(Probe.KING_PARK)
		ctx.advance(delta)
		driver.draw_frame(delta)
	return driver.result()


## {digest, frames, most_arrows} of a replay scenario run at its default seed.
func _replay_run(scenario: StringName) -> Dictionary:
	var driver: Driver = _new_driver()
	ReplayScenarios.run(scenario, ReplayScenarios.default_seed(scenario), driver.on_tick)
	return driver.result()


func test_the_stress_night_fill_is_pinned() -> void:
	var run: Dictionary = _stress_run()
	var pin: Dictionary = PINS.get("stress", {})
	assert_eq(run["digest"], pin.get("digest", ""), "the stress night's arrow batch")
	assert_eq(run["frames"], pin.get("frames", -1), "frames driven")
	assert_eq(run["most_arrows"], pin.get("most_arrows", -1), "the most arrows in the air")
	assert_gte(int(run["most_arrows"]), STRESS_ARROW_FLOOR, "D-10's 200 arrows were reached")


func test_the_walls_replay_fill_is_pinned() -> void:
	var run: Dictionary = _replay_run(&"walls")
	var pin: Dictionary = PINS.get("walls", {})
	assert_eq(run["digest"], pin.get("digest", ""), "the walls replay's arrow batch")
	assert_eq(run["frames"], pin.get("frames", -1), "frames driven")
	assert_eq(run["most_arrows"], pin.get("most_arrows", -1), "the most arrows in the air")
	assert_gte(int(run["most_arrows"]), 1, "the walls replay shot some arrow")


func test_the_army_replay_fill_is_pinned() -> void:
	var run: Dictionary = _replay_run(&"army")
	var pin: Dictionary = PINS.get("army", {})
	assert_eq(run["digest"], pin.get("digest", ""), "the army replay's arrow batch")
	assert_eq(run["frames"], pin.get("frames", -1), "frames driven")
	assert_eq(run["most_arrows"], pin.get("most_arrows", -1), "the most arrows in the air")
	assert_gte(int(run["most_arrows"]), 1, "the army replay shot some arrow")


func test_the_pins_are_present_and_differ() -> void:
	assert_eq(PINS.size(), 3, "one pin per run")
	var digests: Dictionary = {}
	for key: String in PINS:
		var pin: Dictionary = PINS[key]
		var digest: String = pin.get("digest", "")
		assert_eq(digest.length(), 64, "%s holds a sha256 hex digest" % key)
		digests[digest] = true
	assert_eq(digests.size(), 3, "the three runs read differently")
