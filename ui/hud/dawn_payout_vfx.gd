class_name DawnPayoutVfx
extends Control
## Makes the dawn income visible and attributable (D-12, ECON-02): one gold coin pops out above
## each paying House, one per gold it pays, and flies to the HUD gold counter. When the last coin
## lands a "+X gold" total appears for a moment. Purely visual: the Economy was already credited
## when dawn began, and the HUD lags its readout behind the coins (see Hud).

## Emitted once for every coin that reaches the gold counter.
signal coin_landed

const COIN_SIZE := Vector2(22.0, 22.0)
const COIN_CENTER_COLOR := Color(1.0, 0.93, 0.5)
const COIN_EDGE_COLOR := Color(0.93, 0.62, 0.08)
## World-space offset above the plot where a coin starts.
const SPOT_ANCHOR := Vector3(0.0, 2.5, 0.0)
const STAGGER_SECONDS: float = 0.08
const POP_SECONDS: float = 0.15
const POP_HEIGHT_PX: float = 40.0
## Whole trip per coin: the pop plus the flight to the counter.
const TRIP_SECONDS: float = 0.6
const TOTAL_SHOWN_SECONDS: float = 2.0

var _ctx: RunContext
var _coin_texture: GradientTexture2D
var _launched: Dictionary = {}
var _last_total: int = 0
var _expected_coins: int = 0
var _landed_coins: int = 0
var _pending_total: int = 0
var _generation: int = 0
var _total_tween: Tween

@onready var _gold_label: Label = %GoldLabel
@onready var _payout_total: Label = %PayoutTotal


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	_ctx = ctx
	_coin_texture = _make_coin_texture()
	ctx.events.dawn_payout.connect(_on_dawn_payout)


## Coins in the air (freed coins are not counted).
func live_coin_count() -> int:
	var count: int = 0
	for child: Node in get_children():
		if not child.is_queued_for_deletion():
			count += 1
	return count


## The total of the most recent non-empty payout; 0 until a dawn has paid something.
func get_last_total() -> int:
	return _last_total


## Coins that have left `spot_id` during the current payout.
func get_spawned_count(spot_id: StringName) -> int:
	return _launched.get(spot_id, 0)


func _make_coin_texture() -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, COIN_CENTER_COLOR)
	gradient.set_color(1, COIN_EDGE_COLOR)
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 32
	texture.height = 32
	return texture


func _on_dawn_payout(total: int, per_spot: Dictionary) -> void:
	_reset_for_new_payout()
	if total <= 0:
		return
	_pending_total = total
	var index: int = 0
	for spot_id: StringName in per_spot:
		var amount: int = per_spot[spot_id]
		for _coin: int in range(amount):
			_expected_coins += 1
			_schedule_launch(spot_id, float(index) * STAGGER_SECONDS)
			index += 1


func _reset_for_new_payout() -> void:
	_generation += 1
	_launched.clear()
	_expected_coins = 0
	_landed_coins = 0
	_pending_total = 0
	if _total_tween != null:
		_total_tween.kill()
	_payout_total.visible = false
	for child: Node in get_children():
		child.queue_free()


func _schedule_launch(spot_id: StringName, delay: float) -> void:
	if delay <= 0.0:
		_launch_coin(spot_id, _generation)
		return
	var tween: Tween = create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(_launch_coin.bind(spot_id, _generation))


func _launch_coin(spot_id: StringName, generation: int) -> void:
	if generation != _generation:
		return
	_launched[spot_id] = get_spawned_count(spot_id) + 1
	var coin: TextureRect = TextureRect.new()
	coin.texture = _coin_texture
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin.size = COIN_SIZE
	add_child(coin)
	var start: Vector2 = _start_point(spot_id) - COIN_SIZE * 0.5
	var target: Vector2 = _gold_label.get_global_rect().get_center() - COIN_SIZE * 0.5
	coin.global_position = start
	var tween: Tween = coin.create_tween()
	(
		tween
		. tween_property(coin, "global_position", start + Vector2(0.0, -POP_HEIGHT_PX), POP_SECONDS)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)
	(
		tween
		. tween_property(coin, "global_position", target, TRIP_SECONDS - POP_SECONDS)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_IN)
	)
	tween.tween_callback(_on_coin_arrived.bind(coin, generation))


## Where the plot appears on screen; the middle of the screen if there is no camera yet.
func _start_point(spot_id: StringName) -> Vector2:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return get_viewport_rect().size * 0.5
	var world_point: Vector3 = _ctx.buildings.get_spot(spot_id).position + SPOT_ANCHOR
	return camera.unproject_position(world_point)


func _on_coin_arrived(coin: TextureRect, generation: int) -> void:
	coin.queue_free()
	if generation != _generation:
		return
	_landed_coins += 1
	coin_landed.emit()
	if _landed_coins >= _expected_coins:
		_show_total()


func _show_total() -> void:
	_last_total = _pending_total
	_payout_total.text = "+%d gold" % _last_total
	_payout_total.visible = true
	_total_tween = create_tween()
	_total_tween.tween_interval(TOTAL_SHOWN_SECONDS)
	_total_tween.tween_callback(_payout_total.set_visible.bind(false))
