class_name Hud
extends CanvasLayer
## Gold readout. Gold is the only currency the HUD shows.

@onready var _gold_label: Label = %GoldLabel


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	_set_gold(ctx.economy.get_gold())
	ctx.events.gold_changed.connect(_on_gold_changed)


func _on_gold_changed(new_amount: int, _delta: int) -> void:
	_set_gold(new_amount)


func _set_gold(amount: int) -> void:
	_gold_label.text = "Gold: %d" % amount
