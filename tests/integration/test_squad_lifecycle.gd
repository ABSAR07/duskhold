extends GutTest
## UNIT-07 across the whole loop on a RunContext: a squad that lost units at night is whole again at
## dawn (numbers and health) without its anchor moving, squad_restored comes before the dawn payout,
## the units cost no gold, an emptied squad whose building fell is rebuilt and restored, and the
## squad stands at its post the next day. A replacement that comes due on the very last step of a
## night still spawns before the night ends.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const BARRACKS: StringName = &"barracks_1"
const ARCHERY: StringName = &"archery_1"
const KILL_DAMAGE: int = 1000
const MAX_NIGHT_STEPS: int = 3000
const DAY_SETTLE_STEPS: int = 300
const SLOT_EPSILON: float = 0.05
## An enemy that is effectively stationary far from every squad, so a test decides when it dies.
const CRAWL_SPEED: float = 0.001

var _tuning: LoopTuning
var _ctx: RunContext
var _sequence: Array[String] = []
var _payouts: Array[int] = []
var _held_enemy_kill: bool = false
var _stood_at_restore: bool = false


func before_each() -> void:
	_tuning = load(TUNING)
	_sequence = []
	_payouts = []
	_held_enemy_kill = false
	_stood_at_restore = false


func _context(crawling: bool = false) -> RunContext:
	var shipped: MapConfig = load(FIXTURE)
	var map: MapConfig = shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	if crawling:
		for enemy: EnemyDef in map.enemies:
			enemy.move_speed = CRAWL_SPEED
	_ctx = RunContext.new(map, _tuning, 1)
	_ctx.events.unit_spawned.connect(_on_unit_spawned)
	_ctx.events.squad_restored.connect(_on_squad_restored)
	_ctx.events.dawn_payout.connect(_on_dawn_payout)
	_ctx.events.buildings_rebuilt.connect(_on_buildings_rebuilt)
	return _ctx


func _on_unit_spawned(_id: int, _squad: StringName, _def: StringName, _pos: Vector2) -> void:
	var phase: int = _ctx.run_manager.get_phase()
	_sequence.append("spawn@%d" % phase)
	if _held_enemy_kill and phase == RunManager.RunPhase.NIGHT:
		_kill_every_enemy()


func _on_squad_restored(squad_id: StringName, alive: int) -> void:
	_sequence.append("restored:%s:%d" % [squad_id, alive])
	_stood_at_restore = not _ctx.buildings.is_destroyed(BARRACKS)


func _on_dawn_payout(total: int, _per_spot: Dictionary) -> void:
	_payouts.append(total)
	_sequence.append("payout")


func _on_buildings_rebuilt(_spots: Array) -> void:
	_sequence.append("rebuilt")


func _kill_every_enemy() -> void:
	for enemy_id: int in _ctx.night.get_enemies().ids():
		_ctx.night.get_enemies().damage(enemy_id, KILL_DAMAGE, &"test")


func _build_and_start_night() -> void:
	assert_eq(
		_ctx.commands.submit(BuildIntent.new(BARRACKS)), CommandProcessor.OK, "barracks built"
	)
	_ctx.step()
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")


func _kill_unit(unit_id: int) -> void:
	_ctx.squads.damage_unit(unit_id, KILL_DAMAGE, &"test")


## Steps, killing every enemy as it appears, until the run leaves the night.
func _clear_the_night() -> void:
	var steps: int = 0
	while _ctx.run_manager.get_phase() == RunManager.RunPhase.NIGHT and steps < MAX_NIGHT_STEPS:
		_kill_every_enemy()
		_ctx.step()
		steps += 1


func _index_of(prefix: String) -> int:
	for index: int in range(_sequence.size()):
		if _sequence[index].begins_with(prefix):
			return index
	return -1


func _count_of(prefix: String) -> int:
	var total: int = 0
	for entry: String in _sequence:
		if entry.begins_with(prefix):
			total += 1
	return total


func test_dawn_makes_every_squad_whole_without_moving_it_or_charging_gold() -> void:
	_context()
	_build_and_start_night()
	for _i: int in range(10):
		_ctx.step()
	var ids: Array[int] = _ctx.squads.unit_ids_of(BARRACKS)
	_kill_unit(ids[0])
	_kill_unit(ids[1])
	_ctx.squads.damage_unit(ids[2], 4, &"test")
	_ctx.step()
	var anchor: Vector2 = _ctx.squads.anchor_of(BARRACKS)
	var gold_before: int = _ctx.economy.get_gold()
	_sequence = []
	_clear_the_night()
	assert_eq(_ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "the night was cleared")
	for squad_id: StringName in _ctx.squads.squad_ids():
		assert_eq(
			_ctx.squads.alive_count(squad_id),
			_ctx.squads.max_count(squad_id),
			"%s is full" % squad_id
		)
		for unit_id: int in _ctx.squads.unit_ids_of(squad_id):
			var def: UnitDef = _ctx.squads.get_units().def_of(unit_id)
			assert_eq(_ctx.squads.get_units().health_of(unit_id), def.max_health, "unit is whole")
	assert_eq(_ctx.squads.anchor_of(BARRACKS), anchor, "the anchor did not move")
	var restored: int = _index_of("restored:")
	assert_ne(restored, -1, "squad_restored fired")
	assert_eq(_count_of("restored:"), 1, "once for the one squad")
	assert_lt(restored, _sequence.find("payout"), "the restore comes before the dawn payout")
	assert_eq(_ctx.economy.get_gold(), gold_before + _payouts[0], "no gold went on units")


func test_during_the_next_day_every_unit_stands_at_its_slot() -> void:
	_context()
	_build_and_start_night()
	for _i: int in range(20):
		_ctx.step()
	_kill_unit(_ctx.squads.unit_ids_of(BARRACKS)[0])
	_clear_the_night()
	var steps: int = 0
	while _ctx.run_manager.get_phase() != RunManager.RunPhase.DAY and steps < MAX_NIGHT_STEPS:
		_ctx.step()
		steps += 1
	for _i: int in range(DAY_SETTLE_STEPS):
		_ctx.step()
	assert_eq(_ctx.squads.alive_count(BARRACKS), 4, "the squad is full by day")
	var units: UnitSystem = _ctx.squads.get_units()
	var spacing: float = _ctx.squads.unit_def_of(BARRACKS).formation_spacing
	var cap: int = _ctx.squads.max_count(BARRACKS)
	for unit_id: int in _ctx.squads.unit_ids_of(BARRACKS):
		var slot: Vector2 = (
			_ctx.squads.anchor_of(BARRACKS)
			+ SquadFormation.slot_offset(units.slot_of(unit_id), cap, spacing)
		)
		assert_lt(units.position_of(unit_id).distance_to(slot), SLOT_EPSILON, "unit is at its slot")


func test_an_emptied_squad_whose_building_fell_is_rebuilt_and_restored_at_dawn() -> void:
	_context()
	_build_and_start_night()
	_ctx.step()
	for unit_id: int in _ctx.squads.unit_ids_of(BARRACKS):
		_kill_unit(unit_id)
	_ctx.buildings.damage_building(BARRACKS, KILL_DAMAGE)
	_ctx.step()
	assert_eq(_ctx.squads.alive_count(BARRACKS), 0, "nobody is left while the building is rubble")
	assert_eq(_ctx.squads.squad_ids(), [BARRACKS] as Array[StringName], "the squad keeps its id")
	_clear_the_night()
	assert_false(_ctx.buildings.is_destroyed(BARRACKS), "dawn rebuilt the barracks")
	assert_eq(_ctx.squads.alive_count(BARRACKS), 4, "and the squad is full again")
	assert_true(_stood_at_restore, "the building was back up when the squad was restored")


func test_a_replacement_due_on_the_last_step_of_the_night_spawns_before_dawn() -> void:
	_context(true)
	_build_and_start_night()
	var ids: Array[int] = _ctx.squads.unit_ids_of(BARRACKS)
	_kill_unit(ids[0])
	_kill_unit(ids[1])
	_held_enemy_kill = true
	_sequence = []
	var steps: int = 0
	while _ctx.run_manager.get_phase() == RunManager.RunPhase.NIGHT and steps < MAX_NIGHT_STEPS:
		_ctx.step()
		steps += 1
	assert_eq(_ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "the night ended")
	assert_eq(steps, SimClock.ticks(10.0), "on the step the first replacement came due")
	var trickle: int = _sequence.find("spawn@%d" % RunManager.RunPhase.NIGHT)
	var dawn_spawn: int = _sequence.find("spawn@%d" % RunManager.RunPhase.DAWN)
	assert_ne(trickle, -1, "the replacement spawned while it was still night")
	assert_gt(dawn_spawn, trickle, "and dawn then raised the one still missing")
	assert_eq(_ctx.squads.alive_count(BARRACKS), 4, "the squad is full")
	assert_lt(dawn_spawn, _index_of("restored:"), "squad_restored closes the restore")
