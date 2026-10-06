class_name CastleAttack
extends RefCounted
## The castle's own attack (owner decision 2026-10-06, G-02-1 point 2: a simple attack, not too
## strong). While the castle stands it shoots the nearest enemy whose centre is within
## MapConfig.castle_attack_range, once per castle_attack_interval, as a pending hit that lands
## SimClock.flight_ticks(distance, castle_projectile_speed) ticks later on the enemy's id, like a
## tower arrow (RESEARCH Pattern 2). The shipped numbers (damage 2, reach 11 m, every 1.5 s) are
## meant to kill a grunt (6 hp) in three hits and a skirmisher (4 hp) in two, and the reach is
## castle_radius plus a skirmisher's attack_range plus a little, so the castle answers a skirmisher
## shooting at it from its stand-off.
##
## It is stepped by NightSim.step only, between the towers and the enemies (DR-8), so it never acts
## by day, at dawn or after the run ends. It is armed only when damage, range and interval are all
## above 0, so bad data can never make it fire every tick (T-02-33); with the fields at their
## default 0 it does nothing, which keeps every fixture and the smoke golden unchanged. The
## castle's attacker id in PendingHits is always 0.

var _map: MapConfig
var _castle: CastleState
var _events: SimEvents
## First night tick on which the castle may shoot again.
var _ready_at: int = 0


func _init(map: MapConfig, castle: CastleState, events: SimEvents) -> void:
	_map = map
	_castle = castle
	_events = events


## True when the map gives the castle a real attack: damage, range and interval all above 0.
func is_armed() -> bool:
	return (
		_map.castle_attack_damage > 0
		and _map.castle_attack_range > 0.0
		and _map.castle_attack_interval > 0.0
	)


## A new night: the castle is ready on night tick 0.
func begin_night() -> void:
	_ready_at = 0


## One night step. With no enemy in reach the castle does nothing and keeps its cooldown, so an
## enemy entering reach is shot on that same tick.
func step(tick: int, enemies: EnemySystem, hits: PendingHits) -> void:
	if not is_armed() or _castle.is_destroyed() or tick < _ready_at:
		return
	var origin: Vector2 = _castle.get_position()
	var target_id: int = TargetQuery.nearest_enemy(enemies, origin, _map.castle_attack_range)
	if target_id < 0:
		return
	var flight: int = SimClock.flight_ticks(
		origin.distance_to(enemies.position_of(target_id)), _map.castle_projectile_speed
	)
	hits.enqueue(
		tick + flight,
		PendingHits.KIND_CASTLE,
		0,
		PendingHits.KIND_ENEMY,
		target_id,
		_map.castle_attack_damage
	)
	_events.attack_fired.emit(PendingHits.KIND_CASTLE, 0, PendingHits.KIND_ENEMY, target_id, flight)
	_ready_at = tick + SimClock.ticks(_map.castle_attack_interval)
