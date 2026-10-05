extends GutTest
## DR-5: nothing under simulation/ may use an engine facility that would make two runs of the same
## seed diverge. A source scan, like the phase-writer scan in test_run_manager.gd: every pattern is
## proven against a known offending sample so it cannot pass vacuously, and the scan must prove it
## read the first-party sources.

const SIM_ROOT := "res://simulation"
## Directories whose math must stay on + - * / and sqrt (libm results can differ by platform).
const MATH_ROOTS: Array[String] = [
	"res://simulation/clock",
	"res://simulation/night",
	"res://simulation/king",
	"res://simulation/castle",
]
const GLOBAL_RAND := "(^|[^A-Za-z0-9_.])"
const WORD_START := "(^|[^A-Za-z0-9_])"
## [label, pattern, offending sample]
const FORBIDDEN: Array[Array] = [
	["global randi", GLOBAL_RAND + "randi\\(", "var x: int = randi()"],
	["global randf", GLOBAL_RAND + "randf\\(", "var x: float = randf()"],
	["global randi_range", GLOBAL_RAND + "randi_range\\(", "randi_range(1, 6)"],
	["global randf_range", GLOBAL_RAND + "randf_range\\(", "randf_range(0.0, 1.0)"],
	["randomize", WORD_START + "randomize\\(", "randomize()"],
	["shuffle", "\\.shuffle\\(", "items.shuffle()"],
	["pick_random", "\\.pick_random\\(", "items.pick_random()"],
	["Time", WORD_START + "Time\\.", "var t: int = Time.get_ticks_msec()"],
	["OS", WORD_START + "OS\\.", "OS.get_name()"],
	["scene tree", "get_tree\\(", "get_tree().quit()"],
	["NavigationServer", "NavigationServer", "NavigationServer3D.map_get_path()"],
	["PhysicsServer", "PhysicsServer", "PhysicsServer3D.body_create()"],
	["Engine", WORD_START + "Engine\\.get_", "Engine.get_frames_drawn()"],
]
const TRANSCENDENTAL: Array[Array] = [
	["sin", GLOBAL_RAND + "sin\\(", "var s: float = sin(angle)"],
	["cos", GLOBAL_RAND + "cos\\(", "var c: float = cos(angle)"],
	["tan", GLOBAL_RAND + "tan\\(", "var t: float = tan(angle)"],
	["atan2", GLOBAL_RAND + "atan2\\(", "atan2(v.y, v.x)"],
	["pow", GLOBAL_RAND + "pow\\(", "pow(2.0, 3.0)"],
	["lerp_angle", GLOBAL_RAND + "lerp_angle\\(", "lerp_angle(a, b, 0.5)"],
]


func _gd_files(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return found
	for sub: String in dir.get_directories():
		found.append_array(_gd_files(dir_path.path_join(sub)))
	for file_name: String in dir.get_files():
		if file_name.ends_with(".gd"):
			found.append(dir_path.path_join(file_name))
	return found


## "path: label" for every code line (comment-only lines skipped) that matches a rule. The file
## count goes into counter[0] so the caller can prove the scan read something.
func _offences(roots: Array[String], rules: Array[Array], counter: Array[int]) -> Array[String]:
	var patterns: Array[RegEx] = []
	for rule: Array in rules:
		patterns.append(RegEx.create_from_string(rule[1]))
	var found: Array[String] = []
	for root: String in roots:
		for path: String in _gd_files(root):
			counter[0] += 1
			for line: String in FileAccess.get_file_as_string(path).split("\n"):
				if line.strip_edges().begins_with("#"):
					continue
				for index: int in range(patterns.size()):
					if patterns[index].search(line) != null:
						found.append("%s: %s" % [path, rules[index][0]])
	return found


func test_the_simulation_uses_no_nondeterministic_engine_facility() -> void:
	var scanned: Array[int] = [0]
	var roots: Array[String] = [SIM_ROOT]
	var offences: Array[String] = _offences(roots, FORBIDDEN, scanned)
	assert_gt(scanned[0], 20, "the scan really read the simulation sources")
	assert_eq(offences, [] as Array[String], "no forbidden call under simulation/")


func test_the_night_math_uses_no_transcendental_function() -> void:
	var scanned: Array[int] = [0]
	var offences: Array[String] = _offences(MATH_ROOTS, TRANSCENDENTAL, scanned)
	assert_gt(scanned[0], 3, "the scan read the clock, night and king sources")
	assert_eq(offences, [] as Array[String], "no transcendental call in the night rules")


func test_every_forbidden_pattern_matches_its_own_offending_sample() -> void:
	var rules: Array[Array] = []
	rules.append_array(FORBIDDEN)
	rules.append_array(TRANSCENDENTAL)
	for rule: Array in rules:
		var pattern: RegEx = RegEx.create_from_string(rule[1])
		assert_not_null(pattern.search(rule[2]), "'%s' matches its sample" % rule[0])


func test_an_instance_call_is_not_mistaken_for_the_global_function() -> void:
	var range_pattern: RegEx = RegEx.create_from_string(FORBIDDEN[3][1])
	var int_pattern: RegEx = RegEx.create_from_string(FORBIDDEN[0][1])
	assert_null(range_pattern.search("var x: float = _spawn_rng.randf_range(-1.0, 1.0)"), "ok")
	assert_null(int_pattern.search("var n: int = rng.randi()"), "an instance call is allowed")
