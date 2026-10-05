extends SceneTree
## Headless replay CLI (DEV-05, ROADMAP success criterion 3). Replays an allowlisted scripted,
## seeded scenario, once or twice in one process, and checks its event digest.
##
## Launch it through the wrapper, which adds the import warm-up, a timeout and the sentinel check:
##   bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json
## The raw command it wraps (a runtime error inside still exits 0, so never trust the exit code
## alone, see tools/replay.sh):
##   godot --headless --path <project> -s res://tools/replay/replay_cli.gd -- <arguments>
##
## Arguments (everything after `--`; anything else is a usage error):
##   --scenario=<name>        required; a name in ReplayScenarios.NAMES
##   --seed=<int>             any value String.is_valid_int() accepts; default per scenario
##   --twice                  run twice in this process; the two digests must match
##   --expect-file=<path>     a .json under tests/golden/; the digest must equal its entry
##   --out=<dir>              under build/; default build/replay; <scenario>.json and .log go here
##   --write-golden           write tests/golden/<scenario>.json (its `default` key); cannot be
##                            combined with --expect-file
## Output: one line starting with REPLAY_OK on success (exit 0), REPLAY_MISMATCH,
## REPLAY_GOLDEN_MISMATCH or REPLAY_FAILED on failure (exit 1), REPLAY_USAGE on bad arguments
## (exit 64). tools/ is excluded from the export.

const EXIT_OK: int = 0
const EXIT_FAILED: int = 1

const RES := "res://"
const OUT_ROOT := "res://build"
const DEFAULT_OUT := "res://build/replay"
const GOLDEN_ROOT := "res://tests/golden"
const GOLDEN_SUFFIX := ".json"
const DIGEST_LENGTH: int = 64


## Parses the user arguments. Returns {error, scenario, seed, twice, write_golden, out,
## expect_file}; `error` is "" when every argument passed the allowlist, else a one-line reason.
## `out` and `expect_file` come back as normalised res:// paths ("" for an absent expect_file).
static func parse_args(args: PackedStringArray) -> Dictionary:
	var parsed: Dictionary = {
		"error": "",
		"scenario": &"",
		"seed": 0,
		"twice": false,
		"write_golden": false,
		"out": DEFAULT_OUT,
		"expect_file": "",
	}
	var seed_text: String = ""
	var has_seed: bool = false
	for arg: String in args:
		if arg == "--twice":
			parsed["twice"] = true
		elif arg == "--write-golden":
			parsed["write_golden"] = true
		elif arg.begins_with("--scenario="):
			parsed["scenario"] = StringName(arg.trim_prefix("--scenario="))
		elif arg.begins_with("--seed="):
			seed_text = arg.trim_prefix("--seed=")
			has_seed = true
		elif arg.begins_with("--out="):
			parsed["out"] = _safe_dir(arg.trim_prefix("--out="), OUT_ROOT)
		elif arg.begins_with("--expect-file="):
			parsed["expect_file"] = _safe_json(arg.trim_prefix("--expect-file="), GOLDEN_ROOT)
		else:
			return _usage(parsed, "unknown argument '%s'" % arg)
	return _validate(parsed, has_seed, seed_text, args)


## The res:// form of `raw` when it is a directory at or under `root`, else "". Rejects any `..`
## segment, an absolute path outside the project and a sibling that merely shares the prefix.
static func _safe_dir(raw: String, root: String) -> String:
	var path: String = _normalise(raw)
	if path == root or path.begins_with(root + "/"):
		return path
	return ""


## The res:// form of `raw` when it is a file ending in .json under `root`, else "".
static func _safe_json(raw: String, root: String) -> String:
	var path: String = _normalise(raw)
	if path.begins_with(root + "/") and path.ends_with(GOLDEN_SUFFIX):
		if path.length() > root.length() + 1 + GOLDEN_SUFFIX.length():
			return path
	return ""


## A res:// path for `raw`, "" when it is empty, climbs with `..` or leaves the project.
static func _normalise(raw: String) -> String:
	var path: String = raw.replace("\\", "/").strip_edges()
	if path.is_empty():
		return ""
	if ".." in path.split("/"):
		return ""
	if path.is_absolute_path() and not path.begins_with(RES):
		path = ProjectSettings.localize_path(path)
		if not path.begins_with(RES):
			return ""
	elif not path.begins_with(RES):
		path = RES + path
	return path.simplify_path()


static func _validate(
	parsed: Dictionary, has_seed: bool, seed_text: String, args: PackedStringArray
) -> Dictionary:
	var name: StringName = parsed["scenario"]
	if not ReplayScenarios.has(name):
		return _usage(parsed, "--scenario must be one of %s" % [ReplayScenarios.NAMES])
	if has_seed and not seed_text.is_valid_int():
		return _usage(parsed, "--seed must be an integer, got '%s'" % seed_text)
	parsed["seed"] = seed_text.to_int() if has_seed else ReplayScenarios.default_seed(name)
	if String(parsed["out"]).is_empty():
		return _usage(parsed, "--out must be a directory under build/")
	var wants_expect: bool = false
	for arg: String in args:
		wants_expect = wants_expect or arg.begins_with("--expect-file=")
	if wants_expect and String(parsed["expect_file"]).is_empty():
		return _usage(parsed, "--expect-file must be a .json file under tests/golden/")
	if parsed["write_golden"] and wants_expect:
		return _usage(parsed, "--write-golden and --expect-file cannot be combined")
	return parsed


static func _usage(parsed: Dictionary, reason: String) -> Dictionary:
	parsed["error"] = reason
	return parsed


func _initialize() -> void:
	var parsed: Dictionary = parse_args(OS.get_cmdline_user_args())
	var error: String = parsed["error"]
	if not error.is_empty():
		printerr("REPLAY_USAGE %s" % error)
		printerr(
			(
				"usage: --scenario=<name> [--seed=<int>] [--twice] [--expect-file=tests/golden/<f>.json]"
				+ " [--out=build/<dir>] [--write-golden]"
			)
		)
		quit(64)
		return
	quit(_execute(parsed))


## Runs the requested replay and returns the process exit code.
func _execute(parsed: Dictionary) -> int:
	var name: StringName = parsed["scenario"]
	var run_seed: int = parsed["seed"]
	var first: Dictionary = ReplayScenarios.run(name, run_seed)
	if not _usable(first):
		return _fail("REPLAY_FAILED scenario=%s seed=%d reason=no_digest" % [name, run_seed])
	if parsed["twice"]:
		var second: Dictionary = ReplayScenarios.run(name, run_seed)
		if not _same_run(first, second):
			return _fail(
				(
					"REPLAY_MISMATCH scenario=%s seed=%d first=%s second=%s"
					% [name, run_seed, first["digest"], second.get("digest", "")]
				)
			)
	return _conclude(parsed, first)


## The checks that follow a usable, repeatable run: the output files, the timeout outcome, the
## golden digest. Prints the sentinel line only when all of them pass.
func _conclude(parsed: Dictionary, first: Dictionary) -> int:
	var name: StringName = parsed["scenario"]
	var run_seed: int = parsed["seed"]
	if not _write_result(parsed, first):
		return _fail(
			"REPLAY_FAILED scenario=%s seed=%d reason=cannot_write_output" % [name, run_seed]
		)
	var outcome: StringName = first["outcome"]
	if outcome == ReplayDriver.OUTCOME_TIMEOUT:
		return _fail(
			(
				"REPLAY_FAILED scenario=%s seed=%d outcome=timeout ticks=%d"
				% [name, run_seed, first["ticks"]]
			)
		)
	var expect_file: String = parsed["expect_file"]
	if not expect_file.is_empty() and not _matches_golden(expect_file, first):
		return EXIT_FAILED
	if parsed["write_golden"] and not _write_golden(name, run_seed, first):
		return _fail(
			"REPLAY_FAILED scenario=%s seed=%d reason=cannot_write_golden" % [name, run_seed]
		)
	print(
		(
			"REPLAY_OK scenario=%s seed=%d outcome=%s ticks=%d digest=%s"
			% [name, run_seed, outcome, first["ticks"], first["digest"]]
		)
	)
	return EXIT_OK


## True when the result carries a 64-character hex digest (a script error can leave a default).
func _usable(result: Dictionary) -> bool:
	if not result.has("digest") or not result.has("outcome") or not result.has("ticks"):
		return false
	var digest: String = str(result["digest"])
	return digest.length() == DIGEST_LENGTH and digest.is_valid_hex_number()


func _same_run(first: Dictionary, second: Dictionary) -> bool:
	return (
		_usable(second)
		and first["digest"] == second["digest"]
		and first["ticks"] == second["ticks"]
		and first["line_count"] == second["line_count"]
		and first["outcome"] == second["outcome"]
	)


func _matches_golden(path: String, result: Dictionary) -> bool:
	var expected: String = ReplayScenarios.golden_digest(path)
	if expected.is_empty():
		_fail("REPLAY_FAILED reason=no_golden_digest file=%s platform=%s" % [path, OS.get_name()])
		return false
	if expected != result["digest"]:
		_fail(
			(
				"REPLAY_GOLDEN_MISMATCH platform=%s expected=%s actual=%s"
				% [OS.get_name(), expected, result["digest"]]
			)
		)
		return false
	return true


func _fail(message: String) -> int:
	printerr(message)
	return EXIT_FAILED


## Writes <out>/<scenario>.json (the summary) and <scenario>.log (the canonical event lines, for
## diffing two platforms when a digest disagrees).
func _write_result(parsed: Dictionary, result: Dictionary) -> bool:
	var out: String = parsed["out"]
	var name: String = parsed["scenario"]
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out)) != OK:
		return false
	var summary: Dictionary = {
		"scenario": name,
		"seed": parsed["seed"],
		"outcome": str(result["outcome"]),
		"ticks": result["ticks"],
		"digest": result["digest"],
		"line_count": result["line_count"],
		"nights_started": result["nights_started"],
		"stats": _stringified(result["stats"]),
		"platform": OS.get_name(),
	}
	var lines: PackedStringArray = result["lines"]
	return (
		_write_text("%s/%s.json" % [out, name], JSON.stringify(summary, "  ", false) + "\n")
		and _write_text("%s/%s.log" % [out, name], "\n".join(lines) + "\n")
	)


## Writes tests/golden/<scenario>.json with this run's digest under the `default` key, keeping any
## other platform key already in the file.
func _write_golden(name: StringName, run_seed: int, result: Dictionary) -> bool:
	var path: String = "%s/%s%s" % [GOLDEN_ROOT, name, GOLDEN_SUFFIX]
	var digests: Dictionary = {}
	if FileAccess.file_exists(path):
		var existing: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if existing is Dictionary and (existing as Dictionary).get("digests") is Dictionary:
			digests = (existing as Dictionary)["digests"]
	digests[ReplayScenarios.DEFAULT_KEY] = result["digest"]
	var golden: Dictionary = {"scenario": str(name), "seed": run_seed, "digests": digests}
	return _write_text(path, JSON.stringify(golden, "  ", false) + "\n")


func _write_text(path: String, text: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	return true


## The same dictionary with every StringName value as a String, so it serialises as JSON text.
func _stringified(table: Dictionary) -> Dictionary:
	var copy: Dictionary = {}
	for key: Variant in table.keys():
		var value: Variant = table[key]
		copy[str(key)] = str(value) if value is StringName else value
	return copy
