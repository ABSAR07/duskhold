extends GutTest
## UAT G-01-4 and G-01-58 on the real scene: holds with the shipped map and tuning (no overrides)
## pay each coin at its due time on the accelerating curve (D-05 as amended). Every measurement
## is on the hold's own clock (the frame deltas the controller accumulates), never wall-clock
## time, so these assertions hold on any frame timing and a frame hitch cannot make them flake
## (review WR-01). Only the wait timeouts use real time.

const HOUSE_SPOT: StringName = &"house_1"
const TOWER_SPOT: StringName = &"tower_1"
## Sits well inside interaction_radius of a plot.
const NEAR_OFFSET := Vector3(0.5, 0.0, 0.0)
const EPSILON: float = 0.0001
## Real-time slack on top of the expected hold length while waiting for the build.
const LATE_SLACK_S: float = 0.5
## UAT G-01-4 judged a 0.4 s House I hold too short.
const MIN_HOLD_S: float = 0.5

var _ctx: RunContext
var _hold: BuildHoldController
var _spot_id: StringName = &""
var _cost: int = 0
var _coin_numbers: Array[int] = []
var _coin_stamps_s: Array[float] = []
var _coin_deltas_s: Array[float] = []
var _coin_frame_clocks_s: Array[float] = []
var _frame_clock_s: float = 0.0
var _clock_running: bool = false
var _frame_hook_connected: bool = false


func before_each() -> void:
	_coin_numbers.clear()
	_coin_stamps_s.clear()
	_coin_deltas_s.clear()
	_coin_frame_clocks_s.clear()
	_frame_clock_s = 0.0
	_clock_running = false


func after_each() -> void:
	E2eSupport.release_all_actions()
	if _frame_hook_connected and get_tree().process_frame.is_connected(_on_process_frame):
		get_tree().process_frame.disconnect(_on_process_frame)
	_frame_hook_connected = false


## process_frame fires before the nodes' _process, so on each frame this adds the same delta the
## controller adds to its hold clock.
func _on_process_frame() -> void:
	if _clock_running:
		_frame_clock_s += get_process_delta_time()


func _on_hold_started(_spot_id: StringName, _hold_cost: int) -> void:
	_frame_clock_s = 0.0
	_clock_running = true


func _on_hold_progress(_spot: StringName, coins_paid: int, _hold_cost: int) -> void:
	_coin_numbers.append(coins_paid)
	_coin_stamps_s.append(_hold.get_hold_elapsed())
	_coin_deltas_s.append(get_process_delta_time())
	_coin_frame_clocks_s.append(_frame_clock_s)


func _focused() -> bool:
	return _hold.get_focused_spot() == _spot_id


func _tier_built() -> bool:
	return _ctx.buildings.current_tier(_spot_id) == 1


## Stands the king beside the plot, holds the action key until tier I stands and lets go. Fills
## the coin arrays and returns whether the build completed in time.
func _measure_hold(spot_id: StringName) -> bool:
	_spot_id = spot_id
	var map_root: MapRoot = await E2eSupport.spawn_map(self)
	_ctx = map_root.get_context()
	_hold = map_root.get_build_hold()
	_cost = _ctx.buildings.next_action_cost(spot_id)
	assert_gte(_ctx.economy.get_gold(), _cost, "the starting gold covers the first tier")
	E2eSupport.teleport_king(map_root, _ctx.buildings.get_spot(spot_id).position + NEAR_OFFSET)
	await E2eSupport.wait_until(self, _focused, 1.0)
	_hold.hold_started.connect(_on_hold_started)
	_hold.hold_progress.connect(_on_hold_progress)
	get_tree().process_frame.connect(_on_process_frame)
	_frame_hook_connected = true

	Input.action_press(&"action_build")
	var built: bool = await E2eSupport.wait_until(
		self, _tier_built, _ctx.tuning.build_hold_seconds(_cost) + LATE_SLACK_S
	)
	Input.action_release(&"action_build")
	return built


func _last_stamp_s() -> float:
	return _coin_stamps_s[_coin_stamps_s.size() - 1]


func _last_delta_s() -> float:
	return _coin_deltas_s[_coin_deltas_s.size() - 1]


func test_house_one_hold_ends_when_its_last_coin_is_due() -> void:
	var built: bool = await _measure_hold(HOUSE_SPOT)
	assert_true(built, "the House I hold completed and built tier I")
	assert_eq(_coin_stamps_s.size(), _cost, "one hold_progress per coin")
	if _coin_stamps_s.is_empty():
		return
	var expected_s: float = _ctx.tuning.build_hold_seconds(_cost)

	assert_gte(_last_stamp_s(), expected_s - EPSILON, "the hold is not cut short")
	assert_lte(_last_stamp_s(), expected_s + _last_delta_s() + EPSILON, "or dragged out")


func test_each_tower_coin_is_paid_at_its_due_time() -> void:
	var built: bool = await _measure_hold(TOWER_SPOT)
	assert_true(built, "the Tower I hold completed and built tier I")
	assert_eq(_coin_numbers.size(), _cost, "exactly one hold_progress per coin")
	for i: int in _coin_numbers.size():
		var coin: int = _coin_numbers[i]
		var due_s: float = _ctx.tuning.coin_due_seconds(coin)
		assert_eq(coin, i + 1, "coins run 1..cost in order")
		assert_gte(_coin_stamps_s[i], due_s - EPSILON, "coin %d is not paid early" % coin)
		assert_lte(
			_coin_stamps_s[i],
			due_s + _coin_deltas_s[i] + EPSILON,
			"coin %d is paid within one frame of its due time" % coin
		)


func test_the_hold_clock_equals_the_summed_frame_deltas() -> void:
	var built: bool = await _measure_hold(TOWER_SPOT)
	assert_true(built, "the Tower I hold completed")
	for i: int in _coin_stamps_s.size():
		assert_almost_eq(
			_coin_stamps_s[i],
			_coin_frame_clocks_s[i],
			EPSILON,
			"at coin %d no frame delta was lost or counted twice" % _coin_numbers[i]
		)


func test_house_one_hold_lasts_at_least_the_minimum() -> void:
	var built: bool = await _measure_hold(HOUSE_SPOT)
	assert_true(built, "the House I hold completed")
	if _coin_stamps_s.is_empty():
		return
	assert_gte(_last_stamp_s(), MIN_HOLD_S - EPSILON, "a House I hold is a deliberate moment")
