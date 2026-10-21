extends GutTest
## META-08 tracer: one modifier written as data reaches a tower's arrow through the one stack
## (RunContext.stat_stack -> NightSim -> TowerSystem) and shows in the debug overlay's Stats rows.
## A RunContext on fixture_map_one_night.tres (a tower 10 m from the grunts' spawn), no scene tree.

const FIXTURE := "res://tests/fixtures/fixture_map_one_night.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const GRUNT_PATH := "res://data/enemies/grunt.tres"
const TOWER_SPOT: StringName = &"tower_1"
const TOWER_DAMAGE := &"tower.damage"
const TOWER_RANGE := &"tower.range"
const MAX_STEPS: int = 600

var _tuning: LoopTuning


func before_each() -> void:
	_tuning = load(TUNING)


func _context() -> RunContext:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	var ctx: RunContext = RunContext.new(map, _tuning, 1)
	ctx.economy.grant(50)
	assert_eq(ctx.commands.submit(BuildIntent.new(TOWER_SPOT)), CommandProcessor.OK, "tower built")
	return ctx


func _tower_tier(ctx: RunContext) -> BuildingTierDef:
	var building: BuildingDef = ctx.buildings.get_building_def_for_spot(TOWER_SPOT)
	return building.tier_def(ctx.buildings.current_tier(TOWER_SPOT))


func _percent(stat: StringName, value: int) -> Array[StatModifierDef]:
	var mod: StatModifierDef = StatModifierDef.new()
	mod.stat = stat
	mod.bucket = StatModifierDef.Bucket.PERCENT
	mod.value = value
	return [mod] as Array[StatModifierDef]


## Starts the night and returns the damage of the first enemy_damaged that follows a tower shot.
func _first_tower_hit(ctx: RunContext) -> int:
	var shots: Array[StringName] = []
	var hits: Array[int] = []
	ctx.events.attack_fired.connect(
		func(
			kind: StringName, _id: int, _target_kind: StringName, _target: int, _flight: int
		) -> void:
			shots.append(kind)
	)
	ctx.events.enemy_damaged.connect(
		func(_id: int, amount: int, _hp: int) -> void:
			if not shots.is_empty() and hits.is_empty():
				hits.append(amount)
	)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night starts")
	for _i: int in range(MAX_STEPS):
		ctx.step()
		if not hits.is_empty():
			break
	assert_false(shots.is_empty(), "a shot was fired")
	assert_eq(shots[0], PendingHits.KIND_BUILDING, "the first shot is the tower's")
	assert_false(hits.is_empty(), "and it landed")
	return hits[0] if not hits.is_empty() else -1


func test_a_run_owns_one_stack_and_hands_it_to_the_night() -> void:
	var ctx: RunContext = _context()
	assert_not_null(ctx.stat_stack, "the context owns a stack")
	assert_true(ctx.stat_stack.modified_stats().is_empty(), "and it starts empty")


func test_with_no_source_the_first_tower_hit_is_the_tier_damage() -> void:
	var ctx: RunContext = _context()
	var base: int = _tower_tier(ctx).attack_damage
	assert_eq(_first_tower_hit(ctx), base, "the tier's attack damage, untouched")


func test_a_percent_source_raises_the_next_nights_first_tower_hit_by_half_up_rounding() -> void:
	var ctx: RunContext = _context()
	var base: int = _tower_tier(ctx).attack_damage
	assert_true(ctx.stat_stack.add_source(&"test_engineers", _percent(TOWER_DAMAGE, 50)), "added")
	var expected: int = (base * 150 * 2 + 100) / 200
	assert_gt(expected, base, "the fixture tier is large enough for +50% to show")
	assert_eq(_first_tower_hit(ctx), expected, "roundi-half-up(1.5 x base)")


func test_a_range_source_lets_the_tower_shoot_an_enemy_the_base_range_misses() -> void:
	var ctx: RunContext = _context()
	var tier: BuildingTierDef = _tower_tier(ctx)
	var at: Vector3 = ctx.buildings.get_spot(TOWER_SPOT).position
	var enemies: EnemySystem = EnemySystem.new(ctx.events)
	var hits: PendingHits = PendingHits.new()
	var towers: TowerSystem = TowerSystem.new(ctx.buildings, ctx.events, ctx.stat_stack)
	towers.begin_night()
	enemies.spawn(load(GRUNT_PATH), Vector2(at.x + tier.attack_range + 2.0, at.z))
	towers.step(0, enemies, hits)
	assert_true(hits.take_due(1000).is_empty(), "out of the base reach: no shot")
	assert_true(ctx.stat_stack.add_source(&"test_reach", _percent(TOWER_RANGE, 50)), "added")
	towers.begin_night()
	towers.step(0, enemies, hits)
	assert_eq(hits.take_due(1000).size(), 1, "inside the stacked reach: one shot")


func test_the_stats_rows_list_a_modified_stat_with_base_and_final_and_none_after_removal() -> void:
	var ctx: RunContext = _context()
	var base: int = _tower_tier(ctx).attack_damage
	var rows: Array = StatOverlaySections.stat_rows(ctx)
	assert_eq(rows, [[StatOverlaySections.NO_MODIFIERS_LABEL, StatOverlaySections.NONE_TEXT]])
	assert_true(ctx.stat_stack.add_source(&"test_engineers", _percent(TOWER_DAMAGE, 50)), "added")
	rows = StatOverlaySections.stat_rows(ctx)
	assert_eq(rows.size(), 1, "one modified stat, one row")
	assert_eq(rows[0][0], "tower.damage", "it names the stat")
	var final: int = ctx.stat_stack.int_value(TOWER_DAMAGE, base)
	assert_eq(rows[0][1], "%d -> %d" % [base, final], "base then final")
	ctx.stat_stack.remove_source(&"test_engineers")
	assert_eq(StatOverlaySections.stat_rows(ctx)[0][0], StatOverlaySections.NO_MODIFIERS_LABEL)


func test_a_stat_without_a_single_base_prints_its_bucket_sums() -> void:
	var ctx: RunContext = _context()
	var mods: Array[StatModifierDef] = _percent(&"king.max_health", 20)
	var mult: StatModifierDef = StatModifierDef.new()
	mult.stat = &"king.max_health"
	mult.bucket = StatModifierDef.Bucket.MULTIPLIER
	mult.value = 150
	mods.append(mult)
	assert_true(ctx.stat_stack.add_source(&"pack", mods), "added")
	var rows: Array = StatOverlaySections.stat_rows(ctx)
	assert_eq(rows[0], ["king.max_health", "flat +0, pct +20%, x1.5"], "the sums")


func test_collecting_the_stats_rows_never_writes_the_stack() -> void:
	var ctx: RunContext = _context()
	assert_true(ctx.stat_stack.add_source(&"test_engineers", _percent(TOWER_DAMAGE, 50)), "added")
	watch_signals(ctx.stat_stack)
	var before: Dictionary = ctx.stat_stack.sums_of(TOWER_DAMAGE)
	for _i: int in range(100):
		StatOverlaySections.stat_rows(ctx)
	assert_eq(ctx.stat_stack.sums_of(TOWER_DAMAGE), before, "the sums are unchanged")
	assert_eq(
		ctx.stat_stack.source_ids(), [&"test_engineers"] as Array[StringName], "so are sources"
	)
	assert_signal_not_emitted(ctx.stat_stack, "changed", "and nothing was announced")
