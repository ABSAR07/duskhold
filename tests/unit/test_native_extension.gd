extends GutTest
## PLAT-01 (plan 04-14): the native simulation library built by tools/native_build.sh loads in
## this Godot binary and reports what it was built from. The library is git-ignored, so a missing
## one fails here loudly: the build is a prerequisite of the test run (hard guards follow in 04-22).

const PIN_PATH := "res://tools/godot_cpp_pin.txt"
const EXPECTED_API := "4.7.2"
const EXPECTED_REAL_T_BYTES := 4


func _pinned_sha() -> String:
	var text: String = FileAccess.get_file_as_string(PIN_PATH)
	return text.split("\n")[0].strip_edges()


func test_the_native_class_is_registered() -> void:
	assert_true(ClassDB.class_exists(&"NativeSim"), "NativeSim is registered by the extension")


func test_the_native_class_reports_a_version() -> void:
	if not ClassDB.class_exists(&"NativeSim"):
		fail_test("NativeSim is missing; run: bash tools/native_build.sh --fetch")
		return
	var version: String = String(ClassDB.class_call_static(&"NativeSim", &"version"))
	assert_ne(version, "", "the native version is not empty")


func test_the_native_class_reports_the_godot_cpp_pin() -> void:
	if not ClassDB.class_exists(&"NativeSim"):
		fail_test("NativeSim is missing; run: bash tools/native_build.sh --fetch")
		return
	var pin: String = _pinned_sha()
	assert_eq(pin.length(), 40, "tools/godot_cpp_pin.txt starts with a full commit SHA")
	var built_against: String = String(ClassDB.class_call_static(&"NativeSim", &"godot_cpp_pin"))
	assert_eq(built_against, pin, "the loaded library was built against the pinned godot-cpp")


func test_the_native_class_reports_the_engine_api_it_was_built_for() -> void:
	if not ClassDB.class_exists(&"NativeSim"):
		fail_test("NativeSim is missing; run: bash tools/native_build.sh --fetch")
		return
	var api: String = String(ClassDB.class_call_static(&"NativeSim", &"api_version"))
	assert_eq(api, EXPECTED_API, "the bindings come from the API of the pinned Godot binary")
	var version_info: Dictionary = Engine.get_version_info()
	var running: String = (
		"%d.%d.%d"
		% [int(version_info["major"]), int(version_info["minor"]), int(version_info["patch"])]
	)
	assert_eq(api, running, "the running engine is the version the library was built for")


func test_the_native_class_uses_single_precision_floats() -> void:
	if not ClassDB.class_exists(&"NativeSim"):
		fail_test("NativeSim is missing; run: bash tools/native_build.sh --fetch")
		return
	var bytes: int = int(ClassDB.class_call_static(&"NativeSim", &"real_t_bytes"))
	assert_eq(bytes, EXPECTED_REAL_T_BYTES, "real_t is 4 bytes, matching the engine's floats")
