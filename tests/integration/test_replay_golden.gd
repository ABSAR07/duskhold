extends GutTest
## DEV-05: the smoke scenario replays to the same digest twice in one process and to the checked-in
## golden. The scenario runs on frozen fixture data, so a balance retune of data/ never moves it.
## The test uses the very run and golden lookup the replay CLI uses.

const GOLDEN := "res://tests/golden/smoke.json"
const FIXTURE_MAPS: Array[String] = [
	"res://tests/fixtures/fixture_map_replay_smoke.tres",
	"res://tests/fixtures/fixture_king_replay_smoke.tres",
	"res://tests/fixtures/fixture_tuning_replay_smoke.tres",
]
const SEED: int = 1


func _event_names(lines: PackedStringArray) -> Array[String]:
	var names: Array[String] = []
	for line: String in lines:
		names.append(line.split(" ")[1])
	return names


func _count_attacks(lines: PackedStringArray, attacker_kind: String, flying: bool) -> int:
	var count: int = 0
	for line: String in lines:
		var parts: PackedStringArray = line.split(" ")
		if parts[1] != "attack_fired" or parts[2] != attacker_kind:
			continue
		if (int(parts[6]) > 0) == flying:
			count += 1
	return count


func test_two_runs_of_the_smoke_scenario_give_the_same_digest_as_the_golden() -> void:
	var first: Dictionary = ReplayScenarios.run(&"smoke", SEED)
	var second: Dictionary = ReplayScenarios.run(&"smoke", SEED)
	var golden: String = ReplayScenarios.golden_digest(GOLDEN)
	assert_eq(String(first.get("digest", "")).length(), 64, "a sha256 digest")
	assert_eq(first.get("digest"), second.get("digest"), "same process, same digest")
	assert_eq(first.get("line_count"), second.get("line_count"), "same number of lines")
	assert_ne(golden, "", "the golden file holds a digest for this platform")
	assert_eq(first.get("digest"), golden, "and it is the checked-in golden")


func test_the_smoke_scenario_is_a_win() -> void:
	var result: Dictionary = ReplayScenarios.run(&"smoke", SEED)
	assert_eq(result.get("outcome"), &"won", "the scripted run clears every night")
	assert_lt(int(result.get("ticks", -1)), ReplayScenarios.max_ticks(&"smoke"), "inside its bound")


func test_the_smoke_log_exercises_every_event_family_the_digest_must_guard() -> void:
	var lines: PackedStringArray = ReplayScenarios.run(&"smoke", SEED).get("lines", [])
	var names: Array[String] = _event_names(lines)
	for event_name: String in [
		"enemy_spawned",
		"building_destroyed",
		"king_downed",
		"castle_damaged",
		"run_ended",
	]:
		assert_true(names.has(event_name), "the log has %s" % event_name)
	assert_gt(_count_attacks(lines, "king", false), 0, "the king strikes")
	assert_gt(_count_attacks(lines, "building", false), 0, "a tower shoots")
	assert_gt(_count_attacks(lines, "enemy", true), 0, "a ranged enemy fires a projectile")
	assert_true(lines.size() > 0 and lines[lines.size() - 1].contains(" final "), "final state")
	var ended: String = ""
	for line: String in lines:
		if line.split(" ")[1] == "run_ended":
			ended = line
	assert_true(ended.ends_with(" victory"), "the run ended in victory: %s" % ended)


func test_a_different_seed_gives_a_different_digest() -> void:
	var one: Dictionary = ReplayScenarios.run(&"smoke", 1)
	var two: Dictionary = ReplayScenarios.run(&"smoke", 2)
	assert_ne(one.get("digest"), two.get("digest"), "spawn scatter is seeded")


func test_the_smoke_fixtures_reference_nothing_in_data() -> void:
	for path: String in FIXTURE_MAPS:
		var text: String = FileAccess.get_file_as_string(path)
		assert_ne(text, "", "%s exists" % path)
		assert_false(text.contains("res://data/"), "%s is self-contained" % path)


func test_the_golden_file_names_the_scenario_and_its_seed() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN))
	assert_true(parsed is Dictionary, "the golden is a JSON object")
	if parsed is Dictionary:
		var table: Dictionary = parsed
		assert_eq(table.get("scenario"), "smoke", "scenario")
		assert_eq(int(table.get("seed", -1)), SEED, "seed")
		assert_true(table.get("digests") is Dictionary, "digests table")
		if table.get("digests") is Dictionary:
			assert_true((table["digests"] as Dictionary).has("default"), "a default digest")


func test_an_unknown_scenario_has_no_digest_and_no_golden_is_empty() -> void:
	assert_false(ReplayScenarios.has(&"nope"), "not on the allowlist")
	assert_eq(ReplayScenarios.golden_digest("res://tests/golden/nope.json"), "", "no file, no digest")
