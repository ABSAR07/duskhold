extends GutTest
## Plan 04-24: the argument allowlist of the per-view fill bench (tools/stress/view_fill_bench.gd).
## The arguments arrive as untrusted strings and size a headless run, so each is checked before
## anything is built. Pure parsing, no process is spawned.

const Bench := preload("res://tools/stress/view_fill_bench.gd")
const NEWLINE: String = "\n"


func _parse(args: Array[String]) -> Dictionary:
	return Bench.parse_args(PackedStringArray(args))


func _error_of(args: Array[String]) -> String:
	return String(_parse(args).get("error", "missing"))


func test_the_defaults_are_the_documented_ones() -> void:
	var parsed: Dictionary = _parse(["--view=arrows"])
	assert_eq(parsed.get("error"), "", "no error")
	assert_eq(parsed.get("view"), "arrows", "the view")
	assert_eq(parsed.get("warmup"), 1440, "a 1440 frame warm-up")
	assert_eq(parsed.get("frames"), 720, "720 timed frames")


func test_each_of_the_four_views_is_read() -> void:
	for view_name: String in ["arrows", "enemies", "units", "puffs"]:
		var parsed: Dictionary = _parse(["--view=%s" % view_name])
		assert_eq(parsed.get("error"), "", "%s passes" % view_name)
		assert_eq(parsed.get("view"), view_name, "%s is read" % view_name)


func test_warmup_and_frames_are_read() -> void:
	var parsed: Dictionary = _parse(["--view=units", "--warmup=10", "--frames=20"])
	assert_eq(parsed.get("error"), "", "no error")
	assert_eq(parsed.get("warmup"), 10, "warmup")
	assert_eq(parsed.get("frames"), 20, "frames")


func test_the_bounds_pass() -> void:
	for arg: String in ["--warmup=0", "--warmup=4320", "--frames=1", "--frames=4320"]:
		assert_eq(_error_of(["--view=enemies", arg]), "", "%s passes" % arg)


func test_a_missing_view_is_refused() -> void:
	var error: String = _error_of([])
	assert_ne(error, "", "no view is refused")
	assert_true(error.contains("--view"), "the reason names the flag")
	assert_ne(_error_of(["--frames=10"]), "", "numbers alone are refused")


func test_an_unknown_view_is_refused() -> void:
	for arg: String in ["--view=towers", "--view=", "--view=Arrows"]:
		var error: String = _error_of([arg])
		assert_ne(error, "", "%s is refused" % arg)
		assert_false(error.contains(NEWLINE), "%s gives a one-line reason" % arg)


func test_values_out_of_range_are_one_line_errors() -> void:
	for arg: String in [
		"--warmup=-1",
		"--warmup=4321",
		"--frames=0",
		"--frames=4321",
		"--frames=ten",
		"--warmup=1.5"
	]:
		var error: String = _error_of(["--view=arrows", arg])
		assert_ne(error, "", "%s is refused" % arg)
		assert_false(error.contains(NEWLINE), "%s gives a one-line reason" % arg)


func test_an_unknown_flag_is_refused() -> void:
	for arg: String in ["--runs=3", "--out=build/x.txt", "view=arrows", "--enemies=300"]:
		var error: String = _error_of(["--view=arrows", arg])
		assert_ne(error, "", "%s is refused" % arg)
		assert_true(error.contains("unknown argument"), "%s is named unknown" % arg)
