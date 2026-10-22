extends GutTest
## BLDG-05, BLDG-08, ECON-03 to ECON-06, D-08: the scripted economy scenario replays to the same
## digest twice in one process and to the checked-in golden. It runs on a frozen, self-contained
## fixture (inline copies of the castle with its four tier II cards, Gold Mine, Mill, Field, Fishing
## Harbor, Shrine and tower as they were when the scenario was pinned), so a later retune of data/
## never moves it. The log must show every rule family the digest guards: the card pick, all five
## new buildings built, a dawn that pays Mine, Mill, Field and Harbor, the boats, the Shrine's wake
## and its shots, and a building lost in the night and rebuilt at dawn.

const GOLDEN := "res://tests/golden/economy.json"
const FIXTURE := "res://tests/fixtures/fixture_map_replay_economy.tres"
const SEED: int = 1
const NEW_BUILDINGS: Array[String] = ["gold_mine", "mill", "field", "fishing_harbor", "shrine"]
const PAID_PLOTS: Array[String] = ["gold_mine_1", "mill_1", "field_1", "harbor_1"]
const SHRINE_SPOT := &"shrine_1"

var _first: Dictionary = {}


func before_all() -> void:
	_first = ReplayScenarios.run(&"economy", SEED)


func _lines() -> PackedStringArray:
	return _first.get("lines", PackedStringArray())


func _count(event_name: String) -> int:
	var total: int = 0
	for line: String in _lines():
		if line.split(" ")[1] == event_name:
			total += 1
	return total


## The spot's index in the fixture's MapConfig order, the number attack_fired lines carry.
func _spot_index(spot_id: StringName) -> int:
	var map: MapConfig = load(FIXTURE)
	for index: int in range(map.spots.size()):
		if map.spots[index].id == spot_id:
			return index
	return -1


func test_two_runs_of_the_economy_scenario_give_the_same_digest_as_the_golden() -> void:
	var second: Dictionary = ReplayScenarios.run(&"economy", SEED)
	var golden: String = ReplayScenarios.golden_digest(GOLDEN)
	assert_eq(String(_first.get("digest", "")).length(), 64, "a sha256 digest")
	assert_eq(_first.get("digest"), second.get("digest"), "same process, same digest")
	assert_eq(_first.get("line_count"), second.get("line_count"), "same number of lines")
	assert_ne(golden, "", "the golden file holds a digest for this platform")
	assert_eq(_first.get("digest"), golden, "and it is the checked-in golden")


func test_the_economy_scenario_is_on_the_allowlist_with_a_bound() -> void:
	assert_true(ReplayScenarios.has(&"economy"), "on the allowlist")
	assert_eq(ReplayScenarios.max_ticks(&"economy"), 9000, "its own tick bound")
	assert_eq(ReplayScenarios.default_seed(&"economy"), SEED, "the default seed")
	assert_lt(
		int(_first.get("ticks", -1)), ReplayScenarios.max_ticks(&"economy"), "inside its bound"
	)
	assert_eq(_first.get("outcome"), &"won", "the scripted run clears all three nights")


func test_a_different_seed_gives_a_different_digest() -> void:
	var other: Dictionary = ReplayScenarios.run(&"economy", 2)
	assert_ne(_first.get("digest", ""), "", "the first run produced a digest")
	assert_ne(_first.get("digest"), other.get("digest"), "spawn scatter is seeded")


func test_the_log_shows_the_card_pick_and_all_five_new_buildings_built() -> void:
	assert_eq(_count("choice_picked"), 1, "the castle's tier II card is picked once")
	var built: Dictionary = {}
	for line: String in _lines():
		var parts: PackedStringArray = line.split(" ")
		if parts[1] == "building_built":
			built[parts[3]] = true
		if parts[1] == "choice_picked":
			assert_eq(parts[4], "masons", "the scripted pick")
	for building: String in NEW_BUILDINGS:
		assert_true(built.has(building), "%s is built" % building)


func test_a_dawn_pays_the_mine_the_mill_the_field_and_the_harbor() -> void:
	var best: int = 0
	for line: String in _lines():
		var parts: PackedStringArray = line.split(" ")
		if parts[1] != "dawn_payout":
			continue
		var listed: int = 0
		for plot: String in PAID_PLOTS:
			for part: String in parts:
				if part.begins_with(plot + "="):
					listed += 1
		best = maxi(best, listed)
	assert_eq(best, PAID_PLOTS.size(), "one dawn_payout line lists all four plots")


func test_the_log_shows_boats_the_wake_and_the_shrine_firing() -> void:
	assert_gt(_count("harbor_boats_changed"), 0, "the Harbor gains boats")
	assert_eq(_count("shrine_woke"), 1, "the Shrine wakes once")
	var shots: int = 0
	var shrine_index: String = str(_spot_index(SHRINE_SPOT))
	for line: String in _lines():
		var parts: PackedStringArray = line.split(" ")
		if parts[1] == "attack_fired" and parts[2] == "building" and parts[3] == shrine_index:
			shots += 1
	assert_gt(shots, 0, "an attack_fired has the Shrine's spot index as its source")


func test_the_log_shows_a_building_lost_in_the_night_and_rebuilt_at_dawn() -> void:
	assert_gt(_count("building_destroyed"), 0, "a building falls")
	assert_gt(_count("buildings_rebuilt"), 0, "dawn rebuilds")
	assert_eq(_count("night_started"), 3, "all three nights start")
	assert_gt(_count("enemy_died"), 0, "enemies die")


func test_the_economy_fixture_references_nothing_in_data_and_validates() -> void:
	var text: String = FileAccess.get_file_as_string(FIXTURE)
	assert_ne(text, "", "the fixture exists")
	assert_false(text.contains("res://data/"), "the fixture is self-contained")
	for line: String in text.split("\n"):
		if line.begins_with("[ext_resource"):
			assert_true(line.contains('path="res://simulation/'), "only scripts: %s" % line)
	var map: MapConfig = load(FIXTURE)
	assert_eq(map.validate(), PackedStringArray(), "and it passes the map validation")


func test_the_golden_file_names_the_scenario_and_its_seed() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN))
	assert_true(parsed is Dictionary, "the golden is a JSON object")
	if parsed is Dictionary:
		var table: Dictionary = parsed
		assert_eq(table.get("scenario"), "economy", "scenario")
		assert_eq(int(table.get("seed", -1)), SEED, "seed")
		assert_true(table.get("digests") is Dictionary, "digests table")
		if table.get("digests") is Dictionary:
			assert_true((table["digests"] as Dictionary).has("default"), "a default digest")
