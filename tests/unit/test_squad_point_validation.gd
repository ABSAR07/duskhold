extends GutTest
## T-03-12, Pattern 6: ground points enter the simulation only as Vector2i centimetres inside a
## SquadOrderIntent and the command gate checks them. A move or attack-move needs exactly one point,
## a patrol one to SquadOrder.MAX_PATROL_POINTS - 1; every point must lie within
## MapConfig.ground_half_extent on both axes (inclusive). A rejection returns its reason as a value,
## announces command_rejected and changes nothing. Centimetres become metres by one division by 100.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const BARRACKS: StringName = &"barracks_1"
const ONLY_BARRACKS: Array[StringName] = [&"barracks_1"]
const KING := Vector2(3.0, 4.0)
const EXTENT_CM: int = 9000

var _ctx: RunContext
var _ordered: Array[Array] = []
var _rejected: Array[Array] = []


func before_each() -> void:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	_start(map)


func _start(map: MapConfig) -> void:
	_ctx = RunContext.new(map, load(TUNING), 1)
	_ordered = []
	_rejected = []
	_ctx.events.squad_ordered.connect(_on_squad_ordered)
	_ctx.events.command_rejected.connect(_on_command_rejected)
	assert_eq(_ctx.commands.submit(BuildIntent.new(BARRACKS)), CommandProcessor.OK, "built")
	_ctx.step()
	_ctx.king.report_position(KING)
	_ordered = []


func _on_squad_ordered(squad_id: StringName, verb: StringName, queued: bool, points: Array) -> void:
	_ordered.append([squad_id, verb, queued, points])


func _on_command_rejected(command: StringName, spot_id: StringName, reason: StringName) -> void:
	_rejected.append([command, spot_id, reason])


func _order(verb: StringName, cm: Array[Vector2i], queued: bool = false) -> StringName:
	return _ctx.commands.submit(SquadOrderIntent.new(ONLY_BARRACKS, verb, cm, queued))


func _assert_refused(
	verb: StringName, cm: Array[Vector2i], reason: StringName, label: String
) -> void:
	var anchor: Vector2 = _ctx.squads.anchor_of(BARRACKS)
	var orders: Array[Dictionary] = _ctx.squads.orders_of(BARRACKS)
	_rejected = []
	_ordered = []
	assert_eq(_order(verb, cm), reason, "%s: the reason comes back as a value" % label)
	assert_eq(_rejected, [[&"squad_order", BARRACKS, reason]], "%s: announced" % label)
	assert_eq(_ordered, [], "%s: no squad_ordered" % label)
	assert_eq(_ctx.squads.anchor_of(BARRACKS), anchor, "%s: the anchor did not move" % label)
	assert_eq(_ctx.squads.orders_of(BARRACKS), orders, "%s: the queue did not change" % label)


func _points(count: int) -> Array[Vector2i]:
	var cm: Array[Vector2i] = []
	for index: int in range(count):
		cm.append(Vector2i(100 * index, 200))
	return cm


func test_a_move_or_attack_move_without_a_point_is_refused_with_bad_point() -> void:
	for verb: StringName in [SquadOrder.VERB_MOVE, SquadOrder.VERB_ATTACK_MOVE]:
		_assert_refused(verb, [] as Array[Vector2i], CommandProcessor.BAD_POINT, "%s, none" % verb)


func test_a_move_or_attack_move_with_two_points_is_refused_with_bad_point() -> void:
	for verb: StringName in [SquadOrder.VERB_MOVE, SquadOrder.VERB_ATTACK_MOVE]:
		_assert_refused(verb, _points(2), CommandProcessor.BAD_POINT, "%s, two" % verb)


func test_a_point_one_centimetre_beyond_the_extent_is_refused_on_either_axis_and_sign() -> void:
	var beyond: int = EXTENT_CM + 1
	for cm: Vector2i in [
		Vector2i(beyond, 0), Vector2i(-beyond, 0), Vector2i(0, beyond), Vector2i(0, -beyond)
	]:
		_assert_refused(
			SquadOrder.VERB_MOVE, [cm] as Array[Vector2i], CommandProcessor.BAD_POINT, str(cm)
		)
		_assert_refused(
			SquadOrder.VERB_ATTACK_MOVE,
			[cm] as Array[Vector2i],
			CommandProcessor.BAD_POINT,
			"attack %s" % cm
		)


func test_a_point_exactly_at_the_extent_is_accepted() -> void:
	for cm: Vector2i in [
		Vector2i(EXTENT_CM, EXTENT_CM), Vector2i(-EXTENT_CM, -EXTENT_CM), Vector2i(0, EXTENT_CM)
	]:
		assert_eq(
			_order(SquadOrder.VERB_MOVE, [cm] as Array[Vector2i]), CommandProcessor.OK, str(cm)
		)
		assert_eq(_ctx.squads.anchor_of(BARRACKS), Vector2(cm) / 100.0, "%s reached the squad" % cm)


func test_the_extent_comes_from_the_map() -> void:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	map.ground_half_extent = 5.0
	_start(map)
	assert_eq(
		_order(SquadOrder.VERB_MOVE, [Vector2i(500, -500)] as Array[Vector2i]),
		CommandProcessor.OK,
		"5 m is inside a 5 m extent"
	)
	_assert_refused(
		SquadOrder.VERB_MOVE,
		[Vector2i(501, 0)] as Array[Vector2i],
		CommandProcessor.BAD_POINT,
		"5.01 m"
	)


func test_a_patrol_with_the_maximum_points_is_refused_and_one_fewer_is_accepted() -> void:
	_assert_refused(
		SquadOrder.VERB_PATROL,
		_points(SquadOrder.MAX_PATROL_POINTS),
		CommandProcessor.TOO_MANY_POINTS,
		"eight points"
	)
	assert_eq(
		_order(SquadOrder.VERB_PATROL, _points(SquadOrder.MAX_PATROL_POINTS - 1)),
		CommandProcessor.OK,
		"seven points"
	)
	assert_eq(
		_ctx.squads.patrol_path_of(BARRACKS).size(),
		SquadOrder.MAX_PATROL_POINTS,
		"the path is the centroid plus seven"
	)


func test_a_patrol_without_a_point_or_with_one_off_the_ground_is_refused_with_bad_point() -> void:
	_assert_refused(
		SquadOrder.VERB_PATROL, [] as Array[Vector2i], CommandProcessor.BAD_POINT, "no points"
	)
	var points: Array[Vector2i] = [Vector2i(100, 100), Vector2i(EXTENT_CM + 1, 0)]
	_assert_refused(
		SquadOrder.VERB_PATROL, points, CommandProcessor.BAD_POINT, "one off the ground"
	)


func test_a_centimetre_point_reaches_the_squad_as_exactly_its_metres() -> void:
	assert_eq(
		_order(SquadOrder.VERB_MOVE, [Vector2i(1234, -567)] as Array[Vector2i]),
		CommandProcessor.OK,
		"accepted"
	)
	assert_eq(_ctx.squads.anchor_of(BARRACKS), Vector2(12.34, -5.67), "12.34 m, -5.67 m")
	assert_eq(_ordered[0][3], [Vector2(12.34, -5.67)] as Array, "and so does the announcement")


func test_the_checks_run_in_the_documented_order() -> void:
	var ghost := SquadOrderIntent.new(
		[&"ghost_9"] as Array[StringName], SquadOrder.VERB_MOVE, [] as Array[Vector2i]
	)
	assert_eq(_ctx.commands.submit(ghost), CommandProcessor.UNKNOWN_SQUAD, "squad before point")
	var unknown_verb := SquadOrderIntent.new(ONLY_BARRACKS, &"dance", [] as Array[Vector2i])
	assert_eq(_ctx.commands.submit(unknown_verb), CommandProcessor.UNKNOWN_VERB, "verb first")
	_order(SquadOrder.VERB_HOLD, [] as Array[Vector2i])
	_order(SquadOrder.VERB_MOVE, [Vector2i(500, 500)] as Array[Vector2i])
	_order(SquadOrder.VERB_HOLD, [] as Array[Vector2i], true)
	var closed_and_bad: StringName = _order(
		SquadOrder.VERB_MOVE, [Vector2i(EXTENT_CM + 1, 0)] as Array[Vector2i], true
	)
	assert_eq(closed_and_bad, CommandProcessor.BAD_POINT, "a bad point beats a closed queue")


func test_follow_hold_and_rally_carry_no_point_and_ignore_any_given() -> void:
	for verb: StringName in [SquadOrder.VERB_FOLLOW, SquadOrder.VERB_HOLD, SquadOrder.VERB_RALLY]:
		assert_eq(_order(verb, _points(2)), CommandProcessor.OK, "%s accepted" % verb)
		assert_eq(_rejected, [] as Array[Array], "%s was not rejected" % verb)


func test_a_rejected_point_never_reaches_the_simulation_as_a_vector() -> void:
	var intent := SquadOrderIntent.new(
		ONLY_BARRACKS, SquadOrder.VERB_MOVE, [Vector2i(1, 2)] as Array[Vector2i]
	)
	var found: Array[Variant] = []
	for point: Variant in intent.points:
		found.append(point)
	assert_eq(found, [Vector2i(1, 2)] as Array[Variant], "the intent holds whole centimetres")
	assert_eq(typeof(found[0]), TYPE_VECTOR2I, "as integers")
