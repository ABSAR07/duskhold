class_name SelectionModel
extends RefCounted
## Which squads the player has selected (D-10). Pure presentation state: it never reaches the
## simulation (an order carries the selected ids explicitly) and holds no Node. Ids are squad ids,
## the military spot ids. The list is always rebuilt in `all_ids` order, which is creation order, so
## the order squads were clicked never matters. `changed` fires once per mutation and not for a
## no-op. A squad that dies down to 0 alive stays selected (squads are never deleted).

signal changed
## A control group was recalled (1..10, key 0 is group 10).
signal group_recalled(group: int)

## Control groups: keys 1 to 9 and 0, the last being group 10.
const GROUP_COUNT: int = 10

var _selected: Array[StringName] = []
var _last_cycled: StringName = &""


## The selected squad ids in creation order. A copy.
func selected() -> Array[StringName]:
	return _selected.duplicate()


func is_selected(squad_id: StringName) -> bool:
	return _selected.has(squad_id)


func clear() -> void:
	_store([])


## Selects exactly `ids` (those that exist in `all_ids`), in creation order.
func select_only(ids: Array[StringName], all_ids: Array[StringName]) -> void:
	_store(_in_creation_order(ids, all_ids))


## Adds `squad_id` to the selection, or removes it when it is already selected.
func toggle(squad_id: StringName, all_ids: Array[StringName]) -> void:
	var wanted: Array[StringName] = _selected.duplicate()
	if wanted.has(squad_id):
		wanted.erase(squad_id)
	else:
		wanted.append(squad_id)
	_store(_in_creation_order(wanted, all_ids))


func select_all(all_ids: Array[StringName]) -> void:
	_store(all_ids.duplicate())


## Selects every squad whose type (as `type_of` answers for a squad id) matches `squad_id`'s.
func select_same_type(squad_id: StringName, all_ids: Array[StringName], type_of: Callable) -> void:
	if not all_ids.has(squad_id):
		return
	var wanted_type: Variant = type_of.call(squad_id)
	var same: Array[StringName] = []
	for candidate: StringName in all_ids:
		if type_of.call(candidate) == wanted_type:
			same.append(candidate)
	_store(same)


## Selects only the squad after the one cycled last, in creation order, wrapping at the end, and
## returns it; the first squad when none was cycled yet. &"" (and no change) with no squads.
func cycle_next(all_ids: Array[StringName]) -> StringName:
	if all_ids.is_empty():
		return &""
	var index: int = all_ids.find(_last_cycled)
	var next_id: StringName = all_ids[(index + 1) % all_ids.size()]
	_last_cycled = next_id
	_store([next_id] as Array[StringName])
	return next_id


func _in_creation_order(ids: Array[StringName], all_ids: Array[StringName]) -> Array[StringName]:
	var ordered: Array[StringName] = []
	for squad_id: StringName in all_ids:
		if ids.has(squad_id) and not ordered.has(squad_id):
			ordered.append(squad_id)
	return ordered


func _store(ids: Array[StringName]) -> void:
	if ids == _selected:
		return
	_selected = ids
	changed.emit()


## Stores the selection as control group `group` (1..10). False, with nothing changed, when the
## selection is empty.
func store_group(_group: int) -> bool:
	return false


## Selects the members of control group `group`. False, with the selection kept, when it is empty.
func recall_group(_group: int, _all_ids: Array[StringName]) -> bool:
	return false


## The squad ids stored in `group`, in creation order. A copy.
func group_members(_group: int) -> Array[StringName]:
	return [] as Array[StringName]


## The lowest group number (1..10) `squad_id` belongs to, or -1 when it is in no group.
func lowest_group_of(_squad_id: StringName) -> int:
	return -1


## The digit a badge shows for `group`: 1..9, and 0 for group 10.
static func badge_digit(group: int) -> int:
	return group % 10
