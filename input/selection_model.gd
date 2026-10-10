class_name SelectionModel
extends RefCounted
## Which squads the player has selected (D-10). Inert skeleton: the behaviour lands with the GREEN
## commit of plan 03-06 task 2.

signal changed


func selected() -> Array[StringName]:
	return []


func is_selected(_squad_id: StringName) -> bool:
	return false


func clear() -> void:
	pass


func select_only(_ids: Array[StringName], _all_ids: Array[StringName]) -> void:
	pass


func toggle(_squad_id: StringName, _all_ids: Array[StringName]) -> void:
	pass


func select_all(_all_ids: Array[StringName]) -> void:
	pass


func select_same_type(
	_squad_id: StringName, _all_ids: Array[StringName], _type_of: Callable
) -> void:
	pass


func cycle_next(_all_ids: Array[StringName]) -> StringName:
	return &""
