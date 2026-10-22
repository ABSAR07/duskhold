extends GutTest
## D-14, LOOP-04, LOOP-05, ECON-03 to ECON-06: one night that destroys all four new building types
## at once (the Gold Mine, the Mill, a Field, the Fishing Harbor and an awake Shrine) costs none of
## them anything but that morning's pay. The dawn rebuilds all five free and in MapConfig order,
## none of them is paid that morning while the castle and an untouched House still are, the Mine's
## paid dawns, the Harbor's boats and the Shrine's credit and awake state are exactly what they
## were, every one wears the crossed coin, and the next dawn pays the Mine its next declining
## amount, the Harbor one more boat and the Shrine its income. The per-building versions of this
## rule live in test_gold_mine, test_field_independence, test_fishing_harbor and
## test_shrine_destroyed; this one is the interaction. The run goes through the real RunManager on
## the waveless prototype map (RunContext), and expected numbers are read from the shipped data.

const TUNING := "res://data/tuning/loop_tuning.tres"
const MINE: StringName = &"gold_mine_1"
const MILL: StringName = &"mill_1"
const FIELD: StringName = &"field_1"
const HARBOR: StringName = &"harbor_1"
const SHRINE: StringName = &"shrine_west"
const HOUSE: StringName = &"house_1"
const GRUNT: StringName = &"grunt"
const RICH_GOLD: int = 300
const STANDING_DAWNS: int = 2

var _tuning: LoopTuning
var _ctx: RunContext
var _marker: DawnNoIncomeMarker
var _paid: Dictionary = {}
var _rebuilt: Array = []
var _credit_before: int = 0
var _mine_next_before: int = 0


func before_each() -> void:
	_tuning = load(TUNING)
	var map: MapConfig = E2eSupport.waveless_prototype_map()
	map.starting_gold = RICH_GOLD
	_ctx = RunContext.new(map, _tuning)
	_paid = {}
	_rebuilt = []
	_ctx.events.dawn_payout.connect(
		func(_total: int, per_spot: Dictionary) -> void: _paid = per_spot
	)
	_ctx.events.buildings_rebuilt.connect(func(spot_ids: Array) -> void: _rebuilt = spot_ids)
	for spot_id: StringName in [HOUSE, MINE, MILL, FIELD, HARBOR, SHRINE]:
		assert_eq(_ctx.commands.submit(BuildIntent.new(spot_id)), CommandProcessor.OK, spot_id)
	_wake_the_shrine()
	for _dawn: int in range(STANDING_DAWNS):
		_night_losing([] as Array[StringName])
		_into_day()
	_credit_before = _ctx.income.kill_credit(SHRINE)
	_mine_next_before = _ctx.income.next_payout(MINE)
	_marker = DawnNoIncomeMarker.new()
	add_child_autofree(_marker)
	_marker.bind_run(_ctx, null)


## Wakes the Shrine the way the game does: deaths beside it.
func _wake_the_shrine() -> void:
	var at: Vector3 = _ctx.buildings.get_spot(SHRINE).position
	var hp: int = _ctx.map.find_enemy(GRUNT).max_health
	var threshold: int = (
		_ctx.buildings.get_building_def_for_spot(SHRINE).tier_def(1).wake_threshold_hp
	)
	for death: int in range(ceili(float(threshold) / float(hp))):
		_ctx.events.enemy_died.emit(death, GRUNT, Vector2(at.x, at.z), &"tower")
	assert_true(_ctx.income.is_awake(SHRINE), "the Shrine is awake")


## One night in which `fallen` are destroyed, then the dawn; leaves the run in DAWN.
func _night_losing(fallen: Array[StringName]) -> void:
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	for spot_id: StringName in fallen:
		_ctx.buildings.damage_building(spot_id, _ctx.buildings.max_health_of(spot_id))
		assert_true(_ctx.buildings.is_destroyed(spot_id), "%s fell in the night" % spot_id)
	_ctx.run_manager.tick(_tuning.placeholder_night_seconds + 0.1)
	assert_eq(_ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "dawn reached")


func _into_day() -> void:
	_ctx.run_manager.tick(_tuning.dawn_seconds + 0.1)
	assert_eq(_ctx.run_manager.get_phase(), RunManager.RunPhase.DAY, "day again")


func _all_five() -> Array[StringName]:
	return [MINE, MILL, FIELD, HARBOR, SHRINE] as Array[StringName]


func test_the_dawn_rebuilds_all_five_free_in_map_order() -> void:
	var gold_before: int = _ctx.economy.get_gold()
	_night_losing(_all_five())
	assert_eq(_rebuilt, _all_five(), "the five ids, in MapConfig order")
	for spot_id: StringName in _all_five():
		assert_false(_ctx.buildings.is_destroyed(spot_id), "%s stands" % spot_id)
		assert_eq(
			_ctx.buildings.get_instance(spot_id).health,
			_ctx.buildings.max_health_of(spot_id),
			"%s is back at full health" % spot_id
		)
		assert_true(_ctx.buildings.get_instance(spot_id).rebuilt_this_dawn, "%s marked" % spot_id)
	var total: int = 0
	for amount: int in _paid.values():
		total += amount
	assert_eq(_ctx.economy.get_gold(), gold_before + total, "the rebuilds cost no gold")


func test_none_of_the_five_is_paid_that_morning_but_the_castle_and_the_house_are() -> void:
	_night_losing(_all_five())
	for spot_id: StringName in _all_five():
		assert_false(_paid.has(spot_id), "%s is not in the payout" % spot_id)
	assert_true(_paid.has(MapConfig.CASTLE_PAYOUT_KEY), "the castle is paid")
	assert_true(_paid.has(HOUSE), "and so is the House that stood")


func test_what_each_building_built_up_survives_the_fall() -> void:
	var boats_before: int = _ctx.income.boats_of(HARBOR)
	var paid_dawns_before: int = _ctx.income.mine_paid_dawns(MINE)
	assert_eq(paid_dawns_before, STANDING_DAWNS, "the Mine has been paid twice")
	assert_eq(boats_before, STANDING_DAWNS, "and the Harbor has two boats")
	_night_losing(_all_five())
	assert_eq(_ctx.income.mine_paid_dawns(MINE), paid_dawns_before, "no Mine progress was lost")
	assert_eq(_ctx.income.boats_of(HARBOR), boats_before, "no boat was lost")
	assert_eq(_ctx.income.kill_credit(SHRINE), _credit_before, "the Shrine kept its credit")
	assert_true(_ctx.income.is_awake(SHRINE), "and it is still awake")


func test_rebuilt_economy_marker_hangs_over_all_five() -> void:
	assert_eq(_marker.marker_count(), 0, "no mark before the night")
	_night_losing(_all_five())
	assert_eq(_marker.marked_spots(), _all_five(), "all five wear the crossed coin, in map order")


func test_the_next_dawn_pays_the_next_amounts() -> void:
	_night_losing(_all_five())
	_into_day()
	_night_losing([] as Array[StringName])
	var def_of: Callable = _ctx.buildings.get_building_def_for_spot
	assert_eq(int(_paid.get(MINE, -1)), _mine_next_before, "the Mine pays its next amount")
	var harbor_tier: BuildingTierDef = (def_of.call(HARBOR) as BuildingDef).tier_def(1)
	assert_eq(_ctx.income.boats_of(HARBOR), STANDING_DAWNS + 1, "the Harbor gains its boat")
	assert_eq(
		int(_paid.get(HARBOR, -1)), (STANDING_DAWNS + 1) * harbor_tier.boat_income, "and pays it"
	)
	var shrine_tier: BuildingTierDef = (def_of.call(SHRINE) as BuildingDef).tier_def(1)
	assert_eq(int(_paid.get(SHRINE, -1)), shrine_tier.dawn_income, "the Shrine pays its income")
	for spot_id: StringName in [MILL, FIELD]:
		var tier: BuildingTierDef = (def_of.call(spot_id) as BuildingDef).tier_def(1)
		assert_eq(int(_paid.get(spot_id, -1)), tier.dawn_income, "%s pays again" % spot_id)
