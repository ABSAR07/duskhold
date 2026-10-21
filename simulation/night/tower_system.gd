class_name TowerSystem
extends RefCounted
## Tower fire control (D-13). Every standing building whose current tier has attack_damage above 0
## shoots the nearest enemy within the tier's attack_range, once per attack_interval. The arrow is
## a pending hit that lands SimClock.flight_ticks(distance, projectile_speed) ticks later on the
## enemy's id and is dropped if that enemy is already gone (RESEARCH Pattern 2). Towers are stepped
## in MapConfig spot order (DR-6), between the king and the enemies (DR-8).
##
## The Shrine (ECON-06) is a tower with a gate: a building whose income curve is AWAKENED is skipped
## unless IncomeState says it has woken, before any target query or enqueue, so a dormant Shrine
## never fires (research P4). Damage and reach are read through the stat ids the building names
## (BuildingDef.damage_stat and range_stat, tower.damage and tower.range for a tower), so a modifier
## on one kind never touches the other.

var _buildings: BuildingSystem
var _events: SimEvents
var _stats: StatStack
var _income: IncomeState
## spot_id -> first tick on which that tower may shoot again. A missing entry means ready.
var _ready_at: Dictionary = {}


func _init(
	buildings: BuildingSystem,
	events: SimEvents,
	stat_stack: StatStack = null,
	income: IncomeState = null
) -> void:
	_buildings = buildings
	_events = events
	_stats = stat_stack if stat_stack != null else StatStack.new()
	_income = income


## A new night: every tower is ready on night tick 0.
func begin_night() -> void:
	_ready_at.clear()


## One night step. A tower with no enemy in range does nothing and keeps its cooldown, so an enemy
## entering range is shot on that same tick.
func step(tick: int, enemies: EnemySystem, hits: PendingHits) -> void:
	for spot_id: StringName in _buildings.standing_spot_ids():
		var building_def: BuildingDef = _buildings.get_building_def_for_spot(spot_id)
		var tier: BuildingTierDef = _tier_of(building_def, spot_id)
		if tier == null or tier.attack_damage <= 0:
			continue
		if _is_dormant(building_def, spot_id):
			continue
		if tick < int(_ready_at.get(spot_id, 0)):
			continue
		var spot_position: Vector3 = _buildings.get_spot(spot_id).position
		var origin: Vector2 = Vector2(spot_position.x, spot_position.z)
		var reach: float = _stats.float_value(building_def.range_stat, tier.attack_range)
		var target_id: int = TargetQuery.nearest_enemy(enemies, origin, reach)
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
			_stats.int_value(building_def.damage_stat, tier.attack_damage)
		)
		_events.attack_fired.emit(
			PendingHits.KIND_BUILDING, spot_index, PendingHits.KIND_ENEMY, target_id, flight
		)
		_ready_at[spot_id] = tick + SimClock.ticks(tier.attack_interval)


func _tier_of(building_def: BuildingDef, spot_id: StringName) -> BuildingTierDef:
	if building_def == null:
		return null
	return building_def.tier_def(_buildings.current_tier(spot_id))


## True for an AWAKENED building (the Shrine) that has not woken, or when nobody can say it has.
func _is_dormant(building_def: BuildingDef, spot_id: StringName) -> bool:
	if building_def.income_curve != BuildingDef.IncomeCurve.AWAKENED:
		return false
	return _income == null or not _income.is_awake(spot_id)
