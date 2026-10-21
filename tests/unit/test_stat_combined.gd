extends GutTest
## META-08, D-15: combined modifiers. Bucket mixes (the research E1 vectors and the ability-draft
## pairs), and the rule that the order sources arrive in never changes a result. Single-modifier
## cases are in test_stat_stack.gd.

const TOWER_DAMAGE := &"tower.damage"
const SHRINE_DAMAGE := &"shrine.damage"
const KING_DAMAGE := &"king.attack_damage"
const KING_INTERVAL := &"king.attack_interval"

var _stack: StatStack


func before_each() -> void:
	_stack = StatStack.new()


func _mod(stat: StringName, bucket: StatModifierDef.Bucket, value: int) -> StatModifierDef:
	var mod: StatModifierDef = StatModifierDef.new()
	mod.stat = stat
	mod.bucket = bucket
	mod.value = value
	return mod


func _flat(stat: StringName, value: int) -> StatModifierDef:
	return _mod(stat, StatModifierDef.Bucket.FLAT, value)


func _pct(stat: StringName, value: int) -> StatModifierDef:
	return _mod(stat, StatModifierDef.Bucket.PERCENT, value)


func _mult(stat: StringName, value: int) -> StatModifierDef:
	return _mod(stat, StatModifierDef.Bucket.MULTIPLIER, value)


func _add(source: StringName, mod: StatModifierDef) -> void:
	var mods: Array[StatModifierDef] = [mod]
	assert_true(_stack.add_source(source, mods), "source %s accepted" % source)


## A stack filled in `order` (indexes into `sources`), then read for every registered stat.
func _readings(sources: Array, order: Array) -> Dictionary:
	var stack: StatStack = StatStack.new()
	for index: int in order:
		var entry: Array = sources[index]
		var mods: Array[StatModifierDef] = [entry[1]]
		assert_true(stack.add_source(entry[0], mods), "source accepted")
	var readings: Dictionary = {}
	for stat: StringName in StatIds.all():
		readings[stat] = [stack.int_value(stat, 7), stack.float_value(stat, 7.5)]
	return readings


func test_a_flat_and_a_percent_bonus_add_before_the_percent_applies() -> void:
	_add(&"a", _flat(TOWER_DAMAGE, 2))
	_add(&"b", _pct(TOWER_DAMAGE, 50))
	assert_eq(_stack.int_value(TOWER_DAMAGE, 10), 18, "(10 + 2) x 1.5")


func test_two_percent_sources_add_into_one_percent_not_two() -> void:
	_add(&"a", _pct(TOWER_DAMAGE, 20))
	_add(&"b", _pct(TOWER_DAMAGE, 30))
	assert_eq(_stack.int_value(TOWER_DAMAGE, 10), 15, "10 x (1 + 0.20 + 0.30), not 10 x 1.2 x 1.3")


func test_flat_percent_and_multiplier_apply_in_that_order() -> void:
	_add(&"a", _flat(TOWER_DAMAGE, 2))
	_add(&"b", _pct(TOWER_DAMAGE, 50))
	_add(&"c", _mult(TOWER_DAMAGE, 200))
	assert_eq(_stack.int_value(TOWER_DAMAGE, 10), 36, "(10 + 2) x 1.5 x 2")


func test_flat_then_multiplier_equals_multiplier_then_flat_in_arrival() -> void:
	_add(&"flat_first", _flat(KING_DAMAGE, 1))
	_add(&"then_double", _mult(KING_DAMAGE, 200))
	assert_eq(_stack.int_value(KING_DAMAGE, 3), 8, "(3 + 1) x 2")
	var other: StatStack = StatStack.new()
	var double_mods: Array[StatModifierDef] = [_mult(KING_DAMAGE, 200)]
	var flat_mods: Array[StatModifierDef] = [_flat(KING_DAMAGE, 1)]
	assert_true(other.add_source(&"then_double", double_mods), "double first")
	assert_true(other.add_source(&"flat_first", flat_mods), "then the flat")
	assert_eq(other.int_value(KING_DAMAGE, 3), 8, "the same 8 in the reverse order")


func test_a_slower_king_swing_is_a_float_multiplier() -> void:
	_add(&"assassin", _mult(KING_INTERVAL, 150))
	assert_almost_eq(_stack.float_value(KING_INTERVAL, 0.8), 1.2, 0.000001, "0.8 s x 1.5")


func test_a_shrine_buff_leaves_tower_damage_alone() -> void:
	_add(&"engineers", _pct(TOWER_DAMAGE, 25))
	assert_eq(_stack.int_value(TOWER_DAMAGE, 6), 8, "6 + 25% is 7.5, rounded up")
	_add(&"shrine_synergy", _pct(SHRINE_DAMAGE, 20))
	assert_eq(_stack.int_value(TOWER_DAMAGE, 6), 8, "tower damage did not move")
	assert_eq(_stack.int_value(SHRINE_DAMAGE, 5), 6, "5 + 20% is exactly 6")


func test_two_multipliers_round_once_at_the_end() -> void:
	_add(&"a", _mult(TOWER_DAMAGE, 150))
	_add(&"b", _mult(TOWER_DAMAGE, 150))
	assert_eq(_stack.int_value(TOWER_DAMAGE, 10), 23, "10 x 1.5 x 1.5 is 22.5, rounded up once")


func test_every_arrival_order_of_three_sources_gives_the_same_result() -> void:
	var sources: Array = [
		[&"flat", _flat(TOWER_DAMAGE, 3)],
		[&"percent", _pct(TOWER_DAMAGE, 40)],
		[&"mult", _mult(TOWER_DAMAGE, 175)],
	]
	var orders: Array = [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]]
	var reference: int = -1
	for order: Array in orders:
		var stack: StatStack = StatStack.new()
		for index: int in order:
			var entry: Array = sources[index]
			var mods: Array[StatModifierDef] = [entry[1]]
			assert_true(stack.add_source(entry[0], mods), "accepted")
		var value: int = stack.int_value(TOWER_DAMAGE, 7)
		if reference < 0:
			reference = value
		assert_eq(value, reference, "order %s" % [order])
	assert_eq(reference, 25, "(7 + 3) x 1.4 x 1.75 = 24.5, rounded up")


func test_two_sources_give_equal_readings_for_every_registered_stat_in_either_order() -> void:
	var sources: Array = []
	for stat: StringName in StatIds.all():
		sources.append([StringName("flat_" + stat), _flat(stat, 3)])
		sources.append([StringName("pct_" + stat), _pct(stat, 25)])
		sources.append([StringName("mult_" + stat), _mult(stat, 140)])
	var forward: Array = range(sources.size())
	var backward: Array = forward.duplicate()
	backward.reverse()
	assert_eq(_readings(sources, forward), _readings(sources, backward), "pickup order is moot")
	var ints: Array = _readings(sources, forward)[&"tower.damage"]
	assert_eq(ints[0], 18, "(7 + 3) x 1.25 x 1.4 = 17.5, rounded up")


func test_replacing_a_synergy_style_source_moves_the_result_and_removing_it_clears_it() -> void:
	_add(&"shrine_synergy", _pct(TOWER_DAMAGE, 20))
	assert_eq(_stack.int_value(TOWER_DAMAGE, 10), 12, "+20%")
	_add(&"shrine_synergy", _pct(TOWER_DAMAGE, 40))
	assert_eq(_stack.int_value(TOWER_DAMAGE, 10), 14, "replaced by +40%")
	_stack.remove_source(&"shrine_synergy")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 10), 10, "removed")


func test_removing_one_of_several_sources_keeps_the_others() -> void:
	_add(&"a", _flat(TOWER_DAMAGE, 2))
	_add(&"b", _pct(TOWER_DAMAGE, 50))
	_add(&"c", _mult(TOWER_DAMAGE, 200))
	_stack.remove_source(&"b")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 10), 24, "(10 + 2) x 2")
	_stack.remove_source(&"a")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 10), 20, "10 x 2")


func test_a_percent_sum_left_below_the_limit_by_a_removal_is_clamped_when_read() -> void:
	_add(&"low1", _pct(TOWER_DAMAGE, -80))
	_add(&"boost", _pct(TOWER_DAMAGE, 100))
	_add(&"low2", _pct(TOWER_DAMAGE, -80))
	assert_eq(_stack.int_value(TOWER_DAMAGE, 100), 40, "the sum is -60: 100 x 0.4")
	_stack.remove_source(&"boost")
	assert_eq(_stack.int_value(TOWER_DAMAGE, 100), 10, "a raw -160 reads as -90: 100 x 0.1")
