class_name TowerSystem
extends RefCounted
## Tower fire control (D-13). Every standing building whose current tier has attack_damage above 0
## shoots the nearest enemy within the tier's attack_range, once per attack_interval. The arrow is
## a pending hit that lands SimClock.flight_ticks(distance, projectile_speed) ticks later on the
## enemy's id and is dropped if that enemy is already gone (RESEARCH Pattern 2). Towers are stepped
## in MapConfig spot order (DR-6), between the king and the enemies (DR-8).

var _buildings: BuildingSystem
var _events: SimEvents
## spot_id -> first tick on which that tower may shoot again. A missing entry means ready.
var _ready_at: Dictionary = {}


func _init(buildings: BuildingSystem, events: SimEvents) -> void:
	_buildings = buildings
	_events = events


## A new night: every tower is ready on night tick 0.
func begin_night() -> void:
	_ready_at.clear()


## One night step. A tower with no enemy in range does nothing and keeps its cooldown, so an enemy
## entering range is shot on that same tick.
func step(tick: int, enemies: EnemySystem, hits: PendingHits) -> void:
	for spot_id: StringName in _buildings.standing_spot_ids():
		var tier: BuildingTierDef = _current_tier(spot_id)
		if tier == null or tier.attack_damage <= 0:
			continue
		if tick < int(_ready_at.get(spot_id, 0)):
			continue
		var spot_position: Vector3 = _buildings.get_spot(spot_id).position
		var origin: Vector2 = Vector2(spot_position.x, spot_position.z)
		var target_id: int = TargetQuery.nearest_enemy(enemies, origin, tier.attack_range)
		if target_id < 0:
			continue
		var flight: int = SimClock.flight_ticks(
			origin.distance_to(enemies.position_of(target_id)), tier.projectile_speed
		)
		var spot_index: int = _buildings.spot_index(spot_id)
		hits.enqueue(
			tick + flight,
			PendingHits.KIND_BUILDING,
			spot_index,
			PendingHits.KIND_ENEMY,
			target_id,
			tier.attack_damage
		)
		_events.attack_fired.emit(
			PendingHits.KIND_BUILDING, spot_index, PendingHits.KIND_ENEMY, target_id, flight
		)
		_ready_at[spot_id] = tick + SimClock.ticks(tier.attack_interval)


func _current_tier(spot_id: StringName) -> BuildingTierDef:
	var building_def: BuildingDef = _buildings.get_building_def_for_spot(spot_id)
	if building_def == null:
		return null
	return building_def.tier_def(_buildings.current_tier(spot_id))
