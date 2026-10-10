class_name Toast
extends Label
## One-line toast in the hint-strip slot (UI-SPEC). Inert skeleton until the GREEN commit.

const SELECT_FIRST := "Select a squad first"


func show_toast(_message: String, _seconds: float = 1.2) -> void:
	pass


func show_error(_message: String) -> void:
	pass


func set_line(_message: String) -> void:
	pass


func clear_line() -> void:
	pass


func current_text() -> String:
	return ""
