extends GutTest
## BLDG-10 / D-03 / D-05: what the wall looks like in the real scene. Each tier has its own look (a
## wooden palisade, the Castle Kit stone wall, the stone wall with tower-base pillars); a broken
## segment sinks over 0.4 s and leaves rubble that blocks nothing; a hurt segment shows a bar; the
## dawn restore raises the pieces back. The batches are asserted through their CPU mirror hooks,
## because the headless renderer reads a MultiMesh back as zeros.

const FIXTURE := "res://tests/fixtures/fixture_map_walls.tres"
const WEST: StringName = &"wall_west"
const RING: StringName = &"wall_ring"
const RING_SEGMENTS: int = 32
const WEST_SEGMENTS: int = 12
const DRAW_TIMEOUT_S: float = 2.0
## The collapse takes 0.4 s; the test allows it generous real time.
const COLLAPSE_TIMEOUT_S: float = 3.0
const EXTRA_GOLD: int = 40
const HURT_AMOUNT: int = 5


func _spawn_map(map_config: MapConfig = null) -> MapRoot:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	var map_root: MapRoot = scene.instantiate()
	if map_config != null:
		map_root.map_config = map_config
	map_root.fixed_run_seed = 1
	add_child_autofree(map_root)
	await wait_process_frames(2)
	return map_root


func _fixture_map() -> MapConfig:
	return (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)


func _buy(ctx: RunContext, spot_id: StringName, times: int = 1) -> void:
	for _i: int in range(times):
		if ctx.commands.validate_build(spot_id) == CommandProcessor.CASTLE_TIER:
			E2eSupport.raise_castle(ctx, 2)
		assert_eq(ctx.commands.submit(BuildIntent.new(spot_id)), CommandProcessor.OK, "bought")


func _until(check: Callable) -> bool:
	return await E2eSupport.wait_until(self, check, DRAW_TIMEOUT_S)


func test_nothing_is_drawn_and_no_look_is_set_before_a_purchase() -> void:
	var map_root: MapRoot = await _spawn_map()
	var views: WallViews = map_root.get_node("WallViews")
	assert_eq(views.piece_count(), 0, "no piece")
	assert_eq(views.rubble_count(), 0, "no rubble")
	assert_eq(views.bar_count(), 0, "no bar")
	assert_eq(views.tier_look_of(WEST), &"", "and no look for an unbought run")


func test_the_three_tiers_have_the_barricade_stone_and_reinforced_looks() -> void:
	var map_root: MapRoot = await _spawn_map()
	var ctx: RunContext = map_root.get_context()
	var views: WallViews = map_root.get_node("WallViews")
	ctx.economy.grant(EXTRA_GOLD)
	_buy(ctx, WEST)
	var barricade: Callable = func() -> bool: return views.tier_look_of(WEST) == &"barricade"
	assert_true(await _until(barricade), "tier I is the barricade")
	assert_eq(views.piece_count(), WEST_SEGMENTS, "every segment is a piece")
	assert_eq(views.pillar_count(), 0, "a barricade has no pillars")
	_buy(ctx, WEST)
	var stone: Callable = func() -> bool: return views.tier_look_of(WEST) == &"stone"
	assert_true(await _until(stone), "tier II is the stone wall")
	assert_eq(views.pillar_count(), 0, "a stone wall has no pillars")
	_buy(ctx, WEST)
	var reinforced: Callable = func() -> bool: return views.tier_look_of(WEST) == &"reinforced"
	assert_true(await _until(reinforced), "tier III is the reinforced wall")
	assert_eq(views.piece_count(), WEST_SEGMENTS, "still every segment")
	assert_eq(views.pillar_count(), WEST_SEGMENTS * 2, "a pillar at both ends of every segment")


func test_each_run_wears_the_look_of_its_own_tier() -> void:
	var map_root: MapRoot = await _spawn_map()
	var ctx: RunContext = map_root.get_context()
	var views: WallViews = map_root.get_node("WallViews")
	ctx.economy.grant(EXTRA_GOLD)
	_buy(ctx, WEST, 1)
	_buy(ctx, &"wall_east", 2)
	_buy(ctx, &"wall_north", 3)
	var drawn: Callable = func() -> bool: return views.tier_look_of(&"wall_north") == &"reinforced"
	assert_true(await _until(drawn), "the north run is reinforced")
	assert_eq(views.tier_look_of(WEST), &"barricade", "west stays a barricade")
	assert_eq(views.tier_look_of(&"wall_east"), &"stone", "east is stone")
	assert_eq(views.tier_look_of(RING), &"", "the ring is unbought")


func test_a_broken_segment_sinks_then_becomes_rubble_that_blocks_nothing() -> void:
	var map_root: MapRoot = await _spawn_map(_fixture_map())
	var ctx: RunContext = map_root.get_context()
	var views: WallViews = map_root.get_node("WallViews")
	_buy(ctx, RING)
	var whole: Callable = func() -> bool: return views.piece_count() == RING_SEGMENTS
	assert_true(await _until(whole), "the ring is drawn whole")
	var segment: int = ctx.walls.segments_of(RING)[3]
	ctx.walls.damage_segment(segment, ctx.walls.max_health_of(segment))
	await wait_process_frames(2)
	assert_true(views.is_piece_drawn(segment), "the segment is still drawn while it sinks")
	assert_eq(views.rubble_count(), 0, "and no rubble yet")
	var settled: Callable = func() -> bool: return views.rubble_count() == 1
	assert_true(await E2eSupport.wait_until(self, settled, COLLAPSE_TIMEOUT_S), "rubble")
	assert_false(views.is_piece_drawn(segment), "the sunk segment is no longer a piece")
	assert_eq(views.piece_count(), RING_SEGMENTS - 1, "the rest of the ring still stands")
	assert_false(ctx.walls.is_intact(segment), "and the rubble is a hole, not a wall")


func test_a_hurt_segment_shows_a_bar_and_a_full_one_does_not() -> void:
	var map_root: MapRoot = await _spawn_map(_fixture_map())
	var ctx: RunContext = map_root.get_context()
	var views: WallViews = map_root.get_node("WallViews")
	_buy(ctx, RING)
	var whole: Callable = func() -> bool: return views.piece_count() == RING_SEGMENTS
	assert_true(await _until(whole), "the ring is drawn whole")
	assert_eq(views.bar_count(), 0, "full health shows no bar")
	var segments: PackedInt32Array = ctx.walls.segments_of(RING)
	ctx.walls.damage_segment(segments[0], HURT_AMOUNT)
	var one: Callable = func() -> bool: return views.bar_count() == 1
	assert_true(await _until(one), "one hurt segment adds one bar")
	ctx.walls.damage_segment(segments[1], HURT_AMOUNT)
	var two: Callable = func() -> bool: return views.bar_count() == 2
	assert_true(await _until(two), "a second adds another")


func test_dawn_raises_the_broken_segment_and_clears_rubble_and_bars() -> void:
	var map_root: MapRoot = await _spawn_map(_fixture_map())
	var ctx: RunContext = map_root.get_context()
	var views: WallViews = map_root.get_node("WallViews")
	_buy(ctx, RING)
	var whole: Callable = func() -> bool: return views.piece_count() == RING_SEGMENTS
	assert_true(await _until(whole), "the ring is drawn whole")
	var segments: PackedInt32Array = ctx.walls.segments_of(RING)
	ctx.walls.damage_segment(segments[5], ctx.walls.max_health_of(segments[5]))
	ctx.walls.damage_segment(segments[6], HURT_AMOUNT)
	var rubble: Callable = func() -> bool:
		return views.rubble_count() == 1 and views.bar_count() == 1
	assert_true(await E2eSupport.wait_until(self, rubble, COLLAPSE_TIMEOUT_S), "rubble and a bar")
	ctx.walls.restore_all()
	var raised: Callable = func() -> bool:
		return (
			views.rubble_count() == 0
			and views.bar_count() == 0
			and views.is_piece_drawn(segments[5])
			and views.piece_count() == RING_SEGMENTS
		)
	assert_true(await E2eSupport.wait_until(self, raised, COLLAPSE_TIMEOUT_S), "drawn again")
