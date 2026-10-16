extends GutTest
## D-04: an intact segment is solid to everyone on the ground. A squad ordered across a wall is held
## in front of it, the bot king is held in front of it, and an enemy whose def passes over walls
## (Phase 6 flyers) walks straight across and never attacks one.

const SQUADS_FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const WALLS_FIXTURE := "res://tests/fixtures/fixture_map_walls.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const WALL_PATH := "res://data/buildings/wall.tres"
const GRUNT_PATH := "res://data/enemies/grunt.tres"
const BARRACKS: StringName = &"barracks_1"
const LINE: StringName = &"wall_line"
const RING: StringName = &"wall_ring"
const WALL_X: float = -3.0
const HALF: float = 0.4
const RICH_GOLD: int = 100
const SETTLE_STEPS: int = 60
const MARCH_STEPS: int = 300
const EPSILON: float = 0.001

var _tuning: LoopTuning


func before_each() -> void:
	_tuning = load(TUNING)


## A straight run along x = WALL_X, long enough that no unit walks round its ends.
func _line_plot() -> BuildSpotDef:
	var run: WallRunDef = WallRunDef.new()
	run.points = PackedVector2Array([Vector2(WALL_X, -14.0), Vector2(WALL_X, 14.0)])
	run.half_thickness = HALF
	var spot: BuildSpotDef = BuildSpotDef.new()
	spot.id = LINE
	spot.position = Vector3(WALL_X, 0.0, 16.0)
	spot.building_id = &"wall"
	spot.wall_run = run
	return spot


func _squad_context() -> RunContext:
	var map: MapConfig = (load(SQUADS_FIXTURE) as MapConfig).duplicate_deep(
		Resource.DEEP_DUPLICATE_ALL
	)
	map.buildings.append(load(WALL_PATH))
	map.spots.append(_line_plot())
	map.starting_gold = RICH_GOLD
	return RunContext.new(map, _tuning, 1)


func _clearance(walls: WallSystem, pos: Vector2) -> float:
	var least: float = INF
	for segment: int in range(walls.segment_count()):
		if walls.is_intact(segment):
			var nearest: Vector2 = WallSolids.closest_point(walls, segment, pos)
			least = minf(least, pos.distance_to(nearest))
	return least


func test_a_squad_ordered_across_a_wall_is_held_in_front_of_it() -> void:
	var ctx: RunContext = _squad_context()
	assert_eq(ctx.commands.submit(BuildIntent.new(BARRACKS)), CommandProcessor.OK, "barracks")
	assert_eq(ctx.commands.submit(BuildIntent.new(LINE)), CommandProcessor.OK, "wall")
	for _step: int in range(SETTLE_STEPS):
		ctx.step()
	var units: UnitSystem = ctx.squads.get_units()
	assert_gt(units.count(), 0, "the squad is raised")
	var beyond: Vector2i = Vector2i(300, -270)
	var order: SquadOrderIntent = SquadOrderIntent.new(
		[BARRACKS] as Array[StringName], SquadOrder.VERB_MOVE, [beyond] as Array[Vector2i]
	)
	assert_eq(ctx.commands.submit(order), CommandProcessor.OK, "move order accepted")
	var closest_to_wall: float = INF
	for _step: int in range(MARCH_STEPS):
		ctx.step()
		for id: int in units.ids():
			var at: Vector2 = units.position_of(id)
			var reach: float = HALF + units.def_of(id).radius
			assert_gte(_clearance(ctx.walls, at), reach - EPSILON, "no unit inside the wall")
			assert_lt(at.x, WALL_X, "and none across its line")
			closest_to_wall = minf(closest_to_wall, absf(at.x - WALL_X))
	assert_lt(closest_to_wall, HALF + 0.45 + 0.3, "the squad did walk up to the wall")


func test_the_bot_king_is_held_in_front_of_a_wall() -> void:
	var map: MapConfig = load(WALLS_FIXTURE)
	var ctx: RunContext = RunContext.new(map, _tuning, 1)
	var bot: PlaytestBot = PlaytestBot.new()
	bot.build_order = [RING]
	bot.start_nights = false
	bot.king_mode = PlaytestBot.KING_HOLD_POINT
	bot.hold_point = Vector2(-20.0, 0.0)
	var reach: float = HALF + ctx.king.get_def().body_radius
	var pressed: bool = false
	for _tick: int in range(150):
		bot.think(ctx)
		ctx.step()
		var at: Vector2 = ctx.king.get_position()
		if ctx.walls.intact_count() > 0:
			assert_gte(_clearance(ctx.walls, at), reach - EPSILON, "the king is outside the wall")
			assert_gt(at.x, -12.0, "and has not crossed the west side of the ring")
			pressed = pressed or _clearance(ctx.walls, at) < reach + 0.05
	assert_true(pressed, "he walked up to the wall and stopped there")


func test_an_enemy_that_ignores_walls_crosses_the_line_and_never_attacks_a_segment() -> void:
	var map: MapConfig = (load(WALLS_FIXTURE) as MapConfig).duplicate_deep(
		Resource.DEEP_DUPLICATE_ALL
	)
	var no_nights: Array[NightDef] = []
	map.nights = no_nights
	map.castle_max_health = 1000
	var ctx: RunContext = RunContext.new(map, _tuning, 1)
	ctx.commands.submit(BuildIntent.new(RING))
	ctx.commands.submit(StartNightIntent.new())
	var enemies: EnemySystem = ctx.night.get_enemies()
	var flyer_def: EnemyDef = (load(GRUNT_PATH) as EnemyDef).duplicate()
	flyer_def.ignores_walls = true
	var walker_def: EnemyDef = load(GRUNT_PATH)
	var flyer: int = enemies.spawn(flyer_def, Vector2(-16.0, -6.0))
	var walker: int = enemies.spawn(walker_def, Vector2(-16.0, 6.0))
	var flyer_hits_on_walls: Array[int] = [0]
	var walker_hits_on_walls: Array[int] = [0]
	ctx.events.attack_fired.connect(
		func(kind: StringName, id: int, target: StringName, _tid: int, _flight: int) -> void:
			if kind == PendingHits.KIND_ENEMY and target == PendingHits.KIND_WALL:
				if id == flyer:
					flyer_hits_on_walls[0] += 1
				elif id == walker:
					walker_hits_on_walls[0] += 1
	)
	var flyer_crossed: bool = false
	var walker_crossed: bool = false
	for _tick: int in range(110):
		ctx.step()
		if enemies.is_alive(flyer):
			flyer_crossed = flyer_crossed or enemies.position_of(flyer).x > -11.0
		if enemies.is_alive(walker):
			walker_crossed = walker_crossed or enemies.position_of(walker).x > -11.0
	assert_true(flyer_crossed, "the flyer walked straight across the line of the wall")
	assert_eq(flyer_hits_on_walls[0], 0, "and never attacked a segment")
	assert_false(walker_crossed, "an ordinary grunt cannot cross an intact wall")
	assert_gt(walker_hits_on_walls[0], 0, "it attacks the segment in its way")
