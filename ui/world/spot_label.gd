class_name SpotLabel
extends Node3D
## World-space label floating above the focused build spot (D-07). Shows the next tier's name,
## its cost as coin icons (filling as coins land, red when unaffordable) and its one-line effect.
## Visible only for the single focused spot and only while building is allowed (by day). A denied
## press shakes it with a brief red outline flash; hold_denied is also the Phase 8 SFX hook (D-08).

const LABEL_HEIGHT: float = 3.2
## The camera-to-label distance under the framing the owner approved in UAT test 6 (camera offset
## (0, 16, 11), label LABEL_HEIGHT above the spot, king 0.5 m beside it: the square root of
## 12.8 squared plus 11 squared plus 0.5 squared, about 16.9 m). Farther cameras scale the label up.
const LEGIBLE_CAMERA_DISTANCE: float = 16.9
const UNAFFORDABLE_COLOR := Color(1.0, 0.25, 0.25)
const NORMAL_COLOR := Color(1.0, 1.0, 1.0)
const PAID_COIN_COLOR := Color(1.0, 0.8, 0.2)
const UNPAID_COIN_COLOR := Color(0.25, 0.25, 0.25)
const OUTLINE_COLOR := Color(0.0, 0.0, 0.0)
const COIN_TEXTURE_SIZE: int = 64
const COIN_PIXEL_SIZE: float = 0.006
const COIN_SPACING: float = 0.42
const SHAKE_SECONDS: float = 0.3
const SHAKE_AMPLITUDE: float = 0.15
## Fractions of SHAKE_AMPLITUDE visited in order; the last must be 0 so the label settles.
const SHAKE_STEPS: Array[float] = [1.0, -1.0, 0.66, -0.66, 0.33, 0.0]

var _ctx: RunContext
var _hold: BuildHoldController
var _focused: StringName = &""
var _coins_paid: int = 0
var _anchor: Vector3 = Vector3.ZERO
var _shake_x: float = 0.0:
	set = _set_shake_x
var _coin_texture: GradientTexture2D
var _shake_tween: Tween
var _flash_tween: Tween

@onready var _title: Label3D = %Title
@onready var _effect: Label3D = %Effect
@onready var _coins: Node3D = %Coins
@onready var _status: Label3D = %Status


func bind_run(ctx: RunContext, map_root: MapRoot) -> void:
	_ctx = ctx
	_hold = map_root.get_build_hold()
	_coin_texture = _make_coin_texture()
	_hold.focus_changed.connect(_on_focus_changed)
	_hold.hold_progress.connect(_on_hold_progress)
	_hold.hold_cancelled.connect(_on_hold_cancelled)
	_hold.hold_completed.connect(_on_hold_completed)
	_hold.hold_denied.connect(_on_hold_denied)
	ctx.events.gold_changed.connect(_on_gold_changed)
	ctx.events.building_built.connect(_on_building_built)
	ctx.events.phase_changed.connect(_on_phase_changed)
	_focused = _hold.get_focused_spot()
	_refresh()


func _refresh() -> void:
	var show_label: bool = _focused != &"" and _ctx.run_manager.is_build_allowed()
	visible = show_label
	if not show_label:
		return
	var content: Dictionary = SpotLabelModel.describe(_ctx, _focused, _coins_paid)
	_anchor = _ctx.buildings.get_spot(_focused).position + Vector3(0.0, LABEL_HEIGHT, 0.0)
	_apply_position()
	var tint: Color = NORMAL_COLOR if content["affordable"] else UNAFFORDABLE_COLOR
	_title.text = content["title"]
	_title.modulate = tint
	_effect.text = content["effect"]
	_status.text = content["status_line"]
	_show_coins(content["cost"], content["paid"], content["affordable"])


func _show_coins(cost: int, paid: int, affordable: bool) -> void:
	if _coins.get_child_count() != cost:
		_rebuild_coins(cost)
	for index: int in range(cost):
		var coin: Sprite3D = _coins.get_child(index) as Sprite3D
		if not affordable:
			coin.modulate = UNAFFORDABLE_COLOR
		elif index < paid:
			coin.modulate = PAID_COIN_COLOR
		else:
			coin.modulate = UNPAID_COIN_COLOR


func _rebuild_coins(count: int) -> void:
	for child: Node in _coins.get_children():
		_coins.remove_child(child)
		child.queue_free()
	for index: int in range(count):
		var coin: Sprite3D = Sprite3D.new()
		coin.texture = _coin_texture
		coin.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		coin.no_depth_test = true
		coin.shaded = false
		coin.pixel_size = COIN_PIXEL_SIZE
		coin.position = Vector3((float(index) - (count - 1) * 0.5) * COIN_SPACING, 0.0, 0.0)
		_coins.add_child(coin)


## A white disc with a soft edge; each coin sprite tints it gold, grey or red.
func _make_coin_texture() -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.85, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1.0, 1.0, 1.0, 0.0)])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = COIN_TEXTURE_SIZE
	texture.height = COIN_TEXTURE_SIZE
	return texture


func _set_shake_x(value: float) -> void:
	_shake_x = value
	_apply_position()


func _apply_position() -> void:
	position = _anchor + Vector3(_shake_x, 0.0, 0.0)


func _play_denied() -> void:
	if _shake_tween != null:
		_shake_tween.kill()
	if _flash_tween != null:
		_flash_tween.kill()
	_shake_x = 0.0
	var step_seconds: float = SHAKE_SECONDS / float(SHAKE_STEPS.size())
	_shake_tween = create_tween()
	for fraction: float in SHAKE_STEPS:
		_shake_tween.tween_property(self, "_shake_x", fraction * SHAKE_AMPLITUDE, step_seconds)
	_title.outline_modulate = UNAFFORDABLE_COLOR
	_flash_tween = create_tween()
	_flash_tween.tween_property(_title, "outline_modulate", OUTLINE_COLOR, SHAKE_SECONDS)


func _on_focus_changed(spot_id: StringName) -> void:
	_focused = spot_id
	_coins_paid = 0
	_refresh()


func _on_hold_progress(_spot_id: StringName, coins_paid: int, _cost: int) -> void:
	_coins_paid = coins_paid
	_refresh()


func _on_hold_cancelled(_spot_id: StringName, _coins_refunded: int) -> void:
	_coins_paid = 0
	_refresh()


func _on_hold_completed(_spot_id: StringName) -> void:
	_coins_paid = 0
	_refresh()


## No sound here: hold_denied is the documented Phase 8 SFX hook (D-08).
func _on_hold_denied(_spot_id: StringName, _reason: StringName) -> void:
	if visible:
		_play_denied()


func _on_gold_changed(_new_amount: int, _delta: int) -> void:
	_refresh()


func _on_building_built(_spot_id: StringName, _building_id: StringName, _new_tier: int) -> void:
	_refresh()


func _on_phase_changed(_old_phase: int, _new_phase: int) -> void:
	_refresh()
