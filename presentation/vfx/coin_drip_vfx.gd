class_name CoinDripVfx
extends Node3D
## Makes the hold-to-build payment visible (D-05, D-06): every dripped coin flies from the king
## into the spot, and a cancelled hold flies every dripped coin back to the king. Purely visual;
## the simulation only ever sees the single BuildIntent sent when the last coin lands.

const COIN_RADIUS: float = 0.18
const COIN_HEIGHT: float = 0.05
const COIN_COLOR := Color(1.0, 0.8, 0.2)
const COIN_EMISSION_ENERGY: float = 1.2
const KING_ANCHOR := Vector3(0.0, 1.5, 0.0)
const SPOT_ANCHOR := Vector3(0.0, 3.0, 0.0)
const MAX_FLIGHT_SECONDS: float = 0.18
## A coin must land before the next one leaves, so the stream reads as one coin at a time.
const FLIGHT_FRACTION_OF_INTERVAL: float = 0.9
const REFUND_STAGGER_SECONDS: float = 0.04

var _ctx: RunContext
var _king: King
var _coin_mesh: CylinderMesh


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


func _flight_seconds() -> float:
	return minf(MAX_FLIGHT_SECONDS, _ctx.tuning.coin_drip_interval * FLIGHT_FRACTION_OF_INTERVAL)


func _spawn_coin(from: Vector3) -> MeshInstance3D:
	var coin: MeshInstance3D = MeshInstance3D.new()
	coin.mesh = _coin_mesh
	add_child(coin)
	coin.global_position = from
	return coin


func _fly(coin: MeshInstance3D, to: Vector3, delay: float) -> void:
	var tween: Tween = coin.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(coin, "global_position", to, _flight_seconds())
	tween.tween_callback(coin.queue_free)


func _spot_anchor(spot_id: StringName) -> Vector3:
	return _ctx.buildings.get_spot(spot_id).position + SPOT_ANCHOR


func _on_hold_progress(spot_id: StringName, _coins_paid: int, _cost: int) -> void:
	var coin: MeshInstance3D = _spawn_coin(_king.global_position + KING_ANCHOR)
	_fly(coin, _spot_anchor(spot_id), 0.0)


## D-06 made visible: every dripped coin returns to the king.
func _on_hold_cancelled(spot_id: StringName, coins_refunded: int) -> void:
	var home: Vector3 = _king.global_position + KING_ANCHOR
	for index: int in range(coins_refunded):
		var coin: MeshInstance3D = _spawn_coin(_spot_anchor(spot_id))
		_fly(coin, home, float(index) * REFUND_STAGGER_SECONDS)
