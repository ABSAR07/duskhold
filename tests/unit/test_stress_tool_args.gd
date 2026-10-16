extends GutTest
## T-04-07: the step bench's argument allowlist. Counts arrive as untrusted strings and size a
## headless run, so each is checked before anything is built. Pure parsing, no process is spawned.
## The gate stress CLI's allowlist (T-04-20) is pinned below the step bench's, then the stress
## night, the frame report CLI and the step bench's rebuild probe (T-04-24).

const Bench := preload("res://tools/stress/step_bench.gd")
const GateCli := preload("res://tools/stress/gate_stress_cli.gd")
const FrameCli := preload("res://tools/stress/frame_report_cli.gd")
const NEWLINE: String = "\n"


func _parse(args: Array[String]) -> Dictionary:
	return Bench.parse_args(PackedStringArray(args))


func _ok(args: Array[String]) -> bool:
	return String(_parse(args).get("error", "missing")).is_empty()


func test_no_arguments_give_the_defaults() -> void:
	var parsed: Dictionary = _parse([])
	assert_eq(parsed.get("error"), "", "no error")
	assert_eq(parsed.get("enemies"), 300, "300 enemies")
	assert_eq(parsed.get("steps"), 30, "30 steps")


func test_both_flags_are_read() -> void:
	var parsed: Dictionary = _parse(["--enemies=300", "--steps=30"])
	assert_eq(parsed.get("error"), "", "no error")
	assert_eq(parsed.get("enemies"), 300, "enemies")
	assert_eq(parsed.get("steps"), 30, "steps")
	var other: Dictionary = _parse(["--steps=600", "--enemies=1"])
	assert_eq([other.get("enemies"), other.get("steps")], [1, 600], "the bounds themselves pass")


func test_out_of_range_counts_are_a_one_line_error() -> void:
	for arg: String in [
		"--enemies=0", "--enemies=1001", "--steps=0", "--steps=601", "--enemies=-5"
	]:
		var error: String = String(_parse([arg]).get("error", ""))
		assert_false(error.is_empty(), "%s is refused" % arg)
		assert_false(error.contains(NEWLINE), "%s gives a one-line reason" % arg)


func test_a_non_integer_value_is_refused() -> void:
	assert_false(_ok(["--enemies=abc"]), "letters")
	assert_false(_ok(["--enemies=3.5"]), "a fraction")
	assert_false(_ok(["--steps="]), "empty")
	assert_false(_ok(["--steps=1e2"]), "an exponent")


func test_an_unknown_flag_or_stray_word_is_refused() -> void:
	assert_false(_ok(["--bogus=1"]), "unknown flag")
	assert_false(_ok(["300"]), "a bare word")
	assert_false(_ok(["--out=build/x"]), "no path argument exists")
	assert_false(_ok(["--enemies=300", "--twice"]), "one bad flag fails the lot")


func test_percentile_95_takes_the_nearest_rank() -> void:
	var sorted_ms: PackedFloat64Array = PackedFloat64Array()
	for value: int in range(1, 21):
		sorted_ms.append(float(value))
	assert_eq(Bench.percentile_95(sorted_ms), 19.0, "the 19th of 20")
	assert_eq(Bench.percentile_95(PackedFloat64Array()), 0.0, "an empty list reads 0")


func _gate(args: Array[String]) -> Dictionary:
	return GateCli.parse_args(PackedStringArray(args))


func _gate_ok(args: Array[String]) -> bool:
	return String(_gate(args).get("error", "missing")).is_empty()


func test_gate_stress_defaults_with_no_arguments() -> void:
	var parsed: Dictionary = _gate([])
	assert_eq(parsed.get("error"), "", "no error")
	assert_eq(parsed.get("seed"), 1, "seed 1")
	assert_false(parsed.get("twice"), "once")
	assert_eq(parsed.get("max_seconds"), 60.0, "T_max 60 s")
	assert_eq(parsed.get("out"), "res://build/stress", "output under build/stress")


func test_gate_stress_accepts_its_four_flags() -> void:
	var parsed: Dictionary = _gate(
		["--twice", "--seed=7", "--max-seconds=60", "--out=build/stress"]
	)
	assert_eq(parsed.get("error"), "", "no error")
	assert_true(parsed.get("twice"), "twice")
	assert_eq(parsed.get("seed"), 7, "seed")
	assert_eq(parsed.get("max_seconds"), 60.0, "seconds")
	assert_eq(parsed.get("out"), "res://build/stress", "out")
	assert_true(_gate_ok(["--max-seconds=10"]), "the lower bound itself passes")
	assert_true(_gate_ok(["--max-seconds=300"]), "the upper bound itself passes")


func test_gate_stress_refuses_a_time_limit_outside_ten_to_three_hundred() -> void:
	for arg: String in [
		"--max-seconds=5", "--max-seconds=301", "--max-seconds=-1", "--max-seconds=x"
	]:
		var error: String = String(_gate([arg]).get("error", ""))
		assert_false(error.is_empty(), "%s is refused" % arg)
		assert_false(error.contains(NEWLINE), "%s gives a one-line reason" % arg)


func test_gate_stress_refuses_a_path_that_leaves_build() -> void:
	for arg: String in [
		"--out=../x", "--out=C:/x", "--out=/tmp/x", "--out=data", "--out=build/../x"
	]:
		var error: String = String(_gate([arg]).get("error", ""))
		assert_false(error.is_empty(), "%s is refused" % arg)
		assert_false(error.contains(NEWLINE), "%s gives a one-line reason" % arg)


func test_gate_stress_takes_no_map_and_no_unknown_flag() -> void:
	assert_false(_gate_ok(["--map=anything"]), "no map argument exists")
	assert_false(_gate_ok(["--map=res://data/maps/prototype_map.tres"]), "nor a data path")
	assert_false(_gate_ok(["--bogus"]), "unknown flag")
	assert_false(_gate_ok(["300"]), "a bare word")
	assert_false(_gate_ok(["--seed=abc"]), "a seed that is not an integer")
	assert_false(_gate_ok(["--twice", "--bogus"]), "one bad flag fails the lot")


func _night(args: Array[String]) -> Dictionary:
	return StressNight.parse_args(PackedStringArray(args))


func _night_ok(args: Array[String]) -> bool:
	return String(_night(args).get("error", "missing")).is_empty()


func _frame(args: Array[String]) -> Dictionary:
	return FrameCli.parse_args(PackedStringArray(args))


func _frame_ok(args: Array[String]) -> bool:
	return String(_frame(args).get("error", "missing")).is_empty()


func test_stress_night_defaults_with_no_arguments() -> void:
	var parsed: Dictionary = _night([])
	assert_eq(parsed.get("error"), "", "no error")
	assert_eq(parsed.get("duration"), 20, "20 s measured")
	assert_eq(parsed.get("warmup"), 10, "10 s warm-up")
	assert_eq(parsed.get("run"), 1, "run 1")
	assert_eq(parsed.get("out"), "res://build/stress", "output under build/stress")


func test_stress_night_accepts_its_four_flags_and_their_bounds() -> void:
	var parsed: Dictionary = _night(
		["--duration=20", "--warmup=10", "--run=1", "--out=build/stress"]
	)
	assert_eq(parsed.get("error"), "", "no error")
	assert_eq(
		[parsed.get("duration"), parsed.get("warmup"), parsed.get("run")], [20, 10, 1], "read"
	)
	for arg: String in ["--duration=5", "--duration=120", "--warmup=0", "--warmup=60", "--run=9"]:
		assert_true(_night_ok([arg]), "%s passes at its bound" % arg)


func test_stress_night_refuses_values_outside_the_bounds() -> void:
	for arg: String in [
		"--duration=4",
		"--duration=121",
		"--run=0",
		"--run=10",
		"--warmup=-1",
		"--warmup=61",
		"--duration=x",
		"--run=1.5",
		"--duration="
	]:
		var error: String = String(_night([arg]).get("error", ""))
		assert_false(error.is_empty(), "%s is refused" % arg)
		assert_false(error.contains(NEWLINE), "%s gives a one-line reason" % arg)


func test_stress_night_refuses_a_path_that_leaves_build_and_unknown_flags() -> void:
	for arg: String in [
		"--out=../x", "--out=C:/x", "--out=/tmp/x", "--out=data", "--out=build/../x"
	]:
		assert_false(_night_ok([arg]), "%s is refused" % arg)
	assert_false(_night_ok(["--map=anything"]), "no map argument exists")
	assert_false(_night_ok(["--bogus"]), "unknown flag")
	assert_false(_night_ok(["20"]), "a bare word")
	assert_false(_night_ok(["--run=1", "--bogus"]), "one bad flag fails the lot")


func test_frame_report_cli_defaults_with_no_arguments() -> void:
	var parsed: Dictionary = _frame([])
	assert_eq(parsed.get("error"), "", "no error")
	assert_eq(parsed.get("input"), "res://build/stress", "input under build/stress")
	assert_eq(parsed.get("runs"), 3, "three runs")
	assert_eq(parsed.get("budget_ms"), FrameReport.BUDGET_P95_MS, "the documented budget")


func test_frame_report_cli_accepts_its_three_flags() -> void:
	var parsed: Dictionary = _frame(["--in=build/stress", "--runs=3", "--budget-ms=8.0"])
	assert_eq(parsed.get("error"), "", "no error")
	assert_eq(parsed.get("input"), "res://build/stress", "input")
	assert_eq(parsed.get("runs"), 3, "runs")
	assert_eq(parsed.get("budget_ms"), 8.0, "budget")
	assert_true(_frame_ok(["--runs=1"]), "the lower bound passes")
	assert_true(_frame_ok(["--runs=9"]), "the upper bound passes")
	assert_true(_frame_ok(["--budget-ms=1000"]), "the largest budget passes")


func test_frame_report_cli_refuses_bad_counts_budgets_folders_and_flags() -> void:
	for arg: String in [
		"--runs=0",
		"--runs=10",
		"--runs=x",
		"--budget-ms=-1",
		"--budget-ms=0",
		"--budget-ms=1001",
		"--budget-ms=abc",
		"--in=../x",
		"--in=data",
		"--in=C:/x"
	]:
		var error: String = String(_frame([arg]).get("error", ""))
		assert_false(error.is_empty(), "%s is refused" % arg)
		assert_false(error.contains(NEWLINE), "%s gives a one-line reason" % arg)
	assert_false(_frame_ok(["--bogus"]), "unknown flag")
	assert_false(_frame_ok(["3"]), "a bare word")


func test_step_bench_rebuilds_default_to_none_and_accept_zero_to_sixty_four() -> void:
	assert_eq(_parse([]).get("rebuilds"), 0, "the bench is exactly as before without the flag")
	assert_eq(_parse(["--rebuilds=16"]).get("rebuilds"), 16, "16 rebuilds")
	assert_true(_ok(["--rebuilds=0"]), "0 passes")
	assert_true(_ok(["--rebuilds=64"]), "64 passes")
	assert_true(_ok(["--enemies=300", "--steps=30", "--rebuilds=16"]), "with the other flags")


func test_step_bench_refuses_bad_rebuild_counts() -> void:
	for arg: String in [
		"--rebuilds=-1", "--rebuilds=65", "--rebuilds=x", "--rebuilds=3.5", "--rebuilds="
	]:
		var error: String = String(_parse([arg]).get("error", ""))
		assert_false(error.is_empty(), "%s is refused" % arg)
		assert_false(error.contains(NEWLINE), "%s gives a one-line reason" % arg)
