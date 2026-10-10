extends GutTest
## UNIT-04: a Barracks squad on a hand-built field (BuildingSystem, SquadSystem, EnemySystem and
## PendingHits, no RunContext). The squad is raised by day around its post in front of the building,
## guards at night, takes the nearest enemy within guard_range of the anchor on its staggered
## rescan tick, commits to it until it dies or leaves the leash, and walks back to its slot.
## The plot sits on the x axis so the post lands on exact floats: with the castle at the origin the
## anchor is (-7, 0) and an enemy at (0, 0) is exactly guard_range (7 m) away.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const GRUNT_PATH := "res://data/enemies/grunt.tres"
const SPOT := &"barracks_1"
const PLOT := Vector3(-10.5, 0.0, 0.0)
const ANCHOR := Vector2(-7.0, 0.0)
## A castle this far west keeps a marching enemy walking away from the squad.
const FAR_CASTLE := Vector3(-60.0, 0.0, 0.0)
const FAR_PLOT := Vector3(-3.5, 0.0, 0.0)
const SLOT_EPSILON: float = 0.05

var _grunt: EnemyDef
var _map: MapConfig
var _events: SimEvents
var _buildings: BuildingSystem
var _castle: CastleState
var _squads: SquadSystem
var _enemies: EnemySystem
var _hits: PendingHits
var _tick: int = 0
var _fired: Array[Array] = []


func before_each() -> void:
	_grunt = load(GRUNT_PATH)
	_start_world(PLOT, Vector3.ZERO)


## A fresh world on a private deep copy of the fixture, with the barracks plot and the castle moved.
func _start_world(plot: Vector3, castle: Vector3) -> void:
	var shipped: MapConfig = load(FIXTURE)
	_map = shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	_map.castle_position = castle
	for spot: BuildSpotDef in _map.spots:
		if spot.id == SPOT:
			spot.position = plot
	_events = SimEvents.new()
	_buildings = BuildingSystem.new(_map, _events)
	_castle = CastleState.new(_map, _events)
	_squads = SquadSystem.new(_map, _buildings, _events)
	_enemies = EnemySystem.new(_events)
	_hits = PendingHits.new()
	_tick = 0
	_fired = []
	_events.attack_fired.connect(_on_attack_fired)


func _on_attack_fired(
	_attacker_kind: StringName,
	attacker_id: int,
	_target_kind: StringName,
	_target_id: int,
	flight_ticks: int
) -> void:
	_fired.append([_tick, attacker_id, flight_ticks])


func _footman() -> UnitDef:
	return _map.find_unit(&"footman")


func _build_barracks() -> void:
	_buildings.apply_next_tier(SPOT)


## One squad step; only the squads move (enemies stand still unless a test steps them too).
func _step(night: bool) -> void:
	_squads.step(_tick, _enemies, _hits, night)
	_tick += 1


func _rescan_ticks() -> int:
	return maxi(SimClock.ticks(_footman().retarget_interval_seconds), 1)


func _units() -> UnitSystem:
	return _squads.get_units()


func _targeting(enemy_id: int) -> bool:
	for unit_id: int in _squads.unit_ids_of(SPOT):
		if _units().target_of(unit_id) == enemy_id:
			return true
	return false


func test_nothing_is_raised_before_the_building_stands() -> void:
	_step(false)
	assert_eq(_squads.squad_ids().size(), 0, "no squad without a building")
	assert_eq(_units().count(), 0, "no unit either")


func test_a_built_barracks_raises_its_tier_squad_at_the_formation_slots() -> void:
	_build_barracks()
	watch_signals(_events)
	_step(false)
	var tier_one: BuildingTierDef = _map.buildings[2].tier_def(1)
	assert_eq(_squads.squad_ids(), [SPOT] as Array[StringName], "one squad for the plot")
	assert_eq(_squads.max_count(SPOT), tier_one.squad_size, "seats follow the tier")
	assert_eq(_squads.alive_count(SPOT), 4, "four footmen at tier 1 (D-01)")
	assert_signal_emit_count(_events, "unit_spawned", 4, "each footman announced once")
	var slots: Dictionary = {}
	for unit_id: int in _squads.unit_ids_of(SPOT):
		var slot: int = _units().slot_of(unit_id)
		slots[slot] = true
		var expected: Vector2 = (
			ANCHOR + SquadFormation.slot_offset(slot, 4, _footman().formation_spacing)
		)
		assert_eq(_units().position_of(unit_id), expected, "unit %d stands at its slot" % unit_id)
	assert_eq(slots.size(), 4, "four different slots")


func test_the_post_is_in_front_of_the_building_toward_the_castle() -> void:
	_build_barracks()
	_step(false)
	assert_eq(_squads.anchor_of(SPOT), ANCHOR, "plot moved post_distance toward the castle")
	assert_eq(_squads.unit_def_of(SPOT).id, &"footman", "the barracks fields footmen")


func test_a_squad_never_exceeds_the_guard_constant() -> void:
	for tier: BuildingTierDef in _map.buildings[2].tiers:
		tier.squad_size = 500
	_build_barracks()
	_step(false)
	assert_eq(_squads.max_count(SPOT), SquadSystem.MAX_UNITS_PER_SQUAD, "seats are capped")
	assert_eq(_squads.alive_count(SPOT), SquadSystem.MAX_UNITS_PER_SQUAD, "so are the units")


func test_a_new_night_fills_a_squad_built_in_the_same_step() -> void:
	_build_barracks()
	_squads.begin_night()
	assert_eq(_squads.alive_count(SPOT), 4, "the seats are filled when the night begins")
	for unit_id: int in _squads.unit_ids_of(SPOT):
		assert_eq(_units().target_of(unit_id), -1, "no target at the start of a night")
		assert_eq(_units().cooldown_ready_of(unit_id), 0, "ready to strike")


func test_an_enemy_exactly_guard_range_from_the_anchor_is_engaged() -> void:
	_build_barracks()
	_step(false)
	var enemy_id: int = _enemies.spawn(_grunt, ANCHOR + Vector2(_footman().guard_range, 0.0))
	for _i: int in range(_rescan_ticks()):
		_step(true)
	assert_true(_targeting(enemy_id), "guard range is inclusive")


func test_an_enemy_just_beyond_guard_range_is_ignored() -> void:
	_build_barracks()
	_step(false)
	var enemy_id: int = _enemies.spawn(_grunt, ANCHOR + Vector2(_footman().guard_range + 0.01, 0.0))
	for _i: int in range(_rescan_ticks() * 3):
		_step(true)
	assert_false(_targeting(enemy_id), "0.01 m beyond guard range is not engaged")
	assert_eq(_fired.size(), 0, "and nothing was fired")


func test_equally_near_enemies_go_to_the_lower_id() -> void:
	_build_barracks()
	_step(false)
	var grunt: EnemyDef = _grunt
	var first: int = _enemies.spawn(grunt, ANCHOR + Vector2(0.0, 2.0))
	var second: int = _enemies.spawn(grunt, ANCHOR + Vector2(0.0, -2.0))
	for _i: int in range(_rescan_ticks()):
		_step(true)
	assert_true(_targeting(first), "the lower id is taken")
	assert_false(_targeting(second), "the other one is not")


func test_a_committed_unit_keeps_its_target_when_a_nearer_enemy_appears() -> void:
	_build_barracks()
	_step(false)
	var grunt: EnemyDef = _grunt
	var far_one: int = _enemies.spawn(grunt, ANCHOR + Vector2(5.0, 0.0))
	var unit_id: int = _squads.unit_ids_of(SPOT)[0]
	var guard: int = 0
	while _units().target_of(unit_id) != far_one and guard < _rescan_ticks() * 2:
		_step(true)
		guard += 1
	assert_eq(_units().target_of(unit_id), far_one, "committed to the first enemy")
	_enemies.spawn(grunt, ANCHOR + Vector2(1.0, 1.0))
	for _i: int in range(_rescan_ticks() * 4):
		_step(true)
	assert_eq(_units().target_of(unit_id), far_one, "never swaps to a nearer enemy")


func test_a_target_beyond_the_leash_is_dropped_and_the_unit_walks_back() -> void:
	_start_world(FAR_PLOT, FAR_CASTLE)
	_build_barracks()
	_step(false)
	assert_eq(_squads.anchor_of(SPOT), ANCHOR, "the post is on the same exact spot")
	var enemy_id: int = _enemies.spawn(_grunt, ANCHOR + Vector2(6, 0))
	var engaged: bool = false
	var released: bool = false
	for _i: int in range(900):
		_step(true)
		_enemies.step(_tick, _castle, null, _hits)
		if _targeting(enemy_id):
			engaged = true
		elif engaged:
			released = true
			break
	assert_true(engaged, "the squad engaged the marching enemy")
	assert_true(released, "and let go once it left the leash")
	var leash: float = _footman().leash_range
	assert_gt(ANCHOR.distance_to(_enemies.position_of(enemy_id)), leash, "it was past the leash")
	for _i: int in range(240):
		_step(true)
		_enemies.step(_tick, _castle, null, _hits)
	for unit_id: int in _squads.unit_ids_of(SPOT):
		var slot_at: Vector2 = (
			ANCHOR
			+ SquadFormation.slot_offset(_units().slot_of(unit_id), 4, _footman().formation_spacing)
		)
		assert_lt(_units().position_of(unit_id).distance_to(slot_at), SLOT_EPSILON, "back at slot")


func test_a_footman_strikes_once_per_attack_interval_and_the_hit_lands_that_tick() -> void:
	_build_barracks()
	_step(false)
	_enemies.spawn(_grunt, ANCHOR + Vector2(3.0, 0.0))
	var interval: int = SimClock.ticks(_footman().attack_interval)
	var due_per_tick: Dictionary = {}
	for _i: int in range(150):
		_step(true)
		for hit: PendingHits.Hit in _hits.take_due(_tick - 1):
			assert_eq(hit.target_kind, PendingHits.KIND_ENEMY, "a unit hit names an enemy")
			assert_eq(hit.attacker_kind, PendingHits.KIND_UNIT, "from a unit")
			due_per_tick[_tick - 1] = int(due_per_tick.get(_tick - 1, 0)) + 1
	var by_unit: Dictionary = {}
	for entry: Array in _fired:
		assert_eq(entry[2], 0, "a melee strike has no flight")
		var ticks: Array = by_unit.get(entry[1], [])
		ticks.append(entry[0])
		by_unit[entry[1]] = ticks
	assert_gt(by_unit.size(), 0, "somebody struck")
	for unit_id: int in by_unit:
		var ticks: Array = by_unit[unit_id]
		assert_gt(ticks.size(), 2, "unit %d struck repeatedly" % unit_id)
		for index: int in range(1, ticks.size()):
			assert_eq(ticks[index] - ticks[index - 1], interval, "one strike per interval")
	var fired_per_tick: Dictionary = {}
	for entry: Array in _fired:
		fired_per_tick[entry[0]] = int(fired_per_tick.get(entry[0], 0)) + 1
	assert_eq(due_per_tick, fired_per_tick, "every strike arrives on the tick it was fired")


func test_no_cooldown_is_consumed_while_there_is_no_target() -> void:
	_build_barracks()
	for _i: int in range(60):
		_step(true)
	for unit_id: int in _squads.unit_ids_of(SPOT):
		assert_eq(_units().cooldown_ready_of(unit_id), 0, "an idle unit is always ready")
	assert_eq(_fired.size(), 0, "no strikes without an enemy")


func test_by_day_units_ignore_enemies_and_stay_at_their_slots() -> void:
	_build_barracks()
	_step(false)
	var enemy_id: int = _enemies.spawn(_grunt, ANCHOR)
	for _i: int in range(_rescan_ticks() * 2):
		_step(false)
	assert_false(_targeting(enemy_id), "no engagement outside the night")
	assert_eq(_fired.size(), 0, "no strikes by day")


func test_slot_offsets_form_an_axis_aligned_grid_around_the_anchor() -> void:
	var spacing: float = 1.2
	assert_eq(SquadFormation.slot_offset(0, 1, spacing), Vector2.ZERO, "a lone unit stands on it")
	assert_eq(SquadFormation.slot_offset(0, 0, spacing), Vector2.ZERO, "cap 0 behaves like 1")
	assert_eq(SquadFormation.slot_offset(0, 4, spacing), Vector2(-0.6, -0.6), "2x2 corner")
	assert_eq(SquadFormation.slot_offset(3, 4, spacing), Vector2(0.6, 0.6), "2x2 opposite corner")
	var sum: Vector2 = Vector2.ZERO
	for slot: int in range(16):
		sum += SquadFormation.slot_offset(slot, 16, spacing)
	assert_almost_eq(sum.length(), 0.0, 0.0001, "a full 4x4 grid is centred on the anchor")
