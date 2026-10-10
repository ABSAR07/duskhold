extends GutTest
## UNIT-09, D-10, D-16, D-25: control groups on the SelectionModel, pure presentation state. Ten
## groups of squad ids (keys 1 to 9 and 0, the last being group 10). Storing replaces a group's
## members from the selection; recalling replaces the selection with them. Squads are never
## deleted, so a group never loses a member that drops to 0 alive, and a squad built later joins no
## group. The lowest group number a squad is in feeds its slot badge: 1..9 show as the digit, group
## 10 shows as 0.

const BARRACKS: StringName = &"barracks_1"
const ARCHERY: StringName = &"archery_1"
const ALL: Array[StringName] = [&"barracks_1", &"archery_1"]

var _model: SelectionModel


func before_each() -> void:
	_model = SelectionModel.new()


func _select(ids: Array[StringName]) -> void:
	_model.select_only(ids, ALL)


func test_there_are_ten_groups() -> void:
	assert_eq(SelectionModel.GROUP_COUNT, 10, "keys 1 to 9 and 0")


func test_a_stored_group_is_recalled_as_the_selection() -> void:
	_select([BARRACKS] as Array[StringName])
	assert_true(_model.store_group(1), "stored")
	_select([ARCHERY] as Array[StringName])
	assert_true(_model.recall_group(1, ALL), "recalled")
	assert_eq(_model.selected(), [BARRACKS] as Array[StringName], "exactly the stored squads")


func test_a_group_stores_the_whole_selection_in_creation_order() -> void:
	_select(ALL)
	assert_true(_model.store_group(4), "stored")
	assert_eq(_model.group_members(4), ALL, "both, creation order")
	_model.clear()
	assert_true(_model.recall_group(4, ALL), "recalled")
	assert_eq(_model.selected(), ALL, "both are selected again")


func test_storing_with_nothing_selected_returns_false_and_leaves_the_group_alone() -> void:
	_select([BARRACKS] as Array[StringName])
	_model.store_group(1)
	_model.clear()
	assert_false(_model.store_group(1), "refused")
	assert_eq(_model.group_members(1), [BARRACKS] as Array[StringName], "the group is unchanged")


func test_recalling_an_empty_group_returns_false_and_keeps_the_selection() -> void:
	_select([ARCHERY] as Array[StringName])
	assert_false(_model.recall_group(2, ALL), "nothing to recall")
	assert_eq(_model.selected(), [ARCHERY] as Array[StringName], "the selection is kept")


func test_group_ten_is_key_zero() -> void:
	_select([ARCHERY] as Array[StringName])
	assert_true(_model.store_group(10), "group 10 stores")
	assert_eq(_model.group_members(10), [ARCHERY] as Array[StringName], "with its member")
	assert_eq(SelectionModel.badge_digit(10), 0, "and its badge digit is 0")
	for group: int in range(1, 10):
		assert_eq(SelectionModel.badge_digit(group), group, "group %d shows its own digit" % group)


func test_groups_outside_one_to_ten_do_nothing() -> void:
	_select([BARRACKS] as Array[StringName])
	for group: int in [-1, 0, 11, 100]:
		assert_false(_model.store_group(group), "store %d" % group)
		assert_false(_model.recall_group(group, ALL), "recall %d" % group)
		assert_true(_model.group_members(group).is_empty(), "members of %d" % group)
	assert_eq(_model.selected(), [BARRACKS] as Array[StringName], "the selection is untouched")


func test_the_lowest_group_of_a_squad_is_its_smallest_group_number() -> void:
	_select([BARRACKS] as Array[StringName])
	_model.store_group(10)
	assert_eq(_model.lowest_group_of(BARRACKS), 10, "only in group 10")
	_model.store_group(7)
	assert_eq(_model.lowest_group_of(BARRACKS), 7, "7 is lower than 10")
	_model.store_group(3)
	assert_eq(_model.lowest_group_of(BARRACKS), 3, "3 is lower than 7")
	assert_eq(_model.lowest_group_of(ARCHERY), -1, "a squad in no group is -1")


func test_storing_replaces_the_previous_members_of_the_group() -> void:
	_select([BARRACKS] as Array[StringName])
	_model.store_group(1)
	_select([ARCHERY] as Array[StringName])
	_model.store_group(1)
	assert_eq(_model.group_members(1), [ARCHERY] as Array[StringName], "replaced, not merged")
	assert_eq(_model.lowest_group_of(BARRACKS), -1, "the barracks left the group")


func test_a_squad_that_reached_zero_alive_stays_in_its_groups() -> void:
	_select([BARRACKS] as Array[StringName])
	_model.store_group(2)
	# The model keeps ids and never asks whether anyone is alive: a squad is never deleted.
	_model.clear()
	assert_eq(_model.lowest_group_of(BARRACKS), 2, "still in the group")
	assert_true(_model.recall_group(2, ALL), "and recalled")
	assert_eq(_model.selected(), [BARRACKS] as Array[StringName], "selected again")


func test_a_squad_built_later_joins_no_group() -> void:
	_select(ALL)
	_model.store_group(1)
	var later: Array[StringName] = [&"barracks_1", &"archery_1", &"barracks_2"]
	assert_eq(_model.lowest_group_of(&"barracks_2"), -1, "the new squad has no group")
	_model.clear()
	_model.recall_group(1, later)
	assert_eq(_model.selected(), ALL, "a recall does not pick it up")


func test_group_members_is_a_copy() -> void:
	_select([BARRACKS] as Array[StringName])
	_model.store_group(1)
	var members: Array[StringName] = _model.group_members(1)
	members.append(ARCHERY)
	assert_eq(_model.group_members(1), [BARRACKS] as Array[StringName], "the model is unchanged")


func test_group_recalled_fires_with_the_group_on_a_successful_recall_only() -> void:
	_select([BARRACKS] as Array[StringName])
	_model.store_group(5)
	watch_signals(_model)
	_model.recall_group(6, ALL)
	assert_signal_not_emitted(_model, "group_recalled", "an empty group does not flash")
	_model.recall_group(5, ALL)
	assert_signal_emitted_with_parameters(_model, "group_recalled", [5])
	assert_signal_emit_count(_model, "group_recalled", 1)


func test_changed_fires_when_a_store_changes_a_badge_and_not_for_a_repeat() -> void:
	_select([BARRACKS] as Array[StringName])
	watch_signals(_model)
	_model.store_group(1)
	assert_signal_emit_count(_model, "changed", 1)
	_model.store_group(1)
	assert_signal_emit_count(_model, "changed", 1)
