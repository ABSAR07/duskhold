extends GutTest
## UAT G-05-2 recurrence guard (BLDG-08, META-08, D-02, D-15): every modifier of every castle card
## must move its stat at every shipped base it can touch, in the written direction, by between half
## and one and a half times its written effect, so a card that the integer rounding swallowed (the
## old +25% on a base of 1, the footman's blow) or doubled can not come back.
## test_ability_data alone missed the defect: it pins stat, bucket and value only, and the stack
## tests use synthetic bases, so neither ever ran a card against the numbers the game ships.
## Every base here is read from the shipped files (the prototype map's buildings, units, enemies and
## castle fields, the king and his sword, castle_center.tres tiers II to IV), never a literal, so a
## retune of any base is checked where it lands. One fresh StatStack per card, integer stats read
## through int_value and float stats through float_value, the exact value computed from the one
## documented formula of docs/STAT_MODIFIERS.md:
## (base + sum(flat)) * (1 + sum(percent) / 100) * product(multiplier / 100).

const MAP_PATH := "res://data/maps/prototype_map.tres"
const KING_PATH := "res://data/king/king.tres"
const CASTLE_ID: StringName = &"castle_center"
const WALL_ID: StringName = &"wall"
const SHRINE_ID: StringName = &"shrine"
const SHRINE_DAMAGE: StringName = &"shrine.damage"
const SYNERGY_SOURCE: StringName = &"shrine_synergy"
const GOLD_STAT: StringName = &"castle.base_income"
const PERCENT: StatModifierDef.Bucket = StatModifierDef.Bucket.PERCENT
const FLAT: StatModifierDef.Bucket = StatModifierDef.Bucket.FLAT
## A card must land between half and one and a half times what its text writes.
const BAND_LOW: float = 0.5
const BAND_HIGH: float = 1.5
const FLOAT_TOLERANCE: float = 0.000001
## The owner's scale: every integer health and damage base is at least this (UAT G-05-2).
const SCALE_FLOOR: int = 100
## Half a unit, plus a hair for the float arithmetic of the reference value.
const HALF_UNIT: float = 0.500001

var _map: MapConfig
## stat id -> { label -> shipped base (an int for an integer stat, a float for a float stat) }.
var _bases: Dictionary = {}


func before_all() -> void:
	_map = load(MAP_PATH)
	_bases = {}
	_collect_king()
	_collect_units_and_enemies()
	_collect_buildings()
	_collect_castle()


func _add(stat: StringName, label: String, base: Variant) -> void:
	if not _bases.has(stat):
		_bases[stat] = {}
	(_bases[stat] as Dictionary)[label] = base


func _collect_king() -> void:
	var king: KingDef = load(KING_PATH)
	_add(&"king.max_health", "king", king.max_health)
	_add(&"king.attack_damage", "sword", king.weapon.attack_damage)
	_add(&"king.slam_damage", "sword slam", king.weapon.slam_damage)
	_add(&"king.attack_interval", "sword", king.weapon.attack_interval)


func _collect_units_and_enemies() -> void:
	for unit: UnitDef in _map.units:
		_add(&"unit.max_health", String(unit.id), unit.max_health)
		_add(&"unit.attack_damage", String(unit.id), unit.attack_damage)
	for enemy: EnemyDef in _map.enemies:
		_add(&"king.damage_taken", "%s blow" % enemy.id, enemy.attack_damage)


func _collect_buildings() -> void:
	for def: BuildingDef in _map.buildings:
		if def.id == CASTLE_ID:
			continue
		var health_stat: StringName = (
			&"wall.max_health" if def.id == WALL_ID else &"building.max_health"
		)
		for index: int in range(def.tiers.size()):
			var tier: BuildingTierDef = def.tiers[index]
			var label: String = "%s tier %d" % [def.id, index + 1]
			_add(health_stat, label, tier.max_health)
			if tier.attack_damage > 0:
				_add(def.damage_stat, label, tier.attack_damage)
			if tier.attack_range > 0.0:
				_add(def.range_stat, label, tier.attack_range)
			if tier.squad_respawn_seconds > 0.0:
				_add(&"squad.respawn_seconds", label, tier.squad_respawn_seconds)


## Tier I of the castle lives in the map's castle fields, tiers II to IV in castle_center.tres.
func _collect_castle() -> void:
	_add(&"castle.max_health", "castle tier 1", _map.castle_max_health)
	_add(&"castle.arrow_damage", "castle tier 1", _map.castle_attack_damage)
	_add(&"castle.arrow_range", "castle tier 1", _map.castle_attack_range)
	_add(&"castle.base_income", "castle tier 1", _map.base_dawn_income)
	var castle: BuildingDef = _def_of(CASTLE_ID)
	for tier_number: int in range(2, castle.max_tier() + 1):
		var tier: BuildingTierDef = castle.tier_def(tier_number)
		var label: String = "castle tier %d" % tier_number
		_add(&"castle.max_health", label, tier.max_health)
		_add(&"castle.arrow_damage", label, tier.attack_damage)
		_add(&"castle.arrow_range", label, tier.attack_range)
		_add(&"castle.base_income", label, tier.dawn_income)


func _def_of(building_id: StringName) -> BuildingDef:
	for def: BuildingDef in _map.buildings:
		if def.id == building_id:
			return def
	return null


## Every card of castle tiers II to IV, in tier order.
func _cards() -> Array[ChoiceDef]:
	var cards: Array[ChoiceDef] = []
	var castle: BuildingDef = _def_of(CASTLE_ID)
	for tier_number: int in range(2, castle.max_tier() + 1):
		cards.append_array(castle.tier_def(tier_number).choices)
	return cards


func _card(card_id: StringName) -> ChoiceDef:
	for card: ChoiceDef in _cards():
		if card.id == card_id:
			return card
	return null


func _stack_of(card: ChoiceDef) -> StatStack:
	var stack: StatStack = StatStack.new()
	assert_true(stack.add_source(card.id, card.modifiers), "%s is armed" % card.id)
	return stack


func _stats_of(card: ChoiceDef) -> Array[StringName]:
	var stats: Array[StringName] = []
	for mod: StatModifierDef in card.modifiers:
		if not stats.has(mod.stat):
			stats.append(mod.stat)
	return stats


func _mods_on(card: ChoiceDef, stat: StringName) -> Array[StatModifierDef]:
	var mods: Array[StatModifierDef] = []
	for mod: StatModifierDef in card.modifiers:
		if mod.stat == stat:
			mods.append(mod)
	return mods


## The exact value of the documented formula for these modifiers on one stat (no rounding).
func _exact(base: float, mods: Array[StatModifierDef]) -> float:
	var flat: int = 0
	var percent: int = 0
	var multiplier: float = 1.0
	for mod: StatModifierDef in mods:
		if mod.bucket == FLAT:
			flat += mod.value
		elif mod.bucket == PERCENT:
			percent += mod.value
		else:
			multiplier *= mod.value / 100.0
	return (base + flat) * (1.0 + percent / 100.0) * multiplier


## True when a stat that should have moved by `written` moved by `moved`: the same direction and
## between half and one and a half times as far. A written change of nothing must stay nothing.
func _in_band(written: float, moved: float) -> bool:
	if is_zero_approx(written):
		return is_zero_approx(moved)
	if moved * written <= 0.0:
		return false
	var ratio: float = moved / written
	return ratio >= BAND_LOW and ratio <= BAND_HIGH


## One case per card x integer stat it names x shipped base of that stat.
func _int_cases() -> Array[Dictionary]:
	return _cases(true)


func _float_cases() -> Array[Dictionary]:
	return _cases(false)


func _cases(integers: bool) -> Array[Dictionary]:
	var cases: Array[Dictionary] = []
	for card: ChoiceDef in _cards():
		var stack: StatStack = _stack_of(card)
		for stat: StringName in _stats_of(card):
			if StatIds.is_int(stat) != integers or not _bases.has(stat):
				continue
			var group: Dictionary = _bases[stat]
			for label: String in group:
				var base: Variant = group[label]
				var result: Variant = (
					stack.int_value(stat, int(base))
					if integers
					else stack.float_value(stat, float(base))
				)
				var exact: float = _exact(float(base), _mods_on(card, stat))
				(
					cases
					. append(
						{
							"card": card.id,
							"stat": stat,
							"label": label,
							"base": base,
							"result": result,
							"exact": exact,
							"name": "%s %s at %s %s" % [card.id, stat, label, str(base)],
						}
					)
				)
	return cases


func test_every_stat_a_card_names_has_a_shipped_base_list() -> void:
	assert_gt(_cards().size(), 0, "the castle offers cards")
	for card: ChoiceDef in _cards():
		for mod: StatModifierDef in card.modifiers:
			assert_true(_bases.has(mod.stat), "%s: '%s' has shipped bases" % [card.id, mod.stat])
			if _bases.has(mod.stat):
				assert_gt((_bases[mod.stat] as Dictionary).size(), 0, "%s has a base" % mod.stat)


func test_every_registered_stat_has_bases_of_its_own_kind() -> void:
	for stat: StringName in StatIds.all():
		assert_true(_bases.has(stat), "'%s' has shipped bases" % stat)
		if not _bases.has(stat):
			continue
		var group: Dictionary = _bases[stat]
		for label: String in group:
			var base: Variant = group[label]
			if StatIds.is_int(stat):
				assert_true(base is int, "%s at %s is an integer" % [stat, label])
			else:
				assert_true(base is float, "%s at %s is a float" % [stat, label])


func test_every_integer_modifier_moves_its_stat_in_the_written_direction_at_every_base() -> void:
	var cases: Array[Dictionary] = _int_cases()
	assert_gt(cases.size(), 0, "integer cases exist")
	for case: Dictionary in cases:
		var base: float = float(case["base"])
		var moved: float = float(case["result"]) - base
		var written: float = float(case["exact"]) - base
		assert_ne(moved, 0.0, "%s moves" % case["name"])
		assert_gt(moved * written, 0.0, "%s moves the written way" % case["name"])


func test_every_integer_modifier_lands_within_half_to_one_and_a_half_of_its_text() -> void:
	var cases: Array[Dictionary] = _int_cases()
	assert_gt(cases.size(), 0, "integer cases exist")
	for case: Dictionary in cases:
		var base: float = float(case["base"])
		var result: float = float(case["result"])
		var exact: float = float(case["exact"])
		assert_true(_in_band(exact - base, result - base), "%s lands in band" % case["name"])
		assert_lte(absf(result - exact), HALF_UNIT, "%s is rounded once, half up" % case["name"])


func test_every_float_modifier_lands_exactly_and_moves_its_stat() -> void:
	var cases: Array[Dictionary] = _float_cases()
	assert_gt(cases.size(), 0, "float cases exist")
	for case: Dictionary in cases:
		var result: float = float(case["result"])
		assert_almost_eq(
			result, float(case["exact"]), FLOAT_TOLERANCE, "%s is exact" % case["name"]
		)
		assert_ne(result, float(case["base"]), "%s moves" % case["name"])


## The shipped Shrine synergy, as the IncomeState source: +synergy_percent per other awake Shrine,
## here for one other (the shipped map has two Shrine plots, so one is always awake beside any).
func _synergy_mods() -> Array[StatModifierDef]:
	var percent: int = 0
	for tier: BuildingTierDef in _def_of(SHRINE_ID).tiers:
		percent = maxi(percent, tier.synergy_percent)
	var mod: StatModifierDef = StatModifierDef.new()
	mod.stat = SHRINE_DAMAGE
	mod.bucket = PERCENT
	mod.value = percent
	var mods: Array[StatModifierDef] = [mod]
	return mods


func _shrine_plots() -> int:
	var plots: int = 0
	for spot: BuildSpotDef in _map.spots:
		if spot.building_id == SHRINE_ID:
			plots += 1
	return plots


func test_golden_age_on_top_of_the_shrine_synergy_adds_a_quarter_of_the_base() -> void:
	assert_gte(_shrine_plots(), 2, "two Shrine plots, so one other Shrine can be awake")
	var synergy: Array[StatModifierDef] = _synergy_mods()
	assert_gt(synergy[0].value, 0, "the shipped Shrine has a synergy percent")
	var golden: ChoiceDef = _card(&"golden_age")
	var with_card: Array[StatModifierDef] = []
	with_card.append_array(synergy)
	with_card.append_array(_mods_on(golden, SHRINE_DAMAGE))
	var plain: StatStack = StatStack.new()
	plain.add_source(SYNERGY_SOURCE, synergy)
	var boosted: StatStack = StatStack.new()
	boosted.add_source(SYNERGY_SOURCE, synergy)
	boosted.add_source(golden.id, golden.modifiers)
	var group: Dictionary = _bases[SHRINE_DAMAGE]
	assert_gt(group.size(), 0, "a shrine base exists")
	for label: String in group:
		var base: int = int(group[label])
		var written: float = _exact(float(base), with_card) - _exact(float(base), synergy)
		var moved: float = float(
			boosted.int_value(SHRINE_DAMAGE, base) - plain.int_value(SHRINE_DAMAGE, base)
		)
		assert_true(
			_in_band(written, moved), "%s: Golden Age adds %s of %s" % [label, moved, written]
		)


## Every integer health and damage base lies between the owner's 100 and the stack's int64 bound
## (StatStack.MAX_ABS_BASE, the largest the stack accepts); the largest shipped base is castle
## tier IV's 20000. Gold (castle.base_income) is not rescaled and is exempt.
func test_every_integer_health_and_damage_base_lies_between_100_and_the_stack_bound() -> void:
	var checked: int = 0
	for stat: StringName in _bases:
		if stat == GOLD_STAT or not StatIds.is_int(stat):
			continue
		var group: Dictionary = _bases[stat]
		for label: String in group:
			var base: int = int(group[label])
			checked += 1
			assert_gte(base, SCALE_FLOOR, "%s at %s is at the owner's scale" % [stat, label])
			assert_lte(base, StatStack.MAX_ABS_BASE, "%s at %s fits the stack" % [stat, label])
	assert_gt(checked, 0, "integer bases were checked")


## Negative control: the old footman blow (a base of 1) rounds a +25% to no change, so the band
## rejects it; the same modifier on 100 lands and passes; a card that doubled would fail too.
func test_the_band_rejects_a_quarter_on_a_base_of_one_and_accepts_it_on_one_hundred() -> void:
	var mod: StatModifierDef = StatModifierDef.new()
	mod.stat = &"unit.attack_damage"
	mod.bucket = PERCENT
	mod.value = 25
	var mods: Array[StatModifierDef] = [mod]
	var stack: StatStack = StatStack.new()
	assert_true(stack.add_source(&"control", mods), "the control source is armed")
	var old_blow: int = stack.int_value(mod.stat, 1)
	var old_written: float = _exact(1.0, mods) - 1.0
	assert_false(_in_band(old_written, float(old_blow - 1)), "+25%% on 1 (%d) fails" % old_blow)
	var new_blow: int = stack.int_value(mod.stat, SCALE_FLOOR)
	var new_written: float = _exact(float(SCALE_FLOOR), mods) - SCALE_FLOOR
	assert_true(_in_band(new_written, float(new_blow - SCALE_FLOOR)), "+25% on 100 passes")
	assert_false(_in_band(new_written, new_written * 2.0), "a doubled effect fails")
