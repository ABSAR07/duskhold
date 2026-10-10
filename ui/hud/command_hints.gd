class_name CommandHints
extends HBoxContainer
## Inert skeleton, replaced by the real strip in the GREEN step of plan 03-10.

const VERBS: Array[String] = ["Follow", "Hold", "Rally", "Move", "Attack", "Patrol", "Queue"]


func bind_run(_ctx: RunContext, _map_root: MapRoot) -> void:
	pass


func set_selection(_selection: SelectionModel) -> void:
	pass


func visible_item_count() -> int:
	return 0


func item_words() -> Array[String]:
	return []


func get_item(_word: String) -> HBoxContainer:
	return null
