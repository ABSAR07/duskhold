class_name CastleState
extends RefCounted
## The castle's health and numbers. Integer hit points from MapConfig.castle_max_health; the castle
## is the one thing the night is lost on, so `castle_destroyed` fires exactly once, at the hit that
## takes the last point. What the loss does (the results screen) arrives with the run-end plan; this
## class only reports it.
##
## Every castle number a bonus can touch is read through the stat stack here (META-08): maximum
## health, arrow damage and reach, and the gold it pays at dawn. A change of the maximum raises
## current health by the gain, as for every health stat.
##
## The castle is also a plot (BLDG-08, D-01, D-04): a spot marked BuildSpotDef.is_castle whose
## building (castle_center) has four tiers. Tier I is the map's own castle fields (health, arrow,
## base income), so no number has two homes; tiers II to IV take their health, arrow damage, reach,
## interval, speed and dawn income from the tier data when the plot's upgrade is built. A map with
## no castle plot has no tiers and keeps every MapConfig number.

var _position: Vector2
var _radius: float
var _health: int
var _max_health: int
var _destroyed: bool = false
var _events: SimEvents
var _map: MapConfig
var _stats: StatStack
var _plot_id: StringName = &""
var _def: BuildingDef
var _tier: int = 0


func _init(map: MapConfig, events: SimEvents, stat_stack: StatStack = null) -> void:
	_map = map
	_position = Vector2(map.castle_position.x, map.castle_position.z)
	_radius = map.castle_radius
	_events = events
	_stats = stat_stack if stat_stack != null else StatStack.new()
	_find_castle_plot(map)
	_max_health = _stat_max_health()
	_health = _max_health
	_stats.changed.connect(_on_stats_changed)
	events.building_built.connect(_on_building_built)


## Where the castle centre stands, in XZ metres.
func get_position() -> Vector2:
	return _position


func get_radius() -> float:
	return _radius


## True when the map has a castle plot, so the castle has tiers.
func has_tiers() -> bool:
	return _tier > 0


## The castle's tier, 1 to 4; 0 on a map with no castle plot.
func tier() -> int:
	return _tier


## The castle plot's spot id; empty on a map with no castle plot.
func plot_id() -> StringName:
	return _plot_id


func get_health() -> int:
	return _health


func get_max_health() -> int:
	return _max_health


func is_destroyed() -> bool:
	return _destroyed


## Removes up to `amount` hit points (never below 0) and emits castle_damaged with the points
## actually lost; the hit that reaches 0 then emits castle_destroyed, once. A hit on a destroyed
## castle, or a non-positive amount, is dropped.
func damage(amount: int) -> void:
	if _destroyed or amount <= 0:
		return
	var lost: int = mini(amount, _health)
	_health -= lost
	_events.castle_damaged.emit(lost, _health, _max_health)
	if _health == 0:
		_destroyed = true
		_events.castle_destroyed.emit()


## Full health again (the dawn repair). Clears the destroyed flag; emits nothing.
func repair() -> void:
	_health = _max_health
	_destroyed = false


## Damage of one castle arrow: the tier's attack_damage (tier I and a map with no castle plot: the
## map's castle_attack_damage) through castle.arrow_damage.
func arrow_damage() -> int:
	var tier_def: BuildingTierDef = _upgraded_tier()
	var base: int = tier_def.attack_damage if tier_def != null else _map.castle_attack_damage
	return _stats.int_value(&"castle.arrow_damage", base)


## Reach of the castle arrow in metres: the tier's attack_range (tier I: the map's
## castle_attack_range) through castle.arrow_range.
func arrow_range() -> float:
	var tier_def: BuildingTierDef = _upgraded_tier()
	var base: float = tier_def.attack_range if tier_def != null else _map.castle_attack_range
	return _stats.float_value(&"castle.arrow_range", base)


## Seconds between castle arrows: the tier's attack_interval (tier I: the map's
## castle_attack_interval); no stat touches it.
func arrow_interval() -> float:
	var tier_def: BuildingTierDef = _upgraded_tier()
	return tier_def.attack_interval if tier_def != null else _map.castle_attack_interval


## Metres per second of a castle arrow: the tier's projectile_speed (tier I: the map's
## castle_projectile_speed); no stat touches it.
func arrow_speed() -> float:
	var tier_def: BuildingTierDef = _upgraded_tier()
	return tier_def.projectile_speed if tier_def != null else _map.castle_projectile_speed


## Gold the castle pays at every dawn: the tier's dawn_income (tier I: the map's base_dawn_income)
## through castle.base_income, never below 0.
func base_income() -> int:
	var tier_def: BuildingTierDef = _upgraded_tier()
	var base: int = tier_def.dawn_income if tier_def != null else _map.base_dawn_income
	return maxi(_stats.int_value(&"castle.base_income", maxi(base, 0)), 0)


## The first castle plot of the map and its building; a map without one leaves the castle with no
## tiers.
func _find_castle_plot(map: MapConfig) -> void:
	for spot: BuildSpotDef in map.spots:
		if spot == null or not spot.is_castle:
			continue
		for building_def: BuildingDef in map.buildings:
			if building_def != null and building_def.id == spot.building_id:
				if building_def.max_tier() > 0:
					_plot_id = spot.id
					_def = building_def
					_tier = 1
				return
		return


## The tier data of the castle once it has been upgraded (tier II or above); null at tier I and on a
## map with no castle plot, whose numbers are the map's own castle fields.
func _upgraded_tier() -> BuildingTierDef:
	if _def == null or _tier < 2:
		return null
	return _def.tier_def(_tier)


## Health at the base of the stack: the tier's max_health from tier II, else the map's.
func _base_max_health() -> int:
	var tier_def: BuildingTierDef = _upgraded_tier()
	if tier_def != null:
		return maxi(tier_def.max_health, 1)
	return maxi(_map.castle_max_health, 1)


func _stat_max_health() -> int:
	return _stats.int_value(&"castle.max_health", _base_max_health())


## The castle plot was bought up a tier: the castle stands at that tier's numbers, whole (the
## upgrade is a day action and the dawn repair left the castle at full health). Any other plot is
## none of the castle's business.
func _on_building_built(spot_id: StringName, _building_id: StringName, new_tier: int) -> void:
	if _tier == 0 or spot_id != _plot_id:
		return
	_tier = clampi(new_tier, 1, _def.max_tier())
	_max_health = _stat_max_health()
	_health = _max_health


## A change of castle.max_health: the gain raises current health by the gain of the maximum and a
## loss clamps it into [1, max] while the castle stands. Emits nothing.
func _on_stats_changed(stats: Array[StringName]) -> void:
	if not stats.has(&"castle.max_health"):
		return
	var gain: int = (
		_stat_max_health() - _stats.previous_int_value(&"castle.max_health", _base_max_health())
	)
	_max_health = _stat_max_health()
	if not _destroyed:
		_health = clampi(_health + gain, 1, _max_health)
