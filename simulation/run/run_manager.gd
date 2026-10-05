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
var _castle: CastleState
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
	king: KingState = null,
	castle: CastleState = null
) -> void:
	_events = events
	_economy = economy
	_buildings = buildings
	_tuning = tuning
	_night = night
	_king = king
	_castle = castle


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


## True when the map authors no nights of its own: the night is then the Phase 1 timed night that
## ends on a clock. A map with authored nights plays real nights that end when the wave is cleared.
func is_timed_night() -> bool:
	return _night == null or not _night.has_authored_nights()


## Seconds left in the current timed phase: the Phase 1 timed night or dawn. A real night has no
## clock, and the day has none either, so both report 0.0.
func get_phase_time_remaining() -> float:
	match _phase:
		RunPhase.NIGHT:
			if not is_timed_night():
				return 0.0
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
	_buildings.clear_rebuilt_marks()
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


## The night is over. What fell is rebuilt for free (LOOP-04), everything that stands and the castle
## are repaired, the king is whole again, and only then are the survivors paid (LOOP-05).
func _enter_dawn() -> void:
	_change_phase(RunPhase.DAWN)
	if _night != null:
		_night.end_night()
	var rebuilt: Array[StringName] = _buildings.rebuild_destroyed()
	_buildings.repair_standing()
	if _castle != null:
		_castle.repair()
	if _king != null:
		_king.restore_for_dawn()
	_events.buildings_rebuilt.emit(rebuilt)
	_apply_dawn_payout()


func _enter_day() -> void:
	_day_number += 1
	_change_phase(RunPhase.DAY)
	_events.day_started.emit(_day_number)


## Pays each standing House its current tier's income, exactly once per DAWN entry (ECON-02). A
## building rebuilt this dawn pays nothing (LOOP-05): BuildingSystem leaves it out of the income it
## reports. Nothing here or at day start resets or rebases gold, so unspent gold carries over
## (ECON-07).
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
