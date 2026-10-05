extends SceneTree
## Headless balance report CLI (D-18). Runs the named strategies over a seed set on the shipped
## prototype map and writes report.json and report.md.
##
## Launch it through the wrapper, which adds the import warm-up, a timeout and the sentinel check:
##   bash tools/playtest.sh --strategies=balanced,no_build --seeds=10
## The raw command it wraps (a runtime error inside still exits 0, so never trust the exit code
## alone, see tools/playtest.sh):
##   godot --headless --path <project> -s res://tools/playtest/playtest_cli.gd -- <arguments>
##
## Arguments (everything after `--`; anything else is a usage error):
##   --strategies=<a,b,...>   names from PlaytestStrategies.NAMES; default all of them
##   --seeds=<N>              1 to 50, runs seeds 1..N; default 10
##   --out=<dir>              under build/; default build/playtest; the report files go here
## Output: one line `PLAYTEST_OK runs=<n>` on success (exit 0), PLAYTEST_FAILED on failure
## (exit 1: a run ended in timeout, or a file could not be written), PLAYTEST_USAGE on bad
## arguments (exit 64). tools/ is excluded from the export.

const ReplayCli := preload("res://tools/replay/replay_cli.gd")

const EXIT_OK: int = 0
const EXIT_FAILED: int = 1
const DEFAULT_OUT := "res://build/playtest"
const DEFAULT_SEEDS: int = 10
## The most seeds one invocation runs (T-02-21).
const MAX_SEEDS: int = 50


## Parses the user arguments. Returns {error, strategies, seeds, out}; `error` is "" when every
## argument passed the allowlist, else a one-line reason. `strategies` is an Array[StringName] of
## allowlisted names, `seeds` the count and `out` a normalised res:// directory under build/.
static func parse_args(args: PackedStringArray) -> Dictionary:
	var strategies: Array[StringName] = PlaytestStrategies.NAMES.duplicate()
	var parsed: Dictionary = {
		"error": "", "strategies": strategies, "seeds": DEFAULT_SEEDS, "out": DEFAULT_OUT
	}
	for arg: String in args:
		var reason: String = ""
		if arg.begins_with("--strategies="):
			reason = _read_strategies(arg.trim_prefix("--strategies="), parsed)
		elif arg.begins_with("--seeds="):
			reason = _read_seeds(arg.trim_prefix("--seeds="), parsed)
		elif arg.begins_with("--out="):
			parsed["out"] = ReplayCli.safe_dir(arg.trim_prefix("--out="), ReplayCli.OUT_ROOT)
			if String(parsed["out"]).is_empty():
				reason = "--out must be a directory under build/"
		else:
			reason = "unknown argument '%s'" % arg
		if not reason.is_empty():
			parsed["error"] = reason
			return parsed
	return parsed


static func _read_strategies(text: String, parsed: Dictionary) -> String:
	var chosen: Array[StringName] = []
	for piece: String in text.split(","):
		var name: StringName = StringName(piece)
		if not PlaytestStrategies.NAMES.has(name):
			return (
				"--strategies entries must be among %s, got '%s'"
				% [PlaytestStrategies.NAMES, piece]
			)
		if not chosen.has(name):
			chosen.append(name)
	parsed["strategies"] = chosen
	return ""


static func _read_seeds(text: String, parsed: Dictionary) -> String:
	if not text.is_valid_int():
		return "--seeds must be an integer, got '%s'" % text
	var count: int = text.to_int()
	if count < 1 or count > MAX_SEEDS:
		return "--seeds must be from 1 to %d, got %d" % [MAX_SEEDS, count]
	parsed["seeds"] = count
	return ""


func _initialize() -> void:
	var parsed: Dictionary = parse_args(OS.get_cmdline_user_args())
	var error: String = parsed["error"]
	if not error.is_empty():
		printerr("PLAYTEST_USAGE %s" % error)
		printerr("usage: [--strategies=<a,b,...>] [--seeds=<1..50>] [--out=build/<dir>]")
		quit(64)
		return
	quit(_execute(parsed))


## Runs the matrix, writes the two report files and returns the process exit code.
func _execute(parsed: Dictionary) -> int:
	var strategies: Array[StringName] = parsed["strategies"]
	var seeds: Array[int] = []
	for run_seed: int in range(1, int(parsed["seeds"]) + 1):
		seeds.append(run_seed)
	var report: Dictionary = BalanceReport.run(strategies, seeds)
	var out: String = parsed["out"]
	if not _write_report(out, report):
		return _fail("PLAYTEST_FAILED reason=cannot_write_output out=%s" % out)
	var runs: Array = report["runs"]
	for entry: Dictionary in runs:
		if entry["outcome"] == str(ReplayDriver.OUTCOME_TIMEOUT):
			return _fail(
				(
					"PLAYTEST_FAILED reason=timeout strategy=%s seed=%d"
					% [entry["strategy"], entry["seed"]]
				)
			)
	print("PLAYTEST_OK runs=%d" % runs.size())
	return EXIT_OK


func _write_report(out: String, report: Dictionary) -> bool:
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out)) != OK:
		return false
	return (
		_write_text("%s/report.json" % out, JSON.stringify(report, "  ", false) + "\n")
		and _write_text("%s/report.md" % out, BalanceReport.to_markdown(report))
	)


func _write_text(path: String, text: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	return true


func _fail(message: String) -> int:
	printerr(message)
	return EXIT_FAILED
