extends GutTest
## ENMY-04: everyone on the ground goes round walls. On the gap fixture every enemy that crosses the
## wall line does so inside the 4 m gap, never round a run end, and no wall is hit; on the sealed
## ring the enemies still break in; two segments breaking in one tick rebuild the field once; a map
## with no wall builds no field.

const GAP_FIXTURE := "res://tests/fixtures/fixture_map_walls_gap.tres"
const RING_FIXTURE := "res://tests/fixtures/fixture_map_walls.tres"
const SQUADS_FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const RUN: StringName = &"wall_west"
const RING: StringName = &"wall_ring"
const TOWER: StringName = &"tower_1"
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
	ctx.walls.damage_segment(1, 1000)
	ctx.walls.damage_segment(2, 1000)
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
	assert_false(pathing.is_sealed(Vector2(5.0, 5.0)), "nothing is sealed")


func test_an_unbought_run_builds_no_field_either() -> void:
	var ctx: RunContext = RunContext.new(load(GAP_FIXTURE), _tuning, 1)
	for _step: int in range(30):
		ctx.step()
	var pathing: Pathing = ctx.night.get_pathing()
	assert_null(pathing.castle_field(), "no segment stands, no field")
	assert_eq(pathing.grid().allocated_cells(), 0, "and nothing is allocated")
