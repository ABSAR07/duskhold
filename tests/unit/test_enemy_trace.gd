extends GutTest
## PLAT-01 (plan 04-23, threat T-04-49): the per-tick enemy trace tool plan 04-19 diffs the native
## enemy step against. The argument allowlist, the default bound of every scenario (derived from the
## scenario's own limit, never a written-down tick count), the documented line format, a run built
## twice giving the same text, and the proof that the on_tick hooks only read: a replay and a gate
## run with a hook attached produce the digest they produce without one.

const EnemyTrace := preload("res://tools/stress/enemy_trace.gd")
const SMOKE_GOLDEN := "res://tests/golden/smoke.json"
const LINE_PATTERN := "^(\\d+) (\\d+) ([0-9a-f]{16}) ([0-9a-f]{16}) (\\d+) (\\w+) (-?\\d+)$"
const SMOKE_TICKS: int = 120
const GATE_SECONDS: float = 10.0
const GATE_SEED: int = 1


func test_the_defaults_name_the_scenario_and_leave_the_bound_to_it() -> void:
	var parsed: Dictionary = EnemyTrace.parse_args(PackedStringArray(["--scenario=walls"]))
	assert_eq(parsed["error"], "", "accepted")
	assert_eq(parsed["scenario"], "walls", "the scenario")
	assert_eq(parsed["ticks"], 0, "0 means the scenario's own bound")
	assert_eq(parsed["out"], "res://build/trace/walls.txt", "under build/trace by default")


func test_every_scenario_name_is_accepted_and_others_are_not() -> void:
	for scenario: String in ["smoke", "army", "walls", "full_idle", "gate"]:
		var parsed: Dictionary = EnemyTrace.parse_args(
			PackedStringArray(["--scenario=%s" % scenario])
		)
		assert_eq(parsed["error"], "", "%s accepted" % scenario)
	for bad: String in [
		"--scenario=nope", "--scenario=", "--scenario=../smoke", "--scenario=Smoke"
	]:
		assert_ne(EnemyTrace.parse_args(PackedStringArray([bad]))["error"], "", bad)
	assert_ne(EnemyTrace.parse_args(PackedStringArray())["error"], "", "the scenario is required")
	assert_ne(
		EnemyTrace.parse_args(PackedStringArray(["--scenario=smoke", "--verbose"]))["error"],
		"",
		"an unknown argument"
	)


func test_ticks_must_be_an_integer_from_1_to_40000() -> void:
	for good: String in ["1", "400", "40000"]:
		var parsed: Dictionary = EnemyTrace.parse_args(
			PackedStringArray(["--scenario=smoke", "--ticks=%s" % good])
		)
		assert_eq(parsed["error"], "", "%s accepted" % good)
		assert_eq(parsed["ticks"], good.to_int(), "%s kept" % good)
	for bad: String in ["0", "-3", "40001", "abc", "", "1.5"]:
		var parsed: Dictionary = EnemyTrace.parse_args(
			PackedStringArray(["--scenario=smoke", "--ticks=%s" % bad])
		)
		assert_ne(parsed["error"], "", "'%s' refused" % bad)


func test_the_output_path_must_be_a_txt_file_under_build() -> void:
	var good: Dictionary = EnemyTrace.parse_args(
		PackedStringArray(["--scenario=smoke", "--out=build/trace/a.txt"])
	)
	assert_eq(good["error"], "", "a file under build/trace")
	assert_eq(good["out"], "res://build/trace/a.txt", "as a res:// path")
	for bad: String in [
		"../a.txt",
		"build/../a.txt",
		"build/trace/../../a.txt",
		"res://tests/a.txt",
		"tests/unit/a.txt",
		"build",
		"build/",
		"build/a.json",
		"build/a",
		"buildx/a.txt",
		"",
	]:
		var parsed: Dictionary = EnemyTrace.parse_args(
			PackedStringArray(["--scenario=smoke", "--out=%s" % bad])
		)
		assert_ne(parsed["error"], "", "'%s' refused" % bad)


func test_the_default_bound_comes_from_each_scenarios_own_limit() -> void:
	for scenario: String in ["smoke", "army", "walls", "full_idle"]:
		assert_eq(
			EnemyTrace.default_bound(scenario),
			ReplayScenarios.max_ticks(StringName(scenario)),
			"%s uses ReplayScenarios.max_ticks" % scenario
		)
		assert_gt(EnemyTrace.default_bound(scenario), 0, "%s has a bound" % scenario)
	assert_eq(
		EnemyTrace.default_bound("gate"),
		SimClock.ticks(GateStress.DEFAULT_MAX_SECONDS),
		"the gate uses its own time limit"
	)
	assert_eq(EnemyTrace.default_bound("nope"), 0, "an unknown name has no bound")


func test_a_smoke_trace_has_the_documented_format_and_is_the_same_twice() -> void:
	var first: Array = _trace("smoke", SMOKE_TICKS)
	var second: Array = _trace("smoke", SMOKE_TICKS)
	assert_eq(first[0], second[0], "the same text twice")
	assert_eq(first[1], SMOKE_TICKS, "the bound lowered the recorded ticks")
	assert_eq(second[1], SMOKE_TICKS, "twice")
	var lines: PackedStringArray = (first[0] as String).split("\n", false)
	assert_gt(lines.size(), 20, "enemies march within the first %d ticks" % SMOKE_TICKS)
	assert_eq(first[2], lines.size(), "the line count the run reports")
	assert_true((first[0] as String).ends_with("\n"), "every line ends with a line feed")
	var pattern: RegEx = RegEx.create_from_string(LINE_PATTERN)
	var last_tick: int = 0
	var last_id: int = 0
	for line: String in lines:
		assert_not_null(pattern.search(line), "format: %s" % line)
		var fields: PackedStringArray = line.split(" ")
		var tick: int = fields[0].to_int()
		var id: int = fields[1].to_int()
		assert_gte(tick, last_tick, "ticks never go back")
		assert_gt(id, last_id if tick == last_tick else 0, "ascending id within a tick")
		assert_lte(tick, SMOKE_TICKS, "within the bound")
		assert_gt(fields[4].to_int(), 0, "only living enemies")
		last_tick = tick
		last_id = id


func test_a_trace_line_carries_the_float32_bytes_of_both_positions() -> void:
	var enemies: EnemySystem = EnemySystem.new(SimEvents.new())
	var grunt: EnemyDef = load("res://data/enemies/grunt.tres")
	var id: int = enemies.spawn(grunt, Vector2(1.5, -2.25))
	var line: String = EnemyTrace.Collector.line_of(9, id, enemies)
	var hex: String = PackedVector2Array([Vector2(1.5, -2.25)]).to_byte_array().hex_encode()
	assert_eq(
		line,
		"9 %d %s %s %d none -1\n" % [id, hex, hex, enemies.health_of(id)],
		"position and previous, a target-less enemy"
	)
	assert_eq(hex.length(), 16, "two float32 are 16 hex digits")
	assert_eq(EnemyTrace.Collector.tick_text(9, EnemySystem.new(SimEvents.new())), "", "none")


func test_a_replay_with_the_hook_has_the_digest_it_has_without_one() -> void:
	var seen: Array[int] = [0]
	var hook: Callable = func(ctx: RunContext) -> void: seen[0] = ctx.tick_count
	var hooked: Dictionary = ReplayScenarios.run(&"smoke", 1, hook)
	assert_eq(hooked["digest"], ReplayScenarios.golden_digest(SMOKE_GOLDEN), "the golden digest")
	assert_eq(seen[0], hooked["ticks"], "the hook saw every tick up to the last")
	assert_eq(
		ReplayScenarios.run(&"smoke", 1)["digest"], hooked["digest"], "and the unhooked run agrees"
	)


func test_a_gate_run_with_the_hook_has_the_digest_it_has_without_one() -> void:
	var map: MapConfig = load(GateStress.STRESS_MAP)
	var calls: Array[int] = [0]
	var hook: Callable = func(_ctx: RunContext) -> void: calls[0] += 1
	var hooked: Dictionary = GateStress.run(map, GATE_SEED, GATE_SECONDS, hook)
	var plain: Dictionary = GateStress.run(map, GATE_SEED, GATE_SECONDS)
	assert_eq(hooked["digest"], plain["digest"], "the hook changes nothing")
	assert_eq(calls[0], SimClock.ticks(GATE_SECONDS), "once per step, up to the bound")


## [text, ticks, lines] of `scenario` traced for `bound` ticks in this process.
func _trace(scenario: String, bound: int) -> Array:
	var text: Array[String] = [""]
	var sink: Callable = func(chunk: String) -> void: text[0] += chunk
	var result: Dictionary = EnemyTrace.run_scenario(scenario, bound, sink)
	return [text[0], result["ticks"], result["lines"]]
