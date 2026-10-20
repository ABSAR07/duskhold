extends SceneTree
## Headless per-frame cost of ONE view's `_process` on the stress shape (PLAT-01, plan 04-24): the
## before/after instrument of plans 04-25 to 04-27, which port the per-frame view fills to C++. It
## builds the stress shape exactly as step_attribution.gd does (`build_context("full", 300)`: every
## plot built, the night started, the king parked), adds one view to the tree with its own
## processing off, binds it, and times the view's `_process` by hand on every frame of a fixed 1/144
## s clock (the stress night's measured rate) after an untimed warm-up. Each frame the simulation
## advances first (`ctx.advance`), then the view runs, so the view sees a moving crowd.
## The dummy renderer draws nothing and a MultiMesh reads back zeros there, so this measures script
## and buffer-building work only, never a frame time; the real-window ablation (view_ablation.gd)
## and tools/stress.sh remain the judges of the budget. It reads only: it builds its own RunContext
## and writes nothing but stdout. Local only, never CI; tools/ is excluded from the export.
##
## `--view=puffs` has no context: a DeathPuffBatch (the ring plan 04-26 ports, review IN-08) is
## given one spawn and one refresh per frame, timed together (the per-death scan and the per-frame
## scan), at a clock of frame index times 1/144 s, the puff origin stepping 0.5 m along x and
## wrapping every 64 puffs. About 87 puffs stand once the ring is warm (0.6 s at 144 frames a
## second).
##
## Launch:
##   bash tools/godot.sh --headless --path . -s res://tools/stress/view_fill_bench.gd -- \
##       --view=arrows
## Arguments (everything after `--`; anything else prints VIEW_FILL_BENCH_USAGE and exits 64):
##   --view=<arrows|enemies|units|puffs>   required
##   --warmup=<0..4320>                    untimed frames before the timed ones; default 1440
##   --frames=<1..4320>                    timed frames; default 720
## Output, one line:
##   VIEW_FILL_BENCH view=<v> warmup=<n> frames=<n> mean_us=<x.xx> p95_us=<x.xx> max_us=<x.xx>
##   drawn_max=<n>   (drawn_max: the most instances one timed frame drew; arrows, enemies, units
##   or puffs)

const Attribution := preload("res://tools/stress/step_attribution.gd")

const EXIT_USAGE: int = 64
const VIEW_ARROWS := "arrows"
const VIEW_ENEMIES := "enemies"
const VIEW_UNITS := "units"
const VIEW_PUFFS := "puffs"
const VIEWS: Array[String] = [VIEW_ARROWS, VIEW_ENEMIES, VIEW_UNITS, VIEW_PUFFS]
const MAX_FRAMES: int = 4320
const DEFAULT_WARMUP: int = 1440
const DEFAULT_FRAMES: int = 720
const FLAG_VIEW := "--view="
const FLAG_WARMUP := "--warmup="
const FLAG_FRAMES := "--frames="
## The stress night's measured frame rate.
const FRAME_DELTA: float = 1.0 / 144.0
const STRESS_VARIANT := "full"
const STRESS_ENEMIES: int = 300
const PUFF_STEP_M: float = 0.5
const PUFF_WRAP: int = 64
const PUFF_HEIGHT: float = 0.8


## Parses the user arguments. Returns {error, view, warmup, frames}; `error` is "" when every
## argument passed the allowlist, else a one-line reason. `view` stays "" when it was not given.
static func parse_args(args: PackedStringArray) -> Dictionary:
	var parsed: Dictionary = {
		"error": "",
		"view": "",
		"warmup": DEFAULT_WARMUP,
		"frames": DEFAULT_FRAMES,
	}
	for arg: String in args:
		var failure: String = ""
		if arg.begins_with(FLAG_VIEW):
			failure = _read_view(parsed, arg.trim_prefix(FLAG_VIEW))
		elif arg.begins_with(FLAG_WARMUP):
			failure = _read_bounded(parsed, "warmup", arg.trim_prefix(FLAG_WARMUP), 0, MAX_FRAMES)
		elif arg.begins_with(FLAG_FRAMES):
			failure = _read_bounded(parsed, "frames", arg.trim_prefix(FLAG_FRAMES), 1, MAX_FRAMES)
		else:
			failure = "unknown argument '%s'" % arg
		if not failure.is_empty():
			parsed["error"] = failure
			return parsed
	if String(parsed["view"]).is_empty():
		parsed["error"] = "--view is required, one of %s" % ", ".join(VIEWS)
	return parsed


## Runs the bench for `parsed` (a parse_args result without an error) and returns the output line.
## `host` is the node the view is added to, so slashes and models behave as in play.
static func run_bench(parsed: Dictionary, host: Node) -> String:
	var view_name: String = parsed["view"]
	var warmup: int = parsed["warmup"]
	var frames: int = parsed["frames"]
	var micros: PackedFloat64Array = PackedFloat64Array()
	var drawn_max: int = 0
	if view_name == VIEW_PUFFS:
		var puffs: DeathPuffBatch = DeathPuffBatch.new()
		host.add_child(puffs)
		puffs.set_process(false)
		puffs.setup_puffs()
		for frame: int in range(warmup + frames):
			var started: int = Time.get_ticks_usec()
			_puff_frame(puffs, frame)
			var spent: int = Time.get_ticks_usec() - started
			if frame >= warmup:
				micros.append(float(spent))
				drawn_max = maxi(drawn_max, puffs.count())
		puffs.free()
	else:
		var ctx: RunContext = Attribution.build_context(STRESS_VARIANT, STRESS_ENEMIES)
		var view: Node3D = _make_view(view_name)
		host.add_child(view)
		view.set_process(false)
		view.call("bind_run", ctx, null)
		for frame: int in range(warmup + frames):
			ctx.king.report_position(Attribution.KING_PARK)
			ctx.advance(FRAME_DELTA)
			var started: int = Time.get_ticks_usec()
			view.call("_process", FRAME_DELTA)
			var spent: int = Time.get_ticks_usec() - started
			if frame >= warmup:
				micros.append(float(spent))
				drawn_max = maxi(drawn_max, _drawn_of(view_name, view))
		view.free()
	return (
		(
			"VIEW_FILL_BENCH view=%s warmup=%d frames=%d mean_us=%.2f p95_us=%.2f max_us=%.2f"
			+ " drawn_max=%d"
		)
		% [
			view_name,
			warmup,
			frames,
			FrameReport.mean(micros),
			FrameReport.percentile(micros, 0.95),
			FrameReport.maximum(micros),
			drawn_max,
		]
	)


static func _make_view(view_name: String) -> Node3D:
	match view_name:
		VIEW_ARROWS:
			return ProjectileVfx.new()
		VIEW_ENEMIES:
			return EnemyViews.new()
	return UnitViews.new()


static func _drawn_of(view_name: String, view: Node3D) -> int:
	match view_name:
		VIEW_ARROWS:
			return (view as ProjectileVfx).arrow_count()
		VIEW_ENEMIES:
			return (view as EnemyViews).view_count()
	return (view as UnitViews).view_count()


## One frame of the puff ring: a spawn and a refresh at the frame's clock.
static func _puff_frame(puffs: DeathPuffBatch, frame: int) -> void:
	var now_s: float = float(frame) * FRAME_DELTA
	var origin: Vector3 = Vector3(float(frame % PUFF_WRAP) * PUFF_STEP_M, PUFF_HEIGHT, 0.0)
	puffs.spawn(origin, now_s, Color.WHITE)
	puffs.refresh(now_s)


static func _read_view(parsed: Dictionary, text: String) -> String:
	if not VIEWS.has(text):
		return "--view must be one of %s, got '%s'" % [", ".join(VIEWS), text]
	parsed["view"] = text
	return ""


## Stores the integer `text` under `key` when it lies in `lower`..`upper`; returns "" or the reason.
static func _read_bounded(
	parsed: Dictionary, key: String, text: String, lower: int, upper: int
) -> String:
	if not text.is_valid_int():
		return "--%s must be an integer, got '%s'" % [key, text]
	var value: int = text.to_int()
	if value < lower or value > upper:
		return "--%s must be between %d and %d, got %d" % [key, lower, upper, value]
	parsed[key] = value
	return ""


func _initialize() -> void:
	var parsed: Dictionary = parse_args(OS.get_cmdline_user_args())
	var error: String = parsed["error"]
	if not error.is_empty():
		printerr("VIEW_FILL_BENCH_USAGE %s" % error)
		printerr(
			(
				"usage: --view=<%s> [--warmup=<0..%d>] [--frames=<1..%d>]"
				% ["|".join(VIEWS), MAX_FRAMES, MAX_FRAMES]
			)
		)
		quit(EXIT_USAGE)
		return
	print(run_bench(parsed, root))
	quit(0)
