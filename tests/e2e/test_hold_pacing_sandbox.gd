extends GutTest
## The hold-pacing sandbox (tools/sandbox) is the owner's real-window way to feel the accelerating,
## uncapped hold where every coin drips (UAT G-01-58 and G-01-59). This keeps it loading with House
## tiers of 15, 30 and 50 coins, enough gold for all three on every House plot, the shipped
## tuning, and the shipped House data untouched.

const SANDBOX_SCENE := "res://tools/sandbox/hold_pacing_sandbox.tscn"
const HOUSE_PATH := "res://data/buildings/house.tres"
const HOUSE: StringName = &"house"
const EXPECTED_COSTS: Array[int] = [15, 30, 50]
const SHIPPED_TUNING_PATH := "res://data/tuning/loop_tuning.tres"


## Gold the sandbox is expected to start with: every tier's cost on every House plot plus its
## margin, derived from the sandbox's constants and the map's spots (review IN-04, IN-03).
func _expected_gold(map: MapConfig) -> int:
	var chain: int = 0
	for cost: int in HoldPacingSandbox.SANDBOX_HOUSE_COSTS:
		chain += cost
	var plots: int = 0
	for spot: BuildSpotDef in map.spots:
		if spot.building_id == HOUSE:
			plots += 1
	return chain * plots + HoldPacingSandbox.GOLD_MARGIN


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
	assert_gt(
		_expected_gold(ctx.map), 100, "the map has several House plots, so one chain is not it"
	)
	assert_eq(
		ctx.economy.get_gold(),
		_expected_gold(ctx.map),
		"gold covers all three tiers on every House plot plus a margin"
	)


func test_the_sandbox_uses_the_shipped_tuning_so_every_coin_drips() -> void:
	var sandbox: HoldPacingSandbox = await _spawn_sandbox()
	var map_root: MapRoot = sandbox.get_map_root()
	assert_not_null(map_root, "the sandbox started the map")
	if map_root == null:
		return
	var tuning: LoopTuning = map_root.get_context().tuning
	var shipped: LoopTuning = load(SHIPPED_TUNING_PATH)
	var big_cost: int = EXPECTED_COSTS[2]
	var plain_sum_s: float = 0.0
	for coin: int in range(1, big_cost + 1):
		plain_sum_s += tuning.coin_interval(coin)

	assert_eq(tuning.coin_drip_interval, shipped.coin_drip_interval, "shipped first interval")
	assert_eq(tuning.coin_drip_min_interval, shipped.coin_drip_min_interval, "shipped floor")
	assert_eq(tuning.max_build_hold_seconds, shipped.max_build_hold_seconds, "shipped cap")
	assert_almost_eq(
		tuning.build_hold_seconds(big_cost),
		plain_sum_s,
		0.0001,
		"the 50-coin hold is the plain sum"
	)
	assert_gt(
		tuning.build_hold_seconds(big_cost),
		tuning.build_hold_seconds(EXPECTED_COSTS[1]),
		"the 50-coin tier takes longer than the 30-coin one"
	)


func test_the_shipped_house_data_is_untouched() -> void:
	var before: Array[int] = _house_costs(load(HOUSE_PATH))
	var sandbox: HoldPacingSandbox = await _spawn_sandbox()

	assert_not_null(sandbox.get_map_root(), "the sandbox started the map")
	assert_eq(_house_costs(load(HOUSE_PATH)), before, "the cached house.tres keeps its costs")
	assert_ne(before, EXPECTED_COSTS, "the sandbox costs really differ from the shipped ones")
