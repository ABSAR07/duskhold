class_name CoinDripVfx
extends Node3D
## Makes the hold-to-build payment visible (D-05 as amended by UAT G-01-58 and G-01-59, and D-06).
## Every dripped coin flies from the king into the spot and lands just before the next one leaves,
## so the stream speeds up with the hold and still reads as one coin at a time. At the tuned floor
## the minimum flight makes a few coins overlap in the air, which reads as the stream speeding up.
## Coins paid in the same frame (after a long frame or hitch, or at a cap if the tuning ever sets
## one) leave staggered inside BURST_WINDOW_SECONDS and at most MAX_BURST_COINS of them are drawn,
## so a group reads as many coins and never floods the scene.
## A cancelled hold flies the dripped coins back to the king (D-06). Purely visual: the simulation
## only ever sees the single BuildIntent sent when the last coin lands.

const COIN_RADIUS: float = 0.18
const COIN_HEIGHT: float = 0.05
const COIN_COLOR := Color(1.0, 0.8, 0.2)
const COIN_EMISSION_ENERGY: float = 1.2
const KING_ANCHOR := Vector3(0.0, 1.5, 0.0)
const SPOT_ANCHOR := Vector3(0.0, 3.0, 0.0)
## A coin must land before the next one leaves, so the stream reads as one coin at a time.
const FLIGHT_FRACTION_OF_INTERVAL: float = 0.9
## Shortest readable flight. Once the gaps shrink to the floor, flights overlap slightly, which
## reads as the stream speeding up.
const MIN_FLIGHT_SECONDS: float = 0.12
## Flight ceiling, derived from D-05's slowest first interval so no second number needs editing
## (review IN-02). It only binds for drips slower than D-05 allows.
const MAX_FLIGHT_SECONDS: float = FLIGHT_FRACTION_OF_INTERVAL * LoopTuning.COIN_DRIP_INTERVAL_MAX_S
## Largest gap between two coins launched in the same frame.
const STAGGER_SECONDS: float = 0.04
## Every coin of one same-frame group leaves within this window.
const BURST_WINDOW_SECONDS: float = 0.3
## Visual cap per same-frame group or refund. The HUD and the label still count every coin.
const MAX_BURST_COINS: int = 12

var _ctx: RunContext
var _king: King
var _coin_mesh: CylinderMesh
var _group_frame: int = -1
var _group_index: int = 0
var _group_stagger: float = 0.0
var _burst_delays: Array[float] = []


## Seconds a coin flies when the next coin follows `gap_seconds` later: 90% of the gap, never
## shorter than MIN_FLIGHT_SECONDS and never longer than MAX_FLIGHT_SECONDS.
static func flight_seconds_for(gap_seconds: float) -> float:
	return clampf(gap_seconds * FLIGHT_FRACTION_OF_INTERVAL, MIN_FLIGHT_SECONDS, MAX_FLIGHT_SECONDS)


## Seconds between two coin launches of a same-frame group of `coin_count` coins: STAGGER_SECONDS,
## tightened so the whole group leaves inside BURST_WINDOW_SECONDS.
static func launch_stagger(coin_count: int) -> float:
	return clampf(BURST_WINDOW_SECONDS / float(maxi(coin_count - 1, 1)), 0.0, STAGGER_SECONDS)


func bind_run(ctx: RunContext, map_root: MapRoot) -> void:
	_ctx = ctx
	_king = map_root.get_king()
	_coin_mesh = _make_coin_mesh()
	var hold: BuildHoldController = map_root.get_build_hold()
	hold.hold_progress.connect(_on_hold_progress)
	hold.hold_cancelled.connect(_on_hold_cancelled)


## Coins still in the air (freed coins are not counted).
func live_coin_count() -> int:
	var count: int = 0
	for child: Node in get_children():
		if not child.is_queued_for_deletion():
			count += 1
	return count


## Seconds after their frame at which each coin of the latest same-frame group launched, in launch
## order. A normal drip is [0.0]. Test hook, read-only: it lets a test check the schedule without
## waiting on the clock.
func get_last_burst_delays() -> Array[float]:
	return _burst_delays.duplicate()


func _make_coin_mesh() -> CylinderMesh:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = COIN_COLOR
	material.emission_enabled = true
	material.emission = COIN_COLOR
	material.emission_energy_multiplier = COIN_EMISSION_ENERGY
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = COIN_RADIUS
	mesh.bottom_radius = COIN_RADIUS
	mesh.height = COIN_HEIGHT
	mesh.material = material
	return mesh


func _spawn_coin(from: Vector3) -> MeshInstance3D:
	var coin: MeshInstance3D = MeshInstance3D.new()
	coin.mesh = _coin_mesh
	add_child(coin)
	coin.global_position = from
	return coin


func _fly(coin: MeshInstance3D, to: Vector3, delay: float, flight_seconds: float) -> void:
	var tween: Tween = coin.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(coin, "global_position", to, flight_seconds)
	tween.tween_callback(coin.queue_free)


func _spot_anchor(spot_id: StringName) -> Vector3:
	return _ctx.buildings.get_spot(spot_id).position + SPOT_ANCHOR


## Each coin flies for 90% of the gap to the next one. Coins paid in the same frame (a long frame
## or a hitch, or a cap if the tuning sets one) form one group: staggered, and drawn only up to
## MAX_BURST_COINS.
func _on_hold_progress(spot_id: StringName, coins_paid: int, cost: int) -> void:
	var frame: int = Engine.get_process_frames()
	if frame != _group_frame:
		_group_frame = frame
		_group_index = 0
		_group_stagger = launch_stagger(mini(cost - coins_paid + 1, MAX_BURST_COINS))
		_burst_delays.clear()
	var index: int = _group_index
	_group_index += 1
	if index >= MAX_BURST_COINS:
		return
	var delay: float = float(index) * _group_stagger
	_burst_delays.append(delay)
	var coin: MeshInstance3D = _spawn_coin(_king.global_position + KING_ANCHOR)
	var flight: float = flight_seconds_for(_ctx.tuning.coin_interval(coins_paid + 1))
	_fly(coin, _spot_anchor(spot_id), delay, flight)


## D-06 made visible: the dripped coins return to the king, staggered, up to MAX_BURST_COINS.
func _on_hold_cancelled(spot_id: StringName, coins_refunded: int) -> void:
	var home: Vector3 = _king.global_position + KING_ANCHOR
	var count: int = mini(coins_refunded, MAX_BURST_COINS)
	var stagger: float = launch_stagger(count)
	var flight: float = flight_seconds_for(_ctx.tuning.coin_interval(1))
	for index: int in range(count):
		var coin: MeshInstance3D = _spawn_coin(_spot_anchor(spot_id))
		_fly(coin, home, float(index) * stagger, flight)
