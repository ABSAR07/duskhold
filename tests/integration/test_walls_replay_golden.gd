extends GutTest
## BLDG-10, ENMY-04, D-14: the scripted walls scenario replays to the same digest twice in one
## process and to the checked-in golden. It runs on a frozen, self-contained fixture (a long wall
## run on the west road with one gap, a tower, and two nights: a crowd that breaks a segment, then
## stragglers that walk round through the gap), so a later retune of data/ never moves it. The log
## must show every wall rule family the digest guards: building, damage, breaking, the dawn
## restore, and enemies and the tower attacking walls.

const GOLDEN := "res://tests/golden/walls.json"
const FIXTURE := "res://tests/fixtures/fixture_map_replay_walls.tres"
const SEED: int = 1
## The run is the line x = -20 from z -30 to 30; its one gap lies 52 to 56 m along it (z 22 to 26).
const WALL_LINE_X: float = -20.0
const GAP_SOUTH: float = 22.0
const GAP_NORTH: float = 26.0
const STRAGGLERS: int = 8
const WALL_SPOT := "wall_west"

var _first: Dictionary = {}


func before_all() -> void:
	_first = ReplayScenarios.run(&"walls", SEED)


func _lines() -> PackedStringArray:
	return _first.get("lines", PackedStringArray())


func _count(event_name: String) -> int:
	var total: int = 0
	for line: String in _lines():
		if line.split(" ")[1] == event_name:
			total += 1
	return total


## Steps the scenario's own bot through the fixture again and returns, per enemy, the night and the
## z at which it first crossed the wall line from west to east: {id: [night, z]}.
func _crossings() -> Dictionary:
	var bot: PlaytestBot = PlaytestBot.new()
	bot.build_order = ReplayScenarios.WALLS_BUILD_ORDER.duplicate()
	bot.king_mode = PlaytestBot.KING_HOLD_POINT
	bot.hold_point = ReplayScenarios.WALLS_HOLD_POINT
	var ctx: RunContext = RunContext.new(
		load(ReplayScenarios.WALLS_MAP),
		load(ReplayScenarios.SMOKE_TUNING),
		SEED,
		load(ReplayScenarios.SMOKE_KING)
	)
	var enemies: EnemySystem = ctx.night.get_enemies()
	var crossed: Dictionary = {}
	for _tick: int in range(ReplayScenarios.WALLS_MAX_TICKS):
		bot.think(ctx)
		ctx.step()
		for id: int in enemies.ids():
			var before: Vector2 = enemies.previous_position_of(id)
			var after: Vector2 = enemies.position_of(id)
			if before.x < WALL_LINE_X and after.x >= WALL_LINE_X and not crossed.has(id):
				var along: float = (WALL_LINE_X - before.x) / (after.x - before.x)
				crossed[id] = [
					ctx.run_manager.get_night_number(), before.y + (after.y - before.y) * along
				]
		if ctx.run_manager.is_run_over():
			break
	return crossed


func test_two_runs_of_the_walls_scenario_give_the_same_digest_as_the_golden() -> void:
	var second: Dictionary = ReplayScenarios.run(&"walls", SEED)
	var golden: String = ReplayScenarios.golden_digest(GOLDEN)
	assert_eq(String(_first.get("digest", "")).length(), 64, "a sha256 digest")
	assert_eq(_first.get("digest"), second.get("digest"), "same process, same digest")
	assert_eq(_first.get("line_count"), second.get("line_count"), "same number of lines")
	assert_ne(golden, "", "the golden file holds a digest for this platform")
	assert_eq(_first.get("digest"), golden, "and it is the checked-in golden")


func test_the_walls_scenario_is_on_the_allowlist_with_a_bound() -> void:
	assert_true(ReplayScenarios.has(&"walls"), "on the allowlist")
	assert_eq(ReplayScenarios.max_ticks(&"walls"), 8000, "its own tick bound")
	assert_eq(ReplayScenarios.default_seed(&"walls"), SEED, "the default seed")
	assert_lt(int(_first.get("ticks", -1)), ReplayScenarios.max_ticks(&"walls"), "inside its bound")
	assert_eq(_first.get("outcome"), &"won", "the scripted run clears both nights")


func test_the_log_shows_the_wall_bought_hit_broken_and_restored() -> void:
	var built: bool = false
	for line: String in _lines():
		var parts: PackedStringArray = line.split(" ")
		if parts[1] == "building_built" and parts[2] == WALL_SPOT and parts[3] == "wall":
			built = true
	assert_true(built, "the wall plot is built")
	assert_gt(_count("wall_damaged"), 0, "the wall is hit")
	assert_gt(_count("wall_segment_broken"), 0, "a segment breaks")
	assert_eq(_count("walls_restored"), 1, "dawn restores the wall once")
	assert_eq(_count("night_started"), 2, "both nights start")
	assert_gt(_count("enemy_died"), 0, "enemies die")


func test_the_log_shows_enemies_attacking_the_wall() -> void:
	var at_wall: int = 0
	for line: String in _lines():
		var parts: PackedStringArray = line.split(" ")
		if parts[1] == "attack_fired" and parts[4] == "wall":
			at_wall += 1
	assert_gt(at_wall, 0, "an attack_fired has the wall as its target kind")


func test_the_night_one_crowd_goes_through_the_hole_and_the_stragglers_go_round() -> void:
	var crossed: Dictionary = _crossings()
	var through_hole: int = 0
	var through_gap: int = 0
	for id: int in crossed:
		var entry: Array = crossed[id]
		var z: float = entry[1]
		var in_gap: bool = z > GAP_SOUTH and z < GAP_NORTH
		if int(entry[0]) == 1 and absf(z) < GAP_SOUTH:
			through_hole += 1
		if int(entry[0]) == 2 and in_gap:
			through_gap += 1
	assert_gt(through_hole, 0, "night 1: the crowd crosses through the hole it broke")
	assert_eq(through_gap, STRAGGLERS, "night 2: every straggler walks round through the gap")


func test_a_different_seed_gives_a_different_digest() -> void:
	var other: Dictionary = ReplayScenarios.run(&"walls", 2)
	assert_ne(_first.get("digest", ""), "", "the first run produced a digest")
	assert_ne(_first.get("digest"), other.get("digest"), "spawn scatter is seeded")


func test_the_walls_fixture_references_nothing_in_data_and_validates() -> void:
	var text: String = FileAccess.get_file_as_string(FIXTURE)
	assert_ne(text, "", "the fixture exists")
	assert_false(text.contains("res://data/"), "the fixture is self-contained")
	var map: MapConfig = load(FIXTURE)
	assert_eq(map.validate(), PackedStringArray(), "and it passes the map validation")


func test_the_golden_file_names_the_scenario_and_its_seed() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN))
	assert_true(parsed is Dictionary, "the golden is a JSON object")
	if parsed is Dictionary:
		var table: Dictionary = parsed
		assert_eq(table.get("scenario"), "walls", "scenario")
		assert_eq(int(table.get("seed", -1)), SEED, "seed")
		assert_true(table.get("digests") is Dictionary, "digests table")
		if table.get("digests") is Dictionary:
			assert_true((table["digests"] as Dictionary).has("default"), "a default digest")
