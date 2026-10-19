extends GutTest
## Plan 04-20: the step-attribution probe (tools/stress/step_attribution.gd). Its arguments arrive
## as untrusted strings and size a headless run, so each is checked before anything is built; its
## PHASE arithmetic and median live in static functions tested here on given numbers; and the four
## variants must differ in the plots they buy and nothing else. Pure parsing and arithmetic, no
## process is spawned.

const Probe := preload("res://tools/stress/step_attribution.gd")
const NEWLINE: String = "\n"


func _parse(args: Array[String]) -> Dictionary:
	return Probe.parse_args(PackedStringArray(args))


func _error_of(args: Array[String]) -> String:
	return String(_parse(args).get("error", "missing"))


func _built_count(variant: String) -> int:
	var ctx: RunContext = Probe.build_context(variant, 8)
	return ctx.buildings.standing_spot_ids().size()


func test_the_defaults_are_the_documented_ones() -> void:
	var parsed: Dictionary = _parse([])
	assert_eq(parsed.get("error"), "", "no error")
	assert_eq(parsed.get("enemies"), 300, "300 enemies")
	assert_eq(parsed.get("warmup"), 300, "a 300 step warm-up")
	assert_eq(parsed.get("steps"), 300, "300 timed steps")
	assert_eq(parsed.get("runs"), 3, "3 runs")
	assert_eq(parsed.get("out"), "res://build/bench/attribution.txt", "the default output")


func test_every_flag_is_read() -> void:
	var parsed: Dictionary = _parse(
		[
			"--enemies=120",
			"--warmup=50",
			"--steps=40",
			"--runs=5",
			"--out=build/bench/other.txt",
		]
	)
	assert_eq(parsed.get("error"), "", "no error")
	assert_eq(parsed.get("enemies"), 120, "enemies")
	assert_eq(parsed.get("warmup"), 50, "warmup")
	assert_eq(parsed.get("steps"), 40, "steps")
	assert_eq(parsed.get("runs"), 5, "runs")
	assert_eq(parsed.get("out"), "res://build/bench/other.txt", "out")


func test_the_bounds_pass() -> void:
	for arg: String in [
		"--enemies=4",
		"--enemies=1000",
		"--warmup=0",
		"--warmup=900",
		"--steps=1",
		"--steps=600",
		"--runs=1",
		"--runs=9",
	]:
		assert_eq(_error_of([arg]), "", "%s passes" % arg)


func test_values_out_of_range_are_one_line_errors() -> void:
	for arg: String in [
		"--enemies=0",
		"--enemies=1004",
		"--warmup=-1",
		"--warmup=901",
		"--steps=0",
		"--steps=601",
		"--runs=0",
		"--runs=10",
	]:
		var error: String = _error_of([arg])
		assert_ne(error, "", "%s is refused" % arg)
		assert_false(error.contains(NEWLINE), "%s gives a one-line reason" % arg)


func test_an_enemy_total_that_is_not_a_multiple_of_four_is_refused() -> void:
	for arg: String in ["--enemies=5", "--enemies=301", "--enemies=998", "--enemies=7"]:
		var error: String = _error_of([arg])
		assert_ne(error, "", "%s is refused" % arg)
		assert_false(error.contains(NEWLINE), "%s gives a one-line reason" % arg)


func test_values_that_are_not_integers_are_refused() -> void:
	for arg: String in ["--enemies=abc", "--steps=2.5", "--runs=", "--warmup=1e2", "--runs= 3"]:
		assert_ne(_error_of([arg]), "", "%s is refused" % arg)


func test_an_unknown_flag_is_refused() -> void:
	for arg: String in ["--bogus", "--map=stress", "enemies=300", "--rebuilds=2", "-x"]:
		var error: String = _error_of([arg])
		assert_ne(error, "", "%s is refused" % arg)
		assert_true(error.contains("unknown"), "%s is named unknown" % arg)


func test_an_output_path_that_leaves_build_is_refused() -> void:
	for arg: String in [
		"--out=../attribution.txt",
		"--out=build/../x.txt",
		"--out=/tmp/attribution.txt",
		"--out=C:/Windows/attribution.txt",
		"--out=data/attribution.txt",
		"--out=res://simulation/x.txt",
		"--out=build",
		"--out=build/bench/attribution.gd",
		"--out=",
	]:
		var error: String = _error_of([arg])
		assert_ne(error, "", "%s is refused" % arg)
		assert_false(error.contains(NEWLINE), "%s gives a one-line reason" % arg)


func test_phase_arithmetic_is_total_minus_each_variant_and_rest_is_the_remainder() -> void:
	var phases: Dictionary = Probe.phases_of(
		{"full": 4.5, "no_towers": 3.0, "no_squads": 2.25, "enemies_only": 0.75}
	)
	assert_almost_eq(float(phases["total"]), 4.5, 0.0001, "total is the full variant")
	assert_almost_eq(float(phases["towers"]), 1.5, 0.0001, "towers is full minus no_towers")
	assert_almost_eq(float(phases["squads"]), 2.25, 0.0001, "squads is full minus no_squads")
	assert_almost_eq(float(phases["enemies"]), 0.75, 0.0001, "enemies is enemies_only")
	assert_almost_eq(float(phases["rest"]), 0.0, 0.0001, "rest is what is left: 4.5-1.5-2.25-0.75")


func test_rest_can_be_negative_when_the_pieces_overlap() -> void:
	var phases: Dictionary = Probe.phases_of(
		{"full": 4.0, "no_towers": 2.0, "no_squads": 1.0, "enemies_only": 1.5}
	)
	assert_almost_eq(float(phases["rest"]), 4.0 - 2.0 - 3.0 - 1.5, 0.0001, "overlap goes negative")


func test_the_median_is_the_middle_value_or_the_mean_of_the_two_middle_ones() -> void:
	assert_eq(Probe.median_of(PackedFloat64Array()), 0.0, "empty is 0")
	assert_eq(Probe.median_of(PackedFloat64Array([2.0])), 2.0, "one value")
	assert_eq(Probe.median_of(PackedFloat64Array([5.0, 1.0, 3.0])), 3.0, "odd count, unsorted")
	assert_eq(Probe.median_of(PackedFloat64Array([4.0, 1.0, 3.0, 2.0])), 2.5, "even count")
	var input: PackedFloat64Array = PackedFloat64Array([3.0, 1.0, 2.0])
	Probe.median_of(input)
	assert_eq(input, PackedFloat64Array([3.0, 1.0, 2.0]), "the input is not sorted in place")


func test_the_report_has_the_documented_lines_in_order() -> void:
	var parsed: Dictionary = _parse(["--runs=2", "--enemies=40", "--warmup=1", "--steps=2"])
	var lines: Array[String] = Probe.report_lines(
		{"full": 4.5, "no_towers": 3.0, "no_squads": 2.25, "enemies_only": 0.75}, parsed
	)
	assert_eq(lines.size(), 10, "four VARIANT, five PHASE and the OK line")
	assert_eq(lines[0], "VARIANT full mean_ms=4.50", "full first")
	assert_eq(lines[1], "VARIANT no_towers mean_ms=3.00", "then no_towers")
	assert_eq(lines[2], "VARIANT no_squads mean_ms=2.25", "then no_squads")
	assert_eq(lines[3], "VARIANT enemies_only mean_ms=0.75", "then enemies_only")
	assert_eq(lines[4], "PHASE total ms=4.50", "total")
	assert_eq(lines[5], "PHASE towers ms=1.50", "towers")
	assert_eq(lines[6], "PHASE squads ms=2.25", "squads")
	assert_eq(lines[7], "PHASE enemies ms=0.75", "enemies")
	assert_eq(lines[8], "PHASE rest ms=0.00", "rest")
	assert_eq(lines[9], "STEP_ATTRIBUTION_OK runs=2 enemies=40 warmup=1 steps=2", "last")


func test_the_variants_differ_only_in_the_plots_they_buy() -> void:
	assert_eq(_built_count("full"), 22, "every plot: 20 towers and 2 barracks")
	assert_eq(_built_count("no_towers"), 2, "the towers left unbuilt")
	assert_eq(_built_count("no_squads"), 20, "the barracks left unbuilt")
	assert_eq(_built_count("enemies_only"), 0, "neither")
	for variant: String in Probe.VARIANTS:
		var ctx: RunContext = Probe.build_context(variant, 8)
		assert_gt(ctx.walls.intact_count(), 0, "%s: the gate wall stands" % variant)


func test_every_variant_starts_the_same_night_with_the_king_parked() -> void:
	for variant: String in Probe.VARIANTS:
		var ctx: RunContext = Probe.build_context(variant, 8)
		assert_eq(ctx.king.get_position(), Probe.KING_PARK, "%s: the king is parked" % variant)
		assert_eq(ctx.king.get_def().max_health, Probe.KING_HEALTH, "%s: the king's pool" % variant)
		var shipped: MapConfig = load(Probe.STRESS_MAP_PATH)
		assert_eq(ctx.map.nights.size(), shipped.nights.size(), "%s: the same nights" % variant)
		for night: NightDef in ctx.map.nights:
			for group: SpawnGroupDef in night.groups:
				assert_eq(group.count, 2, "%s: the total over four groups" % variant)
		assert_eq(shipped.nights[0].groups[0].count > 2, true, "the shipped map is not edited")
