extends GutTest
## ENMY-04, D-07 to D-09: enemies are smart about walls. On a long wall (80 m, its only gap at the
## far north end) a crowd of 12 grunts breaks a weak segment where it stands and walks on, a lone
## grunt at a strong tier goes all the way round through the gap without hitting the wall, a ring
## with no gap is always broken into, and nobody flips between breaking and walking round at every
## rescan. The long walls are the gap fixture's run lengthened in the test with WallRunDef.

const GAP_FIXTURE := "res://tests/fixtures/fixture_map_walls_gap.tres"
const RING_FIXTURE := "res://tests/fixtures/fixture_map_walls.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const RUN: StringName = &"wall_west"
const RING: StringName = &"wall_ring"
const TOWER: StringName = &"tower_1"
const WALL_LINE_X: float = -20.0
const LONG_RUN_HALF: float = 40.0
const LONG_GAP := Vector2(76.0, 80.0)
const GAP_SOUTH: float = 36.0
const GAP_NORTH: float = 40.0
const CROWD: int = 12
const MAX_STEPS: int = 6000
const MAX_SWITCHES: int = 2
const FAR_FROM_THE_GAP: float = 30.0

var _tuning: LoopTuning


func before_each() -> void:
	_tuning = load(TUNING)


func _count(lines: PackedStringArray, event_name: String) -> int:
	var total: int = 0
	for line: String in lines:
		if line.split(" ")[1] == event_name:
			total += 1
	return total


## The gap fixture with its run lengthened to (-20, -40) to (-20, 40), the gap at 76 to 80 m of the
## path (z 36 to 40), and a night of `grunts` grunts spawned on one tick around (-30, 0).
func _long_wall_map(grunts: int) -> MapConfig:
	var map: MapConfig = (load(GAP_FIXTURE) as MapConfig).duplicate_deep(
		Resource.DEEP_DUPLICATE_ALL
	)
	for spot: BuildSpotDef in map.spots:
		if spot.id == RUN:
			spot.wall_run.points = PackedVector2Array(
				[Vector2(WALL_LINE_X, -LONG_RUN_HALF), Vector2(WALL_LINE_X, LONG_RUN_HALF)]
			)
			spot.wall_run.gaps = PackedVector2Array([LONG_GAP])
	var group: SpawnGroupDef = map.nights[0].groups[0]
	group.count = grunts
	group.interval_seconds = 0.0
	return map


## The long wall bought to `tier`, night 1 started. No tower, so the crowd reaches the wall.
func _long_wall_night(grunts: int, tier: int, run_seed: int = 1) -> RunContext:
	var ctx: RunContext = RunContext.new(_long_wall_map(grunts), _tuning, run_seed)
	for _tier: int in range(tier):
		assert_eq(ctx.commands.submit(BuildIntent.new(RUN)), CommandProcessor.OK, "wall tier")
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "start the night")
	return ctx


## Steps the night out. Returns {"crossed": id -> z where it crossed x = -20, "switches": id -> how
## often it went from a wall target to none or back, "max_wall_hitters": the most enemies on a
## wall target at once}.
func _watch(ctx: RunContext) -> Dictionary:
	var crossed: Dictionary = {}
	var switches: Dictionary = {}
	var on_wall: Dictionary = {}
	var enemies: EnemySystem = ctx.night.get_enemies()
	for _step: int in range(MAX_STEPS):
		if ctx.run_manager.get_phase() != RunManager.RunPhase.NIGHT:
			break
		ctx.step()
		for id: int in enemies.ids():
			var target: Dictionary = enemies.target_of(id)
			var kind: StringName = target.get("kind", &"")
			var attacking: bool = kind == PendingHits.KIND_WALL
			if (attacking or kind == &"") and on_wall.get(id, false) != attacking:
				switches[id] = int(switches.get(id, 0)) + 1
			if attacking or kind == &"":
				on_wall[id] = attacking
			var before: Vector2 = enemies.previous_position_of(id)
			var after: Vector2 = enemies.position_of(id)
			if before.x < WALL_LINE_X and after.x >= WALL_LINE_X and not crossed.has(id):
				var along: float = (WALL_LINE_X - before.x) / (after.x - before.x)
				crossed[id] = before.y + (after.y - before.y) * along
	return {"crossed": crossed, "switches": switches}


func test_a_crowd_of_twelve_breaks_a_weak_wall_where_it_stands_and_walks_on() -> void:
	var ctx: RunContext = _long_wall_night(CROWD, 1)
	var recorder: SimRecorder = SimRecorder.attach(ctx)
	var seen: Dictionary = _watch(ctx)
	var lines: PackedStringArray = recorder.lines()
	assert_gt(_count(lines, "wall_damaged"), 0, "the crowd hit the wall")
	assert_gt(_count(lines, "wall_segment_broken"), 0, "and broke a segment")
	var crossed: Dictionary = seen["crossed"]
	assert_gt(crossed.size(), 0, "grunts reached the castle side")
	var near: int = 0
	for id: int in crossed:
		if absf(float(crossed[id])) < FAR_FROM_THE_GAP:
			near += 1
	assert_gt(near, CROWD / 2, "most crossed through the hole they made, far from the gap")
	assert_ne(ctx.run_manager.get_phase(), RunManager.RunPhase.NIGHT, "the night ended")


func test_a_lone_grunt_at_a_strong_wall_goes_all_the_way_round_through_the_gap() -> void:
	var ctx: RunContext = _long_wall_night(1, 3)
	var recorder: SimRecorder = SimRecorder.attach(ctx)
	var seen: Dictionary = _watch(ctx)
	var crossed: Dictionary = seen["crossed"]
	assert_eq(crossed.size(), 1, "the grunt reached the castle side")
	for id: int in crossed:
		var z: float = crossed[id]
		assert_gt(z, GAP_SOUTH, "it crossed north of the gap's south end (z %.2f)" % z)
		assert_lt(z, GAP_NORTH, "and south of its north end (z %.2f)" % z)
	assert_eq(_count(recorder.lines(), "wall_damaged"), 0, "no wall was hit")
	assert_eq(_count(recorder.lines(), "wall_segment_broken"), 0, "none broke")


func test_a_lone_grunt_takes_on_a_weak_wall_when_the_gap_is_far_enough() -> void:
	## The rule is about time, not numbers: 30 hp is 450 ticks for one grunt, still less than the
	## walk of about 80 m round to the gap. (The castle's fire may kill it before the wall falls.)
	var ctx: RunContext = _long_wall_night(1, 1)
	var recorder: SimRecorder = SimRecorder.attach(ctx)
	_watch(ctx)
	assert_gt(_count(recorder.lines(), "wall_damaged"), 0, "it attacked the weak wall")


func test_on_a_sealed_ring_the_grunts_still_break_in() -> void:
	var ctx: RunContext = RunContext.new(load(RING_FIXTURE), _tuning, 1)
	var recorder: SimRecorder = SimRecorder.attach(ctx)
	ctx.commands.submit(BuildIntent.new(RING))
	ctx.commands.submit(BuildIntent.new(TOWER))
	ctx.commands.submit(StartNightIntent.new())
	for _step: int in range(MAX_STEPS):
		if ctx.run_manager.get_phase() != RunManager.RunPhase.NIGHT:
			break
		ctx.step()
	assert_gt(_count(recorder.lines(), "wall_damaged"), 0, "they attacked a segment")
	assert_gt(_count(recorder.lines(), "wall_segment_broken"), 0, "and broke one")
	assert_ne(ctx.run_manager.get_phase(), RunManager.RunPhase.NIGHT, "the night ended")


func test_nobody_flips_between_breaking_and_walking_round_more_than_twice() -> void:
	for run_seed: int in [1, 2, 3]:
		var ctx: RunContext = _long_wall_night(CROWD, 1, run_seed)
		var seen: Dictionary = _watch(ctx)
		var switches: Dictionary = seen["switches"]
		for id: int in switches:
			assert_lte(
				int(switches[id]),
				MAX_SWITCHES,
				"seed %d grunt %d switched %d times" % [run_seed, id, switches[id]]
			)


func test_the_published_time_to_destruction_is_the_crowds_while_it_is_there() -> void:
	var ctx: RunContext = _long_wall_night(CROWD, 1)
	var pathing: Pathing = ctx.night.get_pathing()
	var lowest: int = SimClock.MAX_TICKS
	var evaluated: int = 0
	for _step: int in range(MAX_STEPS):
		if ctx.run_manager.get_phase() != RunManager.RunPhase.NIGHT:
			break
		ctx.step()
		evaluated += pathing.decision().evaluated_count()
		for segment: int in range(ctx.walls.segment_count()):
			lowest = mini(lowest, pathing.decision().ttd_of(segment))
	assert_gt(evaluated, 0, "segments with a crowd near were evaluated")
	assert_lt(lowest, 450, "a crowd breaks a 30 hp segment faster than one grunt (450 ticks)")


func test_without_a_standing_segment_the_decision_never_runs() -> void:
	var ctx: RunContext = RunContext.new(_long_wall_map(CROWD), _tuning, 1)
	ctx.commands.submit(StartNightIntent.new())
	var pathing: Pathing = ctx.night.get_pathing()
	for _step: int in range(300):
		ctx.step()
		assert_eq(pathing.decision().evaluated_count(), 0, "nothing is evaluated")
	for segment: int in range(ctx.walls.segment_count()):
		assert_eq(pathing.decision().ttd_of(segment), SimClock.MAX_TICKS, "nothing is published")
	for id: int in ctx.night.get_enemies().ids():
		assert_ne(ctx.night.get_enemies().target_of(id).get("kind", &""), PendingHits.KIND_WALL)


func test_the_same_seed_makes_the_same_decisions() -> void:
	var first: Dictionary = _watch(_long_wall_night(CROWD, 1, 5))
	var second: Dictionary = _watch(_long_wall_night(CROWD, 1, 5))
	assert_eq(first["crossed"], second["crossed"], "the crossings repeat exactly")
	assert_eq(first["switches"], second["switches"], "and so do the switches")
	assert_gt((first["crossed"] as Dictionary).size(), 0, "and there are some")
