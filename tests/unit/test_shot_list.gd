extends GutTest
## DEV-04: the screenshot wrapper (bash) and the scenarios (GDScript) each keep a list of shot
## names. They must agree, or CI would capture a different set than the runner can script.

const SCRIPT_PATH := "res://tools/screenshot.sh"
const LIST_OPEN := "ALL_SHOTS=("
const EXPECTED_SHOT_COUNT: int = 44
const PHASE_1_SHOT_COUNT: int = 15


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
	assert_eq(bash_shots.size(), EXPECTED_SHOT_COUNT, "the wrapper lists forty-four shots")
	assert_eq(bash_shots, ShotScenarios.ALL_SHOTS, "bash and GDScript lists are identical")


func test_there_are_forty_four_distinct_shots() -> void:
	var seen: Dictionary = {}
	for shot: StringName in ShotScenarios.ALL_SHOTS:
		seen[shot] = true
	assert_eq(ShotScenarios.ALL_SHOTS.size(), EXPECTED_SHOT_COUNT, "forty-four shots")
	assert_eq(seen.size(), EXPECTED_SHOT_COUNT, "no name is listed twice")


func test_every_shot_has_a_map_copy_with_the_shot_gold() -> void:
	for shot: StringName in ShotScenarios.ALL_SHOTS:
		var map: MapConfig = ShotScenarios.map_for(shot)
		assert_not_null(map, "shot %s has a map" % shot)
		if map != null:
			var wanted: int = ShotScenarios.SHOT_STARTING_GOLD
			if ShotEconomyScenarios.handles(shot):
				wanted = ShotEconomyScenarios.SHOT_GOLD
			assert_eq(map.starting_gold, wanted, "gold for %s" % shot)


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


func test_the_shots_come_in_four_blocks_phase_1_then_3_then_4_then_5() -> void:
	var army_end: int = PHASE_1_SHOT_COUNT + ShotScenarios.ARMY_SHOTS.size()
	var crowd_end: int = army_end + ShotCrowdScenarios.CROWD_SHOTS.size()
	var phase_3: Array[StringName] = []
	for index: int in range(PHASE_1_SHOT_COUNT, army_end):
		phase_3.append(ShotScenarios.ALL_SHOTS[index])
	var phase_4: Array[StringName] = []
	for index: int in range(army_end, crowd_end):
		phase_4.append(ShotScenarios.ALL_SHOTS[index])
	var phase_5: Array[StringName] = []
	for index: int in range(crowd_end, EXPECTED_SHOT_COUNT):
		phase_5.append(ShotScenarios.ALL_SHOTS[index])
	assert_eq(ShotScenarios.ARMY_SHOTS.size(), 18, "eighteen Phase 3 shots")
	assert_eq(phase_3, ShotScenarios.ARMY_SHOTS, "they follow the first fifteen in order")
	assert_eq(ShotCrowdScenarios.CROWD_SHOTS.size(), 4, "four Phase 4 shots")
	assert_eq(phase_4, ShotCrowdScenarios.CROWD_SHOTS, "they follow in order")
	assert_eq(ShotEconomyScenarios.ECONOMY_SHOTS.size(), 7, "seven Phase 5 shots")
	assert_eq(phase_5, ShotEconomyScenarios.ECONOMY_SHOTS, "they close the list in order")
	for shot: StringName in ShotScenarios.ARMY_SHOTS:
		assert_true(ShotArmyScenarios.handles(shot), "%s has a Phase 3 scene" % shot)
		var prefix_ok: bool = String(shot).begins_with("hud_") or String(shot).begins_with("cmd_")
		assert_true(prefix_ok, "%s is checked against the clear centre" % shot)


func test_the_two_wall_shots_are_listed_and_handled_by_the_crowd_scenes() -> void:
	var wanted: Array[StringName] = [&"walls_day", &"walls_night_breach"]
	var listed: Array[StringName] = ShotCrowdScenarios.CROWD_SHOTS.slice(0, 2)
	assert_eq(listed, wanted, "walls_day then walls_night_breach")
	for shot: StringName in wanted:
		assert_true(ShotScenarios.ALL_SHOTS.has(shot), "%s is in ALL_SHOTS" % shot)
		assert_true(ShotCrowdScenarios.handles(shot), "%s has a Phase 4 scene" % shot)
		assert_false(ShotArmyScenarios.handles(shot), "and is not a Phase 3 shot")
	assert_false(ShotCrowdScenarios.handles(ShotScenarios.DAY_OVERVIEW), "day_overview is not one")


func test_the_wall_shots_get_deep_copies_that_never_touch_the_shipped_map() -> void:
	var shipped: MapConfig = load(ShotScenarios.MAP_DATA_PATH)
	var shipped_run: WallRunDef = shipped.spots[10].wall_run
	for shot: StringName in [ShotScenarios.WALLS_DAY, ShotScenarios.WALLS_NIGHT_BREACH]:
		var map: MapConfig = ShotScenarios.map_for(shot)
		assert_not_null(map, "%s has a map" % shot)
		assert_eq(map.starting_gold, ShotScenarios.SHOT_STARTING_GOLD, "gold for %s" % shot)
		assert_ne(map, shipped, "a copy, not the shipped resource")
		assert_ne(map.spots[10].wall_run, shipped_run, "the wall runs are copied too")
		map.spots[10].wall_run.segment_length = 9.0
		assert_eq(shipped_run.segment_length, 3.0, "so an edit never reaches the shipped map")
		assert_eq(map.nights.size(), shipped.nights.size(), "%s keeps the shipped nights" % shot)


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


func test_the_field_gate_shot_runs_on_the_stress_map() -> void:
	var shot: StringName = &"overlay_field_gate"
	var crowd_end: int = ShotScenarios.ALL_SHOTS.find(&"crowd_stress_night")
	assert_eq(ShotScenarios.ALL_SHOTS[crowd_end - 1], shot, "it is second last of Phase 4")
	var crowd: Array[StringName] = ShotCrowdScenarios.CROWD_SHOTS
	assert_eq(crowd.find(shot), 2, "the third Phase 4 shot")
	assert_true(ShotCrowdScenarios.handles(shot), "the crowd scenes handle it")
	assert_true(_bash_shots().has(shot), "and the wrapper lists it")
	var map: MapConfig = ShotScenarios.map_for(shot)
	assert_eq(map.id, &"stress", "it runs on the stress map")
	assert_eq(map.starting_gold, ShotScenarios.SHOT_STARTING_GOLD, "with the shot gold")
	var shipped: MapConfig = load(GateStress.STRESS_MAP)
	assert_ne(map, shipped, "a deep copy, never the shared resource")
	assert_ne(map.spots[0].wall_run, shipped.spots[0].wall_run, "its wall run is copied too")


func test_the_crowd_stress_night_shot_closes_phase_4_and_runs_on_the_stress_map() -> void:
	var shot: StringName = &"crowd_stress_night"
	var after: int = ShotScenarios.ALL_SHOTS.find(shot) + 1
	assert_eq(
		after + ShotEconomyScenarios.ECONOMY_SHOTS.size(),
		ShotScenarios.ALL_SHOTS.size(),
		"only the Phase 5 shots follow it"
	)
	var crowd: Array[StringName] = ShotCrowdScenarios.CROWD_SHOTS
	assert_eq(crowd.find(shot), 3, "the fourth Phase 4 shot")
	assert_true(ShotCrowdScenarios.handles(shot), "the crowd scenes handle it")
	assert_true(_bash_shots().has(shot), "and the wrapper lists it")
	var map: MapConfig = ShotScenarios.map_for(shot)
	assert_eq(map.id, &"stress", "it runs on the stress map")
	assert_eq(map.starting_gold, ShotScenarios.SHOT_STARTING_GOLD, "with the shot gold")
	assert_ne(map, load(GateStress.STRESS_MAP), "a deep copy, never the shared resource")
	assert_lte(map.spots.size(), ShotScenarios.SHOT_STARTING_GOLD, "one coin per plot is paid")


func test_the_crowd_stress_night_king_outlasts_the_surge_and_the_shipped_king_is_untouched(
) -> void:
	var shipped: KingDef = load(ShotScenarios.KING_DATA_PATH)
	var shot_king: KingDef = ShotScenarios.king_def_for(&"crowd_stress_night")
	assert_eq(shot_king.max_health, ShotCrowdScenarios.STRESS_NIGHT_KING_HEALTH, "a long pool")
	assert_eq(shipped.max_health, 50, "the shipped king keeps 50")
	assert_eq(ShotScenarios.king_def_for(&"overlay_field_gate").max_health, 50, "other shots too")


func test_the_economy_shots_are_listed_and_handled_by_the_economy_scenes() -> void:
	var wanted: Array[StringName] = [
		&"castle_cards",
		&"castle_tier_four",
		&"field_locked",
		&"harbor_pond",
		&"shrine_awake_night",
		&"castle_gate_locked",
		&"economy_day",
	]
	assert_eq(
		ShotEconomyScenarios.ECONOMY_SHOTS,
		wanted,
		"the cards, the keep, the lock, the pond, the Shrine, the gate, the south side"
	)
	for shot: StringName in wanted:
		assert_true(ShotScenarios.ALL_SHOTS.has(shot), "%s is in ALL_SHOTS" % shot)
		assert_true(_bash_shots().has(shot), "and the wrapper lists it")
		assert_true(ShotEconomyScenarios.handles(shot), "%s has a Phase 5 scene" % shot)
		assert_false(ShotCrowdScenarios.handles(shot), "and is not a Phase 4 shot")
		assert_false(ShotArmyScenarios.handles(shot), "or a Phase 3 shot")
	assert_false(
		ShotEconomyScenarios.handles(ShotScenarios.DAY_OVERVIEW), "day_overview is not one"
	)


func _castle_building(map: MapConfig) -> BuildingDef:
	for building: BuildingDef in map.buildings:
		if building.id == &"castle_center":
			return building
	return null


func test_the_economy_shots_get_deep_copies_that_never_touch_the_shipped_map() -> void:
	var shipped: MapConfig = load(ShotScenarios.MAP_DATA_PATH)
	var shipped_gold: int = shipped.starting_gold
	var shipped_castle: BuildingDef = _castle_building(shipped)
	var shipped_cards: Array[ChoiceDef] = shipped_castle.tier_def(2).choices
	for shot: StringName in ShotEconomyScenarios.ECONOMY_SHOTS:
		if shot == &"shrine_awake_night":
			continue
		var map: MapConfig = ShotScenarios.map_for(shot)
		assert_not_null(map, "%s has a map" % shot)
		assert_ne(map, shipped, "a copy, not the shipped resource")
		assert_eq(map.starting_gold, ShotEconomyScenarios.SHOT_GOLD, "the shot gold for %s" % shot)
		assert_eq(map.spots.size(), shipped.spots.size(), "%s keeps every plot" % shot)
		assert_ne(_castle_building(map), shipped_castle, "the castle def is copied too")
		map.starting_gold = 1
		assert_eq(shipped.starting_gold, shipped_gold, "so an edit never reaches the shipped map")
		assert_eq(shipped_castle.tier_def(2).choices, shipped_cards, "nor its cards")


func test_the_economy_shots_run_with_the_shipped_king() -> void:
	for shot: StringName in ShotEconomyScenarios.ECONOMY_SHOTS:
		var def: KingDef = ShotScenarios.king_def_for(shot)
		var shipped: KingDef = load(ShotScenarios.KING_DATA_PATH)
		assert_eq(def.max_health, shipped.max_health, "%s: the shipped health" % shot)
		assert_ne(def, shipped, "%s: a copy" % shot)


func test_the_field_locked_shot_stages_a_deep_copy_with_the_mill_unbuilt() -> void:
	var shot: StringName = &"field_locked"
	var listed: Array[StringName] = ShotScenarios.ALL_SHOTS
	assert_eq(listed[listed.size() - 5], shot, "it is fifth last, four Phase 5 shots follow")
	assert_eq(ShotEconomyScenarios.ECONOMY_SHOTS[2], shot, "the third of the Phase 5 block")
	var map: MapConfig = ShotScenarios.map_for(shot)
	var shipped: MapConfig = load(ShotScenarios.MAP_DATA_PATH)
	assert_ne(map, shipped, "a deep copy, never the shared resource")
	assert_eq(map.spots.size(), shipped.spots.size(), "every plot is kept")
	var field_two: BuildSpotDef = null
	for spot: BuildSpotDef in map.spots:
		if spot.id == &"field_2":
			field_two = spot
	assert_not_null(field_two, "the shot's Field is on the map")
	if field_two != null:
		assert_eq(field_two.requires_spot, &"mill_1", "and is locked behind the Mill")


func test_the_harbor_pond_shot_is_a_waveless_deep_copy_with_the_harbor_unbuilt() -> void:
	var shot: StringName = &"harbor_pond"
	var listed: Array[StringName] = ShotScenarios.ALL_SHOTS
	assert_eq(listed[listed.size() - 4], shot, "it is fourth last, three Phase 5 shots follow")
	assert_eq(ShotEconomyScenarios.ECONOMY_SHOTS[3], shot, "the fourth of the Phase 5 block")
	assert_true(_bash_shots().has(shot), "the wrapper lists it")
	var map: MapConfig = ShotScenarios.map_for(shot)
	var shipped: MapConfig = load(ShotScenarios.MAP_DATA_PATH)
	assert_ne(map, shipped, "a deep copy, never the shared resource")
	assert_eq(map.nights.size(), 0, "waveless, so each night ends on its timer")
	assert_gt(shipped.nights.size(), 0, "and the shipped nights are untouched")
	assert_eq(map.pond_radius, shipped.pond_radius, "the pond is kept")
	assert_eq(map.starting_gold, ShotEconomyScenarios.SHOT_GOLD, "with the shot gold")


func test_the_shrine_awake_night_shot_runs_on_the_shrine_fixture_copy() -> void:
	var shot: StringName = &"shrine_awake_night"
	var listed: Array[StringName] = ShotScenarios.ALL_SHOTS
	assert_eq(listed[listed.size() - 3], shot, "it is third last, the plan 05-11 shots follow")
	assert_eq(ShotEconomyScenarios.ECONOMY_SHOTS[4], shot, "the fifth of the Phase 5 block")
	assert_true(_bash_shots().has(shot), "the wrapper lists it")
	var map: MapConfig = ShotScenarios.map_for(shot)
	var fixture: MapConfig = load(ShotEconomyScenarios.SHRINE_FIXTURE)
	assert_ne(map, fixture, "a deep copy, never the shared resource")
	assert_eq(map.id, fixture.id, "of the Shrine fixture")
	assert_eq(map.starting_gold, ShotEconomyScenarios.SHOT_GOLD, "with the shot gold")
	assert_eq(map.spots.size(), fixture.spots.size(), "every plot is kept")
	assert_gt(map.nights.size(), 0, "and its nights, so enemies die beside the Shrine")
