class_name KingWidget
extends HBoxContainer
## The king's health and slam cooldown, bottom-left (D-22).

const HEALTH_TEXT := "%d / %d"
const ABILITY_CAPTION := "Slam"
const READY_COLOR := Color("#8CEBFF")
const IDLE_BORDER_COLOR := Color("#3A3F4B")


func bind_run(_ctx: RunContext, _map_root: MapRoot) -> void:
	pass


func ready_flash_count() -> int:
	return 0


func shake_count() -> int:
	return 0


func get_health_bar() -> ProgressBar:
	return null


func get_health_label() -> Label:
	return null


func get_ability_bar() -> TextureProgressBar:
	return null


func get_plate() -> Panel:
	return null


func get_caption() -> Label:
	return null
