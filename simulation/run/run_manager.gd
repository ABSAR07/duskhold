class_name RunManager
extends RefCounted
## Sole owner of the run phase. `tick` is the only time source for the simulation.
## The loop is DAY -> NIGHT_TRANSITION -> NIGHT -> DAWN -> DAY. It leaves DAY only through
## `start_night` (the deliberate hold-to-confirm input, D-11) and makes at most one phase change
## per `tick`. Phase 2 fills the same NIGHT and DAWN states with real waves instead of replacing
## them: `_night_should_end` now owns the body of LOOP-03 (a night ends when the NightSim reports it
## cleared), and a map with no authored nights keeps the Phase 1 timed night.

enum RunPhase { DAY, NIGHT_TRANSITION, NIGHT, DAWN }

var _events: SimEvents
var _economy: Economy
var _buildings: BuildingSystem
var _tuning: LoopTuning
var _night: NightSim
var _king: KingState
var _phase: RunPhase = RunPhase.DAY
var _elapsed: float = 0.0
var _phase_elapsed: float = 0.0
var _day_number: int = 1
var _night_number: int = 0


func _init(
	events: SimEvents,
	economy: Economy,
	buildings: BuildingSystem,
	tuning: LoopTuning,
	night: NightSim = null,
	king: KingState = null
) -> void:
	_events = events
	_economy = economy
	_buildings = buildings
	_tuning = tuning
	_night = night
	_king = king


func get_phase() -> RunPhase:
	return _phase


func is_build_allowed() -> bool:
	return _phase == RunPhase.DAY


## Simulation seconds since the run started.
func get_elapsed() -> float:
	return _elapsed


## 1 on the first day; grows by one each time dawn hands over to a new day.
func get_day_number() -> int:
	return _day_number


## Number of nights started so far (0 before the first).
func get_night_number() -> int:
	return _night_number


func is_timed_night() -> bool:
	return false


## Seconds left in the current timed phase (NIGHT or DAWN); 0.0 by day.
func get_phase_time_remaining() -> float:
	match _phase:
		RunPhase.NIGHT:
			return maxf(_tuning.placeholder_night_seconds - _phase_elapsed, 0.0)
		RunPhase.DAWN:
			return maxf(_tuning.dawn_seconds - _phase_elapsed, 0.0)
	return 0.0


## Ends the day. Only legal from DAY; returns false and changes nothing otherwise. The night's
## waves are loaded here, so NIGHT_TRANSITION passes through to NIGHT within the same call.
func start_night() -> bool:
	if _phase != RunPhase.DAY:
		return false
	_night_number += 1
	_change_phase(RunPhase.NIGHT_TRANSITION)
	_change_phase(RunPhase.NIGHT)
	if _night != null:
		_night.begin_night(_night_number)
	_events.night_started.emit(_night_number)
	return true


## Advances simulation time and performs at most one phase transition.
func tick(delta: float) -> void:
	var step: float = maxf(delta, 0.0)
	_elapsed += step
	match _phase:
		RunPhase.NIGHT:
			_phase_elapsed += step
			if _night_should_end():
				_enter_dawn()
		RunPhase.DAWN:
			_phase_elapsed += step
			if _phase_elapsed >= _tuning.dawn_seconds:
				_enter_day()


## LOOP-03: on a map with authored nights the night ends only when every group has finished
## spawning and every enemy is dead. A waveless map keeps the Phase 1 enemy-free timed night (D-12).
func _night_should_end() -> bool:
	if _night != null and _night.has_authored_nights():
		return _night.is_cleared()
	return _phase_elapsed >= _tuning.placeholder_night_seconds


func _enter_dawn() -> void:
	_change_phase(RunPhase.DAWN)
	if _night != null:
		_night.end_night()
	if _king != null:
		_king.restore_for_dawn()
	_apply_dawn_payout()


func _enter_day() -> void:
	_day_number += 1
	_change_phase(RunPhase.DAY)
	_events.day_started.emit(_day_number)


## Pays each House its current tier's income, exactly once per DAWN entry (ECON-02). Nothing here
## or at day start resets or rebases gold, so unspent gold carries over (ECON-07). Phase 2 extends
## this with the dawn rebuild (LOOP-04) and the rule that rebuilt buildings pay nothing (LOOP-05).
func _apply_dawn_payout() -> void:
	var per_spot: Dictionary = _buildings.dawn_income_by_spot()
	var total: int = 0
	for amount: int in per_spot.values():
		total += amount
	if total > 0:
		_economy.grant(total)
	_events.dawn_payout.emit(total, per_spot)


func _change_phase(new_phase: RunPhase) -> void:
	var old_phase: RunPhase = _phase
	_phase = new_phase
	_phase_elapsed = 0.0
	_events.phase_changed.emit(old_phase, new_phase)
