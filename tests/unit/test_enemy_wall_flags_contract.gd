extends GutTest
## ENMY-04, G-04-7 (owner rule change of 2026-10-19): EnemyDef.drops_blocked_targets is the per-type
## opt-out of "a melee enemy breaks through a wall to reach its target" for the Phase 6 roster. It
## defaults to false and no shipped or fixture enemy sets it, nor ignores_walls. Every file check
## is proven against a known offending sample so it cannot pass vacuously.

const ENEMY_DIR := "res://data/enemies"
const STRESS_GRUNT := "res://tools/stress/data/stress_grunt.tres"
const SCAN_ROOTS: Array[String] = ["res://data", "res://tools", "res://tests/fixtures"]
const FLAG := "drops_blocked_targets"
const SAMPLE := '[resource]\nid = &"x"\ndrops_blocked_targets = true\n'


## Every enemy definition that ships: data/enemies/*.tres plus the stress grunt.
func _shipped_defs() -> Array[EnemyDef]:
	var defs: Array[EnemyDef] = []
	var dir: DirAccess = DirAccess.open(ENEMY_DIR)
	for file_name: String in dir.get_files():
		if file_name.ends_with(".tres"):
			defs.append(load(ENEMY_DIR.path_join(file_name)) as EnemyDef)
	defs.append(load(STRESS_GRUNT) as EnemyDef)
	return defs


func _tres_files(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return found
	for sub: String in dir.get_directories():
		found.append_array(_tres_files(dir_path.path_join(sub)))
	for file_name: String in dir.get_files():
		if file_name.ends_with(".tres"):
			found.append(dir_path.path_join(file_name))
	return found


func _mentions_flag(text: String) -> bool:
	return text.find(FLAG) >= 0


func test_the_flag_defaults_to_false() -> void:
	assert_eq(EnemyDef.new().get(FLAG), false, "a new enemy breaks through to targets")


func test_no_shipped_enemy_sets_the_flag_or_ignores_walls() -> void:
	var defs: Array[EnemyDef] = _shipped_defs()
	assert_gt(defs.size(), 2, "the grunt, the skirmisher and the stress grunt were read")
	for def: EnemyDef in defs:
		assert_not_null(def, "the definition loads")
		assert_eq(def.get(FLAG), false, "%s keeps the new rule" % def.id)
		assert_false(def.ignores_walls, "%s respects walls" % def.id)


func test_no_resource_file_sets_the_flag() -> void:
	var read: int = 0
	var offenders: Array[String] = []
	for root: String in SCAN_ROOTS:
		for path: String in _tres_files(root):
			read += 1
			if _mentions_flag(FileAccess.get_file_as_string(path)):
				offenders.append(path)
	assert_gt(read, 20, "the scan really read the data, tool and fixture resources")
	assert_eq(offenders, [] as Array[String], "no .tres sets drops_blocked_targets")


func test_the_file_scan_flags_its_own_offending_sample() -> void:
	assert_true(_mentions_flag(SAMPLE), "the check fires on a file that sets the flag")
	assert_false(_mentions_flag('[resource]\nid = &"x"\n'), "and not on one that does not")


func test_a_flagged_copy_of_the_grunt_is_a_separate_resource() -> void:
	var grunt: EnemyDef = load(ENEMY_DIR.path_join("grunt.tres")) as EnemyDef
	var flagged: EnemyDef = grunt.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as EnemyDef
	flagged.set(FLAG, true)
	assert_eq(flagged.get(FLAG), true, "the copy carries the flag")
	assert_eq(grunt.get(FLAG), false, "the shipped grunt does not")
