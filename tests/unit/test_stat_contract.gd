extends GutTest
## META-08: the stacking order is written down and the document cannot drift from the code. The
## contract is docs/STAT_MODIFIERS.md plus the same formula line in the head of stat_stack.gd; every
## registered stat id is named in the document's Registry section.

const DOC_PATH := "res://docs/STAT_MODIFIERS.md"
const STACK_PATH := "res://simulation/stats/stat_stack.gd"
const FORMULA := "final = (base + sum(flat)) * (1 + sum(percent) / 100) * product(multiplier / 100)"
const ROUNDING := (
	"Integer stats are computed exactly and rounded once, half up, at the end; "
	+ "a stat whose base is 1 or more never falls below 1."
)
const HEADINGS: Array[String] = [
	"## Formula",
	"## Buckets and units",
	"## Rounding",
	"## Sources",
	"## Registry",
	"## Limits",
]


func _mod(stat: StringName, bucket: StatModifierDef.Bucket, value: int) -> StatModifierDef:
	var mod: StatModifierDef = StatModifierDef.new()
	mod.stat = stat
	mod.bucket = bucket
	mod.value = value
	return mod


func _text(path: String) -> String:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text().replace(String.chr(13), "")


func test_the_document_exists_and_holds_the_formula_and_the_rounding_sentence() -> void:
	var doc: String = _text(DOC_PATH)
	assert_ne(doc, "", "docs/STAT_MODIFIERS.md exists")
	assert_true(doc.contains(FORMULA), "the formula line is in the document")
	assert_true(doc.contains(ROUNDING), "the rounding sentence is in the document")


func test_the_document_has_its_six_sections() -> void:
	var doc: String = _text(DOC_PATH)
	for heading: String in HEADINGS:
		assert_true(doc.contains("\n" + heading + "\n"), "the heading %s" % heading)


func test_the_stack_script_carries_the_same_formula_line() -> void:
	var source: String = _text(STACK_PATH)
	assert_ne(source, "", "stat_stack.gd is readable")
	assert_true(source.contains(FORMULA), "the formula line heads stat_stack.gd")


func test_every_registered_stat_is_named_in_the_registry_section() -> void:
	var doc: String = _text(DOC_PATH)
	var start: int = doc.find("## Registry")
	var end: int = doc.find("## Limits")
	assert_gt(start, -1, "the Registry section exists")
	assert_gt(end, start, "and ends before Limits")
	var registry: String = doc.substr(start, end - start)
	for stat: StringName in StatIds.all():
		assert_true(registry.contains("`%s`" % stat), "the registry names %s" % stat)


func test_the_registry_is_sorted_and_split_by_kind() -> void:
	var ids: Array[StringName] = StatIds.all()
	assert_eq(ids.size(), StatIds.INT_STATS.size() + StatIds.FLOAT_STATS.size(), "every id once")
	for index: int in range(1, ids.size()):
		assert_lt(String(ids[index - 1]), String(ids[index]), "alphabetical at %d" % index)
	assert_true(StatIds.is_int(&"tower.damage"), "tower damage is an integer")
	assert_false(StatIds.is_int(&"tower.range"), "tower range is a float")
	assert_true(StatIds.is_known(&"tower.range"), "and it is known")
	assert_false(StatIds.is_known(&"tower.rnge"), "a typo is not")


func test_a_modifier_reports_a_problem_for_an_unknown_stat_or_a_value_out_of_range() -> void:
	var good: StatModifierDef = StatModifierDef.new()
	good.stat = &"tower.damage"
	good.bucket = StatModifierDef.Bucket.PERCENT
	good.value = 25
	assert_true(good.problems().is_empty(), "a valid modifier has no problem")
	var typo: StatModifierDef = good.duplicate()
	typo.stat = &"tower.dmg"
	var problems: PackedStringArray = typo.problems()
	assert_eq(problems.size(), 1, "one problem")
	assert_true(problems[0].contains("tower.dmg"), "it names the stat id")
	var wide: StatModifierDef = good.duplicate()
	wide.value = 1001
	assert_eq(wide.problems().size(), 1, "a percent of 1001 is reported")
	wide.bucket = StatModifierDef.Bucket.MULTIPLIER
	wide.value = 9
	assert_eq(wide.problems().size(), 1, "a multiplier of 9 is reported")
	wide.bucket = StatModifierDef.Bucket.FLAT
	wide.value = -100001
	assert_eq(wide.problems().size(), 1, "a flat of -100001 is reported")


func test_the_modifier_resource_reads_its_own_text_and_limits() -> void:
	var percent: StatModifierDef = _mod(&"tower.damage", StatModifierDef.Bucket.PERCENT, 25)
	assert_eq(percent.effect_text(), "+25% tower damage", "percent text")
	assert_eq(
		_mod(&"king.attack_damage", StatModifierDef.Bucket.FLAT, 1).effect_text(), "+1 king damage"
	)
	var slow: StatModifierDef = _mod(
		&"king.attack_interval", StatModifierDef.Bucket.MULTIPLIER, 150
	)
	assert_eq(slow.effect_text(), "x1.5 king attack interval", "multiplier text")
	var twice: StatModifierDef = _mod(&"tower.damage", StatModifierDef.Bucket.MULTIPLIER, 200)
	assert_eq(twice.effect_text(), "x2 tower damage", "x2")
	assert_eq(StatIds.label(&"nope"), "nope", "an unknown id labels itself")
	assert_true(percent.problems().is_empty(), "a valid modifier has no problem")
