extends GutTest
## The hold-pacing sandbox (tools/sandbox) is the owner's real-window way to feel the accelerating
## hold and the 3 s cap (UAT G-01-58). This keeps it loading with House tiers of 15, 30 and 50
## coins, enough gold for all three, the shipped tuning, and the shipped House data untouched.

const SANDBOX_SCENE := "res://tools/sandbox/hold_pacing_sandbox.tscn"
const HOUSE_PATH := "res://data/buildings/house.tres"
const HOUSE: StringName = &"house"
const EXPECTED_COSTS: Array[int] = [15, 30, 50]
const EXPECTED_GOLD: int = 15 + 30 + 50 + 5


func _house_costs(house: BuildingDef) -> Array[int]:
	var costs: Array[int] = []
	for tier: BuildingTierDef in house.tiers:
		costs.append(tier.cost)
	return costs


func _sandbox_house(ctx: RunContext) -> BuildingDef:
	for building_def: BuildingDef in ctx.map.buildings:
		if building_def.id == HOUSE:
			return building_def
	return null


func _spawn_sandbox() -> HoldPacingSandbox:
	var scene: PackedScene = load(SANDBOX_SCENE)
	var sandbox: HoldPacingSandbox = scene.instantiate()
	add_child_autofree(sandbox)
	await wait_process_frames(2)
	return sandbox


func test_the_sandbox_starts_the_map_with_the_expensive_house_tiers() -> void:
	var sandbox: HoldPacingSandbox = await _spawn_sandbox()
	var map_root: MapRoot = sandbox.get_map_root()
	assert_not_null(map_root, "the sandbox started the map")
	if map_root == null:
		return
	var ctx: RunContext = map_root.get_context()
	var house: BuildingDef = _sandbox_house(ctx)

	assert_not_null(house, "the sandbox map has a House")
	if house == null:
		return
	assert_eq(_house_costs(house), EXPECTED_COSTS, "House tiers cost 15, 30 and 50")
	assert_eq(ctx.economy.get_gold(), EXPECTED_GOLD, "gold covers all three tiers plus a margin")


func test_the_sandbox_uses_the_shipped_tuning_so_the_big_tiers_hit_the_cap() -> void:
	var sandbox: HoldPacingSandbox = await _spawn_sandbox()
	var map_root: MapRoot = sandbox.get_map_root()
	assert_not_null(map_root, "the sandbox started the map")
	if map_root == null:
		return
	var tuning: LoopTuning = map_root.get_context().tuning
	var shipped: LoopTuning = load("res://data/tuning/loop_tuning.tres")

	assert_eq(tuning.coin_drip_interval, shipped.coin_drip_interval, "shipped first interval")
	assert_eq(tuning.max_build_hold_seconds, shipped.max_build_hold_seconds, "shipped cap")
	assert_eq(
		tuning.build_hold_seconds(EXPECTED_COSTS[2]),
		tuning.max_build_hold_seconds,
		"the 50-coin tier takes the whole cap"
	)


func test_the_shipped_house_data_is_untouched() -> void:
	var before: Array[int] = _house_costs(load(HOUSE_PATH))
	var sandbox: HoldPacingSandbox = await _spawn_sandbox()

	assert_not_null(sandbox.get_map_root(), "the sandbox started the map")
	assert_eq(_house_costs(load(HOUSE_PATH)), before, "the cached house.tres keeps its costs")
	assert_ne(before, EXPECTED_COSTS, "the sandbox costs really differ from the shipped ones")
