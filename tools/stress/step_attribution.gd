extends SceneTree
## Headless step attribution of the stress-night shape (PLAT-01, plan 04-20): where the 4 to 5 ms
## of one RunContext.step() go, by the variant method of 04-FRAME-REPORT.md. It builds the stress
## shape exactly as `step_bench.gd --map=stress` does (plan 04-15: the tools stress map with every
## night group's count set to enemies / 4, the king def deep-copied with max_health 10000000 and the
## king reported at (0, 14) before every step, every chosen plot built once, StartNightIntent, the
## warm-up steps untimed) in four variants that differ ONLY in which build plots are bought:
##   full          every plot (the gate wall, the towers and the barracks)
##   no_towers     the stress_tower plots left unbuilt
##   no_squads     the stress_barracks plots left unbuilt (no squad unit ever stands)
##   enemies_only  neither (the gate wall and the king as in full)
## Nothing under simulation/ or data/ changes: the probe uses public API only (which plots are
## built, where the king is parked) on its own RunContexts, and writes nothing but its output file.
##
## Each variant runs `--runs` times, interleaved (all four variants once, then again) so machine
## drift hits them alike. A run's value is the mean of its timed ctx.step() calls in milliseconds;
## a variant's value is the median of its runs. Output (printed and written to --out), in order:
##   VARIANT <name> mean_ms=<x.xx>              one per variant, in the order above
##   PHASE total ms=<x.xx>                      the full variant
##   PHASE towers ms=<x.xx>                     full minus no_towers
##   PHASE squads ms=<x.xx>                     full minus no_squads
##   PHASE enemies ms=<x.xx>                    enemies_only
##   PHASE rest ms=<x.xx>                       total minus towers minus squads minus enemies
##   STEP_ATTRIBUTION_OK runs=<n> enemies=<n> warmup=<n> steps=<n>
## PHASE values are ablation deltas, not exclusive phase timings: the pieces interact (a tower
## kills enemies a squad would have fought, a squad draws enemies off the gate), so they need not
## add up, and `rest` can come out negative; read them as "what the step costs more with this
## built". The arithmetic is phases_of(), a static function the test calls.
##
## Launch (tools/ is excluded from the export; plan 04-21 reruns this line and quotes it):
##   bash tools/godot.sh --headless --path . -s res://tools/stress/step_attribution.gd -- \
##       --runs=3 --out=build/bench/attribution.txt
## Arguments (everything after `--`; anything else prints STEP_ATTRIBUTION_USAGE and exits 64):
##   --enemies=<4..1000>   the enemy total over the four night groups, a multiple of 4; default 300
##   --warmup=<0..900>     untimed steps before the timed ones; default 300
##   --steps=<1..600>      timed steps per run; default 300
##   --runs=<1..9>         runs per variant; default 3
##   --out=<path>          a .txt file under build/ (ReplayCli.safe_dir); default
##                         build/bench/attribution.txt
## The number is recorded evidence on the dev machine, never a gate and never run in CI; the dummy
## renderer draws nothing, so it measures the simulation alone.

const ReplayCli := preload("res://tools/replay/replay_cli.gd")

const EXIT_USAGE: int = 64
const EXIT_FAILED: int = 1
const GROUPS: int = 4
const MIN_ENEMIES: int = 4
const MAX_ENEMIES: int = 1000
const DEFAULT_ENEMIES: int = 300
const MAX_WARMUP: int = 900
const DEFAULT_WARMUP: int = 300
const MIN_STEPS: int = 1
const MAX_STEPS: int = 600
const DEFAULT_STEPS: int = 300
const MIN_RUNS: int = 1
const MAX_RUNS: int = 9
const DEFAULT_RUNS: int = 3
const OUT_ROOT := "res://build"
const DEFAULT_OUT := "res://build/bench/attribution.txt"
const OUT_SUFFIX := ".txt"
const FLAG_ENEMIES := "--enemies="
const FLAG_WARMUP := "--warmup="
const FLAG_STEPS := "--steps="
const FLAG_RUNS := "--runs="
const FLAG_OUT := "--out="
const STRESS_MAP_PATH := "res://tools/stress/stress_map.tres"
const KING_PATH := "res://data/king/king.tres"
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
## The stress shape's king parking spot and health pool (the stress night's own values).
const KING_PARK := Vector2(0.0, 14.0)
const KING_HEALTH: int = 10000000
const MICROS_PER_MS: float = 1000.0
const VARIANT_FULL: String = "full"
const VARIANT_NO_TOWERS: String = "no_towers"
const VARIANT_NO_SQUADS: String = "no_squads"
const VARIANT_ENEMIES_ONLY: String = "enemies_only"
const VARIANTS: Array[String] = [
	VARIANT_FULL, VARIANT_NO_TOWERS, VARIANT_NO_SQUADS, VARIANT_ENEMIES_ONLY
]
## The building ids of the stress map a variant leaves unbuilt.
const TOWER_BUILDING: StringName = &"stress_tower"
const BARRACKS_BUILDING: StringName = &"stress_barracks"


## Parses the user arguments. Returns {error, enemies, warmup, steps, runs, out}; `error` is ""
## when every argument passed the allowlist, else a one-line reason. `out` is a res:// path under
## build/.
static func parse_args(args: PackedStringArray) -> Dictionary:
	var parsed: Dictionary = {
		"error": "",
		"enemies": DEFAULT_ENEMIES,
		"warmup": DEFAULT_WARMUP,
		"steps": DEFAULT_STEPS,
		"runs": DEFAULT_RUNS,
		"out": DEFAULT_OUT,
	}
	for arg: String in args:
		var failure: String = ""
		if arg.begins_with(FLAG_ENEMIES):
			failure = _read_enemies(parsed, arg.trim_prefix(FLAG_ENEMIES))
		elif arg.begins_with(FLAG_WARMUP):
			failure = _read_bounded(parsed, "warmup", arg.trim_prefix(FLAG_WARMUP), 0, MAX_WARMUP)
		elif arg.begins_with(FLAG_STEPS):
			failure = _read_bounded(
				parsed, "steps", arg.trim_prefix(FLAG_STEPS), MIN_STEPS, MAX_STEPS
			)
		elif arg.begins_with(FLAG_RUNS):
			failure = _read_bounded(parsed, "runs", arg.trim_prefix(FLAG_RUNS), MIN_RUNS, MAX_RUNS)
		elif arg.begins_with(FLAG_OUT):
			failure = _read_out(parsed, arg.trim_prefix(FLAG_OUT))
		else:
			failure = "unknown argument '%s'" % arg
		if not failure.is_empty():
			parsed["error"] = failure
			return parsed
	return parsed


## The PHASE values from the variant means (milliseconds, keyed by variant name): {total, towers,
## squads, enemies, rest}. towers and squads are what the step costs more with those plots built;
## rest is what is left of the total after the three, so it is the interaction and the unattributed
## remainder and can be negative.
static func phases_of(means: Dictionary) -> Dictionary:
	var total: float = means[VARIANT_FULL]
	var towers: float = total - float(means[VARIANT_NO_TOWERS])
	var squads: float = total - float(means[VARIANT_NO_SQUADS])
	var enemies: float = means[VARIANT_ENEMIES_ONLY]
	return {
		"total": total,
		"towers": towers,
		"squads": squads,
		"enemies": enemies,
		"rest": total - towers - squads - enemies,
	}


## The median of `values`: the middle one, or the mean of the two middle ones; 0.0 when empty.
static func median_of(values: PackedFloat64Array) -> float:
	if values.is_empty():
		return 0.0
	var sorted: PackedFloat64Array = values.duplicate()
	sorted.sort()
	@warning_ignore("integer_division")
	var middle: int = sorted.size() / 2
	if sorted.size() % 2 == 1:
		return sorted[middle]
	return (sorted[middle - 1] + sorted[middle]) / 2.0


## The output lines for the variant medians: VARIANT lines, PHASE lines, STEP_ATTRIBUTION_OK.
static func report_lines(means: Dictionary, parsed: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for variant: String in VARIANTS:
		lines.append("VARIANT %s mean_ms=%.2f" % [variant, means[variant]])
	var phases: Dictionary = phases_of(means)
	for phase: String in ["total", "towers", "squads", "enemies", "rest"]:
		lines.append("PHASE %s ms=%.2f" % [phase, phases[phase]])
	lines.append(
		(
			"STEP_ATTRIBUTION_OK runs=%d enemies=%d warmup=%d steps=%d"
			% [parsed["runs"], parsed["enemies"], parsed["warmup"], parsed["steps"]]
		)
	)
	return lines


## The stress-night context of `variant` with `enemy_total` enemies over the four groups, the king
## parked and reported, the plots of the variant built once and the night started. Built exactly
## as step_bench.gd's --map=stress shape; only the plots bought differ between variants.
static func build_context(variant: String, enemy_total: int) -> RunContext:
	var map: MapConfig = (load(STRESS_MAP_PATH) as MapConfig).duplicate_deep(
		Resource.DEEP_DUPLICATE_ALL
	)
	@warning_ignore("integer_division")
	var per_group: int = enemy_total / GROUPS
	for night: NightDef in map.nights:
		for group: SpawnGroupDef in night.groups:
			group.count = per_group
	var king_def: KingDef = (load(KING_PATH) as KingDef).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	king_def.max_health = KING_HEALTH
	var tuning: LoopTuning = load(TUNING_PATH) as LoopTuning
	var ctx: RunContext = RunContext.new(map, tuning, 1, king_def)
	var skipped: Array[StringName] = _skipped_buildings(variant)
	for spot_id: StringName in ctx.buildings.spot_ids():
		if not skipped.has(ctx.buildings.get_spot(spot_id).building_id):
			ctx.buildings.apply_next_tier(spot_id)
	ctx.king.report_position(KING_PARK)
	ctx.step()
	ctx.commands.submit(StartNightIntent.new())
	return ctx


## The mean milliseconds of `steps` timed ctx.step() calls after `warmup` untimed ones, the king
## reported at its parking spot before each.
static func run_once(variant: String, enemy_total: int, warmup: int, steps: int) -> float:
	var ctx: RunContext = build_context(variant, enemy_total)
	for _warm: int in range(warmup):
		ctx.king.report_position(KING_PARK)
		ctx.step()
	var total_us: int = 0
	for _timed: int in range(steps):
		ctx.king.report_position(KING_PARK)
		var started: int = Time.get_ticks_usec()
		ctx.step()
		total_us += Time.get_ticks_usec() - started
	return float(total_us) / MICROS_PER_MS / float(steps)


static func _skipped_buildings(variant: String) -> Array[StringName]:
	var skipped: Array[StringName] = []
	if variant == VARIANT_NO_TOWERS or variant == VARIANT_ENEMIES_ONLY:
		skipped.append(TOWER_BUILDING)
	if variant == VARIANT_NO_SQUADS or variant == VARIANT_ENEMIES_ONLY:
		skipped.append(BARRACKS_BUILDING)
	return skipped


## Stores the enemy total when it is a multiple of four in range; returns "" or the reason.
static func _read_enemies(parsed: Dictionary, text: String) -> String:
	var failure: String = _read_bounded(parsed, "enemies", text, MIN_ENEMIES, MAX_ENEMIES)
	if failure.is_empty() and int(parsed["enemies"]) % GROUPS != 0:
		return "--enemies must be a multiple of %d, got %s" % [GROUPS, text]
	return failure


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


## Stores the output path when it is a .txt file under build/; returns "" or the reason.
static func _read_out(parsed: Dictionary, text: String) -> String:
	var path: String = ReplayCli.safe_dir(text, OUT_ROOT)
	if path.is_empty() or path == OUT_ROOT or not path.ends_with(OUT_SUFFIX):
		return "--out must be a .txt file under build/, got '%s'" % text
	parsed["out"] = path
	return ""


func _initialize() -> void:
	var parsed: Dictionary = parse_args(OS.get_cmdline_user_args())
	var error: String = parsed["error"]
	if not error.is_empty():
		printerr("STEP_ATTRIBUTION_USAGE %s" % error)
		printerr(
			(
				(
					"usage: [--enemies=<%d..%d, multiple of %d>] [--warmup=<0..%d>]"
					+ " [--steps=<%d..%d>] [--runs=<%d..%d>] [--out=build/<name>.txt]"
				)
				% [
					MIN_ENEMIES,
					MAX_ENEMIES,
					GROUPS,
					MAX_WARMUP,
					MIN_STEPS,
					MAX_STEPS,
					MIN_RUNS,
					MAX_RUNS,
				]
			)
		)
		quit(EXIT_USAGE)
		return
	var path: String = parsed["out"]
	var made: Error = DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(path.get_base_dir())
	)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if made != OK or file == null:
		printerr("STEP_ATTRIBUTION_FAILED cannot write %s" % path)
		quit(EXIT_FAILED)
		return
	var runs: Dictionary = {}
	for variant: String in VARIANTS:
		runs[variant] = PackedFloat64Array()
	for _run: int in range(int(parsed["runs"])):
		for variant: String in VARIANTS:
			var mean_ms: float = run_once(
				variant, parsed["enemies"], parsed["warmup"], parsed["steps"]
			)
			# A packed array in a Dictionary is a copy on read: write it back.
			var values: PackedFloat64Array = runs[variant]
			values.append(mean_ms)
			runs[variant] = values
	var means: Dictionary = {}
	for variant: String in VARIANTS:
		means[variant] = median_of(runs[variant])
	for line: String in report_lines(means, parsed):
		print(line)
		file.store_line(line)
	file.close()
	quit(0)
