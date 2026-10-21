class_name KingState
extends RefCounted
## The king as the night simulation sees him: a position it is told, the weapon's passive attack it
## makes, the weapon's slam the player triggers and the health that makes him mortal. Movement stays
## in presentation (the King node) or in a scripted bot; both feed the position in through
## `report_position`, the only position input (DR-10).
##
## Knockout rules (D-01 to D-06): at 0 health the king is down for a countdown of whole ticks,
## SimClock.ticks(LoopTuning.respawn_seconds(n)) for the nth knockout of the night; while down he
## ignores position reports, attacks nothing and takes no damage; when the countdown ends he stands
## at the spawn with full health. A knockout costs nothing but that time, and dawn restores his
## health fully.
##
## Regeneration (D-20, KING-05): SimClock.ticks(regen_delay_seconds) steps after the last hit taken
## he regains regen_fraction_per_second of his maximum health per second, as whole points through a
## float accumulator (`+ - * /` only, DR-7), until full, by day and by night, and never while he is
## down. Every hit restarts the delay and drops the partial point; a respawn and the dawn still
## return full health. A fraction that is zero, negative or not finite switches it off.
##
## The slam (D-17, D-19): CommandProcessor validates the press and calls `activate_ability`, which
## starts the cooldown of SimClock.ticks(slam_cooldown_seconds) and arms the slam. The next
## `resolve_ability` (the night step, or the day step when it is day) queues one hit of slam_damage
## on every living enemy whose centre is within slam_radius (inclusive, ascending id), with the king
## as attacker, and emits king_ability_used. The cooldown is a countdown that `tick_timers` runs
## once per simulation step in every phase (DR-3: counters, no tick base).

## Guards the floor of the regeneration accumulator against float noise: 0.9999999999999999 of a
## point is a point (a quantisation guard, not a tuning value).
const REGEN_EPSILON: float = 0.000001

var _def: KingDef
var _weapon: WeaponDef
var _events: SimEvents
var _tuning: LoopTuning
var _stats: StatStack
var _spawn: Vector2
var _position: Vector2
var _cooldown_ready_tick: int = 0
var _health: int
var _down: bool = false
var _respawn_ticks_left: int = 0
var _knockouts_this_night: int = 0
var _knockouts_total: int = 0
var _ability_ticks_left: int = 0
var _ability_total_ticks: int = 0
var _slam_pending: bool = false
var _regen_delay_ticks_left: int = 0
var _regen_progress: float = 0.0


func _init(
	def: KingDef,
	spawn: Vector2,
	events: SimEvents,
	tuning: LoopTuning = null,
	stat_stack: StatStack = null
) -> void:
	_def = def
	_weapon = def.weapon if def.weapon != null else WeaponDef.new()
	_spawn = spawn
	_position = spawn
	_events = events
	_tuning = tuning if tuning != null else LoopTuning.new()
	_stats = stat_stack if stat_stack != null else StatStack.new()
	_health = get_max_health()
	_stats.changed.connect(_on_stats_changed)


func get_def() -> KingDef:
	return _def


## The weapon he carries: the def's, or the WeaponDef defaults when the def has none.
func get_weapon() -> WeaponDef:
	return _weapon


## Runs the king's countdowns by one simulation step: the slam cooldown and the regeneration.
## RunContext.step calls it once per step in every phase, so both run by day and by night.
func tick_timers() -> void:
	if _ability_ticks_left > 0:
		_ability_ticks_left -= 1
	_regenerate()


## True when the weapon has a usable slam (WeaponDef.is_slam_armed).
func has_ability() -> bool:
	return _weapon.is_slam_armed()


## Whole ticks until the slam can be used again; 0 when it is ready.
func ability_ticks_left() -> int:
	return _ability_ticks_left


## How far the slam has recharged: 0.0 right after use, 1.0 when ready. A king with no slam reads
## 1.0, so a widget never shows a cooldown that does not exist.
func ability_cooldown_ratio() -> float:
	if not has_ability() or _ability_ticks_left <= 0 or _ability_total_ticks <= 0:
		return 1.0
	return 1.0 - float(_ability_ticks_left) / float(_ability_total_ticks)


## Starts the slam cooldown and arms the slam for the next step. CommandProcessor calls this after
## it has checked the run, the weapon, the king and the cooldown; a king with no slam ignores it.
func activate_ability() -> void:
	if not has_ability():
		return
	_ability_total_ticks = SimClock.ticks(_weapon.slam_cooldown_seconds)
	_ability_ticks_left = _ability_total_ticks
	_slam_pending = true


## Resolves an armed slam: one hit of slam_damage on every living enemy whose centre is within
## slam_radius (inclusive), in ascending id, then king_ability_used with the count. It enqueues
## only enemy hits, so squads, buildings and the castle are never touched, and a slam killing an
## enemy pays nothing. It emits no attack_fired (the slash is the passive's). A king who went down
## since the press drops the slam. With nothing armed it does nothing.
func resolve_ability(tick: int, enemies: EnemySystem, hits: PendingHits) -> void:
	if not _slam_pending:
		return
	_slam_pending = false
	if _down:
		return
	var limit: float = _weapon.slam_radius * _weapon.slam_radius
	var struck: int = 0
	for id: int in enemies.ids():
		if not enemies.is_alive(id):
			continue
		if _position.distance_squared_to(enemies.position_of(id)) <= limit:
			hits.enqueue(
				tick,
				PendingHits.KIND_KING,
				0,
				PendingHits.KIND_ENEMY,
				id,
				_stats.int_value(&"king.slam_damage", _weapon.slam_damage)
			)
			struck += 1
	_events.king_ability_used.emit(struck)


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
	return _stats.int_value(&"king.max_health", maxi(_def.max_health, 1))


## True from the hit that takes him to 0 until he respawns.
func is_down() -> bool:
	return _down


## Removes up to `amount` hit points (never below 0) and emits king_damaged with the points
## actually lost. The hit that reaches 0 knocks him out: the knockout counters grow, the countdown
## starts and king_downed fires, once. Ignored while he is down and for a non-positive amount.
func take_damage(amount: int) -> void:
	if _down or amount <= 0:
		return
	amount = _stats.int_value(&"king.damage_taken", amount)
	var lost: int = mini(amount, _health)
	_health -= lost
	_regen_delay_ticks_left = _regen_delay_ticks()
	_regen_progress = 0.0
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
	_regen_progress = 0.0
	if _down:
		_respawn()


## A new night: the passive attack is ready at once and the night's knockout count starts over.
func begin_night() -> void:
	_cooldown_ready_tick = 0
	_knockouts_this_night = 0


## One night step. While down it only runs the countdown (and drops a slam armed before he fell);
## when that ends he respawns. Otherwise he attacks the nearest enemy in range when the cooldown
## has elapsed, then resolves an armed slam. The hits arrive this very tick, so they resolve with
## the others before dead enemies are removed. With no enemy in range nothing happens and no
## cooldown is consumed, so an enemy entering range is hit that same tick.
func step(tick: int, enemies: EnemySystem, hits: PendingHits) -> void:
	if _down:
		_slam_pending = false
		_respawn_ticks_left -= 1
		if _respawn_ticks_left <= 0:
			_respawn()
		return
	_passive_attack(tick, enemies, hits)
	resolve_ability(tick, enemies, hits)


## One step of regeneration: skipped while down, at full health or with the feature off; counts the
## delay down, then adds the share of one step to the accumulator and heals its whole points, capped
## at the missing health. king_healed is emitted only when the integer health changed.
func _regenerate() -> void:
	var fraction: float = _def.regen_fraction_per_second
	var max_hp: int = get_max_health()
	if _down or _health >= max_hp or not is_finite(fraction) or fraction <= 0.0:
		_regen_progress = 0.0
		return
	if _regen_delay_ticks_left > 0:
		_regen_delay_ticks_left -= 1
		return
	_regen_progress += float(max_hp) * fraction * SimClock.STEP
	var gained: int = mini(floori(_regen_progress + REGEN_EPSILON), max_hp - _health)
	if gained <= 0:
		return
	_regen_progress -= float(gained)
	_health += gained
	if _health >= max_hp:
		_regen_progress = 0.0
	_events.king_healed.emit(gained, _health, max_hp)


## The delay after a hit in whole ticks; a negative or non-finite delay counts as none.
func _regen_delay_ticks() -> int:
	var seconds: float = _def.regen_delay_seconds
	if not is_finite(seconds) or seconds <= 0.0:
		return 0
	return SimClock.ticks(seconds)


func _passive_attack(tick: int, enemies: EnemySystem, hits: PendingHits) -> void:
	if tick < _cooldown_ready_tick:
		return
	var target_id: int = TargetQuery.nearest_enemy(enemies, _position, _weapon.attack_range)
	if target_id < 0:
		return
	hits.enqueue(
		tick,
		PendingHits.KIND_KING,
		0,
		PendingHits.KIND_ENEMY,
		target_id,
		_stats.int_value(&"king.attack_damage", _weapon.attack_damage)
	)
	_events.attack_fired.emit(PendingHits.KIND_KING, 0, PendingHits.KIND_ENEMY, target_id, 0)
	var interval: float = _stats.float_value(&"king.attack_interval", _weapon.attack_interval)
	_cooldown_ready_tick = tick + SimClock.ticks(interval)


## A change of king.max_health (a pick, a buff): the gain raises current health by the gain of the
## maximum and a loss clamps it into [1, max]. A downed king stays at 0 (the respawn restores him to
## the new maximum). Emits nothing: a refresh is neither a hit nor a heal.
func _on_stats_changed(stats: Array[StringName]) -> void:
	if _down or not stats.has(&"king.max_health"):
		return
	var base: int = maxi(_def.max_health, 1)
	var gain: int = _stats.int_value(&"king.max_health", base)
	gain -= _stats.previous_int_value(&"king.max_health", base)
	_health = clampi(_health + gain, 1, get_max_health())


## Up again at the spawn with full health. His attack is ready at once.
func _respawn() -> void:
	_down = false
	_respawn_ticks_left = 0
	_position = _spawn
	_health = get_max_health()
	_regen_progress = 0.0
	_cooldown_ready_tick = 0
	_events.king_respawned.emit()
