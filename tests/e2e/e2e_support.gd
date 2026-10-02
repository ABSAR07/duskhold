class_name E2eSupport
extends RefCounted
## Shared helpers for scene-level tests that drive the real game through Input.action_press.
## Not collected by GUT (no test_ prefix); later plans reuse it.

const MAP_SCENE_PATH := "res://presentation/map/prototype_map.tscn"
const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_forward", &"move_back"]
const PROTOTYPE_MAP_PATH := "res://data/maps/prototype_map.tres"
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"


## An isolated deep copy of the shipped prototype map with one building tier repriced and the
## starting gold replaced. The shallow `duplicate(true)` copy shares the external house.tres and
## tower.tres, so an in-place tier edit would leak into the cached resource for every later test in
## the same GUT process (debugger-verified); `DEEP_DUPLICATE_ALL` copies those sub-resources too.
## `tier` is 1-based. Null when the building or tier does not exist.
static func map_with_tier_cost(
	building_id: StringName, tier: int, cost: int, starting_gold: int
) -> MapConfig:
	var shipped: MapConfig = load(PROTOTYPE_MAP_PATH)
	var map: MapConfig = shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	for building_def: BuildingDef in map.buildings:
		if building_def.id != building_id:
			continue
		var tier_def: BuildingTierDef = building_def.tier_def(tier)
		if tier_def == null:
			return null
		tier_def.cost = cost
		map.starting_gold = starting_gold
		return map
	return null


## A copy of the shipped tuning with a flat, uncapped drip: every coin takes `seconds_per_coin` and
## no cap ends the hold early. Tests that slow the drip to watch a hold in progress use this, so
## they do not depend on the shipped acceleration and cap (D-05 as amended, UAT G-01-58). Tests that
## measure the shipped pacing must keep using the shipped tuning. LoopTuning holds only scalars, so
## the copy shares nothing with the cached resource other tests read.
static func flat_drip_tuning(seconds_per_coin: float) -> LoopTuning:
	var shipped: LoopTuning = load(TUNING_PATH)
	var tuning: LoopTuning = shipped.duplicate(true)
	tuning.coin_drip_interval = seconds_per_coin
	tuning.coin_drip_decay = 1.0
	tuning.max_build_hold_seconds = 0.0
	return tuning


## Instantiates the real prototype map scene, optionally swapping the map data or tuning before
## `_ready` builds the RunContext, and waits two frames for the run-bound nodes to bind.
static func spawn_map(
	test: GutTest, map_config: MapConfig = null, tuning: LoopTuning = null
) -> MapRoot:
	var scene: PackedScene = load(MAP_SCENE_PATH)
	var map_root: MapRoot = scene.instantiate()
	if map_config != null:
		map_root.map_config = map_config
	if tuning != null:
		map_root.loop_tuning = tuning
	test.add_child_autofree(map_root)
	await test.wait_process_frames(2)
	return map_root


## Polls `predicate` once per process frame until it is true or `timeout_s` of real time passes.
## True if the predicate became true in time.
static func wait_until(test: GutTest, predicate: Callable, timeout_s: float) -> bool:
	var timeout_ms: int = roundi(timeout_s * 1000.0)
	var started: int = Time.get_ticks_msec()
	while not predicate.call() and Time.get_ticks_msec() - started < timeout_ms:
		await test.wait_process_frames(1)
	return predicate.call()


## Releases every action in the Input Map so no test leaks a held key into the next.
static func release_all_actions() -> void:
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)


## Places the king instantly, without going through movement.
static func teleport_king(map_root: MapRoot, pos: Vector3) -> void:
	map_root.get_king().global_position = pos


## Presses the move actions toward the spot and polls until the hold controller focuses it.
## Releases the move actions before returning. True if the spot was reached in time.
static func ride_until_focused(
	test: GutTest, map_root: MapRoot, spot_id: StringName, timeout_s: float
) -> bool:
	var ctx: RunContext = map_root.get_context()
	var king: King = map_root.get_king()
	var hold: BuildHoldController = map_root.get_build_hold()
	var target: Vector3 = ctx.buildings.get_spot(spot_id).position
	var toward: Vector3 = target - king.global_position
	var direction: Vector2 = Vector2(toward.x, toward.z).normalized()
	Input.action_press(&"move_left", maxf(-direction.x, 0.0))
	Input.action_press(&"move_right", maxf(direction.x, 0.0))
	Input.action_press(&"move_forward", maxf(-direction.y, 0.0))
	Input.action_press(&"move_back", maxf(direction.y, 0.0))
	var timeout_ms: int = roundi(timeout_s * 1000.0)
	var started: int = Time.get_ticks_msec()
	while hold.get_focused_spot() != spot_id and Time.get_ticks_msec() - started < timeout_ms:
		await test.wait_process_frames(1)
	for action: StringName in MOVE_ACTIONS:
		Input.action_release(action)
	return hold.get_focused_spot() == spot_id


## Holds `action` for `seconds` of real time, then releases it.
static func hold_action_seconds(test: GutTest, action: StringName, seconds: float) -> void:
	Input.action_press(action)
	await test.wait_seconds(seconds)
	Input.action_release(action)
