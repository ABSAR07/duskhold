extends GutTest
## BLDG-09, D-03, D-10: a tier can need the castle at tier N and a plot's first build can need
## another plot at tier N. validate_build checks NOT_DAY, UNKNOWN_SPOT, MAX_TIER, CASTLE_TIER or
## NEEDS_SPOT, then CANNOT_AFFORD; a refusal announces command_rejected and spends nothing. The
## gate fixture carries an inline tower whose tier II needs castle II, so shipped tower.tres stays
## ungated. [assumed-contract BLDG-09]: exactly at the required tier unlocks, one below refuses, 0
## never refuses and MAX_TIER wins at the top.
## Gap round G-05-2 (owner UAT decision 2026-10-25): every health and damage number is 100
## times larger; this test's felling blow moved with them so it fells what it felled before.

const FIXTURE := "res://tests/fixtures/fixture_map_gate.tres"
const ONE_NIGHT := "res://tests/fixtures/fixture_map_one_night.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const TOWER: StringName = &"tower_1"
const HOUSE_A: StringName = &"house_a"
const HOUSE_B: StringName = &"house_b"
const CASTLE: StringName = &"castle_plot"
const CARD: StringName = &"royal_training"
const RICH_GOLD: int = 80

var _ctx: RunContext
var _rejections: Array = []


func before_each() -> void:
	_rejections = []
	_ctx = _context(load(FIXTURE) as MapConfig, RICH_GOLD)


func _context(source: MapConfig, gold: int) -> RunContext:
	var map: MapConfig = source.duplicate(true)
	map.starting_gold = gold
	var ctx: RunContext = RunContext.new(map, load(TUNING))
	ctx.events.command_rejected.connect(_on_rejected)
	return ctx


func _on_rejected(command: StringName, spot_id: StringName, reason: StringName) -> void:
	_rejections.append([command, spot_id, reason])


func _build(ctx: RunContext, spot_id: StringName, choice: StringName = &"") -> void:
	var result: StringName = ctx.commands.submit(BuildIntent.new(spot_id, choice))
	assert_eq(result, CommandProcessor.OK, "build %s" % spot_id)


func test_the_gated_tower_tier_is_castle_tier_while_the_castle_is_at_one() -> void:
	_build(_ctx, TOWER)
	assert_eq(_ctx.commands.validate_build(TOWER), CommandProcessor.CASTLE_TIER, "castle I")


func test_submitting_the_gated_tier_announces_it_and_spends_nothing() -> void:
	_build(_ctx, TOWER)
	var gold: int = _ctx.economy.get_gold()
	var result: StringName = _ctx.commands.submit(BuildIntent.new(TOWER))
	assert_eq(result, CommandProcessor.CASTLE_TIER, "refused")
	assert_eq(_rejections, [[&"build", TOWER, &"castle_tier"]], "announced")
	assert_eq(_ctx.economy.get_gold(), gold, "gold unchanged")
	assert_eq(_ctx.buildings.current_tier(TOWER), 1, "the tower stays at tier I")


func test_castle_two_unlocks_the_tier_and_castle_one_below_it_refuses() -> void:
	_build(_ctx, TOWER)
	assert_eq(_ctx.commands.validate_build(TOWER), CommandProcessor.CASTLE_TIER, "one below")
	_build(_ctx, CASTLE, CARD)
	assert_eq(BuildRequirements.castle_tier(_ctx.map, _ctx.buildings), 2, "castle II stands")
	assert_eq(_ctx.commands.validate_build(TOWER), CommandProcessor.OK, "exactly at the tier")
	_build(_ctx, TOWER)
	assert_eq(_ctx.buildings.current_tier(TOWER), 2, "Tower II was bought")


func test_a_gated_tier_with_too_little_gold_is_castle_tier_not_cannot_afford() -> void:
	var ctx: RunContext = _context(load(FIXTURE) as MapConfig, 4)
	_build(ctx, TOWER)
	assert_eq(ctx.economy.get_gold(), 0, "the first tower took all the gold")
	assert_eq(ctx.commands.validate_build(TOWER), CommandProcessor.CASTLE_TIER, "locked first")


func test_an_ungated_tier_with_too_little_gold_is_still_cannot_afford() -> void:
	var ctx: RunContext = _context(load(FIXTURE) as MapConfig, 0)
	assert_eq(ctx.commands.validate_build(TOWER), CommandProcessor.CANNOT_AFFORD, "a plain price")


func test_a_requirement_of_zero_never_refuses() -> void:
	assert_eq(_ctx.commands.validate_build(TOWER), CommandProcessor.OK, "Tower I needs nothing")
	assert_eq(_ctx.commands.validate_build(HOUSE_A), CommandProcessor.OK, "nor does the House")
	assert_eq(_ctx.commands.validate_build(CASTLE, CARD), CommandProcessor.OK, "nor the castle")


func test_a_tower_at_its_top_tier_is_max_tier_not_castle_tier() -> void:
	_build(_ctx, CASTLE, CARD)
	_build(_ctx, TOWER)
	_build(_ctx, TOWER)
	assert_eq(_ctx.commands.validate_build(TOWER), CommandProcessor.MAX_TIER, "nothing left")


func test_a_plot_needing_another_is_needs_spot_until_that_plot_stands() -> void:
	assert_eq(_ctx.commands.validate_build(HOUSE_B), CommandProcessor.NEEDS_SPOT, "house_a missing")
	assert_eq(_ctx.commands.validate_build(HOUSE_A), CommandProcessor.OK, "the required plot")
	_build(_ctx, HOUSE_A)
	assert_eq(_ctx.commands.validate_build(HOUSE_B), CommandProcessor.OK, "house_a stands")


func test_submitting_a_locked_plot_announces_needs_spot_and_spends_nothing() -> void:
	var gold: int = _ctx.economy.get_gold()
	var result: StringName = _ctx.commands.submit(BuildIntent.new(HOUSE_B))
	assert_eq(result, CommandProcessor.NEEDS_SPOT, "refused")
	assert_eq(_rejections, [[&"build", HOUSE_B, &"needs_spot"]], "announced")
	assert_eq(_ctx.economy.get_gold(), gold, "gold unchanged")
	assert_eq(_ctx.buildings.current_tier(HOUSE_B), 0, "nothing built")


func test_a_locked_plot_with_too_little_gold_is_needs_spot_not_cannot_afford() -> void:
	var ctx: RunContext = _context(load(FIXTURE) as MapConfig, 0)
	assert_eq(ctx.commands.validate_build(HOUSE_B), CommandProcessor.NEEDS_SPOT, "locked first")


func test_the_castle_tier_is_one_at_the_start_and_zero_without_a_castle_plot() -> void:
	assert_eq(BuildRequirements.castle_tier(_ctx.map, _ctx.buildings), 1, "the castle stands")
	var plain: RunContext = _context(load(ONE_NIGHT) as MapConfig, 0)
	assert_eq(BuildRequirements.castle_tier(plain.map, plain.buildings), 0, "no castle plot")


func test_on_a_map_without_a_castle_plot_a_castle_requirement_never_applies() -> void:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate(true)
	var kept: Array[BuildSpotDef] = []
	for spot: BuildSpotDef in map.spots:
		if not spot.is_castle:
			kept.append(spot)
	map.spots = kept
	var ctx: RunContext = _context(map, RICH_GOLD)
	_build(ctx, TOWER)
	assert_eq(ctx.commands.validate_build(TOWER), CommandProcessor.OK, "Tower II is open")
	_build(ctx, TOWER)
	assert_eq(ctx.buildings.current_tier(TOWER), 2, "and it can be bought")


func test_a_destroyed_required_plot_does_not_relock_a_built_plot() -> void:
	_build(_ctx, HOUSE_A)
	_build(_ctx, HOUSE_B)
	_ctx.buildings.damage_building(HOUSE_A, 100000)
	assert_true(_ctx.buildings.is_destroyed(HOUSE_A), "house_a fell")
	assert_eq(_ctx.commands.validate_build(HOUSE_B), CommandProcessor.OK, "house_b upgrades free")


func test_the_night_is_reported_before_a_requirement() -> void:
	_build(_ctx, TOWER)
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night begins")
	assert_eq(_ctx.commands.validate_build(TOWER), CommandProcessor.NOT_DAY, "not day first")
	assert_eq(_ctx.commands.validate_build(&"nowhere"), CommandProcessor.NOT_DAY, "even unknown")


func test_an_unknown_spot_has_no_requirement() -> void:
	assert_eq(_ctx.commands.validate_build(&"nowhere"), CommandProcessor.UNKNOWN_SPOT, "unknown")
	assert_eq(
		BuildRequirements.rejection(_ctx.map, _ctx.buildings, &"nowhere"),
		CommandProcessor.OK,
		"the requirement check leaves it to the gate"
	)
