class_name RunManager
extends RefCounted
## Sole owner of the run phase. `tick` is the only time source for the simulation.
## Plan 01-08 adds start_night and the timed NIGHT and DAWN phases to this same class.

enum RunPhase { DAY, NIGHT_TRANSITION, NIGHT, DAWN }

var _events: SimEvents
var _phase: RunPhase = RunPhase.DAY
var _elapsed: float = 0.0


func _init(events: SimEvents) -> void:
	_events = events


func get_phase() -> RunPhase:
	return _phase


func is_build_allowed() -> bool:
	return _phase == RunPhase.DAY


## Simulation seconds since the run started.
func get_elapsed() -> float:
	return _elapsed


## Advances simulation time. No timed phase is active yet, so only the clock moves.
func tick(delta: float) -> void:
	_elapsed += maxf(delta, 0.0)
