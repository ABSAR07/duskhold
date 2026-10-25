extends GutTest
## PLAT-01 (plan 04-27, exact_port_rules 7): the friendly unit bodies and their hurt-only bars
## pinned on the GDScript per-unit fill that shipped before any native unit-view code existed.
## Three runs drive a UnitViews frame by frame: the 300-enemy stress night (the stress shape of the
## bench: every plot built, the king parked, fifty footmen walking and fighting under varying
## blends; nobody is hurt there, so it pins bodies), the same night with the army hit, restored and
## one unit killed (so it pins the bars) and the army replay scenario (two frames per simulation
## tick; a Barracks and an Archery squad; the walls scenario fields no squad and would pin
## nothing). Frame deltas cycle through six
## unequal values, so the interpolation blend varies. After every frame one SHA-256 per run is fed
## the view and bar counts and then, for the child batch "Units_<def id>" of every unit type of the
## map in map order (when it exists) and for "Bars", the batch's count and its whole CPU mirror
## (instances, custom data and the stale tail past the count). Headless every type wears the
## capsule after the one retry of the first frame, which is fine: before and after agree. The pins
## were computed on the GDScript fill and are never edited: the native fill must reproduce them
## unchanged. The view only reads the run, so the golden digests do not move (the replay wrappers
## prove it).
##
## Gap round G-05-2 (owner UAT decision 2026-10-25): every health and damage number is 100 times
## larger; this test's own amounts moved with them so it checks what it checked before. The pins
## were not edited: their inputs moved with the scale (or, for the wall decision, keep the Phase 4
## numbers the pins were computed on).

const Probe := preload("res://tools/stress/step_attribution.gd")
const DELTAS: Array[float] = [1.0 / 144.0, 1.0 / 60.0, 1.0 / 240.0, 0.021, 1.0 / 30.0, 0.0047]
const STRESS_VARIANT := "full"
const STRESS_ENEMIES: int = 300
const STRESS_FRAMES: int = 2400
const FRAMES_PER_TICK: int = 2
## The hurt run: a unit takes a hit every HURT_EVERY frames, the dawn restore comes twice and one
## unit is killed outright, so the bars show, fill, hide and drop out under the same varying blends.
const HURT_EVERY: int = 6
const RESTORE_FRAMES: Array[int] = [700, 1500]
const KILL_FRAME: int = 1000
const KILL_DAMAGE: int = 9900
## D-10's unit bar: the stress night must put at least this many friendly units on screen at once.
const STRESS_VIEW_FLOOR: int = 50
const PINS: Dictionary = {
	"stress":
	{
		"digest": "1a7a6269efd0efd128f3853e34ec2186d523638d64922d754731694eac005220",
		"frames": 2400,
		"most_views": 50,
		"most_bars": 0,
	},
	"army":
	{
		"digest": "5faf6ada627cc485769592cac440b580c7ce1c1bf041a2fd98a6f2086f2f52ce",
		"frames": 2706,
		"most_views": 8,
		"most_bars": 2,
	},
	"hurt":
	{
		"digest": "f5d6b012ccf861f8c40d10d41c7d0feaeaf94b88c537709d98180692e339c8c4",
		"frames": 2400,
		"most_views": 50,
		"most_bars": 50,
	},
}


## Drives one UnitViews and hashes what it draws after every frame.
class Driver:
	extends RefCounted

	var views: UnitViews
	var frames: int = 0
	var most_views: int = 0
	var most_bars: int = 0
	var _context: HashingContext = HashingContext.new()
	var _bound: bool = false
	var _batch_names: Array[String] = []

	func _init(view: UnitViews) -> void:
		views = view
		_context.start(HashingContext.HASH_SHA256)

	## The replay observer: binds on the first call, then drives FRAMES_PER_TICK frames.
	func on_tick(ctx: RunContext) -> void:
		if not _bound:
			bind_first(ctx)
		for _frame: int in range(FRAMES_PER_TICK):
			draw_frame()

	func bind_first(ctx: RunContext) -> void:
		views.bind_run(ctx, null)
		_bound = true
		for def: UnitDef in ctx.map.units:
			_batch_names.append("Units_%s" % def.id)
		_batch_names.append("Bars")

	## One frame of the fill, then everything it drew goes into the hash.
	func draw_frame() -> void:
		views._process(0.0)
		var drawn: int = views.view_count()
		var bars: int = views.bar_count()
		most_views = maxi(most_views, drawn)
		most_bars = maxi(most_bars, bars)
		_context.update(PackedInt64Array([drawn, bars]).to_byte_array())
		for batch_name: String in _batch_names:
			var batch: CrowdBatch = views.get_node_or_null(batch_name) as CrowdBatch
			if batch == null:
				continue
			_context.update(PackedInt64Array([batch.count()]).to_byte_array())
			_context.update(batch.mirror().to_byte_array())
		frames += 1

	func result() -> Dictionary:
		return {
			"digest": _context.finish().hex_encode(),
			"frames": frames,
			"most_views": most_views,
			"most_bars": most_bars,
		}


func _new_driver() -> Driver:
	var views: UnitViews = UnitViews.new()
	add_child_autofree(views)
	views.set_process(false)
	return Driver.new(views)


## {digest, frames, most_views, most_bars} of `STRESS_FRAMES` frames of the stress night.
func _stress_run() -> Dictionary:
	var ctx: RunContext = Probe.build_context(STRESS_VARIANT, STRESS_ENEMIES)
	var driver: Driver = _new_driver()
	driver.bind_first(ctx)
	for frame: int in range(STRESS_FRAMES):
		var delta: float = DELTAS[frame % DELTAS.size()]
		ctx.king.report_position(Probe.KING_PARK)
		ctx.advance(delta)
		driver.draw_frame()
	return driver.result()


## The same fields for the stress night with the army hurt: the hits, restores and the kill of the
## HURT constants, so the bar batch is exercised far past what the plain night does.
func _hurt_run() -> Dictionary:
	var ctx: RunContext = Probe.build_context(STRESS_VARIANT, STRESS_ENEMIES)
	var driver: Driver = _new_driver()
	driver.bind_first(ctx)
	for frame: int in range(STRESS_FRAMES):
		var delta: float = DELTAS[frame % DELTAS.size()]
		ctx.king.report_position(Probe.KING_PARK)
		ctx.advance(delta)
		var ids: Array[int] = ctx.squads.get_units().ids()
		if not ids.is_empty() and frame % HURT_EVERY == 0:
			ctx.squads.damage_unit(ids[(frame / HURT_EVERY) % ids.size()], 100, &"test")
		if frame == KILL_FRAME and not ids.is_empty():
			ctx.squads.damage_unit(ids[ids.size() / 2], KILL_DAMAGE, &"test")
		if RESTORE_FRAMES.has(frame):
			ctx.squads.restore_for_dawn()
		driver.draw_frame()
	return driver.result()


## The same fields for a replay scenario run at its default seed.
func _replay_run(scenario: StringName) -> Dictionary:
	var driver: Driver = _new_driver()
	ReplayScenarios.run(scenario, ReplayScenarios.default_seed(scenario), driver.on_tick)
	return driver.result()


func _assert_pinned(run: Dictionary, key: String, label: String) -> void:
	var pin: Dictionary = PINS.get(key, {})
	assert_eq(run["digest"], pin.get("digest", ""), "%s: the mirrors, the bars, the counts" % label)
	assert_eq(run["frames"], pin.get("frames", -1), "%s: frames driven" % label)
	assert_eq(run["most_views"], pin.get("most_views", -1), "%s: the most units drawn" % label)
	assert_eq(run["most_bars"], pin.get("most_bars", -1), "%s: the most bars drawn" % label)


func test_the_stress_night_fill_is_pinned() -> void:
	var run: Dictionary = _stress_run()
	_assert_pinned(run, "stress", "the stress night")
	assert_gte(int(run["most_views"]), STRESS_VIEW_FLOOR, "D-10's fifty units were reached")


func test_the_hurt_stress_night_fill_is_pinned() -> void:
	var run: Dictionary = _hurt_run()
	_assert_pinned(run, "hurt", "the hurt stress night")
	assert_gte(int(run["most_bars"]), 1, "the hits showed some bar")


func test_the_army_replay_fill_is_pinned() -> void:
	var run: Dictionary = _replay_run(&"army")
	_assert_pinned(run, "army", "the army replay")
	assert_gte(int(run["most_views"]), 1, "the army replay drew some unit")


func test_the_pins_are_present_and_differ() -> void:
	assert_eq(PINS.size(), 3, "one pin per run")
	var digests: Dictionary = {}
	for key: String in PINS:
		var pin: Dictionary = PINS[key]
		var digest: String = pin.get("digest", "")
		assert_eq(digest.length(), 64, "%s holds a sha256 hex digest" % key)
		digests[digest] = true
	assert_eq(digests.size(), 3, "the three runs read differently")
