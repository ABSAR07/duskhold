extends GutTest
## UI-02, BLDG-05, BLDG-08, D-05, D-06 on the real scene (fixed run seed 1): riding up to the castle
## by day with the next tier affordable shows a row of four cards above it; keys 1 to 4 highlight
## one (raised and brighter); the hold is refused with no highlight and starts only with one; the
## highlighted card at hold start is the card bought. Nothing here reads rendered pixels: the cards
## are checked through CardRow's hooks, so the test runs on the headless renderer.

const CASTLE: StringName = &"castle_plot"
const HOUSE: StringName = &"house_1"
const SETTLE_FRAMES: int = 3
const GRANTED_GOLD: int = 40
const HOLD_SLACK_S: float = 1.5
const FAR_AWAY := Vector3(40.0, 0.0, 40.0)

var _map: MapRoot
var _ctx: RunContext
var _picker: CardPicker
var _row: CardRow


func _setup() -> void:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	_map = scene.instantiate()
	_map.map_config = E2eSupport.waveless_prototype_map()
	_map.fixed_run_seed = 1
	_map.handle_results_actions = false
	add_child_autofree(_map)
	await wait_process_frames(SETTLE_FRAMES)
	_ctx = _map.get_context()
	_picker = _map.get_cards()
	_row = _map.get_node("CardRow")


func after_each() -> void:
	E2eSupport.release_all_actions()


func _tier_two_cost() -> int:
	return _ctx.buildings.get_building_def_for_spot(CASTLE).tier_def(2).cost


## Grants gold, rides the king onto the castle plot and lets the picker see him there.
func _arrive_with_gold() -> void:
	_ctx.economy.grant(GRANTED_GOLD)
	var focused: bool = await E2eSupport.stand_at_spot(self, _map, CASTLE)
	assert_true(focused, "the king reached the castle plot")
	await wait_process_frames(2)


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await wait_process_frames(2)
	Input.action_release(action)
	await wait_process_frames(2)


func _raised_cards() -> int:
	var raised: int = 0
	for index: int in range(_row.card_count()):
		if _row.is_card_raised(index):
			raised += 1
	return raised


func test_the_scene_has_a_card_picker_and_a_card_row_that_start_hidden() -> void:
	await _setup()
	assert_not_null(_picker, "the map has a CardPicker")
	assert_not_null(_row, "and a CardRow")
	assert_false(_picker.is_showing(), "nothing shows at the start of the day")
	assert_eq(_row.card_count(), 0, "so no card is drawn")


func test_riding_up_to_the_castle_with_the_gold_shows_four_cards_none_raised() -> void:
	await _setup()
	await _arrive_with_gold()
	assert_true(_picker.is_showing(), "the cards show")
	assert_eq(_picker.shown_spot(), CASTLE, "for the castle")
	assert_eq(_row.card_count(), 4, "four cards")
	assert_eq(_raised_cards(), 0, "none is raised: nothing is highlighted")
	assert_eq(_picker.highlighted_index(), -1, "no highlight")
	assert_eq(_row.card_name(0), "Royal Training", "left to right in the authored order")
	assert_eq(_row.card_name(3), "Prosperity", "to the last")


func test_the_cards_do_not_show_without_the_gold() -> void:
	await _setup()
	assert_lt(_ctx.economy.get_gold(), _tier_two_cost(), "the start gold is below the price")
	var focused: bool = await E2eSupport.stand_at_spot(self, _map, CASTLE)
	assert_true(focused, "the king is at the castle plot")
	await wait_process_frames(2)
	assert_false(_picker.is_showing(), "a broke player sees the price, not the cards")
	assert_eq(_row.card_count(), 0, "nothing is drawn")


func test_pressing_the_action_key_with_no_highlight_is_denied_and_spends_nothing() -> void:
	await _setup()
	await _arrive_with_gold()
	var hold: BuildHoldController = _map.get_build_hold()
	watch_signals(hold)
	var gold: int = _ctx.economy.get_gold()
	await _tap(&"action_build")
	assert_signal_emitted_with_parameters(hold, "hold_denied", [CASTLE, &"choice_required"])
	assert_signal_not_emitted(hold, "hold_started", "no hold began")
	assert_eq(_ctx.economy.get_gold(), gold, "gold is unchanged")
	assert_eq(_ctx.buildings.current_tier(CASTLE), 1, "and so is the tier")


func test_a_digit_key_highlights_that_card_raised_and_only_that_one() -> void:
	await _setup()
	await _arrive_with_gold()
	await _tap(&"group_2")
	assert_eq(_picker.highlighted_index(), 1, "card 2 is highlighted")
	assert_eq(_picker.highlighted(), &"commander", "it is Commander")
	assert_true(_row.is_card_raised(1), "card 2 is raised")
	assert_eq(_raised_cards(), 1, "and only card 2")
	await _tap(&"group_4")
	assert_eq(_picker.highlighted_index(), 3, "key 4 moves it to card 4")
	assert_true(_row.is_card_raised(3), "which is now raised")
	assert_false(_row.is_card_raised(1), "and card 2 rests")


func test_holding_with_a_highlighted_card_buys_the_castle_tier_with_that_card() -> void:
	await _setup()
	await _arrive_with_gold()
	await _tap(&"group_2")
	var hold: BuildHoldController = _map.get_build_hold()
	watch_signals(hold)
	watch_signals(_ctx.events)
	var gold: int = _ctx.economy.get_gold()
	var seconds: float = _ctx.tuning.build_hold_seconds(_tier_two_cost()) + HOLD_SLACK_S
	Input.action_press(&"action_build")
	var bought: Callable = func() -> bool: return _ctx.buildings.current_tier(CASTLE) == 2
	assert_true(await E2eSupport.wait_until(self, bought, seconds), "the castle reached tier II")
	Input.action_release(&"action_build")
	assert_signal_emitted(hold, "hold_completed", "the hold completed")
	assert_signal_emitted_with_parameters(_ctx.events, "choice_picked", [CASTLE, 2, &"commander"])
	assert_eq(_ctx.economy.get_gold(), gold - _tier_two_cost(), "the cost was spent")
	assert_true(_ctx.stat_stack.has_source(&"commander"), "the card is armed")
	assert_eq(_ctx.choices.picks_of(CASTLE), [&"commander"] as Array[StringName], "recorded")


func test_after_the_purchase_the_next_tiers_cards_show_and_the_highlight_is_reset() -> void:
	await _setup()
	await _arrive_with_gold()
	await _tap(&"group_3")
	var seconds: float = _ctx.tuning.build_hold_seconds(_tier_two_cost()) + HOLD_SLACK_S
	Input.action_press(&"action_build")
	var bought: Callable = func() -> bool: return _ctx.buildings.current_tier(CASTLE) == 2
	assert_true(await E2eSupport.wait_until(self, bought, seconds), "bought")
	Input.action_release(&"action_build")
	await wait_process_frames(3)
	assert_true(_picker.is_showing(), "tier III offers its own cards (the gold still covers it)")
	assert_eq(_row.card_name(0), "Headsman's Edge", "the tier III row, not the tier II one")
	assert_eq(_picker.highlighted_index(), -1, "and nothing stays highlighted")


func test_leaving_range_hides_the_cards_and_returning_finds_no_highlight() -> void:
	await _setup()
	await _arrive_with_gold()
	await _tap(&"group_1")
	assert_eq(_picker.highlighted_index(), 0, "card 1 is highlighted")
	E2eSupport.teleport_king(_map, FAR_AWAY)
	await wait_process_frames(3)
	assert_false(_picker.is_showing(), "the cards hid")
	assert_eq(_row.card_count(), 0, "nothing is drawn")
	assert_false(_row.visible, "the row is hidden")
	var back: bool = await E2eSupport.stand_at_spot(self, _map, CASTLE)
	assert_true(back, "back at the plot")
	await wait_process_frames(2)
	assert_true(_picker.is_showing(), "the cards show again")
	assert_eq(_picker.highlighted_index(), -1, "with nothing highlighted")


func test_the_highlight_cannot_change_while_a_hold_is_under_way() -> void:
	await _setup()
	await _arrive_with_gold()
	await _tap(&"group_2")
	var hold: BuildHoldController = _map.get_build_hold()
	await E2eSupport.begin_stepped_hold(self, hold)
	assert_true(hold.is_holding(), "the hold started with card 2")
	_picker.set_highlight(0)
	assert_eq(_picker.highlighted_index(), 1, "set_highlight is ignored mid-hold")
	Input.action_press(&"group_4")
	await wait_process_frames(2)
	Input.action_release(&"group_4")
	assert_eq(_picker.highlighted_index(), 1, "so are the digit keys")
	assert_true(_row.is_card_raised(1), "the card shown raised is the card being bought")
	Input.action_release(&"action_build")
	await E2eSupport.step_hold(self, hold, 0.0)
	assert_false(hold.is_holding(), "releasing cancelled it")
	assert_eq(_ctx.buildings.current_tier(CASTLE), 1, "and nothing was bought")


func test_releasing_early_cancels_for_free() -> void:
	await _setup()
	await _arrive_with_gold()
	await _tap(&"group_1")
	var hold: BuildHoldController = _map.get_build_hold()
	watch_signals(hold)
	var gold: int = _ctx.economy.get_gold()
	await E2eSupport.begin_stepped_hold(self, hold)
	Input.action_release(&"action_build")
	await E2eSupport.step_hold(self, hold, 0.0)
	assert_signal_emitted(hold, "hold_cancelled", "cancelled")
	assert_eq(_ctx.economy.get_gold(), gold, "nothing was spent")
	assert_eq(_ctx.buildings.current_tier(CASTLE), 1, "no tier")


func test_a_house_plot_shows_no_cards() -> void:
	await _setup()
	_ctx.economy.grant(GRANTED_GOLD)
	var focused: bool = await E2eSupport.stand_at_spot(self, _map, HOUSE)
	assert_true(focused, "the king is at a House plot")
	await wait_process_frames(2)
	assert_false(_picker.is_showing(), "a plain tier shows no row")
	assert_eq(_row.card_count(), 0, "no cards")


func test_the_cards_never_show_at_night_even_with_the_king_on_the_plot() -> void:
	await _setup()
	await _arrive_with_gold()
	assert_true(_picker.is_showing(), "they show by day")
	assert_eq(_ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night begins")
	await wait_process_frames(3)
	assert_false(_picker.is_showing(), "not at night")
	assert_eq(_row.card_count(), 0, "so no card is drawn")
	assert_eq(_picker.highlighted_index(), -1, "and none is highlighted")
