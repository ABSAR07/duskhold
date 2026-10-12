extends GutTest
## DEV-04: the screenshot wrapper (bash) and the scenarios (GDScript) each keep a list of shot
## names. They must agree, or CI would capture a different set than the runner can script.

const SCRIPT_PATH := "res://tools/screenshot.sh"
const LIST_OPEN := "ALL_SHOTS=("
const EXPECTED_SHOT_COUNT: int = 33


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
	assert_eq(bash_shots.size(), EXPECTED_SHOT_COUNT, "the wrapper lists thirty-three shots")
	assert_eq(bash_shots, ShotScenarios.ALL_SHOTS, "bash and GDScript lists are identical")


func test_there_are_thirty_three_distinct_shots() -> void:
	var seen: Dictionary = {}
	for shot: StringName in ShotScenarios.ALL_SHOTS:
		seen[shot] = true
	assert_eq(ShotScenarios.ALL_SHOTS.size(), EXPECTED_SHOT_COUNT, "thirty-three shots")
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


func test_the_eighteen_phase_3_shots_are_listed_after_the_first_fifteen() -> void:
	var tail: Array[StringName] = []
	for index: int in range(
		ShotScenarios.ALL_SHOTS.size() - ShotScenarios.ARMY_SHOTS.size(), EXPECTED_SHOT_COUNT
	):
		tail.append(ShotScenarios.ALL_SHOTS[index])
	assert_eq(ShotScenarios.ARMY_SHOTS.size(), 18, "eighteen Phase 3 shots")
	assert_eq(tail, ShotScenarios.ARMY_SHOTS, "they close the list in order")
	for shot: StringName in ShotScenarios.ARMY_SHOTS:
		assert_true(ShotArmyScenarios.handles(shot), "%s has a Phase 3 scene" % shot)
		var prefix_ok: bool = String(shot).begins_with("hud_") or String(shot).begins_with("cmd_")
		assert_true(prefix_ok, "%s is checked against the clear centre" % shot)


func test_the_window_shape_comes_from_the_shot_name_suffix() -> void:
	var text: String = FileAccess.get_file_as_string(SCRIPT_PATH)
	assert_true(text.contains('*_1080p) echo "1920x1080"'), "1080p shots get a 1920x1080 window")
	assert_true(text.contains('*_16x10) echo "1600x1000"'), "16:10 shots get a 1600x1000 window")


func test_the_long_counter_map_has_twelve_nights_of_one_grunt() -> void:
	var map: MapConfig = ShotScenarios.map_for(ShotScenarios.HUD_DAY_COUNTER_LONG)
	assert_eq(map.nights.size(), 12, "twelve nights")
	for night: NightDef in map.nights:
		assert_eq(night.groups.size(), 1, "one group")
		assert_eq(night.groups[0].count, 1, "one grunt")
	var shipped: MapConfig = load(ShotScenarios.MAP_DATA_PATH)
	assert_eq(shipped.nights.size(), 8, "the shipped map keeps its eight nights")


func test_the_king_copies_of_the_hurt_shots_hold_their_health() -> void:
	var shipped: KingDef = load(ShotScenarios.KING_DATA_PATH)
	for shot: StringName in ShotArmyScenarios.FROZEN_KING_SHOTS:
		var def: KingDef = ShotScenarios.king_def_for(shot)
		assert_eq(def.regen_fraction_per_second, 0.0, "%s: no regeneration" % shot)
	assert_eq(ShotScenarios.king_def_for(ShotScenarios.HUD_KING_120).max_health, 120, "120 health")
	assert_eq(shipped.max_health, 50, "the shipped king is untouched")
	assert_gt(shipped.regen_fraction_per_second, 0.0, "and still regenerates")
