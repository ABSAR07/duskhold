extends GutTest
## DEV-05 for the army: the scripted army scenario replays to the same digest twice in one process
## and to the checked-in golden. It runs on frozen fixture data (a self-contained map and king with
## the slam and regeneration, copies of the numbers shipped at plan 03-11), so a later retune of
## data/ never moves it. The log must show every Phase 3 rule family the digest guards: units
## spawning and dying, the six squad orders, the dawn restore, the slam and the regeneration.

const GOLDEN := "res://tests/golden/army.json"
const FIXTURES: Array[String] = [
	"res://tests/fixtures/fixture_map_replay_army.tres",
	"res://tests/fixtures/fixture_king_replay_army.tres",
]
const BOT_SOURCE := "res://tools/replay/playtest_bot.gd"
const SEED: int = 1
## Phase number of RunManager.RunPhase that ends a night.
const PHASE_NIGHT: int = 2

var _first: Dictionary = {}


func before_all() -> void:
	_first = ReplayScenarios.run(&"army", SEED)


func _lines() -> PackedStringArray:
	return _first.get("lines", PackedStringArray())


func _event_names(lines: PackedStringArray) -> Array[String]:
	var names: Array[String] = []
	for line: String in lines:
		names.append(line.split(" ")[1])
	return names


## The verbs of every squad_ordered line (token 3: tick, name, squad, verb, queued, points).
func _ordered_verbs(lines: PackedStringArray) -> Array[String]:
	var verbs: Array[String] = []
	for line: String in lines:
		var parts: PackedStringArray = line.split(" ")
		if parts[1] == "squad_ordered":
			verbs.append(parts[3])
	return verbs


func test_two_runs_of_the_army_scenario_give_the_same_digest_as_the_golden() -> void:
	var second: Dictionary = ReplayScenarios.run(&"army", SEED)
	var golden: String = ReplayScenarios.golden_digest(GOLDEN)
	assert_eq(String(_first.get("digest", "")).length(), 64, "a sha256 digest")
	assert_eq(_first.get("digest"), second.get("digest"), "same process, same digest")
	assert_eq(_first.get("line_count"), second.get("line_count"), "same number of lines")
	assert_ne(golden, "", "the golden file holds a digest for this platform")
	assert_eq(_first.get("digest"), golden, "and it is the checked-in golden")


func test_the_army_scenario_is_on_the_allowlist_with_a_bound() -> void:
	assert_true(ReplayScenarios.has(&"army"), "on the allowlist")
	assert_eq(ReplayScenarios.max_ticks(&"army"), 8000, "its own tick bound")
	assert_eq(ReplayScenarios.default_seed(&"army"), SEED, "the default seed")
	assert_lt(int(_first.get("ticks", -1)), ReplayScenarios.max_ticks(&"army"), "inside its bound")


func test_the_log_shows_units_spawning_dying_and_the_dawn_restore() -> void:
	var names: Array[String] = _event_names(_lines())
	for event_name: String in ["unit_spawned", "unit_died", "squad_restored"]:
		assert_true(names.has(event_name), "the log has %s" % event_name)


func test_the_log_shows_all_five_orders_the_script_gives() -> void:
	var verbs: Array[String] = _ordered_verbs(_lines())
	for verb: String in ["follow", "hold", "move", "attack_move", "patrol"]:
		assert_true(verbs.has(verb), "the log has a squad_ordered %s" % verb)


func test_the_log_shows_the_slam_and_the_regeneration() -> void:
	var names: Array[String] = _event_names(_lines())
	assert_true(names.has("king_ability_used"), "the bot slams")
	assert_true(names.has("king_healed"), "the king heals")


func test_a_different_seed_gives_a_different_digest() -> void:
	var other: Dictionary = ReplayScenarios.run(&"army", 2)
	assert_ne(_first.get("digest", ""), "", "the first run produced a digest")
	assert_ne(_first.get("digest"), other.get("digest"), "spawn scatter is seeded")


func test_the_army_fixtures_reference_nothing_in_data() -> void:
	for path: String in FIXTURES:
		var text: String = FileAccess.get_file_as_string(path)
		assert_ne(text, "", "%s exists" % path)
		assert_false(text.contains("res://data/"), "%s is self-contained" % path)


func test_the_golden_file_names_the_scenario_and_its_seed() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN))
	assert_true(parsed is Dictionary, "the golden is a JSON object")
	if parsed is Dictionary:
		var table: Dictionary = parsed
		assert_eq(table.get("scenario"), "army", "scenario")
		assert_eq(int(table.get("seed", -1)), SEED, "seed")
		assert_true(table.get("digests") is Dictionary, "digests table")
		if table.get("digests") is Dictionary:
			assert_true((table["digests"] as Dictionary).has("default"), "a default digest")


## Splits the log into the lines of each night: from night_started to the phase_changed line that
## leaves NIGHT (inclusive).
func _night_lines(lines: PackedStringArray) -> Array:
	var nights: Array = []
	var current: Array = []
	var inside: bool = false
	for line: String in lines:
		var parts: PackedStringArray = line.split(" ")
		if parts[1] == "night_started":
			inside = true
			current = []
		if inside:
			current.append(line)
		if inside and parts[1] == "phase_changed" and int(parts[2]) == PHASE_NIGHT:
			nights.append(current)
			inside = false
	if inside:
		nights.append(current)
	return nights


func test_kills_and_units_lost_per_night_match_the_log() -> void:
	var nights: Array = _night_lines(_lines())
	var per_night: Array = _first.get("per_night", [])
	assert_gt(per_night.size(), 0, "nights were played")
	assert_eq(nights.size(), per_night.size(), "the log has the same nights")
	var total_units_lost: int = 0
	for index: int in range(per_night.size()):
		var deaths: int = 0
		var unit_deaths: int = 0
		for line: String in nights[index]:
			var parts: PackedStringArray = line.split(" ")
			deaths += 1 if parts[1] == "enemy_died" else 0
			unit_deaths += 1 if parts[1] == "unit_died" else 0
		var night: Dictionary = per_night[index]
		var kills: int = (
			int(night.get("kills_king", 0))
			+ int(night.get("kills_towers", 0))
			+ int(night.get("kills_castle", 0))
			+ int(night.get("kills_units", -1000))
		)
		assert_eq(kills, deaths, "night %d: every enemy death has one killer kind" % (index + 1))
		assert_eq(
			int(night.get("units_lost", -1)), unit_deaths, "night %d units lost" % (index + 1)
		)
		total_units_lost += unit_deaths
	assert_gt(total_units_lost, 0, "the scripted army loses someone, so the column is exercised")


func test_the_scripted_army_kills_some_enemies_with_its_units() -> void:
	var units_killed: int = 0
	for night: Dictionary in _first.get("per_night", []):
		units_killed += int(night.get("kills_units", 0))
	assert_gt(units_killed, 0, "squads kill enemies")


func test_the_bot_uses_no_random_function() -> void:
	var text: String = FileAccess.get_file_as_string(BOT_SOURCE)
	assert_ne(text, "", "the bot source is readable")
	for banned: String in ["randi(", "randf(", "randomize(", "RandomNumberGenerator", "shuffle("]:
		assert_false(text.contains(banned), "the bot never calls %s" % banned)
