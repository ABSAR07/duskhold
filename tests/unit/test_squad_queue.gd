extends GutTest
## UNIT-10 (D-09): the Shift queue. The queue holds at most SquadOrder.MAX_QUEUE orders, the running
## one first, and a tenth replaces the last. An order queued after a terminal verb (hold, follow,
## patrol) is refused with QUEUE_CLOSED. A non-queued order clears the queue first. A queued rally
## expands to a move to the king's position at apply time followed by hold. Re-issuing an order is
## idempotent and orders apply in submission order.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const BARRACKS: StringName = &"barracks_1"
const ARCHERY: StringName = &"archery_1"
const ONLY_BARRACKS: Array[StringName] = [&"barracks_1"]
const BOTH: Array[StringName] = [&"barracks_1", &"archery_1"]
const KING := Vector2(4.0, 6.0)
const KING_LATER := Vector2(-6.0, 8.0)
const FIRST := Vector2(0.0, 10.0)
const SECOND := Vector2(15.0, 10.0)
const WALK_STEPS: int = 900

var _map: MapConfig
var _events: SimEvents
var _buildings: BuildingSystem
var _squads: SquadSystem
var _enemies: EnemySystem
var _hits: PendingHits
var _tick: int = 0
var _ordered: Array[Array] = []
var _ctx: RunContext
var _rejected: Array[Array] = []


func before_each() -> void:
	var shipped: MapConfig = load(FIXTURE)
	_map = shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	_events = SimEvents.new()
	_buildings = BuildingSystem.new(_map, _events)
	_squads = SquadSystem.new(_map, _buildings, _events)
	_enemies = EnemySystem.new(_events)
	_hits = PendingHits.new()
	_tick = 0
	_ordered = []
	_events.squad_ordered.connect(_on_squad_ordered)
	_buildings.apply_next_tier(BARRACKS)
	_step()


func _on_squad_ordered(squad_id: StringName, verb: StringName, queued: bool, points: Array) -> void:
	_ordered.append([squad_id, verb, queued, points])


func _step() -> void:
	_squads.step(_tick, _enemies, _hits, false, KING)
	_squads.remove_dead()
	_tick += 1


func _give(verb: StringName, points: Array[Vector2], queued: bool, king: Vector2 = KING) -> void:
	_squads.apply_order(ONLY_BARRACKS, verb, points, queued, king)


func _move(point: Vector2, queued: bool) -> void:
	_give(SquadOrder.VERB_MOVE, [point] as Array[Vector2], queued)


func _verbs() -> Array[StringName]:
	var verbs: Array[StringName] = []
	for order: Dictionary in _squads.orders_of(BARRACKS):
		verbs.append(order["verb"])
	return verbs


## A RunContext with the barracks standing, for the checks that go through the command gate.
func _gate() -> void:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	_ctx = RunContext.new(map, load(TUNING), 1)
	_rejected = []
	_ctx.events.command_rejected.connect(_on_command_rejected)
	assert_eq(_ctx.commands.submit(BuildIntent.new(BARRACKS)), CommandProcessor.OK, "built")
	_ctx.step()
	_ctx.king.report_position(KING)


func _on_command_rejected(command: StringName, spot_id: StringName, reason: StringName) -> void:
	_rejected.append([command, spot_id, reason])


func _submit(verb: StringName, cm: Array[Vector2i], queued: bool) -> StringName:
	return _ctx.commands.submit(SquadOrderIntent.new(ONLY_BARRACKS, verb, cm, queued))


func test_a_queue_runs_its_orders_in_turn_and_ends_with_the_hold() -> void:
	_move(FIRST, false)
	_move(SECOND, true)
	_give(SquadOrder.VERB_HOLD, [] as Array[Vector2], true)
	assert_eq(
		_verbs(),
		[SquadOrder.VERB_MOVE, SquadOrder.VERB_MOVE, SquadOrder.VERB_HOLD] as Array[StringName],
		"move, move, hold waiting"
	)
	assert_eq(_squads.resting_stance(BARRACKS), SquadOrder.STANCE_HOLD, "it will rest in hold")
	var anchors: Array[Vector2] = [_squads.anchor_of(BARRACKS)]
	var steps: int = 0
	while not _squads.orders_of(BARRACKS).is_empty() and steps < WALK_STEPS:
		_step()
		steps += 1
		if _squads.anchor_of(BARRACKS) != anchors.back():
			anchors.append(_squads.anchor_of(BARRACKS))
	assert_lt(steps, WALK_STEPS, "the queue drained")
	assert_eq(anchors, [FIRST, SECOND] as Array[Vector2], "A first, then B")
	assert_eq(_squads.resting_stance(BARRACKS), SquadOrder.STANCE_HOLD, "holding")
	assert_eq(_squads.anchor_of(BARRACKS), SECOND, "at B")
	_steps_by_day(30)
	assert_eq(_squads.anchor_of(BARRACKS), SECOND, "and it stays there")


func _steps_by_day(count: int) -> void:
	for _i: int in range(count):
		_step()


func test_orders_of_lists_the_running_order_first_with_its_points() -> void:
	_move(FIRST, false)
	_move(SECOND, true)
	var orders: Array[Dictionary] = _squads.orders_of(BARRACKS)
	assert_eq(orders[0]["verb"], SquadOrder.VERB_MOVE, "head is the running move")
	assert_eq(orders[0]["points"], [FIRST] as Array[Vector2], "with its point")
	assert_eq(orders[1]["points"], [SECOND] as Array[Vector2], "then the queued one")
	orders.clear()
	assert_eq(_squads.orders_of(BARRACKS).size(), 2, "the snapshot is a copy")
	assert_eq(_squads.orders_of(&"ghost").size(), 0, "an unknown squad has none")


func test_a_queued_order_on_an_empty_queue_starts_at_once() -> void:
	_move(FIRST, true)
	assert_eq(_squads.anchor_of(BARRACKS), FIRST, "nothing to wait for")
	assert_eq(_squads.orders_of(BARRACKS).size(), 1, "it is the running order")


func test_a_non_queued_order_clears_the_queue_first() -> void:
	_move(FIRST, false)
	_move(SECOND, true)
	_move(KING_LATER, false)
	assert_eq(_squads.orders_of(BARRACKS).size(), 1, "only the new order is left")
	assert_eq(_squads.anchor_of(BARRACKS), KING_LATER, "and it runs")


func test_the_tenth_queued_order_replaces_the_last() -> void:
	_move(Vector2(0.0, 0.0), false)
	for index: int in range(1, 10):
		_move(Vector2(float(index), 5.0), true)
	var orders: Array[Dictionary] = _squads.orders_of(BARRACKS)
	assert_eq(orders.size(), SquadOrder.MAX_QUEUE, "nine orders, no more")
	assert_eq(orders[0]["points"], [Vector2(0.0, 0.0)] as Array[Vector2], "the running one stays")
	assert_eq(orders[7]["points"], [Vector2(7.0, 5.0)] as Array[Vector2], "the eighth is kept")
	assert_eq(orders[8]["points"], [Vector2(9.0, 5.0)] as Array[Vector2], "the tenth took the last")


func test_repeating_a_queued_order_never_grows_the_queue_past_nine() -> void:
	_move(Vector2(0.0, 0.0), false)
	for _i: int in range(30):
		_move(Vector2(3.0, 3.0), true)
	assert_eq(_squads.orders_of(BARRACKS).size(), SquadOrder.MAX_QUEUE, "still nine")


func test_re_issuing_the_same_non_queued_order_leaves_an_identical_queue() -> void:
	_move(FIRST, false)
	var once: Array[Dictionary] = _squads.orders_of(BARRACKS)
	_move(FIRST, false)
	assert_eq(_squads.orders_of(BARRACKS), once, "the same queue")
	assert_eq(_ordered.size(), 2, "one squad_ordered per issue")
	assert_eq(_ordered[0], _ordered[1], "and the two announcements are identical")


func test_two_orders_between_two_steps_apply_in_submission_order() -> void:
	_move(FIRST, false)
	_move(SECOND, false)
	_step()
	assert_eq(
		_squads.orders_of(BARRACKS).size(), 1, "the later non-queued order replaced the first"
	)
	assert_eq(_squads.anchor_of(BARRACKS), SECOND, "and is the one that runs")
	assert_eq(_ordered[0][3], [FIRST] as Array, "both were announced, first one first")
	assert_eq(_ordered[1][3], [SECOND] as Array, "second one second")


func test_a_queued_rally_appends_a_move_to_the_king_then_hold() -> void:
	_move(FIRST, false)
	_give(SquadOrder.VERB_RALLY, [] as Array[Vector2], true, KING_LATER)
	assert_eq(
		_verbs(),
		[SquadOrder.VERB_MOVE, SquadOrder.VERB_MOVE, SquadOrder.VERB_HOLD] as Array[StringName],
		"the rally expanded to a move and a hold"
	)
	assert_eq(
		_squads.orders_of(BARRACKS)[1]["points"], [KING_LATER] as Array[Vector2], "to the king"
	)
	assert_eq(_ordered.back()[3], [KING_LATER] as Array, "the announcement carries the king's spot")
	assert_eq(_squads.resting_stance(BARRACKS), SquadOrder.STANCE_HOLD, "ending in hold")


func test_a_queued_rally_near_the_cap_replaces_enough_of_the_tail_to_fit_both_halves() -> void:
	_move(Vector2(0.0, 0.0), false)
	for index: int in range(1, 8):
		_move(Vector2(float(index), 5.0), true)
	assert_eq(_squads.orders_of(BARRACKS).size(), 8, "one place left")
	_give(SquadOrder.VERB_RALLY, [] as Array[Vector2], true, KING_LATER)
	var verbs: Array[StringName] = _verbs()
	assert_eq(verbs.size(), SquadOrder.MAX_QUEUE, "still nine")
	assert_eq(verbs[7], SquadOrder.VERB_MOVE, "the move half")
	assert_eq(verbs[8], SquadOrder.VERB_HOLD, "and the hold half both fit")


func test_a_queued_hold_announces_no_point_and_a_non_queued_hold_its_anchor() -> void:
	_move(FIRST, false)
	_ordered = []
	_give(SquadOrder.VERB_HOLD, [] as Array[Vector2], true)
	assert_eq(_ordered[0][3], [] as Array, "the spot is not known until it runs")
	_give(SquadOrder.VERB_HOLD, [] as Array[Vector2], false)
	assert_eq(_ordered[1][3].size(), 1, "a hold that runs now froze its anchor")


func test_a_queued_order_after_hold_follow_or_patrol_is_refused_with_queue_closed() -> void:
	_gate()
	for terminal: StringName in [
		SquadOrder.VERB_HOLD, SquadOrder.VERB_FOLLOW, SquadOrder.VERB_PATROL
	]:
		var cm: Array[Vector2i] = [Vector2i(1500, 1000)]
		assert_eq(_submit(SquadOrder.VERB_MOVE, cm, false), CommandProcessor.OK, "a move runs")
		var terminal_cm: Array[Vector2i] = []
		if terminal == SquadOrder.VERB_PATROL:
			terminal_cm = [Vector2i(500, 500)]
		assert_eq(_submit(terminal, terminal_cm, true), CommandProcessor.OK, "%s queues" % terminal)
		var before: Array[Dictionary] = _ctx.squads.orders_of(BARRACKS)
		_rejected = []
		assert_eq(
			_submit(SquadOrder.VERB_MOVE, cm, true),
			CommandProcessor.QUEUE_CLOSED,
			"nothing queues after %s" % terminal
		)
		assert_eq(_rejected, [[&"squad_order", BARRACKS, CommandProcessor.QUEUE_CLOSED]], "told")
		assert_eq(_ctx.squads.orders_of(BARRACKS), before, "the queue is untouched")


## A RunContext with both the barracks and the archery range standing (the mixed-selection checks).
func _gate_both() -> void:
	_gate()
	assert_eq(_ctx.commands.submit(BuildIntent.new(ARCHERY)), CommandProcessor.OK, "range built")
	_ctx.step()


func _submit_both(verb: StringName, cm: Array[Vector2i], queued: bool) -> StringName:
	return _ctx.commands.submit(SquadOrderIntent.new(BOTH, verb, cm, queued))


func test_a_queued_order_for_a_mixed_selection_skips_the_closed_squad_only() -> void:
	_gate_both()
	var cm: Array[Vector2i] = [Vector2i(1500, 1000)]
	var none: Array[Vector2i] = []
	assert_eq(_submit_both(SquadOrder.VERB_MOVE, cm, false), CommandProcessor.OK, "both walk")
	assert_eq(_submit(SquadOrder.VERB_HOLD, none, true), CommandProcessor.OK, "barracks will hold")
	var closed_before: Array[Dictionary] = _ctx.squads.orders_of(BARRACKS)
	var open_before: int = _ctx.squads.orders_of(ARCHERY).size()
	_rejected = []
	assert_eq(
		_submit_both(SquadOrder.VERB_MOVE, cm, true),
		CommandProcessor.OK,
		"one open squad is enough: the order is not refused whole"
	)
	assert_eq(_rejected, [] as Array[Array], "and nobody is told it was refused")
	assert_eq(_ctx.squads.orders_of(BARRACKS), closed_before, "the closed squad is skipped")
	assert_eq(_ctx.squads.orders_of(ARCHERY).size(), open_before + 1, "the open squad queued it")


func test_a_queued_order_is_refused_when_every_selected_squad_is_closed() -> void:
	_gate_both()
	var cm: Array[Vector2i] = [Vector2i(1500, 1000)]
	var none: Array[Vector2i] = []
	assert_eq(_submit_both(SquadOrder.VERB_MOVE, cm, false), CommandProcessor.OK, "both walk")
	assert_eq(_submit_both(SquadOrder.VERB_HOLD, none, true), CommandProcessor.OK, "both will hold")
	_rejected = []
	assert_eq(
		_submit_both(SquadOrder.VERB_MOVE, cm, true), CommandProcessor.QUEUE_CLOSED, "all closed"
	)
	assert_eq(_rejected.size(), 1, "told once")
	assert_eq(_rejected[0][2], CommandProcessor.QUEUE_CLOSED, "with the reason")


func test_a_non_queued_order_is_never_refused_for_a_closed_queue() -> void:
	_gate()
	var cm: Array[Vector2i] = [Vector2i(1500, 1000)]
	_submit(SquadOrder.VERB_MOVE, cm, false)
	_submit(SquadOrder.VERB_HOLD, [] as Array[Vector2i], true)
	assert_eq(_submit(SquadOrder.VERB_MOVE, cm, false), CommandProcessor.OK, "it replaces them")
	assert_eq(_ctx.squads.orders_of(BARRACKS).size(), 1, "one order")


func test_a_squad_whose_building_falls_keeps_executing_its_orders() -> void:
	_move(FIRST, false)
	_move(SECOND, true)
	_buildings.damage_building(BARRACKS, 10000)
	assert_true(_buildings.is_destroyed(BARRACKS), "the barracks fell")
	var steps: int = 0
	while not _squads.orders_of(BARRACKS).is_empty() and steps < WALK_STEPS:
		_step()
		steps += 1
	assert_lt(steps, WALK_STEPS, "the queue still ran")
	assert_eq(_squads.anchor_of(BARRACKS), SECOND, "to the end")


func test_an_order_after_the_run_ended_is_refused_with_run_over() -> void:
	_gate()
	_submit(SquadOrder.VERB_MOVE, [Vector2i(500, 500)] as Array[Vector2i], false)
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night")
	assert_true(_ctx.run_manager.end_run_in_defeat(), "the run ends")
	var before: Array[Dictionary] = _ctx.squads.orders_of(BARRACKS)
	assert_eq(
		_submit(SquadOrder.VERB_MOVE, [Vector2i(900, 900)] as Array[Vector2i], true),
		CommandProcessor.RUN_OVER,
		"refused"
	)
	assert_eq(_ctx.squads.orders_of(BARRACKS), before, "nothing changed")
