extends GutTest
## ECON-04, D-10, D-13, D-14: a built Field never depends on its Mill again. Nights are run through
## the real RunManager on the prototype map (RunContext, Mill I plus field_1 and field_2 built,
## gold granted), and a fall is dealt by damaging a building during the night, as an enemy would:
## - a Mill that falls is rebuilt free at dawn and pays nothing that morning (D-14), while the
##   Fields keep paying; it never relocks or unpays them;
## - the lock on an unbuilt Field is read from the Mill's tier, which the free rebuild keeps, so a
##   Mill that fell (or is down right now) does not relock field_3 either;
## - a Field that falls skips its own morning only, and the other Field and the Mill still pay;
## - buying Mill II raises only the Mill's own entry in the payout (D-13).
## Expected numbers are read from the shipped data, never repeated here.

const TUNING := "res://data/tuning/loop_tuning.tres"
const MILL: StringName = &"mill_1"
const FIELD_1: StringName = &"field_1"
const FIELD_2: StringName = &"field_2"
const FIELD_3: StringName = &"field_3"
const RICH_GOLD: int = 200

var _tuning: LoopTuning
var _ctx: RunContext


func before_each() -> void:
	_tuning = load(TUNING)
	var map: MapConfig = E2eSupport.waveless_prototype_map()
	map.starting_gold = RICH_GOLD
	_ctx = RunContext.new(map, _tuning)
	watch_signals(_ctx.events)
	for spot_id: StringName in [MILL, FIELD_1, FIELD_2]:
		assert_eq(_ctx.commands.submit(BuildIntent.new(spot_id)), CommandProcessor.OK, spot_id)


func _income(spot_id: StringName) -> int:
	var tier: int = _ctx.buildings.current_tier(spot_id)
	return _ctx.buildings.get_building_def_for_spot(spot_id).tier_def(tier).dawn_income


## One night in which `fallen` are destroyed, then the dawn; the dawn's per_spot payout. Leaves the
## run in DAWN.
func _night_losing(fallen: Array[StringName]) -> Dictionary:
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	for spot_id: StringName in fallen:
		_ctx.buildings.damage_building(spot_id, _ctx.buildings.max_health_of(spot_id))
		assert_true(_ctx.buildings.is_destroyed(spot_id), "%s fell in the night" % spot_id)
	_ctx.run_manager.tick(_tuning.placeholder_night_seconds + 0.1)
	assert_eq(_ctx.run_manager.get_phase(), RunManager.RunPhase.DAWN, "dawn reached")
	var emissions: int = get_signal_emit_count(_ctx.events, "dawn_payout")
	var params: Variant = get_signal_parameters(_ctx.events, "dawn_payout", emissions - 1)
	return (params as Array)[1] if params != null else {}


func _into_day() -> void:
	_ctx.run_manager.tick(_tuning.dawn_seconds + 0.1)
	assert_eq(_ctx.run_manager.get_phase(), RunManager.RunPhase.DAY, "day again")


func test_a_fallen_mill_is_rebuilt_free_and_pays_nothing_that_morning_but_the_fields_pay() -> void:
	var gold: int = _ctx.economy.get_gold()
	var fallen: Array[StringName] = [MILL]
	var payout: Dictionary = _night_losing(fallen)
	assert_false(_ctx.buildings.is_destroyed(MILL), "the Mill was rebuilt at dawn")
	assert_eq(_ctx.buildings.current_tier(MILL), 1, "at the tier it fell at")
	assert_false(payout.has(MILL), "and it pays nothing that morning")
	assert_eq(payout[FIELD_1], _income(FIELD_1), "field_1 still pays its gold")
	assert_eq(payout[FIELD_2], _income(FIELD_2), "field_2 still pays its gold")
	var total: int = int((get_signal_parameters(_ctx.events, "dawn_payout", 0) as Array)[0])
	assert_eq(_ctx.economy.get_gold(), gold + total, "the rebuild itself cost nothing")


func test_the_mill_pays_again_the_dawn_after_its_rebuild() -> void:
	var fallen: Array[StringName] = [MILL]
	_night_losing(fallen)
	_into_day()
	var quiet: Array[StringName] = []
	var payout: Dictionary = _night_losing(quiet)
	assert_eq(payout[MILL], _income(MILL), "the Mill is paying again")
	assert_eq(payout[FIELD_1], _income(FIELD_1), "and so are the Fields")


func test_a_fallen_mill_does_not_relock_an_unbuilt_field() -> void:
	var fallen: Array[StringName] = [MILL]
	_night_losing(fallen)
	_into_day()
	assert_eq(_ctx.commands.validate_build(FIELD_3), CommandProcessor.OK, "field_3 still opens")
	assert_eq(_ctx.commands.submit(BuildIntent.new(FIELD_3)), CommandProcessor.OK, "and builds")
	assert_eq(_ctx.buildings.current_tier(FIELD_3), 1, "field_3 stands")


func test_even_a_mill_that_is_down_right_now_leaves_the_lock_open() -> void:
	_ctx.buildings.damage_building(MILL, _ctx.buildings.max_health_of(MILL))
	assert_true(_ctx.buildings.is_destroyed(MILL), "the Mill is down")
	assert_eq(_ctx.commands.validate_build(FIELD_3), CommandProcessor.OK, "the lock reads its tier")
	assert_eq(_ctx.commands.submit(BuildIntent.new(FIELD_3)), CommandProcessor.OK, "a Field builds")


func test_two_nights_without_a_standing_mill_never_stop_the_fields() -> void:
	var fallen: Array[StringName] = [MILL]
	for night: int in range(2):
		var payout: Dictionary = _night_losing(fallen)
		assert_false(payout.has(MILL), "night %d: the Mill skips its morning" % (night + 1))
		assert_eq(payout[FIELD_1], _income(FIELD_1), "night %d: field_1 pays" % (night + 1))
		assert_eq(payout[FIELD_2], _income(FIELD_2), "night %d: field_2 pays" % (night + 1))
		_into_day()


func test_a_fallen_field_skips_its_own_morning_and_nobody_else_does() -> void:
	var fallen: Array[StringName] = [FIELD_1]
	var payout: Dictionary = _night_losing(fallen)
	assert_false(_ctx.buildings.is_destroyed(FIELD_1), "field_1 was rebuilt free")
	assert_false(payout.has(FIELD_1), "and pays nothing that morning")
	assert_eq(payout[FIELD_2], _income(FIELD_2), "field_2 still pays")
	assert_eq(payout[MILL], _income(MILL), "the Mill still pays")
	_into_day()
	var quiet: Array[StringName] = []
	assert_eq(_night_losing(quiet)[FIELD_1], _income(FIELD_1), "field_1 pays again the next dawn")


func test_the_mill_and_a_field_falling_together_leave_the_other_field_paying() -> void:
	var fallen: Array[StringName] = [MILL, FIELD_1]
	var payout: Dictionary = _night_losing(fallen)
	assert_eq(payout.keys(), [FIELD_2, MapConfig.CASTLE_PAYOUT_KEY], "field_2 and the castle")
	assert_eq(payout[FIELD_2], _income(FIELD_2), "field_2 pays its gold")


func test_buying_mill_two_raises_only_the_mills_own_entry() -> void:
	var quiet: Array[StringName] = []
	var before: Dictionary = _night_losing(quiet)
	_into_day()
	assert_eq(_ctx.commands.submit(BuildIntent.new(MILL)), CommandProcessor.OK, "Mill II bought")
	assert_eq(_ctx.buildings.current_tier(MILL), 2, "Mill II stands")
	var after: Dictionary = _night_losing(quiet)
	assert_gt(int(after[MILL]), int(before[MILL]), "the Mill pays more")
	assert_eq(after[MILL], _income(MILL), "exactly its tier II income")
	assert_eq(after[FIELD_1], before[FIELD_1], "field_1 is unchanged")
	assert_eq(after[FIELD_2], before[FIELD_2], "field_2 is unchanged")
	assert_eq(after[MapConfig.CASTLE_PAYOUT_KEY], before[MapConfig.CASTLE_PAYOUT_KEY], "castle too")
	assert_eq(_ctx.buildings.current_tier(FIELD_1), 1, "no Field gained a tier")
