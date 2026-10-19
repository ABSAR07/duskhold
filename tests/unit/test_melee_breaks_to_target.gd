extends GutTest
## ENMY-04, G-04-7 (owner rule change of 2026-10-19, UAT test 13): a default melee enemy whose
## king, unit or building target stands behind an intact wall breaks the segment its centre line
## crosses and resumes the target. The three sub-rules the plan settled are pinned here, one test
## each: (a) a target in sight still wins, (b) a body that only grazes a gap's edge walks through
## the gap, (c) the castle is never a target behind a wall. The release rules and the crowd count
## (D-08) follow. Hand-built worlds far from the castle; the wall at x = 102 (z 80 to 120) stands
## between x = 101.6 and 102.4, and every line runs at z = 101 so it crosses a segment's middle.

const GRUNT_PATH := "res://data/enemies/grunt.tres"
const FOOTMAN_PATH := "res://data/units/footman.tres"
const WALL_PATH := "res://data/buildings/wall.tres"
const KING_PATH := "res://data/king/king.tres"
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
const GAP_FIXTURE := "res://tests/fixtures/fixture_map_walls_gap.tres"
const RING_FIXTURE := "res://tests/fixtures/fixture_map_walls.tres"
const PLOT: StringName = &"plot"
const RING: StringName = &"wall_ring"
const RUN: StringName = &"wall_west"
const TOWER: StringName = &"tower_1"
const LINE_Z: float = 101.0
const ENEMY_AT := Vector2(100.0, LINE_Z)
const BEHIND := Vector2(104.0, LINE_Z)
const OPEN_SIDE := Vector2(96.0, LINE_Z)
const FAR := Vector2(500.0, 500.0)
const WALL_X: float = 102.0
const RESCAN_WINDOW: int = 40
const RICH_GOLD: int = 200
const HUGE_HEALTH: int = 100000
const LATE_SPAWN_SECONDS: float = 5000.0
const MOUTH_Z: float = 100.6
const CROWD: int = 12
const LONE_TTD: int = 450

var _grunt: EnemyDef
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
var _ctx: RunContext
var _broken: Array[int] = []
var _wall_hits: Array[int] = []
var _tower_hits: Array[int] = []
var _tower_down: bool = false


func before_each() -> void:
	_grunt = load(GRUNT_PATH)
	_unit_def = load(FOOTMAN_PATH)
	_events = SimEvents.new()
	_broken.clear()
	_wall_hits.clear()
	_tower_hits.clear()
	_tower_down = false


## The x = 102 world of test_los_targets: the run (z 80 to 120) at tier I, the castle at the
## origin, the king parked far away. `castle_at` moves the castle for the castle case.
func _world(castle_at: Vector3 = Vector3.ZERO) -> void:
	var run: WallRunDef = WallRunDef.new()
	run.points = PackedVector2Array([Vector2(WALL_X, 80.0), Vector2(WALL_X, 120.0)])
	run.half_thickness = 0.4
	var spot: BuildSpotDef = BuildSpotDef.new()
	spot.id = PLOT
	spot.position = Vector3(WALL_X - 3.0, 0.0, LINE_Z)
	spot.building_id = &"wall"
	spot.wall_run = run
	_map = MapConfig.new()
	_map.castle_position = castle_at
	_map.buildings = [load(WALL_PATH)] as Array[BuildingDef]
	_map.spots = [spot] as Array[BuildSpotDef]
	_build(PLOT)


func _build(plot: StringName) -> void:
	_castle = CastleState.new(_map, _events)
	var buildings: BuildingSystem = BuildingSystem.new(_map, _events)
	_walls = WallSystem.new(_map, buildings, _events)
	buildings.apply_next_tier(plot)
	_pathing = Pathing.new(_map, _walls)
	_pathing.refresh()
	_king = KingState.new(load(KING_PATH), FAR, _events, load(TUNING_PATH))
	_king.report_position(FAR)
	_units = UnitSystem.new(_events)
	_enemies = EnemySystem.new(_events)
	_hits = PendingHits.new()


func _step(tick: int) -> void:
	_enemies.step(tick, _castle, _king, _hits, null, _units, _pathing)


func _target_kind(id: int) -> Variant:
	return _enemies.target_of(id).get("kind")


## What the segment held by enemy `id` stands in front of: its behind_kind, empty when none.
func _behind(id: int) -> StringName:
	return EnemySystem.KIND_NAMES[_enemies._native.behind_kind_of(id)]


func _segment(from: Vector2, to: Vector2) -> int:
	return _pathing.first_blocking(from, to, 0.0)


func _wall_target(segment: int) -> Dictionary:
	return {"kind": PendingHits.KIND_WALL, "id": segment}


func _on_broken(_spot: StringName, segment: int) -> void:
	_broken.append(segment)


func _on_wall_damaged(_spot: StringName, segment: int, _amt: int, _hp: int, _max: int) -> void:
	_wall_hits.append(segment)


func _on_building_damaged(spot: StringName, _amount: int, _hp: int, _max: int) -> void:
	if spot == TOWER:
		_tower_hits.append(1)


func _on_building_destroyed(spot: StringName, _building: StringName, _tier: int) -> void:
	_tower_down = _tower_down or spot == TOWER


## The gap fixture turned into a hand-built night: the run at x = 102 (z 80 to 120) with `gaps`
## along its path, the tower at (105, `line_z`), no scripted spawn. The tower and the run are
## bought, night 1 runs, and the king stands 500 m away.
func _night(gaps: PackedVector2Array, line_z: float) -> void:
	var map: MapConfig = (load(GAP_FIXTURE) as MapConfig).duplicate_deep(
		Resource.DEEP_DUPLICATE_ALL
	)
	map.starting_gold = RICH_GOLD
	for spot: BuildSpotDef in map.spots:
		if spot.id == RUN:
			spot.position = Vector3(WALL_X - 3.0, 0.0, line_z)
			spot.wall_run.points = PackedVector2Array(
				[Vector2(WALL_X, 80.0), Vector2(WALL_X, 120.0)]
			)
			spot.wall_run.gaps = gaps
		elif spot.id == TOWER:
			spot.position = Vector3(WALL_X + 3.0, 0.0, line_z)
	for night: NightDef in map.nights:
		for group: SpawnGroupDef in night.groups:
			group.start_delay_seconds = LATE_SPAWN_SECONDS
	_ctx = RunContext.new(map, load(TUNING_PATH), 1)
	_ctx.king.report_position(FAR)
	assert_eq(_ctx.commands.submit(BuildIntent.new(TOWER)), CommandProcessor.OK, "the tower")
	assert_eq(_ctx.commands.submit(BuildIntent.new(RUN)), CommandProcessor.OK, "the wall")
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night 1")
	_ctx.events.wall_segment_broken.connect(_on_broken)
	_ctx.events.wall_damaged.connect(_on_wall_damaged)
	_ctx.events.building_damaged.connect(_on_building_damaged)
	_ctx.events.building_destroyed.connect(_on_building_destroyed)


func _huge_grunt() -> EnemyDef:
	var def: EnemyDef = _grunt.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	def.max_health = HUGE_HEALTH
	return def


## 1. The king pulls a default grunt through his own wall.
func test_a_king_behind_the_wall_pulls_the_grunt_to_the_segment_and_then_to_him() -> void:
	_world()
	_king.report_position(BEHIND)
	var id: int = _enemies.spawn(_grunt, ENEMY_AT)
	var segment: int = _segment(ENEMY_AT, BEHIND)
	assert_gte(segment, 0, "his centre line crosses the run")
	_step(0)
	assert_eq(_enemies.target_of(id), _wall_target(segment), "it takes the segment in the way")
	assert_eq(_behind(id), PendingHits.KIND_KING, "and remembers the king behind it")
	_walls.damage_segment(segment, 1000)
	_step(1)
	assert_eq(_enemies.target_of(id), {"kind": PendingHits.KIND_KING, "id": 0}, "he is back")
	assert_eq(_behind(id), &"", "the memory is spent")


## 2. A held king who walks behind the wall is held for, never dropped.
func test_a_held_king_who_walks_behind_the_wall_is_never_dropped() -> void:
	_world()
	_king.report_position(OPEN_SIDE)
	var id: int = _enemies.spawn(_grunt, ENEMY_AT)
	_step(0)
	assert_eq(_target_kind(id), PendingHits.KIND_KING, "first he is in sight")
	_king.report_position(Vector2(WALL_X + 2.0, LINE_Z - 3.0))
	var held: bool = false
	for tick: int in range(1, RESCAN_WINDOW):
		_step(tick)
		var kind: Variant = _target_kind(id)
		assert_true(
			kind == PendingHits.KIND_KING or kind == PendingHits.KIND_WALL,
			"tick %d: the king or a wall held for him, never empty" % tick
		)
		held = held or (kind == PendingHits.KIND_WALL and _behind(id) == PendingHits.KIND_KING)
	assert_true(held, "once he was behind the wall the segment was held for him")


## 3. With only a unit behind the wall inside aggro range the grunt takes the segment.
func test_a_unit_behind_the_wall_is_reached_through_the_segment_in_front() -> void:
	_world()
	_units.spawn(_unit_def, &"barracks_1", 0, BEHIND)
	var id: int = _enemies.spawn(_grunt, ENEMY_AT)
	_step(0)
	assert_eq(_enemies.target_of(id), _wall_target(_segment(ENEMY_AT, BEHIND)), "the segment")
	assert_eq(_behind(id), PendingHits.KIND_UNIT, "held for the unit")


## 4. Sub-rule (a): a target in sight still wins over a nearer one behind the wall.
func test_a_nearer_unit_behind_the_wall_loses_to_a_farther_one_in_sight() -> void:
	_world()
	_units.spawn(_unit_def, &"barracks_1", 0, BEHIND)
	var visible: int = _units.spawn(_unit_def, &"barracks_1", 1, Vector2(94.5, LINE_Z))
	var id: int = _enemies.spawn(_grunt, ENEMY_AT)
	_step(0)
	assert_eq(_enemies.target_of(id), {"kind": PendingHits.KIND_UNIT, "id": visible}, "in sight")
	assert_eq(_behind(id), &"", "no segment is held")


## 5. Sub-rule (b): the gap mouth. A body line that grazes the gap-edge segment is clear.
func test_a_grunt_in_a_gap_mouth_walks_through_and_damages_no_segment() -> void:
	var mouth := Vector2(WALL_X - 2.0, MOUTH_Z)
	var tower_at := Vector2(WALL_X + 3.0, MOUTH_Z)
	_night(PackedVector2Array([Vector2(20.0, 24.0)]), MOUTH_Z)
	var pathing: Pathing = _ctx.night.get_pathing()
	assert_gte(pathing.first_blocking(mouth, tower_at, 0.5), 0, "the 0.5 m body line grazes")
	assert_eq(pathing.first_blocking(mouth, tower_at, 0.0), -1, "the centre line clears the edge")
	var enemies: EnemySystem = _ctx.night.get_enemies()
	var id: int = enemies.spawn(_huge_grunt(), mouth)
	for _step_count: int in range(300):
		_ctx.step()
		assert_ne(enemies.target_of(id).get("kind"), PendingHits.KIND_WALL, "never a wall")
	assert_eq(_wall_hits, [] as Array[int], "no wall_damaged for any segment")
	assert_gt(enemies.position_of(id).x, WALL_X, "it walked through the gap")
	assert_false(_tower_hits.is_empty(), "and reached the tower")


## 6. Sub-rule (c): the castle is never a target behind a wall; the castle march keeps D-07.
func test_the_castle_behind_a_wall_is_never_a_target_and_is_still_broken_into() -> void:
	_map = (load(RING_FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	for spot: BuildSpotDef in _map.spots:
		if spot.id == RING:
			spot.wall_run.points = PackedVector2Array(
				[
					Vector2(-6.0, -6.0),
					Vector2(6.0, -6.0),
					Vector2(6.0, 6.0),
					Vector2(-6.0, 6.0),
					Vector2(-6.0, -6.0)
				]
			)
	_build(RING)
	var outside := Vector2(-9.0, 0.0)
	assert_lte(outside.distance_to(_castle.get_position()) - _castle.get_radius(), 6.0, "aggro")
	var id: int = _enemies.spawn(_grunt, outside)
	var broke_in: bool = false
	for tick: int in range(120):
		_step(tick)
		assert_ne(_target_kind(id), PendingHits.KIND_CASTLE, "the castle is not chosen")
		assert_eq(_behind(id), &"", "no segment is held for it")
		broke_in = broke_in or _target_kind(id) == PendingHits.KIND_WALL
	assert_true(broke_in, "the sealed ring is still attacked by the D-07 castle rule")


## 7. Release on death: the unit it breaks toward dies and the segment is let go.
func test_the_segment_is_let_go_when_the_unit_behind_it_dies() -> void:
	_world()
	var unit: int = _units.spawn(_unit_def, &"barracks_1", 0, BEHIND)
	var id: int = _enemies.spawn(_grunt, ENEMY_AT)
	_step(0)
	assert_eq(_behind(id), PendingHits.KIND_UNIT, "held for the unit")
	_units.damage(unit, HUGE_HEALTH, PendingHits.KIND_ENEMY)
	_step(1)
	assert_eq(_behind(id), &"", "no memory of a dead unit")
	assert_ne(_target_kind(id), PendingHits.KIND_WALL, "and no segment held for it")


## 8. Release on the leash: the king walks out of reach of the held segment.
func test_the_segment_is_let_go_when_the_king_leaves_the_leash() -> void:
	_world()
	_king.report_position(BEHIND)
	var id: int = _enemies.spawn(_grunt, ENEMY_AT)
	_step(0)
	assert_eq(_behind(id), PendingHits.KIND_KING, "held for the king")
	_king.report_position(Vector2(ENEMY_AT.x + _grunt.leash_range + 2.0, LINE_Z))
	_step(1)
	assert_eq(_behind(id), &"", "he is out of the leash")
	assert_ne(_target_kind(id), PendingHits.KIND_WALL, "so the segment is let go")


## 9. Release when the line clears: on a rescan the target comes back.
func test_the_segment_is_let_go_on_a_rescan_when_the_line_to_the_king_clears() -> void:
	_world()
	_king.report_position(BEHIND)
	var id: int = _enemies.spawn(_grunt, ENEMY_AT)
	_step(0)
	assert_eq(_behind(id), PendingHits.KIND_KING, "held for the king")
	_king.report_position(OPEN_SIDE)
	var rescan: int = 0
	var period: int = maxi(SimClock.ticks(_grunt.retarget_interval_seconds), 1)
	while not EnemySystem.is_rescan_tick(rescan, id, period):
		rescan += 1
	for tick: int in range(1, rescan):
		_step(tick)
		assert_eq(_behind(id), PendingHits.KIND_KING, "tick %d: held until a rescan" % tick)
	_step(rescan)
	assert_eq(_enemies.target_of(id), {"kind": PendingHits.KIND_KING, "id": 0}, "he is the target")
	assert_eq(_behind(id), &"", "and nothing is held")


## 10. No give-up flip: a crowd holds its weak segments for the tower, with no castle detour. A
## jostled grunt may move to the segment its line now crosses; it is never left without a wall
## while the tower stands (a fallen tower releases every grunt held for it).
func test_a_crowd_keeps_a_wall_in_front_of_the_tower_until_the_segment_breaks() -> void:
	_night(PackedVector2Array(), LINE_Z)
	var enemies: EnemySystem = _ctx.night.get_enemies()
	var ids: Array[int] = []
	for index: int in range(CROWD):
		var at := Vector2(99.0 + float(index % 3) * 0.4, LINE_Z - 1.4 + float(index / 3) * 0.7)
		ids.append(enemies.spawn(_huge_grunt(), at))
	_ctx.step()
	var held: Dictionary = {}
	for id: int in ids:
		assert_eq(enemies.target_of(id).get("kind"), PendingHits.KIND_WALL, "enemy %d" % id)
		held[id] = enemies.target_of(id).get("id")
	var shortest: int = LONE_TTD
	var decision: WallDecision = _ctx.night.get_pathing().decision()
	for _step_count: int in range(600):
		var already_broken: Array[int] = _broken.duplicate()
		_ctx.step()
		if _tower_down:
			break
		for id: int in ids:
			var target: Dictionary = enemies.target_of(id)
			if not already_broken.has(held[id]):
				assert_eq(target.get("kind"), PendingHits.KIND_WALL, "enemy %d holds on" % id)
			if target.get("kind") == PendingHits.KIND_WALL:
				held[id] = target.get("id")
				shortest = mini(shortest, decision.ttd_of(held[id]))
	assert_gt(_broken.size(), 0, "the crowd broke through")
	assert_lt(shortest, LONE_TTD, "the holders counted into the segment's crowd (D-08)")
