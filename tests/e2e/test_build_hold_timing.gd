extends GutTest
## UAT G-01-4 on the real scene: a House I hold with the shipped map and tuning (no overrides)
## lasts its full cost x coin_drip_interval, one coin per interval. Guards against a too-short
## tuning value and against any timing bug (a double-counted delta, a reset timer).

const SPOT: StringName = &"house_1"
## Sits well inside interaction_radius of a plot.
const NEAR_OFFSET := Vector3(0.5, 0.0, 0.0)
## A hold may complete at most this much sooner than cost x interval (frame-boundary slack).
const EARLY_TOLERANCE_S: float = 0.02
## A hold may complete at most this much later than cost x interval.
const LATE_TOLERANCE_S: float = 0.5
## Allowed jitter of one gap between consecutive coins (frame granularity).
const GAP_TOLERANCE_S: float = 0.05
## UAT G-01-4 judged a 0.4 s House I hold too short.
const MIN_HOLD_S: float = 0.5

var _coin_times_s: Array[float] = []


func after_each() -> void:
	E2eSupport.release_all_actions()


func _on_hold_progress(_spot_id: StringName, _coins_paid: int, _cost: int) -> void:
	_coin_times_s.append(float(Time.get_ticks_usec()) / 1_000_000.0)


func _tier_built(ctx: RunContext) -> bool:
	return ctx.buildings.current_tier(SPOT) == 1


func _focused(hold: BuildHoldController) -> bool:
	return hold.get_focused_spot() == SPOT


## Stands the king beside the House plot, holds the action key until tier I stands, and returns
## { "ctx": RunContext, "cost": int, "started_s": float, "finished_s": float, "built": bool }.
func _measure_house_hold() -> Dictionary:
	_coin_times_s.clear()
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	var ctx: RunContext = map_root.get_context()
	var hold: BuildHoldController = map_root.get_build_hold()
	var cost: int = ctx.buildings.next_action_cost(SPOT)
	E2eSupport.teleport_king(map_root, ctx.buildings.get_spot(SPOT).position + NEAR_OFFSET)
	await E2eSupport.wait_until(self, _focused.bind(hold), 1.0)
	hold.hold_progress.connect(_on_hold_progress)

	var started_s: float = float(Time.get_ticks_usec()) / 1_000_000.0
	Input.action_press(&"action_build")
	var timeout_s: float = float(cost) * ctx.tuning.coin_drip_interval + LATE_TOLERANCE_S
	var built: bool = await E2eSupport.wait_until(self, _tier_built.bind(ctx), timeout_s)
	var finished_s: float = float(Time.get_ticks_usec()) / 1_000_000.0
	Input.action_release(&"action_build")
	return {
		"ctx": ctx, "cost": cost, "started_s": started_s, "finished_s": finished_s, "built": built
	}


func test_house_one_hold_lasts_cost_times_the_drip_interval() -> void:
	var run: Dictionary = await _measure_house_hold()
	var ctx: RunContext = run["ctx"]
	var expected_s: float = float(run["cost"]) * ctx.tuning.coin_drip_interval
	var held_s: float = float(run["finished_s"]) - float(run["started_s"])

	assert_true(run["built"], "the House I hold completed and built tier I")
	assert_gte(held_s, expected_s - EARLY_TOLERANCE_S, "the hold is not cut short")
	assert_lte(held_s, expected_s + LATE_TOLERANCE_S, "the hold is not dragged out")


func test_coins_drip_one_per_interval() -> void:
	var run: Dictionary = await _measure_house_hold()
	var ctx: RunContext = run["ctx"]
	var interval: float = ctx.tuning.coin_drip_interval

	assert_eq(_coin_times_s.size(), int(run["cost"]), "one hold_progress per coin")
	for i: int in range(1, _coin_times_s.size()):
		assert_almost_eq(
			_coin_times_s[i] - _coin_times_s[i - 1],
			interval,
			GAP_TOLERANCE_S,
			"gap before coin %d is one drip interval" % (i + 1)
		)


func test_house_one_hold_is_at_least_the_minimum() -> void:
	var run: Dictionary = await _measure_house_hold()
	var held_s: float = float(run["finished_s"]) - float(run["started_s"])
	assert_gte(held_s, MIN_HOLD_S, "a House I hold is a deliberate moment")
