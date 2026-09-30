class_name OverlayTestSupport
extends RefCounted
## Shared setup, lookup and read-only helpers for the debug overlay model suites. Not collected by
## GUT (no test_ prefix), so a fix to a helper reaches every suite that uses it.

const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
## How often the read-only checks collect, enough for a stray write or event to show up.
const COLLECT_REPEATS: int = 200


## A private copy of the loop tuning, so a test that edits it never writes to the cached resource.
## Copied all the way down like new_map, so a subresource added to LoopTuning later is not shared.
static func new_tuning() -> LoopTuning:
	return (load(TUNING) as LoopTuning).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)


## A private copy of the prototype map, for the same reason as new_tuning. It is copied all the way
## down, building definitions and their tiers included: those are external .tres files, which
## duplicate(true) would leave shared with the cached resource, so a test that edits a cost or a
## dawn income would leak into every later suite of the run.
static func new_map() -> MapConfig:
	return (load(PROTOTYPE_MAP) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)


## A RunContext on its own copies of the prototype map and (unless given) the tuning, with a House
## built on the first spot through the command gate. Duplicated, like the e2e tests do, so nothing
## here is ever tested against a shared cached resource that another test wrote to.
static func context_with_one_house(test: GutTest, tuning: LoopTuning = null) -> RunContext:
	var ctx: RunContext = RunContext.new(new_map(), tuning if tuning != null else new_tuning())
	var spot_ids: Array[StringName] = ctx.buildings.spot_ids()
	test.assert_false(spot_ids.is_empty(), "the map has a spot to build the setup House on")
	if spot_ids.is_empty():
		return ctx
	var result: StringName = ctx.commands.submit(BuildIntent.new(spot_ids[0]))
	test.assert_eq(result, CommandProcessor.OK, "the setup House is built through the command gate")
	return ctx


## The section of a collect() result with this title, or {} when it is not listed.
static func section(sections: Array, title: String) -> Dictionary:
	for candidate: Dictionary in sections:
		if candidate["title"] == title:
			return candidate
	return {}


## The value of the row with this label in a section, or null when the section has no such row.
static func row_value(section_dict: Dictionary, label: String) -> Variant:
	for row: Array in section_dict.get("rows", []):
		if row[0] == label:
			return row[1]
	return null


## Collects COLLECT_REPEATS times and asserts that nothing the model reads changed and that the
## simulation emitted no event. `ctx` is the context `model` was built on.
static func assert_collecting_is_read_only(
	test: GutTest, ctx: RunContext, model: DebugOverlayModel
) -> void:
	var gold_before: int = ctx.economy.get_gold()
	var phase_before: RunManager.RunPhase = ctx.run_manager.get_phase()
	var timer_before: float = ctx.run_manager.get_phase_time_remaining()
	var elapsed_before: float = ctx.run_manager.get_elapsed()
	var world_before: Dictionary = _agents_and_buildings(ctx)
	test.watch_signals(ctx.events)
	for i: int in COLLECT_REPEATS:
		model.collect(float(i))
	test.assert_eq(ctx.economy.get_gold(), gold_before, "gold unchanged")
	test.assert_eq(ctx.run_manager.get_phase(), phase_before, "phase unchanged")
	test.assert_eq(
		ctx.run_manager.get_phase_time_remaining(), timer_before, "the phase timer unchanged"
	)
	test.assert_eq(ctx.run_manager.get_elapsed(), elapsed_before, "simulation time unchanged")
	test.assert_eq(
		_agents_and_buildings(ctx),
		world_before,
		"every spot's tier and the unit and enemy counts unchanged"
	)
	for signal_name: String in SimSignals.ALL:
		test.assert_signal_not_emitted(ctx.events, signal_name)


## What the model reads beyond gold and the clock: every spot's tier and the unit and enemy counts.
static func _agents_and_buildings(ctx: RunContext) -> Dictionary:
	var tiers: Dictionary = {}
	for spot_id: StringName in ctx.buildings.spot_ids():
		tiers[spot_id] = ctx.buildings.current_tier(spot_id)
	return {"tiers": tiers, "units": ctx.get_unit_count(), "enemies": ctx.get_enemy_count()}
