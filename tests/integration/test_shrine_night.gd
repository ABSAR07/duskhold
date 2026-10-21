extends GutTest
## ECON-06, D-12 and research P4 / Pitfall 2 in the night step. Part one is a hand-built night
## (TowerSystem, IncomeState, BuildingSystem, EnemySystem and PendingHits, no RunContext): a dormant
## Shrine never fires even with an enemy in reach, an awake one shoots like a tower, and it reads
## its damage and reach through shrine.damage and shrine.range, never the tower stats. Part two runs
## a whole night on tests/fixtures/fixture_map_shrine.tres in a RunContext: grunts die beside the
## Shrine, it wakes, fires bolts it never fired while dormant and pays at dawn, and the run replays
## to the same digest. The Shrine's numbers are set on a deep copy (damage 3, reach 9 m, interval
## 1.1 s, speed 20 m/s), so a later fit of the shipped Shrine cannot break these tests.

const FIXTURE := "res://tests/fixtures/fixture_map_shrine.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const SHRINE_PATH := "res://data/buildings/shrine.tres"
const HOUSE_PATH := "res://data/buildings/house.tres"
const GRUNT_PATH := "res://data/enemies/grunt.tres"
const SHRINE_SPOT: StringName = &"shrine_1"
const TOWER_SPOT: StringName = &"tower_1"
const SECOND_TOWER_SPOT: StringName = &"tower_2"
const SHRINE_AT := Vector2(40.0, 0.0)
const DAMAGE: int = 3
const REACH: float = 9.0
const INTERVAL: float = 1.1
const SPEED: float = 20.0
const TOUGH_HEALTH: int = 100000
const NEAR: float = 5.0
const JUST_PAST_REACH: float = 9.5
const HALF_AGAIN: int = 50
const PAY: int = 1
const MAX_NIGHT_TICKS: int = 4000

var _map: MapConfig
var _events: SimEvents
var _buildings: BuildingSystem
var _income: IncomeState
var _stats: StatStack
var _towers: TowerSystem
var _enemies: EnemySystem
var _hits: PendingHits
var _grunt: EnemyDef


func before_each() -> void:
	_grunt = load(GRUNT_PATH)
	_build_hand_night(true)


## A one-Shrine map and the systems around it; `with_income` false builds the TowerSystem without
## the IncomeState, the way a caller that never learned about Shrines would.
func _build_hand_night(with_income: bool) -> void:
	var shrine: BuildingDef = (load(SHRINE_PATH) as BuildingDef).duplicate_deep(
		Resource.DEEP_DUPLICATE_ALL
	)
	var tier: BuildingTierDef = shrine.tier_def(1)
	tier.attack_damage = DAMAGE
	tier.attack_range = REACH
	tier.attack_interval = INTERVAL
	tier.projectile_speed = SPEED
	_map = MapConfig.new()
	_map.buildings = [shrine, load(HOUSE_PATH)] as Array[BuildingDef]
	_map.enemies = [_grunt] as Array[EnemyDef]
	var spot: BuildSpotDef = BuildSpotDef.new()
	spot.id = SHRINE_SPOT
	spot.building_id = shrine.id
	spot.position = Vector3(SHRINE_AT.x, 0.0, SHRINE_AT.y)
	_map.spots = [spot] as Array[BuildSpotDef]
	_events = SimEvents.new()
	_stats = StatStack.new()
	_buildings = BuildingSystem.new(_map, _events, _stats)
	_income = IncomeState.new(_map, _buildings, _events, _stats)
	_towers = TowerSystem.new(_buildings, _events, _stats, _income if with_income else null)
	_towers.begin_night()
	_enemies = EnemySystem.new(_events)
	_hits = PendingHits.new()
	assert_not_null(_buildings.apply_next_tier(SHRINE_SPOT), "the Shrine is built")


func _tough_grunt() -> EnemyDef:
	var def: EnemyDef = _grunt.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	def.max_health = TOUGH_HEALTH
	return def


func _spawn_at(distance: float) -> int:
	return _enemies.spawn(_tough_grunt(), SHRINE_AT + Vector2(distance, 0.0))


## Wakes the Shrine the way the game does: deaths beside it.
func _wake() -> void:
	var tier: BuildingTierDef = _buildings.get_building_def_for_spot(SHRINE_SPOT).tier_def(1)
	var needed: int = ceili(float(tier.wake_threshold_hp) / float(_grunt.max_health))
	for death: int in range(needed):
		_events.enemy_died.emit(death, &"grunt", SHRINE_AT, &"tower")
	assert_true(_income.is_awake(SHRINE_SPOT), "the Shrine is awake")


func _record_shots() -> Array:
	var shots: Array = []
	_events.attack_fired.connect(
		func(kind: StringName, id: int, target_kind: StringName, target: int, flight: int) -> void:
			shots.append([kind, id, target_kind, target, flight])
	)
	return shots


## One night step in the DR-8 order; the damage of every hit that landed is appended to `landed`.
func _tick(tick: int, landed: Array[int]) -> void:
	_towers.step(tick, _enemies, _hits)
	for hit: PendingHits.Hit in _hits.take_due(tick):
		if hit.target_kind == PendingHits.KIND_ENEMY:
			landed.append(hit.amount)
			_enemies.damage(hit.target_id, hit.amount, hit.attacker_kind)
	_enemies.remove_dead()


func _run(ticks: int) -> Array[int]:
	var landed: Array[int] = []
	for tick: int in range(ticks):
		_tick(tick, landed)
	return landed


func test_a_dormant_shrine_never_fires_with_an_enemy_in_reach() -> void:
	_spawn_at(NEAR)
	var shots: Array = _record_shots()
	var landed: Array[int] = _run(200)
	assert_eq(shots.size(), 0, "no shot in 200 ticks")
	assert_eq(_hits.size(), 0, "and nothing queued")
	assert_eq(landed.size(), 0, "so nothing landed")


func test_a_tower_system_that_cannot_ask_about_waking_keeps_the_shrine_silent() -> void:
	_build_hand_night(false)
	_wake()
	_spawn_at(NEAR)
	var shots: Array = _record_shots()
	_run(100)
	assert_eq(shots.size(), 0, "without an IncomeState nobody can say it woke")


func test_an_awake_shrine_shoots_the_nearest_enemy_like_a_tower() -> void:
	_wake()
	var target: int = _spawn_at(NEAR)
	var shots: Array = _record_shots()
	_run(1)
	assert_eq(shots.size(), 1, "it fires on the first step it can")
	assert_eq(shots[0][0], PendingHits.KIND_BUILDING, "as a building")
	assert_eq(shots[0][1], _buildings.spot_index(SHRINE_SPOT), "from its own plot index")
	assert_eq(shots[0][3], target, "at the enemy")
	assert_gt(shots[0][4], 0, "the bolt takes time to fly")


func test_an_awake_shrine_fires_once_per_interval() -> void:
	_wake()
	_spawn_at(NEAR)
	var shots: Array = _record_shots()
	var ticks: int = SimClock.ticks(INTERVAL) * 3 + 1
	_run(ticks)
	assert_eq(shots.size(), 4, "ticks 0, 1, 2 and 3 intervals")


func test_the_bolt_lands_for_the_shrine_damage() -> void:
	_wake()
	_spawn_at(NEAR)
	var landed: Array[int] = _run(SimClock.ticks(INTERVAL))
	assert_eq(landed, [DAMAGE] as Array[int], "one bolt of the tier's damage")


func test_shrine_damage_modifiers_change_the_bolt_and_tower_damage_ones_do_not() -> void:
	_wake()
	var tower_mod: StatModifierDef = _modifier(&"tower.damage", StatModifierDef.Bucket.FLAT, 40)
	_stats.add_source(&"tower_buff", [tower_mod] as Array[StatModifierDef])
	_spawn_at(NEAR)
	assert_eq(_run(SimClock.ticks(INTERVAL)), [DAMAGE] as Array[int], "a tower buff is not read")
	var shrine_mod: StatModifierDef = _modifier(
		&"shrine.damage", StatModifierDef.Bucket.PERCENT, HALF_AGAIN
	)
	_stats.add_source(&"shrine_buff", [shrine_mod] as Array[StatModifierDef])
	var buffed: int = _stats.int_value(&"shrine.damage", DAMAGE)
	assert_gt(buffed, DAMAGE, "a shrine buff raises the stat")
	_towers.begin_night()
	assert_eq(
		_run(SimClock.ticks(INTERVAL)), [buffed] as Array[int], "and the next bolt carries it"
	)


func test_an_enemy_just_past_the_reach_is_not_shot_until_the_shrine_range_grows() -> void:
	_wake()
	_spawn_at(JUST_PAST_REACH)
	var shots: Array = _record_shots()
	_run(10)
	assert_eq(shots.size(), 0, "9.5 m is past a 9 m reach")
	var tower_range: StatModifierDef = _modifier(
		&"tower.range", StatModifierDef.Bucket.PERCENT, HALF_AGAIN
	)
	_stats.add_source(&"tower_range", [tower_range] as Array[StatModifierDef])
	_run(10)
	assert_eq(shots.size(), 0, "a tower range buff is not read")
	var shrine_range: StatModifierDef = _modifier(
		&"shrine.range", StatModifierDef.Bucket.PERCENT, HALF_AGAIN
	)
	_stats.add_source(&"shrine_range", [shrine_range] as Array[StatModifierDef])
	_run(1)
	assert_eq(shots.size(), 1, "a shrine range buff brings it into reach")


func test_a_fallen_awake_shrine_fires_nothing_and_fires_again_once_rebuilt() -> void:
	_wake()
	_spawn_at(NEAR)
	_buildings.damage_building(SHRINE_SPOT, _buildings.max_health_of(SHRINE_SPOT))
	var shots: Array = _record_shots()
	_run(100)
	assert_eq(shots.size(), 0, "a fallen Shrine does not shoot")
	assert_true(_income.is_awake(SHRINE_SPOT), "yet it is still awake")
	_buildings.rebuild_destroyed()
	_towers.begin_night()
	_run(1)
	assert_eq(shots.size(), 1, "rebuilt, it shoots again at the next night")


func test_towers_keep_the_tower_stats_and_the_shrine_names_its_own() -> void:
	var tower_free: BuildingDef = _buildings.get_building_def_for_spot(SHRINE_SPOT)
	assert_eq(tower_free.income_curve, BuildingDef.IncomeCurve.AWAKENED, "the plot is a Shrine")
	assert_eq(tower_free.damage_stat, &"shrine.damage", "reading its own damage stat")
	var tower: BuildingDef = load("res://data/buildings/tower.tres")
	assert_eq(tower.damage_stat, &"tower.damage", "towers keep the tower stats")
	assert_eq(tower.range_stat, &"tower.range", "damage and reach")


func _modifier(stat: StringName, bucket: StatModifierDef.Bucket, value: int) -> StatModifierDef:
	var mod: StatModifierDef = StatModifierDef.new()
	mod.stat = stat
	mod.bucket = bucket
	mod.value = value
	return mod


# ---- Part two: a whole night in a RunContext on the fixture map -------------------------------


func _fixture_ctx(run_seed: int) -> RunContext:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	var ctx: RunContext = RunContext.new(map, load(TUNING), run_seed)
	assert_eq(ctx.commands.submit(BuildIntent.new(TOWER_SPOT)), CommandProcessor.OK, "tower bought")
	var second: StringName = ctx.commands.submit(BuildIntent.new(SECOND_TOWER_SPOT))
	assert_eq(second, CommandProcessor.OK, "second tower bought")
	assert_eq(
		ctx.commands.submit(BuildIntent.new(SHRINE_SPOT)), CommandProcessor.OK, "Shrine bought"
	)
	return ctx


## Plays night 1 to dawn and reports what the Shrine did. Keys: wake_tick (-1 when it never woke),
## fires (the run ticks of every Shrine shot), dormant_in_reach (steps the Shrine was dormant with
## an enemy in its reach), awake_at_fire (false if any shot came while dormant), payout (what the
## dawn paid the Shrine, 0 when it is absent), lines (the recorder's log).
func _play_night(ctx: RunContext) -> Dictionary:
	var report: Dictionary = {
		"wake_tick": -1,
		"fires": [] as Array[int],
		"dormant_in_reach": 0,
		"awake_at_fire": true,
		"payout": 0,
	}
	var recorder: SimRecorder = SimRecorder.attach(ctx)
	var shrine_index: int = ctx.buildings.spot_index(SHRINE_SPOT)
	var plot: Vector3 = ctx.buildings.get_spot(SHRINE_SPOT).position
	var tier: BuildingTierDef = ctx.buildings.get_building_def_for_spot(SHRINE_SPOT).tier_def(1)
	ctx.events.shrine_woke.connect(
		func(_spot: StringName) -> void: report["wake_tick"] = ctx.tick_count
	)
	ctx.events.attack_fired.connect(
		func(kind: StringName, id: int, _tk: StringName, _tid: int, _flight: int) -> void:
			if kind == PendingHits.KIND_BUILDING and id == shrine_index:
				(report["fires"] as Array[int]).append(ctx.tick_count)
				if not ctx.income.is_awake(SHRINE_SPOT):
					report["awake_at_fire"] = false
	)
	ctx.events.dawn_payout.connect(
		func(_total: int, per_spot: Dictionary) -> void:
			report["payout"] = int(per_spot.get(SHRINE_SPOT, 0))
	)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night starts")
	var steps: int = 0
	while ctx.run_manager.get_phase() != RunManager.RunPhase.DAWN and steps < MAX_NIGHT_TICKS:
		var dormant: bool = not ctx.income.is_awake(SHRINE_SPOT)
		ctx.step()
		steps += 1
		if (
			dormant
			and not (
				ctx
				. night
				. get_enemies()
				. living_within(Vector2(plot.x, plot.z), tier.attack_range)
				. is_empty()
			)
		):
			report["dormant_in_reach"] = int(report["dormant_in_reach"]) + 1
	recorder.append_final_state(ctx)
	report["lines"] = recorder.lines()
	report["digest"] = recorder.digest()
	return report


func test_the_shrine_stays_silent_while_dormant_then_wakes_fires_and_pays() -> void:
	var ctx: RunContext = _fixture_ctx(1)
	var report: Dictionary = _play_night(ctx)
	assert_gt(int(report["wake_tick"]), -1, "enough grunts fell beside it to wake it in night 1")
	assert_true(ctx.income.is_awake(SHRINE_SPOT), "and it is awake at dawn")
	assert_gt(int(report["dormant_in_reach"]), 0, "grunts were in its reach while it slept")
	assert_true(report["awake_at_fire"], "no shot came from it while it was dormant")
	var fires: Array[int] = report["fires"]
	assert_gt(fires.size(), 0, "once awake it shot")
	assert_gte(fires[0], int(report["wake_tick"]), "and never before it woke")
	assert_eq(int(report["payout"]), _fixture_pay(ctx), "the first dawn pays the awake Shrine")


func _fixture_pay(ctx: RunContext) -> int:
	return ctx.buildings.get_building_def_for_spot(SHRINE_SPOT).tier_def(1).dawn_income


func test_the_log_records_one_wake_before_the_shrine_shoots() -> void:
	var ctx: RunContext = _fixture_ctx(1)
	var report: Dictionary = _play_night(ctx)
	var wakes: int = 0
	var woke_line: int = -1
	var first_shot_line: int = -1
	var lines: PackedStringArray = report["lines"]
	var shot_prefix: String = " attack_fired building %d " % ctx.buildings.spot_index(SHRINE_SPOT)
	for index: int in range(lines.size()):
		if lines[index].contains(" shrine_woke "):
			wakes += 1
			woke_line = index
		if first_shot_line < 0 and lines[index].contains(shot_prefix):
			first_shot_line = index
	assert_eq(wakes, 1, "exactly one shrine_woke line")
	assert_gt(first_shot_line, woke_line, "the first Shrine shot comes after the wake")


func test_two_runs_with_the_same_seed_give_the_same_digest_and_another_seed_differs() -> void:
	var first: Dictionary = _play_night(_fixture_ctx(1))
	var second: Dictionary = _play_night(_fixture_ctx(1))
	var other: Dictionary = _play_night(_fixture_ctx(2))
	assert_eq(first["digest"], second["digest"], "same seed, same digest")
	assert_ne(first["digest"], other["digest"], "another seed scatters the spawns differently")


func test_a_run_that_never_builds_the_shrine_never_hears_a_wake() -> void:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	var ctx: RunContext = RunContext.new(map, load(TUNING), 1)
	assert_eq(ctx.commands.submit(BuildIntent.new(TOWER_SPOT)), CommandProcessor.OK, "tower only")
	var recorder: SimRecorder = SimRecorder.attach(ctx)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night starts")
	var steps: int = 0
	while ctx.run_manager.get_phase() != RunManager.RunPhase.DAWN and steps < MAX_NIGHT_TICKS:
		ctx.step()
		steps += 1
	for line: String in recorder.lines():
		assert_false(line.contains(" shrine_woke "), "no wake without a Shrine")
	assert_eq(ctx.income.kill_credit(SHRINE_SPOT), 0, "and no credit")
