extends GutTest
## D-03, D-10: a locked next tier or plot reads its requirement instead of a price. The castle
## requirement reads "Needs Castle II" (the Roman numeral of the required tier) and a plot
## requirement reads "Needs a House" (the required building's display name); cost is 0 and the
## label is affordable (no red coins) while locked, the title still names the locked tier, and the
## price and the normal title return the moment the requirement is met.

const FIXTURE := "res://tests/fixtures/fixture_map_gate.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
const TOWER: StringName = &"tower_1"
const HOUSE_A: StringName = &"house_a"
const HOUSE_B: StringName = &"house_b"
const CASTLE: StringName = &"castle_plot"

var _ctx: RunContext


func before_each() -> void:
	_ctx = RunContext.new((load(FIXTURE) as MapConfig).duplicate(true), load(TUNING))


func _label(spot_id: StringName, coins_paid: int = 0) -> Dictionary:
	return SpotLabelModel.describe(_ctx, spot_id, coins_paid)


func _build(spot_id: StringName, choice: StringName = &"") -> void:
	var result: StringName = _ctx.commands.submit(BuildIntent.new(spot_id, choice))
	assert_eq(result, CommandProcessor.OK, "build %s" % spot_id)


func test_the_gated_tower_reads_needs_castle_two_with_no_price() -> void:
	_build(TOWER)
	var content: Dictionary = _label(TOWER)
	assert_eq(content["status_line"], "Needs Castle II", "the requirement")
	assert_eq(content["cost"], 0, "no price, so no coins")
	assert_eq(content["affordable"], true, "and no red coins")
	assert_eq(content["title"], "Tower II", "the title still names the locked tier")
	assert_eq(content["max_tier"], false, "it is not the top")
	assert_eq(content["paid"], 0, "nothing paid")


func test_the_locked_label_does_not_depend_on_the_gold() -> void:
	_build(TOWER)
	assert_true(_ctx.economy.try_spend(_ctx.economy.get_gold()), "spend every coin")
	assert_eq(_label(TOWER)["affordable"], true, "not red when poor")
	assert_eq(_label(TOWER)["status_line"], "Needs Castle II", "still locked")
	_ctx.economy.grant(40)
	_build(CASTLE, &"royal_training")
	assert_eq(_label(TOWER)["status_line"], "", "castle II lifts it")


func test_a_locked_plot_reads_needs_a_house() -> void:
	var content: Dictionary = _label(HOUSE_B)
	assert_eq(content["status_line"], "Needs a House", "the required building's name")
	assert_eq(content["cost"], 0, "no price")
	assert_eq(content["affordable"], true, "not red")
	assert_eq(content["title"], "House I", "the title names the plot's first tier")


func test_the_price_and_the_normal_title_return_once_unlocked() -> void:
	_build(HOUSE_A)
	var content: Dictionary = _label(HOUSE_B)
	assert_eq(content["status_line"], "", "no status")
	assert_eq(content["title"], "House I", "title")
	assert_eq(content["cost"], 2, "the House I price is back")
	assert_eq(content["effect"], "+1 gold at dawn", "and its effect")


func test_the_castle_unlock_brings_the_tower_price_back() -> void:
	_build(TOWER)
	_build(CASTLE, &"royal_training")
	var content: Dictionary = _label(TOWER)
	assert_eq(content["status_line"], "", "unlocked")
	assert_eq(content["cost"], 6, "Tower II price")
	assert_eq(content["title"], "Tower II", "title")


func test_an_unlocked_ungated_plot_has_an_empty_status_line() -> void:
	assert_eq(_label(TOWER)["status_line"], "", "Tower I")
	assert_eq(_label(HOUSE_A)["status_line"], "", "House I")


func test_the_top_tier_still_reads_max_tier_not_a_requirement() -> void:
	_build(CASTLE, &"royal_training")
	_build(TOWER)
	_build(TOWER)
	var content: Dictionary = _label(TOWER)
	assert_eq(content["status_line"], "Max tier", "the top wins")
	assert_eq(content["max_tier"], true, "flagged")
