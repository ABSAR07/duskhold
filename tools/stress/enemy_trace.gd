extends SceneTree
## Per-tick enemy trace tool (PLAT-01, plan 04-23): the oracle plan 04-19 diffs the native enemy
## step against. It runs one scenario headlessly and writes, for every tick and every LIVING
## enemy in ascending id, one line of the enemy's state as the step left it (read-only: the
## ReplayDriver, ReplayScenarios and GateStress on_tick hooks only read, so the digests cannot
## move, which the four replays and the gate prove). It prints
##   ENEMY_TRACE_OK scenario=<s> ticks=<n> lines=<n> sha256=<hex of the file>
## and exits 0.
##
## LINE FORMAT (plan 04-19 reads it exactly; one line per living enemy, fields separated by one
## space, the line ends with a line feed, so a file ends with one):
##   <tick> <id> <position> <previous> <health> <target_kind> <target_id>
##   tick         RunContext.tick_count after the step (the first step is tick 1)
##   id           the enemy id, ascending within a tick
##   position     16 lowercase hex digits: the bytes of the Vector2 (float32 x, then float32 y,
##                little endian), as PackedVector2Array.to_byte_array().hex_encode() gives them
##   previous     the same for previous_position_of(id), where the enemy stood one step ago
##   health       health_of(id), an integer above 0 (only living enemies are written)
##   target_kind  target_of(id)["kind"], the word `none` while the enemy has no target
##   target_id    target_of(id)["id"] (a unit id, a spot index, a wall segment index, 0 for the
##                castle or the king), -1 while the enemy has no target
## A tick with no living enemy writes no line.
##
## By default a scenario runs to its own end within its own bound: ReplayScenarios.max_ticks(name)
## for the four replays (the run stops when it is over, as ReplayDriver.run does) and
## SimClock.ticks(GateStress.DEFAULT_MAX_SECONDS) for the gate (the gate's own time limit, stopping
## earlier when every enemy has crossed). --ticks only lowers that bound.
##
## Launch (tools/ is excluded from the export):
##   bash tools/godot.sh --headless --path . -s res://tools/stress/enemy_trace.gd -- \
##       --scenario=<smoke|army|walls|full_idle|gate> [--ticks=<1..40000>] \
##       [--out=build/trace/<name>.txt]
## Arguments (everything after `--`; anything else is a usage error):
##   --scenario=<name>   one of smoke, army, walls, full_idle, gate (required)
##   --ticks=<1..40000>  record at most this many ticks; default the scenario's own bound
##   --out=<path>        the trace file, a .txt under build/ (ReplayCli.safe_dir); default
##                       build/trace/<scenario>.txt
## A usage error prints ENEMY_TRACE_USAGE <reason> and exits 64; a run that cannot happen (no gate
## in the map, an unwritable file) prints ENEMY_TRACE_FAILED <reason> and exits 1.

const ReplayCli := preload("res://tools/replay/replay_cli.gd")

const EXIT_FAILED: int = 1
const EXIT_USAGE: int = 64
const GATE: String = "gate"
const SCENARIOS: Array[String] = ["smoke", "army", "walls", "full_idle", "gate"]
const MIN_TICKS: int = 1
const MAX_TICKS: int = 40000
const OUT_ROOT := "res://build"
const OUT_DIR := "res://build/trace"
const OUT_SUFFIX := ".txt"
const FLAG_SCENARIO := "--scenario="
const FLAG_TICKS := "--ticks="
const FLAG_OUT := "--out="
const GATE_SEED: int = 1
## The word and id of a target-less enemy in a trace line.
const NO_TARGET_KIND := "none"
const NO_TARGET_ID: int = -1


## Parses the user arguments. Returns {error, scenario, ticks, out}; `error` is "" when every
## argument passed the allowlist, else a one-line reason. `ticks` is 0 for the scenario's own
## bound; `out` is a res:// path under build/.
static func parse_args(args: PackedStringArray) -> Dictionary:
	var parsed: Dictionary = {"error": "", "scenario": "", "ticks": 0, "out": ""}
	for arg: String in args:
		var failure: String = ""
		if arg.begins_with(FLAG_SCENARIO):
			failure = _read_scenario(parsed, arg.trim_prefix(FLAG_SCENARIO))
		elif arg.begins_with(FLAG_TICKS):
			failure = _read_ticks(parsed, arg.trim_prefix(FLAG_TICKS))
		elif arg.begins_with(FLAG_OUT):
			failure = _read_out(parsed, arg.trim_prefix(FLAG_OUT))
		else:
			failure = "unknown argument '%s'" % arg
		if not failure.is_empty():
			parsed["error"] = failure
			return parsed
	if String(parsed["scenario"]).is_empty():
		parsed["error"] = "--scenario is required"
	elif String(parsed["out"]).is_empty():
		parsed["out"] = "%s/%s%s" % [OUT_DIR, parsed["scenario"], OUT_SUFFIX]
	return parsed


## The scenario's own tick bound: ReplayScenarios.max_ticks for a replay, the gate's time limit in
## ticks for the gate; 0 for a name that is not on the list.
static func default_bound(scenario: String) -> int:
	if scenario == GATE:
		return SimClock.ticks(GateStress.DEFAULT_MAX_SECONDS)
	return ReplayScenarios.max_ticks(StringName(scenario))


## Runs `scenario` for at most `bound` ticks (0 or less: its own bound) and hands the text of each
## tick that has living enemies to `sink` (a Callable taking one String). Returns {ticks, lines,
## ran}: the ticks seen, the lines written and false when the run could not happen (no gate).
static func run_scenario(scenario: String, bound: int, sink: Callable) -> Dictionary:
	var own: int = default_bound(scenario)
	var limit: int = own if bound <= 0 else mini(bound, own)
	var collector: Collector = Collector.new(limit, sink)
	var hook: Callable = Callable(collector, "record")
	var ran: bool = true
	if scenario == GATE:
		var seconds: float = GateStress.DEFAULT_MAX_SECONDS
		if limit < own:
			seconds = float(limit) * SimClock.STEP
		var map: MapConfig = load(GateStress.STRESS_MAP) as MapConfig
		var result: Dictionary = GateStress.run(map, GATE_SEED, seconds, hook)
		ran = String(result["reason"]).is_empty()
	elif ReplayScenarios.has(StringName(scenario)):
		var name: StringName = StringName(scenario)
		ReplayScenarios.run(name, ReplayScenarios.default_seed(name), hook)
	else:
		ran = false
	return {"ticks": collector.ticks, "lines": collector.lines, "ran": ran}


static func _read_scenario(parsed: Dictionary, text: String) -> String:
	if not SCENARIOS.has(text):
		return "--scenario must be one of %s, got '%s'" % [", ".join(SCENARIOS), text]
	parsed["scenario"] = text
	return ""


static func _read_ticks(parsed: Dictionary, text: String) -> String:
	if not text.is_valid_int():
		return "--ticks must be an integer, got '%s'" % text
	var value: int = text.to_int()
	if value < MIN_TICKS or value > MAX_TICKS:
		return "--ticks must be between %d and %d, got %d" % [MIN_TICKS, MAX_TICKS, value]
	parsed["ticks"] = value
	return ""


## Stores the trace path when it is a .txt file under build/; returns "" or the reason.
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
		printerr("ENEMY_TRACE_USAGE %s" % error)
		printerr(
			(
				"usage: --scenario=<%s> [--ticks=<%d..%d>] [--out=build/trace/<name>.txt]"
				% ["|".join(SCENARIOS), MIN_TICKS, MAX_TICKS]
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
		printerr("ENEMY_TRACE_FAILED cannot write %s" % path)
		quit(EXIT_FAILED)
		return
	var result: Dictionary = run_scenario(parsed["scenario"], parsed["ticks"], file.store_string)
	file.close()
	if not bool(result["ran"]):
		printerr("ENEMY_TRACE_FAILED scenario %s could not run" % parsed["scenario"])
		quit(EXIT_FAILED)
		return
	print(
		(
			"ENEMY_TRACE_OK scenario=%s ticks=%d lines=%d sha256=%s"
			% [parsed["scenario"], result["ticks"], result["lines"], FileAccess.get_sha256(path)]
		)
	)
	quit(0)


## The on_tick hook: reads the living enemies after every step and hands their text to the sink.
## Read-only by construction; it holds no reference the simulation reads.
class Collector:
	extends RefCounted

	var ticks: int = 0
	var lines: int = 0
	var _bound: int
	var _sink: Callable

	func _init(bound: int, sink: Callable) -> void:
		_bound = bound
		_sink = sink

	## Called by the driver with the RunContext after every step; records at most `_bound` ticks.
	func record(ctx: RunContext) -> void:
		if ticks >= _bound:
			return
		ticks += 1
		var text: String = tick_text(ctx.tick_count, ctx.night.get_enemies())
		if text.is_empty():
			return
		lines += text.count("\n")
		_sink.call(text)

	## The lines of one tick, one per living enemy in ascending id, each ending in a line feed.
	static func tick_text(tick: int, enemies: EnemySystem) -> String:
		var text: String = ""
		for id: int in enemies.ids():
			if enemies.is_alive(id):
				text += line_of(tick, id, enemies)
		return text

	## One line, in the format documented at the top of enemy_trace.gd.
	static func line_of(tick: int, id: int, enemies: EnemySystem) -> String:
		var target: Dictionary = enemies.target_of(id)
		var kind: String = NO_TARGET_KIND
		var target_id: int = NO_TARGET_ID
		if not target.is_empty():
			kind = String(target["kind"])
			target_id = int(target["id"])
		return (
			"%d %d %s %s %d %s %d\n"
			% [
				tick,
				id,
				PackedVector2Array([enemies.position_of(id)]).to_byte_array().hex_encode(),
				PackedVector2Array([enemies.previous_position_of(id)]).to_byte_array().hex_encode(),
				enemies.health_of(id),
				kind,
				target_id,
			]
		)
