extends SceneTree
## Headless report tool of the stress night (PLAT-01, D-12). It reads run_1.json .. run_<n>.json
## from the folder the stress night wrote them to, summarises each, picks the run with the median
## p95, writes report.json and report.md beside them and prints one sentinel line:
##   FRAME_REPORT_OK runs=<n> median_run=<n> p95_ms=<x.xx> budget_ms=<x.x> within=<true|false>
##       enemies=<min> units=<min> arrows=<min>
## (one line; `within` is the median p95 at or under the budget AND the minimum on-screen counts at
## or over the D-10 bar, the counts being the minimum over the median run's samples).
##
## Launch it through tools/stress.sh, which runs it after the real-window runs:
##   godot --headless --path <project> -s res://tools/stress/frame_report_cli.gd -- <arguments>
## Arguments (everything after `--`; anything else is a usage error):
##   --in=<dir>          under build/; default build/stress
##   --runs=<1..9>       how many run_<n>.json files to read; default 3
##   --budget-ms=<x>     the p95 budget in ms, 0 < x <= 1000; default FrameReport.BUDGET_P95_MS
## Output: FRAME_REPORT_OK (exit 0, also when the budget is missed: the numbers are valid),
## FRAME_REPORT_FAILED when a run is missing or malformed (exit 1), FRAME_REPORT_USAGE on bad
## arguments (exit 64). tools/ is excluded from the export.

const ReplayCli := preload("res://tools/replay/replay_cli.gd")

const EXIT_OK: int = 0
const EXIT_FAILED: int = 1
const EXIT_USAGE: int = 64
const OUT_ROOT := "res://build"
const DEFAULT_IN := "res://build/stress"
const DEFAULT_RUNS: int = 3
const MAX_RUNS: int = 9
const MAX_BUDGET_MS: float = 1000.0
const FLAG_IN := "--in="
const FLAG_RUNS := "--runs="
const FLAG_BUDGET := "--budget-ms="
const REPORT_JSON := "report.json"
const REPORT_MD := "report.md"


## Parses the user arguments. Returns {error, input, runs, budget_ms}; `error` is "" when every
## argument passed the allowlist, else a one-line reason. `input` comes back as a res:// path.
static func parse_args(args: PackedStringArray) -> Dictionary:
	var parsed: Dictionary = {
		"error": "",
		"input": DEFAULT_IN,
		"runs": DEFAULT_RUNS,
		"budget_ms": FrameReport.BUDGET_P95_MS,
	}
	for arg: String in args:
		var failure: String = ""
		if arg.begins_with(FLAG_IN):
			failure = _read_input(parsed, arg.trim_prefix(FLAG_IN))
		elif arg.begins_with(FLAG_RUNS):
			failure = _read_runs(parsed, arg.trim_prefix(FLAG_RUNS))
		elif arg.begins_with(FLAG_BUDGET):
			failure = _read_budget(parsed, arg.trim_prefix(FLAG_BUDGET))
		else:
			failure = "unknown argument '%s'" % arg
		if not failure.is_empty():
			parsed["error"] = failure
			return parsed
	return parsed


static func _read_input(parsed: Dictionary, text: String) -> String:
	var path: String = ReplayCli.safe_dir(text, OUT_ROOT)
	if path.is_empty():
		return "--in must be a directory under build/"
	parsed["input"] = path
	return ""


static func _read_runs(parsed: Dictionary, text: String) -> String:
	if not text.is_valid_int():
		return "--runs must be an integer, got '%s'" % text
	var value: int = text.to_int()
	if value < 1 or value > MAX_RUNS:
		return "--runs must be between 1 and %d, got %d" % [MAX_RUNS, value]
	parsed["runs"] = value
	return ""


static func _read_budget(parsed: Dictionary, text: String) -> String:
	if not text.is_valid_float():
		return "--budget-ms must be a number, got '%s'" % text
	var value: float = text.to_float()
	if not is_finite(value) or value <= 0.0 or value > MAX_BUDGET_MS:
		return "--budget-ms must be above 0 and at most %d, got %s" % [int(MAX_BUDGET_MS), text]
	parsed["budget_ms"] = value
	return ""


func _initialize() -> void:
	var parsed: Dictionary = parse_args(OS.get_cmdline_user_args())
	var error: String = parsed["error"]
	if not error.is_empty():
		printerr("FRAME_REPORT_USAGE %s" % error)
		printerr("usage: [--in=build/<dir>] [--runs=<1..%d>] [--budget-ms=<x>]" % MAX_RUNS)
		quit(EXIT_USAGE)
		return
	quit(_execute(parsed))


## Reads the runs, writes the report files and returns the process exit code.
func _execute(parsed: Dictionary) -> int:
	var input: String = parsed["input"]
	var summaries: Array = []
	for number: int in range(1, int(parsed["runs"]) + 1):
		var path: String = "%s/run_%d.json" % [input, number]
		var run: Dictionary = _read_run(path)
		if run.is_empty():
			return _fail("FRAME_REPORT_FAILED reason=missing_or_malformed file=%s" % path)
		var summary: Dictionary = FrameReport.summarise(run)
		if int(summary["count"]) < 1:
			return _fail("FRAME_REPORT_FAILED reason=no_frames file=%s" % path)
		summaries.append(summary)
	var budget: float = parsed["budget_ms"]
	var median: Dictionary = FrameReport.median_run(summaries)
	var report: Dictionary = {"median": median, "runs": summaries, "budget_ms": budget}
	if not _write(input, report):
		return _fail("FRAME_REPORT_FAILED reason=cannot_write_output")
	print(_ok_line(summaries.size(), median, budget))
	return EXIT_OK


## The sentinel line of a finished report.
func _ok_line(run_count: int, median: Dictionary, budget_ms: float) -> String:
	return (
		(
			"FRAME_REPORT_OK runs=%d median_run=%d p95_ms=%.2f budget_ms=%.1f within=%s "
			+ "enemies=%d units=%d arrows=%d"
		)
		% [
			run_count,
			median["run"],
			median["p95"],
			budget_ms,
			str(FrameReport.meets_budget(median, budget_ms)).to_lower(),
			median["enemies_min"],
			median["units_min"],
			median["arrows_min"],
		]
	)


## The parsed run at `path`, or an empty dictionary when it is missing or not a JSON object.
func _read_run(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}


## Writes report.json and report.md into `folder`.
func _write(folder: String, report: Dictionary) -> bool:
	var json: FileAccess = FileAccess.open("%s/%s" % [folder, REPORT_JSON], FileAccess.WRITE)
	var markdown: FileAccess = FileAccess.open("%s/%s" % [folder, REPORT_MD], FileAccess.WRITE)
	if json == null or markdown == null:
		return false
	json.store_string(JSON.stringify(report, "  ", false) + "\n")
	markdown.store_string(FrameReport.markdown(report))
	json.close()
	markdown.close()
	return true


func _fail(message: String) -> int:
	printerr(message)
	return EXIT_FAILED
