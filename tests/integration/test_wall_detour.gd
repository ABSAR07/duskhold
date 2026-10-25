extends GutTest
## ENMY-04: everyone on the ground goes round walls. On the gap fixture every enemy that crosses the
## wall line does so inside the 4 m gap, never round a run end, and no wall is hit; on the sealed
## ring the enemies still break in; two segments breaking in one tick rebuild the field once; a map
## with no wall builds no field.
## Gap round G-05-2: a break is 100000 damage against the shipped 3000-health segments.

const GAP_FIXTURE := "res://tests/fixtures/fixture_map_walls_gap.tres"
const RING_FIXTURE := "res://tests/fixtures/fixture_map_walls.tres"
const SQUADS_FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const RUN: StringName = &"wall_west"
const RING: StringName = &"wall_ring"
const TOWER: StringName = &"tower_1"
const BARRACKS: StringName = &"barracks_1"
const BARRACKS_PATH := "res://data/buildings/barracks.tres"
const FOOTMAN_PATH := "res://data/units/footman.tres"
const BEYOND := Vector2i(-2500, 0)
const BEYOND_M := Vector2(-25.0, 0.0)
const ARRIVAL_SLACK: float = 4.0
const WALL_HALF: float = 0.4
const RICH_GOLD: int = 200
const MARCH_STEPS: int = 700
const WALL_LINE_X: float = -20.0
const GAP_SOUTH: float = 2.0
const GAP_NORTH: float = 6.0
const MAX_STEPS: int = 6000

var _tuning: LoopTuning


func before_each() -> void:
	_tuning = load(TUNING)


func _count(lines: PackedStringArray, event_name: String) -> int:
	var total: int = 0
	for line: String in lines:
		if line.split(" ")[1] == event_name:
			total += 1
	return total


## The gap fixture with the run bought to tier III and the tower built, night 1 started.
func _gap_night(run_seed: int) -> RunContext:
	var ctx: RunContext = RunContext.new(load(GAP_FIXTURE), _tuning, run_seed)
	for _tier: int in range(3):
		assert_eq(ctx.commands.submit(BuildIntent.new(RUN)), CommandProcessor.OK, "wall tier")
	assert_eq(ctx.commands.submit(BuildIntent.new(TOWER)), CommandProcessor.OK, "tower")
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "start the night")
	return ctx


## Steps the night out and returns where each enemy crossed x = -20 (z at the crossing, by id).
func _crossings(ctx: RunContext) -> Dictionary:
	var crossed: Dictionary = {}
	var enemies: EnemySystem = ctx.night.get_enemies()
	for _step: int in range(MAX_STEPS):
		if ctx.run_manager.get_phase() != RunManager.RunPhase.NIGHT:
			break
		ctx.step()
		for id: int in enemies.ids():
			var before: Vector2 = enemies.previous_position_of(id)
			var after: Vector2 = enemies.position_of(id)
			if before.x < WALL_LINE_X and after.x >= WALL_LINE_X and not crossed.has(id):
				var along: float = (WALL_LINE_X - before.x) / (after.x - before.x)
				crossed[id] = before.y + (after.y - before.y) * along
	return crossed


func test_every_enemy_crosses_the_wall_line_inside_the_gap() -> void:
	var ctx: RunContext = _gap_night(1)
	var recorder: SimRecorder = SimRecorder.attach(ctx)
	var crossed: Dictionary = _crossings(ctx)
	assert_gt(crossed.size(), 0, "at least one enemy reached the castle side")
	for id: int in crossed:
		var z: float = crossed[id]
		assert_gt(z, GAP_SOUTH, "enemy %d crossed north of the gap's south end (z %.2f)" % [id, z])
		assert_lt(z, GAP_NORTH, "enemy %d crossed south of the gap's north end (z %.2f)" % [id, z])
	assert_eq(_count(recorder.lines(), "wall_damaged"), 0, "nobody hit the wall")
	assert_ne(ctx.run_manager.get_phase(), RunManager.RunPhase.NIGHT, "the night ended")


func test_the_night_clears_and_no_enemy_is_left_on_the_far_side() -> void:
	var ctx: RunContext = _gap_night(1)
	_crossings(ctx)
	assert_true(ctx.night.is_cleared(), "every enemy of the night is dead")
	assert_eq(ctx.night.get_enemies().count(), 0, "none stands on either side")
	assert_gt(ctx.castle.get_health(), 0, "and the castle stands")


func test_the_same_seed_takes_the_same_paths() -> void:
	var first: Dictionary = _crossings(_gap_night(3))
	var second: Dictionary = _crossings(_gap_night(3))
	assert_eq(first, second, "the crossings repeat exactly")
	assert_gt(first.size(), 0, "and there are some")


func test_other_seeds_also_go_through_the_gap() -> void:
	for run_seed: int in [2, 4]:
		var crossed: Dictionary = _crossings(_gap_night(run_seed))
		assert_gt(crossed.size(), 0, "seed %d: someone crossed" % run_seed)
		for id: int in crossed:
			var z: float = crossed[id]
			assert_true(
				z > GAP_SOUTH and z < GAP_NORTH, "seed %d enemy %d: z %.2f" % [run_seed, id, z]
			)


func test_a_sealed_ring_still_gets_broken_into() -> void:
	var ctx: RunContext = RunContext.new(load(RING_FIXTURE), _tuning, 1)
	var recorder: SimRecorder = SimRecorder.attach(ctx)
	ctx.commands.submit(BuildIntent.new(RING))
	ctx.commands.submit(BuildIntent.new(TOWER))
	ctx.commands.submit(StartNightIntent.new())
	for _step: int in range(MAX_STEPS):
		if ctx.run_manager.get_phase() != RunManager.RunPhase.NIGHT:
			break
		ctx.step()
	var lines: PackedStringArray = recorder.lines()
	assert_gt(_count(lines, "wall_damaged"), 0, "the enemies attacked a segment")
	assert_gt(_count(lines, "wall_segment_broken"), 0, "and broke one")
	assert_ne(ctx.run_manager.get_phase(), RunManager.RunPhase.NIGHT, "the night ended")
	var pathing: Pathing = ctx.night.get_pathing()
	assert_not_null(pathing.castle_field(), "the ring has a field")


func test_two_breaks_in_one_tick_rebuild_the_field_once() -> void:
	var ctx: RunContext = RunContext.new(load(GAP_FIXTURE), _tuning, 1)
	ctx.commands.submit(BuildIntent.new(RUN))
	ctx.step()
	var pathing: Pathing = ctx.night.get_pathing()
	var built: int = pathing.field_version()
	assert_gt(built, 0, "the purchase built the field")
	ctx.step()
	assert_eq(pathing.field_version(), built, "a step with no change builds nothing")
	ctx.walls.damage_segment(1, 100000)
	ctx.walls.damage_segment(2, 100000)
	assert_eq(pathing.field_version(), built, "the field waits for the next step")
	ctx.step()
	assert_eq(pathing.field_version(), built + 1, "two breaks, one rebuild")
	ctx.step()
	assert_eq(pathing.field_version(), built + 1, "and no more")


func test_a_map_with_no_wall_plot_builds_no_field() -> void:
	var ctx: RunContext = RunContext.new(load(SQUADS_FIXTURE), _tuning, 1)
	for _step: int in range(30):
		ctx.step()
	var pathing: Pathing = ctx.night.get_pathing()
	assert_null(pathing.castle_field(), "no field")
	assert_eq(pathing.field_version(), 0, "never rebuilt")
	assert_eq(pathing.grid().allocated_cells(), 0, "and the grid allocated nothing")
	assert_false(pathing.route().is_sealed(Vector2(5.0, 5.0)), "nothing is sealed")


func test_an_unbought_run_builds_no_field_either() -> void:
	var ctx: RunContext = RunContext.new(load(GAP_FIXTURE), _tuning, 1)
	for _step: int in range(30):
		ctx.step()
	var pathing: Pathing = ctx.night.get_pathing()
	assert_null(pathing.castle_field(), "no segment stands, no field")
	assert_eq(pathing.grid().allocated_cells(), 0, "and nothing is allocated")


## A deep copy of the gap fixture with a Barracks plot on the castle side, southeast of the gap so
## the straight line from the squad to the point beyond the wall crosses solid wall.
func _squad_world() -> RunContext:
	var map: MapConfig = (load(GAP_FIXTURE) as MapConfig).duplicate_deep(
		Resource.DEEP_DUPLICATE_ALL
	)
	map.buildings.append(load(BARRACKS_PATH))
	map.units.append(load(FOOTMAN_PATH))
	var spot: BuildSpotDef = BuildSpotDef.new()
	spot.id = BARRACKS
	spot.position = Vector3(-12.0, 0.0, -8.0)
	spot.building_id = &"barracks"
	map.spots.append(spot)
	map.starting_gold = RICH_GOLD
	return RunContext.new(map, _tuning, 1)


func test_a_squad_ordered_beyond_the_wall_walks_through_the_gap_and_arrives() -> void:
	var ctx: RunContext = _squad_world()
	assert_eq(ctx.commands.submit(BuildIntent.new(BARRACKS)), CommandProcessor.OK, "barracks")
	assert_eq(ctx.commands.submit(BuildIntent.new(RUN)), CommandProcessor.OK, "wall")
	for _step: int in range(60):
		ctx.step()
	var units: UnitSystem = ctx.squads.get_units()
	assert_gt(units.count(), 0, "the squad is raised")
	var order: SquadOrderIntent = SquadOrderIntent.new(
		[BARRACKS] as Array[StringName], SquadOrder.VERB_MOVE, [BEYOND] as Array[Vector2i]
	)
	assert_eq(ctx.commands.submit(order), CommandProcessor.OK, "move order accepted")
	var crossings: Dictionary = {}
	for _step: int in range(MARCH_STEPS):
		ctx.step()
		for id: int in units.ids():
			var before: Vector2 = units.previous_position_of(id)
			var after: Vector2 = units.position_of(id)
			if before.x >= WALL_LINE_X and after.x < WALL_LINE_X and not crossings.has(id):
				var along: float = (WALL_LINE_X - before.x) / (after.x - before.x)
				crossings[id] = before.y + (after.y - before.y) * along
	assert_eq(crossings.size(), units.count(), "every unit crossed the wall line")
	for id: int in crossings:
		var z: float = crossings[id]
		assert_true(
			z > GAP_SOUTH and z < GAP_NORTH, "unit %d crossed in the gap (z %.2f)" % [id, z]
		)
	for id: int in units.ids():
		assert_lt(
			units.position_of(id).distance_to(BEYOND_M), ARRIVAL_SLACK, "unit %d arrived" % id
		)


func test_the_bot_king_holding_a_point_beyond_the_wall_reaches_it_through_the_gap() -> void:
	var ctx: RunContext = RunContext.new(load(GAP_FIXTURE), _tuning, 1)
	var bot: PlaytestBot = PlaytestBot.new()
	bot.build_order = [RUN]
	bot.start_nights = false
	bot.king_mode = PlaytestBot.KING_HOLD_POINT
	bot.hold_point = BEYOND_M
	var crossed_at: float = INF
	var before: Vector2 = ctx.king.get_position()
	for _tick: int in range(MARCH_STEPS):
		bot.think(ctx)
		ctx.step()
		var after: Vector2 = ctx.king.get_position()
		if before.x >= WALL_LINE_X and after.x < WALL_LINE_X and crossed_at == INF:
			var along: float = (WALL_LINE_X - before.x) / (after.x - before.x)
			crossed_at = before.y + (after.y - before.y) * along
		before = after
	assert_lt(crossed_at, INF, "the king crossed the wall line")
	assert_true(
		crossed_at > GAP_SOUTH and crossed_at < GAP_NORTH, "in the gap (z %.2f)" % crossed_at
	)
	assert_lt(ctx.king.get_position().distance_to(BEYOND_M), 1.0, "and reached the point")


func test_with_the_field_budget_spent_a_unit_takes_the_straight_step_for_that_tick_only() -> void:
	var ctx: RunContext = _squad_world()
	ctx.commands.submit(BuildIntent.new(RUN))
	ctx.step()
	var pathing: Pathing = ctx.night.get_pathing()
	var cache: GoalFieldCache = pathing.new_goal_cache()
	var here: Vector2 = Vector2(-12.0, -8.0)
	var first_goal: Vector2 = BEYOND_M
	var second_goal: Vector2 = Vector2(-26.0, -4.0)
	var reach: float = 0.1
	var straight_first: Vector2 = EnemySystem.desired_step(here, first_goal, reach)
	var straight_second: Vector2 = EnemySystem.desired_step(here, second_goal, reach)
	var routed: Vector2 = pathing.walk_step(here, first_goal, reach, WALL_HALF, 0.0, 5, cache)
	assert_ne(routed, straight_first, "the first request is routed round the wall")
	assert_almost_eq(routed.length(), reach, 0.0001, "and is one full step long")
	var spent: Vector2 = pathing.walk_step(here, second_goal, reach, WALL_HALF, 0.0, 5, cache)
	assert_eq(spent, straight_second, "the second new goal in the tick takes the straight step")
	var next_tick: Vector2 = pathing.walk_step(here, second_goal, reach, WALL_HALF, 0.0, 6, cache)
	assert_ne(next_tick, straight_second, "and is routed on the next tick")


func test_walk_step_is_the_exact_straight_step_when_the_line_is_clear_or_no_wall_stands() -> void:
	var ctx: RunContext = _squad_world()
	var pathing: Pathing = ctx.night.get_pathing()
	var here: Vector2 = Vector2(-12.0, -8.0)
	var goal: Vector2 = Vector2(-4.0, 3.0)
	var straight: Vector2 = EnemySystem.desired_step(here, goal, 0.1)
	assert_eq(pathing.walk_step(here, goal, 0.1, WALL_HALF, 0.0, 0), straight, "no wall stands")
	ctx.commands.submit(BuildIntent.new(RUN))
	ctx.step()
	assert_eq(pathing.walk_step(here, goal, 0.1, WALL_HALF, 0.0, 1), straight, "a clear line")
	assert_eq(
		pathing.walk_step(here, goal, 0.1, WALL_HALF, 0.0, 1, null, 0), straight, "known clear"
	)
