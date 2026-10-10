extends GutTest
## D-09, T-03-10, T-03-11: a SquadOrderIntent goes through the one CommandProcessor gate. Check
## order RUN_OVER, NO_SQUADS, UNKNOWN_SQUAD, UNKNOWN_VERB; a rejection returns its reason as a
## value, announces command_rejected and changes nothing. An accepted order is applied to its
## squads in creation order whatever order the ids arrive in, and squad_ordered carries the points
## the simulation resolved.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const BARRACKS: StringName = &"barracks_1"
const ARCHERY: StringName = &"archery_1"
const KILL_DAMAGE: int = 1000
const KING := Vector2(3.0, 4.0)

var _ctx: RunContext
var _ordered: Array[Array] = []
var _rejected: Array[Array] = []


func before_each() -> void:
	var shipped: MapConfig = load(FIXTURE)
	var map: MapConfig = shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	_ctx = RunContext.new(map, load(TUNING), 1)
	_ordered = []
	_rejected = []
	_ctx.events.squad_ordered.connect(_on_squad_ordered)
	_ctx.events.command_rejected.connect(_on_command_rejected)
	assert_eq(
		_ctx.commands.submit(BuildIntent.new(BARRACKS)), CommandProcessor.OK, "barracks built"
	)
	assert_eq(_ctx.commands.submit(BuildIntent.new(ARCHERY)), CommandProcessor.OK, "range built")
	_ctx.step()
	_ctx.king.report_position(KING)
	_ordered = []
	_rejected = []


func _on_squad_ordered(squad_id: StringName, verb: StringName, queued: bool, points: Array) -> void:
	_ordered.append([squad_id, verb, queued, points])


func _on_command_rejected(command: StringName, spot_id: StringName, reason: StringName) -> void:
	_rejected.append([command, spot_id, reason])


func _ids(list: Array[StringName]) -> Array[StringName]:
	return list


## The castle falls on the first night: the run is over.
func _end_the_run() -> void:
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	assert_true(_ctx.run_manager.end_run_in_defeat(), "the run ends")
	assert_true(_ctx.run_manager.is_run_over(), "and is over")
	_ordered = []
	_rejected = []


func _state() -> Array:
	var state: Array = []
	for squad_id: StringName in _ctx.squads.squad_ids():
		(
			state
			. append(
				[
					squad_id,
					_ctx.squads.anchor_of(squad_id),
					_ctx.squads.resting_stance(squad_id),
					_ctx.squads.alive_count(squad_id),
				]
			)
		)
	return state


func _assert_rejected(intent: SquadOrderIntent, reason: StringName, first_id: StringName) -> void:
	var before: Array = _state()
	assert_eq(_ctx.commands.submit(intent), reason, "the reason comes back as a value")
	assert_eq(_rejected, [[&"squad_order", first_id, reason]], "command_rejected is announced")
	assert_eq(_ordered, [], "no squad_ordered for a rejection")
	assert_eq(_state(), before, "nothing changed")


func test_an_empty_list_is_rejected_with_no_squads() -> void:
	_assert_rejected(
		SquadOrderIntent.new(_ids([]), SquadOrder.VERB_HOLD), CommandProcessor.NO_SQUADS, &""
	)


func test_an_unknown_squad_is_rejected_even_beside_a_known_one() -> void:
	var intent := SquadOrderIntent.new(_ids([BARRACKS, &"ghost_9"]), SquadOrder.VERB_HOLD)
	_assert_rejected(intent, CommandProcessor.UNKNOWN_SQUAD, BARRACKS)


func test_a_verb_outside_the_allow_list_is_rejected() -> void:
	for verb: StringName in [&"dance", &"", &"teleport"]:
		_rejected = []
		_assert_rejected(
			SquadOrderIntent.new(_ids([BARRACKS]), verb), CommandProcessor.UNKNOWN_VERB, BARRACKS
		)


func test_the_checks_run_in_the_documented_order() -> void:
	var nobody := SquadOrderIntent.new(_ids([]), &"dance")
	assert_eq(_ctx.commands.submit(nobody), CommandProcessor.NO_SQUADS, "no squads beats the verb")
	var ghost := SquadOrderIntent.new(_ids([&"ghost_9"]), &"dance")
	assert_eq(_ctx.commands.submit(ghost), CommandProcessor.UNKNOWN_SQUAD, "squad beats verb")
	_end_the_run()
	assert_eq(_ctx.commands.submit(nobody), CommandProcessor.RUN_OVER, "run over beats the rest")
	assert_eq(_ctx.commands.submit(ghost), CommandProcessor.RUN_OVER, "also with an unknown squad")


func test_an_order_after_the_run_ended_changes_nothing() -> void:
	_end_the_run()
	var before: Array = _state()
	var result: StringName = _ctx.commands.submit(
		SquadOrderIntent.new(_ids([BARRACKS]), SquadOrder.VERB_FOLLOW)
	)
	assert_eq(result, CommandProcessor.RUN_OVER, "refused")
	assert_eq(_rejected, [[&"squad_order", BARRACKS, CommandProcessor.RUN_OVER]], "announced")
	assert_eq(_ordered, [], "nothing ordered")
	assert_eq(_state(), before, "nothing changed")


func test_ids_given_out_of_order_are_applied_and_emitted_in_creation_order() -> void:
	var intent := SquadOrderIntent.new(_ids([ARCHERY, BARRACKS]), SquadOrder.VERB_FOLLOW)
	assert_eq(_ctx.commands.submit(intent), CommandProcessor.OK, "accepted")
	assert_eq(_ordered.size(), 2, "once per squad")
	assert_eq(_ordered[0][0], BARRACKS, "barracks was created first")
	assert_eq(_ordered[1][0], ARCHERY, "archery second")
	assert_eq(_rejected, [], "no rejection")


func test_a_repeated_id_is_ordered_once() -> void:
	var intent := SquadOrderIntent.new(_ids([BARRACKS, BARRACKS]), SquadOrder.VERB_HOLD)
	assert_eq(_ctx.commands.submit(intent), CommandProcessor.OK, "accepted")
	assert_eq(_ordered.size(), 1, "one squad_ordered")


func test_follow_carries_no_point() -> void:
	_ctx.commands.submit(SquadOrderIntent.new(_ids([BARRACKS]), SquadOrder.VERB_FOLLOW))
	assert_eq(_ordered, [[BARRACKS, SquadOrder.VERB_FOLLOW, false, []]], "follow resolves nothing")
	assert_eq(_ctx.squads.resting_stance(BARRACKS), SquadOrder.STANCE_FOLLOW, "and follows")


func test_hold_carries_the_anchor_it_froze() -> void:
	_ctx.commands.submit(SquadOrderIntent.new(_ids([BARRACKS]), SquadOrder.VERB_HOLD))
	var anchor: Vector2 = _ctx.squads.anchor_of(BARRACKS)
	assert_eq(_ordered, [[BARRACKS, SquadOrder.VERB_HOLD, false, [anchor]]], "the frozen anchor")
	assert_eq(_ctx.squads.resting_stance(BARRACKS), SquadOrder.STANCE_HOLD, "and holds")


func test_rally_carries_the_king_position_at_the_apply_tick() -> void:
	_ctx.commands.submit(SquadOrderIntent.new(_ids([ARCHERY]), SquadOrder.VERB_RALLY))
	assert_eq(_ordered, [[ARCHERY, SquadOrder.VERB_RALLY, false, [KING]]], "the king position")
	assert_eq(_ctx.squads.anchor_of(ARCHERY), KING, "the anchor is there at once")
	_ctx.king.report_position(Vector2(-8.0, 8.0))
	assert_eq(_ctx.squads.anchor_of(ARCHERY), KING, "the king leaving moves nothing")


func test_an_order_to_a_squad_with_nobody_alive_is_accepted() -> void:
	for unit_id: int in _ctx.squads.unit_ids_of(BARRACKS):
		_ctx.squads.damage_unit(unit_id, KILL_DAMAGE, &"test")
	_ctx.squads.remove_dead()
	assert_eq(_ctx.squads.alive_count(BARRACKS), 0, "nobody is left")
	var result: StringName = _ctx.commands.submit(
		SquadOrderIntent.new(_ids([BARRACKS]), SquadOrder.VERB_RALLY)
	)
	assert_eq(result, CommandProcessor.OK, "accepted")
	assert_eq(_ctx.squads.anchor_of(BARRACKS), KING, "replacements will walk to the new anchor")


func test_the_intent_keeps_its_own_copies_of_the_lists() -> void:
	var ids: Array[StringName] = [BARRACKS]
	var cm: Array[Vector2i] = [Vector2i(150, -250)]
	var intent := SquadOrderIntent.new(ids, SquadOrder.VERB_HOLD, cm, true)
	ids.append(ARCHERY)
	cm.clear()
	assert_eq(intent.squad_ids, [BARRACKS] as Array[StringName], "ids were copied")
	assert_eq(
		intent.points, [Vector2i(150, -250)] as Array[Vector2i], "centimetre points were copied"
	)
	assert_true(intent.queued, "the queue flag is kept")
