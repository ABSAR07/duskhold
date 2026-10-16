extends SceneTree
## Headless gate stress CLI (ENMY-04, ROADMAP success criterion 2). Sends the tools-only stress
## map's 300 enemies at its one gate, once or twice in one process, and prints GATE_OK only when
## every enemy crossed, no living enemy is still flagged stuck at the end and (with --twice) both
## runs agree on the event digest.
##
## Launch it through the wrapper, which adds the import warm-up, a timeout and the sentinel check:
##   bash tools/gate_stress.sh --twice
## The raw command it wraps (a runtime error inside still exits 0, so never trust the exit code
## alone, see tools/gate_stress.sh):
##   godot --headless --path <project> -s res://tools/stress/gate_stress_cli.gd -- <arguments>
##
## Arguments (everything after `--`; anything else is a usage error). No map or data path can be
## passed: the map is always GateStress.STRESS_MAP.
##   --seed=<int>           any value String.is_valid_int() accepts; default 1
##   --twice                run twice in this process; the two digests must match
##   --max-seconds=<10..300> the simulation time limit; default 60
##   --out=<dir>            under build/; default build/stress; gate.json goes here
## Output: one line starting with GATE_OK on a pass (exit 0), GATE_FAILED on a failure (exit 1),
## GATE_USAGE on bad arguments (exit 64). tools/ is excluded from the export.

const ReplayCli := preload("res://tools/replay/replay_cli.gd")

const EXIT_OK: int = 0
const EXIT_FAILED: int = 1
const EXIT_USAGE: int = 64
const OUT_ROOT := "res://build"
const DEFAULT_OUT := "res://build/stress"
const RESULT_FILE := "gate.json"
const DEFAULT_SEED: int = 1
const MIN_SECONDS: int = 10
const MAX_SECONDS: int = 300
const FLAG_SEED := "--seed="
const FLAG_SECONDS := "--max-seconds="
const FLAG_OUT := "--out="
const FLAG_TWICE := "--twice"


## Parses the user arguments. Returns {error, seed, twice, max_seconds, out}; `error` is "" when
## every argument passed the allowlist, else a one-line reason. `out` comes back as a res:// path.
static func parse_args(args: PackedStringArray) -> Dictionary:
	var parsed: Dictionary = {
		"error": "",
		"seed": DEFAULT_SEED,
		"twice": false,
		"max_seconds": GateStress.DEFAULT_MAX_SECONDS,
		"out": DEFAULT_OUT,
	}
	for arg: String in args:
		var failure: String = ""
		if arg == FLAG_TWICE:
			parsed["twice"] = true
		elif arg.begins_with(FLAG_SEED):
			failure = _read_seed(parsed, arg.trim_prefix(FLAG_SEED))
		elif arg.begins_with(FLAG_SECONDS):
			failure = _read_seconds(parsed, arg.trim_prefix(FLAG_SECONDS))
		elif arg.begins_with(FLAG_OUT):
			failure = _read_out(parsed, arg.trim_prefix(FLAG_OUT))
		else:
			failure = "unknown argument '%s'" % arg
		if not failure.is_empty():
			parsed["error"] = failure
			return parsed
	return parsed


static func _read_seed(parsed: Dictionary, text: String) -> String:
	if not text.is_valid_int():
		return "--seed must be an integer, got '%s'" % text
	parsed["seed"] = text.to_int()
	return ""


static func _read_seconds(parsed: Dictionary, text: String) -> String:
	if not text.is_valid_int():
		return "--max-seconds must be an integer, got '%s'" % text
	var value: int = text.to_int()
	if value < MIN_SECONDS or value > MAX_SECONDS:
		return "--max-seconds must be between %d and %d, got %d" % [MIN_SECONDS, MAX_SECONDS, value]
	parsed["max_seconds"] = float(value)
	return ""


static func _read_out(parsed: Dictionary, text: String) -> String:
	var path: String = ReplayCli.safe_dir(text, OUT_ROOT)
	if path.is_empty():
		return "--out must be a directory under build/"
	parsed["out"] = path
	return ""


func _initialize() -> void:
	var parsed: Dictionary = parse_args(OS.get_cmdline_user_args())
	var error: String = parsed["error"]
	if not error.is_empty():
		printerr("GATE_USAGE %s" % error)
		printerr(
			(
				"usage: [--seed=<int>] [--twice] [--max-seconds=<%d..%d>] [--out=build/<dir>]"
				% [MIN_SECONDS, MAX_SECONDS]
			)
		)
		quit(EXIT_USAGE)
		return
	quit(_execute(parsed))


## Runs the gate stress and returns the process exit code.
func _execute(parsed: Dictionary) -> int:
	var map: MapConfig = load(GateStress.STRESS_MAP) as MapConfig
	if map == null:
		return _fail("GATE_FAILED reason=no_stress_map")
	var run_seed: int = parsed["seed"]
	var max_seconds: float = parsed["max_seconds"]
	var first: Dictionary = GateStress.run(map, run_seed, max_seconds)
	var reason: String = first["reason"]
	if not reason.is_empty():
		return _fail("GATE_FAILED reason=%s" % reason)
	if parsed["twice"]:
		var second: Dictionary = GateStress.run(map, run_seed, max_seconds)
		if not _same_run(first, second):
			return _fail(
				(
					"GATE_FAILED reason=digest_mismatch first=%s second=%s"
					% [first["digest"], second["digest"]]
				)
			)
	if not _write_result(parsed, first):
		return _fail("GATE_FAILED reason=cannot_write_output")
	if not first["passed"]:
		return _fail(_failure_line(first))
	print(_ok_line(first))
	return EXIT_OK


## The sentinel line of a pass.
func _ok_line(result: Dictionary) -> String:
	return (
		(
			"GATE_OK enemies=%d crossed=%d stuck=%d median_cross_s=%.2f max_cross_s=%.2f "
			+ "longest_flag_s=%.2f wall_hits=%d digest=%s"
		)
		% [
			result["enemies"],
			result["crossed"],
			result["stuck_at_end"],
			result["median_cross_s"],
			result["max_cross_s"],
			result["longest_flag_s"],
			result["wall_hits"],
			result["digest"],
		]
	)


## The failure line of a run that happened but did not pass.
func _failure_line(result: Dictionary) -> String:
	var why: String = "stuck_or_uncrossed"
	if result["hit_limit"]:
		why = "time_limit"
	return (
		"GATE_FAILED reason=%s enemies=%d crossed=%d stuck=%d max_cross_s=%.2f digest=%s"
		% [
			why,
			result["enemies"],
			result["crossed"],
			result["stuck_at_end"],
			result["max_cross_s"],
			result["digest"],
		]
	)


func _same_run(first: Dictionary, second: Dictionary) -> bool:
	return (
		str(second["digest"]).length() == 64
		and first["digest"] == second["digest"]
		and first["ticks"] == second["ticks"]
		and first["crossed"] == second["crossed"]
		and first["stuck_at_end"] == second["stuck_at_end"]
	)


func _fail(message: String) -> int:
	printerr(message)
	return EXIT_FAILED


## Writes <out>/gate.json, the numbers of the first run.
func _write_result(parsed: Dictionary, result: Dictionary) -> bool:
	var out: String = parsed["out"]
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out)) != OK:
		return false
	var summary: Dictionary = result.duplicate()
	summary["seed"] = parsed["seed"]
	summary["max_seconds"] = parsed["max_seconds"]
	summary["twice"] = parsed["twice"]
	summary["platform"] = OS.get_name()
	var file: FileAccess = FileAccess.open("%s/%s" % [out, RESULT_FILE], FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(summary, "  ", false) + "\n")
	file.close()
	return true
