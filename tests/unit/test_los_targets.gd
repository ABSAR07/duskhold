extends GutTest
## ENMY-04, RESEARCH Open Question 3 (decided): while a wall stands, a melee enemy chooses or keeps
## a king, unit, building or castle target only while its straight line is clear, a ranged enemy
## also while the target is within its attack range; a melee unit takes an enemy only with a clear
## line, an archer regardless (its arrows arc over). With no wall every choice is the Phase 3 one.
## Hand-built worlds far from the castle; the long wall at x = 102 stands between x = 100 and 104.

const GRUNT_PATH := "res://data/enemies/grunt.tres"
const RANGED_PATH := "res://data/enemies/ranged.tres"
const FOOTMAN_PATH := "res://data/units/footman.tres"
const WALL_PATH := "res://data/buildings/wall.tres"
const KING_PATH := "res://data/king/king.tres"
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
const SQUADS_FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const PLOT: StringName = &"plot"
const ENEMY_AT := Vector2(100.0, 100.0)
const BEHIND := Vector2(104.0, 100.0)
const OPEN_SIDE := Vector2(96.0, 100.0)
const WALL_X: float = 102.0
const RESCAN_WINDOW: int = 40
const SQUAD_WALL_X: float = -8.0
const RICH_GOLD: int = 200
## No scripted enemy spawns within a test; the test places its own.
const LATE_SPAWN_SECONDS: float = 5000.0

var _grunt: EnemyDef
var _ranged: EnemyDef
var _unit_def: UnitDef
var _map: MapConfig
var _events: SimEvents
var _castle: CastleState
var _king: KingState
var _units: UnitSystem
var _enemies: EnemySystem
var _hits: PendingHits
var _walls: WallSystem
var _pathing: Pathing


func before_each() -> void:
	_grunt = load(GRUNT_PATH)
	_ranged = load(RANGED_PATH)
	_unit_def = load(FOOTMAN_PATH)
	_events = SimEvents.new()


## Builds the world; `wall_up` buys the run at x = 102 (z 80 to 120) at tier I.
func _world(wall_up: bool) -> void:
	var run: WallRunDef = WallRunDef.new()
	run.points = PackedVector2Array([Vector2(WALL_X, 80.0), Vector2(WALL_X, 120.0)])
	run.half_thickness = 0.4
	var spot: BuildSpotDef = BuildSpotDef.new()
	spot.id = PLOT
	spot.position = Vector3(WALL_X - 3.0, 0.0, 100.0)
	spot.building_id = &"wall"
	spot.wall_run = run
	_map = MapConfig.new()
	_map.buildings = [load(WALL_PATH)] as Array[BuildingDef]
	_map.spots = [spot] as Array[BuildSpotDef]
	_castle = CastleState.new(_map, _events)
	var buildings: BuildingSystem = BuildingSystem.new(_map, _events)
	_walls = WallSystem.new(_map, buildings, _events)
	if wall_up:
		buildings.apply_next_tier(PLOT)
	_pathing = Pathing.new(_map, _walls)
	_pathing.refresh()
	_king = KingState.new(load(KING_PATH), Vector2(500.0, 500.0), _events, load(TUNING_PATH))
	_king.report_position(Vector2(500.0, 500.0))
	_units = UnitSystem.new(_events)
	_enemies = EnemySystem.new(_events)
	_hits = PendingHits.new()


func _step(tick: int) -> void:
	_enemies.step(tick, _castle, _king, _hits, null, _units, _pathing)


func _target_kind(id: int) -> Variant:
	return _enemies.target_of(id).get("kind")


func test_a_melee_enemy_does_not_target_a_king_behind_the_wall_and_marches_on() -> void:
	_world(true)
	_king.report_position(BEHIND)
	var id: int = _enemies.spawn(_grunt, ENEMY_AT)
	_step(0)
	assert_ne(_target_kind(id), PendingHits.KIND_KING, "the king is 4 m away but behind the wall")
	assert_ne(_target_kind(id), PendingHits.KIND_WALL, "and it does not attack the wall either")
	assert_lt(_enemies.position_of(id).x, ENEMY_AT.x, "it marches on toward the castle")


func test_the_same_king_on_the_open_side_is_targeted() -> void:
	_world(true)
	_king.report_position(OPEN_SIDE)
	var id: int = _enemies.spawn(_grunt, ENEMY_AT)
	_step(0)
	assert_eq(_target_kind(id), PendingHits.KIND_KING, "a clear line, a king in aggro range")


func test_a_held_target_that_walks_behind_the_wall_is_dropped_on_a_rescan() -> void:
	_world(true)
	_king.report_position(OPEN_SIDE)
	var id: int = _enemies.spawn(_grunt, ENEMY_AT)
	_step(0)
	assert_eq(_target_kind(id), PendingHits.KIND_KING, "first he is in sight")
	_king.report_position(Vector2(WALL_X + 2.0, 100.0 - 3.0))
	var dropped: bool = false
	for tick: int in range(1, RESCAN_WINDOW):
		_step(tick)
		if _target_kind(id) != PendingHits.KIND_KING:
			dropped = true
			break
	assert_true(dropped, "the enemy let go of a king it can no longer see")


func test_a_ranged_enemy_keeps_shooting_a_unit_behind_the_wall_within_its_range() -> void:
	_world(true)
	var unit: int = _units.spawn(_unit_def, &"barracks_1", 0, BEHIND)
	var id: int = _enemies.spawn(_ranged, ENEMY_AT)
	_step(0)
	assert_eq(_enemies.target_of(id), {"kind": PendingHits.KIND_UNIT, "id": unit}, "shoots over it")


func test_a_ranged_enemy_does_not_shoot_what_is_behind_the_wall_and_out_of_range() -> void:
	_world(true)
	var far: Vector2 = Vector2(WALL_X + 6.0, 100.0)
	var id: int = _enemies.spawn(_ranged, ENEMY_AT)
	_units.spawn(_unit_def, &"barracks_1", 0, far)
	_step(0)
	assert_ne(_target_kind(id), PendingHits.KIND_UNIT, "8 m of edge is beyond its 7 m of range")


func test_a_nearer_unit_behind_the_wall_loses_to_a_farther_one_in_sight() -> void:
	_world(true)
	_units.spawn(_unit_def, &"barracks_1", 0, BEHIND)
	var visible: int = _units.spawn(_unit_def, &"barracks_1", 1, Vector2(94.5, 100.0))
	var id: int = _enemies.spawn(_grunt, ENEMY_AT)
	_step(0)
	assert_eq(_enemies.target_of(id), {"kind": PendingHits.KIND_UNIT, "id": visible}, "in sight")


func test_with_no_wall_the_choice_is_the_phase_3_choice() -> void:
	_world(false)
	_king.report_position(BEHIND)
	var id: int = _enemies.spawn(_grunt, ENEMY_AT)
	_step(0)
	assert_eq(_target_kind(id), PendingHits.KIND_KING, "no wall, no sight line to keep")
	var other: int = _enemies.spawn(_grunt, Vector2(100.0, 110.0))
	_units.spawn(_unit_def, &"barracks_1", 0, Vector2(104.0, 110.0))
	_step(1)
	assert_eq(_target_kind(other), PendingHits.KIND_UNIT, "a unit across where the wall would be")


func test_nearest_enemy_clear_skips_an_enemy_behind_the_wall() -> void:
	_world(true)
	var behind: int = _enemies.spawn(_grunt, BEHIND)
	var open: int = _enemies.spawn(_grunt, OPEN_SIDE)
	assert_eq(
		TargetQuery.nearest_enemy(_enemies, ENEMY_AT, 10.0), behind, "ties go to the lower id"
	)
	assert_eq(
		TargetQuery.nearest_enemy_clear(_enemies, ENEMY_AT, 10.0, _pathing, 0.45),
		open,
		"the clear one is chosen"
	)


func test_nearest_enemy_clear_breaks_ties_between_clear_enemies_to_the_lower_id() -> void:
	_world(true)
	_enemies.spawn(_grunt, BEHIND)
	var first: int = _enemies.spawn(_grunt, OPEN_SIDE)
	_enemies.spawn(_grunt, Vector2(100.0, 104.0))
	_enemies.spawn(_grunt, Vector2(100.0, 96.0))
	assert_eq(
		TargetQuery.nearest_enemy_clear(_enemies, ENEMY_AT, 10.0, _pathing, 0.45),
		first,
		"four metres each, the lower id"
	)


func test_nearest_enemy_clear_equals_nearest_enemy_when_no_wall_stands() -> void:
	_world(false)
	_enemies.spawn(_grunt, BEHIND)
	_enemies.spawn(_grunt, OPEN_SIDE)
	assert_eq(
		TargetQuery.nearest_enemy_clear(_enemies, ENEMY_AT, 10.0, _pathing, 0.45),
		TargetQuery.nearest_enemy(_enemies, ENEMY_AT, 10.0),
		"the same answer"
	)
	assert_eq(
		TargetQuery.nearest_enemy_clear(_enemies, ENEMY_AT, 10.0, null, 0.45),
		TargetQuery.nearest_enemy(_enemies, ENEMY_AT, 10.0),
		"and with no pathing at all"
	)
	assert_eq(
		TargetQuery.nearest_enemy_clear(_enemies, ENEMY_AT, 1.0, _pathing, 0.45),
		-1,
		"none in reach"
	)


func test_a_footman_ignores_an_enemy_behind_the_wall_while_an_archer_shoots_it() -> void:
	var map: MapConfig = (load(SQUADS_FIXTURE) as MapConfig).duplicate_deep(
		Resource.DEEP_DUPLICATE_ALL
	)
	for night: NightDef in map.nights:
		for group: SpawnGroupDef in night.groups:
			group.start_delay_seconds = LATE_SPAWN_SECONDS
	map.buildings.append(load(WALL_PATH))
	var run: WallRunDef = WallRunDef.new()
	run.points = PackedVector2Array([Vector2(SQUAD_WALL_X, -14.0), Vector2(SQUAD_WALL_X, 14.0)])
	run.half_thickness = 0.4
	var spot: BuildSpotDef = BuildSpotDef.new()
	spot.id = PLOT
	spot.position = Vector3(SQUAD_WALL_X, 0.0, 16.0)
	spot.building_id = &"wall"
	spot.wall_run = run
	map.spots.append(spot)
	map.starting_gold = RICH_GOLD
	var ctx: RunContext = RunContext.new(map, load(TUNING_PATH), 1)
	assert_eq(ctx.commands.submit(BuildIntent.new(&"barracks_1")), CommandProcessor.OK, "barracks")
	assert_eq(ctx.commands.submit(BuildIntent.new(&"archery_1")), CommandProcessor.OK, "archery")
	assert_eq(ctx.commands.submit(BuildIntent.new(PLOT)), CommandProcessor.OK, "wall")
	for _step_day: int in range(60):
		ctx.step()
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night")
	var enemies: EnemySystem = ctx.night.get_enemies()
	var victim: int = enemies.spawn(load(GRUNT_PATH), Vector2(-6.0, 0.0))
	var units: UnitSystem = ctx.squads.get_units()
	var footman_engaged: bool = false
	var archer_engaged: bool = false
	for _tick: int in range(40):
		ctx.step()
		if not enemies.is_alive(victim):
			break
		for id: int in units.ids():
			var kind: StringName = units.def_of(id).id
			if units.target_of(id) == victim:
				footman_engaged = footman_engaged or kind == &"footman"
				archer_engaged = archer_engaged or kind == &"archer"
	assert_false(footman_engaged, "no footman takes an enemy it cannot walk straight to")
	assert_true(archer_engaged, "an archer shoots it over the wall")
