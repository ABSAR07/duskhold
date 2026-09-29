extends GutTest
## Proves the pinned toolchain: Godot 4.7.2-stable and the typed-declaration error setting.
##
## Note for later plans: rejected operations in game code return values instead of calling
## push_error(), because GUT 9.7 can count engine errors as test failures.


func test_engine_is_pinned_version() -> void:
	var info: Dictionary = Engine.get_version_info()
	assert_eq(info["major"], 4, "major version")
	assert_eq(info["minor"], 7, "minor version")
	assert_eq(info["patch"], 2, "patch version")
	assert_eq(info["status"], "stable", "release status")


func test_untyped_declarations_are_errors() -> void:
	var level: int = ProjectSettings.get_setting("debug/gdscript/warnings/untyped_declaration")
	assert_eq(level, 2, "untyped_declaration must be an error (2)")
