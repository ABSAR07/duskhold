class_name ResultsScreen
extends CanvasLayer
## The end-of-run screen (D-15, D-16, D-17): the outcome and the run's stats with Play again and
## Quit, and nothing else (no score or reward). A victory shows it at once; a defeat first lets the
## frozen collapse of the castle play for `loss_beat_seconds` of real time. It only reads RunStats
## and the run's phase and emits its two button signals; MapRoot decides what they do. The buttons
## take keyboard and gamepad focus (Play again first), and the mouse may click them.
##
## The build key (Space, gamepad A) is also ui_accept, so a player still tapping it as the run ends
## would press the focused Play again and lose the screen before reading it (review WR-03). For
## `LoopTuning.results_input_grace_seconds` of real time after the screen appears (at most
## MAX_GRACE_S) both buttons ignore every press, from any device; the focus and the look of the
## screen are unchanged, and once the window is over all three devices work as before (D-16). A
## Button emits `pressed` when the press is released, so what is gated is when the press began
## (`button_down`): a press that starts inside the window and is let go after it does nothing too.

signal play_again_pressed
signal quit_pressed

## Player-facing copy. The nights line counts the nights survived out of the map's total.
const VICTORY_TEXT := "Victory"
const DEFEAT_TEXT := "Defeat"
const NIGHTS_TEXT := "Nights survived: %d of %d"
const GOLD_TEXT := "Gold earned: %d"
const BUILDINGS_LOST_TEXT := "Buildings lost: %d"
const KNOCKOUTS_TEXT := "King knockouts: %d"

## Cap on the input grace, in seconds. A typo in the data (60 for 0.6) would otherwise leave both
## buttons dead for that long with nothing on screen to say why; no tap or hold lasts this long.
const MAX_GRACE_S: float = 3.0

var _ctx: RunContext
var _scheduled: bool = false
var _showing: bool = false
## Real time (Time.get_ticks_msec) from which presses are taken; set when the screen appears.
var _accept_from_ms: int = 0
## Real time at which the latest press on either button began; -1 until one has.
var _down_ms: int = -1

@onready var _outcome_label: Label = %OutcomeLabel
@onready var _nights_label: Label = %NightsLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _buildings_lost_label: Label = %BuildingsLostLabel
@onready var _knockouts_label: Label = %KnockoutsLabel
@onready var _play_again_button: Button = %PlayAgainButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	_play_again_button.pressed.connect(_on_play_again_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_play_again_button.button_down.connect(_on_button_down)
	_quit_button.button_down.connect(_on_button_down)


## Binds the screen to one run. MapRoot calls this once; a repeat call is ignored so no signal is
## ever connected twice.
func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	ctx.events.run_ended.connect(_on_run_ended)


## True from the moment the screen is up until the scene goes away.
func is_showing() -> bool:
	return _showing


## True once the screen is up and its input grace window is over: only then do the buttons act.
func accepts_input() -> bool:
	return _showing and Time.get_ticks_msec() >= _accept_from_ms


## The screen shows at most once per run, whatever run_ended is told afterwards.
func _on_run_ended(outcome: StringName) -> void:
	if _scheduled:
		return
	_scheduled = true
	if outcome == &"victory":
		_show_results(outcome)
		return
	# The beat is real time that ignores the engine's time scale and keeps running if the tree is
	# paused; the simulation is already frozen, so only the presentation plays through it.
	var beat: SceneTreeTimer = get_tree().create_timer(
		maxf(_ctx.tuning.loss_beat_seconds, 0.0), true, false, true
	)
	beat.timeout.connect(_show_results.bind(outcome))


func _show_results(outcome: StringName) -> void:
	if _showing:
		return
	_showing = true
	var grace_s: float = clampf(_ctx.tuning.results_input_grace_seconds, 0.0, MAX_GRACE_S)
	var grace_ms: int = roundi(grace_s * 1000.0)
	_accept_from_ms = Time.get_ticks_msec() + grace_ms
	_outcome_label.text = VICTORY_TEXT if outcome == &"victory" else DEFEAT_TEXT
	var stats: RunStats = _ctx.stats
	_nights_label.text = (
		NIGHTS_TEXT % [stats.nights_survived(), _ctx.run_manager.get_total_nights()]
	)
	_gold_label.text = GOLD_TEXT % stats.gold_earned()
	_buildings_lost_label.text = BUILDINGS_LOST_TEXT % stats.buildings_lost()
	_knockouts_label.text = KNOCKOUTS_TEXT % stats.king_knockouts()
	visible = true
	_play_again_button.grab_focus()


func _on_button_down() -> void:
	_down_ms = Time.get_ticks_msec()


## A press counts only if the screen is taking input now and the press began after the window.
func _press_counts() -> bool:
	return accepts_input() and _down_ms >= _accept_from_ms


func _on_play_again_pressed() -> void:
	if _press_counts():
		play_again_pressed.emit()


func _on_quit_pressed() -> void:
	if _press_counts():
		quit_pressed.emit()
