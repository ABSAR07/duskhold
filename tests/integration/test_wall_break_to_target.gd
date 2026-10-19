extends GutTest
## ENMY-04, G-04-7 (owner rule change of 2026-10-19), the tracer: a default melee enemy whose
## nearest target is a tower behind an intact wall run takes the segment its centre line crosses,
## strikes it until it breaks, then resumes the tower and damages it. It never drops the tower for
## the castle march. Hand-built world far from the castle: the run at x = 102 (z 80 to 120, tier I),
## the tower at (105, 101), the grunt at (100, 101), the king parked 500 m away.

const GAP_FIXTURE := "res://tests/fixtures/fixture_map_walls_gap.tres"
const GRUNT_PATH := "res://data/enemies/grunt.tres"
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
const RUN: StringName = &"wall_west"
const TOWER: StringName = &"tower_1"
const WALL_X: float = 102.0
const LINE_Z: float = 101.0
const ENEMY_AT := Vector2(100.0, LINE_Z)
const TOWER_AT := Vector2(105.0, LINE_Z)
const KING_AT := Vector2(500.0, 500.0)
const RICH_GOLD: int = 200
const HUGE_HEALTH: int = 100000
const LATE_SPAWN_SECONDS: float = 5000.0
const MAX_STEPS: int = 2400

var _ctx: RunContext
var _broken: Array[int] = []
var _tower_hits: Array[int] = []


func _on_broken(_spot: StringName, segment: int) -> void:
	_broken.append(segment)


func _on_tower_damaged(spot: StringName, _amount: int, _hp: int, _max: int) -> void:
	if spot == TOWER:
		_tower_hits.append(1)


## The gap fixture turned into the diagnosis repro: the run at x = 102, no gap, the tower at
## (105, 101), no scripted spawn within the test.
func _map() -> MapConfig:
	var map: MapConfig = (load(GAP_FIXTURE) as MapConfig).duplicate_deep(
		Resource.DEEP_DUPLICATE_ALL
	)
	map.starting_gold = RICH_GOLD
	for spot: BuildSpotDef in map.spots:
		if spot.id == RUN:
			spot.position = Vector3(WALL_X - 3.0, 0.0, LINE_Z)
			spot.wall_run.points = PackedVector2Array(
				[Vector2(WALL_X, 80.0), Vector2(WALL_X, 120.0)]
			)
			spot.wall_run.gaps = PackedVector2Array()
		elif spot.id == TOWER:
			spot.position = Vector3(TOWER_AT.x, 0.0, TOWER_AT.y)
	for night: NightDef in map.nights:
		for group: SpawnGroupDef in night.groups:
			group.start_delay_seconds = LATE_SPAWN_SECONDS
	return map


## Night 1 with the tower built and, when `wall_up`, the run bought at tier I; one grunt of
## 100000 hit points standing at ENEMY_AT. Returns its id.
func _night(wall_up: bool) -> int:
	_ctx = RunContext.new(_map(), load(TUNING_PATH), 1)
	_ctx.king.report_position(KING_AT)
	assert_eq(_ctx.commands.submit(BuildIntent.new(TOWER)), CommandProcessor.OK, "the tower")
	if wall_up:
		assert_eq(_ctx.commands.submit(BuildIntent.new(RUN)), CommandProcessor.OK, "the wall")
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night 1")
	_ctx.events.wall_segment_broken.connect(_on_broken)
	_ctx.events.building_damaged.connect(_on_tower_damaged)
	var def: EnemyDef = (load(GRUNT_PATH) as EnemyDef).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	def.max_health = HUGE_HEALTH
	return _ctx.night.get_enemies().spawn(def, ENEMY_AT)


func test_a_grunt_breaks_the_wall_in_front_of_a_tower_then_damages_the_tower() -> void:
	var id: int = _night(true)
	var enemies: EnemySystem = _ctx.night.get_enemies()
	var blocking: int = _ctx.night.get_pathing().first_blocking(ENEMY_AT, TOWER_AT, 0.0)
	assert_gte(blocking, 0, "the centre line to the tower crosses the run")
	_ctx.step()
	assert_eq(
		enemies.target_of(id),
		{"kind": PendingHits.KIND_WALL, "id": blocking},
		"on its first step it takes the segment in the way, not the castle"
	)
	var tower_index: int = _ctx.buildings.spot_index(TOWER)
	var resumed: bool = false
	for _step: int in range(MAX_STEPS):
		var was_broken: bool = not _broken.is_empty()
		_ctx.step()
		var target: Dictionary = enemies.target_of(id)
		assert_ne(target.get("kind", &""), PendingHits.KIND_CASTLE, "never the castle")
		assert_false(target.is_empty(), "never without a target")
		if was_broken and not resumed:
			resumed = true
			assert_eq(
				target,
				{"kind": PendingHits.KIND_BUILDING, "id": tower_index},
				"the step after the break it has its tower back"
			)
		if not _tower_hits.is_empty():
			break
	assert_eq(_broken, [blocking] as Array[int], "it broke exactly the segment in its way")
	assert_true(resumed, "it resumed the tower after the break")
	assert_false(_tower_hits.is_empty(), "and damaged the tower")


func test_with_the_run_unbuilt_the_grunt_targets_the_tower_at_once() -> void:
	var id: int = _night(false)
	_ctx.step()
	var enemies: EnemySystem = _ctx.night.get_enemies()
	assert_eq(
		enemies.target_of(id),
		{"kind": PendingHits.KIND_BUILDING, "id": _ctx.buildings.spot_index(TOWER)},
		"the Phase 3 choice"
	)
