class_name Hud
extends CanvasLayer
## Gold readout, the start-night prompt and the night banner. Gold is the only currency the HUD
## shows and its label is always visible (ECON-01).
## While a hold is dripping, the readout shows the gold the player would have left
## (Economy gold minus the coins in flight). This is display only: Economy stays
## all-or-nothing and only changes when a BuildIntent is accepted (D-06).
## At dawn the Economy is credited at once, but the readout stays behind by the gold whose coins
## are still flying in, and ticks up as each one lands (D-12).

var _ctx: RunContext
var _pending: int = 0
var _payout_pending: int = 0

@onready var _gold_label: Label = %GoldLabel
@onready var _start_night_prompt: Label = %StartNightPrompt
@onready var _start_night_fill: ProgressBar = %StartNightFill
@onready var _phase_banner: Label = %PhaseBanner
@onready var _payout_vfx: DawnPayoutVfx = %DawnPayoutVfx


func bind_run(ctx: RunContext, map_root: MapRoot) -> void:
	_ctx = ctx
	var hold: BuildHoldController = map_root.get_build_hold()
	hold.hold_progress.connect(_on_hold_progress)
	hold.hold_cancelled.connect(_on_hold_cancelled)
	hold.hold_completed.connect(_on_hold_completed)
	ctx.events.gold_changed.connect(_on_gold_changed)
	ctx.events.phase_changed.connect(_on_phase_changed)
	ctx.events.night_started.connect(_on_night_started)
	ctx.events.day_started.connect(_on_day_started)
	ctx.events.dawn_payout.connect(_on_dawn_payout)
	# Defensive: the vfx outlives a run, so its signal must never be connected twice even if
	# bind_run is called again on this HUD.
	if not _payout_vfx.coin_landed.is_connected(_on_coin_landed):
		_payout_vfx.coin_landed.connect(_on_coin_landed)
	var start_night_hold: StartNightHoldController = (
		map_root.find_child("StartNightHold", true, false) as StartNightHoldController
	)
	if start_night_hold != null:
		start_night_hold.progress_changed.connect(_on_start_night_progress)
	_refresh()
	_refresh_loop()


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


func _on_dawn_payout(total: int, _per_spot: Dictionary) -> void:
	_payout_pending = maxi(total, 0)
	_refresh()


func _on_coin_landed(amount: int) -> void:
	_payout_pending = maxi(_payout_pending - amount, 0)
	_refresh()


func _on_phase_changed(_old_phase: int, _new_phase: int) -> void:
	_refresh_loop()


func _on_night_started(_night_number: int) -> void:
	_refresh_loop()


func _on_day_started(_day_number: int) -> void:
	_refresh_loop()


func _on_start_night_progress(ratio: float) -> void:
	_start_night_fill.value = ratio


## The prompt shows only by day (D-11); the banner only during the night itself (D-12).
func _refresh_loop() -> void:
	var run_manager: RunManager = _ctx.run_manager
	var by_day: bool = run_manager.get_phase() == RunManager.RunPhase.DAY
	_start_night_prompt.visible = by_day
	_start_night_fill.visible = by_day
	if not by_day:
		_start_night_fill.value = 0.0
	_start_night_prompt.text = (
		"Hold N / (Y) to start Night %d" % (run_manager.get_night_number() + 1)
	)
	var at_night: bool = (
		run_manager.get_phase() == RunManager.RunPhase.NIGHT_TRANSITION
		or run_manager.get_phase() == RunManager.RunPhase.NIGHT
	)
	_phase_banner.visible = at_night
	_phase_banner.text = "Night %d — no enemies yet" % run_manager.get_night_number()


func _refresh() -> void:
	_gold_label.text = "Gold: %d" % maxi(_ctx.economy.get_gold() - _pending - _payout_pending, 0)
