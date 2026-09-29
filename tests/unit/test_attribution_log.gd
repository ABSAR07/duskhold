extends GutTest
## ART-02: every third-party file in the repository is covered by exactly one entry of the
## attribution manifest, whose licence is on the allow-list. The checks are pure functions of
## (entries, file list), so the negative cases (uncovered folder, nested prefix, disallowed
## licence) are proven on synthetic data and the same functions then run on the real repo.

const LOG_PATH := "res://assets/attribution.json"
const ASSETS_MD_PATH := "res://ASSETS.md"
const THIRD_PARTY_DIR := "res://assets/third_party/"
const ADDONS_DIR := "res://addons/"
const ALLOWED_LICENSES: Array[String] = ["CC0-1.0", "MIT"]
const REQUIRED_KEYS: Array[String] = [
	"id",
	"name",
	"kind",
	"license",
	"author",
	"source_url",
	"license_url",
	"paths",
	"retrieved",
	"sha256",
	"ships_in_build",
]
const IGNORED_SUFFIXES: Array[String] = [".import", ".uid"]
const IGNORED_NAMES: Array[String] = [".gdignore"]
const SHA256_HEX_LENGTH: int = 64


func _load_log() -> Dictionary:
	var file: FileAccess = FileAccess.open(LOG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}


func _entries() -> Array:
	var entries: Variant = _load_log().get("entries", [])
	if entries is Array:
		return entries
	return []


## Every file under `dir_path` (recursive), as res:// paths, minus import/uid sidecars.
func _list_files(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return found
	dir.list_dir_begin()
	var entry_name: String = dir.get_next()
	while entry_name != "":
		var full: String = dir_path.path_join(entry_name)
		if dir.current_is_dir():
			found.append_array(_list_files(full))
		elif not _is_ignored(entry_name):
			found.append(full)
		entry_name = dir.get_next()
	dir.list_dir_end()
	return found


func _is_ignored(file_name: String) -> bool:
	if IGNORED_NAMES.has(file_name):
		return true
	for suffix: String in IGNORED_SUFFIXES:
		if file_name.ends_with(suffix):
			return true
	return false


func _child_folders(dir_path: String) -> Array[String]:
	var folders: Array[String] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return folders
	for folder_name: String in dir.get_directories():
		folders.append(dir_path.path_join(folder_name) + "/")
	return folders


func _all_paths(entries: Array) -> Array[String]:
	var paths: Array[String] = []
	for entry: Dictionary in entries:
		for path: String in entry.get("paths", []):
			paths.append(path)
	return paths


## Files that start with no entry path, or with more than one.
func _coverage_problems(files: Array[String], entries: Array) -> Array[String]:
	var problems: Array[String] = []
	var paths: Array[String] = _all_paths(entries)
	for file_path: String in files:
		var matches: int = 0
		for path: String in paths:
			if file_path.begins_with(path):
				matches += 1
		if matches != 1:
			problems.append("%s matched %d entries" % [file_path, matches])
	return problems


func _nested_path_problems(entries: Array) -> Array[String]:
	var problems: Array[String] = []
	var paths: Array[String] = _all_paths(entries)
	for i: int in range(paths.size()):
		for j: int in range(paths.size()):
			if i != j and paths[j].begins_with(paths[i]):
				problems.append("%s is a prefix of %s" % [paths[i], paths[j]])
	return problems


func _uncovered_folders(folders: Array[String], entries: Array) -> Array[String]:
	var paths: Array[String] = _all_paths(entries)
	var missing: Array[String] = []
	for folder: String in folders:
		if not paths.has(folder):
			missing.append(folder)
	return missing


func _sorted_ids(entries: Array) -> Array[String]:
	var ids: Array[String] = []
	for entry: Dictionary in entries:
		ids.append(str(entry.get("id", "")))
	return ids


func _synthetic_entry(id: String, path: String) -> Dictionary:
	return {"id": id, "paths": [path]}


# --- the manifest file itself ---------------------------------------------------------------


func test_log_parses_with_schema_version_one() -> void:
	var manifest: Dictionary = _load_log()
	assert_false(manifest.is_empty(), "assets/attribution.json must exist and parse")
	assert_eq(manifest.get("schema_version"), 1.0, "schema_version")
	assert_gt(_entries().size(), 0, "at least the engine and GUT entries")


func test_every_entry_has_every_required_key() -> void:
	for entry: Dictionary in _entries():
		for key: String in REQUIRED_KEYS:
			assert_true(entry.has(key), "entry '%s' is missing '%s'" % [entry.get("id"), key])


func test_every_license_is_on_the_allow_list() -> void:
	for entry: Dictionary in _entries():
		var license: String = str(entry.get("license", ""))
		assert_true(
			ALLOWED_LICENSES.has(license),
			"entry '%s' has disallowed license '%s'" % [entry.get("id"), license]
		)


func test_ids_are_unique_and_sorted() -> void:
	var ids: Array[String] = _sorted_ids(_entries())
	var sorted_ids: Array[String] = ids.duplicate()
	sorted_ids.sort()
	assert_eq(ids, sorted_ids, "entries are sorted by id")
	var seen: Dictionary = {}
	for id: String in ids:
		assert_false(seen.has(id), "duplicate id '%s'" % id)
		seen[id] = true


func test_paths_are_res_folders() -> void:
	for path: String in _all_paths(_entries()):
		assert_true(path.begins_with("res://"), "%s must start with res://" % path)
		assert_true(path.ends_with("/"), "%s must end with /" % path)


func test_model_entries_carry_a_sha256() -> void:
	for entry: Dictionary in _entries():
		var sha: String = str(entry.get("sha256", ""))
		if entry.get("kind") == "model":
			assert_eq(
				sha.length(),
				SHA256_HEX_LENGTH,
				"model '%s' needs a 64-hex sha256" % entry.get("id")
			)
		if sha != "":
			assert_true(
				sha.is_valid_hex_number(false), "sha256 of '%s' must be hex" % entry.get("id")
			)
			assert_eq(sha.length(), SHA256_HEX_LENGTH, "sha256 length of '%s'" % entry.get("id"))


func test_retrieved_dates_are_iso() -> void:
	var pattern: RegEx = RegEx.create_from_string("^\\d{4}-\\d{2}-\\d{2}$")
	for entry: Dictionary in _entries():
		var retrieved: String = str(entry.get("retrieved", ""))
		assert_not_null(pattern.search(retrieved), "entry '%s' retrieved date" % entry.get("id"))


# --- coverage of the real repository --------------------------------------------------------


func test_real_entry_paths_do_not_nest() -> void:
	assert_eq(
		_nested_path_problems(_entries()), [] as Array[String], "adjacency: no nested prefixes"
	)


func test_every_third_party_file_is_covered_by_exactly_one_entry() -> void:
	var files: Array[String] = _list_files(THIRD_PARTY_DIR)
	files.append_array(_list_files(ADDONS_DIR))
	assert_eq(_coverage_problems(files, _entries()), [] as Array[String], "coverage")


func test_every_third_party_folder_has_an_entry() -> void:
	assert_eq(
		_uncovered_folders(_child_folders(THIRD_PARTY_DIR), _entries()),
		[] as Array[String],
		"each assets/third_party/<pack_id>/ folder is logged"
	)


func test_every_addon_folder_has_an_entry() -> void:
	assert_eq(
		_uncovered_folders(_child_folders(ADDONS_DIR), _entries()),
		[] as Array[String],
		"each addons/<name>/ folder is logged"
	)


# --- ASSETS.md ------------------------------------------------------------------------------


func test_assets_md_lists_every_entry_in_json_order() -> void:
	var file: FileAccess = FileAccess.open(ASSETS_MD_PATH, FileAccess.READ)
	assert_not_null(file, "ASSETS.md must exist")
	if file == null:
		return
	var text: String = file.get_as_text()
	var cursor: int = 0
	for entry: Dictionary in _entries():
		var row_start: int = text.find(str(entry.get("name")), cursor)
		assert_gt(row_start, -1, "ASSETS.md lists '%s' in order" % entry.get("name"))
		if row_start < 0:
			return
		var row_end: int = text.find("\n", row_start)
		var row: String = text.substr(row_start, row_end - row_start)
		assert_true(
			row.contains(str(entry.get("license"))),
			"row for '%s' names its license" % entry.get("name")
		)
		cursor = row_start + 1


# --- the checks themselves, on synthetic data -----------------------------------------------


func test_engine_and_gut_only_with_no_asset_folder_passes() -> void:
	var entries: Array = [
		{"id": "godot-engine", "paths": []},
		_synthetic_entry("gut", "res://addons/gut/"),
	]
	var files: Array[String] = ["res://addons/gut/gut.gd", "res://addons/gut/plugin.cfg"]
	assert_eq(_coverage_problems(files, entries), [] as Array[String])
	assert_eq(_nested_path_problems(entries), [] as Array[String])
	assert_eq(_uncovered_folders([] as Array[String], entries), [] as Array[String])


func test_asset_folder_without_entry_fails() -> void:
	var entries: Array = [_synthetic_entry("gut", "res://addons/gut/")]
	var files: Array[String] = ["res://assets/third_party/some_pack/model.glb"]
	assert_eq(_coverage_problems(files, entries).size(), 1, "uncovered file is reported")
	var folders: Array[String] = ["res://assets/third_party/some_pack/"]
	assert_eq(_uncovered_folders(folders, entries), folders, "uncovered folder is reported")


func test_nested_entry_paths_are_reported() -> void:
	var entries: Array = [
		_synthetic_entry("a", "res://assets/third_party/pack/"),
		_synthetic_entry("b", "res://assets/third_party/pack/sub/"),
	]
	assert_eq(_nested_path_problems(entries).size(), 1, "nested prefix is reported")
	var files: Array[String] = ["res://assets/third_party/pack/sub/x.glb"]
	assert_eq(_coverage_problems(files, entries).size(), 1, "double coverage is reported")


func test_import_and_uid_sidecars_are_ignored() -> void:
	assert_true(_is_ignored("model.glb.import"))
	assert_true(_is_ignored("script.gd.uid"))
	assert_true(_is_ignored(".gdignore"))
	assert_false(_is_ignored("model.glb"))
