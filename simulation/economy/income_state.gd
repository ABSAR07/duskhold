class_name IncomeState
extends RefCounted
## The per-plot economy state of every income curve that is not flat (D-12, D-14, ECON-03): so far
## the Gold Mine's decline. A sibling of BuildingSystem, which is at the public-method cap, in the
## style of WallSystem: it reads BuildingSystem's public getters and never calls it back to change
## anything. The Harbor's boats and the Shrine's credit join it in their own plans.
##
## IncomeState is the only payer of every non-FLAT curve, and BuildingSystem.dawn_income_by_spot()
## the only payer of FLAT ones, so a building is paid by exactly one of them (Pitfall 4). RunManager
## merges the two into the one dawn_payout.
##
## A DECLINING building pays maxi(income_floor, dawn_income - income_step * paid_dawns), integers
## only (DR-7). paid_dawns advances by 1 after a dawn the building stood and was not rebuilt, and
## only while that dawn's payout was above the floor, so it stops at the first count whose payout is
## the floor and never grows without bound. A building that fell and was rebuilt this dawn pays
## nothing and makes no progress (D-14, LOOP-05): it loses nothing it accumulated, it only skips
## the morning. Detached from the scene tree and the clock; no randomness (DR-1 to DR-10).

var _buildings: BuildingSystem
## Plot id -> dawns paid so far; a plot appears here the first time it pays.
var _paid: Dictionary = {}


func _init(
	_map: MapConfig, buildings: BuildingSystem, _events: SimEvents, _stat_stack: StatStack = null
) -> void:
	_buildings = buildings


## What every standing non-flat building pays at this dawn: spot_id -> gold, in MapConfig order,
## listing only the plots that pay more than 0. Advances the state: call it once per dawn
## (RunManager does, after the rebuild). A plot with no building, a fallen one, and one rebuilt
## this dawn are left out with no progress (D-14). Empty when nothing of the kind stands.
func dawn_payouts() -> Dictionary:
	var payouts: Dictionary = {}
	for spot_id: StringName in _buildings.spot_ids():
		var tier_def: BuildingTierDef = _declining_tier_of(spot_id)
		if tier_def == null:
			continue
		var instance: BuildingInstance = _buildings.get_instance(spot_id)
		if instance.destroyed or instance.rebuilt_this_dawn:
			continue
		var amount: int = _amount(tier_def, mine_paid_dawns(spot_id))
		# Bad data (a step below 1) never lowers the payout, so it never counts either.
		if amount > tier_def.income_floor and tier_def.income_step > 0:
			_paid[spot_id] = mine_paid_dawns(spot_id) + 1
		if amount > 0:
			payouts[spot_id] = amount
	return payouts


## Dawns the Mine has been paid so far, counting only the dawns that lowered its payout; 0 for a
## plot that has never paid and for a plot that is not a declining one.
func mine_paid_dawns(spot_id: StringName) -> int:
	return int(_paid.get(spot_id, 0))


## What the plot would pay at the next dawn it stands and is not rebuilt; 0 for an empty plot, a
## plot whose building does not decline, and a tier with no declining data. Pure: it changes
## nothing.
func next_payout(spot_id: StringName) -> int:
	var tier_def: BuildingTierDef = _declining_tier_of(spot_id)
	if tier_def == null:
		return 0
	return _amount(tier_def, mine_paid_dawns(spot_id))


## The payout after `paid` earlier paying dawns, never below the floor.
func _amount(tier_def: BuildingTierDef, paid: int) -> int:
	return maxi(tier_def.income_floor, tier_def.dawn_income - tier_def.income_step * paid)


## The current tier of the plot's building when it is built and its curve is DECLINING, else null.
func _declining_tier_of(spot_id: StringName) -> BuildingTierDef:
	var building_def: BuildingDef = _buildings.get_building_def_for_spot(spot_id)
	if building_def == null or building_def.income_curve != BuildingDef.IncomeCurve.DECLINING:
		return null
	return building_def.tier_def(_buildings.current_tier(spot_id))
