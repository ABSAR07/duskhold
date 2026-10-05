extends GutTest
## D-18: the named scripted strategies the balance report runs. Each strategy is a PlaytestBot
## configuration, so the tests check what the bots are told to build and how the king behaves, and
## that a run with a strategy stays reproducible. The numbers come from the shipped map.

const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
const HOUSE: StringName = &"house"
const TOWER: StringName = &"tower"
const EPSILON: float = 0.0001


func _context(run_seed: int = 1) -> RunContext:
	var tuning: LoopTuning = load(TUNING_PATH)
	return RunContext.new(E2eSupport.shipped_prototype_map(), tuning, run_seed)


func _building_of(map: MapConfig, spot_id: StringName) -> StringName:
	for spot: BuildSpotDef in map.spots:
		if spot.id == spot_id:
			return spot.building_id
	return &""


func test_the_five_named_strategies_are_listed() -> void:
	var expected: Array[StringName] = [
		&"no_build", &"greedy_economy", &"houses_first", &"towers_first", &"balanced"
	]
	assert_eq(PlaytestStrategies.NAMES, expected, "the names the CLI may select")


func test_make_returns_a_bot_for_every_listed_name() -> void:
	for strategy: StringName in PlaytestStrategies.NAMES:
		assert_not_null(PlaytestStrategies.make(strategy), "a bot for %s" % strategy)


func test_make_returns_nothing_for_an_unknown_name() -> void:
	assert_null(PlaytestStrategies.make(&"nope"), "unknown name")
	assert_null(PlaytestStrategies.make(&""), "empty name")


func test_every_make_call_gives_a_fresh_bot() -> void:
	var first: PlaytestBot = PlaytestStrategies.make(&"balanced")
	var second: PlaytestBot = PlaytestStrategies.make(&"balanced")
	assert_ne(first, second, "bots keep a cursor, so they are never shared")


func test_no_build_has_an_empty_order_and_an_idle_king() -> void:
	var bot: PlaytestBot = PlaytestStrategies.make(&"no_build")
	assert_eq(bot.build_order.size(), 0, "builds nothing")
	assert_eq(bot.king_mode, PlaytestBot.KING_IDLE_AT_CASTLE, "the king waits at the castle")


func test_greedy_economy_builds_only_house_plots_and_upgrades_them() -> void:
	var bot: PlaytestBot = PlaytestStrategies.make(&"greedy_economy")
	var map: MapConfig = E2eSupport.shipped_prototype_map()
	assert_gt(bot.build_order.size(), 0, "it has an order")
	var seen: Dictionary = {}
	var upgrades: int = 0
	for spot_id: StringName in bot.build_order:
		assert_eq(_building_of(map, spot_id), HOUSE, "%s is a House plot" % spot_id)
		if seen.has(spot_id):
			upgrades += 1
		seen[spot_id] = true
	assert_gt(upgrades, 0, "a repeated House plot is an upgrade")


func test_every_strategy_order_names_real_spots() -> void:
	var map: MapConfig = E2eSupport.shipped_prototype_map()
	for strategy: StringName in PlaytestStrategies.NAMES:
		for spot_id: StringName in PlaytestStrategies.make(strategy).build_order:
			assert_ne(_building_of(map, spot_id), &"", "%s: spot %s exists" % [strategy, spot_id])


func test_the_tower_and_house_orders_differ_in_what_they_build_first() -> void:
	var map: MapConfig = E2eSupport.shipped_prototype_map()
	var houses: PlaytestBot = PlaytestStrategies.make(&"houses_first")
	var towers: PlaytestBot = PlaytestStrategies.make(&"towers_first")
	assert_eq(_building_of(map, houses.build_order[0]), HOUSE, "houses_first starts on a House")
	assert_eq(_building_of(map, towers.build_order[0]), TOWER, "towers_first starts on a tower")
	var houses_before_tower: int = 0
	for spot_id: StringName in houses.build_order:
		if _building_of(map, spot_id) == TOWER:
			break
		houses_before_tower += 1
	assert_eq(houses_before_tower, 3, "houses_first builds three Houses, then towers")


func test_only_balanced_prefers_telegraphed_towers() -> void:
	for strategy: StringName in PlaytestStrategies.NAMES:
		var bot: PlaytestBot = PlaytestStrategies.make(strategy)
		assert_eq(bot.prefer_telegraphed_towers, strategy == &"balanced", "%s" % strategy)


func test_every_strategy_except_no_build_defends_with_the_king() -> void:
	for strategy: StringName in PlaytestStrategies.NAMES:
		if strategy == &"no_build":
			continue
		var bot: PlaytestBot = PlaytestStrategies.make(strategy)
		assert_eq(bot.king_mode, PlaytestBot.KING_DEFEND_NEAREST_THREAT, "%s" % strategy)
		assert_true(bot.start_nights, "%s starts every night as soon as it can" % strategy)


func test_the_defending_king_sprints_toward_the_enemy_nearest_the_castle() -> void:
	var ctx: RunContext = _context()
	var bot: PlaytestBot = PlaytestStrategies.make(&"houses_first")
	var guard: int = 0
	while ctx.get_enemy_count() < 2 and guard < 3000:
		bot.think(ctx)
		ctx.step()
		guard += 1
	assert_gte(ctx.get_enemy_count(), 2, "the first night's enemies appeared")
	var enemies: EnemySystem = ctx.night.get_enemies()
	var target_pos: Vector2 = Vector2.ZERO
	var best: float = INF
	for id: int in enemies.ids():
		var distance: float = enemies.position_of(id).distance_to(ctx.castle.get_position())
		if distance < best:
			best = distance
			target_pos = enemies.position_of(id)
	var before: Vector2 = ctx.king.get_position()
	bot.think(ctx)
	var after: Vector2 = ctx.king.get_position()
	var def: KingDef = ctx.king.get_def()
	var pace: float = def.walk_speed * def.sprint_multiplier * SimClock.STEP
	assert_lte(before.distance_to(after), pace + EPSILON, "no faster than a sprint step")
	assert_lt(after.distance_to(target_pos), before.distance_to(target_pos), "and it is closer")
	assert_gt(before.distance_to(after), def.walk_speed * SimClock.STEP, "faster than a walk")


func test_the_defending_king_waits_at_the_castle_front_when_no_enemy_is_up() -> void:
	var ctx: RunContext = _context()
	var bot: PlaytestBot = PlaytestStrategies.make(&"balanced")
	bot.start_nights = false
	ctx.king.report_position(Vector2(0.0, 40.0))
	for _i: int in range(300):
		bot.think(ctx)
		ctx.step()
	var front: Vector2 = Vector2(ctx.map.king_spawn.x, ctx.map.king_spawn.z)
	assert_lt(ctx.king.get_position().distance_to(front), 0.5, "back at the castle front")


func test_balanced_builds_the_tower_on_the_coming_nights_road_first() -> void:
	var ctx: RunContext = _context()
	var bot: PlaytestBot = PlaytestStrategies.make(&"balanced")
	var order: Array[StringName] = [&"tower_3", &"tower_2", &"tower_1"]
	bot.build_order = order
	bot.think(ctx)
	assert_eq(ctx.buildings.current_tier(&"tower_1"), 1, "night 1 comes from the west road")
	assert_eq(ctx.buildings.current_tier(&"tower_3"), 0, "the north plot waits")
	assert_eq(ctx.buildings.current_tier(&"tower_2"), 0, "and so does the east plot")


func test_a_strategy_run_is_reproducible() -> void:
	var map: MapConfig = load("res://data/maps/prototype_map.tres")
	var tuning: LoopTuning = load(TUNING_PATH)
	var king: KingDef = load("res://data/king/king.tres")
	var first: Dictionary = ReplayDriver.run(
		map, tuning, 3, PlaytestStrategies.make(&"balanced"), 1500, 0, king
	)
	var second: Dictionary = ReplayDriver.run(
		map, tuning, 3, PlaytestStrategies.make(&"balanced"), 1500, 0, king
	)
	assert_eq(String(first["digest"]).length(), 64, "a sha256 digest")
	assert_eq(first["digest"], second["digest"], "same strategy and seed, same run")
