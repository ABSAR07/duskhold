extends SceneTree
## Headless step-cost bench at crowd scale (PLAT-01, RESEARCH F1). It builds the shipped prototype
## map with every plot built at tier 1, lets the squads fill by day, starts the night and spawns
## grunts evenly over the three spawn points, then times the next `steps` calls of
## RunContext.step() while they all march on the castle. It prints one line:
##   STEP_BENCH enemies=<n> steps=<n> mean_ms=<x.xx> p95_ms=<x.xx> max_ms=<x.xx>
## The number is recorded evidence on the dev machine, never a gate and never run in CI; the dummy
## renderer draws nothing, so it measures the simulation alone.
##
## With --rebuilds=<n> (n above 0) it then also times the synchronous grid and castle-field rebuild
## a wall break causes (plan 04-06's accepted one-step hitch, RESEARCH F4 and A4): on the same map
## it breaks the first n intact wall segments one at a time, calls Pathing.refresh() directly
## between two clock reads, and prints
##   STEP_BENCH_REBUILD cells=<grid width times height> rebuilds=<n> mean_ms=<x.xx> max_ms=<x.xx>
## A rebuild that does not raise Pathing.field_version() by exactly one prints
## STEP_BENCH_REBUILD_FAILED and exits 1.
##
## Launch (tools/ is excluded from the export):
##   bash tools/godot.sh --headless --path . -s res://tools/stress/step_bench.gd -- \
##       --enemies=300 --steps=30 [--rebuilds=16]
## Arguments (everything after `--`; anything else is a usage error):
##   --enemies=<1..1000>   grunts to spawn; default 300
##   --steps=<1..600>      timed steps; default 30
##   --rebuilds=<0..64>    wall-break rebuilds to time after the steps; default 0 (none)
## A usage error prints STEP_BENCH_USAGE <reason> and exits 64.

const EXIT_USAGE: int = 64
const DEFAULT_ENEMIES: int = 300
const DEFAULT_STEPS: int = 30
const MAX_ENEMIES: int = 1000
const MAX_STEPS: int = 600
const MAX_REBUILDS: int = 64
const MAP_PATH: String = "res://data/maps/prototype_map.tres"
const TUNING_PATH: String = "res://data/tuning/loop_tuning.tres"
const SPAWN_SEED: int = 1
## The castle must outlive the timed steps whatever the machine does; a bench run is no balance run.
const CASTLE_HEALTH: int = 10000000
const GRUNT_ID: StringName = &"grunt"
const FLAG_ENEMIES: String = "--enemies="
const FLAG_STEPS: String = "--steps="
const FLAG_REBUILDS: String = "--rebuilds="
const EXIT_FAILED: int = 1
const MICROS_PER_MS: float = 1000.0


## Parses the user arguments. Returns {error, enemies, steps, rebuilds}; `error` is "" when every
## argument passed the allowlist, else a one-line reason.
static func parse_args(args: PackedStringArray) -> Dictionary:
	var parsed: Dictionary = {
		"error": "", "enemies": DEFAULT_ENEMIES, "steps": DEFAULT_STEPS, "rebuilds": 0
	}
	for arg: String in args:
		var failure: String = ""
		if arg.begins_with(FLAG_ENEMIES):
			failure = _read_bounded(
				parsed, "enemies", arg.trim_prefix(FLAG_ENEMIES), 1, MAX_ENEMIES
			)
		elif arg.begins_with(FLAG_STEPS):
			failure = _read_bounded(parsed, "steps", arg.trim_prefix(FLAG_STEPS), 1, MAX_STEPS)
		elif arg.begins_with(FLAG_REBUILDS):
			failure = _read_bounded(
				parsed, "rebuilds", arg.trim_prefix(FLAG_REBUILDS), 0, MAX_REBUILDS
			)
		else:
			failure = "unknown argument '%s'" % arg
		if not failure.is_empty():
			parsed["error"] = failure
			return parsed
	return parsed


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


## The p95 of an ascending-sorted list (nearest rank).
static func percentile_95(sorted_ms: PackedFloat64Array) -> float:
	if sorted_ms.is_empty():
		return 0.0
	var rank: int = clampi(ceili(0.95 * float(sorted_ms.size())) - 1, 0, sorted_ms.size() - 1)
	return sorted_ms[rank]


func _initialize() -> void:
	var parsed: Dictionary = parse_args(OS.get_cmdline_user_args())
	var error: String = parsed["error"]
	if not error.is_empty():
		printerr("STEP_BENCH_USAGE %s" % error)
		printerr(
			(
				"usage: --enemies=<1..%d> --steps=<1..%d> [--rebuilds=<0..%d>]"
				% [MAX_ENEMIES, MAX_STEPS, MAX_REBUILDS]
			)
		)
		quit(EXIT_USAGE)
		return
	var ctx: RunContext = _build(parsed["enemies"])
	var samples: PackedFloat64Array = _time_steps(ctx, parsed["steps"])
	var sorted_ms: PackedFloat64Array = samples.duplicate()
	sorted_ms.sort()
	var total: float = 0.0
	for sample: float in samples:
		total += sample
	print(
		(
			"STEP_BENCH enemies=%d steps=%d mean_ms=%.2f p95_ms=%.2f max_ms=%.2f"
			% [
				parsed["enemies"],
				parsed["steps"],
				total / float(samples.size()),
				percentile_95(sorted_ms),
				sorted_ms[sorted_ms.size() - 1],
			]
		)
	)
	if int(parsed["rebuilds"]) > 0:
		quit(_probe_rebuilds(ctx, parsed["rebuilds"]))
		return
	quit(0)


## Builds the night and spawns the grunts, ready for the timed steps.
func _build(enemy_count: int) -> RunContext:
	var map: MapConfig = (load(MAP_PATH) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	map.castle_max_health = CASTLE_HEALTH
	var no_nights: Array[NightDef] = []
	map.nights = no_nights
	var tuning: LoopTuning = load(TUNING_PATH) as LoopTuning
	var ctx: RunContext = RunContext.new(map, tuning, 1)
	for spot_id: StringName in ctx.buildings.spot_ids():
		ctx.buildings.apply_next_tier(spot_id)
	ctx.step()
	ctx.commands.submit(StartNightIntent.new())
	_spawn_grunts(ctx, enemy_count)
	return ctx


## The milliseconds of each of `step_count` timed steps of the marching night.
func _time_steps(ctx: RunContext, step_count: int) -> PackedFloat64Array:
	var samples: PackedFloat64Array = PackedFloat64Array()
	for _step_index: int in range(step_count):
		var started: int = Time.get_ticks_usec()
		ctx.step()
		samples.append(float(Time.get_ticks_usec() - started) / MICROS_PER_MS)
	return samples


## `count` grunts dealt evenly over the spawn points, each scattered within its point's radius.
func _spawn_grunts(ctx: RunContext, count: int) -> void:
	var grunt: EnemyDef = ctx.map.find_enemy(GRUNT_ID)
	var points: Array[SpawnPointDef] = ctx.map.spawn_points
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SPAWN_SEED
	for index: int in range(count):
		var point: SpawnPointDef = points[index % points.size()]
		var scatter: float = point.scatter_radius
		var offset: Vector2 = Vector2(
			rng.randf_range(-scatter, scatter), rng.randf_range(-scatter, scatter)
		)
		ctx.night.get_enemies().spawn(grunt, Vector2(point.position.x, point.position.z) + offset)


## Breaks the first `wanted` intact wall segments one at a time and times the rebuild the next
## step would run, `Pathing.refresh()`, around two clock reads. Prints the STEP_BENCH_REBUILD line
## and returns the exit code; a rebuild that does not raise field_version() by one is a failure.
func _probe_rebuilds(ctx: RunContext, wanted: int) -> int:
	var pathing: Pathing = ctx.night.get_pathing()
	pathing.refresh()
	var version: int = pathing.field_version()
	var times: PackedFloat64Array = PackedFloat64Array()
	for segment: int in range(ctx.walls.segment_count()):
		if times.size() >= wanted:
			break
		if not ctx.walls.is_intact(segment):
			continue
		ctx.walls.damage_segment(segment, ctx.walls.health_of(segment))
		var started: int = Time.get_ticks_usec()
		pathing.refresh()
		times.append(float(Time.get_ticks_usec() - started) / MICROS_PER_MS)
		version += 1
		if pathing.field_version() != version:
			printerr("STEP_BENCH_REBUILD_FAILED segment=%d version=%d" % [segment, version])
			return EXIT_FAILED
	if times.size() < wanted:
		printerr(
			(
				"STEP_BENCH_REBUILD_FAILED only %d intact segments for %d rebuilds"
				% [times.size(), wanted]
			)
		)
		return EXIT_FAILED
	var total: float = 0.0
	var worst: float = 0.0
	for sample: float in times:
		total += sample
		worst = maxf(worst, sample)
	print(
		(
			"STEP_BENCH_REBUILD cells=%d rebuilds=%d mean_ms=%.2f max_ms=%.2f"
			% [
				pathing.grid().width() * pathing.grid().height(),
				times.size(),
				total / float(times.size()),
				worst,
			]
		)
	)
	return 0
