class_name SquadSlot
extends PanelContainer
## RED skeleton: one squad's slot in the strip. Built in the implementation step.

const ALIVE_TEXT := "%d / %d"

var squad_id: StringName = &""


func refresh(_ctx: RunContext) -> void:
	pass


func set_selected(_selected: bool) -> void:
	pass


func set_group(_digit: int) -> void:
	pass


func get_alive_label() -> Label:
	return null


func get_icon() -> TextureRect:
	return null


func get_glyph() -> StanceGlyph:
	return null


func get_fill() -> ProgressBar:
	return null


func get_badge() -> PanelContainer:
	return null


func flash_count() -> int:
	return 0


func border_color() -> Color:
	return Color.BLACK
