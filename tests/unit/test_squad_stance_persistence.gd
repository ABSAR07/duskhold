extends GutTest
## D-14, D-05: stances, anchors and orders persist across begin_night and the dawn restore, day
## after day, until the player changes them. A held squad keeps its stance and spot; a following
## squad follows again the next day; a replacement raised at night appears at the building's post
## and walks to the squad's current anchor. Runs on a RunContext over the squad fixture.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const BARRACKS: StringName = &"barracks_1"
const ONLY_BARRACKS: Array[StringName] = [&"barracks_1"]
const KING := Vector2(8.0, 3.0)
const KILL_DAMAGE: int = 1000
const MAX_STEPS: int = 3000
const DAY_SETTLE_STEPS: int = 300
const SLOT_EPSILON: float = 0.05
## An enemy that is effectively stationary far from every squad, so a test decides when it dies.
const CRAWL_SPEED: float = 0.001

var _ctx: RunContext
var _spawns: Array[Array] = []


func before_each() -> void:
	_spawns = []


func _context(crawling: bool) -> void:
	var shipped: MapConfig = load(FIXTURE)
	var map: MapConfig = shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	if crawling:
		for enemy: EnemyDef in map.enemies:
			enemy.move_speed = CRAWL_SPEED
	_ctx = RunContext.new(map, load(TUNING), 1)
	_ctx.events.unit_spawned.connect(_on_unit_spawned)
	assert_eq(_ctx.commands.submit(BuildIntent.new(BARRACKS)), CommandProcessor.OK, "built")
	_ctx.step()
	_ctx.king.report_position(KING)


func _on_unit_spawned(unit_id: int, _squad: StringName, _def: StringName, pos: Vector2) -> void:
	_spawns.append([unit_id, pos, _ctx.run_manager.get_phase()])


func _order(verb: StringName) -> void:
	assert_eq(
		_ctx.commands.submit(SquadOrderIntent.new(ONLY_BARRACKS, verb)),
		CommandProcessor.OK,
		"ordered"
	)


func _kill_every_enemy() -> void:
	for enemy_id: int in _ctx.night.get_enemies().ids():
		_ctx.night.get_enemies().damage(enemy_id, KILL_DAMAGE, &"test")


func _start_night() -> void:
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	var steps: int = 0
	while _ctx.run_manager.get_phase() != RunManager.RunPhase.NIGHT and steps < MAX_STEPS:
		_ctx.step()
		steps += 1
	assert_eq(_ctx.run_manager.get_phase(), RunManager.RunPhase.NIGHT, "the night began")


func _clear_the_night() -> void:
	var steps: int = 0
	while _ctx.run_manager.get_phase() == RunManager.RunPhase.NIGHT and steps < MAX_STEPS:
		_kill_every_enemy()
		_ctx.step()
		steps += 1


func _into_the_next_day() -> void:
	var steps: int = 0
	while _ctx.run_manager.get_phase() != RunManager.RunPhase.DAY and steps < MAX_STEPS:
		_ctx.step()
		steps += 1
	for _i: int in range(DAY_SETTLE_STEPS):
		_ctx.step()


func _slot_distance(unit_id: int, anchor: Vector2) -> float:
	var units: UnitSystem = _ctx.squads.get_units()
	var spacing: float = _ctx.squads.unit_def_of(BARRACKS).formation_spacing
	var slot: Vector2 = (
		anchor
		+ SquadFormation.slot_offset(
			units.slot_of(unit_id), _ctx.squads.max_count(BARRACKS), spacing
		)
	)
	return units.position_of(unit_id).distance_to(slot)


func test_a_held_squad_keeps_its_stance_and_spot_through_the_night_dawn_and_next_day() -> void:
	_context(false)
	_order(SquadOrder.VERB_HOLD)
	var spot: Vector2 = _ctx.squads.anchor_of(BARRACKS)
	_start_night()
	assert_eq(_ctx.squads.anchor_of(BARRACKS), spot, "begin_night left the spot alone")
	assert_eq(_ctx.squads.resting_stance(BARRACKS), SquadOrder.STANCE_HOLD, "and the stance")
	_clear_the_night()
	assert_eq(_ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "the night was cleared")
	assert_eq(_ctx.squads.anchor_of(BARRACKS), spot, "the dawn restore left the spot alone")
	assert_eq(_ctx.squads.resting_stance(BARRACKS), SquadOrder.STANCE_HOLD, "and the stance")
	_into_the_next_day()
	assert_eq(_ctx.squads.anchor_of(BARRACKS), spot, "the next day still holds the spot")
	assert_eq(_ctx.squads.resting_stance(BARRACKS), SquadOrder.STANCE_HOLD, "and the stance")
	assert_eq(_ctx.squads.alive_count(BARRACKS), 4, "the squad is whole")
	for unit_id: int in _ctx.squads.unit_ids_of(BARRACKS):
		assert_lt(
			_slot_distance(unit_id, spot), SLOT_EPSILON, "unit %d stands at the spot" % unit_id
		)


func test_a_following_squad_still_follows_the_king_the_next_day() -> void:
	_context(false)
	_order(SquadOrder.VERB_FOLLOW)
	_start_night()
	_clear_the_night()
	_ctx.king.report_position(Vector2(-3.0, 9.0))
	_into_the_next_day()
	assert_eq(_ctx.squads.resting_stance(BARRACKS), SquadOrder.STANCE_FOLLOW, "still following")
	assert_eq(_ctx.squads.anchor_of(BARRACKS), Vector2(-3.0, 9.0), "the anchor is the king")
	for unit_id: int in _ctx.squads.unit_ids_of(BARRACKS):
		assert_lt(
			_slot_distance(unit_id, Vector2(-3.0, 9.0)),
			SLOT_EPSILON,
			"unit %d stands round the king" % unit_id
		)


func test_a_night_replacement_appears_at_the_post_and_walks_to_the_following_squad() -> void:
	_context(true)
	var post: Vector2 = _ctx.squads.anchor_of(BARRACKS)
	_order(SquadOrder.VERB_FOLLOW)
	_start_night()
	_ctx.squads.damage_unit(_ctx.squads.unit_ids_of(BARRACKS)[0], KILL_DAMAGE, &"test")
	_spawns = []
	var steps: int = 0
	while _spawns.is_empty() and steps < MAX_STEPS:
		_ctx.step()
		steps += 1
	assert_eq(_spawns.size(), 1, "one replacement arrived during the night")
	assert_eq(_spawns[0][2], RunManager.RunPhase.NIGHT, "while it was night")
	assert_eq(_spawns[0][1], post, "at the building's post, not at the king")
	var unit_id: int = _spawns[0][0]
	var at_spawn: float = _slot_distance(unit_id, KING)
	for _i: int in range(60):
		_ctx.step()
	assert_lt(_slot_distance(unit_id, KING), at_spawn - 5.0, "and walks toward the king")
	assert_eq(_ctx.squads.anchor_of(BARRACKS), KING, "the squad still follows the king")
