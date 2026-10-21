class_name IncomeState
extends RefCounted
## The per-plot economy state of every income curve that is not flat (D-12, D-14, ECON-03,
## ECON-05, ECON-06): the Gold Mine's decline, the Fishing Harbor's boats and the Shrine's kill
## credit. A sibling of BuildingSystem, which is at the public-method cap, in the style of
## WallSystem: it reads BuildingSystem's public getters and never calls it back to change anything.
##
## IncomeState is the only payer of every non-FLAT curve, and BuildingSystem.dawn_income_by_spot()
## the only payer of FLAT ones, so a building is paid by exactly one of them (Pitfall 4). RunManager
## merges the two into the one dawn_payout.
##
## A DECLINING building pays maxi(income_floor, dawn_income - income_step * paid_dawns), integers
## only (DR-7). paid_dawns advances by 1 after a dawn the building stood and was not rebuilt, and
## only while that dawn's payout was above the floor, so it stops at the first count whose payout is
## the floor and never grows without bound.
##
## A BOATS building gains one boat at every dawn it stands and was not rebuilt, up to the boat_cap
## of its current tier, and then pays boats * boat_income. It emits harbor_boats_changed only when
## the count changes, so the boat views redraw on news and a Harbor at its cap is silent. An upgrade
## raises the cap and keeps the boats it has; the boats stay when the Harbor falls.
##
## An AWAKENED building (the Shrine) listens to enemy_died: every death within its tier's
## wake_radius (a death exactly that far away counts) adds the dead enemy's max health to its
## credit, whoever killed it and whether the Shrine stands or lies in rubble (D-14: nothing it
## earned is ever lost).
## A credit that reaches wake_threshold_hp (exactly equal wakes it) wakes it for good and emits
## shrine_woke once. The Shrine pays its dawn_income only while awake. The towers loop asks
## is_awake() before it lets a Shrine fire, so a dormant one never shoots (research P4).
##
## A building that fell and was rebuilt this dawn pays nothing and makes no progress (D-14,
## LOOP-05): it loses nothing it accumulated, it only skips the morning. Detached from the scene
## tree and the clock; no randomness (DR-1 to DR-10).

var _map: MapConfig
var _buildings: BuildingSystem
var _events: SimEvents
## Plot id -> dawns paid so far; a plot appears here the first time it pays.
var _paid: Dictionary = {}
## Plot id -> boats the Harbor has; a plot appears here the first time it gains a boat.
var _boats: Dictionary = {}
## Plot id -> enemy max health credited to the Shrine so far; a plot appears here with its first
## credit.
var _credit: Dictionary = {}
## Plot id -> true for every Shrine that has woken. Never cleared during a run.
var _awake: Dictionary = {}


func _init(
	map: MapConfig, buildings: BuildingSystem, events: SimEvents, _stat_stack: StatStack = null
) -> void:
	_map = map
	_buildings = buildings
	_events = events
	events.enemy_died.connect(_on_enemy_died)


## What every standing non-flat building pays at this dawn: spot_id -> gold, in MapConfig order,
## listing only the plots that pay more than 0. Advances the state: call it once per dawn
## (RunManager does, after the rebuild). A plot with no building, a fallen one, and one rebuilt
## this dawn are left out with no progress (D-14). Empty when nothing of the kind stands.
func dawn_payouts() -> Dictionary:
	var payouts: Dictionary = {}
	for spot_id: StringName in _buildings.spot_ids():
		var building_def: BuildingDef = _buildings.get_building_def_for_spot(spot_id)
		if building_def == null or building_def.income_curve == BuildingDef.IncomeCurve.FLAT:
			continue
		var tier_def: BuildingTierDef = building_def.tier_def(_buildings.current_tier(spot_id))
		if tier_def == null:
			continue
		var instance: BuildingInstance = _buildings.get_instance(spot_id)
		if instance.destroyed or instance.rebuilt_this_dawn:
			continue
		var amount: int = 0
		if building_def.income_curve == BuildingDef.IncomeCurve.DECLINING:
			amount = _pay_declining(spot_id, tier_def)
		elif building_def.income_curve == BuildingDef.IncomeCurve.BOATS:
			amount = _pay_boats(spot_id, tier_def)
		elif building_def.income_curve == BuildingDef.IncomeCurve.AWAKENED and is_awake(spot_id):
			amount = tier_def.dawn_income
		if amount > 0:
			payouts[spot_id] = amount
	return payouts


## Dawns the Mine has been paid so far, counting only the dawns that lowered its payout; 0 for a
## plot that has never paid and for a plot that is not a declining one.
func mine_paid_dawns(spot_id: StringName) -> int:
	return int(_paid.get(spot_id, 0))


## Boats the Harbor on this plot has; 0 for a Harbor that has not yet seen a dawn standing, for an
## empty plot and for a plot that is not a BOATS one. They stay when the Harbor falls and when it is
## upgraded (D-14).
func boats_of(spot_id: StringName) -> int:
	return int(_boats.get(spot_id, 0))


## True once the Shrine on this plot has woken; false for a dormant one, an empty plot and a plot
## that is not an AWAKENED one. It stays true when the Shrine falls and when it is rebuilt (D-14).
func is_awake(spot_id: StringName) -> bool:
	return _awake.has(spot_id)


## The max health of enemies that died within the Shrine's wake radius so far, from any killer; 0
## for a Shrine that has seen no such death, an empty plot and a plot that is not an AWAKENED one.
## It keeps growing after the Shrine wakes and while it lies in rubble.
func kill_credit(spot_id: StringName) -> int:
	return int(_credit.get(spot_id, 0))


## How many Shrines are awake.
func awake_count() -> int:
	return _awake.size()


## What the plot would pay at the next dawn it stands and is not rebuilt; 0 for an empty plot, a
## plot whose building is neither declining nor a Harbor, and a tier with no data for its curve.
## For a Harbor that is the boat it would gain, up to the cap, times the gold per boat. Pure: it
## changes nothing.
func next_payout(spot_id: StringName) -> int:
	var building_def: BuildingDef = _buildings.get_building_def_for_spot(spot_id)
	if building_def == null:
		return 0
	var tier_def: BuildingTierDef = building_def.tier_def(_buildings.current_tier(spot_id))
	if tier_def == null:
		return 0
	if building_def.income_curve == BuildingDef.IncomeCurve.DECLINING:
		return _amount(tier_def, mine_paid_dawns(spot_id))
	if building_def.income_curve == BuildingDef.IncomeCurve.BOATS:
		return mini(boats_of(spot_id) + 1, tier_def.boat_cap) * tier_def.boat_income
	return 0


## The Mine's payout this dawn, advancing its paid count while it is above the floor.
func _pay_declining(spot_id: StringName, tier_def: BuildingTierDef) -> int:
	var amount: int = _amount(tier_def, mine_paid_dawns(spot_id))
	# Bad data (a step below 1) never lowers the payout, so it never counts either.
	if amount > tier_def.income_floor and tier_def.income_step > 0:
		_paid[spot_id] = mine_paid_dawns(spot_id) + 1
	return amount


## The Harbor's payout this dawn: it gains a boat first, up to the tier's cap, announcing the new
## count only when it changed, and every boat it then has pays.
func _pay_boats(spot_id: StringName, tier_def: BuildingTierDef) -> int:
	var before: int = boats_of(spot_id)
	var after: int = maxi(before, mini(before + 1, tier_def.boat_cap))
	if after != before:
		_boats[spot_id] = after
		_events.harbor_boats_changed.emit(spot_id, after)
	return after * tier_def.boat_income


## The payout after `paid` earlier paying dawns, never below the floor.
func _amount(tier_def: BuildingTierDef, paid: int) -> int:
	return maxi(tier_def.income_floor, tier_def.dawn_income - tier_def.income_step * paid)


## Credits one enemy death to every built Shrine whose wake radius holds it, in MapConfig order
## (a death inside two radii credits both). Whoever killed the enemy (research A8), and whether the
## Shrine stands or has fallen (D-14): only a plot with no Shrine built yet credits nothing. A
## Shrine that reaches its threshold wakes now and emits shrine_woke once.
func _on_enemy_died(
	_enemy_id: int, def_id: StringName, pos: Vector2, _killer_kind: StringName
) -> void:
	var enemy: EnemyDef = _map.find_enemy(def_id)
	if enemy == null or enemy.max_health <= 0:
		return
	for spot_id: StringName in _buildings.spot_ids():
		var tier_def: BuildingTierDef = _shrine_tier(spot_id)
		if tier_def == null:
			continue
		var plot: Vector3 = _buildings.get_spot(spot_id).position
		var reach: float = tier_def.wake_radius
		if pos.distance_squared_to(Vector2(plot.x, plot.z)) > reach * reach:
			continue
		var total: int = kill_credit(spot_id) + enemy.max_health
		_credit[spot_id] = total
		if total >= tier_def.wake_threshold_hp and not _awake.has(spot_id):
			_awake[spot_id] = true
			_events.shrine_woke.emit(spot_id)


## The current tier of the AWAKENED building built on this plot, fallen or standing; null for an
## empty plot or any other curve.
func _shrine_tier(spot_id: StringName) -> BuildingTierDef:
	var building_def: BuildingDef = _buildings.get_building_def_for_spot(spot_id)
	if building_def == null or building_def.income_curve != BuildingDef.IncomeCurve.AWAKENED:
		return null
	return building_def.tier_def(_buildings.current_tier(spot_id))
