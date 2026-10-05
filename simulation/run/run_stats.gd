class_name RunStats
extends RefCounted
## The numbers the results screen shows (D-15), counted from the run's own events. A read-only
## listener: it only connects to SimEvents, and never emits or changes any simulation state.
## Nights survived counts every night that ended in dawn or in victory, so a run lost during night n
## has survived n - 1. Gold earned is the sum of every dawn payout (a victory pays no last dawn).

var _nights_survived: int = 0
var _gold_earned: int = 0
var _buildings_lost: int = 0
var _king_knockouts: int = 0
var _outcome: StringName = &""


func _init(events: SimEvents) -> void:
	events.phase_changed.connect(_on_phase_changed)
	events.dawn_payout.connect(_on_dawn_payout)
	events.building_destroyed.connect(_on_building_destroyed)
	events.king_downed.connect(_on_king_downed)
	events.run_ended.connect(_on_run_ended)


func nights_survived() -> int:
	return _nights_survived


func gold_earned() -> int:
	return _gold_earned


func buildings_lost() -> int:
	return _buildings_lost


func king_knockouts() -> int:
	return _king_knockouts


## &"victory" or &"defeat" once the run has ended; &"" until then.
func outcome() -> StringName:
	return _outcome


func _on_phase_changed(old_phase: int, new_phase: int) -> void:
	if old_phase != RunManager.RunPhase.NIGHT:
		return
	if new_phase == RunManager.RunPhase.DAWN or new_phase == RunManager.RunPhase.WON:
		_nights_survived += 1


func _on_dawn_payout(total: int, _per_spot: Dictionary) -> void:
	_gold_earned += total


func _on_building_destroyed(_spot_id: StringName, _building_id: StringName, _tier: int) -> void:
	_buildings_lost += 1


func _on_king_downed(_respawn_ticks: int, _knockout_number: int) -> void:
	_king_knockouts += 1


func _on_run_ended(outcome: StringName) -> void:
	_outcome = outcome
