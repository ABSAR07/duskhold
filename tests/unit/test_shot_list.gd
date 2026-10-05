extends GutTest
## DEV-04: the screenshot wrapper (bash) and the scenarios (GDScript) each keep a list of shot
## names. They must agree, or CI would capture a different set than the runner can script.

const SCRIPT_PATH := "res://tools/screenshot.sh"
const LIST_OPEN := "ALL_SHOTS=("
const EXPECTED_SHOT_COUNT: int = 15


## The names inside the `ALL_SHOTS=( ... )` array of the wrapper, in order. The array may span
## several lines.
func _bash_shots() -> Array[StringName]:
	var found: Array[StringName] = []
	var file: FileAccess = FileAccess.open(SCRIPT_PATH, FileAccess.READ)
	if file == null:
		return found
	var text: String = file.get_as_text()
	var start: int = text.find(LIST_OPEN)
	if start < 0:
		return found
	start += LIST_OPEN.length()
	var end: int = text.find(")", start)
	if end < 0:
		return found
	for token: String in text.substr(start, end - start).split(" ", false):
		var name: String = token.strip_edges()
		if not name.is_empty():
			found.append(StringName(name))
	return found


func test_the_wrapper_lists_the_scenarios_in_the_same_order() -> void:
	var bash_shots: Array[StringName] = _bash_shots()
	assert_eq(bash_shots.size(), EXPECTED_SHOT_COUNT, "the wrapper lists fifteen shots")
	assert_eq(bash_shots, ShotScenarios.ALL_SHOTS, "bash and GDScript lists are identical")


func test_there_are_fifteen_distinct_shots() -> void:
	var seen: Dictionary = {}
	for shot: StringName in ShotScenarios.ALL_SHOTS:
		seen[shot] = true
	assert_eq(ShotScenarios.ALL_SHOTS.size(), EXPECTED_SHOT_COUNT, "fifteen shots")
	assert_eq(seen.size(), EXPECTED_SHOT_COUNT, "no name is listed twice")


func test_every_shot_has_a_map_copy_with_the_shot_gold() -> void:
	for shot: StringName in ShotScenarios.ALL_SHOTS:
		var map: MapConfig = ShotScenarios.map_for(shot)
		assert_not_null(map, "shot %s has a map" % shot)
		if map != null:
			assert_eq(map.starting_gold, ShotScenarios.SHOT_STARTING_GOLD, "gold for %s" % shot)


func test_the_copies_are_deep_and_never_touch_the_shipped_map() -> void:
	var shipped: MapConfig = load(ShotScenarios.MAP_DATA_PATH)
	var shipped_nights: int = shipped.nights.size()
	var shipped_castle: int = shipped.castle_max_health
	var shipped_gold: int = shipped.starting_gold
	var victory: MapConfig = ShotScenarios.map_for(ShotScenarios.RESULTS_VICTORY)
	var defeat: MapConfig = ShotScenarios.map_for(ShotScenarios.RESULTS_DEFEAT)
	assert_ne(victory.nights[0], shipped.nights[0], "night definitions are copied, not shared")
	assert_ne(victory, defeat, "each call returns its own copy")
	assert_eq(shipped.nights.size(), shipped_nights, "the shipped nights are untouched")
	assert_eq(shipped.castle_max_health, shipped_castle, "the shipped castle is untouched")
	assert_eq(shipped.starting_gold, shipped_gold, "the shipped gold is untouched")


func test_each_shot_gets_the_map_its_scene_needs() -> void:
	var shipped: MapConfig = load(ShotScenarios.MAP_DATA_PATH)
	assert_eq(
		ShotScenarios.map_for(ShotScenarios.RESULTS_VICTORY).nights.size(), 1, "victory: one night"
	)
	assert_eq(
		ShotScenarios.map_for(ShotScenarios.RESULTS_DEFEAT).castle_max_health,
		ShotScenarios.DEFEAT_CASTLE_HEALTH,
		"defeat: a castle that falls at once"
	)
	assert_eq(
		ShotScenarios.map_for(ShotScenarios.RESULTS_DEFEAT).nights.size(),
		shipped.nights.size(),
		"defeat keeps every night"
	)
	for shot: StringName in [ShotScenarios.NIGHT_BANNER, ShotScenarios.DAWN_PAYOUT]:
		assert_eq(ShotScenarios.map_for(shot).nights.size(), 0, "%s: the timed night" % shot)
	for shot: StringName in [
		ShotScenarios.NIGHT_COMBAT,
		ShotScenarios.BUILDING_DESTROYED,
		ShotScenarios.DAWN_REBUILT,
		ShotScenarios.KING_DOWN_COUNTDOWN,
		ShotScenarios.OVERLAY_PATHS,
		ShotScenarios.SPAWN_TELEGRAPH
	]:
		var map: MapConfig = ShotScenarios.map_for(shot)
		assert_eq(map.nights.size(), shipped.nights.size(), "%s keeps the shipped nights" % shot)
		assert_eq(map.castle_max_health, shipped.castle_max_health, "%s: the shipped castle" % shot)
