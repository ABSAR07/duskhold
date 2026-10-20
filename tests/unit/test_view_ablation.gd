extends GutTest
## Plan 04-24: the real-window view ablation (tools/stress/view_ablation.gd). The probe reads the
## stress night's own arguments, so the duration rule, the slice clock, the view switches and the
## saved-time arithmetic are static functions tested here on given numbers. Pure parsing and
## arithmetic: no window, no process.

const Probe := preload("res://tools/stress/view_ablation.gd")


func _check(args: Array[String]) -> String:
	return Probe.check_duration(StressNight.parse_args(PackedStringArray(args)))


func test_a_whole_number_of_trials_is_accepted_and_anything_else_refused() -> void:
	assert_eq(_check(["--duration=60", "--warmup=10", "--run=9"]), "", "60 s is two trials")
	for seconds: int in [30, 90, 120]:
		assert_eq(_check(["--duration=%d" % seconds]), "", "%d s is whole trials" % seconds)
	for seconds: int in [45, 20, 5, 75]:
		var error: String = _check(["--duration=%d" % seconds])
		assert_ne(error, "", "%d s is refused" % seconds)
		assert_false(error.contains("\n"), "%d s gives a one-line reason" % seconds)
	assert_ne(_check([]), "", "the default 20 s is not a whole trial")


func test_the_stress_night_flags_pass_and_an_unknown_flag_is_refused() -> void:
	var args: Array[String] = [
		"--duration=60", "--warmup=10", "--run=9", "--out=build/stress/ablation"
	]
	assert_eq(_check(args), "", "the four flags are accepted")
	var error: String = _check(["--duration=60", "--slices=3"])
	assert_ne(error, "", "an unknown flag is refused")
	assert_true(error.contains("unknown argument"), "it is named unknown")
	assert_ne(_check(["--duration=60", "--out=/tmp/elsewhere"]), "", "an --out outside build/")


func test_the_slice_clock_walks_six_five_second_slices_per_trial() -> void:
	var expected: Array = [
		[0.0, 1, 0, "all_on"],
		[4.99, 1, 0, "all_on"],
		[5.0, 1, 1, "enemy_views_off"],
		[29.99, 1, 5, "all_on_again"],
		[30.0, 2, 0, "all_on"],
		[59.99, 2, 5, "all_on_again"],
	]
	for row: Array in expected:
		var slice: Dictionary = Probe.slice_at(float(row[0]))
		assert_eq(slice["trial"], row[1], "trial at %s s" % row[0])
		assert_eq(slice["index"], row[2], "index at %s s" % row[0])
		assert_eq(slice["name"], row[3], "name at %s s" % row[0])
	assert_eq(Probe.slice_at(12.0)["name"], "unit_views_off", "the third slice")
	assert_eq(Probe.slice_at(17.5)["name"], "projectile_vfx_off", "the fourth slice")
	assert_eq(Probe.slice_at(22.0)["name"], "all_off", "the fifth slice")


func test_each_slice_switches_the_views_it_names() -> void:
	var expected: Dictionary = {
		"all_on": [true, true, true],
		"enemy_views_off": [false, true, true],
		"unit_views_off": [true, false, true],
		"projectile_vfx_off": [true, true, false],
		"all_off": [false, false, false],
		"all_on_again": [true, true, true],
	}
	for slice_name: String in expected:
		assert_eq(Probe.views_on(slice_name), expected[slice_name], "%s plan" % slice_name)
	assert_eq(Probe.views_on("no_such_slice"), [true, true, true], "an unknown name leaves all on")


func test_saved_is_the_median_over_trials_of_all_on_minus_the_slice() -> void:
	var one: float = Probe.saved_of(PackedFloat64Array([7.14]), PackedFloat64Array([6.09]))
	assert_almost_eq(one, 1.05, 0.0001, "one trial: the difference")
	var two: float = Probe.saved_of(
		PackedFloat64Array([7.14, 6.98]), PackedFloat64Array([6.09, 5.88])
	)
	assert_almost_eq(two, 1.075, 0.0001, "two trials: the mean of the two gains")
	var three: float = Probe.saved_of(
		PackedFloat64Array([7.0, 7.0, 7.0]), PackedFloat64Array([6.0, 4.0, 5.5])
	)
	assert_almost_eq(three, 1.5, 0.0001, "three trials: the middle gain (1.0, 3.0, 1.5)")
	assert_eq(Probe.saved_of(PackedFloat64Array(), PackedFloat64Array()), 0.0, "none is zero")
	assert_eq(
		Probe.saved_of(PackedFloat64Array([7.0]), PackedFloat64Array([6.0, 5.0])),
		0.0,
		"mismatched trial counts give zero"
	)
