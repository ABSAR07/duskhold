extends GutTest
## Economy invariants (ECON-01): gold is a plain integer ledger that never goes negative.

const RANDOM_OPERATIONS: int = 200


func _new_economy(starting_gold: int) -> Economy:
	return Economy.new(SimEvents.new(), starting_gold)


func test_try_spend_above_gold_is_refused_and_changes_nothing() -> void:
	var economy: Economy = _new_economy(3)
	assert_false(economy.try_spend(4), "cannot spend more than the gold held")
	assert_eq(economy.get_gold(), 3, "gold unchanged after a refused spend")


func test_try_spend_negative_cost_is_refused_and_changes_nothing() -> void:
	var economy: Economy = _new_economy(3)
	assert_false(economy.try_spend(-1), "a negative cost cannot mint gold")
	assert_eq(economy.get_gold(), 3, "gold unchanged after a refused negative spend")


func test_grant_negative_amount_is_refused_and_changes_nothing() -> void:
	var economy: Economy = _new_economy(3)
	assert_false(economy.grant(-1), "a negative grant cannot drain gold")
	assert_eq(economy.get_gold(), 3, "gold unchanged after a refused negative grant")


func test_spend_exact_balance_reaches_zero() -> void:
	var economy: Economy = _new_economy(3)
	assert_true(economy.try_spend(3), "spending exactly the balance is allowed")
	assert_eq(economy.get_gold(), 0, "gold is exactly zero, not negative")


func test_gold_changed_reports_new_amount_and_delta() -> void:
	var events: SimEvents = SimEvents.new()
	var economy: Economy = Economy.new(events, 5)
	watch_signals(events)
	economy.try_spend(2)
	assert_signal_emitted_with_parameters(events, "gold_changed", [3, -2])
	economy.grant(4)
	assert_signal_emitted_with_parameters(events, "gold_changed", [7, 4])


func test_refused_operations_emit_no_gold_changed() -> void:
	var events: SimEvents = SimEvents.new()
	var economy: Economy = Economy.new(events, 2)
	watch_signals(events)
	economy.try_spend(9)
	economy.try_spend(-1)
	economy.grant(-1)
	assert_signal_not_emitted(events, "gold_changed")


func test_negative_starting_gold_is_clamped_to_zero() -> void:
	assert_eq(_new_economy(-5).get_gold(), 0, "the ledger never starts negative")


func test_random_operations_never_drive_gold_negative() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1234
	var economy: Economy = _new_economy(5)
	for i: int in RANDOM_OPERATIONS:
		var amount: int = rng.randi_range(-3, 8)
		if rng.randf() < 0.5:
			economy.try_spend(amount)
		else:
			economy.grant(amount)
		assert_true(economy.get_gold() >= 0, "gold stayed non-negative at operation %d" % i)
