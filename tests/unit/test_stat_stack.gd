extends GutTest
## META-08, D-15: the stat stack's single-modifier behaviour, one bucket at a time. The combined
## cases (bucket mixes, pickup-order permutations) live in test_stat_combined.gd. The vectors are
## the research E1 numbers: every integer stat is rounded once, half up, at the end.

const TOWER_DAMAGE := &"tower.damage"
const TOWER_RANGE := &"tower.range"
const KING_DAMAGE := &"king.attack_damage"

var _stack: StatStack


func before_each() -> void:
	_stack = StatStack.new()


func _mod(stat: StringName, bucket: StatModifierDef.Bucket, value: int) -> StatModifierDef:
	var mod: StatModifierDef = StatModifierDef.new()
	mod.stat = stat
	mod.bucket = bucket
	mod.value = value
	return mod


func _add(source: StringName, stat: StringName, bucket: StatModifierDef.Bucket, value: int) -> bool:
	var mods: Array[StatModifierDef] = [_mod(stat, bucket, value)]
	return _stack.add_source(source, mods)


func test_with_no_source_every_read_returns_the_base_untouched() -> void:
	assert_eq(_stack.int_value(TOWER_DAMAGE, 6), 6, "an integer stat is its base")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 0), 0, "a zero base stays zero")
	assert_eq(_stack.float_value(TOWER_RANGE, 9.0), 9.0, "a float stat is its base, bit for bit")
	assert_eq(_stack.float_value(TOWER_RANGE, 0.1 + 0.2), 0.1 + 0.2, "even an inexact float")
	assert_false(_stack.is_modified(TOWER_DAMAGE), "nothing is modified")
	assert_true(_stack.modified_stats().is_empty(), "no stat is listed")
	assert_true(_stack.source_ids().is_empty(), "no source is listed")


func test_a_flat_modifier_adds_stat_units_to_the_base() -> void:
	assert_true(_add(&"a", TOWER_DAMAGE, StatModifierDef.Bucket.FLAT, 2), "accepted")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 10), 12, "10 + 2")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 0), 2, "0 + 2")


func test_a_percent_modifier_adds_whole_percent() -> void:
	assert_true(_add(&"a", TOWER_DAMAGE, StatModifierDef.Bucket.PERCENT, 50), "accepted")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 10), 15, "10 + 50%")


func test_a_multiplier_is_a_percent_of_x1() -> void:
	assert_true(_add(&"a", TOWER_DAMAGE, StatModifierDef.Bucket.MULTIPLIER, 200), "accepted")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 10), 20, "10 x 2")


func test_a_negative_percent_lowers_and_rounds_half_up() -> void:
	assert_true(_add(&"a", TOWER_DAMAGE, StatModifierDef.Bucket.PERCENT, -50), "accepted")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 3), 2, "3 - 50% is 1.5, rounded up")


func test_rounding_ties_go_up() -> void:
	assert_true(_add(&"a", TOWER_DAMAGE, StatModifierDef.Bucket.PERCENT, 50), "accepted")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 3), 5, "3 + 50% is 4.5, rounded up")
	assert_true(_add(&"b", KING_DAMAGE, StatModifierDef.Bucket.PERCENT, 25), "accepted")
	assert_eq(_stack.int_value(KING_DAMAGE, 6), 8, "6 + 25% is 7.5, rounded up")


func test_a_positive_base_never_falls_below_one() -> void:
	assert_true(_add(&"a", TOWER_DAMAGE, StatModifierDef.Bucket.MULTIPLIER, 40), "accepted")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 1), 1, "1 x 0.4 clamps to 1")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 0), 0, "a zero base stays zero")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 10), 4, "a larger base is not clamped")


func test_a_flat_bonus_lifts_a_zero_base() -> void:
	assert_true(_add(&"a", TOWER_DAMAGE, StatModifierDef.Bucket.FLAT, 5), "accepted")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 0), 5, "0 + 5")


func test_a_negative_flat_total_counts_as_zero_before_the_percent() -> void:
	assert_true(_add(&"a", TOWER_DAMAGE, StatModifierDef.Bucket.FLAT, -50), "accepted")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 3), 1, "3 - 50 is below zero: the clamp to 1 holds")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 0), 0, "and a zero base stays at zero")


func test_a_float_stat_applies_its_buckets_without_rounding() -> void:
	assert_true(_add(&"a", TOWER_RANGE, StatModifierDef.Bucket.PERCENT, 15), "accepted")
	assert_almost_eq(_stack.float_value(TOWER_RANGE, 10.0), 11.5, 0.000001, "10 m + 15%")
	assert_true(_add(&"a", TOWER_RANGE, StatModifierDef.Bucket.FLAT, 2), "replaced by a flat")
	assert_almost_eq(_stack.float_value(TOWER_RANGE, 10.0), 12.0, 0.000001, "10 m + 2")
	assert_true(_add(&"a", TOWER_RANGE, StatModifierDef.Bucket.MULTIPLIER, 150), "and a multiplier")
	assert_almost_eq(_stack.float_value(TOWER_RANGE, 10.0), 15.0, 0.000001, "10 m x 1.5")


func test_a_modifier_that_is_not_allowed_is_refused_and_changes_nothing() -> void:
	assert_true(_add(&"keep", TOWER_DAMAGE, StatModifierDef.Bucket.FLAT, 1), "a good source")
	watch_signals(_stack)
	var buckets: StatModifierDef.Bucket = StatModifierDef.Bucket.PERCENT
	assert_false(_add(&"x", &"tower.dmg", StatModifierDef.Bucket.FLAT, 1), "unregistered stat")
	assert_false(_add(&"x", TOWER_DAMAGE, buckets, 1001), "percent 1001")
	assert_false(_add(&"x", TOWER_DAMAGE, buckets, -91), "percent -91")
	assert_false(_add(&"x", TOWER_DAMAGE, StatModifierDef.Bucket.MULTIPLIER, 401), "multiplier 401")
	assert_false(_add(&"x", TOWER_DAMAGE, StatModifierDef.Bucket.MULTIPLIER, 9), "multiplier 9")
	assert_false(_add(&"x", TOWER_DAMAGE, StatModifierDef.Bucket.FLAT, 100001), "flat 100001")
	assert_false(_add(&"x", TOWER_DAMAGE, StatModifierDef.Bucket.FLAT, -100001), "flat -100001")
	assert_false(_stack.add_source(&"x", [null] as Array[StatModifierDef]), "a null modifier")
	assert_false(_stack.has_source(&"x"), "no refused source was kept")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 10), 11, "the earlier source is untouched")
	assert_signal_not_emitted(_stack, "changed", "a refusal announces nothing")


func test_one_bad_modifier_refuses_the_whole_source() -> void:
	var mods: Array[StatModifierDef] = [
		_mod(TOWER_DAMAGE, StatModifierDef.Bucket.FLAT, 3),
		_mod(&"nope", StatModifierDef.Bucket.FLAT, 3),
	]
	assert_false(_stack.add_source(&"mixed", mods), "refused as a whole")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 10), 10, "the good half was not applied")


func test_a_fifth_multiplier_and_a_percent_sum_below_minus_ninety_are_refused() -> void:
	for index: int in range(StatStack.MAX_MULTIPLIERS_PER_STAT):
		var source: StringName = StringName("m%d" % index)
		assert_true(_add(source, TOWER_DAMAGE, StatModifierDef.Bucket.MULTIPLIER, 110), "mult")
	assert_false(_add(&"m4", TOWER_DAMAGE, StatModifierDef.Bucket.MULTIPLIER, 110), "a fifth")
	assert_true(_add(&"m4", KING_DAMAGE, StatModifierDef.Bucket.MULTIPLIER, 110), "another stat")
	assert_true(_add(&"p1", KING_DAMAGE, StatModifierDef.Bucket.PERCENT, -50), "-50")
	assert_true(_add(&"p2", KING_DAMAGE, StatModifierDef.Bucket.PERCENT, -40), "-90 is allowed")
	assert_false(_add(&"p3", KING_DAMAGE, StatModifierDef.Bucket.PERCENT, -1), "-91 is not")
	assert_true(_add(&"big1", TOWER_RANGE, StatModifierDef.Bucket.PERCENT, 600), "+600")
	assert_false(_add(&"big2", TOWER_RANGE, StatModifierDef.Bucket.PERCENT, 401), "+1001 is not")
	assert_true(_add(&"big2", TOWER_RANGE, StatModifierDef.Bucket.PERCENT, 400), "+1000 is")


func test_the_largest_allowed_stack_stays_exact_inside_int64() -> void:
	assert_true(_add(&"f", TOWER_DAMAGE, StatModifierDef.Bucket.FLAT, 100000), "flat")
	assert_true(_add(&"p", TOWER_DAMAGE, StatModifierDef.Bucket.PERCENT, 1000), "percent")
	for index: int in range(StatStack.MAX_MULTIPLIERS_PER_STAT):
		var source: StringName = StringName("m%d" % index)
		assert_true(_add(source, TOWER_DAMAGE, StatModifierDef.Bucket.MULTIPLIER, 400), "mult")
	# (100000 + 100000, clamped to 100000) x 11 x 4^4 = 281600000.
	assert_eq(_stack.int_value(TOWER_DAMAGE, 100000), 281600000, "clamped base, no overflow")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 900000), 281600000, "a huge base is clamped first")


func test_adding_a_source_id_again_replaces_its_list() -> void:
	assert_true(_add(&"synergy", TOWER_DAMAGE, StatModifierDef.Bucket.PERCENT, 20), "first")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 10), 12, "+20%")
	assert_true(_add(&"synergy", TOWER_DAMAGE, StatModifierDef.Bucket.PERCENT, 40), "again")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 10), 14, "+40%, not +60%")
	assert_true(_add(&"synergy", KING_DAMAGE, StatModifierDef.Bucket.FLAT, 1), "another stat")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 10), 10, "the old stat is released")
	assert_eq(_stack.source_ids(), [&"synergy"] as Array[StringName], "still one source")


func test_remove_source_restores_the_base_and_an_unknown_id_does_nothing() -> void:
	assert_true(_add(&"a", TOWER_DAMAGE, StatModifierDef.Bucket.FLAT, 2), "added")
	assert_true(_stack.has_source(&"a"), "listed")
	watch_signals(_stack)
	_stack.remove_source(&"missing")
	assert_signal_not_emitted(_stack, "changed", "an unknown id announces nothing")
	_stack.remove_source(&"a")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 10), 10, "the base again")
	assert_false(_stack.is_modified(TOWER_DAMAGE), "no longer modified")
	assert_false(_stack.has_source(&"a"), "no longer listed")
	assert_signal_emit_count(_stack, "changed", 1, "one announcement for the removal")


func test_changed_fires_once_per_change_with_the_sorted_stats_that_moved() -> void:
	watch_signals(_stack)
	var mods: Array[StatModifierDef] = [
		_mod(TOWER_RANGE, StatModifierDef.Bucket.PERCENT, 10),
		_mod(KING_DAMAGE, StatModifierDef.Bucket.FLAT, 1),
		_mod(KING_DAMAGE, StatModifierDef.Bucket.PERCENT, 10),
	]
	assert_true(_stack.add_source(&"pack", mods), "added")
	assert_signal_emit_count(_stack, "changed", 1, "one announcement")
	var moved: Array = get_signal_parameters(_stack, "changed", 0)[0]
	assert_eq(moved, [KING_DAMAGE, TOWER_RANGE] as Array[StringName], "sorted, no duplicates")
	assert_true(_stack.add_source(&"pack", mods), "the same list again")
	assert_signal_emit_count(_stack, "changed", 1, "a no-op announces nothing")


func test_previous_int_value_is_the_value_before_the_change_being_announced() -> void:
	var seen: Array[int] = []
	_stack.changed.connect(
		func(_stats: Array[StringName]) -> void:
			seen.append(_stack.previous_int_value(TOWER_DAMAGE, 10))
			seen.append(_stack.int_value(TOWER_DAMAGE, 10))
	)
	assert_true(_add(&"a", TOWER_DAMAGE, StatModifierDef.Bucket.FLAT, 2), "first change")
	assert_true(_add(&"a", TOWER_DAMAGE, StatModifierDef.Bucket.FLAT, 5), "second change")
	_stack.remove_source(&"a")
	assert_eq(seen, [10, 12, 12, 15, 15, 10] as Array[int], "old and new, each time")
	assert_eq(_stack.previous_int_value(KING_DAMAGE, 7), 7, "an untouched stat reads as now")


func test_sums_and_listings_describe_the_stack_for_the_overlay() -> void:
	assert_true(_add(&"b", TOWER_DAMAGE, StatModifierDef.Bucket.MULTIPLIER, 150), "b")
	assert_true(_add(&"a", TOWER_DAMAGE, StatModifierDef.Bucket.MULTIPLIER, 120), "a")
	assert_true(_add(&"c", TOWER_DAMAGE, StatModifierDef.Bucket.FLAT, 3), "c")
	assert_true(_add(&"d", KING_DAMAGE, StatModifierDef.Bucket.PERCENT, 5), "d")
	var sums: Dictionary = _stack.sums_of(TOWER_DAMAGE)
	assert_eq(sums["flat"], 3, "flat sum")
	assert_eq(sums["pct"], 0, "percent sum")
	assert_eq(sums["mults"], [120, 150] as Array[int], "multipliers ascending")
	assert_eq(_stack.sums_of(TOWER_RANGE)["mults"], [] as Array[int], "none for a clean stat")
	assert_eq(_stack.modified_stats(), [KING_DAMAGE, TOWER_DAMAGE] as Array[StringName], "sorted")
	assert_eq(_stack.source_ids(), [&"a", &"b", &"c", &"d"] as Array[StringName], "sorted ids")
	assert_true(_stack.is_modified(KING_DAMAGE), "modified")
