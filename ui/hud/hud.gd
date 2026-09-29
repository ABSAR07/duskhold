class_name Hud
extends CanvasLayer
## Gold readout. Gold is the only currency the HUD shows.
## While a hold is dripping, the readout shows the gold the player would have left
## (Economy gold minus the coins in flight). This is display only: Economy stays
## all-or-nothing and only changes when a BuildIntent is accepted (D-06).

var _ctx: RunContext
var _pending: int = 0

@onready var _gold_label: Label = %GoldLabel


func bind_run(ctx: RunContext, map_root: MapRoot) -> void:
	_ctx = ctx
	var hold: BuildHoldController = map_root.get_build_hold()
	hold.hold_progress.connect(_on_hold_progress)
	hold.hold_cancelled.connect(_on_hold_cancelled)
	hold.hold_completed.connect(_on_hold_completed)
	ctx.events.gold_changed.connect(_on_gold_changed)
	_refresh()


func _on_hold_progress(_spot_id: StringName, coins_paid: int, _cost: int) -> void:
	_pending = coins_paid
	_refresh()


func _on_hold_cancelled(_spot_id: StringName, _coins_refunded: int) -> void:
	_pending = 0
	_refresh()


func _on_hold_completed(_spot_id: StringName) -> void:
	_pending = 0
	_refresh()


func _on_gold_changed(_new_amount: int, _delta: int) -> void:
	_refresh()


func _refresh() -> void:
	_gold_label.text = "Gold: %d" % (_ctx.economy.get_gold() - _pending)
