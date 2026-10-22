extends GutTest
## Plan 05-11: the two shots that close the screenshot list, castle_gate_locked (a shipped Tower
## plot whose upgrade reads "Needs Castle II") and economy_day (the south side by day). Split from
## test_shot_list.gd, which is at the test cap. They run on deep copies of the shipped map, the
## second waveless so the dawns that grow the Harbor end on their timer, and the wrapper lists them.

const SCRIPT_PATH := "res://tools/screenshot.sh"
const GATE_SHOT: StringName = &"castle_gate_locked"
const DAY_SHOT: StringName = &"economy_day"


func _wrapper_text() -> String:
	var file: FileAccess = FileAccess.open(SCRIPT_PATH, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func test_the_two_shots_close_the_list() -> void:
	var listed: Array[StringName] = ShotScenarios.ALL_SHOTS
	assert_eq(listed[listed.size() - 2], GATE_SHOT, "the gate shot is second last")
	assert_eq(listed.back(), DAY_SHOT, "the south side closes the list")
	assert_eq(ShotEconomyScenarios.ECONOMY_SHOTS.back(), DAY_SHOT, "and the Phase 5 block")
	for shot: StringName in [GATE_SHOT, DAY_SHOT]:
		assert_true(_wrapper_text().contains(String(shot)), "the wrapper lists %s" % shot)
		assert_true(ShotEconomyScenarios.handles(shot), "%s has a Phase 5 scene" % shot)


func test_the_gate_shot_runs_on_a_deep_copy_with_the_shipped_nights() -> void:
	var shipped: MapConfig = load(ShotScenarios.MAP_DATA_PATH)
	var gate: MapConfig = ShotScenarios.map_for(GATE_SHOT)
	assert_ne(gate, shipped, "a deep copy, never the shared resource")
	assert_eq(gate.nights.size(), shipped.nights.size(), "the shipped nights are kept")
	assert_eq(gate.spots.size(), shipped.spots.size(), "so is every plot")
	assert_eq(gate.starting_gold, ShotEconomyScenarios.SHOT_GOLD, "with the shot gold")


func test_the_south_side_shot_is_a_waveless_deep_copy_with_the_pond() -> void:
	var shipped: MapConfig = load(ShotScenarios.MAP_DATA_PATH)
	var day: MapConfig = ShotScenarios.map_for(DAY_SHOT)
	assert_ne(day, shipped, "a deep copy as well")
	assert_eq(day.nights.size(), 0, "waveless, so each dawn that grows the Harbor ends on a timer")
	assert_gt(shipped.nights.size(), 0, "and the shipped nights are untouched")
	assert_eq(day.pond_radius, shipped.pond_radius, "the pond is kept")
	for spot_id: StringName in ShotEconomyScenarios.DAY_BUILD_ORDER:
		var found: bool = false
		for spot: BuildSpotDef in day.spots:
			found = found or spot.id == spot_id
		assert_true(found, "%s is on the map the shot builds on" % spot_id)
