extends GutTest
## PLAT-01 (plan 04-14, T-04-35 and T-04-36): the C++ counterpart of test_sim_rules_guard. Nothing
## under native/src may use a facility that would make two runs of the same seed diverge, and the
## build files must keep the precise floating-point model. Every pattern is proven against a
## known offending sample so it cannot pass vacuously, and the scan must prove it read the
## sources (DirAccess and FileAccess read native/ although it carries a .gdignore). Unlike the
## GDScript guard, comments are not exempt: a forbidden token in a comment is renamed or removed.

const NATIVE_SRC := "res://native/src"
const CMAKE_PATH := "res://native/CMakeLists.txt"
const BUILD_SCRIPT_PATH := "res://tools/native_build.sh"
const SOURCE_SUFFIXES: Array[String] = [".h", ".hpp", ".cpp"]
## A call or name that does not continue an identifier ("my_sin(" and "dosin(" are not "sin(").
const BEGIN := "(?<![A-Za-z0-9_])"
const NATIVE_REQUIRED_SWITCHES: Array[String] = ["/fp:precise", "-ffp-contract=off"]
## [label, pattern, offending sample]. libm results can differ by platform and compiler, so the
## native step stays on + - * / and sqrt, exactly like the night maths of the GDScript simulation.
const FORBIDDEN_CODE: Array[Array] = [
	[
		"trigonometric call",
		(
			BEGIN
			+ "(std::)?(sin|cos|tan|asin|acos|atan|atan2|sinh|cosh|tanh|asinh|acosh|atanh)[fl]?\\s*\\("
		),
		"float s = sinf(angle);",
	],
	[
		"pow, exp, log or root call",
		BEGIN + "(std::)?(pow|exp|exp2|expm1|log|log2|log10|log1p|cbrt|hypot)[fl]?\\s*\\(",
		"float p = std::pow(a, 2.0f);",
	],
	["fused multiply-add call", BEGIN + "(std::)?fma[fl]?\\s*\\(", "float r = std::fma(a, b, c);"],
	[
		"SIMD intrinsic",
		"_mm\\d*_f?n?m(add|sub)|#\\s*include\\s*<(immintrin|x86intrin|intrin)\\.h>",
		"__m128 r = _mm_fmadd_ps(a, b, c);",
	],
	["rand or srand", BEGIN + "(std::)?(rand|srand|drand48|random)\\s*\\(", "int r = rand();"],
	["random header", "#\\s*include\\s*<random>", "#include <random>"],
	["chrono header", "#\\s*include\\s*<chrono>", "#include <chrono>"],
	["chrono namespace", "std::chrono", "auto t = std::chrono::steady_clock::now();"],
	[
		"time or clock call",
		BEGIN + "(std::)?(time|clock|clock_gettime|gettimeofday|timespec_get)\\s*\\(",
		"long t = time(nullptr);",
	],
	[
		"thread header",
		"#\\s*include\\s*<(thread|mutex|future|atomic|condition_variable)>",
		"#include <thread>",
	],
	["std thread", "std::(thread|jthread|async)", "std::thread worker(run);"],
	[
		"unordered container",
		"unordered_(map|set|multimap|multiset)",
		"std::unordered_map<int, int> by_id;",
	],
	[
		"floating-point pragma",
		(
			"#\\s*pragma\\s+(STDC|float_control|fp_contract|fenv_access|GCC\\s+optimize"
			+ "|clang\\s+fp|optimize)"
		),
		"#pragma STDC FP_CONTRACT ON",
	],
	[
		"engine singleton call",
		BEGIN + "(OS|Time|Engine|Input|InputMap|DisplayServer|ProjectSettings)::",
		"uint64_t ms = OS::get_singleton()->get_ticks_msec();",
	],
	[
		"engine singleton header",
		(
			"godot_cpp/classes/(os|time|engine|input|input_map|display_server|project_settings"
			+ "|random_number_generator|navigation_server[23]d|physics_server[23]d)\\.hpp"
		),
		"#include <godot_cpp/classes/os.hpp>",
	],
	[
		"RandomNumberGenerator",
		BEGIN + "RandomNumberGenerator",
		"Ref<RandomNumberGenerator> rng;",
	],
	["NavigationServer", "NavigationServer[23]D", "NavigationServer3D::get_singleton();"],
	["PhysicsServer", "PhysicsServer[23]D", "PhysicsServer3D::get_singleton();"],
	[
		"Godot utility randomness",
		"UtilityFunctions::(randi|randf|randi_range|randf_range|randomize|randfn|seed|rand_from_seed)",
		"double r = UtilityFunctions::randf();",
	],
]
## Switches the build files must never carry. [label, pattern, offending sample, literal that
## tools/native_build.sh must also refuse in compile_commands.json].
const FORBIDDEN_SWITCHES: Array[Array] = [
	["MSVC fast model", "/fp:fast", "target_compile_options(t PRIVATE /fp:fast)", "/fp:fast"],
	[
		"MSVC contraction",
		"/fp:contract",
		"target_compile_options(t PRIVATE /fp:contract)",
		"/fp:contract",
	],
	["fast math", "-ffast-math", "target_compile_options(t PRIVATE -ffast-math)", "-ffast-math"],
	["Ofast", "-Ofast", "target_compile_options(t PRIVATE -Ofast)", "-Ofast"],
	[
		"unsafe math",
		"-funsafe-math-optimizations|-ffinite-math-only|-fassociative-math|-freciprocal-math",
		"target_compile_options(t PRIVATE -fassociative-math)",
		"-funsafe-math-optimizations",
	],
	[
		"FMA contraction",
		"-ffp-contract=(fast|on)",
		"target_compile_options(t PRIVATE -ffp-contract=fast)",
		"-ffp-contract=",
	],
	["FMA instructions", "-mfma", "target_compile_options(t PRIVATE -mfma)", "-mfma"],
	["AVX (GCC)", "-mavx", "target_compile_options(t PRIVATE -mavx2)", "-mavx"],
	["AVX (MSVC)", "/arch:AVX", "target_compile_options(t PRIVATE /arch:AVX2)", "/arch:AVX"],
	["host architecture", "-march=", "target_compile_options(t PRIVATE -march=native)", "-march="],
	["host tuning", "-mtune=", "target_compile_options(t PRIVATE -mtune=native)", "-mtune="],
]


func _native_sources() -> Array[String]:
	var found: Array[String] = []
	var dir: DirAccess = DirAccess.open(NATIVE_SRC)
	if dir == null:
		return found
	for file_name: String in dir.get_files():
		for suffix: String in SOURCE_SUFFIXES:
			if file_name.ends_with(suffix):
				found.append(NATIVE_SRC.path_join(file_name))
	found.sort()
	return found


func _offences_in(text: String, rules: Array[Array]) -> Array[String]:
	var found: Array[String] = []
	for rule: Array in rules:
		var pattern: RegEx = RegEx.create_from_string(rule[1])
		for line: String in text.split("\n"):
			if pattern.search(line) != null:
				found.append("%s: %s" % [rule[0], line.strip_edges()])
	return found


## The non-comment lines of a CMake file (a switch named in prose is not a switch).
func _cmake_code(path: String) -> String:
	var kept: Array[String] = []
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		if not line.strip_edges().begins_with("#"):
			kept.append(line)
	return "\n".join(kept)


func test_the_scan_reads_the_native_sources() -> void:
	var sources: Array[String] = _native_sources()
	gut.p("native_rules_guard scanned %d native source files" % sources.size())
	assert_gte(sources.size(), 2, "the scan really read files under res://native/src")
	for path: String in sources:
		assert_gt(FileAccess.get_file_as_string(path).length(), 0, "%s is not empty" % path)


func test_the_native_sources_use_no_nondeterministic_facility() -> void:
	var offences: Array[String] = []
	for path: String in _native_sources():
		for offence: String in _offences_in(FileAccess.get_file_as_string(path), FORBIDDEN_CODE):
			offences.append("%s: %s" % [path, offence])
	assert_eq(offences, [] as Array[String], "no forbidden call, header or singleton in native/src")


func test_every_forbidden_code_pattern_matches_its_own_offending_sample() -> void:
	for rule: Array in FORBIDDEN_CODE:
		var pattern: RegEx = RegEx.create_from_string(rule[1])
		assert_not_null(pattern, "'%s' compiles" % rule[0])
		assert_not_null(pattern.search(rule[2]), "'%s' matches its sample" % rule[0])


func test_an_identifier_that_merely_contains_a_function_name_is_allowed() -> void:
	var trig: RegEx = RegEx.create_from_string(FORBIDDEN_CODE[0][1])
	var power: RegEx = RegEx.create_from_string(FORBIDDEN_CODE[1][1])
	var clock: RegEx = RegEx.create_from_string(FORBIDDEN_CODE[8][1])
	assert_null(trig.search("float v = my_sin(angle);"), "my_sin( is not sin(")
	assert_null(power.search("float v = dilog(x);"), "dilog( is not log(")
	assert_null(clock.search("int64_t t = get_tick_time(x);"), "get_tick_time( is not time(")
	assert_null(trig.search("float v = sqrt(x) + a * b;"), "sqrt and arithmetic are allowed")


func test_a_forbidden_token_in_a_comment_is_still_caught() -> void:
	var sample: String = "// switch to std::pow(a, b) later"
	assert_gt(_offences_in(sample, FORBIDDEN_CODE).size(), 0, "comments are not exempt")


func test_the_cmake_build_names_the_precise_floating_point_model() -> void:
	var code: String = _cmake_code(CMAKE_PATH)
	assert_gt(code.length(), 0, "native/CMakeLists.txt was read")
	for switch: String in NATIVE_REQUIRED_SWITCHES:
		assert_true(code.contains(switch), "native/CMakeLists.txt names %s" % switch)


func test_the_cmake_build_carries_no_forbidden_switch() -> void:
	var offences: Array[String] = _offences_in(_cmake_code(CMAKE_PATH), FORBIDDEN_SWITCHES)
	assert_eq(offences, [] as Array[String], "no fast-math, FMA, AVX or host-tuned switch")


func test_the_negated_fast_math_switch_is_not_mistaken_for_fast_math() -> void:
	var fast_math: RegEx = RegEx.create_from_string(FORBIDDEN_SWITCHES[2][1])
	assert_null(fast_math.search("-ffp-contract=off -fno-fast-math -Wall"), "-fno-fast-math is ok")
	var contraction: RegEx = RegEx.create_from_string(FORBIDDEN_SWITCHES[5][1])
	assert_null(contraction.search("-ffp-contract=off"), "-ffp-contract=off is ok")


func test_every_forbidden_switch_pattern_matches_its_own_offending_sample() -> void:
	for rule: Array in FORBIDDEN_SWITCHES:
		var pattern: RegEx = RegEx.create_from_string(rule[1])
		assert_not_null(pattern, "'%s' compiles" % rule[0])
		assert_not_null(pattern.search(rule[2]), "'%s' matches its sample" % rule[0])


func test_the_build_script_scans_the_compile_commands_for_the_same_switches() -> void:
	var script: String = FileAccess.get_file_as_string(BUILD_SCRIPT_PATH)
	assert_gt(script.length(), 0, "tools/native_build.sh was read")
	assert_true(script.contains("compile_commands.json"), "the script reads compile_commands.json")
	assert_true(script.contains("FORBIDDEN_SWITCHES"), "the script has its forbidden-switch scan")
	for rule: Array in FORBIDDEN_SWITCHES:
		assert_true(script.contains(rule[3]), "the script refuses %s (%s)" % [rule[3], rule[0]])
	for switch: String in NATIVE_REQUIRED_SWITCHES:
		assert_true(script.contains(switch), "the script requires %s in the commands" % switch)
