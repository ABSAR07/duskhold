extends GutTest
## D-10, UNIT-09: the pure selection state. The list is always in creation order whatever order
## squads were clicked; `changed` fires once per mutation and never for a no-op; cycling picks the
## squad after the last cycled one and wraps.

const ALL: Array[StringName] = [&"barracks_1", &"archery_1", &"barracks_2"]
const FOOTMAN: StringName = &"footman"
const ARCHER: StringName = &"archer"

var _model: SelectionModel
var _changes: int = 0


func before_each() -> void:
	_model = SelectionModel.new()
	_changes = 0
	_model.changed.connect(func() -> void: _changes += 1)


func _type_of(squad_id: StringName) -> StringName:
	return ARCHER if squad_id == &"archery_1" else FOOTMAN


func test_a_new_model_selects_nothing() -> void:
	assert_eq(_model.selected(), [] as Array[StringName], "empty")
	assert_false(_model.is_selected(&"barracks_1"), "nothing is selected")
	assert_eq(_changes, 0, "no signal yet")


func test_select_only_keeps_creation_order() -> void:
	_model.select_only([&"barracks_2", &"barracks_1"] as Array[StringName], ALL)
	assert_eq(
		_model.selected(), [&"barracks_1", &"barracks_2"] as Array[StringName], "creation order"
	)
	assert_true(_model.is_selected(&"barracks_2"), "is_selected agrees")
	assert_eq(_changes, 1, "one change")


func test_select_only_drops_ids_that_are_not_squads() -> void:
	_model.select_only([&"ghost", &"archery_1"] as Array[StringName], ALL)
	assert_eq(_model.selected(), [&"archery_1"] as Array[StringName], "only the real squad")


func test_toggle_adds_then_removes() -> void:
	_model.toggle(&"archery_1", ALL)
	assert_eq(_model.selected(), [&"archery_1"] as Array[StringName], "added")
	_model.toggle(&"barracks_1", ALL)
	assert_eq(
		_model.selected(),
		[&"barracks_1", &"archery_1"] as Array[StringName],
		"added in creation order"
	)
	_model.toggle(&"archery_1", ALL)
	assert_eq(_model.selected(), [&"barracks_1"] as Array[StringName], "removed")
	assert_eq(_changes, 3, "one change per toggle")


func test_select_all_returns_every_id_in_creation_order() -> void:
	_model.select_all(ALL)
	assert_eq(_model.selected(), ALL, "all of them")
	assert_eq(_changes, 1, "one change")


func test_select_same_type_returns_every_squad_of_that_type_in_creation_order() -> void:
	_model.select_same_type(&"barracks_2", ALL, _type_of)
	assert_eq(
		_model.selected(), [&"barracks_1", &"barracks_2"] as Array[StringName], "both footmen"
	)
	_model.select_same_type(&"archery_1", ALL, _type_of)
	assert_eq(_model.selected(), [&"archery_1"] as Array[StringName], "the archers replace them")


func test_select_same_type_of_an_unknown_squad_changes_nothing() -> void:
	_model.select_same_type(&"ghost", ALL, _type_of)
	assert_eq(_model.selected(), [] as Array[StringName], "nothing selected")
	assert_eq(_changes, 0, "no signal")


func test_clear_empties_the_selection() -> void:
	_model.select_all(ALL)
	_model.clear()
	assert_eq(_model.selected(), [] as Array[StringName], "empty")
	assert_eq(_changes, 2, "select and clear")


func test_a_no_op_fires_no_change() -> void:
	_model.clear()
	assert_eq(_changes, 0, "clearing nothing")
	_model.select_only([&"archery_1"] as Array[StringName], ALL)
	_model.select_only([&"archery_1"] as Array[StringName], ALL)
	assert_eq(_changes, 1, "the same selection twice")
	_model.select_all(ALL)
	_model.select_all(ALL)
	assert_eq(_changes, 2, "select all twice")


func test_cycle_next_walks_the_squads_in_creation_order_and_wraps() -> void:
	assert_eq(_model.cycle_next(ALL), &"barracks_1", "first")
	assert_eq(_model.selected(), [&"barracks_1"] as Array[StringName], "selects only it")
	assert_eq(_model.cycle_next(ALL), &"archery_1", "second")
	assert_eq(_model.cycle_next(ALL), &"barracks_2", "third")
	assert_eq(_model.cycle_next(ALL), &"barracks_1", "wraps to the first")
	assert_eq(_model.selected(), [&"barracks_1"] as Array[StringName], "selects only the wrap")


func test_cycle_next_follows_the_last_cycled_not_the_last_clicked() -> void:
	_model.cycle_next(ALL)
	_model.select_only([&"barracks_2"] as Array[StringName], ALL)
	assert_eq(_model.cycle_next(ALL), &"archery_1", "the squad after the last cycled one")


func test_cycle_next_with_no_squads_returns_nothing_and_changes_nothing() -> void:
	var none: Array[StringName] = []
	assert_eq(_model.cycle_next(none), &"", "no squad")
	assert_eq(_changes, 0, "no signal")


func test_cycling_a_single_squad_selects_it_once() -> void:
	var one: Array[StringName] = [&"barracks_1"]
	assert_eq(_model.cycle_next(one), &"barracks_1", "the only squad")
	assert_eq(_model.cycle_next(one), &"barracks_1", "again")
	assert_eq(_changes, 1, "the second cycle changed nothing")
