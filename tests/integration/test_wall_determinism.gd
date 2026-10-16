extends GutTest
## DEV-05 for the walls: the same wall map, seed and scripted bot replay to the same digest, and a
## second seed does not. The bot buys the ring and a tower on day one and starts the night, so the
## grunts attack a segment, break it and the log records every wall event.

const FIXTURE := "res://tests/fixtures/fixture_map_walls.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const MAX_TICKS: int = 4000

var _map: MapConfig
var _tuning: LoopTuning


func before_each() -> void:
	_map = load(FIXTURE)
	_tuning = load(TUNING)


func _bot() -> PlaytestBot:
	var bot: PlaytestBot = PlaytestBot.new()
	bot.build_order = [&"wall_ring", &"tower_1"]
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


func test_the_log_records_the_walls_being_hit_and_broken() -> void:
	var lines: PackedStringArray = _run(1)["lines"]
	assert_gt(_count(lines, "wall_damaged"), 0, "a segment was hit")
	assert_gt(_count(lines, "wall_segment_broken"), 0, "a segment broke")
	assert_gt(_count(lines, "attack_fired", " attack_fired enemy "), 0, "enemies attacked")
	assert_gt(_count(lines, "attack_fired", " wall "), 0, "one of the attacks named a wall")
	assert_eq(_count(lines, "building_built"), 2, "the ring and the tower were bought")
