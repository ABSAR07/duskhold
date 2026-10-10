extends GutTest
## DEV-05 for the army: the same squad map, seed and scripted bot replay to the same digest, and a
## second seed does not. The bot builds the Barracks on day one and starts the night, so footmen
## guard, commit to grunts, take hits and the log records every unit event.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const MAX_TICKS: int = 4000

var _map: MapConfig
var _tuning: LoopTuning


func before_each() -> void:
	_map = load(FIXTURE)
	_tuning = load(TUNING)


func _bot() -> PlaytestBot:
	var bot: PlaytestBot = PlaytestBot.new()
	bot.build_order = [&"barracks_1"]
	return bot


func _run(run_seed: int) -> Dictionary:
	return ReplayDriver.run(_map, _tuning, run_seed, _bot(), MAX_TICKS, 1)


func _count(lines: PackedStringArray, event_name: String, needle: String = "") -> int:
	var total: int = 0
	for line: String in lines:
		var parts: PackedStringArray = line.split(" ")
		if parts[1] == event_name and (needle.is_empty() or line.contains(needle)):
			total += 1
	return total


func test_two_runs_of_the_same_seed_give_identical_digests() -> void:
	var first: Dictionary = _run(1)
	var second: Dictionary = _run(1)
	assert_eq(first["outcome"], &"stopped", "the run reaches the first dawn")
	assert_eq(first["digest"], second["digest"], "same seed, same digest")
	assert_eq(first["line_count"], second["line_count"], "same number of lines")
	assert_eq(first["ticks"], second["ticks"], "same final tick")


func test_a_different_seed_gives_a_different_digest() -> void:
	assert_ne(_run(1)["digest"], _run(2)["digest"], "the seeds scatter the spawns differently")


func test_the_log_records_the_squad_being_raised_and_fighting() -> void:
	var lines: PackedStringArray = _run(1)["lines"]
	assert_eq(_count(lines, "unit_spawned"), 4, "four footmen are raised")
	assert_gt(_count(lines, "attack_fired", " attack_fired unit "), 0, "a unit attack is logged")
	assert_gt(_count(lines, "enemy_died", " unit"), 0, "the squad killed an enemy")
	assert_gt(_count(lines, "unit_damaged"), 0, "enemies hurt the squad back")
