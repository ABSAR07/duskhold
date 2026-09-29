extends GutTest
## D-08: a spot that cannot be bought answers with hold_denied, once per key press, and never
## moves coins. Covers an unaffordable spot, a max-tier building and building at night.

const POOR_MAP := "res://tests/fixtures/fixture_map_poor.tres"
const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const RICH_GOLD: int = 50
const POOR_SPOT: StringName = &"spot_a"
const MAX_SPOT: StringName = &"house_1"
const HOLD_SECONDS: float = 1.0
const SECOND_PRESS_SECONDS: float = 0.3
const NEAR_OFFSET := Vector3(0.5, 0.0, 0.0)


func after_each() -> void:
	E2eSupport.release_all_actions()


func _stand_at(map_root: MapRoot, spot_id: StringName) -> void:
	var spot_position: Vector3 = map_root.get_context().buildings.get_spot(spot_id).position
	E2eSupport.teleport_king(map_root, spot_position + NEAR_OFFSET)
	await wait_process_frames(2)


func test_an_unaffordable_spot_is_denied_once_per_press_and_moves_no_coins() -> void:
	var map: MapConfig = load(POOR_MAP)
	var map_root: MapRoot = await E2eSupport.spawn_map(self, map)
	var ctx: RunContext = map_root.get_context()
	var hold: BuildHoldController = map_root.get_build_hold()
	assert_false(
		ctx.economy.can_afford(ctx.buildings.next_action_cost(POOR_SPOT)), "the spot is too dear"
	)
	var gold_before: int = ctx.economy.get_gold()
	await _stand_at(map_root, POOR_SPOT)
	watch_signals(hold)

	await E2eSupport.hold_action_seconds(self, &"action_build", HOLD_SECONDS)
	await wait_process_frames(2)
	assert_signal_emit_count(hold, "hold_denied", 1, "one denial for one long press")
	assert_signal_emitted_with_parameters(
		hold, "hold_denied", [POOR_SPOT, CommandProcessor.CANNOT_AFFORD]
	)
	assert_signal_not_emitted(hold, "hold_started")
	assert_signal_not_emitted(hold, "hold_progress")
	assert_eq(ctx.economy.get_gold(), gold_before, "gold unchanged")
	assert_null(ctx.buildings.get_instance(POOR_SPOT), "nothing was built")

	await E2eSupport.hold_action_seconds(self, &"action_build", SECOND_PRESS_SECONDS)
	await wait_process_frames(2)
	assert_signal_emit_count(hold, "hold_denied", 2, "a second press is denied again")
	assert_eq(ctx.economy.get_gold(), gold_before, "gold still unchanged")


func test_a_max_tier_building_is_denied_with_max_tier() -> void:
	var map: MapConfig = (load(PROTOTYPE_MAP) as MapConfig).duplicate(true)
	map.starting_gold = RICH_GOLD
	var map_root: MapRoot = await E2eSupport.spawn_map(self, map)
	var ctx: RunContext = map_root.get_context()
	var hold: BuildHoldController = map_root.get_build_hold()
	var building_def: BuildingDef = ctx.buildings.get_building_def_for_spot(MAX_SPOT)
	for _tier: int in range(building_def.max_tier()):
		assert_eq(ctx.commands.submit(BuildIntent.new(MAX_SPOT)), CommandProcessor.OK, "climb")
	assert_eq(ctx.buildings.current_tier(MAX_SPOT), building_def.max_tier(), "at the top")
	var gold_before: int = ctx.economy.get_gold()
	await _stand_at(map_root, MAX_SPOT)
	watch_signals(hold)

	await E2eSupport.hold_action_seconds(self, &"action_build", HOLD_SECONDS)
	await wait_process_frames(2)
	assert_signal_emit_count(hold, "hold_denied", 1, "one denial for one long press")
	assert_signal_emitted_with_parameters(
		hold, "hold_denied", [MAX_SPOT, CommandProcessor.MAX_TIER]
	)
	assert_signal_not_emitted(hold, "hold_started")
	assert_eq(ctx.economy.get_gold(), gold_before, "gold unchanged")
	assert_eq(ctx.buildings.current_tier(MAX_SPOT), building_def.max_tier(), "tier unchanged")


func test_pressing_at_night_is_denied_with_not_day() -> void:
	var map: MapConfig = (load(PROTOTYPE_MAP) as MapConfig).duplicate(true)
	map.starting_gold = RICH_GOLD
	var map_root: MapRoot = await E2eSupport.spawn_map(self, map)
	var ctx: RunContext = map_root.get_context()
	var hold: BuildHoldController = map_root.get_build_hold()
	var gold_before: int = ctx.economy.get_gold()
	await _stand_at(map_root, MAX_SPOT)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	watch_signals(hold)

	await E2eSupport.hold_action_seconds(self, &"action_build", HOLD_SECONDS)
	await wait_process_frames(2)
	assert_signal_emit_count(hold, "hold_denied", 1, "one denial for one long press")
	assert_signal_emitted_with_parameters(hold, "hold_denied", [MAX_SPOT, CommandProcessor.NOT_DAY])
	assert_signal_not_emitted(hold, "hold_started")
	assert_eq(ctx.economy.get_gold(), gold_before, "gold unchanged")
