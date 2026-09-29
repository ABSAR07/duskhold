extends GutTest
## BLDG-06: building and upgrading are impossible outside DAY. Exercised on a RunContext with no
## scene tree, entering NIGHT and DAWN only through the real start-night command.

const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"

var _tuning: LoopTuning


func before_each() -> void:
	_tuning = load(TUNING)


func _context() -> RunContext:
	return RunContext.new(load(PROTOTYPE_MAP), _tuning)


func _building_count(ctx: RunContext) -> int:
	var count: int = 0
	for spot_id: StringName in ctx.buildings.spot_ids():
		if ctx.buildings.get_instance(spot_id) != null:
			count += 1
	return count


func _enter_night(ctx: RunContext) -> void:
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")


func _enter_dawn(ctx: RunContext) -> void:
	_enter_night(ctx)
	ctx.run_manager.tick(_tuning.placeholder_night_seconds + 0.1)


func _assert_locked(ctx: RunContext, label: String) -> void:
	var gold_before: int = ctx.economy.get_gold()
	var buildings_before: int = _building_count(ctx)
	for spot_id: StringName in ctx.buildings.spot_ids():
		assert_eq(
			ctx.commands.validate_build(spot_id),
			CommandProcessor.NOT_DAY,
			"%s: validate_build(%s) is not_day" % [label, spot_id]
		)
		assert_eq(
			ctx.commands.submit(BuildIntent.new(spot_id)),
			CommandProcessor.NOT_DAY,
			"%s: submit(%s) is not_day" % [label, spot_id]
		)
	assert_eq(ctx.economy.get_gold(), gold_before, "%s: gold unchanged" % label)
	assert_eq(_building_count(ctx), buildings_before, "%s: buildings unchanged" % label)


func test_no_spot_can_be_built_on_during_the_night() -> void:
	var ctx: RunContext = _context()
	_enter_night(ctx)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.NIGHT, "in NIGHT")
	_assert_locked(ctx, "night")


func test_no_spot_can_be_built_on_during_dawn() -> void:
	var ctx: RunContext = _context()
	_enter_dawn(ctx)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "in DAWN")
	_assert_locked(ctx, "dawn")


func test_no_upgrade_is_possible_outside_the_day() -> void:
	var ctx: RunContext = _context()
	var house_spot: StringName = ctx.buildings.spot_ids()[0]
	assert_eq(ctx.commands.submit(BuildIntent.new(house_spot)), CommandProcessor.OK, "built by day")
	_enter_dawn(ctx)
	var gold_before: int = ctx.economy.get_gold()

	assert_eq(
		ctx.commands.submit(BuildIntent.new(house_spot)), CommandProcessor.NOT_DAY, "no upgrade"
	)
	assert_eq(ctx.buildings.current_tier(house_spot), 1, "still tier I")
	assert_eq(ctx.economy.get_gold(), gold_before, "gold unchanged")


func test_building_is_possible_again_on_the_next_day() -> void:
	var ctx: RunContext = _context()
	_enter_dawn(ctx)
	ctx.run_manager.tick(_tuning.dawn_seconds)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAY, "day again")
	var spot_id: StringName = ctx.buildings.spot_ids()[0]

	assert_eq(ctx.commands.validate_build(spot_id), CommandProcessor.OK, "valid again by day")
	assert_eq(ctx.commands.submit(BuildIntent.new(spot_id)), CommandProcessor.OK, "built again")
