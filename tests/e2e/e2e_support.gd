class_name E2eSupport
extends RefCounted
## Shared helpers for scene-level tests that drive the real game through Input.action_press.
## Not collected by GUT (no test_ prefix); later plans reuse it.

const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_forward", &"move_back"]


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
