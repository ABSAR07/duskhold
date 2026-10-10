class_name DayCounter
extends CenterContainer
## UI-01 / D-21: "Night 3 of 8" top-centre, the next night out of the map's total. It shows by day
## and at dawn and hides while the night banner shows (and once the run is over); a map with no
## authored nights has no total, so it hides there too. Display only: it reads the run manager
## and never writes the simulation. Mouse input is ignored.

## "Night <next night> of <total>"; the number is the night the player is about to face.
const DAY_COUNTER_TEXT := "Night %d of %d"

var _ctx: RunContext

@onready var _label: Label = %DayCounterLabel


## Binds the counter to one run. A repeat call is ignored so no signal is connected twice.
func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	ctx.events.phase_changed.connect(_on_phase_changed)
	_refresh()


## The label the counter draws into, for layout tests.
func get_label() -> Label:
	return _label


## The text for a night out of a total, never above the total.
static func text_for(next_night: int, total_nights: int) -> String:
	return DAY_COUNTER_TEXT % [mini(next_night, total_nights), total_nights]


func _on_phase_changed(_old_phase: int, _new_phase: int) -> void:
	_refresh()


func _refresh() -> void:
	var run_manager: RunManager = _ctx.run_manager
	var total: int = run_manager.get_total_nights()
	var phase: int = run_manager.get_phase()
	var shows: bool = (
		total > 0 and (phase == RunManager.RunPhase.DAY or phase == RunManager.RunPhase.DAWN)
	)
	visible = shows
	if shows:
		_label.text = text_for(run_manager.get_night_number() + 1, total)
