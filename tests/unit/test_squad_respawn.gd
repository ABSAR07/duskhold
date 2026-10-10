extends GutTest
## UNIT-07 on a hand-built field (BuildingSystem, SquadSystem, EnemySystem and PendingHits, no
## RunContext): a squad below its cap whose building stands gets one replacement per tier interval
## during the night, spawned at the post and walking to its slot; a squad at its cap runs no
## countdown; a fallen building freezes the countdown; the dawn restore brings every squad back to
## full numbers and health without moving its anchor. Every pace is read from the data files.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const BARRACKS: StringName = &"barracks_1"
const ARCHERY: StringName = &"archery_1"
const KILL_DAMAGE: int = 1000
const MAX_STEPS: int = 2000

var _map: MapConfig
var _events: SimEvents
var _buildings: BuildingSystem
var _squads: SquadSystem
var _enemies: EnemySystem
var _hits: PendingHits
var _tick: int = 0
var _spawns: Array[Array] = []
var _restored: Array[Array] = []


func before_each() -> void:
	var shipped: MapConfig = load(FIXTURE)
	_map = shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	_events = SimEvents.new()
	_buildings = BuildingSystem.new(_map, _events)
	_squads = SquadSystem.new(_map, _buildings, _events)
	_enemies = EnemySystem.new(_events)
	_hits = PendingHits.new()
	_tick = 0
	_spawns = []
	_restored = []
	_events.unit_spawned.connect(_on_unit_spawned)
	_events.squad_restored.connect(_on_squad_restored)


func _on_unit_spawned(
	unit_id: int, squad_id: StringName, _def_id: StringName, pos: Vector2
) -> void:
	_spawns.append([unit_id, squad_id, pos, _tick])


func _on_squad_restored(squad_id: StringName, alive: int) -> void:
	_restored.append([squad_id, alive])


func _units() -> UnitSystem:
	return _squads.get_units()


func _step(night: bool) -> void:
	_squads.step(_tick, _enemies, _hits, night)
	_squads.remove_dead()
	_tick += 1


## Builds the spot up to `tier` and lets the day fill every seat.
func _stand_at_tier(spot: StringName, tier: int) -> void:
	for _i: int in range(tier):
		_buildings.apply_next_tier(spot)
	_step(false)


func _kill(unit_id: int) -> void:
	_squads.damage_unit(unit_id, KILL_DAMAGE, &"test")
	_squads.remove_dead()


func _respawn_ticks(spot: StringName, tier: int) -> int:
	var building: BuildingDef = _buildings.get_building_def_for_spot(spot)
	return SimClock.ticks(building.tier_def(tier).squad_respawn_seconds)


## Night steps until the squad is back to `alive` units; the number of steps taken.
func _steps_until_alive(spot: StringName, alive: int) -> int:
	var steps: int = 0
	while _squads.alive_count(spot) < alive and steps < MAX_STEPS:
		_step(true)
		steps += 1
	return steps


func test_a_tier_one_squad_gets_a_replacement_every_ten_seconds_of_night() -> void:
	_stand_at_tier(BARRACKS, 1)
	var ids: Array[int] = _squads.unit_ids_of(BARRACKS)
	_kill(ids[0])
	_kill(ids[1])
	var interval: int = SimClock.ticks(10.0)
	assert_eq(_respawn_ticks(BARRACKS, 1), interval, "the data says 10 s at tier 1")
	assert_eq(_steps_until_alive(BARRACKS, 3), interval, "the first comes after one interval")
	assert_eq(_steps_until_alive(BARRACKS, 4), interval, "the second after another")
	assert_eq(_squads.alive_count(BARRACKS), 4, "the squad is whole again")


func test_a_tier_two_squad_uses_its_own_faster_pace() -> void:
	_stand_at_tier(BARRACKS, 2)
	_kill(_squads.unit_ids_of(BARRACKS)[0])
	assert_eq(_steps_until_alive(BARRACKS, 8), SimClock.ticks(7.0), "7 s at tier 2")


func test_a_tier_three_squad_uses_the_fastest_pace() -> void:
	_stand_at_tier(BARRACKS, 3)
	_kill(_squads.unit_ids_of(BARRACKS)[0])
	assert_eq(_steps_until_alive(BARRACKS, 14), SimClock.ticks(4.0), "4 s at tier 3")


func test_a_squad_at_its_cap_runs_no_countdown() -> void:
	_stand_at_tier(BARRACKS, 1)
	for _i: int in range(30):
		_step(true)
	assert_eq(_squads.replacement_progress(BARRACKS), 0.0, "no progress at the cap")
	assert_eq(_squads.alive_count(BARRACKS), 4, "and nothing was added")
	assert_eq(_spawns.size(), 4, "only the day fill ever spawned")
	assert_eq(_squads.replacement_progress(&"no_such_squad"), 0.0, "an unknown squad reads 0")


func test_the_progress_rises_toward_one_between_replacements() -> void:
	_stand_at_tier(BARRACKS, 1)
	_kill(_squads.unit_ids_of(BARRACKS)[0])
	var interval: int = _respawn_ticks(BARRACKS, 1)
	var last: float = 0.0
	for index: int in range(interval - 1):
		_step(true)
		var progress: float = _squads.replacement_progress(BARRACKS)
		assert_gt(progress, last, "step %d moves the bar forward" % index)
		assert_lt(progress, 1.0, "and it stays under 1 until the unit arrives")
		last = progress
	_step(true)
	assert_eq(_squads.alive_count(BARRACKS), 4, "the interval ends with the replacement")
	assert_eq(_squads.replacement_progress(BARRACKS), 0.0, "and the bar rests at the cap")


func test_a_replacement_appears_at_the_post_in_the_lowest_free_slot() -> void:
	_stand_at_tier(BARRACKS, 1)
	var ids: Array[int] = _squads.unit_ids_of(BARRACKS)
	var freed_slot: int = _units().slot_of(ids[2])
	_kill(ids[2])
	_spawns = []
	_steps_until_alive(BARRACKS, 4)
	assert_eq(_spawns.size(), 1, "one replacement")
	var arrived: int = _spawns[0][0]
	assert_eq(_units().slot_of(arrived), freed_slot, "it takes the slot that was freed")
	var home: Vector2 = _squads.anchor_of(BARRACKS)
	assert_eq(_spawns[0][2], home, "it is raised at the post, not at its slot")


func test_a_fallen_building_freezes_the_countdown_and_spawns_nothing() -> void:
	_stand_at_tier(BARRACKS, 1)
	_kill(_squads.unit_ids_of(BARRACKS)[0])
	var interval: int = _respawn_ticks(BARRACKS, 1)
	for _i: int in range(5):
		_step(true)
	var frozen: float = _squads.replacement_progress(BARRACKS)
	_buildings.damage_building(BARRACKS, 1000)
	assert_true(_buildings.is_destroyed(BARRACKS), "the barracks fell")
	for _i: int in range(interval * 2):
		_step(true)
	assert_eq(_squads.alive_count(BARRACKS), 3, "nothing came out of rubble")
	assert_eq(_squads.replacement_progress(BARRACKS), frozen, "the countdown did not advance")
	_buildings.rebuild_destroyed()
	assert_eq(_steps_until_alive(BARRACKS, 4), interval - 5, "it resumes where it stopped")


func test_replacements_due_on_the_same_step_follow_the_creation_order() -> void:
	_stand_at_tier(ARCHERY, 1)
	_stand_at_tier(BARRACKS, 1)
	assert_eq(_squads.squad_ids(), [ARCHERY, BARRACKS] as Array[StringName], "archery came first")
	_kill(_squads.unit_ids_of(BARRACKS)[0])
	_kill(_squads.unit_ids_of(ARCHERY)[0])
	_spawns = []
	for _i: int in range(_respawn_ticks(BARRACKS, 1)):
		_step(true)
	assert_eq(_spawns.size(), 2, "both squads got one unit back")
	assert_eq(_spawns[0][1], ARCHERY, "the older squad first")
	assert_eq(_spawns[1][1], BARRACKS, "then the newer one")
	assert_eq(_spawns[0][3], _spawns[1][3], "on the same step")
	assert_lt(_spawns[0][0], _spawns[1][0], "so the ids ascend")


func test_by_day_an_upgrade_fills_the_new_seats_in_the_same_step() -> void:
	_stand_at_tier(BARRACKS, 1)
	_buildings.apply_next_tier(BARRACKS)
	_step(false)
	assert_eq(_squads.alive_count(BARRACKS), 8, "the four new seats are filled at once")


func test_a_squad_that_reaches_its_cap_clears_the_countdown() -> void:
	_stand_at_tier(BARRACKS, 1)
	_kill(_squads.unit_ids_of(BARRACKS)[0])
	for _i: int in range(5):
		_step(true)
	assert_gt(_squads.replacement_progress(BARRACKS), 0.0, "a countdown runs")
	_step(false)
	assert_eq(_squads.alive_count(BARRACKS), 4, "the day fill closes the gap")
	_step(true)
	assert_eq(_squads.replacement_progress(BARRACKS), 0.0, "and the night clears the countdown")
	_kill(_squads.unit_ids_of(BARRACKS)[0])
	assert_eq(
		_steps_until_alive(BARRACKS, 4),
		_respawn_ticks(BARRACKS, 1),
		"the next death is a full interval"
	)


func test_a_squad_at_zero_trickles_back_while_its_building_stands() -> void:
	_stand_at_tier(BARRACKS, 1)
	for unit_id: int in _squads.unit_ids_of(BARRACKS):
		_kill(unit_id)
	assert_eq(_squads.alive_count(BARRACKS), 0, "nobody left")
	assert_eq(_squads.squad_ids(), [BARRACKS] as Array[StringName], "the squad keeps its id")
	assert_eq(_steps_until_alive(BARRACKS, 1), _respawn_ticks(BARRACKS, 1), "one comes back")


func test_the_dawn_restore_brings_back_numbers_and_health_without_moving_the_anchor() -> void:
	_stand_at_tier(BARRACKS, 2)
	var ids: Array[int] = _squads.unit_ids_of(BARRACKS)
	var anchor: Vector2 = _squads.anchor_of(BARRACKS)
	var def: UnitDef = _squads.unit_def_of(BARRACKS)
	_kill(ids[1])
	_kill(ids[5])
	_squads.damage_unit(ids[0], 3, &"test")
	_spawns = []
	_squads.restore_for_dawn()
	assert_eq(_squads.alive_count(BARRACKS), 8, "back to the tier cap")
	for unit_id: int in _squads.unit_ids_of(BARRACKS):
		assert_eq(_units().health_of(unit_id), def.max_health, "unit %d is whole" % unit_id)
	assert_eq(_squads.anchor_of(BARRACKS), anchor, "dawn never moves the anchor")
	assert_eq(_spawns.size(), 2, "two units were raised")
	assert_eq(_units().slot_of(_spawns[0][0]), 1, "the lowest free slot first")
	assert_eq(_units().slot_of(_spawns[1][0]), 5, "then the next one")
	var expected: Vector2 = anchor + SquadFormation.slot_offset(1, 8, def.formation_spacing)
	assert_eq(_spawns[0][2], expected, "at its formation slot around the anchor")
	assert_eq(_restored, [[BARRACKS, 8]], "squad_restored fired once with the new count")


func test_the_dawn_restore_clears_a_running_countdown() -> void:
	_stand_at_tier(BARRACKS, 1)
	_kill(_squads.unit_ids_of(BARRACKS)[0])
	for _i: int in range(4):
		_step(true)
	_squads.restore_for_dawn()
	assert_eq(_squads.replacement_progress(BARRACKS), 0.0, "no countdown after dawn")


func test_the_dawn_restore_visits_every_squad_in_creation_order() -> void:
	_stand_at_tier(ARCHERY, 1)
	_stand_at_tier(BARRACKS, 1)
	_kill(_squads.unit_ids_of(BARRACKS)[0])
	_squads.restore_for_dawn()
	assert_eq(_restored, [[ARCHERY, 4], [BARRACKS, 4]], "once per squad, oldest first")
