class_name KingState
extends RefCounted
## The king as the night simulation sees him: a position it is told, a passive attack it makes and
## the health that makes him mortal. Movement stays in presentation (the King node) or in a scripted
## bot; both feed the position in through `report_position`, the only position input (DR-10).
##
## Knockout rules (D-01 to D-06): at 0 health the king is down for a countdown of whole ticks,
## SimClock.ticks(LoopTuning.respawn_seconds(n)) for the nth knockout of the night; while down he
## ignores position reports, attacks nothing and takes no damage; when the countdown ends he stands
## at the spawn with full health. A knockout costs nothing but that time, health never regenerates
## during a night (KING-05 is Phase 3) and dawn restores it fully.

var _def: KingDef
var _events: SimEvents
var _tuning: LoopTuning
var _spawn: Vector2
var _position: Vector2
var _cooldown_ready_tick: int = 0
var _health: int
var _down: bool = false
var _respawn_ticks_left: int = 0
var _knockouts_this_night: int = 0
var _knockouts_total: int = 0


func _init(def: KingDef, spawn: Vector2, events: SimEvents, tuning: LoopTuning = null) -> void:
	_def = def
	_spawn = spawn
	_position = spawn
	_events = events
	_tuning = tuning if tuning != null else LoopTuning.new()
	_health = maxi(def.max_health, 1)


func get_def() -> KingDef:
	return _def


## Where the king stands, in XZ metres. Ignored while he is down (T-02-06).
func report_position(pos: Vector2) -> void:
	if _down:
		return
	_position = pos


func get_position() -> Vector2:
	return _position


func get_health() -> int:
	return _health


func get_max_health() -> int:
	return maxi(_def.max_health, 1)


## True from the hit that takes him to 0 until he respawns.
func is_down() -> bool:
	return _down


## Removes up to `amount` hit points (never below 0) and emits king_damaged with the points
## actually lost. The hit that reaches 0 knocks him out: the knockout counters grow, the countdown
## starts and king_downed fires, once. Ignored while he is down and for a non-positive amount.
func take_damage(amount: int) -> void:
	if _down or amount <= 0:
		return
	var lost: int = mini(amount, _health)
	_health -= lost
	_events.king_damaged.emit(lost, _health, get_max_health())
	if _health > 0:
		return
	_down = true
	_knockouts_this_night += 1
	_knockouts_total += 1
	_respawn_ticks_left = SimClock.ticks(_tuning.respawn_seconds(_knockouts_this_night))
	_events.king_downed.emit(_respawn_ticks_left, _knockouts_this_night)


## Seconds until he is back; 0.0 while he is up. Whole ticks times the step, so it never reads 0
## while a tick is left (the HUD rounds it up).
func respawn_seconds_remaining() -> float:
	if not _down:
		return 0.0
	return SimClock.seconds(_respawn_ticks_left)


## Knockouts since the current night began.
func knockouts_this_night() -> int:
	return _knockouts_this_night


## Knockouts since the run began.
func knockouts_total() -> int:
	return _knockouts_total


## Dawn: full health, and back at the spawn if he was still down. Emits king_respawned only in the
## second case; an up king is healed in place.
func restore_for_dawn() -> void:
	_health = get_max_health()
	if _down:
		_respawn()


## A new night: the passive attack is ready at once and the night's knockout count starts over.
func begin_night() -> void:
	_cooldown_ready_tick = 0
	_knockouts_this_night = 0


## One night step. While down it only runs the countdown; when that ends he respawns. Otherwise he
## attacks the nearest enemy in range when the cooldown has elapsed. The hit arrives this very
## tick, so it resolves with the others before dead enemies are removed. With no enemy in range
## nothing happens and no cooldown is consumed, so an enemy entering range is hit that same tick.
func step(tick: int, enemies: EnemySystem, hits: PendingHits) -> void:
	if _down:
		_respawn_ticks_left -= 1
		if _respawn_ticks_left <= 0:
			_respawn()
		return
	if tick < _cooldown_ready_tick:
		return
	var target_id: int = TargetQuery.nearest_enemy(enemies, _position, _def.attack_range)
	if target_id < 0:
		return
	hits.enqueue(
		tick, PendingHits.KIND_KING, 0, PendingHits.KIND_ENEMY, target_id, _def.attack_damage
	)
	_events.attack_fired.emit(PendingHits.KIND_KING, 0, PendingHits.KIND_ENEMY, target_id, 0)
	_cooldown_ready_tick = tick + SimClock.ticks(_def.attack_interval)


## Up again at the spawn with full health. His attack is ready at once.
func _respawn() -> void:
	_down = false
	_respawn_ticks_left = 0
	_position = _spawn
	_health = get_max_health()
	_cooldown_ready_tick = 0
	_events.king_respawned.emit()
