extends GutTest
## DEV-05 / T-02-18: the replay CLI's argument allowlist. Scenario names, seeds and paths arrive as
## untrusted strings, so each is checked before anything runs or any file is written. Pure parsing,
## no process is spawned.

const Cli := preload("res://tools/replay/replay_cli.gd")


func _parse(args: Array[String]) -> Dictionary:
	return Cli.parse_args(PackedStringArray(args))


func _ok(args: Array[String]) -> bool:
	return String(_parse(args).get("error", "missing")).is_empty()


func test_a_known_scenario_is_accepted_with_its_defaults() -> void:
	var parsed: Dictionary = _parse(["--scenario=smoke"])
	assert_eq(parsed.get("error"), "", "no error")
	assert_eq(parsed.get("scenario"), &"smoke", "the scenario")
	assert_eq(parsed.get("seed"), ReplayScenarios.default_seed(&"smoke"), "its own default seed")
	assert_eq(parsed.get("twice"), false, "one run unless asked")
	assert_eq(parsed.get("write_golden"), false, "no golden write unless asked")
	assert_eq(parsed.get("out"), "res://build/replay", "the default output directory")
	assert_eq(parsed.get("expect_file"), "", "no golden comparison unless asked")


func test_an_unknown_or_missing_scenario_is_a_usage_error() -> void:
	assert_false(_ok(["--scenario=nope"]), "unknown name")
	assert_false(_ok(["--scenario="]), "empty name")
	assert_false(_ok([]), "no scenario at all")
	assert_false(_ok(["--twice"]), "flags without a scenario")


func test_both_shipped_scenario_names_are_accepted() -> void:
	assert_true(_ok(["--scenario=smoke"]), "smoke")
	assert_true(_ok(["--scenario=full_idle"]), "full_idle")


func test_any_integer_seed_is_accepted_including_zero_and_negatives() -> void:
	for text: String in ["0", "-5", "12"]:
		var parsed: Dictionary = _parse(["--scenario=smoke", "--seed=%s" % text])
		assert_eq(parsed.get("error"), "", "seed %s is accepted" % text)
		assert_eq(parsed.get("seed"), int(text), "and read back as an int")


func test_a_non_integer_seed_is_a_usage_error() -> void:
	for text: String in ["1.5", "abc", "", "1e3", "0x10"]:
		assert_false(_ok(["--scenario=smoke", "--seed=%s" % text]), "seed '%s'" % text)


func test_an_output_directory_must_stay_under_build() -> void:
	var parsed: Dictionary = _parse(["--scenario=smoke", "--out=build/replay"])
	assert_eq(parsed.get("error"), "", "build/replay is fine")
	assert_eq(parsed.get("out"), "res://build/replay", "normalised to a res:// path")
	assert_true(_ok(["--scenario=smoke", "--out=build/other/sub"]), "any depth under build/")
	assert_false(_ok(["--scenario=smoke", "--out=../x"]), "parent traversal")
	assert_false(_ok(["--scenario=smoke", "--out=build/../tests"]), "traversal through build")
	assert_false(_ok(["--scenario=smoke", "--out=tests"]), "another project directory")
	assert_false(_ok(["--scenario=smoke", "--out=build_extra"]), "a sibling that shares the prefix")
	assert_false(_ok(["--scenario=smoke", "--out="]), "empty path")


func test_an_absolute_output_directory_outside_the_project_is_rejected() -> void:
	assert_false(_ok(["--scenario=smoke", "--out=/etc"]), "a unix absolute path")
	assert_false(_ok(["--scenario=smoke", "--out=C:/Windows/Temp"]), "a windows absolute path")
	assert_false(_ok(["--scenario=smoke", "--out=C:\\Windows\\Temp"]), "backslashes too")
	var inside: String = ProjectSettings.globalize_path("res://build/replay")
	assert_true(_ok(["--scenario=smoke", "--out=%s" % inside]), "an absolute path inside build/")


func test_an_expect_file_must_be_a_json_under_tests_golden() -> void:
	var parsed: Dictionary = _parse(["--scenario=smoke", "--expect-file=tests/golden/smoke.json"])
	assert_eq(parsed.get("error"), "", "the golden file is fine")
	assert_eq(parsed.get("expect_file"), "res://tests/golden/smoke.json", "normalised")
	assert_false(_ok(["--scenario=smoke", "--expect-file=../smoke.json"]), "parent traversal")
	assert_false(_ok(["--scenario=smoke", "--expect-file=tests/golden/../smoke.json"]), "traversal")
	assert_false(_ok(["--scenario=smoke", "--expect-file=build/smoke.json"]), "wrong directory")
	assert_false(_ok(["--scenario=smoke", "--expect-file=tests/golden"]), "the directory itself")
	assert_false(_ok(["--scenario=smoke", "--expect-file=tests/golden/smoke.txt"]), "not a json")
	assert_false(_ok(["--scenario=smoke", "--expect-file="]), "empty path")


func test_flags_that_are_not_on_the_allowlist_are_rejected() -> void:
	assert_false(_ok(["--scenario=smoke", "--evil"]), "unknown flag")
	assert_false(_ok(["--scenario=smoke", "positional"]), "positional argument")
	assert_false(_ok(["--scenario=smoke", "--twice=yes"]), "a flag that takes no value")


func test_twice_and_write_golden_are_switches() -> void:
	var parsed: Dictionary = _parse(["--scenario=smoke", "--twice", "--write-golden"])
	assert_eq(parsed.get("error"), "", "both are fine together")
	assert_eq(parsed.get("twice"), true, "twice")
	assert_eq(parsed.get("write_golden"), true, "write-golden")


func test_writing_the_golden_and_comparing_to_one_cannot_be_combined() -> void:
	assert_false(
		_ok(["--scenario=smoke", "--write-golden", "--expect-file=tests/golden/smoke.json"]),
		"a run cannot both define and check the golden"
	)
