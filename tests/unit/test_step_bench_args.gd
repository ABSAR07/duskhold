extends GutTest
## Plan 04-15: the step bench's --map and --warmup flags (the stress-night shape for the PLAT-01
## native-port measurements). Arguments arrive as untrusted strings and size a headless run, so each
## is checked before anything is built. Pure parsing, no process is spawned. The older flags are
## pinned in test_stress_tool_args.gd (that script is at the 20-test cap).

const Bench := preload("res://tools/stress/step_bench.gd")
const NEWLINE: String = "\n"


func _parse(args: Array[String]) -> Dictionary:
	return Bench.parse_args(PackedStringArray(args))


func _error_of(args: Array[String]) -> String:
	return String(_parse(args).get("error", "missing"))


func test_the_defaults_are_the_prototype_shape_with_no_warm_up() -> void:
	var parsed: Dictionary = _parse([])
	assert_eq(parsed.get("error"), "", "no error")
	assert_eq(parsed.get("map"), "prototype", "the prototype map by default")
	assert_eq(parsed.get("warmup"), 0, "no warm-up by default")
	assert_eq(parsed.get("enemies"), 300, "300 enemies as before")
	assert_eq(parsed.get("steps"), 30, "30 steps as before")
	assert_eq(parsed.get("rebuilds"), 0, "no rebuilds as before")


func test_the_stress_map_and_a_warm_up_are_read() -> void:
	var parsed: Dictionary = _parse(
		["--map=stress", "--enemies=300", "--warmup=300", "--steps=300"]
	)
	assert_eq(parsed.get("error"), "", "no error")
	assert_eq(parsed.get("map"), "stress", "the stress map")
	assert_eq(parsed.get("warmup"), 300, "a 300 step warm-up")
	assert_eq(parsed.get("enemies"), 300, "enemies")
	assert_eq(parsed.get("steps"), 300, "steps")


func test_the_prototype_map_can_be_named_and_warmed_up() -> void:
	var parsed: Dictionary = _parse(["--map=prototype", "--warmup=5"])
	assert_eq(parsed.get("error"), "", "no error")
	assert_eq(parsed.get("map"), "prototype", "named")
	assert_eq(parsed.get("warmup"), 5, "a warm-up on the prototype shape")


func test_the_warm_up_bounds_pass() -> void:
	assert_eq(_error_of(["--warmup=0"]), "", "0 passes")
	assert_eq(_error_of(["--warmup=900"]), "", "900 passes")


func test_a_warm_up_out_of_range_is_a_one_line_error() -> void:
	for arg: String in ["--warmup=-1", "--warmup=901", "--warmup=100000"]:
		var error: String = _error_of([arg])
		assert_ne(error, "", "%s is refused" % arg)
		assert_false(error.contains(NEWLINE), "%s gives a one-line reason" % arg)


func test_a_warm_up_that_is_not_an_integer_is_refused() -> void:
	for arg: String in ["--warmup=abc", "--warmup=2.5", "--warmup=", "--warmup=1e2"]:
		assert_ne(_error_of([arg]), "", "%s is refused" % arg)


func test_an_unknown_map_is_refused_with_a_one_line_error() -> void:
	for arg: String in ["--map=bogus", "--map=", "--map=Stress", "--map=stress2", "--map=../x"]:
		var error: String = _error_of([arg])
		assert_ne(error, "", "%s is refused" % arg)
		assert_false(error.contains(NEWLINE), "%s gives a one-line reason" % arg)


func test_rebuilds_with_the_stress_map_are_refused_in_either_order() -> void:
	assert_ne(_error_of(["--map=stress", "--rebuilds=4"]), "", "stress then rebuilds")
	assert_ne(_error_of(["--rebuilds=4", "--map=stress"]), "", "rebuilds then stress")
	assert_eq(_error_of(["--map=stress", "--rebuilds=0"]), "", "zero rebuilds is no rebuilds")
	assert_eq(_error_of(["--map=prototype", "--rebuilds=4"]), "", "the prototype still rebuilds")
