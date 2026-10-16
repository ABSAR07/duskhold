extends GutTest
## Plan 04-10, D-15: the balance report counts the wall segments that break in each night. The
## per-night `walls_broken` column must equal the wall_segment_broken lines of that night's log,
## and it is a read-only tally, so it never moves a digest (the walls golden and the balanced run
## stay equal to a second run). Split from test_balance_report.gd, which is at the method cap.

const MAP_PATH := "res://data/maps/prototype_map.tres"
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
const KING_PATH := "res://data/king/king.tres"
## Phase number of RunManager.RunPhase that ends a night.
const PHASE_NIGHT: int = 2

var _balanced: Dictionary = {}


func before_all() -> void:
	_balanced = _balanced_run()


func _balanced_run() -> Dictionary:
	return ReplayDriver.run(
		load(MAP_PATH),
		load(TUNING_PATH),
		1,
		PlaytestStrategies.make(&"balanced"),
		40000,
		0,
		load(KING_PATH)
	)


## The lines of each night: from its night_started line to the phase_changed line that leaves NIGHT.
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


func _broken_per_night(result: Dictionary) -> int:
	var nights: Array = _night_lines(result["lines"])
	var per_night: Array = result["per_night"]
	assert_eq(nights.size(), per_night.size(), "the log has the same nights")
	var total: int = 0
	for index: int in range(per_night.size()):
		var broken: int = 0
		for line: String in nights[index]:
			broken += 1 if line.split(" ")[1] == "wall_segment_broken" else 0
		assert_eq(per_night[index]["walls_broken"], broken, "night %d walls broken" % (index + 1))
		total += broken
	return total


func test_the_walls_broken_column_adds_up_in_the_balanced_run() -> void:
	_broken_per_night(_balanced)
	for night: Dictionary in _balanced["per_night"]:
		assert_true(night.has("walls_broken"), "every night entry carries the column")


func test_the_walls_broken_column_adds_up_in_the_walls_scenario_where_segments_fall() -> void:
	var walls: Dictionary = ReplayScenarios.run(&"walls", 1)
	assert_gt(_broken_per_night(walls), 0, "the crowd breaks a segment, so the sum is not zeros")


func test_the_tally_counts_each_wall_segment_broken_event_in_the_open_night() -> void:
	var ctx: RunContext = RunContext.new(load(MAP_PATH), load(TUNING_PATH), 1)
	var tally: ReplayDriver.Tally = ReplayDriver.Tally.new(ctx)
	ctx.events.wall_segment_broken.emit(&"wall_west", 3)
	assert_eq(tally.per_night.size(), 0, "no night is open, so nothing is counted")
	ctx.events.night_started.emit(1)
	ctx.events.wall_segment_broken.emit(&"wall_west", 3)
	ctx.events.wall_segment_broken.emit(&"wall_east", 5)
	assert_eq(tally.per_night[0]["walls_broken"], 2, "two segments fell in night 1")


func test_the_bookkeeping_does_not_change_the_balanced_digest() -> void:
	assert_eq(_balanced_run()["digest"], _balanced["digest"], "the same run, the same digest")
