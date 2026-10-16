extends GutTest
## T-04-07: the step bench's argument allowlist. Counts arrive as untrusted strings and size a
## headless run, so each is checked before anything is built. Pure parsing, no process is spawned.

const Bench := preload("res://tools/stress/step_bench.gd")
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
