extends GutTest
## BLDG-02 / D-07 / D-08 on the real scene: one world-space label follows the nearest in-range
## spot during the day, shows the next tier, its cost as coin icons and its effect, turns red when
## unaffordable, says Max tier at the top, and shakes when a press is denied.

const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const POOR_MAP := "res://tests/fixtures/fixture_map_poor.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const RICH_GOLD: int = 50
const HOUSE_SPOT: StringName = &"house_1"
const POOR_SPOT: StringName = &"spot_a"
const NEAR_OFFSET := Vector3(0.5, 0.0, 0.0)
const FAR_AWAY := Vector3(0.0, 0.0, 40.0)
const LABEL_HEIGHT: float = 3.2
const SLOW_DRIP_S: float = 1.0
const WAIT_SLACK_S: float = 3.0
const SHAKE_WINDOW_S: float = 0.6
const UNAFFORDABLE_RED := Color(1.0, 0.25, 0.25)
const PAID_GOLD := Color(1.0, 0.8, 0.2)


func after_each() -> void:
	E2eSupport.release_all_actions()


func _rich_map() -> MapConfig:
	var map: MapConfig = (load(PROTOTYPE_MAP) as MapConfig).duplicate(true)
	map.starting_gold = RICH_GOLD
	return map


func _slow_tuning() -> LoopTuning:
	var tuning: LoopTuning = (load(TUNING) as LoopTuning).duplicate(true)
	tuning.coin_drip_interval = SLOW_DRIP_S
	return tuning


func _label(map_root: MapRoot) -> Node3D:
	return map_root.find_child("SpotLabel", true, false) as Node3D


func _title(label: Node3D) -> Label3D:
	return label.find_child("Title", true, false) as Label3D


func _coins(label: Node3D) -> Node3D:
	return label.find_child("Coins", true, false) as Node3D


func _spot_position(map_root: MapRoot, spot_id: StringName) -> Vector3:
	return map_root.get_context().buildings.get_spot(spot_id).position


func _stand_near(map_root: MapRoot, spot_id: StringName) -> void:
	E2eSupport.teleport_king(map_root, _spot_position(map_root, spot_id) + NEAR_OFFSET)
	await wait_process_frames(2)


func _coins_at_least(hold: BuildHoldController, coins: int) -> bool:
	return hold.get_coins_paid() >= coins


func test_the_label_floats_above_the_focused_spot_and_names_the_next_tier() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map())
	var ctx: RunContext = map_root.get_context()
	var label: Node3D = _label(map_root)
	assert_not_null(label, "the map has a SpotLabel")
	if label == null:
		return
	await _stand_near(map_root, HOUSE_SPOT)

	var spot_position: Vector3 = _spot_position(map_root, HOUSE_SPOT)
	var house: BuildingDef = ctx.buildings.get_building_def_for_spot(HOUSE_SPOT)
	assert_true(label.visible, "the label shows while the king is in range by day")
	assert_almost_eq(label.global_position.x, spot_position.x, 0.01, "above the spot in X")
	assert_almost_eq(label.global_position.z, spot_position.z, 0.01, "above the spot in Z")
	assert_almost_eq(label.global_position.y, spot_position.y + LABEL_HEIGHT, 0.01, "3.2 m up")
	assert_eq(_title(label).text, house.tier_label(1), "reads House I")
	var effect: Label3D = label.find_child("Effect", true, false) as Label3D
	assert_eq(effect.text, house.tier_def(1).effect_line(), "shows the income line")

	E2eSupport.teleport_king(map_root, FAR_AWAY)
	await wait_process_frames(2)
	assert_false(label.visible, "the label hides when the king is far from every spot")


func test_only_the_nearest_of_two_close_spots_carries_the_label() -> void:
	var map: MapConfig = _rich_map()
	var anchor: Vector3 = map.spots[0].position
	map.spots[1].position = anchor + Vector3(3.0, 0.0, 0.0)
	var map_root: MapRoot = await E2eSupport.spawn_map(self, map)
	var label: Node3D = _label(map_root)
	assert_not_null(label, "the map has a SpotLabel")
	if label == null:
		return

	E2eSupport.teleport_king(map_root, anchor + Vector3(0.5, 0.0, 0.0))
	await wait_process_frames(2)
	assert_almost_eq(label.global_position.x, anchor.x, 0.01, "first plot is nearest")
	E2eSupport.teleport_king(map_root, anchor + Vector3(2.4, 0.0, 0.0))
	await wait_process_frames(2)
	assert_almost_eq(label.global_position.x, anchor.x + 3.0, 0.01, "label moved to the second")
	assert_eq(map_root.find_children("SpotLabel", "", true, false).size(), 1, "one label only")


func test_the_label_hides_when_building_is_not_allowed() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map())
	var ctx: RunContext = map_root.get_context()
	var label: Node3D = _label(map_root)
	assert_not_null(label, "the map has a SpotLabel")
	if label == null:
		return
	await _stand_near(map_root, HOUSE_SPOT)
	assert_true(label.visible, "visible by day")

	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	await wait_process_frames(2)
	assert_false(label.visible, "no label at night")


func test_the_cost_is_drawn_as_coin_icons_that_fill_as_coins_land() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map(), _slow_tuning())
	var ctx: RunContext = map_root.get_context()
	var hold: BuildHoldController = map_root.get_build_hold()
	var label: Node3D = _label(map_root)
	assert_not_null(label, "the map has a SpotLabel")
	if label == null:
		return
	var cost: int = ctx.buildings.next_action_cost(HOUSE_SPOT)
	assert_gt(cost, 1, "a House costs at least two coins")
	await _stand_near(map_root, HOUSE_SPOT)
	var coins: Node3D = _coins(label)
	assert_eq(coins.get_child_count(), cost, "one coin icon per gold of cost")

	Input.action_press(&"action_build")
	var dripped: bool = await E2eSupport.wait_until(
		self, _coins_at_least.bind(hold, 1), WAIT_SLACK_S + SLOW_DRIP_S
	)
	assert_true(dripped, "a coin landed")
	await wait_process_frames(2)
	var paid: int = hold.get_coins_paid()
	assert_lt(paid, cost, "still mid-hold")
	for index: int in range(cost):
		var icon: Sprite3D = coins.get_child(index) as Sprite3D
		var expected_paid: bool = index < paid
		assert_eq(
			icon.modulate.is_equal_approx(PAID_GOLD), expected_paid, "coin %d fill state" % index
		)


func test_an_unaffordable_cost_is_red_and_an_affordable_one_is_not() -> void:
	var poor_map: MapConfig = load(POOR_MAP)
	var poor_root: MapRoot = await E2eSupport.spawn_map(self, poor_map)
	var poor_label: Node3D = _label(poor_root)
	assert_not_null(poor_label, "the map has a SpotLabel")
	if poor_label == null:
		return
	await _stand_near(poor_root, POOR_SPOT)
	assert_true(poor_label.visible, "label shows at the poor spot")
	assert_true(_title(poor_label).modulate.is_equal_approx(UNAFFORDABLE_RED), "title is red")
	var coin: Sprite3D = _coins(poor_label).get_child(0) as Sprite3D
	assert_true(coin.modulate.is_equal_approx(UNAFFORDABLE_RED), "coins are red")

	var rich_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map())
	var rich_label: Node3D = _label(rich_root)
	assert_not_null(rich_label, "the rich map has a SpotLabel")
	if rich_label == null:
		return
	await _stand_near(rich_root, HOUSE_SPOT)
	assert_false(_title(rich_label).modulate.is_equal_approx(UNAFFORDABLE_RED), "title not red")


func test_a_max_tier_spot_says_max_tier_and_shows_no_coins() -> void:
	var map_root: MapRoot = await E2eSupport.spawn_map(self, _rich_map())
	var ctx: RunContext = map_root.get_context()
	var house: BuildingDef = ctx.buildings.get_building_def_for_spot(HOUSE_SPOT)
	for _tier: int in range(house.max_tier()):
		ctx.commands.submit(BuildIntent.new(HOUSE_SPOT))
	var label: Node3D = _label(map_root)
	assert_not_null(label, "the map has a SpotLabel")
	if label == null:
		return
	await _stand_near(map_root, HOUSE_SPOT)
	var status: Label3D = label.find_child("Status", true, false) as Label3D
	assert_true(label.visible, "the label still shows at a max tier building")
	assert_eq(_title(label).text, house.tier_label(house.max_tier()), "shows the top tier")
	assert_eq(status.text, "Max tier", "status line")
	assert_eq(_coins(label).get_child_count(), 0, "nothing left to pay")
	assert_false(_title(label).modulate.is_equal_approx(UNAFFORDABLE_RED), "never red at the top")
	# Let the replaced building views finish their queue_free before GUT counts orphans.
	await wait_process_frames(1)


func test_a_denied_press_shakes_the_label_and_then_settles() -> void:
	var poor_map: MapConfig = load(POOR_MAP)
	var map_root: MapRoot = await E2eSupport.spawn_map(self, poor_map)
	var label: Node3D = _label(map_root)
	assert_not_null(label, "the map has a SpotLabel")
	if label == null:
		return
	await _stand_near(map_root, POOR_SPOT)
	var rest_x: float = label.global_position.x
	var widest: float = 0.0

	Input.action_press(&"action_build")
	var started: int = Time.get_ticks_msec()
	var window_ms: int = roundi(SHAKE_WINDOW_S * 1000.0)
	while Time.get_ticks_msec() - started < window_ms:
		widest = maxf(widest, absf(label.global_position.x - rest_x))
		await wait_process_frames(1)
	Input.action_release(&"action_build")

	assert_gt(widest, 0.02, "the label moved sideways during the shake")
	assert_lt(widest, 0.2, "the shake stays within about 0.15 m")
	assert_almost_eq(label.global_position.x, rest_x, 0.001, "it settles back above the spot")
