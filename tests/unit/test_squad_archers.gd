extends GutTest
## D-06 and D-07: the Archery Range squad on a hand-built field (BuildingSystem, SquadSystem,
## EnemySystem and PendingHits, no RunContext). Archers walk until the enemy centre is within
## attack_range, then stop and fire arrows that land SimClock.flight_ticks(distance, speed) ticks
## later through PendingHits; a skirmisher can target and wound an archer. The plot sits on the x
## axis so the post lands on exact floats: with the castle at the origin the anchor is (-7, 0).

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const GRUNT_PATH := "res://data/enemies/grunt.tres"
const SKIRMISHER_PATH := "res://data/enemies/ranged.tres"
const KING_PATH := "res://data/king/king.tres"
const FOOTMAN_PATH := "res://data/units/footman.tres"
const ARCHER_PATH := "res://data/units/archer.tres"
const SPOT := &"archery_1"
const PLOT := Vector3(-10.5, 0.0, 0.0)
const ANCHOR := Vector2(-7.0, 0.0)
## Hit points of a test dummy: high enough that nothing dies unless a test says so.
const DUMMY_HEALTH: int = 500
const STOP_EPSILON: float = 0.02
## The tick of the first night step the helper runs (the day step that raises the squad is tick 0).
const FIRST_STEP_TICK: int = 1

var _map: MapConfig
var _archer: UnitDef
var _dummy: EnemyDef
var _events: SimEvents
var _buildings: BuildingSystem
var _castle: CastleState
var _squads: SquadSystem
var _enemies: EnemySystem
var _hits: PendingHits
var _tick: int = 0
var _fired: Array[Array] = []
var _hp_log: Dictionary = {}


## Builds a fresh world on a private deep copy of the fixture with the archery plot moved. False
## (after a failed assertion) when the fixture does not carry the Archery Range yet.
func _ready_world() -> bool:
	var shipped: MapConfig = load(FIXTURE)
	_map = shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	_archer = _map.find_unit(&"archer")
	var spot: BuildSpotDef = null
	for candidate: BuildSpotDef in _map.spots:
		if candidate.id == SPOT:
			spot = candidate
	assert_not_null(_archer, "the squad fixture lists the archer unit")
	assert_not_null(spot, "the squad fixture has the archery_1 plot")
	if _archer == null or spot == null:
		return false
	spot.position = PLOT
	var grunt: EnemyDef = load(GRUNT_PATH)
	_dummy = grunt.duplicate()
	_dummy.max_health = DUMMY_HEALTH
	_events = SimEvents.new()
	_buildings = BuildingSystem.new(_map, _events)
	_castle = CastleState.new(_map, _events)
	_squads = SquadSystem.new(_map, _buildings, _events)
	_enemies = EnemySystem.new(_events)
	_hits = PendingHits.new()
	_tick = 0
	_fired = []
	_hp_log = {}
	_events.attack_fired.connect(_on_attack_fired)
	_buildings.apply_next_tier(SPOT)
	_squads.step(_tick, _enemies, _hits, false)
	_tick += 1
	return true


func _on_attack_fired(
	_attacker_kind: StringName,
	attacker_id: int,
	_target_kind: StringName,
	target_id: int,
	flight_ticks: int
) -> void:
	var here: Vector2 = _squads.get_units().position_of(attacker_id)
	var distance: float = here.distance_to(_enemies.position_of(target_id))
	_fired.append([_tick, attacker_id, flight_ticks, distance, target_id])


## One night step of the army and the hits against enemies; enemies themselves stand still.
func _step() -> void:
	_squads.step(_tick, _enemies, _hits, true)
	for hit: PendingHits.Hit in _hits.take_due(_tick):
		if hit.target_kind == PendingHits.KIND_ENEMY:
			_enemies.damage(hit.target_id, hit.amount, hit.attacker_kind)
	for id: int in _enemies.ids():
		var series: Array = _hp_log.get(id, [])
		series.append(_enemies.health_of(id))
		_hp_log[id] = series
	_tick += 1


func _hp_at(series: Array, tick: int) -> int:
	return int(series[tick - FIRST_STEP_TICK])


func _units() -> UnitSystem:
	return _squads.get_units()


func test_the_barracks_and_range_squads_have_the_owner_decided_strengths() -> void:
	var king: KingDef = load(KING_PATH)
	var footman: UnitDef = load(FOOTMAN_PATH)
	var grunt: EnemyDef = load(GRUNT_PATH)
	assert_true(ResourceLoader.exists(ARCHER_PATH), "archer.tres ships")
	if not ResourceLoader.exists(ARCHER_PATH):
		return
	var archer: UnitDef = load(ARCHER_PATH)
	assert_eq(footman.max_health * 5, king.max_health, "a footman has a fifth of the king hp")
	assert_eq(footman.attack_damage * 5, king.attack_damage, "and a fifth of his damage")
	assert_gt(footman.max_health, archer.max_health, "the footman is sturdier than the archer")
	assert_gt(archer.attack_range, grunt.attack_range, "the archer outreaches the grunt")
	assert_gt(archer.projectile_speed, 0.0, "the archer shoots arrows")
	assert_eq(footman.projectile_speed, 0.0, "the footman is melee")


func test_an_archer_stops_once_the_enemy_centre_is_within_attack_range() -> void:
	if not _ready_world():
		return
	_enemies.spawn(_dummy, ANCHOR + Vector2(_archer.guard_range - 0.5, 0.0))
	for _i: int in range(240):
		_step()
	var ids: Array[int] = _squads.unit_ids_of(SPOT)
	assert_eq(ids.size(), 4, "four archers at tier 1")
	var farthest: float = 0.0
	for unit_id: int in ids:
		var distance: float = _units().position_of(unit_id).distance_to(_enemies.position_of(1))
		assert_lte(distance, _archer.attack_range + STOP_EPSILON, "archer %d is in range" % unit_id)
		farthest = maxf(farthest, distance)
	assert_almost_eq(
		farthest, _archer.attack_range, STOP_EPSILON, "the rearmost archer stopped at attack range"
	)


func test_an_arrow_lands_exactly_flight_ticks_after_it_was_fired() -> void:
	if not _ready_world():
		return
	var enemy_id: int = _enemies.spawn(_dummy, ANCHOR + Vector2(_archer.guard_range - 0.5, 0.0))
	for _i: int in range(240):
		_step()
	assert_gt(_fired.size(), 0, "the archers fired")
	if _fired.is_empty():
		return
	var shot: Array = _fired[0]
	var flight: int = SimClock.flight_ticks(shot[3], _archer.projectile_speed)
	assert_eq(shot[2], flight, "attack_fired carries the deterministic flight time")
	assert_gt(flight, 0, "an arrow takes time to fly")
	var series: Array = _hp_log[enemy_id]
	var arrival: int = int(shot[0]) + flight
	var fired_tick: int = int(shot[0])
	assert_eq(_hp_at(series, arrival - 1), DUMMY_HEALTH, "no damage the tick before arrival")
	assert_lt(
		_hp_at(series, arrival), DUMMY_HEALTH, "the enemy loses hp on exactly the arrival tick"
	)
	assert_eq(_hp_at(series, fired_tick), DUMMY_HEALTH, "and not on the tick the arrow left")


func test_an_arrow_whose_target_died_before_arrival_drops_silently() -> void:
	if not _ready_world():
		return
	var enemy_id: int = _enemies.spawn(_dummy, ANCHOR + Vector2(_archer.guard_range - 0.5, 0.0))
	var guard: int = 0
	while _fired.is_empty() and guard < 400:
		_step()
		guard += 1
	assert_false(_fired.is_empty(), "an arrow is in the air")
	_enemies.damage(enemy_id, DUMMY_HEALTH, PendingHits.KIND_BUILDING)
	_enemies.remove_dead()
	assert_gt(_hits.size(), 0, "the arrow is still in flight")
	watch_signals(_events)
	for _i: int in range(60):
		_step()
	assert_signal_not_emitted(_events, "enemy_damaged", "a gone target takes no more hits")
	assert_eq(_enemies.count(), 0, "and nothing came back to life")


func test_archers_fire_no_more_often_than_the_attack_interval() -> void:
	if not _ready_world():
		return
	_enemies.spawn(_dummy, ANCHOR + Vector2(_archer.guard_range - 0.5, 0.0))
	for _i: int in range(240):
		_step()
	var interval: int = SimClock.ticks(_archer.attack_interval)
	var last_by_unit: Dictionary = {}
	for shot: Array in _fired:
		var unit_id: int = shot[1]
		if last_by_unit.has(unit_id):
			assert_gte(int(shot[0]) - int(last_by_unit[unit_id]), interval, "interval respected")
		last_by_unit[unit_id] = shot[0]
	assert_gt(_fired.size(), 4, "there were several volleys")


func test_a_skirmisher_can_target_and_wound_an_archer() -> void:
	if not _ready_world():
		return
	var skirmisher: EnemyDef = (load(SKIRMISHER_PATH) as EnemyDef).duplicate()
	skirmisher.max_health = DUMMY_HEALTH
	var enemy_id: int = _enemies.spawn(skirmisher, ANCHOR + Vector2(-12.0, 0.0))
	watch_signals(_events)
	var targeted: bool = false
	for _i: int in range(600):
		_squads.step(_tick, _enemies, _hits, true)
		_enemies.step(_tick, _castle, null, _hits, null, _units())
		for hit: PendingHits.Hit in _hits.take_due(_tick):
			if hit.target_kind == PendingHits.KIND_ENEMY:
				_enemies.damage(hit.target_id, hit.amount, hit.attacker_kind)
			elif hit.target_kind == PendingHits.KIND_UNIT:
				_squads.damage_unit(hit.target_id, hit.amount, hit.attacker_kind)
		if _enemies.target_of(enemy_id).get("kind", &"") == PendingHits.KIND_UNIT:
			targeted = true
		_tick += 1
		if targeted and get_signal_emit_count(_events, "unit_damaged") > 0:
			break
	assert_true(targeted, "the skirmisher chose an archer as its target")
	assert_gt(get_signal_emit_count(_events, "unit_damaged"), 0, "and its arrow wounded one")
